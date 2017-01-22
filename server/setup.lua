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

local deltas = {
	north = { -0.5,  0, -1,   -1 },
	south = { -0.5,  0,  1,   -1 },
	east  = { -1,   -1, -0.5,  0 },
	west  = {  1,   -1, -0.5,  0 },
}

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

local function hollowBlock(x, y, z, w, c, h, a)
	-- Walls
	fill(x,         y, z,         x + w + 1, y + c + a, z,         block)
	fill(x,         y, z,         x,         y + c + a, z + h + 1, block)
	fill(x,         y, z + h + 1, x + w + 1, y + c + a, z + h + 1, block)
	fill(x + w + 1, y, z,         x + w + 1, y + c + a, z + h,     block)

	-- Glass Ceiling
	fill(x + 1, y + c, z + 1, x + w, y + c, z + h, glass)

	-- Floor
	fill(x, y - 2, z, x + w + 1, y - 1, z + h + 1, block)

	-- Middle
	fill(x + 1, y, z + 1, x + w, y + c - 1, z + h, air)
end

return function()
	local x, y, z = commands.getBlockPosition()
	local info = commands.getBlockInfo(x, y, z)
	local facing = info.metadata
	local facingStr = info.state.facing

	local delta = deltas[facingStr]
	local dx, dz = delta[1], delta[3]

	print("Generating")

	local bx, by, bz = math.floor(x + dx * w), y - c - 1, math.floor(z + dz * h)
	hollowBlock(bx, by, bz, w, c, h, 3)

	-- Beacon base
	fill(bx, by - 3, bz, bx + w + 1, by - 3, bz + h + 1, "minecraft:iron_block")

	-- Modem
	setBlock(x - delta[2], y, z - delta[4], "computercraft:advanced_modem", facing)

	sleep(0.5)
	print("Done!")

	return {
		level = 1,
		build = { bx, by, bz },
		spawn = { bx + math.floor(w * 0.5), y, bz + math.floor(h * 0.5) },
	}
end
