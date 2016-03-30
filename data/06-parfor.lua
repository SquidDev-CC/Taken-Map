--[[
Have fun jumping
]]

local min = math.min
local max = math.max
function generate(world)
	world.setBlock(2, 2, "entrance")
	world.setBlock(world.height - 1, world.width - 1, "exit")

	world.setBlocks(world.height - 3, world.width - 3, 1, 4, "wall")
	world.setBlocks(world.height - 2, world.width - 3, 3, 1, "wall")

--@start

--@stop
	local x, y, height = 2, 2, 0
	while true do
		x = math.random(max(1, x - 1), min(world.width, x + 2))
		y = math.random(max(1, y - 1), min(world.height, y + 2))
		local low = height
		if low >= world.ceiling - 3 then low = 2 end
		height = math.random(low, min(world.ceiling - 3, height + 1))

		-- Prevent overwriting entrance
		if x == 2 and y == 2 then
		elseif x >= world.width - 3 and y >= world.height - 3 then
			break
		else
			world.setBlock(x, y, "platform", height)
		end
	end
end

function setup(world)
	world.setTitle("Chapter #6", "Parfor")
	world.setEnvironment("plain")
end

function validate(world)
	assert.eq(1, #world.find("exit"), "exit")
	assert.eq(1, #world.find("entrance"), "entrance")
end
