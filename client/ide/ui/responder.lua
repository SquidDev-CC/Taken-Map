--- Menu bar responder

local Panel = require "client.ide.ui.panel"

local term = term

--- Triggers an appropriate response to different menu item trigger events.
local Responder = {}
Responder.__index = Responder

--- Create a new responder
function Responder.new(...)
	local self = setmetatable({}, Responder)
	self:setup(...)
	return self
end


function Responder:setup(controller)
	self.controller = controller
end


function Responder.toCamelCase(identifier)
	identifier = identifier:lower()

	local first = true
	local result = ""
	for word in identifier:gmatch("[^%s]+") do
		if first then
			result = result .. word:lower()
			first = false
		else
			result = result .. word:sub(1, 1):upper() .. word:sub(2):lower()
		end
	end

	return result
end


function Responder:trigger(itemName)
	local name = Responder.toCamelCase(itemName)
	if self[name] then
		self[name](self)
		return true
	end

	return false
end


function Responder:about()
	local panel = Panel.new()
	panel:center("LuaIDE 2.0")
	panel:empty()
	panel:center("Made by GravityScore")
	panel:center("Adapted by SquidDev")
	panel:show()
end

return Responder
