local blocks = require "server.world.blocks"
local commands = require "server.commands"
local filler = require "server.world.filler"
local map = require "shared.config".map
local origin = require "server.origin"
local player = require "server.player"

local map_x, map_y, map_z = origin.get()
local spawn_x, spawn_y, spawn_z = origin.getSpawn()

local width, height, ceiling = map.width, map.height, map.ceiling
local top, bottom = map_y + map.ceiling - 1, map_y
local offset = 2

local function build(map)
	local mapData = map.data
	local world = filler.create(width, ceiling + offset + 1, height)

	map.env.setup(world, map)

	for x = 1, width do
		local mapRow = mapData[x]
		local worldRow = world[x]
		for z = 1, height do
			local blockData = mapRow[z]
			if blockData[2] then
				worldRow[offset][z] = blockData[2]
			end

			local block = blocks[blockData[1]]

			if block.build then
				block.build(x, z, world, unpack(blockData[3] or {}))
			elseif block.blocks then
				local blocks = block.blocks
				for i = 1, #blocks do
					local b = blocks[i]
					if type(b) == "string" then
						worldRow[offset][z] = b
					else
						local bOffset = offset + (b.offset or 0)
						for y = 1, b.height or 1 do
							worldRow[bOffset + y - 1][z] = b.block
						end
					end
				end
			end
		end
	end

	filler.optimise(world)
	filler.build(world, map_x, bottom - offset - 1, map_z)
end

local function tearDown(map)
	player.tp(spawn_x, spawn_y, spawn_z)
	commands.async.title(player.player_selector, "title", "Please stand by")
	commands.async.title(player.player_selector, "subtitle", "Splines are being reticulated")

	-- TODO: This should only kill within the bounds of the region
	commands.async.kill("@e[type=!Player,name=!taken_placeholder]")
	commands.async.kill("@e[type=!Player,name=!taken_placeholder]") -- Do it twice to clear items

	--- Reset the floor & clear the main area
	commands.async.fill(map_x + 1, bottom - 2, map_z + 1, map_x + width, bottom - 1, map_z + height, map.env.base)
	commands.async.fill(map_x + 1, bottom,     map_z + 1, map_x + width, top,        map_z + height, "minecraft:air")
end

local function setup(map)
	local entrance = map.entrance

	commands.async.gamemode("adventure", "@a[name=!SquidDev]") -- Am I evil? Yes.
	player.tp(map_x + entrance[1], bottom, map_z + entrance[2])
	commands.async.spawnpoint(player.player_selector, spawn_x, spawn_y, spawn_z)
	commands.async.title(player.player_selector, "title", {text=map.title})
	commands.async.title(player.player_selector, "subtitle", {text=map.subtitle})
end

return {
	tearDown = tearDown,
	build = build,
	setup = setup,
}
