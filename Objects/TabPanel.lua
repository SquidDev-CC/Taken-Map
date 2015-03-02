BackgroundColour = colours.white
Enabled = true
ActiveTab = nil

OnUpdate = function(self, value)
	if value == 'Text' and self.AutoWidth then
		self.Width = #self.Text + 2
	end
end

OnDraw = function(self, x, y)
	local bg = self.BackgroundColour

	if not self.Enabled then
		txt = self.DisabledTextColour
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, bg)

	local xOffset = x
	local handle = fs.open("log.txt", "w")
	for _, tab in pairs(self.Items) do
		local tabColour = tab.Active and tab.ActiveTabColour or tab.TabColour or colours.white
		local tabTextColour = tab.Active and tab.ActiveTabTextColour or tab.TabTextColour or colours.black

		Drawing.DrawCharacters(xOffset, y, tab.Title, tabTextColour, tabColour)
		handle.writeLine(textutils.serialize(tab))
	end
	handle.close()
end

OnLoad = function(self)
	if self.ActiveTab == nil then
		self.ActiveTab = self.Items[1]
	elseif tonumber(self.ActiveTab) ~= nil then
		self.ActiveTab = self.Items[tonumber(self.ActiveTab)]
	else
		error("Expected ActiveTab to be number or nil")
	end

	for _, tab in pairs(self.Children) do
		tab.Visible = false
	end

	if self.ActiveTab then
		self.ActiveTab.Visible = true
	end
end

Click = function(self, event, side, x, y)
	if self.Visible and not self.IgnoreClick and self.Enabled and event ~= 'mouse_scroll' then
		return true
	else
		return false
	end
end