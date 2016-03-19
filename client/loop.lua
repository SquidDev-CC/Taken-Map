local editor = require "client.editor"
local config = require "shared.config"
local network = require "shared.network"(config.serverId)

local files = {
	{
		name = "Welcome!",
		lines = {
			"--[[",
			" Welcome to Taken",
			"",
			" This is some",
			" placeholder text whilst",
			" the main server starts",
			" up, please be patient",
			"--]]",
		},
		writable = { }
	},
}

editor.setFiles(files)
network.send({action = "startup"})

parallel.waitForAny(editor.run, function()
	while true do
		local data = network.receive()

		if data.action == "files" then
			files = data.files
			editor.setFiles(files)
		end
	end
end, function()
	while true do
		local event, name = os.pullEventRaw()
		if event == "menu item trigger" then
			if name == "reset" then
				editor.setFiles(files)
			elseif name == "execute" then
				network.send({
					action = "execute",
					files = editor.getFiles(),
				})
			elseif name == "spectate" then
				network.send({action = "spectate"})
			end
		end
	end
end)
