Options:Default "trace"

Sources:Main "server.lua"
	:Depends {"Config", "World"}
	:Depends {"Items", "Computers"}

Sources:File "../config.lua"
	:Name "Config"

Sources:File "utils.lua"
	:Name "Utils"

Sources:File "world/builder.lua"
	:Name "Builder"

Sources:File "world/builder.lua"
	:Name "Builder"

Sources:File "world/items.lua"
	:Name "Items"

Sources:File "world/computers.lua"
	:Name "Computers"

Sources:File "world/world.lua"
	:Name "World"
	:Depends {"Builder", "Items", "Utils"}

Tasks:Clean("clean", "build")
Tasks:Combine("combine", Sources, "build/server.lua", {"clean"})
	:Verify()
Tasks:Minify("minify", "build/server.lua", "build/server.min.lua")
Tasks:CreateBootstrap("boot", Sources, "build/boot.lua", {"clean"})
	:Traceback()

Tasks:Task "build" {"minify", "boot"}
Tasks:Default "build"
