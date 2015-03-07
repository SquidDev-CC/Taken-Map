local helpers = {}

function helpers.createPocket(id, label)
	return Items.createItem(
		Config.BlockInfo.Pocket.Id,
		1,
		Computers.createPocket(0, "Someone's pocket", true)
	)
end

local environment = {}

function environment:create()
	return {
		Helpers = helpers,

		ipairs = ipairs,
		next = next,
		pairs = pairs,
		rawequal = rawequal,
		rawget = rawget,
		rawset = rawset,
		string = string,
		table = table,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,
	}
end

function environment:execute(func, env, ...)
	local env = setmetatable({}, {__index = env})
	setfenv(func, env)(...)
	return env
end
