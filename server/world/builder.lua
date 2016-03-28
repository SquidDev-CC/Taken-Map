local config = require "shared.config"
local blocks = require "server.world.blocks"
local filler = require "server.world.filler"
local command = require "server.command".wrap

local kill = command "kill"
local fill = command "fill"
local tp = command "tp"
local gamemode = command "gamemode"
local title = command "title"

local width, height = config.map.width, config.map.height
local top, bottom = config.map.top, config.map.bottom
local offset = 2

local function build(map)
	local mapData = map.data
	local world = filler.create(width, top - bottom + offset, height)

	for x = 1, width do
		local mapRow = mapData[x]
		local worldRow = world[x]
		for z = 1, height do
			local block = blocks[mapRow[z]]
			if block.build then
				block.build(x, z)
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
	filler.build(world, 0, bottom - offset, 0)
end

local function clear()
	kill("@e[type=!Player]")
	tp("@a", 2, config.map.top + 2, -2)
	fill(1, config.map.bottom - 1, 1, width, config.map.bottom, height, "minecraft:quartz_block")
	fill(1, config.map.bottom + 1, 1, width, config.map.top, height, "minecraft:air")
end

local function setup(map)
	local entrance = map.entrance

	gamemode("adventure", "@a[name=!ThatVeggie]")
	tp("@a", entrance[1], config.map.bottom + 1, entrance[2])
	title("@a", "title", {text=map.title})
	title("@a", "subtitle", {text=map.subtitle})
end

return {
	build = build,
	clear = clear,
	setup = setup,
}
