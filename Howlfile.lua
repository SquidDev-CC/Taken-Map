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

Tasks:AsRequire("client", client, "build/client/startup")
Tasks:AsRequire("server", server, "build/server/startup")
Tasks:AddTask("data", {}, function()
	fs.copy(File "data", File "build/server/data")
end)

Tasks:Task "build" {"clean", "client", "server", "data"}
Tasks:Default "build"
