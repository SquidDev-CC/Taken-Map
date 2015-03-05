local controller = IDE.Controller.new()

parallel.waitForAny(function()
	term.redirect(term.native())

	controller.tabBar:current():open("Welcome!", {
		"--[[",
		"  Welcome to Trapped with " .. os.getComputerID(),
		"--]]",
	})
	controller:run()
end, function()
	rednet.open("back")
	while true do
		local sender, data = rednet.receive()

		if sender == Config.Server.Id then
			if data.Action == "Files" then
				local content = controller.tabBar
				local count = content:openCount()
				local index = 1

				for _, file in ipairs(data.Files) do
					if index > count then
						content:create(index)
					end

					local tab = content.contentManager.contents[index]
					tab:open(file.Name, file.Lines)

					for _, readOnly in ipairs(file.ReadOnly) do
						tab.editor:setReadOnly(true, unpack(readOnly))
					end

					index = index + 1
				end

				if index < count then
					for i = index + 1, count do
						content:close(index)
					end
				end
			end

			controller:draw()
		end
	end
end, function()
	sleep(30)
end)

term.redirect(term.native())
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
