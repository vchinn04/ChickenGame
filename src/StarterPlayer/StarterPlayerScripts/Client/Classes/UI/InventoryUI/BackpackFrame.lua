local SortedFrame = require(script.Parent:WaitForChild("SortedFrame"))

local function BackpackFrame(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()

	local item_list = Fusion.Value(Core.ReplicaServiceManager.GetData().Items)

	-- Maid:GiveTask(Core.Subscribe("ReplicaUpdate", function()
	-- 	item_list:set(Core.ReplicaServiceManager.GetData().Items)
	-- end))

	return Fusion.Hydrate(Core.UI.Inventory.Backpack:Clone())({
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

					return (not data.Equipped and data.Amount > 0) or (data.Amount > 1)
				end,
				SourceState = "STORE",
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

return BackpackFrame
