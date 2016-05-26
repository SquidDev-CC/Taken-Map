local position = require "server.position"
local sandbox = require "server.sandbox"
local command = require "server.command"
local setup = require "server.setup"

local levels
do
	local success
	success, levels = pcall(require, "levels")
	if not success then
		local loader = require "server.loader"
		local dir = fs.combine(fs.getDir(shell.getRunningProgram()), "data")
		levels = loader(dir)
	end
end

commands.async.scoreboard("objectives add gamemode dummy gamemode")
commands.async.scoreboard("players", "reset", "@a")
commands.async.scoreboard("players", "set", "@a", "gamemode", "0")

if not fs.exists(".taken") then
	print("No dump file found. Generate world? [y/n]")
	local result
	while result == nil do
		local _, contents = os.pullEvent("char")
		contents = contents:lower()
		if contents == "y" or contents == "yes" then
			result = true
		elseif contents == "n" or contents == "no" then
			result = false
		else
			print("Please enter y or n (got " .. contents .. ")")
		end
	end

	position.setup()

	if result then
		setup()
	end

	do return end
else
	local handle = fs.open(".taken", "r")
	local contents = handle.readAll()
	handle.close()

	local config = textutils.deserialize(contents)
	position.setup(config)
end

local network = require "shared.network"()

local level = tonumber(... or 1) or 1
while true do
	local levelFiles = levels[level] or error("No such level " .. level)
	network.send({
		action = "files",
		files = levelFiles,
	})

	local files = levelFiles

	local state = { active = true }
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
				commands.async.gamemode("spectator", "@a")
				commands.async.scoreboard("players", "set", "@a", "gamemode", "1")
				commands.async.execute("@p ~ ~ ~ summon ArmorStand ~ ~1 ~ {Invisible:1,Invulnerable:1,NoGravity:1,NoBasePlate:1}")
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
						command.sayError(message)
					end
				end,
				updateFiles
			)
		else
			command.sayError(result)
			if levelFiles == files then
				command.sayError "Quitting. We hit an error in the original source."
				error("Error in original source")
			else
				updateFiles()
			end
		end
	end
end
