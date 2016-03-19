--- The main controller class

local MenuBar = require "client.ide.ui.menu"
local ContentTabLink = require "client.ide.ui.tab"
local Responder = require "client.ide.ui.responder"
local Theme = require "client.ide.theme"

local setmetatable, term = setmetatable, term

--- The main controller, handles events and delegates things
-- @type
local Controller = {}
Controller.__index = Controller

--- Create a new controller object.
-- @treturn Controller
function Controller.new()
	local self = setmetatable({}, Controller)

	term.setBackgroundColor(colors.black)
	term.clear()

	Theme.load()

	self.menuBar = MenuBar.new()
	self.tabBar = ContentTabLink.new()
	self.responder = Responder.new(self)

	return self
end

--- Draw the whole IDE.
function Controller:draw()
	self.menuBar:draw()
	self.tabBar:draw()
end


--- Run the main loop.
function Controller:run()
	self:draw()

	while true do
		local event = {os.pullEventRaw()}
		local cancel = false

		-- Trigger a redraw so we can close the menu before displaying any menu items, etc.
		if event[1] == "menu item close" or event[1] == "menu item trigger" then
			self:draw()
		end

		if event[1] == "menu item trigger" and not cancel then
			cancel = self.responder:trigger(event[2])

			-- If some event was triggered, then redraw fully
			if cancel then
				self:draw()
			end
		end

		if not cancel then
			cancel = self.menuBar:event(event)
		end

		if not cancel then
			cancel = self.tabBar:event(event)
		end

		self.tabBar:current():restoreCursor()
	end
end

return Controller
