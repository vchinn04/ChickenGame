local function ItemName(text, color_arr)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "ItemName",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),

		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,

		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(color_arr[1], color_arr[2], color_arr[3]),

		BackgroundTransparency = 1,
		Visible = true,
		Text = text,
	})
end

local function Bar(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()
	local size_value = Fusion.Value(UDim2.fromScale(props.Value:get(), 1))
	local spring_size_anim = Fusion.Tween(size_value, TweenInfo.new(0.25))

	local DEFAULT_BAR_COLOR =
		Color3.fromRGB(props.ImageColor3[1] + 35, props.ImageColor3[2] + 35, props.ImageColor3[3] + 35)
	local bar_color_value = Fusion.Value(DEFAULT_BAR_COLOR)
	local bar_color_tween = Fusion.Tween(bar_color_value, TweenInfo.new(0.25))

	local value_observer = Fusion.Observer(props.Value)

	Maid:GiveTask(value_observer:onChange(function()
		local current_progress = props.Value:get()
		if props.LowBarColor and current_progress <= props.LowBarColor[1] then
			bar_color_value:set(Color3.fromRGB(props.LowBarColor[2], props.LowBarColor[3], props.LowBarColor[4]))
		else
			bar_color_value:set(DEFAULT_BAR_COLOR)
		end
		size_value:set(UDim2.fromScale(props.Value:get(), 1))
	end))

	return Fusion.Hydrate(Core.UI.StatBar.BarShadow:Clone())({
		Name = props.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = props.Position,
		Size = props.Size,
		ImageColor3 = Color3.fromRGB(props.ImageColor3[1], props.ImageColor3[2], props.ImageColor3[3]),

		Visible = true,

		[Fusion.Children] = {
			Fusion.Hydrate(Core.UI.StatBar.BarFrame:Clone())({
				Name = props.Name,
				AnchorPoint = Vector2.new(0.5, 0),

				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.fromScale(1, 0.9),
				ImageColor3 = Color3.fromRGB(
					props.ImageColor3[1] + 15,
					props.ImageColor3[2] + 15,
					props.ImageColor3[3] + 15
				),

				Visible = true,

				[Fusion.Children] = {
					Fusion.Hydrate(Core.UI.StatBar.Bar:Clone())({
						Name = props.Name,
						AnchorPoint = Vector2.new(0, 0.5),

						Position = UDim2.fromScale(0, 0.5),
						Size = spring_size_anim,
						ImageColor3 = bar_color_tween,

						Visible = true,
					}),
					ItemName(props.Name, props.ImageColor3),
				},

				[Fusion.Cleanup] = function()
					Maid:DoCleaning()
					print("Destructor called for ItemButton!")
				end,
			}),
		},

		[Fusion.Cleanup] = function()
			Maid:DoCleaning()
			print("Destructor called for ItemButton!")
		end,
	})
end

return Bar
