local Store = {}
Store.__index = Store

function Store:mount()
	self._core_maid.InventoryScreenGui = self.Fusion.New("ScreenGui")({
		Name = "Store",
		Parent = self.Core.PlayerGui,
	})
	print("Created Store")
end

function Store.new()
	local self = setmetatable({}, Store)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	return self
end

function Store:Destroy()
	self._core_maid:DoCleaning()
end

return Store
