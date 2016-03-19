-- local map = require "server.world.map"
-- local builder = require "server.world.builder"
local config = require "config"
local loader = require "server.loader"
local network = require "server.network"

local levelDir = fs.combine(fs.getDir(shell.getRunningProgram()), "data")
print("Using directory: " .. levelDir)

local levels = fs.list(levelDir)
table.sort(levels)

local level = 1
while true do
	local levelName = levels[level] or error("No such level " .. level)
	local contents = loader(fs.combine(levelDir, levelName), levelName)

	network.send({
		action = "files",
		files = { contents }
	})

	local data = network.receive()
	if data.action == "execute" then
		level = level + 1
	elseif data.action == "startup" then
		level = 1
	end
end
