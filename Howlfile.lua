Options:Default "trace"

local client = Files()
	:Include "wild:client/*.lua"
	:Include "wild:shared/*.lua"
	:Startup "client/init.lua"

local server = Files()
	:Include "wild:server/*.lua"
	:Include "wild:shared/*.lua"
	:Startup "server/init.lua"

Tasks:Clean("clean", "build")

local config = dofile(File "shared/config.lua")
Tasks:AsRequire("client", client, "build/" .. config.clientId .. "/startup")
Tasks:AsRequire("server", server, "build/" .. config.serverId .. "/startup")
Tasks:AddTask("data", {}, function()
	fs.copy(File "data", File("build/" .. config.serverId .. "/data"))
end):Description "Copy levels to output folder"

Tasks:Task "build" {"clean", "client", "server", "data"}
Tasks:Default "build"
