local ItemButton = require(script.Parent:WaitForChild("ItemButton"))
local BUFFER = 15
local UserInputService = game:GetService("UserInputService")

local function SortedFrame(props)
	local Core = _G.Core
	local Fusion = Core.Fusion
	local Maid = Core.Utils.Maid.new()
	local dragged_button = Fusion.Value(nil)
	local drag_observer = Fusion.Observer(dragged_button)
	local frame_absolute_position = Fusion.Value()
	local frame_absolute_size = Fusion.Value()

	local last_item = {}
	local button_data = {}

	local binary_insert = function(array, item, priority)
		for button_index, entry in button_data do
			if entry.Priority >= priority then
				table.insert(array, button_index, item)
				return
			end
		end
		table.insert(array, item)
	end

	local drag_observer_cleanup = drag_observer:onChange(function()
		local button_index = dragged_button:get()
		if button_index then
			local mouse_pos = UserInputService:GetMouseLocation()
			local item_data = button_data[button_index].Data
			local button_absolute_position = button_data[button_index].AbsolutePosition
			local button_absolute_size = Fusion.Value()
			local clone_amount = 1
			local prev_button_index = button_index - 1
			local next_button_index = button_index + 1

			local prev_button = nil
			if prev_button_index > 0 then
				prev_button = button_data[prev_button_index]
			end

			local next_button = nil
			if next_button_index <= #button_data then
				next_button = button_data[next_button_index]
			end

			last_item = {
				Data = item_data,
				Visible = button_data[button_index].Visible,
			}

			local button_size = UDim2.new(0.1, 0, 0, 45)
			if props.SortState:get() then
				local abs_size = button_data[button_index].AbsoluteSize:get()
				button_size = UDim2.new(0, abs_size.X, 0, abs_size.Y)
				button_data[button_index].Visible:set(false)
				clone_amount = button_data[button_index].Amount:get()
			end
			local button_pos = Fusion.Value(
				UDim2.new(
					0,
					button_absolute_position:get().X + button_data[button_index].AbsoluteSize:get().X / 2,
					0,
					mouse_pos.Y
				)
			)

			Maid.DragButton = ItemButton({
				Name = item_data.Name,
				Index = 0,
				Dummy = true,
				Parent = props.ScreenGui:get(),
				Amount = clone_amount,
				AbsoluteSizeOut = button_absolute_size,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = button_size,
				Position = button_pos,
				DragEvent = dragged_button,
				[Fusion.Cleanup] = function() end,
			})

			local low_limit = frame_absolute_position:get().Y + (45 / 2) + BUFFER
			local up_limit = frame_absolute_position:get().Y + frame_absolute_size:get().Y

			Maid.DragConnection = UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					local x_new = button_absolute_position:get().X + button_absolute_size:get().X / 2
					if not props.SortState:get() then
						x_new = input.Position.X + (button_absolute_size:get().X / 2)
					end
					local y_pos = input.Position.Y + 45 + (button_absolute_size:get().Y / 2)

					if props.SortState:get() then
						y_pos = math.clamp((y_pos - (button_absolute_size:get().Y / 2)), low_limit, up_limit)
					end

					local new_pos = UDim2.new(0, x_new, 0, y_pos)

					button_pos:set(new_pos)

					if props.SortState:get() and prev_button then
						if
							(prev_button.AbsolutePosition:get().Y + prev_button.AbsoluteSize:get().Y / 2)
							> input.Position.Y
						then
							local temp = button_data[button_index].Priority
							button_data[button_index].Priority = prev_button.Priority
							prev_button.Priority = temp
							button_data[prev_button_index] = button_data[button_index]
							button_data[button_index] = prev_button

							-- button_data[button_index].IndexValue:set(prev_button_index)
							-- prev_button.IndexValue:set(button_index)
							for b_index, entry in button_data do
								entry.IndexValue:set(b_index)
							end

							button_index = prev_button_index

							prev_button_index -= 1
							next_button_index -= 1

							prev_button = nil
							if prev_button_index > 0 then
								prev_button = button_data[prev_button_index]
							end

							next_button = nil
							if next_button_index <= #button_data then
								next_button = button_data[next_button_index]
							end
							return
						end
					end
					if props.SortState:get() and next_button then
						if
							(next_button.AbsolutePosition:get().Y + next_button.AbsoluteSize:get().Y / 2)
							< input.Position.Y
						then
							local temp = button_data[button_index].Priority
							button_data[button_index].Priority = next_button.Priority
							next_button.Priority = temp

							button_data[next_button_index] = button_data[button_index]
							button_data[button_index] = next_button

							-- next_button.IndexValue:set(button_index)
							-- button_data[button_index].IndexValue:set(next_button_index)
							for b_index, entry in button_data do
								entry.IndexValue:set(b_index)
							end
							button_index = next_button_index

							prev_button_index += 1
							next_button_index += 1

							prev_button = nil
							if prev_button_index > 0 then
								prev_button = button_data[prev_button_index]
							end

							next_button = nil
							if next_button_index <= #button_data then
								next_button = button_data[next_button_index]
							end
							return
						end
					end
				end
			end)
		else
			Maid.DragConnection = nil
			Maid.DragButton = nil

			if not props.SortState:get() then
				Core.Fire(props.DragAction, last_item.Data, props.SourceState)
			else
				Core.Utils.Net:RemoteEvent("InventorySort"):FireServer(button_data, props.SourceState)
			end

			last_item.Visible:set(true)
			last_item.Visible = nil
			last_item.Data = nil
			last_item = {}

			for b_index, entry in button_data do
				entry.IndexValue:set(b_index)
			end
		end
	end)

	local mouse_up_event = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragged_button:set(nil)
		end
	end)

	local item_remove_function = function(index, button)
		table.remove(button_data, index)
		for button_index, entry in button_data do
			entry.IndexValue:set(button_index)
		end
		button:Destroy()
	end

	local item_arr = Fusion.ForPairs(props.Items, function(index, entry)
		local item_data = Core.ItemDataManager.GetItem(entry.Id)

		if props.ItemFilter then
			if not props.ItemFilter(item_data) then
				return index, nil
			end
		end

		local button_index = Fusion.Value(#button_data + 1)
		local button_amount = Fusion.Value(entry.Amount)
		local button_absolute_position = Fusion.Value()
		local button_absolute_size = Fusion.Value()

		local visble_state = Fusion.Value(true)
		local item_backpack_priority = entry.BackpackListPriority
		local item_equipped_priority = entry.EquippedListPriority
		local item_priority = if item_backpack_priority then item_backpack_priority else Core.Length(props.Items)

		if props.SourceState == "EQUIP" then
			item_priority = if item_equipped_priority then item_equipped_priority else Core.Length(props.Items)
			button_amount:set(1)
		elseif props.SourceState == "STORE" and entry.Equipped then
			item_priority = if item_backpack_priority then item_backpack_priority else Core.Length(props.Items)
			button_amount:set(entry.Amount - 1)
		end

		local button_pos = Fusion.Computed(function()
			local current_index = (button_index:get() - 1)
			return UDim2.new(0.5, 0, 0, current_index * 45 + (45 / 2) + BUFFER) -- math.clamp(current_index, 0, 1) *
		end)
		local button_tween =
			Fusion.Tween(button_pos, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

		binary_insert(button_data, {
			Data = item_data,
			IndexValue = button_index,
			Visible = visble_state,
			Amount = button_amount,
			Priority = item_priority,
			AbsolutePosition = button_absolute_position,
			AbsoluteSize = button_absolute_size,
		}, item_priority)

		for b_index, ie in button_data do
			ie.IndexValue:set(b_index)
		end

		return button_index,
			ItemButton({
				Name = item_data.Name,
				ItemData = item_data,
				Index = button_index,
				Visible = visble_state,
				Amount = button_amount,
				AnchorPoint = Vector2.new(0.5, 0.5),
				AbsoluteSizeOut = button_absolute_size,
				AbsolutePositionOut = button_absolute_position,
				Size = UDim2.new(0.95, 0, 0, 45),
				Position = button_tween,
				DragEvent = dragged_button,
			})
	end, function(index, button)
		item_remove_function(index:get(), button)
	end)

	Maid:GiveTask(Core.Subscribe("ReplicaUpdate", function(item_path, action)
		local path_list = string.split(item_path, "/")
		local item_key = path_list[#path_list]

		for index, key in path_list do
			if key == "Items" then
				item_key = path_list[(index + 1)]
				break
			end
		end
		props.Items:set(Core.ReplicaServiceManager.GetData().Items, true, { [item_key] = true })
	end))

	return Fusion.New("ScrollingFrame")({
		Size = UDim2.fromScale(0.9, 0.7),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.61),
		[Fusion.Out("AbsoluteSize")] = frame_absolute_size,
		[Fusion.Out("AbsolutePosition")] = frame_absolute_position,
		BackgroundTransparency = 1,
		ScrollBarImageColor3 = Color3.fromRGB(91, 84, 64),
		CanvasSize = UDim2.new(0, 0, 2, 0),
		ScrollBarThickness = 5,
		Visible = true,
		[Fusion.Children] = item_arr,

		[Fusion.Cleanup] = function()
			Maid:DoCleaning()
			mouse_up_event:Disconnect()
			drag_observer_cleanup()
		end,
	})
end

return SortedFrame
