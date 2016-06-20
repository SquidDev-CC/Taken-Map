local config = require "shared.config"
local blocks = require "server.world.blocks"
local filler = require "server.world.filler"
local command = require "server.command".wrap
local mX, mY, mZ = require "server.position".get()

local kill = command "kill"
local fill = command "fill"
local tp = command "tp"
local spawnpoint = command "spawnpoint"
local gamemode = command "gamemode"
local title = command "title"

local width, height = config.map.width, config.map.height
local top, bottom = mY + config.map.ceiling - 1, mY
local spawnOffset = config.map.spawnOffset
local buildOffset = config.map.buildOffset
local offset = 2

local function build(map)
	local mapData = map.data
	local world = filler.create(width, config.map.ceiling + offset + 1, height)

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
	filler.build(world, mX, bottom - offset - 1, mZ)
end

local function clear(map)
	kill("@e[type=!Player]")
	spawnpoint("@a", mX + buildOffset[1], bottom, mZ + buildOffset[2])
	fill(mX + 1, bottom - 2, mZ + 1, mX + width, bottom - 1, mZ + height, map.env.base)
	fill(mX + 1, bottom,     mZ + 1, mX + width, top,        mZ + height, "minecraft:air")
end

local function setup(map)
	local entrance = map.entrance

	gamemode("adventure", "@a[name=!ThatVeggie]")
	tp("@a", mX + entrance[1], bottom, mZ + entrance[2])
	spawnpoint("@a", mX + spawnOffset[1], bottom, mZ + spawnOffset[2])
	title("@a", "title", {text=map.title})
	title("@a", "subtitle", {text=map.subtitle})
end

return {
	build = build,
	clear = clear,
	setup = setup,
}
