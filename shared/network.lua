return function()
	local channel = os.getComputerID()
	local side
	for _, pSide in ipairs(peripheral.getNames()) do
		if peripheral.getType(pSide) == "modem" and peripheral.call(pSide, "isWireless") then
			side = pSide
			peripheral.call(side, "open", channel)
		end
	end

	if not side then
		error("Cannot find modem")
	end

	local function receive()
		-- Wait for events
		while true do
			local name, side, id, returnId, message = os.pullEventRaw()
			if name == "modem_message" and id == channel and returnId == channel then
				return message
			end
		end
	end

	local function send(data)
		peripheral.call(side, "transmit", channel, channel, data)
	end

	return {
		receive = receive,
		send = send,
	}
end
