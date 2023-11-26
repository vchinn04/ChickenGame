local InteractPrompt = {}
InteractPrompt.__index = InteractPrompt
--[[
	<description>
		This component creates a ProximityPrompt for a speicfied name and a PromptAttach if it does not 
		already exist. The Prompt is positioned vertically based on object height, with a max height being 
		specified by MAX_HEIGHT. In order to give a hover effect, the prompt is moved up by an INCREASE_FACTOR 
		of its size (Note: this is limited by MAX_HEIGHT as well)
	</description> 
	
	<API>
		 InteractPrompt:SetPromptEnabled(status: boolean) ---> nil
			-- Set the prompt enabled property
			status : boolean --> enabled status

		InteractPrompt:GetPromptParent() ---> Instance
			-- Return the parent of the proximity prompt

		InteractPrompt.new(object, prompt_name, prompt_data, center_to_part: boolean?) ---> { [string]: any }
			-- Create an instance of InteractPrompt and set its Enabled property to the specified prompt_enabled or true
			object : Instance ---> Instance to which proximity prompt is added
			prompt_name : string ---> Name of the prompt being found 
			prompt_data : > { [string]: any } ---> Data for prompt. Entries include Duration: number, ObjectText: string, ActionText: string
			center_to_part: boolean ---> If set to true, the proximity prompt part will not be adjusted in terms of height and will be attached to center of object. The prompt's
				UIOffset will be set to the additional height * 4.5 (in order to account for studs to pixels) 

		InteractPrompt:Destroy() ---> nil
			-- Cleanup prompt object
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

local MAX_HEIGHT = 4.3
local INCREASE_FACTOR = 1.5 -- means 1/INCREASE_FACTOR

function InteractPrompt:SetPromptEnabled(status: boolean): nil
	self._prompt.Enabled = status
	return
end

function InteractPrompt:GetPromptParent(): Instance?
	return self._prompt_part
end

function InteractPrompt.new(object, prompt_name, prompt_data, center_to_part: boolean?, height_clamp: number?)
	local self = setmetatable({}, InteractPrompt)
	local prompt_part_exists = true
	self._instance = object
	self._prompt = Instance.new("ProximityPrompt")
	self._prompt.Enabled = true
	self._prompt_part = object:FindFirstChild("PromptAttach", true)

	if prompt_data then
		self._prompt.KeyboardKeyCode = if prompt_data.KeyCode then prompt_data.KeyCode else Enum.KeyCode.E
		self._prompt.HoldDuration = if prompt_data.Duration then prompt_data.Duration else 0
		self._prompt.ObjectText = if prompt_data.ObjectText then prompt_data.ObjectText else ""
		self._prompt.ActionText = if prompt_data.ActionText then prompt_data.ActionText else ""
	end

	local object_pos: Vector3 = if object:IsA("Model") then object:GetPivot().Position else object.Position
	local size = if object:IsA("Model") then object:GetExtentsSize() else object.Size

	local center_point = object:FindFirstChild("CenterPoint", true)
	if center_point then
		object_pos = Vector3.new(center_point.WorldPosition.X, object_pos.Y, center_point.WorldPosition.Z)
	end

	local height_addition = size.Y / INCREASE_FACTOR

	if height_clamp then
		height_addition = math.clamp(height_addition, 0, height_clamp)
	end

	local object_base = object_pos.Y - size.Y / 2

	if object_pos.Y > (object_base + MAX_HEIGHT) then
		height_addition = math.clamp(object_base + MAX_HEIGHT - object_pos.Y, -object_pos.Y, height_addition)
	end

	if not self._prompt_part then
		prompt_part_exists = false
		self._prompt_part = Instance.new("Part")
		self._prompt_part.Name = "PromptAttach"
		self._prompt_part.Parent = object
		self._prompt_part.CanCollide = false
		self._prompt_part.CanQuery = false
		self._prompt_part.CanTouch = false
		self._prompt_part.Size = Vector3.new(0.1, 0.1, 0.1)
		self._prompt_part.Transparency = 1
	end

	if center_to_part then
		if not prompt_part_exists or self._prompt_part.Anchored then
			self._prompt_part.Position = object_pos
		end
		local prompt_part_children = self._prompt_part:GetChildren()
		local pixel_addition = height_addition * 100
		local offset = pixel_addition + 100 * #prompt_part_children
		self._prompt.UIOffset = Vector2.new(0, offset)
	else
		if not prompt_part_exists or self._prompt_part.Anchored then
			self._prompt_part.Position = object_pos + Vector3.new(0, height_addition, 0)
		end
	end

	if not prompt_part_exists then
		if object:IsA("Model") and object.PrimaryPart then
			local prompt_part_weld = Instance.new("WeldConstraint")
			prompt_part_weld.Part0 = object.PrimaryPart
			prompt_part_weld.Part1 = self._prompt_part
			prompt_part_weld.Parent = object.PrimaryPart
		else
			self._prompt_part.Anchored = true
		end
	end

	self._prompt.Parent = self._prompt_part
	self._prompt.Name = prompt_name
	self._prompt.RequiresLineOfSight = false

	return self
end

function InteractPrompt:Destroy(): nil
	if self._prompt then
		self._prompt:Destroy()
		self._prompt = nil
	end
	if self._prompt_part then
		self._prompt_part:Destroy()
		self._prompt_part = nil
	end
	self = nil
	return
end

return InteractPrompt
