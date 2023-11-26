--[[
	<description>
		This singleton (manager) is responsible for providing endpoints to 
		managing the user data in the database. 
	</description> 
	
	<API>
		DataManager.GetPlayerObject(player: Player) --> PlayerClass or nil
			-- Returns the instance of PlayerClass for specified player or nil if it doesn't exit
			player : player 

		DataManager.GetPlayerData(player: Player)
			-- Returns the player's data if it exists else nil
			player : player 

		DataManager.ShareReplica(player: Player, consumer_player: Player)
			-- Replicate player data to consumer_player
			player: Player -- Player whose data is replicated
			consumer_player: Player -- to whom it is replicated 
		
		DataManager.RemoveReplicaConsumer(player: Player, consumer_player: Player)
			-- Remove player replica from consumer_player
			player: Player -- Player whose data is to be removed
			consumer_player: Player -- which is removed

		DataManager.RemoveReplicaConsumerList(player: Player, player_list: { [Player]: boolean })
			-- Remove list of players replicsa from consumer_player
			player_list:  { [Player]: boolean } -- List of players whose data is to be removed
			consumer_player: Player -- which is removed

		DataManager.AddItem(player, path_to_item: string)
			-- Add item to the player's inventory.
			path_to_item: string -- Path to item to add. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"
			
		DataManager.RemoveItem(player, path_to_item: string) --> true or nil 
			-- Remove and item from the player's inventory. If Amount = 0 then delete the entry from user's data.
			path_to_item: string -- Path to item to remove. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"
			
		DataManager.DeleteEntry(player, path_to_item: string) --> true or nil 
			-- Delete the entry from user's data
			path_to_item: string -- Path to item to remove. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"

		DataManager.UpdateItem(player, path_to_item: string, path_to_value, value: any) --> true or nil 
			-- Update the entry in user's data
			path_to_item: string -- Path to item to remove. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"
			path_to_value: string -- Path to value in item entry. Examle : "ItemDataDict/ValueKey" If there are NO nested tables: "./ValueKey"
			value: any -- The updated value 
			
		DataManager.AddPounds(player, amount: number, amount_index: string?)
			-- Add pounds or other currency to player
			player: Player -- Player to whom to add currency 
			amount: number -- Amount to add
			amount_index: string? -- Custom currency to add. DEFAULT: "Pounds"

		DataManager.RemovePounds(player, amount: number, amount_index: string?)
			-- Remove pounds or other currency to player
			player: Player -- Player from whom to remove currency 
			amount: number -- Amount to remove
			amount_index: string? -- Custom currency to remove. DEFAULT: "Pounds"

		DataManager.AddHunger(player, amount: number, amount_index: string?)
			-- Add hunger or other stat to player
			player: Player -- Player to whom to add hunger 
			amount: number -- Amount to add
			amount_index: string? -- Custom stat to add. DEFAULT: "Hunger"

		DataManager.RemoveHunger(player, amount: number, amount_index: string?)
			-- remove hunger or other stat to player
			player: Player -- Player from whom to remove hunger 
			amount: number -- Amount to remove
			amount_index: string? -- Custom stat to remove. DEFAULT: "Hunger"

		DataManager.SetGeneralValue(player: Player, value_index: string, value: any) ---> boolean?
			-- Update value in general section
			player: Player -- Player getting updated
			value_index: string -- Index of value in General section
			value: any -- new value to set to
			retiurn True if successful

		DataManager.AddSpace(player: Player, amount: number) ---> boolean
			-- Add space taken to player
			player: Player -- Player getting updated
			amount: number -- amount of space to add 
			return True if no issues
		
		DataManager.RemoveSpace(player: Player, amount: number) ---> boolean
			-- Remove space taken to player
			player: Player -- Player getting updated
			amount: number -- amount of space to remove 
			return True if no issues

		DataManager.AddSpaceAddtion(player: Player, amount: number) ---> boolean
			-- Add space addition to player (e.g. backpack space addition to base space)
			player: Player -- Player getting updated
			amount: number -- amount of space addition to add 
			return True if no issues

		DataManager.RemoveSpaceAddtion(player: Player, amount: number) ---> boolean
			-- Remove space addition to player (e.g. backpack space addition to base space)
			player: Player -- Player getting updated
			amount: number -- amount of space addition to remove 
			return True if no issues

		DataManager.RemovePlayerData(player, wiped_player_id) --> true or nil
			-- Remove the player's data from database. Aka Wipe. Used for compliance with Roblox TOS.
			wiped_player_id : string | integer -- User ID of the wiped player 
			
		DataManager.RevertProfile(player, remote_player_id, profile_version_date_latest) --> true or nil  -- ADMIN ONLY
			-- Revert the user's profile to an earlier version if available 
			remote_player_id : string | integer -- User ID of the reverted player 
			profile_version_date_latest : latest date profile should be reverted to
			
		DataManager.RefundUserAll(player, refund_player_id) --> total_currency : integer or nil 
			-- Caluclate the user's total robux currency amount if items where to be removed and return that amount. 
			refund_player_id : string | integer -- User ID of the refunded player 

		DataManager.UpdateVersionOfProfile(profile) --> true or nil 
			-- Compare the profile's version with game version. If they are not the same, reconcile profile (fill in missing entries with updated template) 
			profile : profile -- the profile to be updated 
			
		DataManager.DataWipe(player, wiped_player_id) --> true or nil 
			-- Wipe the specified user's data. Will also refund the player's robux currency.
			wiped_player_id : string | integer -- User ID of the wiped player 
			
		DataManager.GiveItem(player, remote_player_id, path_to_item: string, item, action_type) --> true or nil 
			-- Give/Update/Remove item of other player. For admin use. Player can be in game our offline.
			remote_player_id : string | integer -- User ID of the player who is affected.
			path_to_item : string -- Path to item to remove. Examle : "ItemTableName/ItemKey" If there are NO nested tables: "./ItemKey"
			action_type : string -- The action being performed on player can be: 
				"AddItem" --> Give player item
				"RemoveItem" --> remove 1 amount of item from player
				"UpdateItem" --> Update values of player item
				"DeleteEntry" --> totally remove item from player's inventory no matter the amount 
				
		DataManager.ProcessProfileGlobalUpdates(player, profile) --> true or nil 
			-- Process all active and locked global updates for user and listen for new incoming updates. 
			profile : profile -- the profile to be updated 
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local DataManager = {
	Name = "DataManager",
	GameVersion = "0.0.3",
}
local ProfileService = require(script.ProfileService)
local ProfileTemplate = require(script.ProfileTemplate)
local ReplicaService = require(script.ReplicaService)
local Core
local Maid
local PlayerClass
local PlayerData = {}
local RunService = game:GetService("RunService")
local ProjectileManagerClass
local ProjectileManager
local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)

if RunService:IsStudio() then
	ProfileStore = ProfileStore.Mock
end

--*************************************************************************************************--

function DataManager.GetPlayerObject(player: Player)
	if not player then
		return nil
	end
	local player_entry: {}? = PlayerData[player]
	return if player_entry then player_entry.PlayerObject else nil
end

function DataManager.GetPlayerData(player: Player)
	if not player then
		return nil
	end
	local player_entry: {}? = PlayerData[player]
	return if player_entry then player_entry.Profile.Data else nil
end

function DataManager.ShareReplica(player: Player, consumer_player: Player)
	if not player then
		return nil
	end

	local player_entry: {}? = PlayerData[player]
	if not player_entry then
		return
	end

	local player_replica: {} = player_entry.Replica
	if not player_replica then
		return
	end

	player_replica:ReplicateFor(consumer_player)
end

function DataManager.RemoveReplicaConsumer(player: Player, consumer_player: Player)
	if not player then
		return nil
	end

	local player_entry: {}? = PlayerData[player]
	if not player_entry then
		return
	end

	local player_replica: {}? = player_entry.Replica
	if not player_replica then
		return
	end

	player_replica:DestroyFor(consumer_player)
end

function DataManager.RemoveReplicaConsumerList(player: Player, player_list: { [Player]: boolean })
	if not player then
		return nil
	end

	local player_entry: {}? = PlayerData[player]
	if not player_entry then
		return
	end

	local player_replica = player_entry.Replica
	if not player_replica then
		return
	end

	for consumer: Instance, _ in player_list do
		if consumer.Name ~= player.Name then
			player_replica:DestroyFor(consumer)
		end
	end
end

function DataManager.AddItem(player: Player, path_to_item: string, add_amount: number?, amount_index: string?)
	local replica: {}? = PlayerData[player].Replica
	if replica then
		if not add_amount then
			add_amount = 1
		end
		replica:Write("AddItem", path_to_item, add_amount, amount_index)
	end
end

function DataManager.RemoveItem(player: Player, path_to_item: string, remove_amount: number?, amount_index: string?)
	local replica: {}? = PlayerData[player].Replica
	if replica then
		replica:Write("RemoveItem", path_to_item, remove_amount, amount_index)
	end
end

function DataManager.DeleteEntry(player: Player, path_to_item: string)
	local replica: {}? = PlayerData[player].Replica
	if replica then
		replica:Write("DeleteEntry", path_to_item)
	end
	return true
end

function DataManager.UpdateItem(player: Player, path_to_item: string, value: any) -- TODO : CONVERT TO REPLICA
	local replica: {}? = PlayerData[player].Replica
	if replica then
		replica:Write("UpdateItem", path_to_item, value)
	end
	return true
end

function DataManager.AddPounds(player: Player, amount: number, amount_index: string?)
	local replica: {}? = PlayerData[player].Replica
	if replica then
		replica:Write("AddPounds", amount, amount_index)
	end
	return true
end

function DataManager.RemovePounds(player: Player, amount: number, amount_index: string?)
	local replica: {}? = PlayerData[player].Replica
	if replica then
		replica:Write("RemovePounds", amount, amount_index)
	end
	return true
end

function DataManager.AddHunger(player: Player, amount: number, amount_index: string?)
	local replica: {}? = PlayerData[player].Replica
	if replica then
		replica:Write("AddHunger", amount, amount_index)
	end
	return true
end

function DataManager.RemoveHunger(player: Player, amount: number, amount_index: string?)
	local replica: {}? = PlayerData[player].Replica
	if replica then
		replica:Write("RemoveHunger", amount, amount_index)
	end
	return true
end

function DataManager.SetGeneralValue(player: Player, value_index: string, value: any): boolean?
	if not value_index then
		return
	end

	local replica: {}? = PlayerData[player].Replica

	if replica then
		replica:Write("SetGeneralValue", value_index, value)
	end
	return true
end

function DataManager.AddSpace(player: Player, amount: number): boolean
	local player_data: {}? = DataManager.GetPlayerData(player)
	print(player_data, player_data.General.Space, amount, player_data.General.Space + amount)
	DataManager.SetGeneralValue(player, "Space", player_data.General.Space + amount)
	return true
end

function DataManager.RemoveSpace(player: Player, amount: number): boolean
	local player_data: {}? = DataManager.GetPlayerData(player)
	DataManager.SetGeneralValue(player, "Space", player_data.General.Space - amount)
	return true
end

function DataManager.AddSpaceAddtion(player: Player, amount: number): boolean
	local player_data: {}? = DataManager.GetPlayerData(player)
	DataManager.SetGeneralValue(player, "SpaceAddition", player_data.General.SpaceAddition + amount)
	return true
end

function DataManager.RemoveSpaceAddtion(player: Player, amount: number): boolean
	local player_data: {}? = DataManager.GetPlayerData(player)
	DataManager.SetGeneralValue(player, "SpaceAddition", player_data.General.SpaceAddition - amount)
	return true
end

function DataManager.RemovePlayerData(player: Player, wiped_player_id: number)
	local profile_key: string = "Player_" .. wiped_player_id
	local profile_mock_store = ProfileStore

	if not RunService:IsStudio() then
		profile_mock_store = ProfileStore.Mock
	end

	local mock_profile = profile_mock_store:LoadProfileAsync(profile_key, "Steal")
	mock_profile:Release()
	profile_mock_store:WipeProfileAsync(profile_key)
	return true
end

function DataManager.RevertProfile(player: Player, remote_player_id: number, profile_version_date_latest: string)
	local player_key: string = "Player_" .. remote_player_id

	local profile_versions = ProfileStore:ProfileVersionQuery(
		player_key, -- The same profile key that gets passed to :LoadProfileAsync()
		Enum.SortDirection.Descending,
		nil,
		profile_version_date_latest
	)

	local profile = profile_versions:NextAsync()
	if profile then
		profile:ClearGlobalUpdates()
		profile:OverwriteAsync()
	else
		print("Revert Not Successfull!")
	end
end

function DataManager.RefundUserAll(player: Player, refund_player_id: number)
	local profile: {}? = PlayerData[player].Profile
	local total_currency: number = profile.Data.General.RobuxCoins

	for _, item: {} in profile.Data.Items do
		if item["Refundable"] ~= nil then
			total_currency += item["Refundable"]
		end
	end
	profile.Data.General.RobuxCoins = total_currency
	return total_currency
end

function DataManager.UpdateVersionOfProfile(profile: {})
	local meta_data: {}? = profile.MetaData
	local profile_version: string = meta_data.MetaTags["ProfileVersion"]

	if profile_version ~= DataManager.GameVersion then
		print("RECONCILING THE PROFILE")
		profile:Reconcile()
	end

	profile.MetaData.MetaTags["ProfileVersion"] = DataManager.GameVersion
	return true
end

function DataManager.DataWipe(player: Player, wiped_player_id: number)
	local profile: {}? = PlayerData[player].Profile
	local total_currency: number = DataManager.RefundUserAll(player, wiped_player_id)

	profile.Data.General.RobuxCoins = total_currency

	DataManager.RemovePlayerData(player, wiped_player_id)
	DataManager.GiveItem(player, wiped_player_id, "General/RobuxCoins", "RobuxCoins", "UpdateItem")
	return true
end

function DataManager.GiveItem(
	player: Player,
	remote_player_id: number,
	path_to_item: string,
	item: string,
	action_type: string
) -- GLOBAL
	local player_key: string = "Player_" .. remote_player_id

	ProfileStore:GlobalUpdateProfileAsync(player_key, function(global_updates)
		global_updates:AddActiveUpdate({
			UpdateAction = action_type,
			ItemPath = path_to_item,
			Item = item,
		})
	end)
	return true
end

function DataManager.ProcessProfileGlobalUpdates(player, profile)
	profile.GlobalUpdates:ListenToNewActiveUpdate(function(update_id, update_data)
		profile.GlobalUpdates:LockActiveUpdate(update_id)
	end)

	profile.GlobalUpdates:ListenToNewLockedUpdate(function(update_id, update_data)
		print("Processing locked global updated! ActionType: " .. update_data.UpdateAction)
		local add_status: boolean = false
		if true then
			return
		end
		if update_data.UpdateAction == "AddItem" then
			add_status = DataManager.AddItem(player, update_data.ItemPath)
		elseif update_data.UpdateAction == "RemoveItem" then
			add_status = DataManager.RemoveItem(player, update_data.ItemPath)
		elseif update_data.UpdateAction == "UpdateItem" then
			add_status = DataManager.UpdateItem(player, update_data.ItemPath, update_data.ValuePath, update_data.Value)
		elseif update_data.UpdateAction == "DeleteEntry" then
			add_status = DataManager.DeleteEntry(player, update_data.ItemPath)
		end
		profile.GlobalUpdates:ClearLockedUpdate(update_id)
	end)

	local function process_current_profile_active_global()
		for _, update in profile.GlobalUpdates:GetActiveUpdates() do
			profile.GlobalUpdates:LockActiveUpdate(update[1])
		end
	end

	process_current_profile_active_global()
	return true
end

function DataManager.GetProjectile(
	projectile_id: string,
	object: Instance?,
	raycast_params,
	ray_update_callback,
	ray_hit_callback,
	on_terminating_callback,
	on_pierced_callback
)
	print(object, type(object))
	return ProjectileManager:CreateProjectile(
		projectile_id,
		object,
		raycast_params,
		ray_update_callback,
		ray_hit_callback,
		on_terminating_callback,
		on_pierced_callback
	)
end
--[[	
	<description>
		This function is responsible for detecting players joining the game, instantiating an 
		instance of PlayerClass for them and loading their data from the datastore. It also detects 
		players that are leaving and frees their resources once they leave. 
	</description> 
--]]
function DataManager.PlayerAddtion()
	local function PlayerAdded(player)
		local profile: {}? = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
		if profile ~= nil then
			--if player.UserId == 770772041 then
			--	print("CALLING GIVE ITEMM!!!!!")
			--	DataManager.GiveItem(player, "1509588724", "General/RobuxCoins", "RobuxCoins", "UpdateItem")
			--end
			profile:AddUserId(player.UserId) -- GDPR compliance
			DataManager.UpdateVersionOfProfile(profile)

			profile:ListenToRelease(function()
				if PlayerData[player].PlayerObject then
					PlayerData[player].PlayerObject:Destroy()
				end
				if PlayerData[player] then
					if PlayerData[player].Replica then
						PlayerData[player].Replica:Destroy()
					end
					PlayerData[player].Replica = nil
					PlayerData[player].PlayerObject = nil
					PlayerData[player].Profile = nil
					PlayerData[player] = nil
				end
				player:Kick()
			end)
			-- if player.Name == "RoGuruu" then
			-- 	DataManager.RemovePlayerData(player, player.UserId)
			-- 	player:Kick()
			-- end
			print(profile.Data.Items)
			if player:IsDescendantOf(Core.Players) == true then
				print("Added player entry!")
				local player_key = player.Name .. "PlayerData"
				local PLAYER_DATA_REPLICA_TOKEN = ReplicaService.NewClassToken(player_key)

				PlayerData[player] = {
					PlayerObject = PlayerClass.new(player, Core),
					Profile = profile,
					Replica = ReplicaService.NewReplica({
						ClassToken = PLAYER_DATA_REPLICA_TOKEN,
						Data = profile.Data, -- Table to be replicated (Retains table reference)
						Replication = player,
						WriteLib = Core.DataModules:WaitForChild("DataWriteLib"),
					}),
				}
				DataManager.ProcessProfileGlobalUpdates(player, profile)
				Core.Utils.Net:RemoteEvent("PlayerInitialLoad"):FireClient(player)
			else
				profile:Release()
			end
		else
			player:Kick()
		end
	end

	Core.Players.PlayerAdded:Connect(function(player)
		task.spawn(PlayerAdded, player)
	end)

	Core.Players.PlayerRemoving:Connect(function(player)
		if PlayerData[player] and PlayerData[player].PlayerObject then
			PlayerData[player].PlayerObject:Destroy()
			PlayerData[player].PlayerObject = nil
		end
		local profile = PlayerData[player].Profile
		if profile ~= nil then
			profile:Release()
			PlayerData[player].Profile = nil
		end
		if PlayerData[player].Replica then
			PlayerData[player].Replica:Destroy()
			PlayerData[player].Replica = nil
		end
		if PlayerData[player] then
			PlayerData[player].PlayerObject = nil
		end
		PlayerData[player] = nil
	end)

	for _, player in ipairs(Core.Players:GetPlayers()) do
		task.spawn(PlayerAdded, player)
	end
end

function DataManager.EventHandler()
	-- game.ReplicatedStorage:WaitForChild("WipePlayer").OnServerEvent:Connect(function(player, wiped_player_id)
	-- 	DataManager.RemovePlayerData(player, wiped_player_id)
	-- end)

	Core.Utils.Net:RemoteEvent("RespawnPlayer").OnServerEvent:Connect(function(player: Player)
		local player_object: {}? = DataManager.GetPlayerObject(player)

		if not player_object then
			return
		end

		if player:GetAttribute("RespawnTimer") and player:GetAttribute("RespawnTimer") <= 0 then
			player:SetAttribute("RespawnTimer", nil)
			player_object:SpawnPlayer()
		end
	end)

	Core.Utils.Net:RemoteEvent("PlayerInitialLoad").OnServerEvent:Connect(function(player: Player)
		local player_object: {}? = DataManager.GetPlayerObject(player)

		if not player_object then
			return
		end

		player_object:InitialLoading()
	end)

	Core.Utils.Net:RemoteEvent("RespawnComplete").OnServerEvent:Connect(function(player: Player)
		local player_object: {}? = DataManager.GetPlayerObject(player)

		if not player_object then
			return
		end

		player_object:ResetTools()
	end)

	Core.Utils.Net:RemoteEvent("PlayerDeath").OnServerEvent:Connect(function(player: Player)
		local player_object: {}? = DataManager.GetPlayerObject(player)

		if not player_object then
			return
		end

		player_object:DeathHandler()
	end)
end

function DataManager.Init()
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	PlayerClass = require(Core.Utils.UtilityFunctions.FindObjectWithPath(Core.Classes, "PlayerClass"))
	ProjectileManagerClass = require(Core.Classes["ProjectileManager"])
	ProjectileManager = ProjectileManagerClass.new()
	Core.Utils.Net:RemoteEvent("Knockback")
	Core.Utils.Net:RemoteEvent("ApplyImpulse")
end

function DataManager.Start()
	DataManager.PlayerAddtion()
	DataManager.EventHandler()
end

function DataManager.Reset() end

return DataManager
