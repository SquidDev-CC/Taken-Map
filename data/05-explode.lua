--[[
Lookout for the mines.
]]

function generate(world)
	world.setBlock(2, 2, "entrance")
	world.setBlock(15, 3, "exit")

	for i = 0, 200 do
		local x = math.random(1, world.width)
		local y = math.random(1, world.height)

		-- Prevent overwriting entrance
		if (x ~= 2 or y ~= 2) and (x ~= 15 or y ~= 3) then
			world.setBlock(x, y, "mine")
--@start

--@stop
		end
	end
end

function setup(world)
	world.setTitle("Chapter #5", "Heavy explosives")
	world.setEnvironment("lab")
	--@start

	--@stop
end

function validate(world)
	assert.lt(80, world.count("mine"), "mines")
	assert.eq(1, world.count("exit"), "exit")
	assert.eq(1, world.count("entrance"), "entrance")
end
