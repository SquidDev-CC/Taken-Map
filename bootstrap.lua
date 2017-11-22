--- Simply calls the appropriate task

local root = fs.getDir(shell.getRunningProgram())
local function checkModules(path)
	if fs.getName(path):sub(1, 1) == "." then
		-- Skip hidden files
		return
	elseif fs.isDir(path) then
		for _, v in ipairs(fs.list(path)) do
			checkModules(fs.combine(path, v))
		end
	elseif path:find("%.lua$") then
		local ok, err = loadfile(path)
		if not ok then error(err, 0) end
	end
end

checkModules(root)

local args = table.pack(...)

-- local original = term.current()
-- term.redirect(term.native())

local success = xpcall(function()
	return loadfile(fs.combine(root, "init.lua"), _ENV)(unpack(args, 1, args.n))
end, function(err)
	printError(err)
	for i = 3, 15 do
		local _, msg = pcall(error, "", i)
		if #msg == 0 or msg:find("^xpcall:") then break end
		print(" ", msg)
	end
end)

if not success then
	error("Exited with errors", 0)
end
