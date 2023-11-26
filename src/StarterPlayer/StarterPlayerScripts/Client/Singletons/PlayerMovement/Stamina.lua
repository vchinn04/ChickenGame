local Stamina = {}
Stamina.__index = Stamina
--[[
	<description>
		This manager is responsible for handling stamina related functionality.
	</description> 
	
	<API>		
		StaminaObject:DrainStamina() ---> nil
			-- Drain the stamina consistently until it reaches 0 or is cancelled. If 0 is reached, regeneration is called.

		StaminaObject:RegenerateStamina() ---> nil
			-- Regenerate the stamina consistently until it reaches the max or it begins to drain again.
			
		StaminaObject:RemoveStamina(remove_amount: amount) ---> nil
			-- Instantly remove a speciefied amount of stamina, with the bottom limit being 0.
			remove_amount: amount ---> Amount of stamina to remove.

		StaminaObject:AddStamina(add_amount: amount) ---> nil
			-- Instantly add a speciefied amount of stamina, with the cap being MAX_STAMINA
			add_amount: amount ---> Amount of stamina to add.

		StaminaObject:Clear() ---> nil
			-- Clear all connections and remove onself from the GlobalConnectionTable.

		StaminaObject:Destroy() ---> nil
			-- Destroy the stamina instance.
			
		Stamina.new()
			-- Create an return a Stamina instance.

		 Stamina.GetMaxStamina() ---> number
		 	-- Return MAX_STAMINA
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local RunService = game:GetService("RunService")

local MAX_STAMINA: number = 100
local DEPLETION_TIME: number = 7 -- Seconds
local REGENERATION_TIME: number = 5 -- Seconds

local DEPLETION_RATE: number = MAX_STAMINA / DEPLETION_TIME
local REGENERATION_RATE: number = MAX_STAMINA / REGENERATION_TIME

local Maid = nil
local Core = nil
local GlobalConnectionTable = {} -- Keep track if anyone is draining stamina

--*************************************************************************************************--

function Stamina:DrainStamina(): nil
	GlobalConnectionTable[self] = true
	Maid.RegenerationConnection = nil

	self._maid.StaminaConnection = RunService.Heartbeat:Connect(function(delta_time)
		local new_stamina: number = self.Core.ActionStateManager:getState().Stamina - DEPLETION_RATE * delta_time

		if new_stamina < 0 then
			self.Core.Fire("StaminaDrained")
			self.Core.Fire("Stamina", 0)
			self:RegenerateStamina() -- No more stamina, so start regenerating
		else
			self.Core.Fire("Stamina", new_stamina)
		end
	end)
	return
end

function Stamina:RegenerateStamina(): nil
	GlobalConnectionTable[self] = nil
	self._maid.StaminaConnection = nil

	if Core.ActionStateManager:getState().Stamina >= MAX_STAMINA then
		return
	end

	if Core.Length(GlobalConnectionTable) > 0 then
		return
	end

	Maid.RegenerationConnection = RunService.Heartbeat:Connect(function(delta_time)
		local new_stamina: number = Core.ActionStateManager:getState().Stamina + REGENERATION_RATE * delta_time

		if Core.ActionStateManager:getState().Stamina > MAX_STAMINA then
			Core.Fire("Stamina", MAX_STAMINA)
			Maid.RegenerationConnection = nil -- Stop regenirating
		else
			Core.Fire("Stamina", new_stamina)
		end
	end)

	--self._maid.RegenerationConnection = Maid.RegenerationConnection
	return
end

function Stamina:RemoveStamina(remove_amount: amount): nil
	local new_stamina: number = self.Core.ActionStateManager:getState().Stamina - remove_amount

	if new_stamina < 0 then
		self.Core.Fire("StaminaDrained")
		self.Core.Fire("Stamina", 0)
	else
		self.Core.Fire("Stamina", new_stamina)
	end

	self:RegenerateStamina()
end

function Stamina:AddStamina(add_amount: amount): nil
	local new_stamina = self.Core.ActionStateManager:getState().Stamina + add_amount

	if new_stamina > MAX_STAMINA then
		self.Core.Fire("Stamina", MAX_STAMINA)
	else
		self.Core.Fire("Stamina", new_stamina)
	end
	self:RegenerateStamina()
end

function Stamina:Clear(): nil
	GlobalConnectionTable[self] = nil
	self._maid:DoCleaning()
	self:RegenerateStamina()
	return
end

function Stamina:Destroy(): nil
	self._maid:DoCleaning()
	GlobalConnectionTable[self] = nil
	self:RegenerateStamina()
	self.Core = nil
	self._maid = nil
	return
end

function Stamina.new()
	local self = setmetatable({}, Stamina)
	self.Core = _G.Core

	if not Core then
		Core = _G.Core
	end

	self._maid = self.Core.Utils.Maid.new()
	if not Maid then
		Maid = self.Core.Utils.Maid.new()
	end
	return self
end

function Stamina.GetMaxStamina(): number
	return MAX_STAMINA
end

return Stamina
