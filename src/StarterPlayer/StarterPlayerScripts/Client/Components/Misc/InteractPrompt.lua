local InteractPrompt = {}
InteractPrompt.__index = InteractPrompt
--[[
	<description>
		This component fetches a specified proximity prompt from an instance, as well as its parent. 
		If it cannot find it, it will wait until that prompot is added. The wait is done through 
		a DescendantAdded event. 
	</description> 
	
	<API>
		InteractPrompt:SetPromptActionText(new_action: string) ---> nil
			-- Set the action text of the prompt. If the prompt did not load yet, cache it. Latest call will be used to set action text.
			new_action : string --> The new action text.

		InteractPrompt:SetPromptEnabled(status: boolean) ---> nil
			-- Set the prompt enabled property, if prompt is not yet found, it will be set to the latest enabled status when it is found
			status : boolean --> enabled status

		InteractPrompt:GetPromptParent() ---> Instance
			-- Return the part the proximity prompt is attached to. 

		InteractPrompt.new(object, prompt_name, prompt_enabled: boolean?) ---> { [string]: any }
			-- Create an instance of InteractPrompt and set its Enabled property to the specified prompt_enabled or true
			object : Instance ---> Instance to which proximity prompt is added
			prompt_name : string ---> Name of the prompt being found 
			prompt_enabled: boolean ---> Starting enabled value of prompt, could be overwritten by SetPromptEnabled, default is true
		
		InteractPrompt:Destroy() ---> nil 
			-- Destroy the intection prompt object.
			
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function InteractPrompt:SetPromptActionText(new_action: string): nil
	if self._prompt then
		self._prompt.ActionText = new_action
	end
	self._prompt_action = new_action
	return
end

function InteractPrompt:SetPromptEnabled(status: boolean): nil
	if self._prompt then
		self._prompt.Enabled = status
	end
	self._prompt_status = status
	return
end

function InteractPrompt:GetPromptParent(): Instance?
	return self._prompt_part
end

function InteractPrompt.new(object, prompt_name, prompt_enabled: boolean?): { [string]: any }
	local self = setmetatable({}, InteractPrompt)
	self._prompt_part = object:FindFirstChild("PromptAttach")
	self._prompt_status = if prompt_enabled ~= nil then prompt_enabled else true

	if self._prompt_part then
		self._prompt = self._prompt_part:FindFirstChild(prompt_name, true)
		if self._prompt then
			self._prompt.Enabled = self._prompt_status
		end
	end

	self.prompt_event = nil
	if not self._prompt or not self._prompt_part then
		print("Waiting for prompt instances for: " .. object.Name)

		self.prompt_event = object.DescendantAdded:Connect(function(item)
			if item:IsA("ProximityPrompt") and item.Name == prompt_name then
				self._prompt = item
				self._prompt.Enabled = self._prompt_status
				if self._prompt_action then
					self._prompt.ActionText = self._prompt_action
				end
			elseif item.Name == "PromptAttach" then
				self._prompt_part = item
			end

			if self._prompt_part and self._prompt then
				self.prompt_event:Disconnect()
				self.prompt_event = nil
				print("Received prompt instances for: " .. object.Name)
			end
		end)
	end

	return self
end

function InteractPrompt:Destroy(): nil
	if self.prompt_event then
		self.prompt_event:Disconnect()
		self.prompt_event = nil
	end
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
