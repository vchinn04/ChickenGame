--!nonstrict

print("————————————————————————————————")
print("—————Programmed by RoGuruu——————")
print("————————————————————————————————")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SmartBone = require(ReplicatedStorage:WaitForChild("SmartBone"))
local Players = game:GetService("Players")
local Utils = ReplicatedStorage:WaitForChild("Utils")
local ClientUtils = ReplicatedStorage:WaitForChild("ClientUtils")
local PLAYER_DATA_LOADED = false
local Types = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("ClientTypes"))

local Core = {}
Core.Types = Types
Core.GoodSignal = nil

export type EventTableType = typeof(setmetatable({}, {
	__index = function(self, key: string): Types.singleton
		self[key] = Core.GoodSignal.new()
		return self[key]
	end,
}))

local PLAYER_STATES: {} = {
	Alive = 1,
	Dead = 2,
}

SmartBone.Start()

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
		event_obj:Fire(unpack(args)) -- TODO: MAKE ASYNCHRONOUS!
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
						cur_entry = cur_entry:FindFirstChild(key)
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
					warn("*THERE WAS AN ERROR INITIALIZING MODULE: ", Obj.Name, "! ERROR: " .. err)
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
					warn("*THERE WAS AN ERROR STARTING MODULE : " .. Obj.Name .. "! ERROR: *" .. err)
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

