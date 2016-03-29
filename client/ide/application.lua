--- Main LuaIDE bootstrapper

local Controller = require "client.ide.controller"

local term = term

local VERSION = "2.0"

local originalTerminal = term.current()
-- term.redirect(term.native())

local controller = Controller.new()
local current = controller.tabBar:current()

current:open("Something", {
	"for i = 0, 10 do",
	"  print('HELLO')",
	"end",
	"-- Insert code here",
	"print('Hello')",
})
current.editor:setReadOnly(true, 1, 3)
current.editor:setReadOnly(true, 5)

controller.tabBar:create()
current = controller.tabBar.contentManager.contents[2]

current:open("Another", {
	"-- Hello!",
	"error('Evil code')",
	"-- Well, that worked",
})
current.editor:setReadOnly(true, 2)

local buffer = {
	"for i = 0, 10 do",
	"  print('HELLO')",
	"end",
	"-- Insert code here",
	"print('Hello')",
	"",
}

local len = #buffer
for _ = 1, 5 do
	for i = 1, len do
		buffer[#buffer + 1] = buffer[i]
	end
end

controller.tabBar:create()
current = controller.tabBar.contentManager.contents[3]
current:open("Long", buffer)

controller:run()

term.redirect(originalTerminal)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
