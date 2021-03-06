--[[
Insert Donald Trump
joke here.

They've caught on.
You can't just knock that
wall down, you'll have to
move it.
]]

function generate(world)
	world.setBlock(3, 3, "entrance")
	world.setBlock(15, 3, "exit")

--@start
	for x = 1, world.width do
		world.setBlock(9, x, "wall")
	end
--@stop
end

function setup(world)
	world.setTitle("Chapter #3", "Move that wall")
	world.setEnvironment("lab")
	--@start

	--@stop
end

function validate(world)
	assert.eq(world.width, world.count("wall"), "walls")
	assert.eq(1, world.count("exit"), "exit")
	assert.eq(1, world.count("entrance"), "entrance")
end
