local ReplicaServiceManager = {
	Name = "ReplicaServiceManager",
}
local ReplicaController

--[[
	<description>
		This manager is responsible for managing Data replication from server.
	</description> 
	
	<API>
		ReplicaServiceManager.GetData() ---> { [string]: any }?
			-- Returns the entire player data 

		ReplicaServiceManager.GetStrangerData(replica_class: string) ---> { [string]: any }?
			-- Returns the data of another player (excluding LocalPlayer) if it is replicated

		ReplicaServiceManager.GetItem(item_path) ---> { [string]: any }?
			-- Returns a specified entry from player data 
			item_path: string ---> Path to item being fetched
		
		(WIP) ReplicaServiceManager.HandleChanges() ---> { [string]: any }?
			-- Handle changes done to data.
		
		ReplicaServiceManager.CreateReplica() ---> nil 
			-- Create a ReplicaController to listen to server changes.
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local Core
local Maid
local Replica
local REPLICA_KEY = game.Players.LocalPlayer.Name .. "PlayerData"
local StrangerReplicas = {}
--*************************************************************************************************--

function ReplicaServiceManager.GetData(): { [string]: any }?
	if Replica ~= nil then
		return Replica.Data
	end
	return nil
end

function ReplicaServiceManager.GetStrangerData(replica_class: string): { [string]: any }?
	local stranger_replica = StrangerReplicas[replica_class]
	if stranger_replica ~= nil then
		return stranger_replica.Data
	end
	return nil
end

function ReplicaServiceManager.GetItem(item_path: string): { [string]: any }?
	if Replica ~= nil then
		local path_list = string.split(item_path, "/")
		local item_key = path_list[#path_list]
		local cur_table = Replica.Data
		for ind, cur_index in path_list do
			if cur_index == "." or ind == #path_list then
				break
			end
			cur_table = cur_table[cur_index]
		end
		return cur_table[item_key]
	end
	return nil
end

function ReplicaServiceManager.HandleChanges(): { [string]: any }?
	if Replica ~= nil then
		return Replica.Data
	end
	return nil
end

function ReplicaServiceManager.CreateReplica(): nil
	ReplicaController.ReplicaOfClassCreated(REPLICA_KEY, function(replica)
		print("TestReplica received! Value:", replica.Data)
		Replica = replica

		replica:ListenToWrite("AddItem", function(ItemPath)
			print(ItemPath)
			print(ReplicaServiceManager.GetItem(ItemPath))
			Core.Fire("ReplicaUpdate", ItemPath, "AddItem")
		end)

		replica:ListenToWrite("SetGeneralValue", function(item_index)
			if item_index == "Space" or item_index == "SpaceAddition" then
				local general_data: {} = Replica.Data.General
				-- Core.Fire("Space", general_data.Space, general_data.BaseSpace + general_data.SpaceAddition)
			end
		end)

		replica:ListenToWrite("RemoveItem", function(ItemPath)
			print(ItemPath)
			print(ReplicaServiceManager.GetItem(ItemPath))
			Core.Fire("ReplicaUpdate", ItemPath, "RemoveItem")
		end)

		replica:ListenToWrite("UpdateItem", function(ItemPath)
			print(ItemPath)
			print(ReplicaServiceManager.GetData())
			Core.Fire("ReplicaUpdate", ItemPath, "UpdateItem")
		end)

		replica:ListenToWrite("AddPounds", function()
			print("Added Pounds!")
			print("New Amount: ", ReplicaServiceManager.GetData().General.Pounds)
			Core.Fire("PoundsUpdate")
		end)

		replica:ListenToWrite("RemovePounds", function()
			print("Removed Pounds!")
			print("New Amount: ", ReplicaServiceManager.GetData().General.Pounds)
			Core.Fire("PoundsUpdate")
		end)

		-- replica:ListenToWrite("AddHunger", function()
		-- 	print("Added Hunger!")
		-- 	print("New Amount: ", ReplicaServiceManager.GetData().General.Hunger)
		-- 	Core.Fire("HungerUpdate")
		-- end)

		replica:ListenToWrite("RemoveHunger", function()
			print("Removed Hunger!")
			print("New Amount: ", ReplicaServiceManager.GetData().General.Hunger)
			Core.Fire("HungerUpdate")
		end)

		Core.Fire("PlayerDataLoaded")
	end)

	ReplicaController.NewReplicaSignal:Connect(function(replica)
		local replica_class = replica.Class
		if replica_class == REPLICA_KEY then
			return
		end

		print("Stranger Replica created:", replica:Identify())
		print(replica.Data)
		StrangerReplicas[replica_class] = replica

		replica:ListenToWrite("AddItem", function(ItemPath)
			print("Stranger Update!")
			Core.Fire("StrangerReplicaUpdate", ItemPath, replica_class)
		end)

		replica:ListenToWrite("RemoveItem", function(ItemPath)
			print("Stranger Update!")
			Core.Fire("StrangerReplicaUpdate", ItemPath, replica_class)
		end)

		replica:AddCleanupTask(function()
			print("Stranger replica removed!")
			StrangerReplicas[replica_class] = nil
		end)
	end)

	ReplicaController.RequestData()
	return
end

function ReplicaServiceManager.Start(): nil
	return
end

function ReplicaServiceManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	ReplicaController = Core.ClientUtils.ReplicaController
	ReplicaServiceManager.CreateReplica()
	return
end

function ReplicaServiceManager.Reset(): nil
	return
end

return ReplicaServiceManager
