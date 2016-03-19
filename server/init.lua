local map = require "server.world.map"
local builder = require "server.world.builder"

local world = map()

for x = 1, world.width do
	world.setBlock(9, x, "lava")
	world.setBlock(10, x, "lava")
	world.setBlock(11, x, "lava")
	world.setBlock(12, x, "lava")
	world.setBlock(13, x, "lava")
end

world.setTitle("Chapter #1", "The floor is lava")
world.setBlock(3, 3, "entrance")
world.setBlock(5, 3, "computer")
world.setBlock(15, 3, "exit")

local map = world.setup()
builder.clear()
sleep(0.5)
builder.build(map)
sleep(0.5)
builder.setup(map)
