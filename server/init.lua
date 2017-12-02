local origin = require "server.origin"
local player = require "server.player"
local commands = require "server.commands"

--- Load all our levels
local levels
do
	local loader = require "server.level.loader"
	local dir = fs.combine(fs.getDir(shell.getRunningProgram()), "data")
	levels = loader(dir)
end

local modules = { commands, origin, player }

local config
if not fs.exists(".taken") then
	print("No dump file found. Generate world? [y/n]")
	local result
	while result == nil do
		local _, contents = os.pullEvent("char")
		contents = contents:lower()
		if contents == "y" then
			result = true
		elseif contents == "n" then
			result = false
		else
			print("Please enter y or n (got " .. contents .. ")")
		end
	end

	if not result then return end

	config = { }
	for i = 1, #modules do modules[i].setup(config) end
	sleep(0.5) -- Wait for setup functions to complete

	local handle = assert(fs.open(".taken", "w"))
	handle.write(textutils.serialize(config))
	handle.close()
else
	local handle = fs.open(".taken", "r")
	local contents = handle.readAll()
	handle.close()

	config = textutils.unserialize(contents)

	for i = 1, #modules do modules[i].load(config) end
end

local network = require "shared.network"()
local sandbox = require "server.level.runner"

local level = config.level or 1
while true do
	local levelFiles = levels[level]
	if not levelFiles then
		commands.sayError("No such level " .. level)
		error("No such level " .. level)
	end

	network.send({
		action = "files",
		files = levelFiles,
	})

	local files = levelFiles

	local state = { active = true }
	local function updateFiles()
		local x, y, z = commands.getBlockPosition()
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
				player.startSpectating()
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
						commands.sayError(message)

						if levelFiles == files then
							commands.sayError "Quitting. We hit an error in the original source."
							error("Error in original source")
						end
					end
				end,
				updateFiles
			)
		else
			commands.sayError(result)
			if levelFiles == files then
				commands.sayError "Quitting. We hit an error in the original source."
				error("Error in original source")
			else
				updateFiles()
			end
		end
	end

	local handle = fs.open(".taken", "w")
	config.level = level
	handle.write(textutils.serialize(config))
	handle.close()
end
