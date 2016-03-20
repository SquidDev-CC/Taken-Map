local config = require "shared.config"
local command = require "server.command".wrap

local setBlock = command "setblock"
local summon = command("summon", true)
local kill = command "kill"

return {
	lava = {
		block = "minecraft:lava",
		height = 1,
		offset = 0,
		decorate = false
	},
	wall = {
		block = "minecraft:iron_bars",
		height = 2,
		offset = 1,
		decorate = true,
	},
	entrance = {
		decorate = true,
	},
	exit = {
		deocrate = false,
		build = function(x, y)
			setBlock(x, config.map.bottom - 1, y, "minecraft:beacon")
			setBlock(x, config.map.bottom, y, "minecraft:stained_glass 3")
		end,
	},
	empty = {
		decorate = true,
	},
	mine = {
		block = "minecraft:stained_glass 2",
		hit = function(world)
			kill "@a"
		end,
	},
	zombie = {
		build = function(x, y)
			-- Slightly OP. Eh.
			summon("Zombie", x, config.map.bottom + 1, y,[=[{Equipment:[{id:"diamond_sword",damage:0,ench:[{id:8,lvl:20}]},{},{},{},{id:"leather_helmet",damage:0}],Attributes:[{Name:generic.movementSpeed,Base:0.5},{Name:generic.attackDamage,Base:100}]}]=])
		end
	},
	computer = {
		deocrate = true,
		build = function(x, y)
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
	},
}
