local UICore = {} 
UICore.__index = UICore 

local TweenService = game:GetService("TweenService")
local frameEntryTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local frameExitTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)

function UICore.new(uiType, enterTweenInfo, exitTweenInfo, enterTweenPosition) 
    local returnTable = setmetatable({ __type = uiType}, UICore)
    local Core = _G.Core
	returnTable.Maid = Core.Utils.Maid.new()
    returnTable.Core = Core 
    returnTable.enterTweenInfo = enterTweenInfo == nil and enterTweenInfo or frameEntryTweenInfo
    returnTable.exitTweenInfo = exitTweenInfo == nil and exitTweenInfo or frameExitTweenInfo
    returnTable.enterTweenPosition = enterTweenPosition == nil and enterTweenPosition or UDim2.new(0.5,0,0.5,0)
    
    return returnTable
end 

function UICore:SetUI(Frame)
    self.uiFrame = Frame
	self.uiFrame.Position = UDim2.new(0.5,0,1.5,0)
	self.uiFrame.Parent = self.Core.MainGui
end

function UICore:TransformEnter() 
	self.uiFrame.Visible = true
	self.Maid.enterTween = TweenService:Create(self.uiFrame, self.enterTweenInfo, {Position = self.enterTweenPosition})
	self.Maid.enterTween:Play() 
end 

function UICore:TransformExit()
	self.Maid.exitTween = TweenService:Create(self.uiFrame, self.exitTweenInfo,{Position =  UDim2.new(0.5,0,1.5,0)})
    self.Maid.exitTween:Play() 
end 

function UICore:Destroy()
    self.Maid:DoCleaning() 
	self.uiFrame.Parent = self.Core.UI
    self.Core = nil
    self.enterTweenInfo = nil
    self.exitTweenInfo = nil 
    self.enterTweenPosition = nil 
    self = nil 
end


return UICore