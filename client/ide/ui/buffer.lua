--[[
	Buffer                 Trystan Cannon
						   24 August 2014

		The Buffer object allows for the screen
	to be sectioned off such that they can be personally
	redirected to and used as a separate terminal. This
	makes things such as windowing and switching between
	different programs in some kind of OS possible.

	NOTES:
		- All methods, unless redirected to, require a 'self'argument
		  so that they can operate upon the buffer as a table.
		  HOWEVER, if the buffer is redirected to via term.redirect (buffer:redirect()),
		  then this is unnecessary.

		- The buffer is redirected to via its redirect table: self.tRedirect.

		- All generic terminal methods return the buffer as a 'self'
		  parameter along with whatever they were ment to return.

		- EX: buffer:getSize() returns the width, height, and self.

	IMPORTANT NOTE 1:
			Each buffer's contents is separated into three tables of
		equal width and height:
			- tText
			- tTextColors
			- tBackColors
			Each of whom is setup that each character represents either a textual
		character or a hex digit to represent a color as a single byte.

			Colors are then converted at render time from their hex equivalent
		into decimal format.

	IMPORTANT NOTE 2:
			What makes this buffer special is the way that
		it handles rendering. While many similar apis simply
		save a pixel as a character, a text color, and a background
		color, then write said pixel out with the respective
		term API calls, this buffer does something different:

			Instead of changing colors all of the time, this
		buffer makes rendering quicker by using a function
		called 'getChunks.'

			'getChunks' goes through a line in a buffer and
		returns every 'chunk' of text that has the given
		text and background colors. This way, the maximum
		amount of text can be written before colors are
		changed.

			To prevent having to make 256 different iterations,
		only the color pairs (set of text and background colors)
		which are actually in the buffer are checked and rendered.
		This is done by recording those used in 'write' and various
		'clear' calls. Also, a function called 'updateColorPairs'
		brute force checks the entire buffer for what color pairs
		actually exist, then stores in them in the 'tColorPairs'
		hash table which looks like this:
			tColorPairs[sTextColor .. sBackColor] = true
			(The value is true if it exists, nil or false if not.)

		However, it is important to note that this maximizes
		efficiency for common use, for most programs make use
		of large portions of similarly colored text both in
		the text color and background color.
			- HOWEVER, situations in which the text and background
			  color pair is changing very often, this buffer may
			  actually be SLOWER than the classic change-every-iteration
			  approach!
]]

local match, find, sub, format, rep, gsub = string.match, string.find, string.sub, string.format, string.rep, string.gsub
local floor, log, abs = math.floor, math.log, math.abs
local pairs, ipairs, tostring, tonumber = pairs, ipairs, tostring, tonumber

-- Log of 2
local log2 = 1  / log (2)

