local config = require "config"
local command = require "server.world.command"

local setBlock = command("setblock")
local summon = command("summon", true, true)

return {
	lava = {
		block = "minecraft:lava",
		height = 1,
		offset = 0,
	},
	wall = {
		block = "minecraft:iron_bars",
		height = 2,
		offset = 1,
	},
	marker = {
		block = "minecraft:carpet 14",
		height = 1,
		offset = 1,
	},
	entrance = true,
	exit = function(x, y)
		setBlock(x, config.map.bottom - 1, y, "minecraft:beacon")
		setBlock(x, config.map.bottom, y, "minecraft:stained_glass 3")
	end,
	empty = true,
	computer = function(x, y)
		summon(
			"Item", x, config.map.bottom + 1, y,
			{
				Age = -32768, -- No despawn
				Item = {
						id = "computercraft:pocketComputer",
						Damage = 1, -- Force advanced
						Count = 1,
						tag = {
							display = {
								Name = "Your computer"
							},
							computerID = assert(config.clientId),
							upgrade = 1,
						}
				}
			}
		)
	end,
}
