local config = require "shared.config"
local command = require "server.command"

local summon = command.wrap "summon"
local kill = command.wrap "kill"

return {
	grass = { blocks = { "minecraft:grass" }, decorate = false, },
	water = { blocks = { "minecraft:water" }, decorate = false, },
	lava = { blocks = { "minecraft:lava" },   decorate = false, },

	wall = {
		blocks = {
			{ block = "minecraft:iron_bars", height = 2, offset = 1, },
		},
		decorate = true,
	},
	entrance = {
		decorate = true,
	},
	exit = {
		blocks = {
			{ block = "minecraft:beacon", offset = -1, },
			"minecraft:stained_glass 3",
		},
		decorate = false,
	},
	empty = { decorate = true, },
	mine = {
		decorate = true,
		hit = function(x, y)
			kill "@a"
			command.say("Boom!")
		end,
	},
	zombie = {
		build = function(x, y)
			-- Slightly OP. Eh.
			summon("Zombie", x, config.map.bottom + 1, y,[=[{Equipment:[{id:"diamond_sword",damage:0,ench:[{id:8,lvl:20}]},{},{},{},{id:"leather_helmet",damage:0}],Attributes:[{Name:generic.movementSpeed,Base:0.5},{Name:generic.attackDamage,Base:100}]}]=])
		end,
		decorate = true,
	},
	computer = {
		decorate = true,
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
