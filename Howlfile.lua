Options:Default "trace"

local editor = Files()
	:Include "wild:client/*.lua"
	:Include "wild:shared/*.lua"
	:Startup "client/init.lua"

Tasks:Clean("clean", "build")

Tasks:AsRequire("editor", editor, "build/editor.lua")
Tasks:AsRequire("editorD", editor, "build/editorD.lua"):Link()

Tasks:Task "build" {"editor"}
Tasks:Default "build"
