return {
	lab = function(world)
		return "minecraft:quartz_block"
	end,

	plain = function(world)
		local depth = 7
		-- Lazy man's simplex noise :p.
		for x = 1, world.width do
			local sin = math.sin((x + math.random(0, 2))/ depth * math.pi / 3)
			local min = math.floor(math.abs(sin) * depth) + math.random(0, 2)
			for y = -min, 0 do
				world.setBlock(x, y + world.height, "water")
			end
		end
		return "minecraft:grass"
	end,
}
