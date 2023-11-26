local function ItemName(text)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "ItemName",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.054, 0, 0.15, 0),
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

local function MaterialEntry(text, amount, position, position_spacers)
	local Core = _G.Core

	return Core.Fusion.New("TextLabel")({
		Name = "MatEntry",
		AnchorPoint = Vector2.new(0, 0),
		Position = position,
		Size = UDim2.new(0.275, 0, 0.173, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(160, 160, 160),
		BackgroundTransparency = 1,
		Visible = true,
		Text = `{text} - x{amount}`,
		[Core.Fusion.OnChange("AbsoluteSize")] = function(new_size)
			position:set(UDim2.new(0.054, position_spacers[1] * new_size.X, 0.5, position_spacers[2] * new_size.Y))
		end,
	})
end

local function CraftingButton(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()

	local button_ref = Fusion.Value()
	local y_pos, x_pos = 0, 0
	local button_color = Fusion.Value(Color3.fromRGB(255, 255, 255))
	local item_arr = Fusion.ForPairs(props.ItemData.Materials, function(index, entry)
		local position = Fusion.Value(UDim2.new(0.054, x_pos * 50, 0.5, y_pos * 25))
		local spacers = { x_pos, y_pos }
		y_pos += 1
		if y_pos > 1 then
			y_pos = 0
			x_pos += 1
		end

		return index, MaterialEntry(entry[1], entry[2], position, spacers)
	end, function(index, button)
		button:Destroy()
	end)

	local function getColor()
		local player_data = Core.ReplicaServiceManager.GetData()
		for _, mat_entry in props.ItemData.Materials do
			if not player_data.Items[mat_entry[1]] or player_data.Items[mat_entry[1]].Amount < mat_entry[2] then
				return Color3.fromRGB(175, 175, 175)
			end
		end
		return Color3.fromRGB(255, 255, 255)
	end

	button_color:set(getColor())

	Maid:GiveTask(Core.Subscribe("ReplicaUpdate", function()
		button_color:set(getColor())
	end))

	return Fusion.Hydrate(Core.UI.Crafting.CraftingButton:Clone())({
		Name = props.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageColor3 = button_color,
		Visible = true,
		[Fusion.Ref] = button_ref,
		[Fusion.Children] = {
			ItemName(props.ItemName),
			item_arr,
		},
		[Core.Fusion.OnEvent("Activated")] = function(_, numClicks)
			print("Crafting: ", props.ItemName)
			Core.Utils.Net:RemoteEvent("Crafting"):FireServer(props.ItemId)
		end,
		[Fusion.Cleanup] = function()
			Maid:DoCleaning()
			print("Destructor called for ItemButton!")
		end,
	})
end

return CraftingButton
