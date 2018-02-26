local commands = require "server.commands"
local map = require "shared.config".map
local map_x, map_y, map_z = require "server.origin".get()
local player = require "server.player"

local top, bottom = map_y + map.ceiling - 1, map_y

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
			builder[x][height + 2][y] = "minecraft:stained_glass 1"
		end,
		args = function(height)
			if type(height) ~= "number" then error("Bad argument #4, expected number, got " .. type(height), 3) end
			if height < 0 or height > map.ceiling then
				error("Height is out of range", 3)
			end

			return height
		end,
		decorate = false,

		-- TODO: Implement something more sensible
		overwrite = function(cb, ca, nb, na) return cb == nb end,
	},
	gate = {
		build = function(x, y, builder, num, col)
			builder[x][2][y] = "minecraft:wool " .. num
		end,
		hit = function(x, y, player, num, col)
			if player.getState() ~= col then
				player.kill()
				commands.say("You're not " .. col)
			end
		end,
		args = getColor,
		decorate = false,
		overwrite = function(cb, ca, nb, na) return cb == nb end,
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
			player.kill()
			commands.say("Boom!")
		end,
	},
	zombie = {
		build = function(x, y)
			-- Slightly OP. Eh.
			-- Movement Speed: 0.5
			-- Damage: 100
			-- Leather cap, Protection 20
			-- Diamond sword, Sharpness 20
			commands.async.summon("minecraft:zombie", map_x + x, bottom, map_z + y,[=[{Attributes:[{Name:"generic.movementSpeed",Base:0.5},{Name:"generic.attackDamage",Base:100}],HandItems:[{id:"minecraft:diamond_sword",tag:{ench:[{id:16,lvl:20}]},Count:1},{}],ArmorItems:[{},{},{},{id:"minecraft:leather_helmet",Count:1,tag:{ench:[{id:8,lvl:20}]}}]}]=])
		end,
		decorate = true,
	},
	computer = {
		decorate = true,
		build = function(x, y)
			commands.async.summon(
				"Item", map_x + x, bottom, map_z + y,
				{
					Age = -32768, -- No despawn
					Item = {
						id = "computercraft:pocket_computer",
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
