--[[
Lets start simple.
You need to get to the
exit.Without dying.

You should only need
6 characters to solve
this.
]]

function generate(world)
	world.setTitle("Chapter #2", "The floor is lava")
	world.setBlock(3, 3, "entrance")
	world.setBlock(15, 3, "exit")
--@start

--@stop
	for x = 1, world.width do
		world.setBlock(9, x, "lava")
		world.setBlock(10, x, "lava")
		world.setBlock(11, x, "lava")
		world.setBlock(12, x, "lava")
		world.setBlock(13, x, "lava")
	end
--@start

--@stop
end

function validate(world)
	assert.eq(1, #world.find("exit"), "exit")
	assert.eq(1, #world.find("entrance"), "entrance") 
end
