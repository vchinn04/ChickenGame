local function ItemText(text)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "ItemName",
		Position = UDim2.new(0.16, 0, 0.262, 0),
		Size = UDim2.new(0.506, 0, 0.442, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(168, 160, 138),
		BackgroundTransparency = 1,
		Visible = true,
		Text = text,
	})
end

local function ItemAmount(amount)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "Amount",
		Position = UDim2.new(0.938, 0, 0.435, 0),
		Size = UDim2.new(0.061, 0, 0.442, 0),
		TextSize = 14,
		TextColor3 = Color3.fromRGB(168, 160, 138),
		BackgroundTransparency = 1,
		Visible = true,
		Text = amount,
	})
end

local function ItemButton(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local is_dragging = Fusion.Value(false)
	print("Constructor called")
	return Fusion.Hydrate(Core.UI.Inventory.ItemButtonTemplate:Clone())({
		Name = props.Name,
		Size = props.Size,
		Parent = props.Parent,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Visible = props.Visible,

		[Fusion.Out("AbsoluteSize")] = props.AbsoluteSizeOut,
		[Fusion.Out("AbsolutePosition")] = props.AbsolutePositionOut,

		[Fusion.Children] = {
			ItemText(props.Name),
			ItemAmount(props.Amount),
		},

		[Fusion.OnEvent("MouseButton1Down")] = function()
			if props.Dummy then
				return
			end
			props.DragEvent:set(props.Index:get())
		end,

		[Fusion.OnEvent("MouseButton1Up")] = function()
			if props.Dummy then
				return
			end
			props.DragEvent:set(nil)
		end,

		[Fusion.OnEvent("MouseButton2Click")] = function()
			if props.Dummy then
				return
			end
			Core.Fire("InventoryAction", "USE", props.ItemData, nil)
		end,

		[Fusion.Cleanup] = function()
			print("Destructor called for ItemButton!")
		end,
	})
end

return ItemButton
