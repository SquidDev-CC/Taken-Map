local controller = require "client.ide.controller".new()

local function setFiles(files)
	local content = controller.tabBar
	local count = content:openCount()
	local index = 1

	for _, file in ipairs(files) do
		if index > count then
			content:create(index)
		end

		local tab = content.contentManager.contents[index]

		local copy = {}
		for i, v in ipairs(file.lines) do copy[i] = v end
		tab:open(file.name, copy)

		-- Start with everything read only
		tab.editor:setReadOnly(true)
		for _, write in ipairs(file.writable) do
			tab.editor:setReadOnly(false, unpack(write))
		end

		tab:updateDirty()

		index = index + 1
	end

	if index < count then
		for i = index + 1, count do
			content:close(index)
		end
	end

	controller:draw()
end

local function getFiles()
	local files = {}
	for i, file in ipairs(controller.tabBar.contentManager.contents) do
		files[i] = {
			name = file.path,
			lines = file.editor.lines,
		}
	end

	return files
end

return {
	getFiles = getFiles,
	setFiles = setFiles,
	run = function() controller:run() end,
}
