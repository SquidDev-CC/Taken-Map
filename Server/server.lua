--[[
rednet.open("back")

rednet.send(Config.Editor.Id, {
	Action = 'Files',
	Files = files
})

while true do
	local id, data = rednet.receive()
	if id == Config.Editor.Id then
		if data.Action == "Reset" then
			rednet.send(Config.Editor.Id, {
				Action = 'Files',
				Files = files
			})
		elseif data.Action == "Execute" then
			local files = {}
			for _, file in pairs(data.Files) do

			end
		end
	end
end
]]

local x, y, z = commands.getBlockPosition()
local world = World(x + 8, y, z)

-- Setup world
world.setDimensions(10, 10)
world.setExit(10, 10)

sleep(1)

-- Setup items
world.setPlayer(0, 0)
world.addItem(5, 0, 5, Items.createItem(
	Config.BlockInfo.Pocket.Id,
	1,
	Computers.createPocket(0, "Someone's pocket", true)
))

local run = world.tick()
while run do
	parallel.waitForAny(function()
		os.pullEvent("char")
		run = false
	end, function()
		sleep(0.5)
		run = world.tick()
	end)
end

commands.execAsync("tp @a " .. x .. " " .. y + 1 .. " " .. z)

Builder.clear()
