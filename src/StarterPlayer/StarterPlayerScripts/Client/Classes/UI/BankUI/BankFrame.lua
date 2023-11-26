local BankButton = require(script.Parent:WaitForChild("BankButton"))

local function PoundTextBox(amount_value)
	local Core = _G.Core
	return Core.Fusion.New("TextBox")({
		Name = "PoundTextBox",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.28, 0, 0.263, 0),
		Size = UDim2.new(0.439, 0, 0.061, 0),

		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(102, 94, 72),

		PlaceholderColor3 = Color3.fromRGB(102, 94, 72),
		PlaceholderText = "",
		Text = amount_value,
		BackgroundTransparency = 1,

		[Core.Fusion.OnChange("Text")] = function(newText)
			local number_representation = tonumber(newText)
			if not number_representation then
				number_representation = 1
			end
			amount_value:set(number_representation)
		end,
		Visible = true,
	})
end

local function PoundButton(action, amount_value)
	local Core = _G.Core
	local Fusion = Core.Fusion
	return Fusion.Hydrate(Core.UI.Bank.PoundButton:Clone())({
		Name = "PoundButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = true,
		Position = UDim2.new(0.729, 0, 0.264, 0),
		Size = UDim2.new(0.396, 0, 0.062, 0),
		[Fusion.Children] = {

			Core.Fusion.New("TextLabel")({
				Name = "ButtonText",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0.568, 0),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,

				TextStrokeTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
				TextScaled = true,
				TextColor3 = Color3.fromRGB(89, 85, 73),
				BackgroundTransparency = 1,
				Visible = true,
				Text = action .. " POUNDS",
			}),
		},
		[Fusion.OnEvent("Activated")] = function()
			print(action)
			Core.Utils.Net:RemoteEvent("Bank"):FireServer("POUNDS", action, amount_value:get())
		end,
		[Fusion.Cleanup] = function()
			print("Destructor called for ItemButton!")
		end,
	})
end

local function BankFrame(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()
	local player_data = Core.ReplicaServiceManager.GetData()

	local amount = 0
	local pound_index = "Pounds"
	if props.Action == "WITHDRAW" then
		pound_index = "BankPounds"
	end

	if player_data and player_data.General[pound_index] then
		amount = player_data.General[pound_index]
	end

	local pound_value = Fusion.Value(amount)

	Maid:GiveTask(Core.Subscribe("PoundsUpdate", function()
		local new_amount = 0

		if player_data and player_data.General[pound_index] then
			new_amount = player_data.General[pound_index]
		end
		pound_value:set(new_amount)
	end))

	local item_buttons = Fusion.ForPairs(player_data.Items, function(index, entry)
		local item_data = Core.ItemDataManager.GetItem(index)

		return index,
			BankButton({
				Name = item_data.Name,
				Id = item_data.Id,
				Action = props.Action,
				ItemIndex = index,
				Visible = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
			})
	end, function(index, button)
		button:Destroy()
	end)

	return Fusion.Hydrate(props.Frame:Clone())({
		Visible = true,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = UDim2.fromScale(0.141, 0.568),
		[Fusion.Children] = {
			PoundTextBox(pound_value),
			PoundButton(props.Action, pound_value),
			Fusion.New("ScrollingFrame")({
				Size = UDim2.fromScale(0.937, 0.637),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.493, 0.65),

				BackgroundTransparency = 1,
				ScrollBarImageColor3 = Color3.fromRGB(91, 84, 64),
				CanvasSize = UDim2.new(0, 0, 2, 0),
				ScrollBarThickness = 5,
				Visible = true,
				Name = "ScrollingFrame",

				[Fusion.Children] = {
					Fusion.New("UIListLayout")({
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0, 3),
					}),

					item_buttons,
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

return BankFrame
