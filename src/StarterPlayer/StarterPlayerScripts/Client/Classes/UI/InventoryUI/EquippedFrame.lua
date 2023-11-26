local SortedFrame = require(script.Parent:WaitForChild("SortedFrame"))

local function EquippedFrame(props)
	local Core = _G.Core
	local Maid = Core.Utils.Maid.new()
	local Fusion = Core.Fusion
	local item_list = Fusion.Value(Core.ReplicaServiceManager.GetData().Items)

	-- Maid:GiveTask(Core.ToolsStateManager.changed:connect(function() -- TODO: REMOVE THIS ToolsStateManager
	-- 	item_list:set(Core.ToolsStateManager:getState().Equipped)
	-- end))
	-- Maid:GiveTask(Core.Subscribe("ReplicaUpdate", function()
	-- 	item_list:set(Core.ReplicaServiceManager.GetData().Items)
	-- end))

	return Fusion.Hydrate(Core.UI.Inventory.Equipped:Clone())({
		Visible = true,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		[Fusion.Children] = {
			SortedFrame({
				Items = item_list,
				ItemFilter = function(item_data)
					if not item_data then
						return false
					end

					local data = Core.ReplicaServiceManager.GetItem(`Items/{item_data.Id}`)

					if not data then
						return false
					end

					return data.Equipped and data.Amount > 0
				end,
				SourceState = "EQUIP",
				DragAction = props.DragAction,
				SortState = props.SortState,
				ScreenGui = props.ScreenGui,
				Name = "CoolFrame",
			}),
		},

		[Fusion.Cleanup] = function()
			print("Cleanup for : ", props.Name, " was called!")
			Maid:DoCleaning()
			Maid = nil
		end,
	})
end

return EquippedFrame
