local GeneralStore = {}
GeneralStore.__index = GeneralStore

local StoreFrame = require(script.Parent:WaitForChild("StoreFrame"))

local UserInputService = game:GetService("UserInputService")

function GeneralStore:mount()
	local goalPosition = self.Core.Fusion.Value(UDim2.new(0.5, 0, 1.2, 0))
	local animated = self.Core.Fusion.Spring(goalPosition, 10, 0.65)

	local goalPosition2 = self.Core.Fusion.Value(UDim2.new(0.5, 0, 1.2, 0))
	local animated2 = self.Core.Fusion.Spring(goalPosition2, 10, 0.65)

	local screen_gui_ref = self.Fusion.Value()

	self._core_maid.InventoryScreenGui = self.Fusion.New("ScreenGui")({
		Name = "GeneralStore",
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
				StoreFrame({

					Visible = true,
					StoreId = self._store_id,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = animated,
				}),

				self.Fusion.Hydrate(self.Core.UI.GeneralStore.InformationFrame:Clone())({
					Visible = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0.132, 0, 0.654, 0),
					Position = animated2,
				}),
			},
		}),
	})
	goalPosition:set(UDim2.new(0.427, 0, 0.5, 0))
	goalPosition2:set(UDim2.new(0.635, 0, 0.5, 0))

	print("Created Crafting")
end

function GeneralStore.new(store_id)
	local self = setmetatable({}, GeneralStore)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	self._store_id = store_id
	return self
end

function GeneralStore:Destroy()
	self._core_maid:DoCleaning()
	print("Cleanup")
end

return GeneralStore
