local StoreButton = require(script.Parent:WaitForChild("StoreButton"))
local SectionButton = require(script.Parent:WaitForChild("SectionButton"))

local function StoreFrame(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()
	local store_data = Core.Utils.ItemDataManager.GetStoreEntry(props.StoreId)
	local store_section = Fusion.Value("Sell")
	local section_data = Fusion.Value(Core.ReplicaServiceManager.GetData().Items)

	local section_observer = Fusion.Observer(store_section)

	local section_buttons = Fusion.ForPairs(store_data, function(index, entry)
		return index,
			SectionButton({
				Name = index,
				SectionName = index,
				SectionIcon = entry.Icon,
				SectionValue = store_section,
				Visible = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0.95, 0, 0, 45),
			})
	end, function(index, button)
		button:Destroy()
	end)

	local item_buttons = Fusion.ForPairs(section_data, function(index, entry)
		local current_section = store_section:get()

		if current_section == "Sell" then
			entry = Core.ItemDataManager.GetItem(index)

			if not entry then
				return index, nil
			end
		end

		return index,
			StoreButton({
				Name = entry.Name,
				Id = entry.Id,
				ItemIndex = index,
				StoreId = props.StoreId,
				Price = entry.Price,
				Section = current_section,
				Visible = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0.95, 0, 0, 45),
			})
	end, function(index, button)
		button:Destroy()
	end)

	Maid:GiveTask(section_observer:onChange(function()
		print("The new section is: ", store_section:get())
		local current_section = store_section:get()

		if current_section == "Sell" then
			section_data:set(Core.ReplicaServiceManager.GetData().Items)
		else
			section_data:set(store_data[current_section].Items)
		end
	end))

	return Fusion.Hydrate(Core.UI.GeneralStore:WaitForChild("StoreFrame"):Clone())({
		Visible = true,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = UDim2.fromScale(0.258, 0.653),
		[Fusion.Children] = {
			Fusion.New("Frame")({
				Size = UDim2.fromScale(0.312, 0.711),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.189, 0.617),
				BackgroundTransparency = 1,
				Visible = true,
				Name = "SectionButtons",

				[Fusion.Children] = {
					Fusion.New("UIListLayout")({
						Padding = UDim.new(0, 4),
					}),
					section_buttons,
					SectionButton({
						Name = "zSell",
						SectionName = "Sell",
						SectionIcon = "http://www.roblox.com/asset/?id=5460555206",
						SectionValue = store_section,
						Visible = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0.95, 0, 0, 45),
					}),
				},
			}),

			Fusion.New("ScrollingFrame")({
				Size = UDim2.fromScale(0.601, 0.702),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.671, 0.617),

				BackgroundTransparency = 1,
				ScrollBarImageColor3 = Color3.fromRGB(91, 84, 64),
				CanvasSize = UDim2.new(0, 0, 2, 0),
				ScrollBarThickness = 5,
				Visible = true,
				Name = "ScrollingFrame",
				[Fusion.Children] = {
					Fusion.New("UIListLayout")({
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

return StoreFrame
