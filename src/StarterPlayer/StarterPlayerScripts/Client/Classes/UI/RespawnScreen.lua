local RespawnScreen = {
	UIType = "Core",
}
RespawnScreen.__index = RespawnScreen
local ContextActionService = game:GetService("ContextActionService")

local function TimerText(timer_val)
	local Core = _G.Core

	return Core.Fusion.New("TextLabel")({
		Name = "TimerText",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.71, 0),
		Size = UDim2.new(1, 0, 0.305, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Regular),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(100, 91, 66),
		BackgroundTransparency = 1,
		Visible = true,
		Text = Core.Fusion.Computed(function()
			return if timer_val:get() > 0 then "in " .. timer_val:get() .. " seconds" else "Press R"
		end),
	})
end

function RespawnScreen:mount()
	local current_timer = self.Core.Player:GetAttribute("RespawnTimer")
	if not current_timer then
		current_timer = 10
	end
	local respawn_timer_value = self.Fusion.Value(current_timer)
	self._core_maid:GiveTask(self.Core.Player:GetAttributeChangedSignal("RespawnTimer"):Connect(function()
		local new_timer = self.Core.Player:GetAttribute("RespawnTimer")
		if not new_timer then
			new_timer = 0
		end
		print("Respawn Timer: ", new_timer)
		respawn_timer_value:set(new_timer)
	end))

	self._core_maid:GiveBindAction("RespawnBinding")
	ContextActionService:BindAction("RespawnBinding", function()
		if respawn_timer_value:get() > 0 then
			return
		end
		self.Core.Utils.Net:RemoteEvent("RespawnPlayer"):FireServer()
	end, false, Enum.KeyCode.R)

	self._core_maid.DeathScreenGui = self.Fusion.New("ScreenGui")({
		Parent = self.Core.PlayerGui,
		Name = "RespawnScreen",
		IgnoreGuiInset = true,
		Enabled = true,
		[self.Fusion.Children] = {
			self.Fusion.Hydrate(self.Core.UI.DeathScreen:Clone())({
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.5, 0.5),

				ImageTransparency = 0,
				Visible = true,

				[self.Fusion.Children] = {
					self.Fusion.Hydrate(self.Core.UI.RespawnButton:Clone())({
						Name = "RespawnButton",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.79),
						Size = UDim2.new(0.093, 0, 0, 59),
						Visible = true,
						ImageColor3 = self.Fusion.Tween(
							self.Fusion.Computed(function()
								return if respawn_timer_value:get() > 0
									then Color3.fromRGB(189, 189, 189)
									else Color3.fromRGB(255, 255, 255)
							end),
							TweenInfo.new(0.25)
						),
						[self.Fusion.Children] = {
							TimerText(respawn_timer_value),
						},
						[self.Fusion.OnEvent("Activated")] = function()
							if respawn_timer_value:get() > 0 then
								return
							end
							self.Core.Utils.Net:RemoteEvent("RespawnPlayer"):FireServer()
						end,
						[self.Fusion.Cleanup] = function()
							print("Destructor called for RespawnButton!")
						end,
					}),
				},
			}),
		},
	})

	print("Created RespawnScreen")
end

function RespawnScreen.new()
	local self = setmetatable({}, RespawnScreen)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	return self
end

function RespawnScreen:Destroy()
	self._core_maid:DoCleaning()
	self._stat_bars = nil
	self._toolbar = nil
end

return RespawnScreen
