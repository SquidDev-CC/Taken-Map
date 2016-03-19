local config = require "config"

rednet.open("back")

local function receive()
	-- Wait for events
	while true do
		local eventName, id, message = os.pullEventRaw("rednet_message")
		if eventName == "rednet_message" then
			if id == config.clientId then
				return message
			end
		end
	end
end

local function send(data)
	rednet.send(config.clientId, data)
end

return {
	receive = receive,
	send = send,
}
