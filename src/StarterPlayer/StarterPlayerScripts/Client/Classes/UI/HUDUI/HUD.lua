local HUD = {
	UIType = "Core",
}
HUD.__index = HUD
local HUD_ENTRIES = { "InventoryUI/Inventory", "CraftingUI/Crafting", "Store" }
local HUD_BUTTON_PATH = "UI/HUD/HUDButton"

function HUD:mount()
	local hud_button = self.Core.Components[HUD_BUTTON_PATH]

	self._core_maid.hud_button_list = self.Fusion.ForPairs(HUD_ENTRIES, function(index, entry)
		return index, hud_button(self.Core, {
			Name = entry,
			Index = index,
		})
	end, function(button)
		print("Destructor got text label:", button.Name)
		button:Destroy()
	end)

	self._core_maid.HUD_ScreenGui = self.Fusion.New("ScreenGui")({
		Parent = self.Core.PlayerGui,
		[self.Fusion.Children] = {
			self.Fusion.New("UIListLayout")({
				SortOrder = "LayoutOrder",
			}),
			self._core_maid.hud_button_list,
		},
	})

	self._toolbar:mount()
	self._stat_bars:mount()
	print("Created HUD")
end

function HUD.new()
	local self = setmetatable({}, HUD)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	self._toolbar = require(script.Parent.Toolbar).new()
	self._stat_bars = require(script.Parent.StatBars).new()

	return self
end

function HUD:Destroy()
	self._core_maid:DoCleaning()
	self._toolbar:Destroy()
	self._stat_bars:Destroy()
	self._stat_bars = nil
	self._toolbar = nil
end

return HUD
