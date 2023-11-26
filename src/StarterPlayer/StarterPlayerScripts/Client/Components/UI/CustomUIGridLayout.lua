local CustomUIGridLayout = {}
CustomUIGridLayout.__index = CustomUIGridLayout

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local TweenService = game:GetService("TweenService")


function CustomUIGridLayout:ConvertGrid() -- CREATES INITIAL BOXES
	local positionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.X.Scale/2 
	local vertPositionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.Y.Scale/2 
	
	for ind, column in ipairs(self.CurrentOrderList[1]) do
		
		for ind2, rows in ipairs(self.CurrentOrderList) do 
			local currentBoxEntry = self.CurrentOrderList[ind2][ind]
			local buttonClone = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate:Clone()
			if currentBoxEntry.ItemIndex == "Denarii" then  self.CurrentOrderList[ind2][ind].ItemAmount = self.Core.PlayerData.Currency.Denarii currentBoxEntry = self.CurrentOrderList[ind2][ind]  end
			buttonClone:SetAttribute("ItemIndex", currentBoxEntry.ItemIndex)
			buttonClone.Name = currentBoxEntry.SlotName
			if currentBoxEntry.ItemTaken then
				buttonClone.ItemText.Visible = true
				buttonClone.ItemText.Text = currentBoxEntry.ItemIndex .. ", " .. tostring(currentBoxEntry.ItemAmount)
			end
			buttonClone.Parent = self.Frame
			buttonClone.Position = UDim2.new(positionSum, 0, vertPositionSum, 0)
			positionSum += (buttonClone.Size.X.Scale + 0.03)
		end
		
		vertPositionSum += (game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.Y.Scale + 0.03)
		positionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.X.Scale/2 
	end
end

function CustomUIGridLayout:ConvertGridExisting() -- ADJUSTS POSITIONS WITHOUT TWEENS
	local positionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.X.Scale/2 
	local vertPositionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.Y.Scale/2 

	for ind, column in ipairs(self.CurrentOrderList[1]) do

		for ind2, rows in ipairs(self.CurrentOrderList) do 
			self.Frame:FindFirstChild(self.CurrentOrderList[ind2][ind].SlotName).Position = UDim2.new(positionSum, 0, vertPositionSum, 0)
			positionSum += (self.Frame:FindFirstChild(self.CurrentOrderList[ind2][ind].SlotName).Size.X.Scale + 0.03)
		end

		vertPositionSum += (game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.Y.Scale + 0.03)
		positionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.X.Scale/2 
	end
	
	
end


