local scoreboard = require "server.command".wrap("scoreboard")

local validStates = {
	none = "white",
	red = "red",
	green = "green",
	blue = "blue",
}
for name, color in pairs(validStates) do
	scoreboard("teams", "add", name)
	scoreboard("teams", "option", name, "color", color)
end

scoreboard("objectives add State dummy State")

return function()
	local display = false

	local state = "none"
	return {
		setup = function()
			scoreboard("players set @a State 0")
			scoreboard("teams join none @a")

			if display then
				scoreboard("objectives setdisplay sidebar State")
			else
				scoreboard("objectives setdisplay sidebar")
			end
		end,

		hasComputer = function()
			return (commands.testfor("@a", {Inventory={{id="computercraft:pocketComputer"}}}))
		end,

		getState = function()
			return state
		end,

		setState = function(newState)
			if type(newState) ~= "string" then error("Bad argument #1, expected string got " .. type(newState), 2) end
			state = newState
			scoreboard("teams join " .. newState .. " @a")
		end,

		showState = function(shouldDisplay)
			display = shouldDisplay or shouldDisplay == nil
		end
	}
end
