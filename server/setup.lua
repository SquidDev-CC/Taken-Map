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

local function hollowBlock(x, y, z, w, c, h)
	-- Walls
	fill(x,         y, z,         x + w + 1, y + c, z,         block)
	fill(x,         y, z,         x,         y + c, z + h + 1, block)
	fill(x,         y, z + h + 1, x + w + 1, y + c, z + h + 1, block)
	fill(x + w + 1, y, z,         x + w + 1, y + c, z + h,     block)

	-- Glass Ceiling
	fill(x + 1, y + c, z + 1, x + w, y + c, z + h, glass)

	-- Floor
	fill(x, y - 2, z, x + w + 1, y - 1, z + h + 1, block)

	-- Middle
	fill(x + 1, y, z + 1, x + w, y + c - 1, z + h, air)
end

return function()
	local x, y, z = commands.getBlockPosition()
	setBlock(x, y + 1, z, "computercraft:advanced_modem", 0)

	x, y, z = position()
	print("Generating")

	hollowBlock(x, y, z, w, c, h)

	-- Pods
	hollowBlock(x,     y, z - 5, 3, 3, 3)
	hollowBlock(x + 5, y, z - 5, 3, 3, 3)

	setBlock(x + 2, y + 1, z - 2, "minecraft:wall_sign", 0, "replace", {Text2 = "You died", Text3 = "Try again"})
	setBlock(x + 7, y + 1, z - 2, "minecraft:wall_sign", 0, "replace", {Text2 = "Building in", Text3 = "progress"})

	-- Beacon base
	fill(x, y - 3, z, x + w + 1, y - 3, z + h + 1, "minecraft:iron_block")

	sleep(0.3)
	print("Done!")
end
