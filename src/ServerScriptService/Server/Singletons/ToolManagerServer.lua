local ToolManager = {
	Name = "ToolManager",
}
--[[
	<description>
		This manager is responsible for handling tools on the server.
	</description> 
	
	<API>
		ToolManager.AddTool(player: Player, tool_id: string) ---> Tool?
			-- Create an instance of the class needed for tool and 
			-- add it to player. Return the Tool or nil if failed
			tool_name : string -- The ID of the tool being added.
			
		ToolManager.RemoveTool(player: Player, tool_name: string) ---> boolean
			-- Remove a tool from player, destroy its resources.
			tool_name : string -- Name of the tool being removed
			
		ToolManager.EquipItem(player: Player, tool_name: string) ---> boolean
			-- Equip specified tool
			tool_name : string -- Name of the tool being equipped
			
		ToolManager.UnequipItem(player: Player, tool_name: string) ---> boolean
			-- Unequip specified tool
			tool_name : string -- Name of the tool being unequipped
			
		ToolManager.EventHandler()
			-- Handle incoming events from players
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local Types = require(game.ReplicatedStorage:WaitForChild("Utils"):WaitForChild("ServerTypes"))

local Core
local Maid

-- In charge of lazily loading in the Tool classes when requested and throwing a warning if not class found

local ToolClasses = setmetatable({}, {
	__index = function(self, obj_index)
		local succ, res = pcall(function()
			local class_object: Instance =
				Core.Utils.UtilityFunctions.FindObjectWithPath(Core.Classes, `Tools/{obj_index}`)
			if class_object then
				local Obj = require(class_object)
				self[obj_index] = Obj
				return Obj
			end
		end)

		if succ then
			return res
		else
			warn("TOOL OBJ: ", obj_index, " ERROR! ERROR: ", res)
			return nil
		end
	end,
})

local USE_FUNCTIONS = {
	Consumable = function(player: Player, item_data: string)
		local player_object: {} = Core.DataManager.GetPlayerObject(player)
		if not player_object then
			return false
		end

		-- player_object:AddHunger(item_data.HungerAmount)

		return true
	end,
}
--*************************************************************************************************--

-- Add a tool to the player's backpack
--tool_id ---> Id of the tool to add to backpack
function ToolManager.AddTool(player: Player, tool_id: string): Tool?
	local player_object: Types.IPlayer = Core.DataManager.GetPlayerObject(player) -- Get the player's PlayerClass instance
	local tool_data: {} = Core.ItemDataManager.GetItem(tool_id)
	local tool_name: string = tool_data.Name
	local tool_class_name: string = tool_data.Class

	if not player_object then
		return nil
	end

	if not Core.ItemDataManager.IsEquippable(tool_data.Category) then
		return
	end

	local tool_class: {}? = ToolClasses[tool_class_name]

	local player_data: {}? = Core.DataManager.GetPlayerData(player)
	local item_player_entry: {} = player_data.Items[tool_id]
	if item_player_entry and not item_player_entry.Equipped then
		Core.DataManager.RemoveSpace(player, tool_data.Weight)
	end

	local tool_object: {} = player_object:AddTool(tool_name, tool_class, tool_data)

	return tool_object:GetToolObject()
end

-- Remove a tool from the player's backpack
--tool_id ---> Id of the tool to remove from backpack
function ToolManager.RemoveTool(player: Player, tool_name: string): boolean
	local player_object: Types.IPlayer = Core.DataManager.GetPlayerObject(player) -- Get the player's PlayerClass instance

	if not player_object then
		return false
	end

	local player_data: {}? = Core.DataManager.GetPlayerData(player)
	local item_id: string = Core.ItemDataManager.NameToId(tool_name)
	local item_player_entry: {} = player_data.Items[item_id]
	if item_player_entry and item_player_entry.Equipped then
		local tool_data: {} = Core.ItemDataManager.GetItem(item_id)
		Core.DataManager.AddSpace(player, tool_data.Weight)
	end
	player_object:RemoveTool(tool_name) -- remove it from player

	return true
end

-- Equip a tool in player's backpack.
--tool_name ---> Name of the tool to equip
function ToolManager.EquipItem(player: Player, tool_name: string): boolean
	print("Handle Tool Equipal!")
	local player_object: Types.IPlayer = Core.DataManager.GetPlayerObject(player)

	if not player_object then
		print("No player object found!")
		return false
	end

	player_object:EquipTool(tool_name)
	return true
end

-- Unequip a tool in player's backpack.
--tool_name ---> Name of the tool to unequip
function ToolManager.UnequipItem(player: Player, tool_name: string): boolean
	--print("Handle Tool Removal!")
	local player_object: Types.IPlayer = Core.DataManager.GetPlayerObject(player)

	if not player_object then
		return false
	end

	local status: boolean? = player_object:UnequipTool(tool_name)
	return status
end

function ToolManager.EventHandler(): nil
	Core.Utils.Net:RemoteEvent("EquipItem").OnServerEvent:Connect(function(player: Player, tool_name: string)
		local tool_add_status: boolean = ToolManager.EquipItem(player, tool_name)

		if tool_add_status then
			Core.Utils.Net:RemoteEvent("EquipItem"):FireClient(player, tool_name, tool_add_status)
		end
	end)

	Core.Utils.Net:RemoteEvent("UnequipItem").OnServerEvent:Connect(function(player: Player, tool_name: string)
		local unequip_status: boolean = ToolManager.UnequipItem(player, tool_name)

		if unequip_status then
			Core.Utils.Net:RemoteEvent("UnequipItem"):FireClient(player, tool_name)
		end
	end)

	Core.Utils.Net:RemoteEvent("AddItem").OnServerEvent:Connect(function(player: Player, tool_id: string)
		local tool_add_status: Tool? = ToolManager.AddTool(player, tool_id)

		if tool_add_status then
			Core.Utils.Net:RemoteEvent("AddItem"):FireClient(player, tool_id, tool_add_status)
		end
	end)

	Core.Subscribe("AddItem", function(player: Player, tool_id: string)
		local tool_add_status: Tool? = ToolManager.AddTool(player, tool_id)

		if tool_add_status then
			Core.Utils.Net:RemoteEvent("AddItem"):FireClient(player, tool_id, tool_add_status)
		end
	end)

	Core.Utils.Net:RemoteEvent("RemoveItem").OnServerEvent:Connect(function(player: Player, tool_name: string)
		local tool_remove_status: boolean = ToolManager.RemoveTool(player, tool_name)
		if tool_remove_status then
			Core.Utils.Net:RemoteEvent("RemoveItem"):FireClient(player, tool_name, tool_remove_status)
		end
	end)

	Core.Utils.Net:RemoteEvent("UseItem").OnServerEvent:Connect(function(player: Player, item_id: string)
		local player_data = Core.DataManager.GetPlayerData(player)
		if not player_data then
			return
		end

		local item_entry: {} = player_data.Items[item_id]
		if not item_entry or item_entry.Amount < 1 then
			print("Player: ", player.Name, " Doesnt have usable item with id: ", item_id)
			return
		end

		local item_data: {} = Core.ItemDataManager.GetItem(item_id)
		if not item_data then
			return false
		end

		local use_item_res: boolean? = false
		if USE_FUNCTIONS[item_data.Category] then
			use_item_res = USE_FUNCTIONS[item_data.Category](player, item_data)
		end

		if not use_item_res then
			return
		end

		Core.DataManager.RemoveItem(player, "Items/" .. item_id, 1)
		Core.DataManager.RemoveSpace(player, item_entry.Weight)

		print("Player: ", player.Name, " used: ", item_id)
	end)

	Core.Subscribe("RemoveItem", function(player: Player, tool_name: string)
		local tool_remove_status: boolean = ToolManager.RemoveTool(player, tool_name)
		if tool_remove_status then
			Core.Utils.Net:RemoteEvent("RemoveItem"):FireClient(player, tool_name, tool_remove_status)
		end
	end)

	Core.Utils.Net
		:RemoteEvent("DropItem").OnServerEvent
		:Connect(function(player: Player, tool_id: string, tool_state: string, loc)
			local tool_data: {} = Core.ItemDataManager.GetItem(tool_id)

			if tool_data then
				Core.Utils.Net:RemoteEvent("UnequipItem"):FireClient(player, tool_data.Name)

				if tool_state == "EQUIP" then
					local tool_remove_status: boolean = ToolManager.RemoveTool(player, tool_data.Name)
					if tool_remove_status then
						Core.Utils.Net:RemoteEvent("RemoveItem"):FireClient(player, tool_data.Name, tool_remove_status)
					end
				end

				local item_path: string = "Items/" .. tool_id

				Core.DataManager.RemoveItem(player, item_path)
				Core.DataManager.RemoveSpace(player, tool_data.Weight)
				Core.InteractionManager.CreateDrop(tool_data.Name, loc)
			end
		end)

	return
end

function ToolManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()

	Core.Utils.Net:RemoteEvent("Parry")
	Core.Utils.Net:RemoteEvent("Block")
	Core.Utils.Net:RemoteEvent("ProjectileVisualize")
	Core.Utils.Net:RemoteEvent("ObstacleHit")
	Core.Utils.Net:RemoteEvent("AttackSuccess")
	Core.Utils.Net:RemoteEvent("BulkAddition")
	Core.Utils.Net:RemoteEvent("HidePlayer")
	return
end

function ToolManager.Start(): nil
	ToolManager.EventHandler()
	return
end

function ToolManager.Reset(): nil
	return
end

return ToolManager