-- Start Execution!
do
	Core.Global = {}
	Core.Camera = workspace.CurrentCamera
	Core.Player = Players.LocalPlayer
	Core.Mouse = Core.Player:GetMouse()
	Core.Players = game:GetService("Players")
	Core.PlayerGui = Core.Player.PlayerGui
	Core.Resources = ReplicatedStorage:WaitForChild("Resources")
	Core.EffectsWorkFolder = Instance.new("Folder")
	Core.EffectsWorkFolder.Name = "EffectsFolder"
	Core.EffectsWorkFolder.Parent = workspace

	Core.ProjectileContainer = Instance.new("Folder")
	Core.ProjectileContainer.Name = "ProjectileContainer"
	Core.ProjectileContainer.Parent = workspace

	Core.GRAVITY_VECTOR = Vector3.new(0, -15, 0)

	--Core.Events = Core.Resources:WaitForChild("Events")
	Core.Lighting = game:GetService("Lighting")
	Core.SoundFolder = Core.Resources:WaitForChild("Sounds")
	Core.EffectsFolder = Core.Resources:WaitForChild("Effects")
	Core.Terrain = workspace.Terrain
	Core.Animations = Core.Resources:WaitForChild("Animations")
	Core.UI = Core.Resources:WaitForChild("UI")
	Core.Items = Core.Resources:WaitForChild("Items")

	--[[Core.Modules = {
		Private = LazyLoader(Core.Resources:WaitForChild("Modules"):WaitForChild("Private")),
		Shared = LazyLoader(Core.Resources:WaitForChild("Modules"):WaitForChild("Shared"))	
	}]]
	Core.Utils = ImmediateRequire(Utils, false) -- Load in the utilities
	Core.ClientUtils = ImmediateRequire(ClientUtils, false) -- Load in the utilities
	Core.GoodSignal = Core.Utils.Signal
	Core.ItemDataManager = Core.Utils.ItemDataManager
	Core.Fusion = Core.ClientUtils.Fusion

	Core.Components = LazyLoader(script.Components) -- Lazy load the components which may or may nit be used

	Core.Classes = script.Classes -- Folder of classes
	Core.Managers = ImmediateRequire(script.Singletons, true) -- Load in the singletons immediatetly
	Core.CooldownClass = Core.Components["Misc/CooldownClass"]
	Core.Character = Core.Player.Character or Core.Player.CharacterAdded:Wait()
	Core.Humanoid = Core.Character:WaitForChild("Humanoid")
	Core.Humanoid.BreakJointsOnDeath = false
	Core.HumanoidRootPart = Core.Character:WaitForChild("HumanoidRootPart")
	Core.RootJoint = Core.HumanoidRootPart:WaitForChild("RootJoint")

	Core.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	Core.Animator = Core.Humanoid:WaitForChild("Animator")
	Core.Length = function(Table) -- Get the length of a dictionary
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

	Core.ActionStateManager = Core.Utils.Rodux.Store.new(
		Core.Managers.RoduxManager.ActionReducer,
		Core.Managers.RoduxManager.ActionDefaultState()
	)

	Core.InteractionStateManager = Core.Utils.Rodux.Store.new(
		Core.Managers.RoduxManager.InteractionReducer,
		Core.Managers.RoduxManager.InteractionDefaultState()
	)

	Core.ToolsStateManager = Core.Utils.Rodux.Store.new(
		Core.Managers.RoduxManager.ToolsReducer,
		Core.Managers.RoduxManager.ToolsDefaultState()
	)

	InitModules({ Core.ItemDataManager })
	InitModules(Core.Managers)

	Core.Subscribe("PlayerDataLoaded", function()
		PLAYER_DATA_LOADED = true
	end)
	while not PLAYER_DATA_LOADED do
		task.wait(1)
	end

	StartModules(Core.Managers)

	local attachTable = {
		["Left Shoulder"] = "LeftCollarAttachment",
		["Neck"] = "NeckAttachment",
		["Right Hip"] = "WaistCenterAttachment",
		["Right Shoulder"] = "RightCollarAttachment",
		["Left Hip"] = "WaistCenterAttachment",
	}

	Core.Player.CharacterAdded:Connect(function(character)
		Core.Character = character
		Core.Humanoid = Core.Character:WaitForChild("Humanoid")
		Core.Animator = Core.Humanoid:WaitForChild("Animator")
		Core.HumanoidRootPart = Core.Character:WaitForChild("HumanoidRootPart")
		Core.RootJoint = Core.HumanoidRootPart:WaitForChild("RootJoint")

		ResetModules(Core.Managers)
		StartModules(Core.Managers)

		Core.Utils.Net:RemoteEvent("RespawnComplete"):FireServer()

		Core.Humanoid.Died:Connect(function()
			-- Do DEATH STUFF ResetModules(Core.Managers)
			Core.Utils.Net:RemoteEvent("PlayerDeath"):FireServer()
			Core.ToolManagerClient.UnequipAll()
			ResetModules(Core.Managers)
			Core.Fire("PlayerDeath")
		end)

		-- local player_general_data: {} = Core.ReplicaServiceManager.GetData().General
		-- Core.PlayerMovement.Overweight(
		-- 	player_general_data.Space,
		-- 	(player_general_data.BaseSpace + player_general_data.SpaceAddition)
		-- )
	end)

	Core.Humanoid.Died:Connect(function()
		print("Player Died")
		Core.Utils.Net:RemoteEvent("PlayerDeath"):FireServer()
		Core.ToolManagerClient.UnequipAll()
		ResetModules(Core.Managers)
		Core.Fire("PlayerDeath")
	end)

	-- local player_general_data: {} = Core.ReplicaServiceManager.GetData().General
	-- Core.PlayerMovement.Overweight(
	-- 	player_general_data.Space,
	-- 	(player_general_data.BaseSpace + player_general_data.SpaceAddition)
	-- )

	-- Core.Player:GetAttributeChangedSignal("Status"):Connect(function()
	-- 	local state: number = Core.Player:GetAttribute("Status")
	-- 	print("New State: ", state)
	-- 	if state == PLAYER_STATES.Dead then
	-- 		print("Player Died")
	-- 		ResetModules(Core.Managers)
	-- 		Core.Fire("PlayerDeath")
	-- 	else
	-- 		ResetModules(Core.Managers)
	-- 		StartModules(Core.Managers)
	-- 	end
	-- end)
	-- local initial_load_event = nil
	initial_load_event = Core.Utils.Net:RemoteEvent("PlayerInitialLoad").OnClientEvent:Connect(function()
		Core.Utils.Net:RemoteEvent("PlayerInitialLoad"):FireServer()
		-- initial_load_event:Disconnect()
		-- initial_load_event = nil
	end)

	print("————————————————————————————————")
	print("—————Init/Starting Complete—————")
	print("————————————————————————————————")
end
