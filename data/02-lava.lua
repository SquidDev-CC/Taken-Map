--[[
Lets start simple.
You need to get to the
exit.Without dying.

You should only need
6 characters to solve
this.
]]

function generate(world)
	world.setBlock(3, 3, "entrance")
	world.setBlock(15, 3, "exit")
--@start

--@stop
	world.setBlocks(5, 1, 13 - 5, world.height, "lava")
--@start

--@stop
end

function setup(world)
	world.setTitle("Chapter #2", "The floor is lava")
	world.setEnvironment("lab")
	--@start

	--@stop
end

function validate(world)
	assert.eq(1, world.count("exit"), "exit")
	assert.eq(1, world.count("entrance"), "entrance")
end
