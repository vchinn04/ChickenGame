local function SectionIcon(icon)
	local Core = _G.Core
	return Core.Fusion.New("ImageLabel")({
		Name = "ItemIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.043, 0, 0.5, 0),
		Size = UDim2.new(0.184, 0, 0.707, 0),
		BackgroundTransparency = 1,
		Image = icon,
		ImageTransparency = 0,
		Visible = true,
	})
end

local function SectionName(text)
	local Core = _G.Core

	return Core.Fusion.New("TextLabel")({
		Name = "SectionName",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0.258, 0, 0.259, 0),
		Size = UDim2.new(0.506, 0, 0.442, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(168, 160, 138),
		BackgroundTransparency = 1,
		Visible = true,
		Text = text,
	})
end

local function SectionButton(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()

	return Fusion.Hydrate(Core.UI.GeneralStore.SectionButton:Clone())({
		Name = props.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = true,
		[Fusion.Children] = {
			SectionName(props.SectionName),
			SectionIcon(props.SectionIcon),
		},
		[Core.Fusion.OnEvent("Activated")] = function(_, numClicks)
			props.SectionValue:set(props.SectionName)
		end,
		[Fusion.Cleanup] = function()
			Maid:DoCleaning()
			print("Destructor called for ItemButton!")
		end,
	})
end

return SectionButton
