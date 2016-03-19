Options:Default "trace"

local editor = Files()
	:Include "wild:client/*.lua"
	:Include "config.lua"
	:Startup "client/wrapper.lua"

Tasks:Clean("clean", "build")

Tasks:AsRequire("editor", editor, "build/editor.lua")
Tasks:AsRequire("editorD", editor, "build/editorD.lua"):Link()

Tasks:Task "build" {"editor"}
Tasks:Default "build"
