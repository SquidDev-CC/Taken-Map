local map = require "shared.config".map

local w, h = map.width, map.height

local x, y, z
local spawnX, spawnY, spawnZ

return {
	-- Get the origin of the map.
	-- The y coordinate is 3 above the absolute base
	get = function()
		if not x then error("Positions have not been set") end
		return x, y, z
	end,

	--- Get the respawn point of the map
	getSpawn = function()
		if not x then error("Positions have not been set") end
		return spawnX, spawnY, spawnZ
	end,

	setup = function(config)
		if x then error("Positions have already been set") end

		x, y, z = unpack(config.build)
		spawnX, spawnY, spawnZ = unpack(config.spawn)
	end,
}
