local EffectObject = {}
EffectObject.__index = EffectObject
--[[
	<description>
		This manager is responsible for particle effects and other VFX for specific path.
	</description> 
	
	<API>
		EffectObject:GetDecal(decal_name: string, parent: Instance): Instance | { [number]: Instance }
			-- Get the decal by passing in name and parent it where specified.
			decal_name : string ---> name of the decal to clone 
			parent : Instance ---> Instance to parent cloned decal to when it is first created.

		EffectObject:GetEffect(effect_name, parent) --->  Instance | { [number]: Instance }?
			-- Gets effect attachment/table or creates it. Has to be effect at path location.
			effect_name: string ---> Name of effect 
            parent: Instance ---> Parent of effect
		
		EffectObject:Emit(effect_name, effect_parent, emit_amount) ---> nil
			-- Find all ParticleEmitter descendants of object and callt their Emit function with number specified 
            effect_name: string ---> Name of effect
            effect_parent: Instance ---> Parent of effect
            emit_amount: number ---> Default emit amount

		EffectObject:EmitAndDestroyObject(effect_name: string, effect_parent: Instance, world_cframe: CFrame, effect_color: Color3?, emit_amount: number): nil
			-- Creates a NEW effect (no reuse) and emits it, destroys after the last effect completes. 
			effect_name : string ---> Effect to clone 
			effect_parent : Instance ---> Parent of new effect 
			world_cframe : CFrame ---> WorldCFrame of the attachment of effect 
			effect_color : Color3 ---> Color of the effect. Optional.
			emit_amount : number ---> amount to emit 

		EffectObject:AddDecal(effect_name, effect_parent, to_anchor) ---> nil
			-- Create ea decal and parent it to specified parent.
            effect_name: string ---> Name of effect
            effect_parent: Instance ---> Parent of effect
            to_anchor: boolean ---> true if decal is to be anchored, false/nil if it is to be welded.

		EffectObject:RemoveDecal(decal_name: string, decal_parent: Instance): nil
			-- Remove cached decal. Does NOT destroy it.
			decal_name : string ---> Name of decal.
			decal_parent : Instance ---> Parent of decal.

		EffectObject:TweenAndDestroyDecal(object: Instance, duration: number, decal_size: Vector3, max_transparency: number?) ---> Promise (A Promise containing all tweens.)
            -- Tween the decal obhect and return a promise for when tweens complete.
            object : Instance ---> object to tween
            duration : number ---> Duration of tween
            decal_size : Vector3 ---> Size to tween to
			max_transparency : number? ---> Transparency to tween to. Optional. 

		 EffectObject.new(path: string) 
			-- Create a EffectObject instance with the folder being at a specified path. 
			path: string ---> Path to effects folder. Starts at Resources/Effects

		 EffectObject:Destroy() ---> nil
			-- Destroy Effect object

	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local TweenService = game:GetService("TweenService")

--*************************************************************************************************--

function EffectObject:CloneEffect(effect_name: string, parent: Instance): Instance | { [number]: Instance }
	local effect: Instance? = self._folder:WaitForChild(effect_name, 5)

	if effect then
		local clone_effect: Instance = effect:Clone()
		local attachment: Attachment = Instance.new("Attachment")

		attachment.Parent = parent

		for _, v in clone_effect:GetChildren() do
			v.Parent = attachment
		end

		clone_effect:Destroy()
		return attachment
	end

	return
end

function EffectObject:GetEffect(effect_name: string, parent: Instance): Instance | { [number]: Instance }
	if self._effects[parent.Name] and self._effects[parent.Name][effect_name] then
		return self._effects[parent.Name][effect_name]
	end

	local effect_clone = self:CloneEffect(effect_name, parent)

	if not self._effects[parent.Name] then
		self._effects[parent.Name] = {}
	end

	self._effects[parent.Name][effect_name] = effect_clone

	return effect_clone
end

function EffectObject:GetDecal(
	decal_name: string,
	parent: Instance,
	one_time: boolean?
): Instance | { [number]: Instance }
	local table_decal_name = decal_name .. "Decal"

	if not one_time then
		if self._effects[parent.Name] and self._effects[parent.Name][table_decal_name] then
			return self._effects[parent.Name][table_decal_name]
		end
	end

	local decal: Instance? = self._folder:WaitForChild(decal_name, 5)

	if decal then
		local clone_decal: Instance = decal:Clone()

		clone_decal.Parent = parent

		if not self._effects[parent.Name] then
			self._effects[parent.Name] = {}
		end

		if not one_time then
			self._effects[parent.Name][table_decal_name] = clone_decal
		end
		return clone_decal
	end

	return
end

function EffectObject:Emit(effect_name: string, effect_parent: Instance, emit_amount: number): nil
	local effect_attachment: {}? | Instance? = self:GetEffect(effect_name, effect_parent)
	if not effect_attachment then
		return
	end
	for _, effect in effect_attachment:GetChildren() do
		effect:Emit(emit_amount)
	end

	return
end

function EffectObject:EmitAndDestroyObject(
	effect_name: string,
	effect_parent: Instance,
	world_cframe: CFrame,
	effect_color: Color3?,
	emit_amount: number
): nil
	local effect_attachment = self:CloneEffect(effect_name, effect_parent)
	effect_attachment.WorldCFrame = world_cframe
	local max_lifetime = 1

	for _, effect in effect_attachment:GetChildren() do
		if effect_color then
			effect.Color = ColorSequence.new(effect_color)
		end
		if max_lifetime < effect.Lifetime.Max then
			max_lifetime = effect.Lifetime.Max
		end
		effect:Emit(emit_amount)
	end

	self.Core.Utils.Promise.delay(max_lifetime):finally(function()
		effect_attachment:Destroy()
	end)

	return
end

function EffectObject:AddDecal(decal_name: string, decal_parent: Instance, to_anchor: boolean, one_time: boolean?): nil
	local decal_folder = self:GetDecal(decal_name, decal_parent, one_time)
	if decal_folder and to_anchor then
		for _, item in decal_folder:GetChildren() do
			if item:IsA("BasePart") then
				item.Anchored = true
			end
		end
	end
	return decal_folder
end

function EffectObject:RemoveDecal(decal_name: string, decal_parent: Instance): nil
	local table_decal_name = decal_name .. "Decal"
	if self._effects[decal_parent.Name] and self._effects[decal_parent.Name][table_decal_name] then
		self._effects[decal_parent.Name][table_decal_name] = nil
	end
	return
end

function EffectObject:TweenAndDestroyDecal(
	object: Instance,
	duration: number,
	decal_size: Vector3,
	max_transparency: number?
): {}
	local decal_stack: {} = {}

	if not max_transparency then
		max_transparency = 0
	end

	if object:IsA("BasePart") then
		table.insert(
			decal_stack,
			self.Core.Utils.Promise.new(function(resolve)
				local tween = TweenService:Create(object, TweenInfo.new(0.25), { Size = decal_size })
				tween.Completed:Connect(resolve)
				tween:Play()
			end)
		)
	end

	for _, decal in object:GetDescendants() do
		if decal:IsA("BasePart") then
			table.insert(
				decal_stack,
				self.Core.Utils.Promise.new(function(resolve)
					local tween = TweenService:Create(decal, TweenInfo.new(0.15), { Size = decal_size })
					tween.Completed:Connect(resolve)
					tween:Play()
				end)
			)
		else
			decal.Transparency = 1
			table.insert(
				decal_stack,
				self.Core.Utils.Promise
					.new(function(resolve)
						local tween =
							TweenService:Create(decal, TweenInfo.new(0.15), { Transparency = max_transparency })
						tween.Completed:Connect(resolve)
						tween:Play()
					end)
					:andThen(function()
						return self.Core.Utils.Promise.new(function(resolve)
							local tween = TweenService:Create(decal, TweenInfo.new(duration), { Transparency = 1 })
							tween.Completed:Connect(resolve)
							tween:Play()
						end)
					end)
			)
		end
	end

	local combined_promise = self.Core.Utils.Promise.all(decal_stack)

	return combined_promise
end

function EffectObject:TweenDecal(object: Instance, duration: number, decal_size: Vector3, max_transparency: number?): {}
	local decal_stack: {} = {}

	if not max_transparency then
		max_transparency = 0
	end

	if object:IsA("BasePart") then
		table.insert(
			decal_stack,
			self.Core.Utils.Promise.new(function(resolve)
				local tween = TweenService:Create(object, TweenInfo.new(duration), { Size = decal_size })
				tween.Completed:Connect(resolve)
				tween:Play()
			end)
		)
	end

	for _, decal in object:GetDescendants() do
		if decal:IsA("BasePart") then
			table.insert(
				decal_stack,
				self.Core.Utils.Promise.new(function(resolve)
					local tween = TweenService:Create(decal, TweenInfo.new(duration), { Size = decal_size })
					tween.Completed:Connect(resolve)
					tween:Play()
				end)
			)
		else
			decal.Transparency = 1
			table.insert(
				decal_stack,
				self.Core.Utils.Promise.new(function(resolve)
					local tween =
						TweenService:Create(decal, TweenInfo.new(duration), { Transparency = max_transparency })
					tween.Completed:Connect(resolve)
					tween:Play()
				end)
			)
		end
	end

	local combined_promise = self.Core.Utils.Promise.all(decal_stack)

	return combined_promise
end

function EffectObject.new(path: string): {}
	local self = setmetatable({}, EffectObject)
	self._effects = {}
	self.Core = _G.Core
	self._folder = self.Core.EffectsFolder

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

function EffectObject:Destroy(): nil
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
	return
end

return EffectObject
