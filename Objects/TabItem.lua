Inherit = 'View'

TabColour = colours.lightGrey
TabTextColour = colours.black

ActiveTabColour = colours.grey
ActiveTabTextColour = nil

Title = ''
CanClose = true
Children = {}

OldActiveObject = nil


LoadView = function(self)
	local view = self:GetObject('View')
	if view.TabColour then
		window.TabColour = view.TabColour
	end
	if view.TabTextColour then
		window.TabTextColour = view.TabTextColour
	end
	view.X = 1
	view.Y = 1

	view:ForceDraw()
	self:OnUpdate('View')
	if self.OnViewLoad then
		self.OnViewLoad(view)
	end

	self.OldActiveObject = self.Bedrock:GetActiveObject()
	self.Bedrock:SetActiveObject(view)
end

SetView = function(self, view)
	self:RemoveObject('View')
	table.insert(self.Children, view)
	view.Parent = self
	self:LoadView()
end

OnDraw = function(self, x, y)
	local toolBarColour = self.Visible and self.ActiveTabColour or self.TabColour
	local toolBarTextColour = self.Visible and self.ActiveTabTextColour or self.TabTextColour
	if toolBarColour then
		Drawing.DrawBlankArea(x, y, self.Width, 1, toolBarColour)
	end

	if toolBarTextColour then
		local title = self.Bedrock.Helpers.TruncateString(self.Title, self.Width - 2)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, title, toolBarTextColour, toolBarColour)
	end
end

Close = function(self)
	self.Bedrock:SetActiveObject(self.OldActiveObject)
	self.Bedrock.Window = nil
	self.Bedrock:RemoveObject(self)
	if self.OnClose then
		self:OnClose()
	end
	self = nil
end