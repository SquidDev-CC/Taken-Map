--- Handles tracking of player state.
local origin = require("server.origin")

--- The latest known position of the player
local x, y, z = 0, 0, 0

--- Whether the player is currently spectating
local spectating = false

--- The active "state" of the player, or nil if not tracking.
local state = nil

local valid_states = {
	none = "white",
	red = "red",
	green = "green",
	blue = "blue",
}

local player_selector = "@p[score_taken_playing=0]"
local placeholder_selector = "@e[name=taken_placeholder]"

return {
	--- Called on the initial setup
	setup = function(config)
		commands.async.scoreboard("objectives", "add", "taken_playing", "dummy", "State")
		commands.async.scoreboard("objectives", "add", "taken_gm", "dummy", "Taken gamemode trigger")

		commands.async.gamerule("keepInventory", "true")

		for name, color in pairs(valid_states) do
			commands.async.scoreboard("teams", "add", "taken_" .. name)
			commands.async.scoreboard("teams", "option", "taken_" .. name, "color", color)
		end

		commands.async.scoreboard("players", "reset", "@a", "taken_playing")
		commands.async.scoreboard("players", "reset", "@a", "taken_gm")
		commands.async.scoreboard("players", "set", "@p", "taken_playing", "0")

		commands.async.kill(placeholder_selector)
		commands.async.summon(
			"minecraft:armor_stand", "~", "~1", "~",
			[[{Marker:1,Small:1,Invisible:1,Invulnerable:1,NoGravity:1,NoBasePlate:1,CustomName:"taken_placeholder"}]]
		)
	end,

	--- Load information from config
	load = function(config) end,

	--- Update the position of the player, called every tick
	updatePosition = function()
		if spectating then
			local result = commands.scoreboard("players", "test", player_selector, "taken_gm", "1", "1")
			if result then
				-- We"ve triggered!
				spectating = false
				commands.async.tp(player_selector, placeholder_selector)
				commands.async.gamemode("adventure", player_selector)
				commands.async.gamemode("creative", "SquidDev") -- Sneaky, sneaky!
			end
		else
			commands.async.tp(placeholder_selector, player_selector)
			local ok, lines = commands.entitydata(placeholder_selector, "{_ignore:1}")
			if not ok then error(table.concat(lines)) end

			local nx, ny, nz = lines[1]:match("Pos:%[([%-%d.]+)d?,([%-%d.]+)d?,([%-%d.]+)d?%]")
			if not nx then error("Cannot extract position from " .. lines[1]) end

			x, y, z = tonumber(nx), tonumber(ny), tonumber(nz)
		end

		return x, y, z
	end,

	--- Get the last known position of the player
	getPosition = function()
		return x, y, z
	end,

	--- Kill the player
	kill = function()
		if spectating then error("Cannot kill when spectating", 2) end
		x, y, z = origin.getSpawn()
		commands.async.tp(placeholder_selector, x, y, z)
		commands.async.kill(player_selector)
	end,

	--- Manually set the player's position
	tp = function(nx, ny, nz)
		if spectating then error("Cannot teleport when spectating", 2) end
		x, y, z = nx, ny, nz
		commands.async.tp(placeholder_selector, x, y, z)
		commands.async.tp(player_selector, x, y, z)
	end,

	--- Mark the player as spectating
	startSpectating = function()
		if spectating then return end

		spectating = true
		commands.async.gamemode("spectator", player_selector)

		-- Enable the taken_gm trigger and reset it
		commands.async.scoreboard("players", "set", player_selector, "taken_gm", "0")
		commands.async.scoreboard("players", "enable", player_selector, "taken_gm")

		-- Tell the player they are in spectator mode
		commands.async.tellraw(player_selector, [=[["",{"text":"You are in Spectator mode "},{"text":"[Resume]","color":"dark_green","clickEvent":{"action":"run_command","value":"/trigger taken_gm set 1"}}]]=])
	end,

	--- Determine whether the player is spectating
	isSpectating = function()
		return spectating
	end,

	--- Determine whether the player is holding a computer
	hasComputer = function()
		return (commands.testfor(player_selector, [[{Inventory:[{id:"computercraft:pocket_computer"}]}]]))
	end,

	--- Mark the system tracking the player"s state
	usingState = function(using)
		if using then
			state = "none"
			commands.async.scoreboard("teams", "join", "taken_" .. state, player_selector)
			commands.async.scoreboard("objectives", "setdisplay", "sidebar", "taken_playing")
		else
			state = nil
			commands.async.scoreboard("objectives", "setdisplay", "sidebar")
		end
	end,

	--- Get the state of the player
	getState = function()
		if not state then error("Cannot get state when not tracking it", 2) end
		return state
	end,

	--- Set the state of the player
	setState = function(new_state)
		if not state then error("Cannot set state when not tracking it", 2) end
		if spectating then error("Cannot set state when spectating", 2) end
		if not valid_states[new_state] then error("Unknown state " .. tostring(new_state), 2) end

		state = new_state
		commands.async.scoreboard("teams", "join", "taken_" .. state, player_selector)
	end,

	player_selector = player_selector,
	placeholder_selector = placeholder_selector,
}
