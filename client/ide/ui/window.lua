--- A lightweight system for drawing text at an offset
-- Doesn't support scroll

local Window = {}
Window.__index = Window

function Window.new(...)
	local self = setmetatable({}, Window)
	self:setup(...)
	return self
end

function Window:setup(x, y, width, height, redirect)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.redirect = redirect or term.native()
end

function Window:redirectToParent()
	term.redirect(self.redirect)
	term.setCursorBlink(false)
	return self
end

function Window:redirectTo()
	local redirect = {}
	for k, v in pairs(self.redirect) do
		local func = self[k:gsub("Colour", "Color")]
		if func then
			v = function(...)
				func(self, ...)
			end
		end

		redirect[k] = v
	end
	term.redirect(redirect)

	return self
end

function Window:setBackgroundColor(color)
	self.redirect.setBackgroundColor(color)
	return self
end

function Window:setTextColor(color)
	self.redirect.setTextColor(color)
	return self
end

function Window:setCursorBlink(blink)
	self.redirect.setCursorBlink(blink)
	return self
end

function Window:setCursorPos(x, y)
	self.redirect.setCursorPos(self.x + x - 1, self.y + y - 1)
	return self
end

function Window:clear()
	local clearLine = (" "):rep(self.width)
	local redirect = self.redirect
	local oldX, oldY = redirect.getCursorPos()
	local x = self.x

	for y = self.y, self.y + self.height - 1 do
		redirect.setCursorPos(x, y)
		redirect.write(clearLine)
	end
	redirect.setCursorPos(oldX, oldY)
	return self
end

function Window:clearLine()
	local redirect = self.redirect
	local oldX, oldY = redirect.getCursorPos()

	redirect.setCursorPos(self.x, oldY)
	redirect.write((" "):rep(self.width))
	redirect.setCursorPos(oldX, oldY)
	return self
end

function Window:write(text)
	self.redirect.write(text)
	return self
end

return Window
