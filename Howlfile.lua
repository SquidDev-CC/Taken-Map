Options:Default "trace"

local client = Files()
	:Include "wild:client/*.lua"
	:Include "wild:shared/*.lua"
	:Startup "client/init.lua"

local server = Files()
	:Include "wild:server/*.lua"
	:Include "wild:shared/*.lua"
	:Startup "server/init.lua"

Tasks:clean()

Tasks:asRequire "main" (function(source)
	source:include {
		"server/*.lua",
		"shared/*.lua",
		"client/*.lua",
		"init.lua",
	}

	source:exclude {
		"*/build/*",
		"Howlfile.lua",
	}

	source:from "build" :include "levels.lua"
	source:startup "init.lua"
	source:output "build/Taken.lua"
end):requires "build/levels.lua"

Tasks:AddTask("data", function()
	local runner = dofile(File "server/loader.lua")
	local contents = runner(File "data")
	local fs = require "howl.platform".fs
	local serialize = require "howl.lib.dump".serialise
	fs.write(File "build/levels.lua", "return " .. serialize(contents))
end)
	:Produces "build/levels.lua"

Tasks:Task "build" {"clean", "main" }
Tasks:Default "build"
