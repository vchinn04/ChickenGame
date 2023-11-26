local StatBars = {
	UIType = "Core",
}
StatBars.__index = StatBars

local Bar = require(script.Parent.Bar)

function StatBars:mount()
	print("Mount StatBars")
	self._toolbar_button_data = {}
	local stamina_value = self.Fusion.Value(1)
	local health_value = self.Fusion.Value(1)
	local hunger_value = self.Fusion.Value(1)
	local player_data = self.Core.ReplicaServiceManager.GetData()

	health_value:set(self.Core.Humanoid.Health / self.Core.Humanoid.MaxHealth)
	self._core_maid:GiveTask(self.Core.Humanoid.HealthChanged:Connect(function(health)
		health_value:set(health / self.Core.Humanoid.MaxHealth)
	end))

	local current_stamina = self.Core.ActionStateManager:getState().Stamina
	if current_stamina then
		stamina_value:set(current_stamina / 100)
	end
	self._core_maid:GiveTask(self.Core.ActionStateManager.changed:connect(function(newState, _)
		local new_stamina = if newState.Stamina then newState.Stamina else 1
		stamina_value:set(new_stamina / 100)
	end))

	local hunger_amount = 100
	local max_hunger = 100

	if player_data and player_data.General.Hunger then
		hunger_amount = player_data.General.Hunger
	end
	if player_data and player_data.General.MaxHunger then
		max_hunger = player_data.General.MaxHunger
	end
	hunger_value:set(hunger_amount / max_hunger)
	self._core_maid:GiveTask(self.Core.Subscribe("HungerUpdate", function()
		local new_amount = 100
		local new_max_hunger = 100

		if player_data and player_data.General.Hunger then
			new_amount = player_data.General.Hunger
		end
		if player_data and player_data.General.MaxHunger then
			new_max_hunger = player_data.General.MaxHunger
		end
		hunger_value:set(new_amount / new_max_hunger)
	end))

	self._core_maid.HUD_ScreenGui = self.Fusion.New("ScreenGui")({
		Parent = self.Core.PlayerGui,
		Name = "StatBars",
		[self.Fusion.Children] = {

			self.Fusion.New("Frame")({
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.5, 0.15),
				Position = UDim2.fromScale(0.5, 0.95),
				Visible = true,

				[self.Fusion.Children] = {
					Bar({
						Name = "STAMINA",
						Position = UDim2.fromScale(0.5, 0.25),
						Size = UDim2.fromScale(0.8, 0.125),
						ImageColor3 = { 68, 85, 80 },
						Value = stamina_value,
						LowBarColor = { 0.25, 117, 53, 54 }, -- [1] - Low Threshhold, [2 - 4] - RGB of low color
					}),

					Bar({
						Name = "HEALTH",
						Position = UDim2.fromScale(0.702, 0.5),
						Size = UDim2.fromScale(0.395, 0.19),
						ImageColor3 = { 71, 39, 40 },
						Value = health_value,
					}),

					Bar({
						Name = "HUNGER",
						Position = UDim2.fromScale(0.298, 0.5),
						Size = UDim2.fromScale(0.395, 0.19),
						ImageColor3 = { 63, 48, 36 },
						Value = hunger_value,
					}),
				},
			}),
		},
	})
end

function StatBars.new()
	local self = setmetatable({}, StatBars)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	return self
end

function StatBars:Destroy()
	self._core_maid:DoCleaning()
end

return StatBars
