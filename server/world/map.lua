local config = require "shared.config"
local blocks = require "server.world.blocks"
local decorations = require "server.world.decorations"
local environment = require "server.world.environment"

local width, height = config.map.width, config.map.height

return function()
	local data = {}
	local map = { data = data }
	local worldEnv

	for x = 1, width do
		local row = {}
		for y = 1, height do
			row[y] = { "empty" }
		end
		data[x] = row
	end

	local world = {}

	world.width = width
	world.height = height
	world.ceiling = config.map.ceiling

	function world.setBlocks(x, y, width, height, kind)
		if type(x) ~= "number" then error("Bad argument #1: expected number, got " .. type(x), 2) end
		if type(y) ~= "number" then error("Bad argument #2: expected number, got " .. type(y), 2) end
		if type(width) ~= "number" then error("Bad argument #3: expected number, got " .. type(width), 2) end
		if type(height) ~= "number" then error("Bad argument #4: expected number, got " .. type(height), 2) end
		if type(kind) ~= "string" then error("Bad argument #5: expected string, got " .. type(kind), 2) end

		if width <= 0 then error("width is <= 0", 2) end
		if height <= 0 then error("height is <= 0", 2) end

		width = width + x - 1
		height = height + y - 1

		for x = x, width do
			for y = y, height do
				world.setBlock(x, y, kind)
			end
		end
	end

	function world.setEnvironment(kind)
		local env = environment[kind]
		if not env then error("No such environment " .. tostring(kind), 2) end
		if worldEnv then error("Already have an environment", 2) end
		worldEnv = env
	end

	function world.setBlock(x, y, kind, ...)
		if type(x) ~= "number" then error("Bad argument #1: expected number, got " .. type(x), 2) end
		if type(y) ~= "number" then error("Bad argument #2: expected number, got " .. type(y), 2) end
		if type(kind) ~= "string" then error("Bad argument #3: expected string, got " .. type(kind), 2) end

		if x < 1 or x > width then error("X coordinate (" .. x .. ") is out of bounds", 2) end
		if y < 1 or y > height then error("Y coordinate (" .. y .. ") is out of bounds", 2) end

		local block = blocks[kind]
		if not block then error("No such block " .. kind, 2) end

		local args
		if block.args then args = {block.args(...)} end

		local row = data[x]
		local current = row[y]
		if current[1] ~= kind and not blocks[current[1]].overwrite then error("Already a block at " .. x .. ", " .. y, 2) end

		if block.decorate then
			current[1] = kind
			current[3] = args
		else
			-- Clear decoration
			row[y] = { kind, nil, args }
		end
	end

	function world.decorate(x, y, decoration)
		if type(x) ~= "number" then error("Bad argument #1: expected number, got " .. type(x), 2) end
		if type(y) ~= "number" then error("Bad argument #2: expected number, got " .. type(y), 2) end
		if type(decoration) ~= "string" then error("Bad argument #3: expected string, got " .. type(decoration), 2) end

		if x < 1 or x > width then error("X coordinate is out of bounds", 2) end
		if y < 1 or y > height then error("Y coordinate is out of bounds", 2) end

		local id = decorations[decoration]
		if not id then error("No such decoration: " .. decoration, 2) end

		local row = data[x]
		local current = row[y]
		local block = blocks[current[1]]
		if not block.decorate then error(current[1] .. " cannot be decorated", 2) end
		current[2] = id
	end

	function world.count()
		local counts = {}

		for name, _ in ipairs(blocks) do
			counts[name] = 0
		end

		for x = 1, width do
			local row = data[x]
			for y = 1, height do
				local value = row[y][1]
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
				local current = row[y]
				if current[1] == kind then
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

		map.width = width
		map.height = height
		map.entrance = entrance
		map.env = worldEnv or environment.lab
		return map
	end

	return world
end
