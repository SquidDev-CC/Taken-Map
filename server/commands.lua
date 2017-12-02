local commands = commands

local function setup(config)
	commands.gamerule("commandBlockOutput", false)
end

local function load(config)
end

--- Wrapper function for debugging commands
local function wrap(name, wrap, verbose)
	if not commands then verbose = true end
	if wrap or verbose then
		local func
		if not commands then
			func = print
		else
		 	func = commands[name]
		end
		return function(...)
			local success, res = func(...)
			if not success or verbose then
				print((textutils.serialize({...}):gsub("%s+", " ")))
				print((textutils.serialize(res):gsub("%s+", " ")))
			end

			return success, res
		end
	else
		return commands.async[name]
	end
end

local function say(message)
	print(message)
	commands.async.tellraw("@a", {"",{text=message,color="white"}})
end

local function sayError(message)
	printError(message)
	commands.async.tellraw("@a", {"",{text=message,color="red"}})
end

local function sayPrint(...)
	local args = { ... }
	for i = 1, select('#', ...) do
		args[i] = tostring(args[i])
	end

	commands.say(table.concat(args, " "))
end

return {
	setup    = setup,
	load     = load,

	say      = say,
	sayError = sayError,
	sayPrint = sayPrint,

	getBlockPosition = commands.getBlockPosition,
	getBlockInfo = commands.getBlockInfo,

	async = commands.async,
	sync = commands,
}
