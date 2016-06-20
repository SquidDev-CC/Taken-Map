local config = require "shared.config"
local command = require "server.command"
local mX, mY, mZ = require "server.position".get()

local summon = command.wrap "summon"
local kill = command.wrap "kill"
local top, bottom = mY + config.map.ceiling - 1, mY

local function getColor(color)
	if color == "red" then return 14, color
	elseif color == "green" then return 5, color
	elseif color == "blue" then return 11, color
	else error("Unknown color: " .. tostring(color), 2) end
end

return {
	empty = {                                 decorate = true,  overwrite = true, },
	-- Decoration style blocks
	grass = { blocks = { "minecraft:grass" }, decorate = false, overwrite = true, },

	-- Useful blocks
	lava  = { blocks = { "minecraft:lava" },  decorate = false, },
	platform = {
		build = function(x, y, builder, height)
			print("Pos", x, height + 2, y)
			builder[x][height + 2][y] = "minecraft:stained_glass 1"
		end,
		args = function(height)
			if type(height) ~= "number" then error("Bad argument #4, expected number, got " .. type(height), 3) end
			if height < 0 or height > config.map.ceiling then
				error("Height is out of range", 3)
			end

			return height
		end,
		decorate = false,
	},

	gate = {
		build = function(x, y, builder, num, col)
			builder[x][2][y] = "minecraft:wool " .. num
		end,
		hit = function(x, y, player, num, col)
			if player.getState() ~= col then
				kill("@a")
				command.say("You're not " .. col)
			end
		end,
		args = getColor,
		decorate = false,
	},

	dye = {
		build = function(x, y, builder, num, col)
			builder[x][2][y] = "minecraft:stained_glass " .. num
		end,
		hit = function(x, y, player, num, col)
			player.setState(col)
		end,
		args = getColor,
		decorate = false,
		overwrite = true,
	},

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
			summon("Zombie", mX + x, bottom, mZ + y,[=[{Attributes:[{Name:generic.attackDamage,Base:100},{Name:generic.movementSpeed,Base:0.5}],Equipment:[{id:"diamond_sword",damage:0,ench:[{id:8,lvl:20}]},{},{},{},{id:"leather_helmet",damage:0,ench:[{id:16,lvl:20}]}],Invulnerable:1,ActiveEffects:[{Id:17,Amplifier:"",Duration:"",ShowParticles:0b}]}]=])
		end,
		decorate = true,
	},
	computer = {
		decorate = true,
		build = function(x, y)
			summon(
				"Item", mX + x, bottom, mY + y,
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
							computerID = os.getComputerID(),
							upgrade = 1,
						}
					}
				}
			)
		end,
	},
}
