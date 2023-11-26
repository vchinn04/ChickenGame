local function ItemName(text)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "ItemName",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.288, 0, 0.19, 0),
		Size = UDim2.new(0.395, 0, 0.231, 0),

		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(160, 160, 160),

		BackgroundTransparency = 1,
		Visible = true,
		Text = text,
	})
end

local function AmountLabel(amount_val)
	local Core = _G.Core

	return Core.Fusion.New("TextLabel")({
		Name = "AmountLabel",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.285, 0, 0.476, 0),
		Size = UDim2.new(0.366, 0, 0.181, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(160, 160, 160),
		BackgroundTransparency = 1,
		Visible = true,
		Text = amount_val,
	})
end

local function ActionButton(item_id, interaction_object)
	local Core = _G.Core
	local Fusion = Core.Fusion
	return Fusion.Hydrate(Core.UI.Looting.ActionButton:Clone())({
		Name = "ActionButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = true,
		Position = UDim2.new(0.707, 0, 0.694, 0),
		Size = UDim2.new(0, 123, 0, 26),
		[Fusion.Children] = {

			Core.Fusion.New("TextLabel")({
				Name = "ButtonText",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0.568, 0),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextStrokeTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
				TextScaled = true,
				TextColor3 = Color3.fromRGB(168, 160, 138),
				BackgroundTransparency = 1,
				Visible = true,
				Text = "Loot",
			}),
		},
		[Fusion.OnEvent("Activated")] = function()
			interaction_object:ClaimItem(item_id)
		end,
		[Fusion.Cleanup] = function()
			print("Destructor called for ItemButton!")
		end,
	})
end

local function LootingButton(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()
	local item_data = props.ItemPlayerData

	local amount = 0
	if item_data then
		amount = item_data.Amount
		if not amount then
			amount = 0
		end
	end

	local owned_amount_val = Fusion.Value(amount)

	Maid:GiveTask(Core.Subscribe("StrangerReplicaUpdate", function(ItemPath, replica_class)
		if replica_class ~= props.ReplicaClass then
			return
		end
		local new_amount = 0
		if item_data then
			new_amount = item_data.Amount
			if not amount then
				new_amount = 0
			end
		end
		owned_amount_val:set(new_amount)
	end))

	return Fusion.Hydrate(Core.UI.Looting.LootingButton:Clone())({
		Name = props.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = props.Size,
		Visible = Fusion.Computed(function()
			return owned_amount_val:get() > 0
		end),

		[Fusion.Children] = {
			ItemName(props.Name),
			AmountLabel(owned_amount_val),
			ActionButton(props.Id, props.InteractionObject),
		},

		[Fusion.Cleanup] = function()
			Maid:DoCleaning()
			item_data = nil
			print("Destructor called for LootingButton!")
		end,
	})
end

return LootingButton
