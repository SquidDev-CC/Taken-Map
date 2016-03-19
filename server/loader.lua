local function parse(path, name)
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

local levelDir = fs.combine(fs.getDir(shell.getRunningProgram()), "data")
if fs.exists(levelDir) then
	local levelNames = fs.list(levelDir)
	table.sort(levelNames)

	local levels = {}
	for i, levelName in ipairs(levelNames) do
		levels[i] = { parse(fs.combine(levelDir, levelName), levelName) }
	end

	return levels
else
	return require "server.levels"
end
