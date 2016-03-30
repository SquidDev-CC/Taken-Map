return {
	lab = {
		base = "minecraft:quartz_block",
		setup = function() end,
	},

	plain = {
		base = "minecraft:grass",
		setup = function(builder, map)
			local depth = 7
			-- Lazy man's simplex noise :p.
			for x = 1, map.width do
				local sin = math.sin((x + math.random(0, 2))/ depth * math.pi / 3)
				local min = math.floor(math.abs(sin) * depth) + math.random(0, 2)
				for y = -min, 0 do
					builder[x][2][y + map.height] = "minecraft:water"
				end
			end
		end,
	}
}
