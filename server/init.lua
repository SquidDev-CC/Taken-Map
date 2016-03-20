local sandbox = require "server.sandbox"
local config = require "shared.config"
local command = require "server.command".wrap
local network = require "shared.network"(config.clientId)
local levels = require "server.loader"

local tellraw = command("tellraw")
local function sayError(message)
	printError(message)
	tellraw("@a", {"",{text=message,color="red"}})
end

local level = tonumber(... or 1) or 1
while true do
	local levelFiles = levels[level] or error("No such level " .. level)
	network.send({
		action = "files",
		files = levelFiles,
	})

	local files = levelFiles

	local function updateFiles()
		while true do
			local data = network.receive()
			if data.action == "execute" then
				files = data.files
				return
			elseif data.action == "startup" then
				network.send({
					action = "files",
					files = levelFiles,
				})
			elseif data.action == "spectate" then
				commands.gamemode("spectator", "@a")
				commands.execute("@p ~ ~ ~ summon ArmorStand ~ ~1 ~ {Invisible:1,Invulnerable:1,NoGravity:1,NoBasePlate:1}")
				commands.native.execAsync([=[tellraw @a ["",{"text":"You are in Spectator mode "},{"text":"[Resume]","color":"dark_green","clickEvent":{"action":"run_command","value":"/setblock -5 64 0 minecraft:redstone_block"}}]]=])
			end
		end
	end

	local running = true
	while running do
		local success, result = pcall(sandbox, files)
		if success then
			parallel.waitForAny(
				function()
					local success, message = pcall(result)
					if success then
						level = level + 1
						running = false
					else
						sayError(message)
					end
				end,
				updateFiles
			)
		else
			sayError(result)
			if levelFiles == files then
				sayError "Quitting. We hit an error in the original source."
				error("Error in original source")
			else
				updateFiles()
			end
		end
	end
end
