Options:Default "trace"

Sources:Main "server.lua"
	:Depends "Config"

Sources:File "../config.lua"
	:Name "Config"

local apiSource = Sources:CloneDependencies():Export(true)

Tasks:Clean("clean", "build")
Tasks:Combine("combine", Sources, "build/server.lua", {"clean"})
	:Verify()
Tasks:Minify("minify", "build/server.lua", "build/server.min.lua")
Tasks:CreateBootstrap("boot", Sources, "build/boot.lua", {"clean"})
	:Traceback()

Tasks:Task "build" {"minify", "boot"}
Tasks:Default "build"
