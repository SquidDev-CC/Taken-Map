local position = require "server.position".get
local map = require "shared.config".map
local command = require "server.command".wrap

local fill = command "fill"
local setBlock = command "setblock"

local block = "minecraft:quartz_block"
local glass = "minecraft:stained_glass 3"
local air = "minecraft:air"
local below = 3

local w, h = map.width, map.height
local c = map.ceiling

local function particle(x, y, z)
	commands.async.particle("reddust", x + 0.5, y, z + 0.6, 0, 0, 0, 0, 20)
end

local function particles(x, y, z)
	-- Fancy particle effects to show where we are going to build
	for x = x, x + w do
		particle(x, y - 2, z)
		particle(x, y + c, z)
		particle(x, y - 2, z + h)
		particle(x, y + c, z + h)
	end

	for z = z, z + h do
		particle(x, y - 2, z)
		particle(x, y + c, z)
		particle(x + w, y - 2, z)
		particle(x + w, y + c, z)
	end

	for y = y - 2, y + c do
		particle(x, y, z)
		particle(x + w, y, z)
		particle(x, y, z + h)
		particle(x + w, y, z + h)
	end
end

return function()
	local x, y, z = commands.getBlockPosition()
	setBlock(x, y + 1, z, "computercraft:advanced_modem", 0)

	x, y, z = position()
	print("Generating")
	-- Walls
	fill(x, y, z, x + w, y + c, z,     block)
	fill(x, y, z, x,     y + c, z + h, block)
	fill(x    , y, z + h, x + w, y + c, z + h, block)
	fill(x + w, y, z,     x + w, y + c, z + h, block)

	-- Glass Ceiling
	fill(x + 1, y + c, z + 1, x + w - 1, y + c, z + h - 1, glass)

	-- Floor
	fill(x, y - 2, z, x + w, y - 1, z + h, block)
	-- Beacon base
	fill(x, y - 3, z, x + w, y - 3, z + h, "minecraft:iron_block")

	-- Middle
	fill(x + 1, y, z + 1, x + w - 1, y + c - 1, z + h - 1, air)

	sleep(0.3)
	print("Done!")

	return x, y, z
end
