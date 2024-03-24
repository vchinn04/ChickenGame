local types = require(script.Parent.Parent.ServerTypes)

local InteractionManager = {
	Name = "InteractionManager",
}
--[[
	<description>
		This manager is responsible for routing interaction requests to to specified 
		classes and lazily instantiating those classes.
	</description> 
	
	<API>
		InteractionManager.CreateDrop(drop_name: string, drop_location: Vector3): nil
			-- Creates a drop of specified item at specified location. 
			drop_name: string ---> Name of item to be dropped. Note: Model of same name has to exist. 
			drop_location: Vector3 ---> Location at which drop is to appear 

		InteractionManager.MakeLootable(object: Instance) ---> nil 
			-- Add lootable tag to object to make it a lootable interactable 

		InteractionManager.GetInteractableInstance(object: Instance) ---> { [string]: any }?
			-- Return interaction class instance for specified object. If it does not exist, create one and assciate it with object. 
			object: Instance ---> Object whoose class instance is being fetched. 

		InteractionManager.BinderSetup() ---> nil 
			-- Goes through the interactable Data (See ReplicatedStorage/ItemDataManager/InteractableData) and 
			   listens to Tagged objects being added, where the tag name is the same as the key. Binds specified 
			   class to Tags, that is an instance of specified class is created whenever object with specified Tag 
			   is added.
			   
		InteractionManager.EventHandler() ---> nil
			-- Handle incoming events such as melee, movement, etc
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local Core
local Maid
local CollectionService = game:GetService("CollectionService")

local InteracationClasses = {}

-- setmetatable({}, {
-- 	__index = function(self, key)
-- 		local class: {} = Core.Utils.UtilityFunctions.FindObjectWithPath(Core.Classes.Interactables, key)
-- 		if class then
-- 			self[key] = require(class)
-- 			return self[key]
-- 		end
-- 		return nil
-- 	end,
-- })

local InteractionInstances = {} :: {
	Instance: {
		string: types.InteractionClassObject,
	},
}

--*************************************************************************************************--

function InteractionManager.GetInteracationClass(class_name: string): types.InteractionClass?
	local interaction_class: types.InteractionClass? = InteracationClasses[class_name]

	if interaction_class then
		return interaction_class
	end

	local succ, res = pcall(function()
		local class = Core.Utils.UtilityFunctions.FindObjectWithPath(Core.Classes.Interactables, class_name)
		if class then
			local Obj: types.InteractionClass = require(class)
			InteracationClasses[class_name] = Obj
			return Obj
		end
	end)

	if succ then
		if res then
			return res
		else
			warn("INTERACTION CLASS: ", class_name, " NOT FOUND!")
			return nil
		end
	else
		warn("INTERACTION CLASS OBJ: ", class_name, " ERROR! ERROR: ", res)
		return nil
	end
end

function InteractionManager.CreateDrop(drop_name: string, drop_location: Vector3): Model?
	local drop_id: string = Core.ItemDataManager.NameToId(drop_name)
	if not drop_id then
		drop_id = drop_name
		warn("No data entry in ItemDataManager for: " .. drop_name .. " found! Trace: InteractionManager.CreateDrop()")
	end

	local drop_template: Instance = Core.Items:WaitForChild(drop_id, 3)
	if not drop_template then
		warn("No model for: " .. drop_name .. " found! Trace: InteractionManager.CreateDrop()")
		return
	end

	local drop_item: Model = Core.Utils.UtilityFunctions.ToModel(drop_template:Clone())
	local primary_part: BasePart? = drop_item.PrimaryPart

	if not primary_part then
		warn("No primary part for drop item: ", drop_id, " found!")
	end

	for _, part: Instance in drop_item:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Drops"
			part.Anchored = true
			if part ~= primary_part then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = primary_part
				weld.Part1 = part
				weld.Name = part.Name
				weld.Parent = primary_part
			end
			part.CanCollide = true
			part.Anchored = false
		end
	end

	drop_item:SetAttribute("Id", drop_id)

	if drop_location then
		drop_item.Parent = workspace
		drop_item:MoveTo(drop_location)
	end

	CollectionService:AddTag(drop_item, "Drop")
	return drop_item
end

function InteractionManager.MakeLootable(object: Instance): nil
	CollectionService:AddTag(object, "Lootable")
	return
end

function InteractionManager.GetInteractableInstance(object: Instance, key: string): types.InteractionClassObject?
	if InteractionInstances[object] and InteractionInstances[object][key] then
		return InteractionInstances[object][key]
	end

	local object_tags: { [number]: string } = object:GetTags()
	local interaction_class = nil
	local interactable_data: { string: types.InteractionData } = Core.ItemDataManager.GetInteractableData()

	for _, tag: string in object_tags do
		local interactable_entry = interactable_data[tag]

		if interactable_entry then
			interaction_class = InteractionManager.GetInteracationClass(interactable_entry.Class)
			if not interaction_class then
				continue
			end

			if InteractionInstances[object] then
				InteractionInstances[object][tag] = interaction_class.new(object, Core, interactable_entry)
			else
				InteractionInstances[object] = {
					[tag] = interaction_class.new(object, Core, interactable_entry),
				}
			end
		end
	end

	if InteractionInstances[object] and InteractionInstances[object][key] then
		return InteractionInstances[object][key]
	else
		return nil
	end
end

function InteractionManager.BinderSetup(): nil
	for key: string, entry: types.InteractionData in Core.ItemDataManager.GetInteractableData() do
		local maid_key: string = key .. "Binder"
		entry.Id = key

		local interaction_class: {}? = InteractionManager.GetInteracationClass(entry.Class)
		--InteracationClasses[entry.Class]
		if not interaction_class then
			return
		end

		Maid[maid_key] = Core.Utils.Binder.new(key, interaction_class, entry)
		Maid[maid_key]:GetClassAddedSignal():Connect(function(class_instance)
			if InteractionInstances[class_instance:GetObject()] then
				InteractionInstances[class_instance:GetObject()][key] = class_instance
			else
				InteractionInstances[class_instance:GetObject()] = {
					[key] = class_instance,
				}
			end
		end)
		Maid[maid_key]:Start()
	end
	return
end

function InteractionManager.EventHandler(): nil
	Maid:GiveTask(
		Core.Utils.Net:RemoteEvent("InteractionTriggered").OnServerEvent:Connect(function(tag: string, object: Instance)
			print("Trigger Began!")
		end)
	)
	Maid:GiveTask(
		Core.Utils.Net
			:RemoteEvent("InteractionTriggerEnded").OnServerEvent
			:Connect(function(tag: string, object: Instance)
				print("Trigger Ended!")
			end)
	)
	Maid:GiveTask(
		Core.Utils.Net
			:RemoteEvent("InteractionSuccess").OnServerEvent
			:Connect(function(player: Player, object: Instance, key: string, ...)
				if not object then
					return
				end
				local args: { any } = { ... }
				local interaction_instance = InteractionManager.GetInteractableInstance(object, key)
				if interaction_instance then
					interaction_instance:Interact(player, table.unpack(args))
				end
			end)
	)

	Maid:GiveTask(Core.Subscribe("PlayerDeath", function(player, character)
		InteractionManager.MakeLootable(character)
	end))

	InteractionManager.BinderSetup()
	return
end

function InteractionManager.Start(): nil
	InteractionManager.EventHandler()
	return
end

function InteractionManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	Core.Utils.Net:RemoteEvent("TreeInteract")
	Core.Utils.Net:RemoteEvent("DefaultInteract")
	return
end

function InteractionManager.Reset(): nil
	return
end

return InteractionManager
