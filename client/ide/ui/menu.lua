--- Menu Bar


local Window = require "client.ide.ui.window"
local Theme = require "client.ide.theme"

local term = term

local MenuBar = {}
MenuBar.__index = MenuBar

--- The y location of the menu bar.
MenuBar.y = 1

--- The duration in seconds to wait when flashing a menu item.
MenuBar.flashDuration = 0.1
MenuBar.clickDuration = 0.3

--- Items contained in the menu bar.
MenuBar.items = {
	{
		name = "\16 Run",
		id = "execute",
	},
	{
		name = "\248 Reset",
		id = "reset",
	},
	{
		name = "\2 Look",
		id = "spectate",
	},
	{
		name = "?",
		id = "help",
		["contents"] = {
			"Help",
			"About",
		},
	},
}


--- Create a new menu bar.
function MenuBar.new(...)
	local self = setmetatable({}, MenuBar)
	self:setup(...)
	return self
end


function MenuBar:setup()
	local w = term.getSize()
	self.win = Window.new(1, MenuBar.y, w, 1, term.native())
	self.flash = nil
	self.focus = nil
end


--- Draws a menu item.
function MenuBar:drawItem(window, item, flash)
	window
		:setBackgroundColor(Theme["menu dropdown background"])
		:clear()

	-- Render all the items
	for i, text in pairs(item.contents) do
		if i == flash then
			window
				:setTextColor(Theme["menu dropdown flash text"])
				:setBackgroundColor(Theme["menu dropdown flash background"])
		else
			window
				:setTextColor(Theme["menu dropdown text"])
				:setBackgroundColor(Theme["menu dropdown background"])
		end

		window
			:setCursorPos(3, i + 1)
			:clearLine()
			:write(text)
	end
end


--- Flashes an item when clicked, then draws it as focused.
function MenuBar:drawFlash(index)
	self.flash = index
	self:draw()
	sleep(MenuBar.flashDuration)
	self.flash = nil
	self.focus = index
	self:draw()
end

function MenuBar:drawClick(index)
	self.flash = index
	self:draw()
	sleep(MenuBar.clickDuration)
	self.flash = nil
	self.focus = nil
	self:draw()
end


--- Returns the width of the window to create for a particular item index.
function MenuBar:itemWidth(index)
	local item = self.items[index]
	local width = -1
	for _, text in pairs(item.contents) do
		if #text > width then
			width = #text
		end
	end
	width = width + 4

	return width
end


--- Opens a menu item, blocking the event loop until it's closed.
function MenuBar:open(index)
	-- Flash the menu item
	term.setCursorBlink(false)
	self:drawFlash(index)

	-- Window location
	local item = self.items[index]
	local x = self:itemLocation(index)
	local y = MenuBar.y + 1
	local height = #item.contents + 2
	local width = self:itemWidth(index)

	if x + width > self.win.width then
		x = self.win.width - width + 1
	end

	-- Create the window
	local win = Window.new(x, y, width, height, term.native())
	self:drawItem(win, item)

	-- Wait for a click
	while true do
		local event = {os.pullEventRaw()}

		if event[1] == "mouse_click" then
			local cx = event[3]
			local cy = event[4]

			if cy >= y and cy < y + height and cx >= x and cx < x + width then
				-- Clicked on the window somewhere
				if cy >= y + 1 and cy < y + height - 1 then
					-- Clicked on an item
					local index = cy - y
					self:drawItem(win, item, index)
					sleep(MenuBar.flashDuration)

					local text = item.contents[index]
					os.queueEvent("menu item trigger", text)
					break
				end
			else
				-- Close the menu item
				os.queueEvent("menu item close")
				break
			end
		end
	end

	self.focus = nil
end


--- Render the menu bar
--- Redirects the terminal to the menu bar's window
function MenuBar:draw()
	local win = self.win
	win
		:redirectToParent()
		:setBackgroundColor(Theme["menu bar background"])
		:setTextColor(Theme["menu bar text"])
		:clear()
		:setCursorPos(1, 1)

	for i, item in pairs(MenuBar.items) do
		if i == self.focus then
			win
				:setTextColor(Theme["menu bar text focused"])
				:setBackgroundColor(Theme["menu bar background focused"])
		elseif i == self.flash then
			win
				:setTextColor(Theme["menu bar flash text " .. item.id] or Theme["menu bar flash text"])
				:setBackgroundColor(Theme["menu bar flash background " .. item.id] or Theme["menu bar flash background"])
		else
			win
				:setTextColor(Theme["menu bar text " .. item.id] or Theme["menu bar text"])
				:setBackgroundColor(Theme["menu bar background " .. item.id] or Theme["menu bar background"])
		end

		win:write(" " .. item.name .. " ")
	end
end


--- Returns the min and max x location for a particular menu item.
--- Returns nil if the index isn't found.
function MenuBar:itemLocation(index)
	local minX = 1
	local maxX = -1

	for i, item in pairs(MenuBar.items) do
		maxX = minX + #item.name + 1
		if index == i then
			return minX, maxX
		end
		minX = maxX + 1
	end

	return nil
end


--- Called when a click event is received.
function MenuBar:click(x, y)
	if y == 1 then
		-- Determine the clicked item
		local minX = 1
		local maxX = -1

		for i, item in pairs(MenuBar.items) do
			maxX = minX + #item.name + 1
			if x >= minX and x <= maxX then

				-- Allow triggering inline menu options
				if item.contents then
					self:open(i)
				else
					os.queueEvent("menu item trigger", item.id)
					self:drawClick(i)
				end
				break
			end
			minX = maxX + 1
		end

		return true
	end
end


--- Called when an event is triggered on the menu bar
function MenuBar:event(event)
	if event[1] == "mouse_click" then
		return self:click(event[3], event[4])
	end

	return false
end

return MenuBar
