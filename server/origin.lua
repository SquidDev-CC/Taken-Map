--- Provides methods to get the origin of the map

local map = require "shared.config".map
local commands = require "server.commands"

-- Various information on how to build the system
local block = "minecraft:quartz_block"
local glass = "minecraft:stained_glass 3"
local air = "minecraft:air"
local below = 3

local w, h, c = map.width, map.height, map.ceiling

local deltas = {
	north = { -0.5,  0, -1,   -1 },
	south = { -0.5,  0,  0,    1 },
	east  = {  0,    1, -0.5,  0 },
	west  = { -1,   -1, -0.5,  0 },
}

local function hollowBlock(x, y, z, w, c, h)
	-- Walls
	commands.async.fill(x,         y, z,         x + w + 1, y + c, z,         block)
	commands.async.fill(x,         y, z,         x,         y + c, z + h + 1, block)
	commands.async.fill(x,         y, z + h + 1, x + w + 1, y + c, z + h + 1, block)
	commands.async.fill(x + w + 1, y, z,         x + w + 1, y + c, z + h,     block)

	-- Floor
	commands.async.fill(x, y - 2, z, x + w + 1, y - 1, z + h + 1, block)

	-- Middle
	commands.async.fill(x + 1, y, z + 1, x + w, y + c - 1, z + h, air)

	-- Glass Ceiling (last to avoid lag)
	commands.async.fill(x + 1, y + c, z + 1, x + w, y + c, z + h, glass)
end

-- Properties
local x, y, z
local spawn_x, spawn_y, spawn_z

return {
	--- Called on the intial setup
	setup = function(config)
		if x then error("Positions have already been set", 2) end

		-- Get the computer's position and some info on it,
		local cx, cy, cz = commands.getBlockPosition()
		local info = commands.getBlockInfo(cx, cy, cz)
		local facing = info.metadata

		local delta = deltas[info.state.facing]
		local dx, dz = delta[1], delta[3]

		local ox, oz = math.floor(dx * (w + 1)), math.floor(dz * (h + 1))
		local bx, by, bz = cx + ox, cy - c - 1, cz + oz
		hollowBlock(bx, by, bz, w, c, h)

		-- Beacon base
		commands.async.fill(bx, by - 3, bz, bx + w + 1, by - 3, bz + h + 1, "minecraft:iron_block")

		-- Modem
		commands.async.setBlock(cx - delta[2], cy, cz - delta[4], "computercraft:advanced_modem", facing)

		-- Load the properties and update the config
		x, y, z = bx, by, bz
		spawn_x, spawn_y, spawn_z = bx + math.floor(w * 0.5), cy, bz + math.floor(h * 0.5)

		config.build = { x, y, z }
		config.spawn = { spawn_x, spawn_y, spawn_z }
	end,

	--- Load information from config
	load = function(config)
		if x then error("Positions have already been set", 2) end

		x, y, z = table.unpack(config.build)
		spawn_x, spawn_y, spawn_z = table.unpack(config.spawn)
	end,

	--- Get the origin of the map.
	-- The y coordinate is 3 above the absolute base
	get = function()
		if not x then error("Positions have not been set", 2) end
		return x, y, z
	end,

	--- Get the respawn point of the map
	getSpawn = function()
		if not x then error("Positions have not been set", 2) end
		return spawn_x, spawn_y, spawn_z
	end,
}
