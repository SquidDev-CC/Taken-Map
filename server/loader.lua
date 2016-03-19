return function(path, name)
	local file = fs.open(path, "r")
	if not file then error("Cannot find file " .. path, 2) end

	local lines, writable = {}, {}
	local writeStart = nil

	for line in file.readLine do
		local command = line:match("%-%-@(.+)")
		if command then
			if command == "start" then
				writeStart = #lines + 1
			elseif command == "stop" then
				if not writeStart then
					error("No write start")
				end

				writable[#writable + 1] = { writeStart, #lines }
				writeStart = nil
			else
				error("Unknown command")
			end
		else
			lines[#lines + 1] = line
		end
	end

	return {
		name = name or path,
		writable = writable,
		lines = lines,
	}
end
