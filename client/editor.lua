local Controller = require "client.ide.controller"
local Config = require "config"

local controller = Controller.new()

function receive(sender)
	-- Wait for events
	while true do
		local eventName, id, message = os.pullEventRaw("rednet_message")
		if eventName == "rednet_message" then
			if sender == nil or sender == id then
				return id, message
			end
		end
	end
end

parallel.waitForAny(function()
	controller.tabBar:current():open("Welcome!", {
		"--[[",
		" Welcome to Trapped",
		"",
		" This is some",
		" placeholder text whilst",
		" the main server starts",
		" up, please be patient",
		"--]]",
	})
	controller:run()
end, function()
	rednet.open("back")
	while true do
		local sender, data = receive(Config.Server.Id)

		if data.Action == "Files" then
			local content = controller.tabBar
			local count = content:openCount()
			local index = 1

			for _, file in ipairs(data.Files) do
				if index > count then
					content:create(index)
				end

				local tab = content.contentManager.contents[index]
				tab:open(file.Name, file.Lines)

				-- Start with everything read only
				tab.editor:setReadOnly(true)
				for _, write in ipairs(file.Write) do
					tab.editor:setReadOnly(false, unpack(write))
				end

				index = index + 1
			end

			if index < count then
				for i = index + 1, count do
					content:close(index)
				end
			end
		end

		controller:draw()
	end
end, function()
	while true do
		local event = {os.pullEventRaw()}
		if event[1] == "menu item trigger" then
			local name = event[2]
			if name == "Reset" then
				rednet.send(Config.Server.Id, {
					Action = "Reset",
				})
			elseif name == "Execute" then
				local files = {}
				for _, file in pairs(controller.tabBar.contentManager.contents) do
					files[#files + 1] = {
						Name = file.path,
						Lines = file.editor.lines
					}
				end

				rednet.send(Config.Server.Id, {
					Action = "Execute",
					Files = files
				})
			end
		end
	end
end)
