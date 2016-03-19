rednet.open("back")
return function(channel)
	local function receive()
		-- Wait for events
		while true do
			local eventName, id, message = os.pullEventRaw("rednet_message")
			if eventName == "rednet_message" then
				if id == channel then
					return message
				end
			end
		end
	end

	local function send(data)
		rednet.send(channel, data)
	end

	return {
		receive = receive,
		send = send,
	}
end