--[[
	Creates and returns a new Buffer object with the specified dimensions
	and offset position on the screen.
]]
return function(tParent, x, y, nWidth, nHeight, bVisible)
	local tRedirect = nil

	local nCursorX = 1
	local nCursorY = 1

	local sTextColor = "0"
	local sBackColor = "f"

	local tText       = {}
	local tTextColors = {}
	local tBackColors = {}
	local tColorPairs = {}

	local bCursorBlink = false

	if bVisible == nil then bVisible = tParent and true end

	--[[--
		Goes through a line in a buffer and
		returns every 'chunk' of text that has the given
		text and background colors. This way, the maximum
		amount of text can be written before colors are
		changed.

		Each chunk looks like this:
			- tChunks[n] = {
				nStart = (Position in the line at which this chunk starts.),
				nStop  = (Position in the line at which this chunk stops.)
			}

		@return tChunks
	]]
	local function getChunks(nLineNumber, sTextColor, sBackColor)
		local sTextColors = tTextColors[nLineNumber]
		local sBackColors = tBackColors[nLineNumber]

		if not match(sTextColors, sTextColor) or not match(sBackColors, sBackColor) then
			return {}
		end

		local tChunks       = {}
		local nStart, nStop = nil, nil

		repeat
			nStart, nStop = find(sTextColors, sTextColor .. "+", nStart or 1)

			if nStart then
				local sChunk                = sub(sBackColors, nStart, nStop)
				local nBackStart, nBackStop = nil, nil

				repeat
					nBackStart, nBackStop = find(sChunk, sBackColor .. "+", nBackStart or 1)

					if nBackStart then
						tChunks[#tChunks + 1] = { nStart = nStart + nBackStart - 1,
												  nStop  = nStart + nBackStop - 1
												}
					end

					nBackStart = (nBackStop ~= nil) and nBackStop + 1 or nil
				until not nBackStart
			end

			nStart = (nStop ~= nil) and nStop + 1 or nil
		until not nStart

		return tChunks
	end

	--[[
		Iterates through the entirety of the buffer and updates the
		tColorPairs table for the buffer. This is the brute force method
		of checking which pairs actually exist in the buffer so that we
		can maximize rendering speed.

		@return self
	]]
	local function updateColorPairs()
		local tCheckedPairs = {}

		for nLineNumber = 1, nHeight do
			local sTextColors = tTextColors[nLineNumber]
			local sBackColors = tBackColors[nLineNumber]

			for sColorPair, _ in pairs (tColorPairs) do
				if not tCheckedPairs[sColorPair] then
					local sTextColor, sBackColor = match(sColorPair, "(%w)(%w)")
					tCheckedPairs[sColorPair] = find(sTextColors, sTextColor) ~= nil and find(sBackColors, sBackColor, find(sTextColors, sTextColor)) or nil
				end
			end
		end

		tColorPairs = tCheckedPairs
	end

	local render

	do
		local parent_write = tParent.write
		local function getSize()
			return nWidth, nHeight
		end

		local function getCursorPos()
			return nCursorX, nCursorY
		end

		local parent_setCursor = tParent.setCursorPos
		local function setCursorPos(cX, cY)
			nCursorX = floor(cX) or nCursorX
			nCursorY = floor (cY) or nCursorY

			if bVisible then parent_setCursor(x + cX - 1, y + cY - 1) end
		end

		local parent_isColor = tParent.isColor
		local function isColor()
			return parent_isColor()
		end

		local parent_setText = tParent.setTextColor
		local function setTextColor(nTextColor)
			sTextColor = format("%x", log(nTextColor) * log2) or sTextColor
			if bVisible then parent_setText(nTextColor) end
		end

		local parent_setBack = tParent.setBackgroundColor
		local function setBackgroundColor(nBackColor)
			sBackColor = format("%x", log(nBackColor) * log2) or sBackColor
			if bVisible then parent_setBack(nBackColor) end
		end

		local parent_setBlink = tParent.setCursorBlink
		local function setCursorBlink(blink)
			bCursorBlink = blink
			if bVisible then parent_setBlink(blink) end
		end

		local function clearLine(nLineNumber, checkColorPairs)
			bCheckColorPairs = checkColorPairs or nLineNumber == nil
			nLineNumber      = nLineNumber or nCursorY

			if nLineNumber >= 1 and nLineNumber <= nHeight then
				tText[nLineNumber]       = rep(" ", nWidth)
				tTextColors[nLineNumber] = rep(sTextColor, nWidth)
				tBackColors[nLineNumber] = rep(sBackColor, nWidth)

				tColorPairs[sTextColor .. sBackColor] = true

				if bCheckColorPairs then
					updateColorPairs()
				end
			end

			if bVisible then
				parent_setCursor(x, nLineNumber + y - 1)
				parent_write(rep(" ", nWidth))
				parent_setCursor(x + nCursorX - 1, y + nCursorY - 1)
			end
		end

		local function clear()
			for nLineNumber = 1, nHeight do
				clearLine(nLineNumber)
			end

			tColorPairs[sTextColor .. sBackColor] = true
			updateColorPairs()
		end

		local function scroll(nTimesToScroll)
			for nTimesScrolled = 1, abs(nTimesToScroll) do
				if nTimesToScroll > 0 then
					for nLineNumber = 1, nHeight do
						tText[nLineNumber]       = tText[nLineNumber + 1] or rep(" ", nWidth)
						tTextColors[nLineNumber] = tTextColors[nLineNumber + 1] or rep(sTextColor, nWidth)
						tBackColors[nLineNumber] = tBackColors[nLineNumber + 1] or rep(sBackColor, nWidth)
					end
				else
					for nLineNumber = nHeight, 1, -1 do
						tText[nLineNumber]       = tText[nLineNumber - 1] or rep(" ", nWidth)
						tTextColors[nLineNumber] = tTextColors[nLineNumber - 1] or rep(sTextColor, nWidth)
						tBackColors[nLineNumber] = tBackColors[nLineNumber - 1] or rep(sBackColor, nWidth)
					end
				end
			end

			tColorPairs[sTextColor .. sBackColor] = true
			updateColorPairs()

			if bVisible then render() end
		end

		local function write(sText)
			if nCursorY >= 1 and nCursorY <= nHeight then
				-- Our rendering problems might be stemming from a problem regarding the color pairs that are registered at render time.
				tColorPairs[sTextColor .. sBackColor] = true

				sText = gsub(gsub(tostring(sText), "\t", " "), "%c", "?")

				local sTextLine   = tText[nCursorY]
				local sTextColors = tTextColors[nCursorY]
				local sBackColors = tBackColors[nCursorY]

				--[[
					This could be better. We just need to calculate stuff instead of using a for loop.
				]]
				for nCharacterIndex = 1, sText:len() do
					if nCursorX >= 1 and nCursorX <= nWidth then
						sTextLine =
							  sub(sTextLine, 1, nCursorX - 1) ..
							  sub(sText, nCharacterIndex, nCharacterIndex) ..
							  sub(sTextLine, nCursorX + 1)
						sTextColors = sub(sTextColors, 1, nCursorX - 1) .. sTextColor .. sub(sTextColors, nCursorX + 1)
						sBackColors = sub(sBackColors, 1, nCursorX - 1) .. sBackColor .. sub(sBackColors, nCursorX + 1)
					end

					nCursorX = nCursorX + 1
				end

				tText[nCursorY]       = sTextLine
				tTextColors[nCursorY] = sTextColors
				tBackColors[nCursorY] = sBackColors

				if bVisible then
					parent_write(sText)
				end
			end
		end

		tRedirect = {
			getSize             = getSize,
			getCursorPos        = getCursorPos,
			setCursorPos        = setCursorPos,
			isColor             = isColor,
			isColour            = isColor,
			setTextColor        = setTextColor,
			setTextColour       = setTextColor,
			setBackgroundColor  = setBackgroundColor,
			setBackgroundColour = setBackgroundColor,
			setCursorBlink      = setCursorBlink,
			clearLine           = clearLine,
			clear               = clear,
			scroll              = scroll,
			write               = write,
		}
	end

	--[[
		Renders the contents of the buffer to its tTerm object. This should
		be the current terminal object or monitor or whatever output it should
		render to.

		The position of the cursor, blink state, and text/background color
		states are restored to their states prior to rendering.
	]]
	render = function(redirect)
		local tTerm = redirect or tParent
		local fTerm_back, fTerm_fore, fTerm_write, fTerm_cursor, fTerm_blink =
			tTerm.setBackgroundColor, tTerm.setTextColor, tTerm.write, tTerm.setCursorPos, tTerm.setCursorBlink

		local sCurrentTextColor
		local sCurrentBackColor

		for sColorPair, _ in pairs (tColorPairs) do
			local sTextColor, sBackColor = match(sColorPair, "(%w)(%w)")

			if sCurrentTextColor ~= sTextColor then
				fTerm_fore(2 ^ tonumber(sTextColor, 16))
				sCurrentTextColor = sTextColor
			end
			if sCurrentBackColor ~= sBackColor then
				fTerm_back(2 ^ tonumber(sBackColor, 16))
				sCurrentBackColor = sBackColor
			end

			for nLineNumber = 1, nHeight do
				for _, tChunk in ipairs (getChunks (nLineNumber, sTextColor, sBackColor)) do
					fTerm_cursor(tChunk.nStart + x - 1, nLineNumber + y - 1)
					fTerm_write(tText[nLineNumber]:sub (tChunk.nStart, tChunk.nStop))
				end
			end
		end

		fTerm_cursor(nCursorX + x - 1, nCursorY + y - 1)
		fTerm_blink(bCursorBlink)

		if sTextColor ~= sCurrentTextColor then
			fTerm_fore (2 ^ tonumber(sTextColor, 16))
		end
		if sBackColor ~= sCurrentBackColor then
			fTerm_back(2 ^ tonumber(sBackColor, 16))
		end
	end

	local function setVisible(visible)
		if bVisible ~= visible then
			bVisible = visible
			if visible then
				render()
			end
		end
	end

	return {
		redirect = tRedirect,
		render = render,
		setVisible = setVisible,
	}
end
