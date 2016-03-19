--- The global theme

local Theme = setmetatable(
	{},
	{
		__newindex = function(self, key, value)
			if value == nil then
				error("Trying to set nil for key " .. key)
			end
			rawset(self, key, value)
		end
	}
)


--- Load the theme
Theme.load = function()
	if term.isColor() then
		-- Menu bar
		Theme["menu bar background"] = colors.white
		Theme["menu bar background focused"] = colors.gray
		Theme["menu bar text"] = colors.black
		Theme["menu bar text focused"] = colors.white
		Theme["menu bar flash text"] = colors.white
		Theme["menu bar flash background"] = colors.lightGray

		Theme["menu bar flash background execute"] = colors.lime
		Theme["menu bar background execute"] = colors.green

		Theme["menu bar flash background reset"] = colors.orange
		Theme["menu bar background reset"] = colors.red

		-- Menu dropdown items
		Theme["menu dropdown background"] = colors.gray
		Theme["menu dropdown text"] = colors.white
		Theme["menu dropdown flash text"] = colors.white
		Theme["menu dropdown flash background"] = colors.lightGray

		-- Tab bar
		Theme["tab bar background"] = colors.white
		Theme["tab bar background focused"] = colors.white
		Theme["tab bar background blurred"] = colors.white
		Theme["tab bar background close"] = colors.white
		Theme["tab bar text focused"] = colors.black
		Theme["tab bar text blurred"] = colors.lightGray
		Theme["tab bar text close"] = colors.red

		-- Editor
		Theme["editor background"] = colors.white
		Theme["editor text"] = colors.black

		-- Gutter
		Theme["gutter background"] = colors.white
		Theme["gutter background focused"] = colors.white
		Theme["gutter background error"] = colors.white
		Theme["gutter text"] = colors.lightGray
		Theme["gutter text focused"] = colors.gray
		Theme["gutter text error"] = colors.red
		Theme["gutter separator"] = "\149"

		-- Syntax Highlighting
		Theme["keywords"] = colors.lightBlue
		Theme["constants"] = colors.orange
		Theme["operators"] = colors.blue
		Theme["numbers"] = colors.black
		Theme["functions"] = colors.magenta
		Theme["string"] = colors.red
		Theme["comment"] = colors.lightGray

		-- Invert mapping for colours taken from Bedrock
		Theme["editor readonly"] = {
			-- Invert
			-- [colours.white] = colours.black,
			-- [colours.orange] = colours.blue,
			-- [colours.magenta] = colours.green,
			-- [colours.lightBlue] = colours.brown,
			-- [colours.yellow] = colours.blue,
			-- [colours.lime] = colours.purple,
			-- [colours.pink] = colours.green,
			-- [colours.grey] = colours.lightGrey,
			-- [colours.lightGrey] = colours.grey,
			-- [colours.cyan] = colours.red,
			-- [colours.purple] = colours.green,
			-- [colours.blue] = colours.yellow,
			-- [colours.brown] = colours.lightBlue,
			-- [colours.green] = colours.purple,
			-- [colours.red] = colours.cyan,
			-- [colours.black] = colours.white,

			-- Darker
			-- [colours.white] = colours.lightGrey,
			-- [colours.orange] = colours.red,
			-- [colours.magenta] = colours.purple,
			-- [colours.lightBlue] = colours.cyan,
			-- [colours.yellow] = colours.orange,
			-- [colours.lime] = colours.green,
			-- [colours.pink] = colours.magenta,
			-- [colours.grey] = colours.black,
			-- [colours.lightGrey] = colours.grey,
			-- [colours.cyan] = colours.blue,
			-- [colours.purple] = colours.grey,
			-- [colours.blue] = colours.grey,
			-- [colours.brown] = colours.grey,
			-- [colours.green] = colours.grey,
			-- [colours.red] = colours.brown,
			-- [colours.black] = colours.black,

			-- Highlight
			[colours.white] = colours.lightGrey,
			[colours.orange] = colours.yellow,
			[colours.magenta] = colours.pink,
			[colours.lightBlue] = colours.cyan,
			[colours.yellow] = colours.orange,
			[colours.lime] = colours.green,
			[colours.pink] = colours.magenta,
			[colours.grey] = colours.lightGrey,
			[colours.lightGrey] = colours.grey,
			[colours.cyan] = colours.lightBlue,
			[colours.purple] = colours.magenta,
			[colours.blue] = colours.lightBlue,
			[colours.brown] = colours.red,
			[colours.green] = colours.lime,
			[colours.red] = colours.orange,
			[colours.black] = colours.grey,
		}

		-- Panel
		Theme["panel text"] = colors.white
		Theme["panel background"] = colors.gray
		Theme["panel border"] = colors.orange
		Theme["panel close text"] = colors.white
		Theme["panel close background"] = colors.red

		-- File dialogue
		Theme["file dialogue background"] = colors.gray
		Theme["file dialogue text"] = colors.white
		Theme["file dialogue text blurred"] = colors.lightGray
		Theme["file dialogue file"] = colors.white
		Theme["file dialogue folder"] = colors.lime
		Theme["file dialogue readonly"] = colors.red
		Theme["file dialogue close text"] = colors.red
		Theme["file dialogue close background"] = colors.lightGray
	else
		error("LuaIDE must be run on a color computer")
	end
end

return Theme
