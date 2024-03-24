local EggHandler = {}
EggHandler.__index = EggHandler
--[[
	<description>
		This component handles egg related functionalities for the player.
	</description> 
	
	<API>
		EggHandlerObject:AddEgg(egg_id: string) ---> nil
			-- Add an egg to player's basket
			egg_id: string -- The id of the egg type to add to basket
	
		EggHandlerObject:GetEggs() ---> { string }
			-- Return list/stack of egg id's in player's basket

		EggHandlerObject:PopEggs(amount: number) ---> { string }?
			-- Pop specified amount of eggs from player's basket and return list of id's popped. If
			amount specified greater than the amount of eggs in basket, all of the eggs in basket 
			are popped. 
			amount: number -- Number of eggs to pop
			
		EggHandlerObject:StealEggs(amount: number) ---> { string }?
			-- Attempt to steal eggs from player. Only steals eggs if number of steal hits remaining is 0.
			amount: number -- Number of eggs attempt to stea;

		EggHandlerObject:ClearEggs() ---> nil
			-- Clear all of the eggs in player's basket
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local types = require(script.Parent.Parent.Parent.Parent.ServerTypes)

local EGG_STEAL_HITS: number = 3

--*************************************************************************************************--

function EggHandler:AddEgg(egg_id: string): nil
	print("ADDING EGG!")
	local basket_obj = self._player_object:GetBasket()

	if basket_obj and basket_obj.AddEgg then
		basket_obj:AddEgg(egg_id)
	end

	return
end

function EggHandler:GetEggs(): { string }
	print("GETTING EGG!")
	local basket_obj = self._player_object:GetBasket()

	local eggs = {}
	if basket_obj and basket_obj.GetEggs then
		eggs = basket_obj:GetEggs()
	end

	return eggs
end

function EggHandler:PopEggs(amount: number): { string }?
	print("POPPING EGG!")
	local basket_obj = self._player_object:GetBasket()

	local eggs = nil
	if basket_obj and basket_obj.PopEggs then
		eggs = basket_obj:PopEggs(amount)
	end
	return eggs
end

function EggHandler:StealEggs(amount: number): { string }?
	self._egg_steal_hits -= 1

	if self._egg_steal_hits <= 0 then
		self._egg_steal_hits = EGG_STEAL_HITS
		return self:PopEggs(amount)
	end

	return nil
end

function EggHandler:ClearEggs(): nil
	print("CLEARING EGG!")
	local basket_obj = self._player_object:GetBasket()

	if basket_obj and basket_obj.ClearEggs then
		basket_obj:ClearEggs()
	end

	return
end

function EggHandler:Destroy()
	self._maid:DoCleaning()
	self._maid = nil
	self._player_object = nil
end

function EggHandler.new(player_object: types.PlayerObject): types.EggHandlerObject
	local self: types.EggHandlerObject = setmetatable({} :: types.EggHandlerObject, EggHandler)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	self._player_object = player_object
	self._egg_steal_hits = EGG_STEAL_HITS

	return self
end

return EggHandler
