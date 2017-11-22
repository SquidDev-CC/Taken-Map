local asserts = require "shared.asserts"
local commands = require "server.commands"
local config = require "shared.config"
local copy = require "shared.collections".copy
local map_x, map_y, map_z = require "server.origin".get()
local player = require "server.player"

local blocks = require "server.world.blocks"
local builder = require "server.world.builder"
local helpers = require "server.world.helpers"
local map = require "server.world.map"

local parse = require "server.level.parse"

local deltas = { -config.check_offset, config.check_offset }
local debug_particles = config.debug_particles
local valid_functions = { setup = true, validate = true, generate = true, exit = true }

local function createWorldAccess(world)
	local clone = copy(world, nil, {setup = true, find = true})
	helpers(clone)
	return clone
end

local function createPlayerAccess(player)
	return copy(player, nil)
end

local function resetEnvironment(env)
	env.print  = commands.sayPrint
	env.pairs  = pairs
	env.ipairs = ipairs
	env.error  = error

	env.math = copy(math)
	env.string = copy(string)
	env.assert = copy(asserts)

	env._G   = env
	env._ENV = env
end

return function(files)
	local file = files[1]
	if not file or not file.lines then error("Cannot find file", 0) end
	local text = table.concat(file.lines, "\n")

	-- Ensure the program is valid Lua
	local env = {}
	local func, msg = load(text, file.name, nil, env)
	if not func then error(msg or "Cannot load file", 0) end

	-- Ensure the file doesn't do really sneaky things
	local parsed = parse(text)
	local defined = {}
	local function makeError(node, msg)
		local header = file.name .. ":"
		if node and node.Head then
			header = header .. node.Head.Line .. ":"
		end

		error(header .. " " .. msg, 0)
	end

	for _, v in ipairs(parsed.Body) do
		if v.AstType == "Function" then
			if v.IsLocal then makeError(v, "Cannot use local functions") end
			if v.Name.AstType ~= "VarExpr" then makeError(v, "Cannot declare indexed function") end
			local name = v.Name.Name
			if not valid_functions[name] then makeError(v, "Cannot define function " .. name) end
			if defined[name] then makeError(v, name .. " has already been defined") end

			defined[name] = true
		else
			-- Make CamelCase type more readable
			local type = v.AstType:gsub("(%u)", " %1"):gsub("^%s", ""):lower()
			makeError(v, "Invalid " .. type)
		end
	end

	-- Invoke the function. This should just define things
	func()

	-- We create a backup of the environment so people don't go overriding the
	-- generated methods
	local backup = copy(env)

	if not backup.generate then error("No generate function", 0) end

	local world = map()
	local use_state = false
	local player_access = {
		hasComputer = player.hasComputer,
		showState = function() use_state = true end,
	}

	-- Setup will configure the title, environment, etc... Nothing important
	if backup.setup then
		-- Setup the environment each time to prevent people from modifying tables
		-- Looking at you @BombBloke
		resetEnvironment(env)
		backup.setup(createWorldAccess(world), createPlayerAccess(player_access))
	end

	-- The main generation functions
	resetEnvironment(env)
	backup.generate(createWorldAccess(world), createPlayerAccess(player_access))

	-- And ensure everything validates correctly
	if backup.validate then
		resetEnvironment(env)
		backup.validate(createWorldAccess(world), createPlayerAccess(player_access))
	end

	local map = world.setup()

	-- Generate the world
	builder.tearDown(map)
	sleep(0.05)
	builder.build(map)
	sleep(0.05)
	builder.setup(map)
	player.usingState(use_state)

	-- We return a function so we can tell the difference between generation
	-- errors and runtime errors
	return function()
		local previous_success = false
		local function handle(x, z)
			local row = map.data[x]
			if row then
				local block_data = row[z]
				if block_data then
					local block = block_data[1]

					if block == "exit" then
						if backup.exit then
							local success, msg = pcall(backup.exit, createPlayerAccess(player_access))
							if success then
								return true
							elseif not previous_success then
								commands.sayError(msg)
							end
							previous_success = true
						else
							return true
						end
					elseif block then
						block = blocks[block]
						if block and block.hit then block.hit(x, z, player, unpack(block_data[3] or {})) end
					end
				end
			end

			return false
		end

		local running = true
		while running do
			local pos_x, pos_y, pos_z = player.updatePosition()
			pos_x = pos_x - map_x
			pos_y = pos_y - map_y
			pos_z = pos_z - map_z

			if debug_particles then
				commands.async.particle("reddust", math.floor(pos_x + map_x) + 0.5, map_y, math.floor(pos_z + map_z) + 0.5, 0, 0, 0, 0, 20)
			end

			if not player.isSpectating() and pos_y >= 0 and pos_y <= config.map.ceiling then
				local visited = {}
				for _, delta_x in ipairs(deltas) do
					for _, delta_z in ipairs(deltas) do
						local x, z = math.floor(pos_x + delta_x), math.floor(pos_z + delta_z)
						local key = x .. "_" .. z
						if running and not visited[key] then
							visited[key] = true

							if debug_particles then
								commands.async.particle("splash", map_x + x + 0.5, map_y, map_z + z + 0.5, 0, 0, 0, 4, 20)
							end

							if handle(x, z) then
								commands.say("Success!")
								running = false
							end
						end
					end
				end
			end
		end
	end
end
