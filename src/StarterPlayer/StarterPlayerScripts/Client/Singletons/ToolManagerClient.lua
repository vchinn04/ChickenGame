local ToolManager = {
	Name = "ToolManager",
}
--[[
	<description>
		This manager is responsible for managing the tool objects.
	</description> 
	
	<API>
		ToolManager.EquipTool(tool_name: string) ---> boolean
			-- Equip specified tool
			tool_name : string -- Name of the tool being equiped
			
		ToolManager.UnequipTool(tool_name: string) ---> boolean
			-- Unequip specified tool if equipped
			tool_name : string -- Name of the tool being unequiped
			
		ToolManager.AddTool(tool_id: string) ---> boolean
			-- Fire the tool addtion remote (Add tool and its objects).
			tool_id : string -- The ID of the tool being added.
			
		ToolManager.RemoveTool(tool_name: string) ---> boolean
			-- Fire the tool removal remote (Destroy tool and its objects).
			tool_name : string -- Name of the tool being removed
			
		ToolManager.UnequipAll() ---> nil
			-- Unequip any equipped tools
			
		ToolManager.EventHandler() ---> nil
			-- Handle incoming events such as melee, movement, etc
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local Core
local Maid
local CurrentTools = {}
local EquippedItem = nil

-- local EQUIPABLE_CATEGORIES = {
-- 	["Accessory"] = true,
-- 	["Tool"] = true,
-- 	["Melee"] = true,
-- 	["Primary"] = true,
-- 	["Secondary"] = true,
-- }

-- local USABLE_CATEGORIES = {
-- 	["Consumable"] = true,
-- }

local ToolClasses = setmetatable({}, {
	__index = function(self, key)
		local class = Core.Utils.UtilityFunctions.FindObjectWithPath(Core.Classes, `Tools/{key}`)
		if class then
			self[key] = require(class)
			return self[key]
		end
		return nil
	end,
})

--*************************************************************************************************--

-----------------Custom Equip/Unequip to be used if not using default toolbar-----------------
function ToolManager.EquipTool(tool_name: string): boolean
	ToolManager.UnequipAll()
	Core.Utils.Net:RemoteEvent("EquipItem"):FireServer(tool_name)
	return true
end

function ToolManager.UnequipTool(tool_name: string): boolean
	-- ToolManager.UnequipAll()
	Core.Utils.Net:RemoteEvent("UnequipItem"):FireServer(tool_name)
	return true
end
---------------------------------------------------------------------------------------

-- Add a tool to the player's backpack
--tool_name ---> Name of the tool to add to backpack
function ToolManager.AddTool(tool_id: string): boolean
	Core.Utils.Net:RemoteEvent("AddItem"):FireServer(tool_id)
	return true
end

-- Remove a tool from the player's backpack
--tool_name ---> Name of the tool to remove from backpack
function ToolManager.RemoveTool(tool_name: string): boolean
	Core.Utils.Net:RemoteEvent("RemoveItem"):FireServer(tool_name)
	return true
end

function ToolManager.UnequipAll(): nil
	if EquippedItem then
		EquippedItem:Unequip()
	end

	EquippedItem = nil
	return
end

function AddItemHandler(tool_id: string, tool_obj)
	local tool_data = Core.ItemDataManager.GetItem(tool_id)
	local tool_class = tool_data.Class
	local tool_name: string = tool_data.Name
	local tool_module_class = ToolClasses[tool_class]
	local tool_class_obj = nil
	if tool_module_class then
		tool_class_obj = tool_module_class.new(tool_obj, tool_data)
	end
	Maid[tool_name] = tool_class_obj
	if tool_class_obj then
		Core.Fire("ItemEquip", true, tool_id)
	end
end

function ToolManager.EventHandler(): nil
	Maid:GiveTask(
		Core.Subscribe("InventoryAction", function(action: string, item_data: { [string]: any }, item_state: string)
			if action == "EQUIP" then
				if not Core.ItemDataManager.IsEquippable(item_data.Category) then
					return
				end
				ToolManager.AddTool(item_data.Id)
			elseif action == "STORE" then
				if not Core.ItemDataManager.IsEquippable(item_data.Category) then
					return
				end
				ToolManager.RemoveTool(item_data.Name)
			elseif action == "USE" then
				if not Core.ItemDataManager.IsUsable(item_data.Category) then
					return
				end
				Core.Utils.Net:RemoteEvent("UseItem"):FireServer(item_data.Id)
			else
				Core.Utils.Net
					:RemoteEvent("DropItem")
					:FireServer(item_data.Id, item_state, (Core.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0)).Position)
			end
		end)
	)

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("AddItem").OnClientEvent:Connect(function(tool_id: string, tool_obj)
		AddItemHandler(tool_id, tool_obj)
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("BulkAddition").OnClientEvent:Connect(function(tool_table: {})
		for tool_id, tool_obj in tool_table do
			AddItemHandler(tool_id, tool_obj)
		end
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("RemoveItem").OnClientEvent:Connect(function(tool_name: string, tool_obj)
		if Maid[tool_name] == EquippedItem then
			EquippedItem = nil
		end
		if Maid[tool_name] then
			Core.Fire("ItemEquip", false, Core.ItemDataManager.NameToId(tool_name))
		end
		Maid[tool_name] = nil
	end))

	-- Equip a tool in player's backpack. Done after server fires event after setting it up on server.
	--tool_name ---> Name of the tool to equip
	--tool_obj ---> The tool object that is used
	Maid:GiveTask(Core.Utils.Net:RemoteEvent("EquipItem").OnClientEvent:Connect(function(tool_name: string, tool_obj)
		ToolManager.UnequipAll()

		EquippedItem = Maid[tool_name]
		if EquippedItem then
			EquippedItem:Equip()
		end
	end))

	-- Unequip a tool in player's backpack. Done after server fires event after cleaning up on server.
	--tool_name ---> Name of the tool to unequip
	Maid:GiveTask(Core.Utils.Net:RemoteEvent("UnequipItem").OnClientEvent:Connect(function(tool_name: string)
		ToolManager.UnequipAll()
		EquippedItem = nil
	end))

	Maid:GiveTask(Core.ToolsStateManager.changed:connect(function(newState, oldState)
		if newState.EquippedItem then
			ToolManager.EquipTool(newState.EquippedItem)
		elseif oldState.EquippedItem then
			ToolManager.UnequipTool(oldState.EquippedItem)
		end
	end))

	return
end

function ToolManager.Start(): nil
	ToolManager.EventHandler()
	Core.Utils.Net:RemoteEvent("AddItem"):FireServer("Basket")
	return
end

function ToolManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	return
end

function ToolManager.Reset(): nil
	EquippedItem = nil
	Maid:DoCleaning()
	return
end

return ToolManager
