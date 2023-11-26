local CraftingButton = require(script.Parent:WaitForChild("CraftingButton"))

local function CraftingFrame(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()

	--local item_list = Fusion.Value(Core.ReplicaServiceManager.GetData().Items)

	-- Maid:GiveTask(Core.Subscribe("ReplicaUpdate", function()
	-- 	item_list:set(Core.ReplicaServiceManager.GetData().Items)
	-- end))

	local item_arr = Fusion.ForPairs(Core.Utils.ItemDataManager.GetCraftingTable("Default"), function(index, entry)
		return index,
			CraftingButton({
				Name = index,
				ItemId = index,
				ItemName = index,
				Visible = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				ItemData = entry,
				Size = UDim2.new(0.95, 0, 0, 45),
			})
	end, function(index, button)
		button:Destroy()
	end)

	return Fusion.Hydrate(Core.UI.Crafting.CraftingFrame:Clone())({
		Visible = true,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = UDim2.fromScale(0.132, 0.654),
		[Fusion.Children] = {
			Fusion.New("ScrollingFrame")({
				Size = UDim2.fromScale(0.894, 0.76),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.6),

				BackgroundTransparency = 1,
				ScrollBarImageColor3 = Color3.fromRGB(168, 160, 138),
				CanvasSize = UDim2.new(0, 0, 2, 0),
				ScrollBarThickness = 10,
				Visible = true,
				Name = "ScrollingFrame",
				[Fusion.Children] = {
					Fusion.New("UIListLayout")({
						Padding = UDim.new(0, 16),
					}),
					item_arr,
				},
			}),
		},

		[Fusion.Cleanup] = function()
			print("Cleanup for : ", props.Name, " was called!")
			Maid:DoCleaning()
			Maid = nil
		end,
	})
end

return CraftingFrame
