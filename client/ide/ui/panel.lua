--- Panel

local Window = require "client.ide.ui.window"
local Theme = require "client.ide.theme"

local term = term

--- A simple text panel to display some text, that pops up with a close button
local Panel = {}
Panel.__index = Panel

--- Create a new panel
function Panel.new(...)
	local self = setmetatable({}, Panel)
	self:setup(...)
	return self
end


--- Create an error panel.
function Panel.error(...)
	local panel = Panel.new()
	panel:center(...)
	panel:show()
end


function Panel:setup()
	self.lines = {}
	self.width = 0
end


function Panel:line(position, ...)
	local items = {...}
	if #items > 1 then
		for _, item in pairs(items) do
			self:line(position, item)
		end
	else
		local line = items[1]
		if #line + 4 > self.width then
			self.width = #line + 4
		end

		table.insert(self.lines, {["text"] = line, ["position"] = position})
	end
end


function Panel:center(...)
	self:line("center", ...)
end


function Panel:left(...)
	self:line("left", ...)
end


function Panel:right(...)
	self:line("right", ...)
end


function Panel:empty()
	self:line("left", "")
end

local function drawBorder(win, char, invert)
	if invert then
		win
			:setTextColor(Theme["panel background"])
			:setBackgroundColor(Theme["panel border"])
	else
		win
			:setTextColor(Theme["panel border"])
			:setBackgroundColor(Theme["panel background"])
	end

	win:write(char)
end


function Panel:show()
	self.height = #self.lines + 3

	local w, h = term.native().getSize()
	local x = math.floor(w / 2 - self.width / 2) + 1
	local y = math.floor(h / 2 - self.height / 2)
	local win = Window.new(x, y, self.width, self.height)

	win
		:redirectToParent()
		:setCursorBlink(false)

	win
		:setBackgroundColor(Theme["panel background"])
		:clear()

	-- Close button
	win
		:setCursorPos(1, 1)
		:setTextColor(Theme["panel close text"])
		:setBackgroundColor(Theme["panel close background"])
		:clearLine()
		:write("x")

	win:setCursorPos(1, 2) drawBorder(win, "\149", false)
	win:setCursorPos(self.width, 2) drawBorder(win, "\149", true)

	-- Lines
	for i, line in pairs(self.lines) do
		win:setCursorPos(1, i + 2)
		drawBorder(win, "\149", false)

		win
			:setTextColor(Theme["panel text"])
			:setBackgroundColor(Theme["panel background"])

		local x = 3
		if line.position == "center" then
			x = math.floor(self.width / 2 - #line.text / 2) + 1
		elseif line.position == "right" then
			x = self.width - #line.text - 1
		end

		win:setCursorPos(x, i + 2):write(line.text)

		win:setCursorPos(self.width, i + 2)
		drawBorder(win, "\149", true)
	end

	win:setCursorPos(1, self.height)
		:setTextColor(Theme["panel background"])
		:setBackgroundColor(Theme["panel border"])
		:write("\138" .. ("\143"):rep(self.width - 2) .. "\133")

	-- Wait for a click on the close button or outside the panel
	while true do
		local event = {os.pullEventRaw()}

		if event[1] == "terminate" then
			os.queueEvent("exit")
			break
		elseif event[1] == "mouse_click" then
			local cx = event[3]
			local cy = event[4]
			if cx == x and cy == y then
				break
			else
				local horizontal = cx < x or cx >= x + self.width
				local vertical = cy < y or cy >= y + self.height
				if horizontal or vertical then
					break
				end
			end
		end
	end
end

return Panel
