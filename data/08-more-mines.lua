--[[
You love em really.
]]

function generate(world)
	world.setBlock(2, 2, "entrance")
	world.setBlock(15, 3, "exit")
	local blacklist = {{2, 2}, {15, 3}}
	world.distribute(200, "mine", blacklist)
--@start

--@stop
end

function setup(world)
	world.setTitle("Chapter #8", "MINEcraft!")
	world.setEnvironment("plain")
	--@start

	--@stop
end

function validate(world)
	assert.eq(1, world.count("exit"), "exit")
	assert.eq(1, world.count("entrance"), "entrance")
end
