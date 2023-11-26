local EffectManager = {
	Name = "EffectManager",
}
--[[
	<description>
		This manager is responsible for particle effects and other VFX
	</description> 
	
	<API>
		EffectObject:GetEffect(effect_name, parent, skip_attachment) --->  Instance | { [number]: Instance }?
			-- Gets effect attachment/table or creates it. Has to be effect at path location.
			effect_name: string ---> Name of effect 
            parent: Instance ---> Parent of effect
			skip_attachment: boolean? ---> If set to true, an effect table is created instead of attachment, resulting 
											in effects directly being parented to instance
										
		EffectObject:Emit(effect_name, effect_parent, emit_amount) ---> nil
			-- Find all ParticleEmitter descendants of object and callt their Emit function with number specified 
            effect_name: string ---> Name of effect
            effect_parent: Instance ---> Parent of effect
            emit_amount: number ---> Default emit amount

		EffectObject:CloneEffect(effect_name, effect_parent)
			-- Clone an effect and return it 
			effect_name: string -- name of effect 
			effect_parent: Instance -- Parent of cloned effect

		EffectObject:Destroy() ---> nil
			-- Destroy Effect object

		-----------------------------------------------

		EffectManager.Create(path: string) ---> {[string]: any}
			-- Create a EffectObject instance with the folder being at a specified path. 
			
		EffectManager.EventHandler() ---> nil
			-- Handle incoming events such as melee, movement, etc
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local Core
local Maid

--*************************************************************************************************--
local EffectObject = {}
EffectObject.__index = EffectObject

function EffectObject:GetEffect(effect_name: string, parent: Instance, skip_attachment: boolean?)
	if self._effects[parent.Name] and self._effects[parent.Name][effect_name] then
		return self._effects[parent.Name][effect_name]
	end

	local effect: Instance = self._folder:WaitForChild(effect_name, 5)
	if effect then
		local clone_effect = effect:Clone()

		if not skip_attachment then
			local attachment: Attachment = Instance.new("Attachment")
			attachment.Parent = parent

			for _, cloned_effect: Instance in clone_effect:GetChildren() do
				cloned_effect.Parent = attachment
			end

			if not self._effects[parent.Name] then
				self._effects[parent.Name] = {}
			end

			clone_effect:Destroy()

			self._effects[parent.Name][effect_name] = attachment
			return attachment
		else
			local clone_table: {} = clone_effect:GetChildren()

			for _, cloned_effect: Instance in clone_table do
				cloned_effect.Parent = parent
			end

			if not self._effects[parent.Name] then
				self._effects[parent.Name] = {}
			end

			clone_effect:Destroy()

			self._effects[parent.Name][effect_name] = clone_table
			return clone_table
		end
	end
	return
end

function EffectObject:Emit(effect_name: string, effect_parent: Instance, emit_amount: number, skip_attachment: boolean?)
	local effect_attachment: Instace | {} = self:GetEffect(effect_name, effect_parent, skip_attachment)

	if not effect_attachment then
		return
	end

	local effect_table: Instace | {} = effect_attachment

	if typeof(effect_attachment) == "Instance" then
		effect_table = effect_attachment:GetChildren()
	end

	for _, effect: Instance in effect_table do
		local custom_count: number? = effect:GetAttribute("EmitCount")
		local delay_amount: number? = effect:GetAttribute("EmitDelay")

		if not delay_amount then
			delay_amount = 0
		end

		if not custom_count then
			custom_count = emit_amount
		end

		Core.Utils.Promise.delay(delay_amount):andThen(function()
			effect:Emit(custom_count)
		end)
	end
end

function EffectObject:Enable(effect_name: string, effect_parent: Instance, status: boolean, skip_attachment: boolean?)
	local effect_attachment: Instace | {} = self:GetEffect(effect_name, effect_parent, skip_attachment)

	if not effect_attachment then
		return
	end

	local effect_table: Instace | {} = effect_attachment

	if typeof(effect_attachment) == "Instance" then
		effect_table = effect_attachment:GetChildren()
	end

	for _, effect: Instance in effect_table do
		effect.Enabled = status
	end
end

function EffectObject:CloneEffect(effect_name: string, effect_parent: Instance)
	local effect_attachment: Instace | {} = self:GetEffect(effect_name, effect_parent, true)
	return effect_attachment
end

function EffectObject:Destroy()
	for key: string, entry: {} in self._effects do -- Clear out effect table and destroy cloned effects
		for ckey: string, effect in entry do
			if typeof(effect) == "table" then
				for ekey: number, _ in effect do
					self._effects[key][ckey][ekey]:Destroy()
					self._effects[key][ckey][ekey] = nil
				end
			else
				self._effects[key][ckey]:Destroy()
			end
			self._effects[key][ckey] = nil
		end
		self._effects[key] = nil
	end

	self._effects = nil
	self = nil
end
--*************************************************************************************************--

function EffectManager.Emit(object: Instance?, emit_amount: number): nil
	if not object then
		return
	end

	for _, item: Instance in object:GetDescendants() do
		if item:IsA("ParticleEmitter") then
			item:Emit(emit_amount)
		end
	end

	return
end

function EffectManager.Create(path: string)
	local self = setmetatable({}, EffectObject)
	self._effects = {}
	self._folder = Core.EffectsFolder

	if path then
		for _, i in string.split(path, "/") do
			if i == "." then
				continue
			end
			self._folder = self._folder[i]
		end
	end

	return self
end

function EffectManager.EventHandler(): nil
	return
end

function EffectManager.Start(): nil
	EffectManager.EventHandler()
	return
end

function EffectManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	EffectTable = {}

	return
end

function EffectManager.Reset(): nil
	return
end

return EffectManager
