local function ItemName(text)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "ItemName",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.288, 0, 0.19, 0),
		Size = UDim2.new(0.395, 0, 0.231, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeColor3 = Color3.fromRGB(80, 80, 80),
		TextStrokeTransparency = 0,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(160, 160, 160),
		BackgroundTransparency = 1,
		Visible = true,
		Text = text,
	})
end

local function Price(price)
	local Core = _G.Core
	local item_price = if price then price else 0
	return Core.Fusion.New("TextLabel")({
		Name = "ItemName",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.288, 0, 0.483, 0),
		Size = UDim2.new(0.366, 0, 0.181, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeColor3 = Color3.fromRGB(129, 110, 3),
		TextStrokeTransparency = 0,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(193, 165, 6),
		BackgroundTransparency = 1,
		Visible = true,
		Text = "£" .. item_price,
	})
end

local function AmountBox(amount_value)
	local Core = _G.Core
	return Core.Fusion.New("TextBox")({
		Name = "AmountBox",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.381, 0, 0.751, 0),
		Size = UDim2.new(0.191, 0, 0.271, 0),

		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextStrokeColor3 = Color3.fromRGB(42, 42, 42),
		TextStrokeTransparency = 0,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(160, 160, 160),

		PlaceholderColor3 = Color3.fromRGB(160, 160, 160),
		PlaceholderText = "1",

		BackgroundColor3 = Color3.fromRGB(76, 76, 76),
		BackgroundTransparency = 0,
		[Core.Fusion.Children] = {
			Core.Fusion.New("UICorner")({
				CornerRadius = UDim.new(0, 3),
			}),
		},
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

local function OwnedAmountLabel(item_id, amount_val)
	local Core = _G.Core

	return Core.Fusion.New("TextLabel")({
		Name = "OwnedAmount",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.585, 0, 0.476, 0),
		Size = UDim2.new(0.366, 0, 0.181, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextStrokeColor3 = Color3.fromRGB(80, 80, 80),
		TextStrokeTransparency = 0,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(160, 160, 160),
		BackgroundTransparency = 1,
		Visible = true,
		Text = Core.Fusion.Computed(function()
			return amount_val:get() .. " in Inventory"
		end),
	})
end

local function PurchaseButton(item_id, action, transaction_amount, store_id, section, item_index)
	local Core = _G.Core
	local Fusion = Core.Fusion
	return Fusion.Hydrate(Core.UI.GeneralStore.PurchaseButton:Clone())({
		Name = "PurchaseButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = true,
		Position = UDim2.new(0.769, 0, 0.75, 0),
		Size = UDim2.new(0.407, 0, 0.254, 0),
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
		[Fusion.OnEvent("Activated")] = function(_, numClicks)
			print("Transaction of: ", transaction_amount:get(), " items.")

			Core.Utils.Net
				:RemoteEvent("Store")
				:FireServer(item_id, transaction_amount:get(), action, `{store_id}/{section}/{item_index}`)
		end,
		[Fusion.Cleanup] = function()
			print("Destructor called for ItemButton!")
		end,
	})
end

local function StoreButton(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()
	local transaction_amount = Fusion.Value(1)
	local item_data = Core.ReplicaServiceManager.GetItem("Items/" .. props.Id)

	local amount = 0
	if item_data and item_data.Amount then
		amount = item_data.Amount
	end
	local owned_amount_val = Fusion.Value(amount)

	Maid:GiveTask(Core.Subscribe("ReplicaUpdate", function()
		local new_amount = 0
		if item_data and item_data.Amount then
			new_amount = item_data.Amount
		end
		owned_amount_val:set(new_amount)
	end))

	local status = if props.Section == "Sell" then "SELL" else "PURCHASE"
	return Fusion.Hydrate(Core.UI.GeneralStore.StoreButton:Clone())({
		Name = props.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),

		Visible = Fusion.Computed(function()
			if props.Section ~= "Sell" then
				return true
			end
			return owned_amount_val:get() > 0
		end),

		[Fusion.Children] = {
			ItemName(props.Name),
			Price(props.Price),
			AmountBox(transaction_amount),
			PurchaseButton(props.Id, status, transaction_amount, props.StoreId, props.Section, props.ItemIndex),
			OwnedAmountLabel(props.Id, owned_amount_val),
		},

		[Fusion.Cleanup] = function()
			Maid:DoCleaning()
			print("Destructor called for ItemButton!")
		end,
	})
end

return StoreButton
