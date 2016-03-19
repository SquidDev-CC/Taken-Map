local config = require "config"
local blocks = require "server.world.blocks"

local width, height = config.map.width, config.map.height

return function()
	local data = {}
	local map = { data = data }

	for x = 1, width do
		local row = {}
		for y = 1, height do
			row[y] = "empty"
		end
		data[x] = row
	end

	local world = {}

	world.width = width
	world.height = height

	function world.setBlock(x, y, kind)
		if type(x) ~= "number" then error("Bad argument #1: expected number, got " .. type(x)) end
		if type(y) ~= "number" then error("Bad argument #2: expected number, got " .. type(y)) end
		if type(kind) ~= "string" then error("Bad argument #3: expected string, got " .. type(kind)) end

		if x < 1 or x > width then error("X coordinate is out of bounds", 2) end
		if y < 1 or y > height then error("Y coordinate is out of bounds", 2) end
		if not blocks[kind] then error("No such block " .. kind, 2) end

		data[x][y] = kind
	end

	function world.count()
		local counts = {}

		for name, _ in ipairs(blocks) do
			counts[name] = 0
		end

		for x = 1, width do
			local row = data[x]
			for y = 1, height do
				local value = row[y]
				counts[value] = counts[value] + 1
			end
		end

		return counts
	end

	function world.find(kind)
		if type(kind) ~= "string" then error("Bad argument #1: expected string, got " .. type(kind)) end
		if not blocks[kind] then error("No such block " .. kind, 2) end

		local items, n = {}, 0

		for x = 1, width do
			local row = data[x]
			for y = 1, height do
				if row[y] == kind then
					n = n + 1
					items[n] = { x, y }
				end
			end
		end

		items.n = n
		return items
	end

	function world.setTitle(title, subtitle)
		if type(title) ~= "string" then error("Bad argument #1: expected string, got " .. type(title)) end
		if type(subtitle) ~= "string" then error("Bad argument #2: expected string, got " .. type(subtitle)) end

		map.title = title
		map.subtitle = subtitle
	end

	function world.setup()
		local entrance = world.find("entrance")[1]
		if not entrance then error("Cannot find entrance", 2) end

		map.entrance = entrance
		return map
	end

	return world
end
