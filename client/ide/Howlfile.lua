Options:Default "trace"

Tasks:Clean("clean", "build")


Tasks:Minify("minify", "build/ide.lua", "build/ide.min.lua")
Tasks:CreateBootstrap("boot", Sources, "build/boot.lua", {"clean"})
	:Traceback()

Tasks:Task "api"({"clean"}, function()
	apiSource:Combiner("build/api.lua")
	Minify("build/api.lua")
end)
	:Description "Create extra build files"
	:Produces {"build/api.lua"}

Tasks:Task "build" {"minify", "api", "boot"}
Tasks:Default "build"
