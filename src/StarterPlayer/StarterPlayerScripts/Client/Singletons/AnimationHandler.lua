local AnimationHandler = {
	Name = "AnimationHandler",
}
--[[
	<description>
		This manager is responsible for dynamically loading in the animations 
		and playing/managing the requested animations. 
	</description> 
	
	<API>
		AnimationObject:CreateAnimation(anim_id, anim_folder)  ---> AnimationTrack
			-- Load in the animation if Animation instance already exists, else create the animation instance.
			anim_id : Animation | string -- Tool instance player is equipping 
			anim_folder : Folder -- folder in which animations for current object are stored
			
		AnimationObject:GetAnimation(anim_id : string, custom_folder) ---> AnimationTrack
			-- Return an animation track from the TrackTable, else create the AnimationTrack, 
			-- add it to table and return it
			anim_id : string -- Name of Animation
			custom_folder : Folder -- folder in which animations for current object are stored
			
		AnimationObject:StopAnimation(anim_name: string, custom_folder) ---> void
			-- Stop the specified animation
			anim_name : string -- Name of Animation
			custom_folder : Folder -- folder in which animations for current object are stored		
			
		AnimationObject:PlayAnimation(anim_name: string, custom_folder, return_promise: boolean?) ---> AnimationTrack | Promise
			-- Play the specified animation
			anim_name : string -- Name of Animation
			custom_folder : Folder -- folder in which animations for current object are stored		
			return_promise: boolean? ---> Whether to return a promise that resolves when animation is complete 

		AnimationObject:GetMarkerReachedSignal(anim_name: string, mark_name: string, func) ---> nil 
			-- Connect a function to a MarkerReachedSignal provided marker name 
			anim_name: string -- Name of animation 
			mark_name: string -- Name of marker 
			func: () -> () -- Function to connect 

		AnimationObject:SetPriority(anim_name: string, priority: Enum.AnimationPriority, custom_folder) ---> void
			-- Set specified animation to a certain priority
			anim_name : string -- Name of Animation
			priority : Enum.AnimationPriority -- Priority to set animation to
			custom_folder : Folder -- folder in which animations for current object are stored	
		
		AnimationObject:load_anims(anim_arr) ---> void
			-- Load an array of animations and add them to animation table
			anim_arr : {string | Animation}
			
		AnimationObject:DoCleaning() ---> void
			-- Stop all animations and clear the animation running table

		AnimationObject:Destroy() ---> void
			-- Stop all animations and destroy object

		//------------------------------------
		
		AnimationHandler.Create(preload_anims, path) ---> AnimationObject
			-- Create an animation object and load in the provided animations. Find the animation folder provided 
			preload_anims : {string | Animation} 
			path : string -- Path to animation folder. Format: "./folderName" or "folderName" or "folderName/folder2" NOTE: All start at the Core.Animations folder.
			
		AnimationHandler.GetAnimationObjects() ---> {AnimationObject}
			-- Return a list of animation objects
			
		AnimationHandler.LoadAnimation(animation_obj: Animation) ---> Animation Track or nil
			-- Load animation into animator
			animation_obj : AnimationTrack -- animation track to load 
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local Types = require(game.ReplicatedStorage:WaitForChild("Utils"):WaitForChild("ClientTypes"))

local Core
local Maid
local DynamicFolder = nil
local CProvider = game:GetService("ContentProvider")

local TrackTable: { [string]: AnimationTrack } = {}
local AnimationTable: { [string]: Animation } = {}

local AnimationObject = {}
AnimationObject.__index = AnimationObject

--*************************************************************************************************--

function AnimationObject:CreateAnimation(anim_id: Animation | string, anim_folder: Folder?): AnimationTrack
	if typeof(anim_id) == "Instance" and anim_id:IsA("Animation") then
		AnimationTable[(self._path .. anim_id.Name)] = anim_id
		return AnimationHandler.LoadAnimation(anim_id) :: AnimationTrack
	end

	if AnimationTable[(self._path .. anim_id)] ~= nil then
		return AnimationHandler.LoadAnimation(AnimationTable[(self._path .. anim_id)]) :: AnimationTrack
	end

	if anim_folder and anim_folder:WaitForChild(anim_id, 3) then
		local anim: Animation = anim_folder:WaitForChild(anim_id, 3) :: Animation
		return AnimationHandler.LoadAnimation(anim) :: AnimationTrack
	end

	if
		self._anim_folder:WaitForChild(anim_id, 3)
		or Core.Animations:WaitForChild("PreloadAnims"):WaitForChild(anim_id, 3)
	then
		local anim: Animation = self._anim_folder:FindFirstChild(anim_id)
			or Core.Animations.PreloadAnims:FindFirstChild(anim_id)
		AnimationTable[(self._path .. anim_id)] = anim
		return AnimationHandler.LoadAnimation(anim) :: AnimationTrack
	end

	local animation_instance: Animation = Instance.new("Animation")
	animation_instance.Name = anim_id

	CProvider:PreloadAsync({ animation_instance })

	animation_instance.Parent = DynamicFolder
	animation_instance.AnimationId = anim_id
	AnimationTable[(self._path .. anim_id)] = animation_instance

	return AnimationHandler.LoadAnimation(animation_instance) :: AnimationTrack
end

function AnimationObject:GetAnimation(
	anim_id: string | {},
	anim_priority: Enum.AnimationPriority?,
	custom_folder: Folder?
): AnimationTrack
	if typeof(anim_id) == "table" then
		anim_priority = anim_id.Priority
		anim_id = anim_id.Name
	end
	if TrackTable[(self._path .. anim_id)] then
		local anim_track: AnimationTrack = TrackTable[(self._path .. anim_id)]
		if anim_priority then
			anim_track.Priority = anim_priority
		end
		return anim_track
	else
		local anim = self:CreateAnimation(anim_id, custom_folder)
		if anim and anim_priority then
			anim.Priority = anim_priority
		end
		TrackTable[(self._path .. anim_id)] = anim
		return TrackTable[(self._path .. anim_id)]
	end
end

-- Resumes a specified paused animation
-- anim_name --> name of animation
function AnimationObject:ResumeAnimation(anim_name: string): nil
	return
end

-- Pauses the specified animation
-- anim_name --> name of animation
-- [duration] --> duration after which to pause. If not specified, immediately pause
function AnimationObject:PauseAnimation(anim_name: string, duration: number): nil
	return
end

function AnimationObject:StopAnimation(anim_name: string?, custom_folder: Folder): nil
	if not anim_name then
		return
	end

	local animation = self:GetAnimation(anim_name, nil, custom_folder)
	if animation then
		animation:Stop()
	end
	return
end

function AnimationObject:PlayAnimation(
	anim_name: string? | {}?,
	custom_folder: Folder?,
	return_promise: boolean?,
	animation_priority: Enum.AnimationPriority?
): AnimationTrack | {}
	if not anim_name then
		return
	end

	local animation: AnimationTrack = self:GetAnimation(anim_name, animation_priority, custom_folder)
	local promise = nil

	if animation then
		table.insert(self._anim_list, animation)
		animation:Play()
		if return_promise then
			promise = Core.Utils.Promise.new(function(resolve, _, _)
				animation.Stopped:Wait()
				resolve()
			end)
		end
	end

	return animation, promise
end

function AnimationObject:PlayReverse(
	anim_name: string? | {}?,
	custom_folder: Folder?,
	anim_speed: number?,
	return_promise: boolean?,
	animation_priority: Enum.AnimationPriority?
): AnimationTrack | {}
	if not anim_name then
		return
	end

	local animation: AnimationTrack = self:GetAnimation(anim_name, animation_priority, custom_folder)
	local promise = nil

	if animation then
		animation.TimePosition = animation.Length

		table.insert(self._anim_list, animation)
		if anim_speed then
			animation:AdjustSpeed(-1 * anim_speed)
		else
			animation:AdjustSpeed(-1)
		end
		animation:Play()
		if return_promise then
			promise = Core.Utils.Promise.new(function(resolve, _, _)
				animation.Stopped:Wait()
				resolve()
			end)
		end
	end

	return animation, promise
end

function AnimationObject:SetSpeed(anim_track: AnimationTrack?, anim_speed: number): nil
	if not anim_track then
		return
	end

	anim_track:AdjustSpeed(anim_speed)

	return
end

function AnimationObject:GetMarkerReachedSignal(anim_name: string, mark_name: string, func: () -> ())
	local animation: AnimationTrack = self:GetAnimation(anim_name, nil, self._anim_folder)
	if animation then
		return animation:GetMarkerReachedSignal(mark_name):Connect(func)
	end
	return nil
end

function AnimationObject:SetPriority(anim_name: string, priority: Enum.AnimationPriority, custom_folder: Folder?): nil
	local animation: AnimationTrack = self:GetAnimation(anim_name, nil, custom_folder)
	if animation then
		animation.Priority = priority
	end
	return
end

-- Immediatelty load in animations
function AnimationObject:load_anims(anim_arr: { [number]: Animation | string }): nil
	for _, anim in anim_arr do
		if typeof(anim) == "Instance" then
			TrackTable[(self._path .. anim.Name)] = self:CreateAnimation(anim)
		else
			if typeof(anim) == "table" then
				TrackTable[(self._path .. anim.Name)] = self:CreateAnimation(anim.Name)
			else
				TrackTable[(self._path .. anim)] = self:CreateAnimation(anim)
			end
		end
	end
	return
end

function AnimationObject:DoCleaning(): nil
	for _, anim in self._anim_list do
		anim:Stop(0)
	end
	self._maid:DoCleaning()
	self._anim_list = {}
	return
end

function AnimationObject:Destroy()
	self:DoCleaning()
	self._anim_list = {}
	self._maid = nil
	self = nil
	return
end

function AnimationHandler.Create(preload_anims: { [number]: Animation | string }, path: string): Types.AnimationObject
	local self = setmetatable({}, AnimationObject)

	self._anim_folder = Core.Animations
	self._path = "./"
	self._maid = Core.Utils.Maid.new()
	if path then
		self._path = path
		for _, i in string.split(path, "/") do
			if i == "." then
				continue
			end
			self._anim_folder = self._anim_folder[i]
		end
	end

	if preload_anims then
		self:load_anims(preload_anims)
	end

	self._anim_list = {}

	return self
end

function AnimationHandler.GetAnimationObjects(): nil
	for _, v: Animation in Core.Animations:GetChildren() do
		TrackTable[v.Name] = Maid.CoreAnimObject:CreateAnimation(v)
	end
	return
end

-- Load in tbe specified animation and set the default priority to Action
function AnimationHandler.LoadAnimation(animation_obj: Animation): AnimationTrack?
	if animation_obj then
		local loaded_anim: AnimationTrack = Core.Animator:LoadAnimation(animation_obj)
		loaded_anim.Priority = Enum.AnimationPriority.Action
		return loaded_anim
	end
	return
end

function AnimationHandler.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("Sprint", function(status: boolean): nil
		if status then
			Maid.CoreAnimObject:PlayAnimation("SprintAnim", nil, nil, Enum.AnimationPriority.Action)
		else
			Maid.CoreAnimObject:StopAnimation("SprintAnim")
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("Knockback", function(status: boolean): nil
		if status then
			Maid.CoreAnimObject:PlayAnimation("Knockback", nil, nil, Enum.AnimationPriority.Action4)
		else
			Maid.CoreAnimObject:StopAnimation("Knockback")
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("Jump", function(status: boolean): nil
		if status then
			Maid.CoreAnimObject:PlayAnimation("JumpUp", nil, nil, Enum.AnimationPriority.Action)
		else
			Maid.CoreAnimObject:PlayAnimation("LandingAnimation", nil, nil, Enum.AnimationPriority.Action)
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("Crouch", function(status: boolean): nil
		if status then
			Maid.CoreAnimObject:PlayAnimation("JumpUp", nil, nil, Enum.AnimationPriority.Action)
		else
			Maid.CoreAnimObject:PlayAnimation("LandingAnimation", nil, nil, Enum.AnimationPriority.Action)
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("DropInteraction", function(): nil
		Maid.CoreAnimObject:PlayAnimation("ItemPickup", nil, nil, Enum.AnimationPriority.Action)
		return
	end))

	Maid:GiveTask(Core.Subscribe("Stun", function(status: boolean)
		if status then
			Maid.CoreAnimObject:PlayAnimation("Stun", nil, nil, Enum.AnimationPriority.Action3)
		else
			Maid.CoreAnimObject:StopAnimation("Stun", nil, nil, Enum.AnimationPriority.Action3)
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("ThrowSuccess", function(anim: {}?)
		if anim then
			Maid.CoreAnimObject:PlayAnimation("Throw")
		else
			--Maid.CoreAnimObject:PlayAnimation("Throw")
		end
		return
	end))

	return
end

function AnimationHandler.Start(): nil
	Maid.CoreAnimObject = AnimationHandler.Create(Core.Animations:WaitForChild("PreloadAnims"):GetChildren())
	AnimationHandler.EventHandler()

	return
end

function AnimationHandler.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()

	DynamicFolder = Instance.new("Folder")
	DynamicFolder.Name = "DynamicLoading"
	DynamicFolder.Parent = Core.Animations
	return
end

function AnimationHandler.Reset(): nil
	Maid:DoCleaning()
	return
end

return AnimationHandler
