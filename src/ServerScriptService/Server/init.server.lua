print("————————————————————————————————")
print("—————Programmed by RoGuruu——————")
print("————————————————————————————————")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = ReplicatedStorage:WaitForChild("Utils")
local Types = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("ClientTypes"))
local PhysicsService = game:GetService("PhysicsService")

local Core = {}
Core.GoodSignal = nil

export type EventTableType = typeof(setmetatable({}, {
	__index = function(self, key: string): Types.singleton
		self[key] = Core.GoodSignal.new()
		return self[key]
	end,
}))

-------------------------------------------------------------------
-- Event Calling and Subscribing Format:
-- 	Core.Subscribe(event_name, function(args)  end) : callback_key
--  Core.Unsubscribe(event_name, callback_key)
--  Core.Fire(event_name, ...)
-------------------------------------------------------------------

-- Store a global even dictionary
-- Each event entry is a GoodSignal object.
local EventTable: EventTableType = setmetatable({}, {
	__index = function(self, key: string): Types.singleton
		self[key] = Core.GoodSignal.new()
		return self[key]
	end,
})

-- Fire specified event in global event system
-- event_name -> Name of the event you are firing
-- ... -> the arguments passed to the callbacks. (Core.Fire is a variadic function). Arguments have to passed in an array, the order has to be the order of callback params.
Core.Fire = function(event_name: string, ...: any): nil
	local event_obj: Types.singleton = EventTable[event_name]
	local args = { ... }

	local succ, err = pcall(function()
		event_obj:Fire(unpack(args))
	end) -- Call the callback in a couroutine and pass in the args. unpack() converts table to just the items. Note we are creating a shallow copy, may have to create deepcopy function if need to pass nested tables!
	if not succ then
		warn("*THERE WAS EVENT CALL ERROR *" .. err)
	end
	return
end

-- Subscribe to specified event in global event system
-- event_name -> Name of the event you are subscribing to
-- callback -> the callback function that will be added to table and called whenever event is fired.
Core.Subscribe = function(event_name: string, callback: (...any) -> nil): Types.singleton
	local event_obj: Types.singleton = EventTable[event_name]
	return event_obj:Connect(callback)
end

-- Unsubscribe from specified event in global event system
-- call_back_obj -> Event object to disconnect
Core.Unsubscribe = function(call_back_obj: Types.singleton): nil
	call_back_obj:Disconnect()
	return
end

-- Require modules right away and store them in a dictionary and return the dict
-- Folder -> Folder where modules located
-- set_core -> determines if the object should have the core attribute set

function ImmediateRequire(Folder: Folder, set_core: boolean): { [string]: Types.singleton }?
	local returnDict = {}

	for _, Module in pairs(Folder:GetChildren()) do
		if not string.match(Module.Name, "Disabled") then
			print(Module)
			local Obj: Types.singleton = require(Module) :: any
			if set_core then
				Obj.Core = Core
			end
			returnDict[Module.Name] = Obj
		end
	end

	return returnDict
end

-- Returns a dictionary with a metatable that requires a module only when it is called
-- Folder -> Folder where modules located. Can contain subfolders.

function LazyLoader(Folder: Folder): (Types.metatable & { [string]: Types.singleton })?
	return setmetatable({}, {
		__index = function(self, module_path: string): Types.singleton?
			local succ, res = pcall(function(): Types.singleton?
				if not string.match(module_path, "Disabled") then
					local path_list: { [number]: string } = string.split(module_path, "/")
					local cur_entry: Instance = Folder

					for _, key in path_list do
						cur_entry = cur_entry:WaitForChild(key, 5)
						if not cur_entry then
							return nil
						end
					end

					local Obj: Types.singleton = require(cur_entry) :: any

					if type(Obj) == table then
						Obj.Core = Core
					end

					self[module_path] = Obj

					return Obj
				else
					return nil
				end
			end)

			if succ then
				return res
			else
				warn(res, 2)
				return
			end
		end,
	})
end

-- Calls the init function of the specified modules if it exists
-- Objects -> table of modules to instantiate

function InitModules(Objects: { [string | number]: Types.singleton }): nil
	for _, Obj in pairs(Objects) do
		if Obj.Init then
			task.spawn(function()
				local succ, err = pcall(function()
					Obj.Init()
				end)

				if succ then
					print("*MODULE INITIALIZED: *", Obj.Name)
				else
					warn("*THERE WAS AN ERROR INITIALIZING MODULE! ERROR: " .. err)
				end
			end)
		end
	end
	return
