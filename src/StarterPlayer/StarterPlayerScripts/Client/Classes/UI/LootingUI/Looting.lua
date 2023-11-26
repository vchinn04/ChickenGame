local Looting = {}
Looting.__index = Looting

local LootingButton = require(script.Parent:WaitForChild("LootingButton"))

function Looting:FetchData(replica_class)
	local data = self.Core.ReplicaServiceManager.GetStrangerData(replica_class)
	local retry_count = 10
	while not data and retry_count > 0 do
		data = self.Core.ReplicaServiceManager.GetStrangerData(replica_class)
		retry_count -= 1
		task.wait(1)
	end
	return data
end

function Looting:mount()
	self._interaction_object:Register()
	local goalPosition = self.Core.Fusion.Value(UDim2.new(0.5, 0, 1.2, 0))
	local animated = self.Core.Fusion.Spring(goalPosition, 10, 0.65)

	local screen_gui_ref = self.Fusion.Value()

	local replica_class = self._interaction_object:GetPlayer().Name .. "PlayerData"
	local player_data = self:FetchData(replica_class)

	local item_buttons = nil

	if player_data then
		item_buttons = self.Fusion.ForPairs(player_data.Items, function(index, entry)
			local item_data = self.Core.ItemDataManager.GetItem(index)

			return index,
				LootingButton(setmetatable({
					Name = item_data.Name,
					Size = UDim2.fromScale(0.966, 0.09),
					Id = index,
					ItemPlayerData = entry,
					InteractionObject = self._interaction_object,
					ReplicaClass = replica_class,
				}, { __mode = "k" }))
		end, function(index, button)
			button:Destroy()
		end)
	end
	self._core_maid.InventoryScreenGui = self.Fusion.New("ScreenGui")({
		Name = "Looting",
		Parent = self.Core.PlayerGui,
		IgnoreGuiInset = true,
		Enabled = true,
		[self.Fusion.Children] = self.Fusion.New("Frame")({
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Visible = true,
			[self.Fusion.Ref] = screen_gui_ref,

			[self.Fusion.Children] = {
				self.Fusion.Hydrate(self.Core.UI.Looting:WaitForChild("LootingFrame"):Clone())({
					Visible = true,
					Position = animated,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(0.162, 0.667),

					[self.Fusion.Children] = {
						self.Fusion.New("ScrollingFrame")({
							Size = UDim2.fromScale(0.937, 0.71),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.613),

							BackgroundTransparency = 1,
							ScrollBarImageColor3 = Color3.fromRGB(91, 84, 64),
							CanvasSize = UDim2.new(0, 0, 2, 0),
							ScrollBarThickness = 5,
							Visible = true,
							Name = "ScrollingFrame",

							[self.Fusion.Children] = {
								self.Fusion.New("UIListLayout")({
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
									VerticalAlignment = Enum.VerticalAlignment.Top,
									Padding = UDim.new(0, 3),
								}),
								item_buttons,
							},
						}),
					},
				}),
			},
		}),
	})
	goalPosition:set(UDim2.new(0.782, 0, 0.499, 0))

	print("Created Looting")
end

function Looting.new(interaction_object: { [string]: any })
	local self = setmetatable({}, Looting)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	self._interaction_object = interaction_object
	return self
end

function Looting:Destroy()
	self._core_maid:DoCleaning()
	self._interaction_object = nil
	print("Cleanup")
end

return Looting
