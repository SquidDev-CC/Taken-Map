--[[
You love em really.
]]

function generate(world)
	world.setBlock(2, 2, "entrance")
	world.setBlock(15, 3, "exit")
	local blacklist = {{2, 2}, {15, 3}}
	helpers.distribute(world, 200, "mine", blacklist)
--@start

--@stop
end

function setup(world)
	world.setTitle("Chapter #7", "MINEcraft!")
	world.setEnvironment("plain")
	--@start

	--@stop
end

function validate(world)
	assert.eq(1, #world.find("exit"), "exit")
	assert.eq(1, #world.find("entrance"), "entrance")
end
