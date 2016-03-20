--[[
Three makes a
horde right?
]]

function generate(world)
	world.setTitle("Chapter #4", "Hordes of Zombies")
	world.setBlock(2, 2, "entrance")
	world.setBlock(15, 3, "exit")

--@start
	local count = 0
	while count < 3 do
		local x = math.random(5, world.width)
		local y = math.random(1, world.height)

		if x > 4 and y ~= 3 and x ~= 15 then
			world.setBlock(x, y, "zombie")
			count = count + 1
		end

	end

	for x = 1, 4 do
		world.setBlock(x, 4, "wall")
	end
	for y = 1, 3 do
		world.setBlock(4, y, "wall")
	end
--@stop
end

function validate(world)
	assert.eq(3, #world.find("zombie"), "zombies")
	assert.eq(1, #world.find("exit"), "exit")
	assert.eq(1, #world.find("entrance"), "entrance")
end
