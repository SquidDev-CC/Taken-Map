Options:Default "trace"

Sources:Main "editor.lua"
	:Depends {"Config", "IDE"}

Sources:File "../config.lua"
	:Name "Config"

Sources:File "LuaIDE/build/api.lua"
	:Name "IDE"

Tasks:Clean("clean", "build")
Tasks:Combine("combine", Sources, "build/editor.lua", {"clean"})
	:Verify()
Tasks:Minify("minify", "build/editor.lua", "build/editor.min.lua")
Tasks:CreateBootstrap("boot", Sources, "build/boot.lua", {"clean"})
	:Traceback()

Tasks:Task "build" {"minify", "boot"}
Tasks:Default "build"
