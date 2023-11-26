local Inventory = {}
Inventory.__index = Inventory

local BackpackFrame = require(script.Parent:WaitForChild("BackpackFrame"))
local EquippedFrame = require(script.Parent:WaitForChild("EquippedFrame"))

local UserInputService = game:GetService("UserInputService")

function Inventory:mount()
	local goalPosition = self.Core.Fusion.Value(UDim2.new(0.5, 0, 1.2, 0))
	local animated = self.Core.Fusion.Spring(goalPosition, 10, 0.65)

	local goalPosition2 = self.Core.Fusion.Value(UDim2.new(0.5, 0, 1.2, 0))
	local animated2 = self.Core.Fusion.Spring(goalPosition2, 10, 0.65)

	local goalPosition3 = self.Core.Fusion.Value(UDim2.new(0.5, 0, 1.2, 0))
	local animated3 = self.Core.Fusion.Spring(goalPosition3, 10, 0.65)
	local screen_gui_ref = self.Fusion.Value()

	local sort_status = self.Fusion.Value(false)
	self._core_maid:GiveTask(
		self.Core.Subscribe("DragAction", function(item_data: { [string]: any }, current_state: string)
			local mouse_position = UserInputService:GetMouseLocation()
			local ui_object_list: { [number]: Instance } =
				self.Core.PlayerGui:GetGuiObjectsAtPosition(mouse_position.X, mouse_position.Y)

			local action: string = "DROP"
			for _, object in ui_object_list do
				if object.Name == "Equipped" then
					action = "EQUIP"
					break
				elseif object.Name == "Backpack" then
					action = "STORE"
				end
			end
			if current_state ~= action then
				self.Core.Fire("InventoryAction", action, item_data, current_state)
			end
		end)
	)

	self._core_maid.InventoryScreenGui = self.Fusion.New("ScreenGui")({
		Name = "Inventory",
		Parent = self.Core.PlayerGui,
		IgnoreGuiInset = true,
		Enabled = true,
		[self.Fusion.Children] = self.Fusion.New("Frame")({
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Visible = true,
			[self.Fusion.Ref] = screen_gui_ref,

			[self.Fusion.Children] = {
				BackpackFrame({
					ScreenGui = screen_gui_ref,
					DragAction = "DragAction",
					SortState = sort_status,
					Visible = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = animated,
				}),

				EquippedFrame({
					ScreenGui = screen_gui_ref,
					DragAction = "DragAction",
					SortState = sort_status,
					Visible = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = animated2,
				}),

				self.Fusion.Hydrate(self.Core.UI.Inventory.InformationFrame:Clone())({
					Visible = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = animated3,
				}),

				self.Fusion.New("TextButton")({
					Visible = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.75, 0, 0.35, 0),
					BackgroundTransparency = 0,
					Size = UDim2.new(0.1, 0, 0.15, 0),
					Text = self.Fusion.Computed(function()
						return sort_status:get() and "Default" or "Sort"
					end),

					[self.Fusion.OnEvent("Activated")] = function()
						local current_status = sort_status:get()
						sort_status:set(not current_status)
					end,
				}),
			},
		}),
	})
	goalPosition:set(UDim2.new(0.5, 0, 0.5, 0))
	goalPosition2:set(UDim2.new(0.3, 0, 0.5, 0))
	goalPosition3:set(UDim2.new(0.69, 0, 0.5, 0))

	print("Created Inventory")
end

function Inventory.new()
	local self = setmetatable({}, Inventory)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	return self
end

function Inventory:Destroy()
	self._core_maid:DoCleaning()
	print("Cleanup")
end

return Inventory
