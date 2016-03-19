--[[
Congratulations,
you've picked
up your computer.

 You now need to
head to the exit
(the beacon)
]]

function generate(world)
	world.setTitle("Chapter #1", "Getting started")
	world.setBlock(3, 3, "entrance")
	world.setBlock(7, 7, "computer")
	world.setBlock(10, 10, "exit")
end

function exit(player)
	if not player.hasComputer() then
		error("Player must have the computer")
	end
end
