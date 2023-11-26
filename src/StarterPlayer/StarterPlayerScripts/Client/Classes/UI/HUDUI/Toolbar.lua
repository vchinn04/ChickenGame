local Toolbar = {
	UIType = "Core",
}
Toolbar.__index = Toolbar

local ContextActionService = game:GetService("ContextActionService")
local KEY_MAP = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
	[Enum.KeyCode.Zero] = 10,
}

local DEFAULT_TOOLBAR_PRIORITIES = {
	Primary = 1,
	Secondary = 2,
	Melee = 3,
	Healing = 4,
	Tool = 5,
}

local VALID_CATEGORIES = {
	["Tool"] = true,
	["Melee"] = true,
	["Primary"] = true,
	["Secondary"] = true,
	["Healing"] = true,
}

local function ItemName(text)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "ItemName",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.85, 0),
		Size = UDim2.new(1, 0, 0.176, 0),

		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Bottom,

		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(118, 112, 97),

		BackgroundTransparency = 1,
		Visible = true,
		Text = text,
	})
end

local function ItemKey(key_value)
	local Core = _G.Core
	return Core.Fusion.New("TextLabel")({
		Name = "ItemKey",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.243, 0, 0.13, 0),
		Size = UDim2.new(0.365, 0, 0.257, 0),

		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,

		TextStrokeTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Light),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(118, 112, 97),

		BackgroundTransparency = 1,
		Visible = true,
		Text = key_value,
	})
end

local binary_insert = function(array, item, priority)
	for button_index, entry in array do
		if entry.Priority >= priority then
			table.insert(array, button_index, item)
			return
		end
	end
	table.insert(array, item)
end

function Toolbar:mount()
	print("Mount Toolbar")
	local backpack_list = self.Fusion.Value(self.Core.ReplicaServiceManager.GetData().Items)
	self._toolbar_button_data = {}

	local current_equipped_item = self.Fusion.Value(nil)

	self._core_maid.toolbar_button_list = self.Fusion.ForPairs(backpack_list, function(index, entry)
		if not entry.Equipped then
			return index, nil
		end

		local item_data = self.Core.ItemDataManager.GetItem(entry.Id)

		if not VALID_CATEGORIES[item_data.Category] then
			return index, nil
		end

		local button_index = self.Fusion.Value(1)

		local item_priority = item_data.ToolbarPriority

		if not item_priority then
			local tool_category = item_data.Category
			if tool_category then
				item_priority = DEFAULT_TOOLBAR_PRIORITIES[tool_category]
			end
		end

		if not item_priority then
			item_priority = 6
		end

		binary_insert(self._toolbar_button_data, {
			Data = item_data,
			IndexValue = button_index,
			Priority = item_priority,
		}, item_priority)

		for i, v in self._toolbar_button_data do
			v.IndexValue:set(i)
		end

		return button_index,
			self.Fusion.Hydrate(self.Core.UI.ToolbarTemplate:Clone())({
				Name = index,
				Size = UDim2.new(0.085, 0, 0.85, 0),
				LayoutOrder = button_index,
				[self.Fusion.Children] = {
					self.Fusion.New("UIScale")({
						Scale = self.Fusion.Tween(
							self.Fusion.Computed(function()
								return if current_equipped_item:get() == item_data.Name then 1.15 else 1
							end),
							TweenInfo.new(0.15)
						),
					}),
					ItemName(item_data.Name),
					ItemKey(button_index),
				},
				[self.Fusion.OnEvent("Activated")] = function()
					local current_equipped = self.Core.ToolsStateManager:getState().EquippedItem
					if current_equipped ~= item_data.Name then
						self.Core.Fire("ItemEquip", item_data.Name)
					else
						self.Core.Fire("ItemEquip", nil)
					end
				end,
			})
	end, function(index, button)
		table.remove(self._toolbar_button_data, index:get())
		button:Destroy()
	end)

	self._core_maid:GiveTask(self.Core.Subscribe("ReplicaUpdate", function(item_path, action)
		local path_list = string.split(item_path, "/")
		local item_key = path_list[#path_list]

		for index, key in path_list do
			if key == "Items" then
				item_key = path_list[(index + 1)]
				break
			end
		end

		local table_data = self.Core.ReplicaServiceManager.GetData().Items
		local item_entry = table_data[item_key]
		local item_data = self.Core.ItemDataManager.GetItem(item_entry.Id)

		if not VALID_CATEGORIES[item_data.Category] then
			return
		end

		backpack_list:set(table_data, true, { [item_key] = true })
	end))

	self._core_maid:GiveTask(self.Core.ToolsStateManager.changed:connect(function()
		current_equipped_item:set(self.Core.ToolsStateManager:getState().EquippedItem)
		for i, v in self._toolbar_button_data do
			v.IndexValue:set(i)
		end
	end))

	self._core_maid:GiveBindAction("Toolbar")
	ContextActionService:BindAction(
		"Toolbar",
		function(_, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				local item_index = KEY_MAP[inputObject.KeyCode]
				if item_index <= #self._toolbar_button_data then
					local item_data = self._toolbar_button_data[item_index].Data
					local current_equipped = self.Core.ToolsStateManager:getState().EquippedItem
					if current_equipped ~= item_data.Name then
						self.Core.Fire("ItemEquip", item_data.Name)
					else
						self.Core.Fire("ItemEquip", nil)
					end
				end
			end
		end,
		false,
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.Five,
		Enum.KeyCode.Six,
		Enum.KeyCode.Seven,
		Enum.KeyCode.Eight,
		Enum.KeyCode.Nine,
		Enum.KeyCode.Zero
	)

	self._core_maid.HUD_ScreenGui = self.Fusion.New("ScreenGui")({
		Parent = self.Core.PlayerGui,
		Name = "Toolbar",
		[self.Fusion.Children] = {

			self.Fusion.New("Frame")({
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.5, 0.15),
				Position = UDim2.fromScale(0.5, 0.81),
				Visible = true,
				[self.Fusion.Children] = {
					self.Fusion.New("UIListLayout")({
						SortOrder = "LayoutOrder",
						Padding = UDim.new(0, 9),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					self._core_maid.toolbar_button_list,
				},
			}),
		},
	})
end

function Toolbar.new()
	local self = setmetatable({}, Toolbar)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	return self
end

function Toolbar:Destroy()
	self._core_maid:DoCleaning()
end

return Toolbar
