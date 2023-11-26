local InteractionManager = {
	Name = "InteractionManager",
}
--[[
	<description>
		This manager is responsible for routing interaction requests to to specified 
		classes and lazily instantiating those classes.
	</description> 
	
	<API>
		InteractionManager.Interact(object: Instance, tag: string) ---> nil
			-- Call the interaction function proximity type if found
			tag : string --> ProximityPromt name (Name of interact Tag)
			object : Instance --> Object that holds proximity

		InteractionManager.Trigger(object: Instance, tag: string) ---> nil
			-- Call the trigger (OnHold) function proximity type if found
			tag : string --> ProximityPromt name
			object : Instance --> Object that holds proximity
			
		InteractionManager.TriggerEnd(object: Instance, tag: string) ---> nil
			-- Call the trigger end (OnRelease) function proximity type if found
			tag : string --> ProximityPromt name
			object : Instance --> Object that holds proximity
			
		InteractionManager.SetCustom(set_type: string, set_obj: any, set_tag: string, func_class: {[string] : any}, func: <a>(a) -> ())  ---> nil
			-- Set a custom interaction function for a specified table and proximity
			set_type : string --> Table to which function is to be assigned. Types: Trigger, TriggerEnd; Default: Interaction Table
			set_obj: any ---> Object that holds proximity
			set_tag: string --> ProximityPromt name
			func_class: {[string] : any} ---> Class instance of object being added
			func : <a>(a) -> () --> Function that accepts 1 argument (object)

		InteractionManager.RemoveCustom(set_type: string, set_tag: string, set_obj: any) 
			-- Remove a custom interaction function for a specified table and proximity
			set_type : string--> Table from which function is to be removed. Types: Trigger, TriggerEnd; Default: Interaction Table
								 "All" will remove alll the Custom functions for that object.
			set_tag : string --> ProximityPromt name
			set_obj : any ---> Object whoose interaction being removed

		InteractionManager.SetDefault(set_type: string, set_obj: any, set_tag: string, func_class, func: <a>(a) -> ()) ---> nil
			-- Set a default interaction function for a specified table and proximity
			set_type : string --> Table to which function is to be assigned. Types: Trigger, TriggerEnd; Default: Interaction Table
			set_obj: any ---> Object that holds proximity
			set_tag: string --> ProximityPromt name
			func_class: {[string] : any} ---> Class instance of object being added
			func : <a>(a) -> () --> Function that accepts 1 argument (object)

		InteractionManager.RemoveDefault(set_type: string, set_tag: string, set_obj: any) ---> nil
			-- Remove a default interaction function for a specified table and proximity
			set_type : string--> Table from which function is to be removed. Types: All, Trigger, TriggerEnd; Default: Interaction Table
			set_tag : string --> ProximityPromt name (Note: ignore for "All")
			set_obj : any ---> Instance of destroyed interaction entry

		InteractionManager.BinderSetup() ---> nil
			-- Goes through the interactable Data (See ReplicatedStorage/ItemDataManager/InteractableData) and 
			   listens to Tagged objects being added, where the tag name is the same as the key. Binds specified 
			   class to Tags, that is an instance of specified class is created whenever object with specified Tag 
			   is added.

		InteractionManager.EventHandler()  ---> nil
			-- Handle incoming events such as melee, movement, etc
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local Core
local Maid

-- Store the functions to be called for specific Proximities when held long enough

local InteractionTable = {
	Customs = {}, -- Custom interactions
	Defaults = {
		--[[
		[object] = {
			[tag_name] = {object_class, function_to_call},
		}
	]]
	},
}

-- Store the functions to be called for specific Proximities when Triggered (OnHold)

local TriggerTable = {
	Customs = {},
	Defaults = {},
}

-- Store the functions to be called for specific Proximities when user releases key (Not Fired when user successfully interacted with item)

local TriggerEndTable = {
	Customs = {},
	Defaults = {},
}

local InteracationClasses = setmetatable({}, {
	__index = function(self, key)
		local class = Core.Utils.UtilityFunctions.FindObjectWithPath(Core.Classes, `Interactables/{key}`)
		if class then
			self[key] = require(class)
			return self[key]
		end
		return nil
	end,
})

--*************************************************************************************************--

function InteractionManager.Interact(object: Instance, tag: string): nil
	print(InteractionTable.Defaults[object])
	if InteractionTable.Customs[object] and InteractionTable.Customs[object][tag] then
		InteractionTable.Customs[object][tag][2](InteractionTable.Customs[object][tag][1], object)
	elseif InteractionTable.Defaults[object] and InteractionTable.Defaults[object][tag] then
		InteractionTable.Defaults[object][tag][2](InteractionTable.Defaults[object][tag][1], object)
	end
	return
end

function InteractionManager.Trigger(object: Instance, tag: string): nil
	if TriggerTable.Customs[object] and TriggerTable.Customs[object][tag] then
		TriggerTable.Customs[object][tag][2](TriggerTable.Customs[object][tag][1], object)
	elseif TriggerTable.Defaults[object] and TriggerTable.Defaults[object][tag] then
		TriggerTable.Defaults[object][tag][2](TriggerTable.Defaults[object][tag][1], object)
	end
	return
end

function InteractionManager.TriggerEnd(object: Instance, tag: string): nil
	if TriggerEndTable.Customs[object] and TriggerEndTable.Customs[object][tag] then
		TriggerEndTable.Customs[object][tag][2](TriggerEndTable.Customs[object][tag][1], object)
	elseif TriggerEndTable.Defaults[object] and TriggerEndTable.Defaults[object][tag] then
		TriggerEndTable.Defaults[object][tag][2](TriggerEndTable.Defaults[object][tag][1], object)
	end
	return
end

function InteractionManager.SetCustom(
	set_type: string,
	set_obj: any,
	set_tag: string,
	func_class,
	func: <a>(a) -> ()
): nil
	if set_type == "Trigger" then
		if not TriggerTable.Customs[set_obj] then
			TriggerTable.Customs[set_obj] = {}
		end
		TriggerTable.Customs[set_obj][set_tag] = { func_class, func }
	elseif set_type == "TriggerEnd" then
		if not TriggerEndTable.Customs[set_obj] then
			TriggerEndTable.Customs[set_obj] = {}
		end
		TriggerEndTable.Customs[set_obj][set_tag] = { func_class, func }
	else
		if not InteractionTable.Customs[set_obj] then
			InteractionTable.Customs[set_obj] = {}
		end
		InteractionTable.Customs[set_obj][set_tag] = { func_class, func }
	end
	return
end

function InteractionManager.RemoveCustom(set_type: string, set_tag: string, set_obj: any): nil
	if set_type == "All" then
		if TriggerTable.Customs[set_obj] then
			for key, _ in TriggerTable.Customs[set_obj] do
				TriggerTable.Customs[set_obj][key] = nil
			end
			TriggerTable.Customs[set_obj] = nil
		end

		if TriggerEndTable.Customs[set_obj] then
			for key, _ in TriggerEndTable.Customs[set_obj] do
				TriggerEndTable.Customs[set_obj][key] = nil
			end
			TriggerEndTable.Customs[set_obj] = nil
		end

		if InteractionTable.Customs[set_obj] then
			for key, _ in InteractionTable.Customs[set_obj] do
				InteractionTable.Customs[set_obj][key] = nil
			end
			InteractionTable.Customs[set_obj] = nil
		end
	elseif set_type == "Trigger" then
		TriggerTable.Customs[set_obj][set_tag] = nil
	elseif set_type == "TriggerEnd" then
		TriggerEndTable.Customs[set_obj][set_tag] = nil
	else
		InteractionTable.Customs[set_obj][set_tag] = nil
	end
	return
end

function InteractionManager.SetDefault(
	set_type: string,
	set_obj: any,
	set_tag: string,
	func_class,
	func: <a>(a) -> ()
): nil
	if set_type == "Trigger" then
		if not TriggerTable.Defaults[set_obj] then
			TriggerTable.Defaults[set_obj] = {}
		end
		TriggerTable.Defaults[set_obj][set_tag] = { func_class, func }
	elseif set_type == "TriggerEnd" then
		if not TriggerEndTable.Defaults[set_obj] then
			TriggerEndTable.Defaults[set_obj] = {}
		end
		TriggerEndTable.Defaults[set_obj][set_tag] = { func_class, func }
	else
		if not InteractionTable.Defaults[set_obj] then
			InteractionTable.Defaults[set_obj] = {}
		end
		InteractionTable.Defaults[set_obj][set_tag] = { func_class, func }
	end
	return
end

function InteractionManager.RemoveDefault(set_type: string, set_tag: string?, set_obj: any): nil
	if set_type == "All" then
		if TriggerTable.Defaults[set_obj] then
			for key, _ in TriggerTable.Defaults[set_obj] do
				TriggerTable.Defaults[set_obj][key] = nil
			end
			TriggerTable.Defaults[set_obj] = nil
		end

		if TriggerEndTable.Defaults[set_obj] then
			for key, _ in TriggerEndTable.Defaults[set_obj] do
				TriggerEndTable.Defaults[set_obj][key] = nil
			end
			TriggerEndTable.Defaults[set_obj] = nil
		end

		if InteractionTable.Defaults[set_obj] then
			for key, _ in InteractionTable.Defaults[set_obj] do
				InteractionTable.Defaults[set_obj][key] = nil
			end
			InteractionTable.Defaults[set_obj] = nil
		end
	elseif set_type == "Trigger" then
		TriggerTable.Defaults[set_obj][set_tag] = nil
	elseif set_type == "TriggerEnd" then
		TriggerEndTable.Defaults[set_obj][set_tag] = nil
	else
		InteractionTable.Defaults[set_obj][set_tag] = nil
	end

	return
end

function InteractionManager.BinderSetup(): nil
	for key, entry in Core.ItemDataManager.GetInteractableData() do
		local maid_key = key .. "Binder"
		entry.Id = key

		if not InteracationClasses[entry.Class] then
			continue
		end

		local binder = Core.Utils.Binder.new(key, InteracationClasses[entry.Class], entry)

		binder:GetClassAddedSignal():Connect(function(class_instance)
			Core.InteractionManager.SetDefault(
				"Default",
				class_instance:GetObject(),
				key,
				class_instance,
				class_instance.Interact
			)
		end)

		binder:GetClassRemovingSignal():Connect(function(class_instance)
			InteractionManager.RemoveDefault("All", key, class_instance:GetObject())
		end)

		binder:Start()
	end
	return
end

function InteractionManager.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("InteractionTriggered", function(tag: string, object: Instance)
		InteractionManager.Trigger(object, tag)
	end))
	Maid:GiveTask(Core.Subscribe("InteractionTriggerEnded", function(tag: string, object: Instance)
		InteractionManager.TriggerEnd(object, tag)
	end))
	Maid:GiveTask(Core.Subscribe("InteractionSuccess", function(tag: string, object: Instance)
		InteractionManager.Interact(object, tag)
	end))

	return
end

function InteractionManager.Start(): nil
	InteractionManager.EventHandler()
	return
end

function InteractionManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	InteractionManager.BinderSetup()
	return
end

function InteractionManager.Reset(): nil
	Maid:DoCleaning()
	return
end

return InteractionManager