function CustomUIGridLayout:AdjustList(tweenTime, tweenBox)	-- ADJUSTS POSITIONS WITH TWEENS
	local positionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.X.Scale/2 
	local vertPositionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.Y.Scale/2 

	for ind, column in ipairs(self.CurrentOrderList[1]) do
		for ind2, rows in ipairs(self.CurrentOrderList) do 
			if (not self.DraggedBox or self.DraggedBox.Name ~= self.CurrentOrderList[ind2][ind].SlotName) or tweenBox then
				self.Frame:FindFirstChild(self.CurrentOrderList[ind2][ind].SlotName):TweenPosition(UDim2.new(positionSum, 0, vertPositionSum, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime, true) 
			end
			positionSum += (self.Frame:FindFirstChild(self.CurrentOrderList[ind2][ind].SlotName).Size.X.Scale + 0.03)
		end

		vertPositionSum += (game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.Y.Scale + 0.03)
		positionSum = game.ReplicatedStorage.Resources.UI.ButtonTemplates.InventoryTemplate.Size.X.Scale/2 
	end
end


function CustomUIGridLayout:GetBoxIndex(box) -- RETURNS COLUMN AND ROW POSITIONS OF BOX
	local curIndex = {Column = 0, Row = 0}
	
	for ind, column in ipairs(self.CurrentOrderList[1]) do
		for ind2, rows in ipairs(self.CurrentOrderList) do 
			if self.CurrentOrderList[ind2][ind].SlotName == box.Name then
				curIndex = {Column = ind2, Row = ind} 
				return curIndex
			end
		end
	end
end


function CustomUIGridLayout:CreateConnection(box)
	self:Destroy()

	local curIndex = self:GetBoxIndex(box)
	
	if not self.DragEvent then
		local CurrentlyAdjusting = false
		
		local originalBoxYPosition = box.Position.Y.Scale
		local originalBoxXPosition = box.Position.X.Scale
		
		local originalAbsBoxYPosition = box.AbsolutePosition.Y
		local originalAbsBoxXPosition = box.AbsolutePosition.X

		local downSizeAmount = curIndex.Row < #self.CurrentOrderList[curIndex.Column] and self.Frame:FindFirstChild(self.CurrentOrderList[curIndex.Column][curIndex.Row+1].SlotName).AbsolutePosition.Y or 0 
		local upSizeAmount = curIndex.Row > 1 and self.Frame:FindFirstChild(self.CurrentOrderList[curIndex.Column][curIndex.Row-1].SlotName).AbsolutePosition.Y or 0 
		
		local rightSizeAmount = curIndex.Column < #self.CurrentOrderList and self.Frame:FindFirstChild(self.CurrentOrderList[curIndex.Column+1][curIndex.Row].SlotName).AbsolutePosition.X or 0 
		local leftSizeAmount = curIndex.Column > 1 and self.Frame:FindFirstChild(self.CurrentOrderList[curIndex.Column-1][curIndex.Row].SlotName).AbsolutePosition.X or 0 
		
		local CurrentListLengthX = #self.CurrentOrderList
		local CyrrentListLengthY = #self.CurrentOrderList[curIndex.Column]
		
		
		self.DragEvent = RunService.RenderStepped:Connect(function()
			print("UNGA")
			if CurrentlyAdjusting then return end
			
			local mousePosYDiff = Mouse.Y - originalAbsBoxYPosition - box.AbsoluteSize.Y/2
			local mousePosXDiff = Mouse.X - originalAbsBoxXPosition- box.AbsoluteSize.X/2

			if (mousePosYDiff - 2 < 0  and curIndex.Row > 1) or (mousePosYDiff - 2 > 0  and curIndex.Row < CyrrentListLengthY) then
				box.Position = UDim2.new(originalBoxXPosition,  box.Position.X.Offset, originalBoxYPosition, mousePosYDiff ) -- MOVE ON Y AXIS IF WITHIN LIMITS
			end
			
			if (mousePosXDiff - 2 < 0  and curIndex.Column > 1) or (mousePosXDiff - 2 > 0  and curIndex.Column < CurrentListLengthX) then
				box.Position = UDim2.new(originalBoxXPosition, mousePosXDiff, originalBoxYPosition,  box.Position.Y.Offset) -- MOVE ON X AXIS IF WITHING LIMITS
			end
			
			
			local boxAbsYPos = box.AbsolutePosition.Y
			local boxAbsXPos = box.AbsolutePosition.X

			if (boxAbsYPos + 1)  < upSizeAmount and curIndex.Row > 1 then  -- CHECK IF ITS POSITION PASSED THE NEEDED POSITION TO MOVE UP THE FRAME
				CurrentlyAdjusting = true
				
				local tSave = self.CurrentOrderList[curIndex.Column][curIndex.Row]
				self.CurrentOrderList[curIndex.Column][curIndex.Row] = self.CurrentOrderList[curIndex.Column][curIndex.Row-1]
				self.CurrentOrderList[curIndex.Column][curIndex.Row-1] = tSave
				
				self:AdjustList(0.25)

				self:ResetDragging()
				self:CreateConnection(box)

			elseif (boxAbsYPos - 1) > downSizeAmount and curIndex.Row < CyrrentListLengthY then   -- CHECK IF ITS POSITION PASSED THE NEEDED POSITION TO MOVE DOWN THE FRAME
				CurrentlyAdjusting = true
				
				local tSave = self.CurrentOrderList[curIndex.Column][curIndex.Row]
				self.CurrentOrderList[curIndex.Column][curIndex.Row] = self.CurrentOrderList[curIndex.Column][curIndex.Row+1]
				self.CurrentOrderList[curIndex.Column][curIndex.Row+1] = tSave

				self:AdjustList(0.25)

				self:ResetDragging()
				self:CreateConnection(box)
			end
			
			if (boxAbsXPos - box.AbsoluteSize.X/5 + 1)  < leftSizeAmount and curIndex.Column > 1 then  -- CHECK IF ITS POSITION PASSED THE NEEDED POSITION TO MOVE LEFT THE FRAME
				CurrentlyAdjusting = true

				local tSave = self.CurrentOrderList[curIndex.Column][curIndex.Row]
				self.CurrentOrderList[curIndex.Column][curIndex.Row] = self.CurrentOrderList[curIndex.Column-1][curIndex.Row]
				self.CurrentOrderList[curIndex.Column-1][curIndex.Row] = tSave

				self:AdjustList(0.25)

				self:ResetDragging()
				self:CreateConnection(box)

			elseif (boxAbsXPos - 1) > rightSizeAmount and curIndex.Column < CurrentListLengthX then  -- CHECK IF ITS POSITION PASSED THE NEEDED POSITION TO MOVE RIGHT THE FRAME
				CurrentlyAdjusting = true
				
				local tSave = self.CurrentOrderList[curIndex.Column][curIndex.Row]
				self.CurrentOrderList[curIndex.Column][curIndex.Row] = self.CurrentOrderList[curIndex.Column+1][curIndex.Row]
				self.CurrentOrderList[curIndex.Column+1][curIndex.Row] = tSave

				self:AdjustList(0.25)

				self:ResetDragging()
				self:CreateConnection(box)
			end

			if self.DraggedBox ~= box then
				self:Destroy()
				return
			end
		end)
	end
end

function CustomUIGridLayout:SetDraggedBox(box) -- SETS DRAG BOX TO BE CURRENTLY DRAGGED BOX
	self.DraggedBox = box
end

function CustomUIGridLayout:ClearDraggedBox()  -- RESETS DraggedBox
	self.DraggedBox = nil
end

function CustomUIGridLayout:ResetDragging() -- THIS IS FIRED FROM "StartDragging" AND RESETS THE DragEvent
	if self.DragEvent then
		self.DragEvent:Disconnect()
		self.DragEvent = nil
	end
end

function CustomUIGridLayout:Destroy() -- STOPS DRAG LOOP AND ADJUSTS BOXES
	if self.DragEvent then
		self.DragEvent:Disconnect()
		self.DragEvent = nil
	end

	self:ConvertGridExisting()
end


function CustomUIGridLayout.new(frame, frameArray, dataIndex, categoryType) -- CREATES NEW OBJECT FOR FRAME
	local myObj = {}
	setmetatable(myObj, CustomUIGridLayout)
	
	myObj.Core = _G.Core
	myObj.Frame = frame
	myObj.CurrentBox = nil
	myObj.CategoryType = categoryType
	myObj.CurrentOrderList = frameArray
	myObj.DragEvent = nil
	myObj.DraggedBox = nil
	myObj.dataIndex = dataIndex
	return myObj
end

function CustomUIGridLayout:Disconnect() -- DELETES OBJECT
	self:Destroy()
	self.Frame = nil
	self.CurrentBox = nil
	self.CurrentOrderList = nil
	self.DraggedBox = nil
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)

	print("DESTROYED CUSTOM UI LIST")
	return 
end


return CustomUIGridLayout