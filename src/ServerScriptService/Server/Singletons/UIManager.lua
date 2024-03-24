local types = require(script.Parent.Parent.ServerTypes)

local UIManager = {
	Name = "UIManager",
}
--[[
	<description>
		This manager is in charge of creates SoundObjects
	</description> 
	
	<API>
		SoundManager.Create(path)
			-- Create a SoundObject for specified folder
			path : string ---> Path to the sound folder
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local Core
local Maid

--*************************************************************************************************--

function UIManager.EventHandler(): nil
	Core.Utils.Net
		:RemoteEvent("InventorySort").OnServerEvent
		:Connect(function(player: Player, button_data: { [number]: any }, tool_add_status: string)
			for _, entry in button_data do
				if tool_add_status == "EQUIP" then
					Core.DataManager.UpdateItem(
						player,
						"Items/" .. entry.Data.Id .. "/EquippedListPriority",
						entry.Priority
					)
				elseif tool_add_status == "STORE" then
					Core.DataManager.UpdateItem(
						player,
						"Items/" .. entry.Data.Id .. "/BackpackListPriority",
						entry.Priority
					)
				end
			end
		end)

	Core.Utils.Net:RemoteEvent("Crafting").OnServerEvent:Connect(function(player: Player, item_id: string)
		local player_data = Core.DataManager.GetPlayerData(player)
		if not player_data then
			return
		end
		local default_crafting_table = Core.Utils.ItemDataManager.GetCraftingTable("Default")
		local item_crafting_entry = default_crafting_table[item_id]
		local tool_data: types.ToolData = Core.ItemDataManager.GetItem(item_id)

		if not item_crafting_entry then
			return
		end

		for _, mat_entry in item_crafting_entry.Materials do
			if not player_data.Items[mat_entry[1]] or player_data.Items[mat_entry[1]].Amount < mat_entry[2] then
				print("Player: ", player.Name, " Doesnt have enough: ", mat_entry[1], " for: ", item_id)
				return
			end
		end

		for _, mat_entry in item_crafting_entry.Materials do
			Core.DataManager.RemoveItem(player, "Items/" .. mat_entry[1], mat_entry[2])
		end

		Core.DataManager.AddItem(player, "Items/" .. item_id)
		Core.DataManager.AddSpace(player, tool_data.Weight)

		print("Player: ", player.Name, " Crafted : ", item_id)
	end)

	Core.Utils.Net
		:RemoteEvent("Bank").OnServerEvent
		:Connect(function(player: Player, item_id: string, action: string, amount: number?)
			local player_data = Core.DataManager.GetPlayerData(player)
			if not player_data then
				return
			end

			local player_item_entry = nil
			local item_entry = nil

			if item_id ~= "POUNDS" then
				player_item_entry = player_data.Items[item_id]
				if not player_item_entry then
					return
				end

				item_entry = Core.Utils.ItemDataManager.GetItem(item_id)
				if not item_entry then
					return
				end
			end

			if action == "DEPOSIT" then
				if item_id == "POUNDS" then
					local player_pounds = player_data.General.Pounds
					if not player_pounds then
						return
					end
					if not amount then
						return
					end
					if player_pounds < amount then
						amount = player_pounds
					end

					print("Depositing: ", amount, " Pounds")
					Core.DataManager.AddPounds(player, amount, "BankPounds")
					Core.DataManager.RemovePounds(player, amount)
					return
				end

				local tool_data: types.ToolData = Core.ItemDataManager.GetItem(item_id)
				local new_bank_space: number = player_data.General.BankSpace + tool_data.Weight
				if new_bank_space > player_data.General.BankMaxSpace then
					return
				end

				Core.DataManager.RemoveSpace(player, tool_data.Weight)

				if not player_item_entry.Amount or player_item_entry.Amount <= 0 then
					return
				end
				Core.Fire("RemoveItem", player, item_entry.Name)
				Core.DataManager.RemoveItem(player, "Items/" .. item_id, 1)
				Core.DataManager.SetGeneralValue(player, "BankSpace", new_bank_space)

				Core.DataManager.AddItem(player, "Items/" .. item_id, 1, "BankAmount")
				print("Deposit: ", item_id)
			elseif action == "WITHDRAW" then
				if item_id == "POUNDS" then
					local player_pounds = player_data.General.BankPounds
					if not player_pounds then
						return
					end
					if not amount then
						return
					end
					if player_pounds < amount then
						amount = player_pounds
					end

					print("Withdrawing: ", amount, " Pounds")
					Core.DataManager.AddPounds(player, amount)
					Core.DataManager.RemovePounds(player, amount, "BankPounds")
					return
				end
				local tool_data: types.ToolData = Core.ItemDataManager.GetItem(item_id)

				if not player_item_entry.BankAmount or player_item_entry.BankAmount <= 0 then
					return
				end
				Core.DataManager.RemoveItem(player, "Items/" .. item_id, 1, "BankAmount")
				Core.DataManager.SetGeneralValue(player, "BankSpace", player_data.General.BankSpace - tool_data.Weight)
				Core.DataManager.AddSpace(player, tool_data.Weight)
				Core.DataManager.AddItem(player, "Items/" .. item_id, 1)
				print("Withdraw: ", item_id)
			end
		end)

	Core.Utils.Net
		:RemoteEvent("Store").OnServerEvent
		:Connect(function(player: Player, item_id: string, item_amount: number, action: string, store_path: string)
			local player_data = Core.DataManager.GetPlayerData(player)
			if not player_data then
				return
			end

			if action == "SELL" then
				local player_item_entry = player_data.Items[item_id]
				if not player_item_entry then
					return
				end

				local item_entry = Core.Utils.ItemDataManager.GetItem(item_id)
				if not item_entry then
					return
				end

				local player_amount = if player_item_entry.Amount then player_item_entry.Amount else 0
				local item_price = if item_entry.Price then item_entry.Price else 0
				local selling_amount = item_amount

				if player_amount < selling_amount then
					selling_amount = player_amount
				end

				if selling_amount < 1 then
					return
				end

				local total_price = selling_amount * item_price

				Core.Fire("RemoveItem", player, item_entry.Name)
				Core.DataManager.RemoveItem(player, "Items/" .. item_id, selling_amount)
				Core.DataManager.AddPounds(player, total_price)
				Core.DataManager.RemoveSpace(player, item_entry.Weight)

				print("Player: ", player.Name, " Sold ", selling_amount, " : ", item_id, " for: ", total_price)
			elseif action == "PURCHASE" then
				local player_pounds = player_data.General.Pounds
				if not player_pounds then
					player_pounds = 0
				end

				local item_entry = Core.Utils.ItemDataManager.GetStoreItem(store_path)
				local item_data = Core.Utils.ItemDataManager.GetItem(item_id)

				if not item_entry then
					return
				end
				local item_price = if item_entry.Price then item_entry.Price else 0
				local total_price = item_amount * item_price

				if player_pounds < total_price then
					print("Not enough pounds!")
					return
				end

				Core.DataManager.AddItem(player, "Items/" .. item_id, item_amount)
				Core.DataManager.RemovePounds(player, total_price)
				Core.DataManager.AddSpace(player, item_data.Weight)

				print("Player: ", player.Name, " Bought ", item_amount, " : ", item_id)
			end
		end)

	return
end

function UIManager.Start(): nil
	UIManager.EventHandler()
	return
end

function UIManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	return
end

function UIManager.Reset(): nil
	return
end

return UIManager
