local function HUDButtonText(Core, text)
	print(text)
	return Core.Fusion.New("TextLabel")({
		Name = "Button_Name",
		Position = UDim2.new(0, 0, 0.7, 0),
		Size = UDim2.new(1, 0, 0.22, 0),
		TextSize = 14,
		TextColor3 = Color3.fromRGB(149, 141, 117),
		BackgroundTransparency = 1,
		Visible = true,
		Text = text,
	})
end

local function HUDButton(Core, props)
	print(props)
	return Core.Fusion.Hydrate(Core.UI.HUD_Button_Template:Clone())({
		Name = props.Name,
		LayoutOrder = props.Index,
		Visible = true,
		[Core.Fusion.Children] = {
			HUDButtonText(Core, props.Name),
		},
		[Core.Fusion.OnEvent("Activated")] = function(_, numClicks)
			print("Button Pressed!")
			Core.Fire("OpenUI", props.Name)
		end,
		[Core.Fusion.Cleanup] = function()
			print("Cleanup for : ", props.Name, " was called!")
		end,
	})
end

return HUDButton
