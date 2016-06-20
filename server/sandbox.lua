local asserts = require "shared.asserts"
local blocks = require "server.world.blocks"
local builder = require "server.world.builder"
local command = require "server.command"
local config = require "shared.config"
local helpers = require "server.world.helpers"
local map = require "server.world.map"
local parse = require "server.parse"
local player = require "server.world.player"
local mX, mY, mZ = require "server.position".get()

local deltas = { -config.checkOffset, config.checkOffset }
local debugParticles = config.debugParticles
local validFunctions = { setup = true, validate = true, generate = true, exit = true }

local function sayPrint(...)
	local args = { ... }
	for i = 1, select('#', ...) do
		args[i] = tostring(args[i])
	end

	command.say(table.concat(args, " "))
end

local function copy(table, cache, blacklist)
	if cache then
		local val = cache[table]
		if val then return val end
	else
		cache = {}
	end

	local out = {}
	cache[table] = out
	for k, v in pairs(table) do
		if not blacklist or not blacklist[k] then
			if type(v) == "table" then
				out[k] = copy(v, cache, blacklist)
			else
				out[k] = v
			end
		end
	end

	return out
end

local function setupWorld(world)
	local clone = copy(world, nil, {setup = true, find = true})
	helpers(clone)
	return clone
end

local function setupPlayer(player)
	local clone = copy(player, nil, {setup = true})
	return clone
end

local function makeEnv(env)
	env.print = sayPrint
	env.pairs = pairs
	env.ipairs = ipairs
	env.error = error

	env.math = copy(math)
	env.string = copy(string)
	env.assert = copy(asserts)

	env._G = env

	return env
end

return function(files)
	local file = files[1]
	if not file or not file.lines then error("Cannot find file", 0) end
	local text = table.concat(file.lines, "\n")

	local env = {}
	local func, msg = load(text, file.name, nil, env)
	if not func then error(msg or "Cannot load file", 0) end

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
			if not validFunctions[name] then makeError(v, "Cannot define function " .. name) end
			if defined[name] then makeError(v, name .. " has already been defined") end

			defined[name] = true
		else
			-- Make CamelCase type more readable
			local type = v.AstType:gsub("(%u)", " %1"):gsub("^%s", ""):lower()
			makeError(v, "Invalid " .. type)
		end
	end

	func()

	local backup = copy(env)

	if not backup.generate then error("No generate function", 0) end

	local world = map()
	local player = player()

	if backup.setup then
		-- Setup the environment each time to prevent people from modifying tables
		-- Looking at you @BombBloke
		makeEnv(env)
		backup.setup(setupWorld(world), setupPlayer(player))
	end

	makeEnv(env)
	backup.generate(setupWorld(world), setupPlayer(player))

	if backup.validate then
		makeEnv(env)
		backup.validate(setupWorld(world), setupPlayer(player))
	end

	local map = world.setup()

	builder.clear(map)
	sleep(0.05)
	builder.build(map)
	sleep(0.05)
	builder.setup(map)
	player.setup()

	return function(state)
		local previousSuccess = false
		local function handle(x, z)
			local row = map.data[x]
			if row then
				local blockData = row[z]
				if blockData then
					local block = blockData[1]

					if block == "exit" then
						if backup.exit then
							local success, msg = pcall(backup.exit, setupPlayer(player))
							if success then
								return true
							elseif not previousSuccess then
								command.sayError(msg)
							end
							previousSuccess = true
						else
							return true
						end
					elseif block then
						block = blocks[block]
						if block and block.hit then block.hit(x, z, player, unpack(blockData[3] or {})) end
					end
				end
			end

			return false
		end

		local noSuccess = true
		while noSuccess do
			local success, msg = commands.execute("@r[score_gamemode=0,score_gamemode_min=0]", "~", "~", "~", "tp", "@p", "~", "~", "~")
			if success then
				local oX, _, oZ = msg[1]:match("to ([-%d%.]+), ([-%d%.]+), ([-%d%.]+)")
				if not oX then print("Cannot extract position from " .. msg[1]) end

				oX = oX - mX
				oZ = oZ - mZ

				if debugParticles then
					commands.async.particle("reddust", math.floor(oX + mX) + 0.5, mY, math.floor(oZ + mZ) + 0.5, 0, 0, 0, 0, 20)
				end

				local visited = {}
				for _, dX in ipairs(deltas) do
					for _, dZ in ipairs(deltas) do
						local x, z = math.floor(oX + dX), math.floor(oZ + dZ)
						local key = x .. "_" .. z
						if noSuccess and not visited[key] then
							visited[key] = true

							if debugParticles then
								commands.async.particle("splash", mX + x + 0.5, mY, mZ + z + 0.5, 0, 0, 0, 4, 20)
							end

							if handle(x, z) then
								noSuccess = false
							end
						end
					end
				end
			end
		end
	end
end
