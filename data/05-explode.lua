--[[
Lookout for the mines.
]]

function generate(world)
	world.setTitle("Chapter #5", "Heavy explosives")
	world.setBlock(2, 2, "entrance")
	world.setBlock(15, 3, "exit")

--@start
	for i = 0, 100 do
		local x = math.random(5, world.width)
		local y = math.random(1, world.height)

		-- Prevent overwriting entrance
		if (x ~= 2 or y ~= 2) and (x ~= 15 and y ~= 3) then
			world.setBlock(x, y, "mine")
		end
	end
--@stop
end

function validate(world)
	assert.lt(40, #world.find("mine"), "mines")
	assert.eq(1, #world.find("exit"), "exit")
	assert.eq(1, #world.find("entrance"), "entrance")
end
