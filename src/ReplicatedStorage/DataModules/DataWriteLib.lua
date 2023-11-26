local DataWriteLib = {}

local Length = function(Table) -- Get the length of a dictionary
	local counter = 0
	for _, v in Table do
		counter = counter + 1
	end
	return counter
end

--[[
	<description>
		Add item to the player's inventory.
	</description> 
	
	<parameter name="player">
		Type: Player
		Description: player
	</parameter 
	
	<parameter name="path_to_item">
		Type: string
		Description:  Path to item to add. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"
	</parameter 
--]]
function DataWriteLib.AddItem(replica, path_to_item: string, add_amount: number?, amount_index: string?)
	local cur_table = replica.Data
	local path_list = string.split(path_to_item, "/")
	local item_key = path_list[#path_list]

	if not add_amount then
		add_amount = 1
	end

	if not amount_index then
		amount_index = "Amount"
	end

	for ind, cur_index in path_list do
		if cur_index == "." or ind == #path_list then
			break
		end
		cur_table = cur_table[cur_index]
	end

	if not cur_table[item_key] then
		local item_entry = {
			Id = item_key,
			Amount = 0,
			BankAmount = 0,
			Equipped = false,
			Data = {},
			EquippedListPriority = Length(replica.Data.Items),
			BackpackListPriority = Length(replica.Data.Items),
		}

		item_entry[amount_index] = add_amount
		replica:SetValue(path_list, item_entry)

		return add_amount
	end

	local old_amount = cur_table[item_key][amount_index]
	if not old_amount then
		old_amount = 0
	end
	local new_val = old_amount + add_amount
	table.insert(path_list, amount_index)
	replica:SetValue(path_list, new_val)

	return new_val
end

--[[
	<description>
		Remove and item from the player's inventory. If Amount = 0 then delete the entry from user's data.
	</description> 
	
	<parameter name="player">
		Type: Player
		Description: player 
	</parameter 
	
	<parameter name="path_to_item">
		Type: string
		Description:  Path to item to remove. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"
	</parameter 
--]]
function DataWriteLib.RemoveItem(replica, path_to_item: string, remove_amount: number?, amount_index: string?)
	local cur_table = replica.Data
	local path_list = string.split(path_to_item, "/")
	local item_key = path_list[#path_list]

	if not remove_amount then
		remove_amount = 1
	end

	if not amount_index then
		amount_index = "Amount"
	end

	for ind, cur_index in path_list do
		if cur_index == "." or ind == #path_list then
			break
		end

		cur_table = cur_table[cur_index]
	end

	if not cur_table[item_key] then
		return
	end

	local old_amount = cur_table[item_key][amount_index]
	if not old_amount then
		old_amount = 0
	end
	local new_val = old_amount - remove_amount

	if new_val <= 0 then
		new_val = 0
	end

	table.insert(path_list, amount_index)
	replica:SetValue(path_list, new_val)

	return true
end

--[[
	<description>
		Delete the entry from user's data
	</description> 
	
	<parameter name="player">
		Type: Player
		Description: player 
	</parameter 
	
	<parameter name="path_to_item">
		Type: string
		Description:  Path to item to delete. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"
	</parameter 
--]]
function DataWriteLib.DeleteEntry(replica, path_to_item: string)
	local path_list = string.split(path_to_item, "/")
	replica:SetValue(path_list, nil)
	return true
end

--[[
	<description>
		Update the entry in user's data
	</description> 
	
	<parameter name="player">
		Type: Player
		Description: player 
	</parameter 
	
	<parameter name="path_to_item">
		Type: string
		Description:  Path to item to update. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"
	</parameter>
	
	<parameter name="path_to_value">
		Type: string
		Description:  Path to value in item entry. Examle : "ItemDataDict/ValueKey" If there are NO nested tables: "./ValueKey"
	</parameter>

	<parameter name="value">
		Type: any
		Description: updated value
	</parameter>
--]]
function DataWriteLib.UpdateItem(replica, path_to_value: string, value: any) -- TODO : CONVERT TO REPLICA
	local cur_table = replica.Data
	local path_list = string.split(path_to_value, "/")
	local item_key = path_list[#path_list - 1]

	for ind, cur_index in path_list do
		if cur_index == "." or ind == #path_list then
			break
		end

		cur_table = cur_table[cur_index]

		if cur_index == "Items" then
			item_key = path_list[ind + 1]
			if not cur_table[item_key] then
				replica:SetValue({ "Items", item_key }, {
					Id = item_key,
					Amount = 1,
					BankAmount = 0,
					Equipped = false,
					Data = {},
					EquippedListPriority = Length(replica.Data.Items),
					BackpackListPriority = Length(replica.Data.Items),
				})
			end
		end
	end

	replica:SetValue(path_list, value)
	return true
end

function DataWriteLib.SetGeneralValue(replica, value_index: string, value: any)
	local cur_table = replica.Data
	local general_items = cur_table.General
	if not general_items then
		return
	end

	replica:SetValue({ "General", value_index }, value)

	print("UPDATED GENERAL VALUE : ", value_index, value)
	return value_index
end

function DataWriteLib.AddPounds(replica, amount: number?, amount_index: string?)
	local cur_table = replica.Data
	local general_items = cur_table.General
	if not general_items then
		return
	end
	if not amount_index then
		amount_index = "Pounds"
	end

	local pounds = general_items[amount_index]
	if not pounds then
		pounds = 0
	end

	if not amount then
		amount = 0
	end

	local new_pounds = pounds + amount

	replica:SetValue({ "General", amount_index }, new_pounds)
	return true
end

function DataWriteLib.RemovePounds(replica, amount: number?, amount_index: string?)
	local cur_table = replica.Data
	local general_items = cur_table.General
	if not general_items then
		return
	end
	if not amount_index then
		amount_index = "Pounds"
	end

	local pounds = general_items[amount_index]
	if not pounds then
		pounds = 0
	end

	if not amount then
		amount = 0
	end

	local new_pounds = pounds - amount
	if new_pounds < 0 then
		new_pounds = 0
	end

	replica:SetValue({ "General", amount_index }, new_pounds)
	return true
end

function DataWriteLib.AddHunger(replica, amount: number?, amount_index: string?)
	local cur_table = replica.Data
	local general_items = cur_table.General
	if not general_items then
		return
	end
	if not amount_index then
		amount_index = "Hunger"
	end
	local max_hunger = general_items.MaxHunger
	if not max_hunger then
		max_hunger = 100
	end

	local add_amount = amount
	if not add_amount then
		add_amount = 0
	end

	local current_amount = general_items[amount_index]

	if (current_amount + add_amount) > max_hunger and amount_index ~= "MaxHunger" then
		add_amount = max_hunger - current_amount
	end

	DataWriteLib.AddPounds(replica, add_amount, amount_index)
end

function DataWriteLib.RemoveHunger(replica, amount: number?, amount_index: string?)
	local cur_table = replica.Data
	local general_items = cur_table.General

	if not general_items then
		return
	end

	if not amount_index then
		amount_index = "Hunger"
	end

	DataWriteLib.RemovePounds(replica, amount, amount_index)
end

return DataWriteLib
