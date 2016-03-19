--- One tab of content

local Buffer = require "client.ide.ui.buffer"
local Editor = require "client.ide.editor.editor"
local SyntaxHighlighter = require "client.ide.editor.highlighter"
local Theme = require "client.ide.theme"

local term = term

--- A content window for each tab.
-- Responsible for rendering the editor.
-- @type
local Content = {}
Content.__index = Content

--- The starting y position of the tab.
Content.startY = 3

--- The width of a tab in spaces
Content.tabWidth = 2

--- Create a new content window.
function Content.new(...)
	local self = setmetatable({}, Content)

	local w, h = term.native().getSize()
	self.height = h - Content.startY + 1
	self.width = w
	self.win = Buffer(term.native(), 1, Content.startY, self.width, self.height, false)
	self.editor = Editor.new({""}, self.width, self.height)
	self.path = nil
	self.highlighter = SyntaxHighlighter.new()
	self:updateSyntaxHighlighting("")

	return self
end

--- Open a set of lines
function Content:open(path, lines)
	self.path = path
	self.editor = Editor.new(lines, self.width, self.height)
	self:updateSyntaxHighlighting("")
end

--- Returns the name of the file being edited.
function Content:name()
	if not self.path then
		return "untitled"
	else
		return fs.getName(self.path)
	end
end

--- Returns true if the content is unedited
function Content:isUnedited()
	return self.path == nil and #self.editor.lines == 1 and #self.editor.lines[1] == 0
end

--- Shows the content window's window, redrawing it over the existing screen space
--- and restoring the cursor to its original position in the window.
function Content:show()
	term.redirect(self.win.redirect)
	self.win.setVisible(true)
	self:draw()
	self:restoreCursor()
end


--- Hides the window.
function Content:hide()
	self.win.setVisible(false)
end


--- Sets the cursor position to that defined by the editor.
function Content:restoreCursor()
	local x, y = self.editor:cursorPosition()

	term.redirect(self.win.redirect)
	term.setCursorPos(x, y)
	if self.editor:isReadOnly(y + self.editor.scroll.y) then
		term.setTextColor(Theme["editor readonly"][Theme["editor text"]])
	else
		term.setTextColor(Theme["editor text"])
	end
	term.setCursorBlink(true)
end


--- Renders a whole line - gutter and text.
--- Does not redirect to the terminal.
function Content:drawLine(y)
	if self.editor:isReadOnly(y + self.editor.scroll.y) then
		term.setBackgroundColor(Theme["editor readonly"][Theme["editor background"]])
	else
		term.setBackgroundColor(Theme["editor background"])
	end
	term.setCursorPos(1, y)
	term.clearLine()
	self:drawText(y)
	self:drawGutter(y)
end


