local function ItemName(text)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "ItemName",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.288, 0, 0.19, 0),
		Size = UDim2.new(0.668, 0, 0.231, 0),

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
		Size = UDim2.new(0.281, 0, 0.184, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeColor3 = Color3.fromRGB(80, 80, 80),
		TextStrokeTransparency = 0,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(160, 160, 160),
		BackgroundTransparency = 1,
		Visible = true,
		Text = amount_val,
	})
end

local function ActionButton(item_id, action)
	local Core = _G.Core
	local Fusion = Core.Fusion
	return Fusion.Hydrate(Core.UI.Bank.ActionButton:Clone())({
		Name = "ActionButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = true,
		Position = UDim2.new(0.707, 0, 0.694, 0),
		Size = UDim2.new(0.289, 0, 0.257, 0),
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
				Text = action,
			}),
		},
		[Fusion.OnEvent("Activated")] = function()
			print(action)
			Core.Utils.Net:RemoteEvent("Bank"):FireServer(item_id, action)
		end,
		[Fusion.Cleanup] = function()
			print("Destructor called for ItemButton!")
		end,
	})
end

local function BankButton(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()
	local item_data = Core.ReplicaServiceManager.GetItem("Items/" .. props.Id)

	local amount = 0
	if item_data then
		if props.Action == "DEPOSIT" and item_data.Amount then
			amount = item_data.Amount
		elseif props.Action == "WITHDRAW" and item_data.BankAmount then
			amount = item_data.BankAmount
		end
	end
	local owned_amount_val = Fusion.Value(amount)

	Maid:GiveTask(Core.Subscribe("ReplicaUpdate", function()
		local new_amount = 0
		if item_data then
			if props.Action == "DEPOSIT" and item_data.Amount then
				new_amount = item_data.Amount
			elseif props.Action == "WITHDRAW" and item_data.BankAmount then
				new_amount = item_data.BankAmount
			end
		end
		owned_amount_val:set(new_amount)
	end))

	return Fusion.Hydrate(Core.UI.Bank.BankButton:Clone())({
		Name = props.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),

		Visible = Fusion.Computed(function()
			return owned_amount_val:get() > 0
		end),

		[Fusion.Children] = {
			ItemName(props.Name),
			AmountLabel(owned_amount_val),
			ActionButton(props.Id, props.Action),
		},

		[Fusion.Cleanup] = function()
			Maid:DoCleaning()
			print("Destructor called for ItemButton!")
		end,
	})
end

return BankButton
