--[[
Be warned! The wool bites!
]]

function generate(world, player)
	world.setBlock(2, 2, "entrance")
	world.setBlock(20, 3, "exit")
	player.showState(true)
--@start

--@stop
	world.setBlocks(3, 1, 1, world.height, "dye", "red")

	world.line(10, 1, 5, world.height, "gate", "green")
	world.line(14, 1, world.width, 6, "gate", "green")
	world.line(4, 1, 20, world.height, "gate", "red")
	world.line(16, 1, 7, world.height, "gate", "blue")
end

function setup(world)
	world.setTitle("Chapter #7", "All the colours of the rainbow")
	world.setEnvironment("plain")
end

function validate(world)
	assert.lt(30, #world.find("gate", "gates"))
	assert.eq(1, #world.find("exit"), "exit")
	assert.eq(1, #world.find("entrance"), "entrance")
end