end

-- Calls the start function of the specified modules if it exists
-- Objects -> table of modules to start

function StartModules(Objects: { [string | number]: Types.singleton }): nil
	for _, Obj in pairs(Objects) do
		if Obj.Start then
			task.spawn(function()
				local succ, err = pcall(function()
					Obj.Start()
				end)
				if succ then
					print("*MODULE STARTED: *", Obj.Name)
				else
					warn("*THERE WAS AN ERROR STARTING MODULE! ERROR: *" .. err)
				end
			end)
		end
	end
	return
end

-- Calls the reset function of the specified modules if it exists
-- Objects -> table of modules to reset

function ResetModules(Objects: { [string | number]: Types.singleton }): nil
	for i, Obj in pairs(Objects) do
		if Obj.Reset then
			task.spawn(function()
				local succ, err = pcall(function()
					Obj.Reset()
				end)

				if succ then
					print("*MODULE RESET: *", Obj.Name)
				else
					warn("*THERE WAS AN ERROR RESETTING MODULE! ERROR: *" .. err)
				end
			end)
		end
	end
	return
end

function UtilRequire(Folder)
	local returnDict = {}

	for _, Module in pairs(Folder:GetChildren()) do
		if not string.match(Module.Name, "Disabled") then
			local Obj = require(Module)
			returnDict[Module.Name] = Obj
		end
	end

	return returnDict
end

do
	local player_collision_group = "Players"
	local drop_collision_group = "Drops"

	PhysicsService:RegisterCollisionGroup(player_collision_group)
	PhysicsService:RegisterCollisionGroup(drop_collision_group)

	PhysicsService:CollisionGroupSetCollidable(player_collision_group, drop_collision_group, false)

	Core.Global = {}

	Core.Players = game:GetService("Players")
	Core.Players.CharacterAutoLoads = false
	Core.Resources = ReplicatedStorage:WaitForChild("Resources")
	Core.DataModules = ReplicatedStorage:WaitForChild("DataModules")
	Core.GRAVITY_VECTOR = Vector3.new(0, -15, 0)
	--Core.Events = Core.Resources:WaitForChild("Events")
	--Core.Sounds = Core.Resources:WaitForChild("Sounds")
	Core.Lighting = game:GetService("Lighting")

	--Core.Items = Core.Resources:WaitForChild("Items")
	--Core.Particles = Core.Resources:WaitForChild("Particles")
	Core.AnimationFolder = Core.Resources:WaitForChild("Animations")
	Core.EffectsFolder = Core.Resources:WaitForChild("Effects")

	Core.SoundFolder = Core.Resources:WaitForChild("Sounds")
	Core.Items = Core.Resources:WaitForChild("Items")
	--Core.UI = Core.Resources:WaitForChild("UI")
	--Core.PlayerData = require(Core.Resources:WaitForChild("Modules"):WaitForChild("ModuleScript"))

	--[[Core.Modules = {
		Private = LazyLoader(Core.Resources:WaitForChild("Modules"):WaitForChild("Private")),
		Shared = LazyLoader(Core.Resources:WaitForChild("Modules"):WaitForChild("Shared"))	
	}]]

	--Core.MainData = Core.Modules.Shared.MainData
	--Core.Module3D = Core.Modules.Private.Module3D
	Core.Components = LazyLoader(script.Components)
	Core.Classes = script.Classes
	Core.Utils = UtilRequire(Utils)
	Core.ItemDataManager = Core.Utils.ItemDataManager
	Core.GoodSignal = Core.Utils.Signal

	Core.Managers = ImmediateRequire(script.Singletons, true)

	--Core.MainGui = Core.Player.PlayerGui:WaitForChild("MainGui")
	Core.Length = function(Table)
		local counter = 0
		for _, v in Table do
			counter = counter + 1
		end
		return counter
	end

	setmetatable(Core, {
		__index = Core.Managers, -- Allow for shortcut to main modules
	})

	_G.Core = Core

	InitModules(Core.Managers)
	InitModules({ Core.ItemDataManager })
	Core.ItemDataManager.GenerateCache()
	StartModules(Core.Managers)

	print("————————————————————————————————")
	print("—————Init/Starting Complete—————")
	print("———————————���————————————————————")
end
