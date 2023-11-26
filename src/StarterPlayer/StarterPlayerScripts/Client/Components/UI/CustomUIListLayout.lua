local ConnectionObj = {}
ConnectionObj.__index = ConnectionObj

local CustomUIListLayout = {}
CustomUIListLayout.__index = CustomUIListLayout

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local TweenService = game:GetService("TweenService")


function CustomUIListLayout:ConvertList() -- INSTANTLY POSITION ALL FRAMES
	local positionSum = 0
	
	for i,v in ipairs(self.CurrentOrderList) do 
		local box = self.Frame:FindFirstChild(v.CategoryType)
		box.Position = UDim2.new(0, 0, positionSum, 0)
		positionSum += (box.Size.Y.Scale + 0.03)
	end
end


function CustomUIListLayout:AdjustList(tweenTime) -- TWEEN ALL FRAMES TO POSITION
	local positionSum = 0
	
	for i,v in ipairs(self.CurrentOrderList) do 
		local box = self.Frame:FindFirstChild(v.CategoryType)
		box:TweenPosition(UDim2.new(0, 0, positionSum, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime, true)
		positionSum += (box.Size.Y.Scale + 0.03)
	end
	
	--task.wait(0.3)
end


function CustomUIListLayout:GetBoxIndex(box) -- RETURNS POSITION OF FRAME
	local curIndex = 0
	for i,v in ipairs(self.CurrentOrderList) do 
		if v.CategoryType == box.Name then
			print("EHHH")
			curIndex = i 
			return curIndex
		end
	end
end


function CustomUIListLayout:CreateConnection(box)
	local returnObj = setmetatable({}, ConnectionObj)
	
	returnObj.dragFrame = box
	returnObj.Maid = self.Core.Utils.Maid.new()
	local CurrentlyAdjusting = false

	returnObj.originalBoxPosition = returnObj.dragFrame.Position.Y.Scale 
	returnObj.originalAbsBoxPosition = returnObj.dragFrame.AbsolutePosition.Y
	returnObj.curIndex = self:GetBoxIndex(returnObj.dragFrame)

	local downSizeAmount = returnObj.curIndex < #self.CurrentOrderList and self.Frame:FindFirstChild(self.CurrentOrderList[returnObj.curIndex+1].CategoryType).AbsolutePosition.Y or 0  -- GETS POSITION OF BOX BELOW CURRENT IF CURRENT ISNT LAST
	local upSizeAmount = returnObj.curIndex > 1 and self.Frame:FindFirstChild(self.CurrentOrderList[returnObj.curIndex-1].CategoryType).AbsolutePosition.Y or 0  -- GETS POSITION OF BOX ABOVE CURRENT IF CURRENT ISNT FIRST

	local CurrentListLength = #self.CurrentOrderList -- AMOUNT OF FRAMES
	
	returnObj.Maid:GiveTask(RunService.RenderStepped:Connect(function()
		--if CurrentlyAdjusting then return end
		local mousePosDiff = Mouse.Y - returnObj.originalAbsBoxPosition

		if (mousePosDiff < 0  and returnObj.curIndex > 1) or (mousePosDiff > 0  and returnObj.curIndex < CurrentListLength) then
			returnObj.dragFrame.Position = UDim2.new(0,0, returnObj.originalBoxPosition, Mouse.Y - returnObj.originalAbsBoxPosition) -- MOVE FRAME IF ISNT WITHIN BORDERS
		end

		local boxAbsPos = returnObj.dragFrame.AbsolutePosition.Y

		if (boxAbsPos - returnObj.dragFrame.AbsoluteSize.Y/5 + 5)  < upSizeAmount and returnObj.curIndex > 1 then  -- CHECK IF ITS POSITION PASSED THE NEEDED POSITION TO MOVE UP THE FRAME
			CurrentlyAdjusting = true

			local temp = self.CurrentOrderList[returnObj.curIndex]
			self.CurrentOrderList[returnObj.curIndex] = self.CurrentOrderList[returnObj.curIndex - 1]
			self.CurrentOrderList[returnObj.curIndex - 1] = temp

			self:AdjustList(0.25)
			
			returnObj.curIndex = self:GetBoxIndex(returnObj.dragFrame)
			downSizeAmount = returnObj.curIndex < #self.CurrentOrderList and self.Frame:FindFirstChild(self.CurrentOrderList[returnObj.curIndex+1].CategoryType).AbsolutePosition.Y or 0  -- GETS POSITION OF BOX BELOW CURRENT IF CURRENT ISNT LAST
			upSizeAmount = returnObj.curIndex > 1 and self.Frame:FindFirstChild(self.CurrentOrderList[returnObj.curIndex-1].CategoryType).AbsolutePosition.Y or 0  -- GETS POSITION OF BOX ABOVE CURRENT IF CURRENT ISNT FIRST

		elseif (boxAbsPos - 5) > downSizeAmount and returnObj.curIndex < CurrentListLength then   -- CHECK IF ITS POSITION PASSED THE NEEDED POSITION TO MOVE DOWN THE FRAME
			CurrentlyAdjusting = true
			local temp = self.CurrentOrderList[returnObj.curIndex]

			self.CurrentOrderList[returnObj.curIndex] = self.CurrentOrderList[returnObj.curIndex + 1]
			self.CurrentOrderList[returnObj.curIndex + 1] = temp

			self:AdjustList(0.25)
			
			returnObj.curIndex = self:GetBoxIndex(returnObj.dragFrame)
			downSizeAmount = returnObj.curIndex < #self.CurrentOrderList and self.Frame:FindFirstChild(self.CurrentOrderList[returnObj.curIndex+1].CategoryType).AbsolutePosition.Y or 0  -- GETS POSITION OF BOX BELOW CURRENT IF CURRENT ISNT LAST
		 	upSizeAmount = returnObj.curIndex > 1 and self.Frame:FindFirstChild(self.CurrentOrderList[returnObj.curIndex-1].CategoryType).AbsolutePosition.Y or 0  -- GETS POSITION OF BOX ABOVE CURRENT IF CURRENT ISNT FIRST
		end
	end))
	
	return returnObj
end

function ConnectionObj:Destroy() 
	print("DESTROYING OBJECT!!!!!")
	self.Maid:DoCleaning()
	self.dragFrame = nil
	self = nil
	return
end

function CustomUIListLayout:Cr(box) -- DRAG EVENT FOR A FRAME
	self:StopDragging()

	local curIndex = self:GetBoxIndex(box)

	if not self.DragEvent then
		local CurrentlyAdjusting = false
		
		local originalBoxPosition = box.Position.Y.Scale 
		local originalAbsBoxPosition = box.AbsolutePosition.Y

		local downSizeAmount = curIndex < #self.CurrentOrderList and self.Frame:FindFirstChild(self.CurrentOrderList[curIndex+1].CategoryType).AbsolutePosition.Y or 0  -- GETS POSITION OF BOX BELOW CURRENT IF CURRENT ISNT LAST
		local upSizeAmount = curIndex > 1 and self.Frame:FindFirstChild(self.CurrentOrderList[curIndex-1].CategoryType).AbsolutePosition.Y or 0  -- GETS POSITION OF BOX ABOVE CURRENT IF CURRENT ISNT FIRST
		
		local CurrentListLength = #self.CurrentOrderList -- AMOUNT OF FRAMES
		
		self.DragEvent = RunService.RenderStepped:Connect(function()
			if CurrentlyAdjusting then return end
			local mousePosDiff = Mouse.Y - originalAbsBoxPosition
			
			if (mousePosDiff < 0  and curIndex > 1) or (mousePosDiff > 0  and curIndex < CurrentListLength) then
				box.Position = UDim2.new(0,0, originalBoxPosition, Mouse.Y - originalAbsBoxPosition) -- MOVE FRAME IF ISNT WITHIN BORDERS
			end
			
			local boxAbsPos = box.AbsolutePosition.Y
			
			if (boxAbsPos - box.AbsoluteSize.Y/5 + 5)  < upSizeAmount and curIndex > 1 then  -- CHECK IF ITS POSITION PASSED THE NEEDED POSITION TO MOVE UP THE FRAME
				CurrentlyAdjusting = true
				
				local temp = self.CurrentOrderList[curIndex]
				self.CurrentOrderList[curIndex] = self.CurrentOrderList[curIndex - 1]
				self.CurrentOrderList[curIndex - 1] = temp
				
				self:AdjustList(0.25)

				self:ResetDragging()
				self:StartDragging(box)
				
			elseif (boxAbsPos - 5) > downSizeAmount and curIndex < CurrentListLength then   -- CHECK IF ITS POSITION PASSED THE NEEDED POSITION TO MOVE DOWN THE FRAME
				CurrentlyAdjusting = true
				local temp = self.CurrentOrderList[curIndex]

				self.CurrentOrderList[curIndex] = self.CurrentOrderList[curIndex + 1]
				self.CurrentOrderList[curIndex + 1] = temp

				self:AdjustList(0.25)

				self:ResetDragging()
				self:StartDragging(box)
			end
			
			if self.DraggedBox ~= box then
				self:StopDragging()
				return
			end
		end)
	end
end

function CustomUIListLayout:SetDraggedBox(box) -- SETS DRAG BOX TO BE CURRENTLY DRAGGED BOX
	self.DraggedBox = box
end

function CustomUIListLayout:ClearDraggedBox() -- RESETS DraggedBox
	self.DraggedBox = nil
end

function CustomUIListLayout:ResetDragging() -- THIS IS FIRED FROM "StartDragging" AND RESETS THE DragEvent
	if self.DragEvent then
		self.DragEvent:Disconnect()
		self.DragEvent = nil
	end

end


function CustomUIListLayout:StopDragging() -- STOPS DRAG LOOP AND ADJUSTS BOXES
	if self.DragEvent then
		self.DragEvent:Disconnect()
		self.DragEvent = nil
	end
	
	self:ConvertList()
end

function CustomUIListLayout.new(frame, frameArray, Core) -- CREATED NEW OBJECT FOR A SPECIFIC FRAME
	local myObj = {}
	setmetatable(myObj, CustomUIListLayout)
	
	myObj.Frame = frame
	myObj.CurrentBox = nil
	myObj.CurrentOrderList = frameArray
	myObj.DragEvent = nil
	myObj.DraggedBox = nil
	myObj.Core = _G.Core
	print(myObj.Core)
	return myObj
end

function CustomUIListLayout:Disconnect() -- DELETES OBJECT
	self:StopDragging()
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


return CustomUIListLayout