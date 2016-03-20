local asserts = require "shared.asserts"
local builder = require "server.world.builder"
local command = require "server.command".wrap
local map = require "server.world.map"
local player = require "server.world.player"

local tellraw = command("tellraw")
local function say(message) tellraw("@a", {"",{text=message,color="red"}}) end

local function sayPrint(...)
	local args = { ... }
	for i = 1, select('#', ...) do
		args[i] = tostring(args[i])
	end

	say(args)
end

local function assertEq(expected, actual, message)
	if expected ~= actual then
		if message then
			message = message .. ": "
		else
			message = ""
		end
		error(message .. "Expected " .. tostring(expected) .. ", got " .. tostring(actual), 0)
	end
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

local function makeEnv()
	local env = {}
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

	local env = makeEnv()
	local func, msg = load(text, file.name, nil, env)
	if not func then error(msg or "Cannot load file", 0) end

	func()

	local backup = copy(env)

	if not backup.generate then error("No generate function", 0) end

	local world = map()
	backup.generate(copy(world, nil, { setup = true }))
	if backup.validate then backup.validate(copy(world, nil, { setup = true })) end

	local map = world.setup()

	builder.clear()
	sleep(0.05)
	builder.build(map)
	sleep(0.05)
	builder.setup(map)

	return function()
		local previousSuccess = false
		while true do
			local success, msg = commands.execute("@a", "~", "~", "~", "testforblock", "~", "~-1", "~", "minecraft:stained_glass", "3")
			if success then
				if backup.exit then
					local success, msg = pcall(backup.exit, copy(player))
					if success then
						break
					elseif not previousSuccess then
						say(msg)
					end
				else
					break
				end
			end

			previousSuccess = success
		end
	end
end
