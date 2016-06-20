local map = require "shared.config".map

local w, h = map.width, map.height

local x, y, z

return {
	-- Get the origin of the map.
	-- The y coordinate is 3 above the absolute base
	get = function()
		if not x then error("Positions have not been set") end
		return x, y, z
	end,

	setup = function(config)
		if x then error("Positions have already been set") end
		if config then
			x = config.x
			y = config.y
			z = config.z
		else
			x, y, z = commands.getBlockPosition()
			local facing = commands.getBlockInfo(x, y, z).state.facing
			if facing == "west" then
				x = x + 1
			elseif facing == "east" then
				x = x - w - 1
			elseif facing == "north" then
				z = z + 1
			elseif facing == "south" then
				z = z - h - 1
			else
				error("Unknown direction " .. tostring(facing))
			end
		end

		return x, y, z
	end,
}
