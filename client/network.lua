local config = require "config"

rednet.open("back")

local function receive()
	-- Wait for events
	while true do
		local eventName, id, message = os.pullEventRaw("rednet_message")
		if eventName == "rednet_message" then
			print(id, message)
			if id == config.serverId then
				return message
			end
		end
	end
end

local function send(data)
	rednet.send(config.serverId, data)
end

return {
	receive = receive,
	send = send,
}
