local CursorBar = {
	UIType = "Core",
}
CursorBar.__index = CursorBar
local UserInputService = game:GetService("UserInputService")
local DEFAULT_TWEEN_INFO: TweenInfo = TweenInfo.new(0.05)

function CursorBar:mount()
	local mouse_pos = UserInputService:GetMouseLocation()

	self.frame = self.Fusion.Value()
	self._charge_size = self.Fusion.Value(UDim2.fromScale(0, 1))
	self._size_tween = self.Fusion.Tween(self._charge_size, DEFAULT_TWEEN_INFO)
	self._frame_pos = self.Fusion.Value(UDim2.new(0, mouse_pos.X, 0, mouse_pos.Y + 95))

	self._main_frame_size = self.Fusion.Value(UDim2.fromScale(0, 0.004))
	local main_frame_size_tween = self.Fusion.Tween(self._main_frame_size, TweenInfo.new(0.25))

	self._core_maid.BlindUI = self.Fusion.New("ScreenGui")({
		Parent = self.Core.PlayerGui,
		Name = "CursorBar",
		IgnoreGuiInset = true,
		Enabled = true,
		[self.Fusion.Children] = {
			self.Fusion.New("Frame")({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = self._frame_pos,
				BackgroundColor3 = Color3.fromRGB(99, 99, 99),

				Size = main_frame_size_tween,
				BackgroundTransparency = 0,
				[self.Fusion.Children] = {
					self.Fusion.New("Frame")({
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						Size = self._size_tween,
						BackgroundTransparency = 0,
						[self.Fusion.Ref] = self.frame,
					}),
				},
			}),
		},
	})

	return self.frame
end

function CursorBar:Set(percentage)
	self._charge_size:set(UDim2.fromScale(percentage, 1))
end

function CursorBar:TrackMouse(status: boolean)
	if status then
		self._core_maid.MouseMoveEvent = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local x_new = input.Position.X
				local y_pos = input.Position.Y + 65
				self._frame_pos:set(UDim2.new(0, x_new, 0, y_pos))
			end
		end)
	else
		self._core_maid.MouseMoveEvent = nil
	end
end

function CursorBar:ChangeVisibility(status: boolean)
	if status then
		self:Show()
	else
		self:Hide()
	end
end

function CursorBar:Show()
	self:TrackMouse(true)
	self._main_frame_size:set(UDim2.fromScale(0.009, 0.004))
end

function CursorBar:Hide()
	self._main_frame_size:set(UDim2.fromScale(0, 0.004))
	self:Reset()
	self:TrackMouse(false)
end

function CursorBar:Fill(fill_time: number)
	self._size_tween.tweenInfo = TweenInfo.new(fill_time)
	self:Set(1)
end

function CursorBar:Reset()
	self._size_tween.tweenInfo = DEFAULT_TWEEN_INFO
	self._charge_size:set(UDim2.fromScale(0, 1))
end

function CursorBar:GetFrameObject()
	return self.frame
end

function CursorBar.new()
	local self = setmetatable({}, CursorBar)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	return self
end

function CursorBar:Destroy()
	self._core_maid:DoCleaning()
	self._size_tween = nil
	self._stat_bars = nil
	self._toolbar = nil
end

return CursorBar