--- Renders the gutter on a single line.
function Content:drawGutter(y)
	local text, color
	local back
	if y == self.editor.cursor.y then
		back = Theme["gutter background focused"]
		term.setTextColor(Theme["gutter text focused"])
	else
		back = Theme["gutter background"]
		term.setTextColor(Theme["gutter text"])
	end
	term.setBackgroundColor(back)

	local size = self.editor:gutterSize()
	local lineNumber = tostring(y + self.editor.scroll.y)
	local padding = string.rep(" ", size - #lineNumber - 1)
	lineNumber = padding .. lineNumber
	term.setCursorPos(1, y)
	term.write(lineNumber)

	term.setTextColor(back)
	if self.editor:isReadOnly(y + self.editor.scroll.y) then
		term.setBackgroundColor(Theme["editor readonly"][Theme["editor background"]])
	else
		term.setBackgroundColor(Theme["editor background"])
	end
	term.write(Theme["gutter separator"])
end


--- Renders the text for a single line.
function Content:drawText(y)
	local absoluteY = y + self.editor.scroll.y
	local data = self.highlighter:data(absoluteY, self.editor.scroll.x, self.width)

	local isReadOnly = self.editor:isReadOnly(absoluteY)

	-- Map colours for readonly
	if isReadOnly then
		term.setBackgroundColor(Theme["editor readonly"][Theme["editor background"]])
		term.setTextColor(Theme["editor readonly"][Theme["editor text"]])
	else
		term.setBackgroundColor(Theme["editor background"])
		term.setTextColor(Theme["editor text"])
	end

	term.setCursorPos(self.editor:gutterSize() + 1, y)
	term.clearLine()

	for _, item in pairs(data) do
		if item.kind == "text" then
			-- Render some text
			term.write(item.data)
		elseif item.kind == "color" then
			-- Set the current text color
			local index = item.data
			if index == "text" then
				index = "editor text"
			end

			local color = Theme[index]

			if isReadOnly then
				color = Theme["editor readonly"][color]
			end

			term.setTextColor(color)
		end
	end
end


--- Fully redraws the editor.
function Content:draw()
	term.redirect(self.win.redirect)

	-- Clear
	term.setBackgroundColor(Theme["editor background"])
	term.clear()

	-- Iterate over each line
	local lineCount = math.min(#self.editor.lines, self.height)
	for y = 1, lineCount do
		self:drawText(y)
		self:drawGutter(y)
	end

	-- Restore the cursor position
	self:restoreCursor()
end


--- Updates the screen based off what the editor says needs redrawing.
function Content:updateDirty()
	local dirty = self.editor:dirty()
	if dirty then
		if dirty == "full" then
			self:draw()
		else
			term.redirect(self.win.redirect)
			for _, data in pairs(dirty) do
				if data.kind == "gutter" then
					self:drawGutter(data.data)
				elseif data.kind == "line" then
					self:drawLine(data.data)
				end
			end
		end

		self.editor:clearDirty()
	end
end


--- Updates the syntax highlighter.
--- Triggers an update of the mapped data if character is non-nil,
--- and a full redraw if character is one of the full redraw triggers.
function Content:updateSyntaxHighlighting(character)
	if character then
		self.highlighter:update(self.editor.lines)

		-- Trigger a full redraw if a mapped character was typed (ie. affects
		-- the highlighting on other lines).
		if SyntaxHighlighter.fullRedrawTriggers:find(character, 1, true) then
			self.editor:setDirty("full")
		end
	end
end


--- Called when a key event occurs.
function Content:key(key)
	if key == keys.up then
		self.editor:moveCursorUp()
	elseif key == keys.down then
		self.editor:moveCursorDown()
	elseif key == keys.left then
		self.editor:moveCursorLeft()
	elseif key == keys.right then
		self.editor:moveCursorRight()
	elseif key == keys.home then
		self.editor:moveCursorToStartOfLine()
	elseif key == keys['end'] then
		self.editor:moveCursorToEndOfLine()
	elseif key == keys.pageUp then
		self.editor:pageUp()
	elseif key == keys.pageDown then
		self.editor:pageDown()
	elseif key == keys.backspace then
		local character = self.editor:backspace()
		self:updateSyntaxHighlighting(character)
	elseif key == keys.delete then
		local character = self.editor:forwardDelete()
		self:updateSyntaxHighlighting(character)
	elseif key == keys.tab then
		for i = 1, Content.tabWidth do
			self.editor:insertCharacter(" ")
		end
		self:updateSyntaxHighlighting(" ")
	elseif key == keys.enter then
		self.editor:insertNewline()
		self:updateSyntaxHighlighting("\n")
	end
end


--- Called when a char event occurs.
function Content:char(character)
	self.editor:insertCharacter(character)
	self:updateSyntaxHighlighting(character)
end


--- Called when an event occurs.
function Content:event(event)
	local returnVal = false
	if event[1] == "char" then
		self:char(event[2])
	elseif event[1] == "key" then
		self:key(event[2])
	elseif event[1] == "mouse_click" then
		self.editor:moveCursorToRelative(event[3] - self.editor:gutterSize(), event[4])
		returnVal = true
	elseif event[1] == "mouse_scroll" then
		if event[2] == 1 then
			self.editor:moveCursorDown()
		else
			self.editor:moveCursorUp()
		end
	end

	self:updateDirty()
	self:restoreCursor()
	return returnVal
end

return Content
