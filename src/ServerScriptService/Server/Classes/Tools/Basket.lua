local Basket = {
	Name = "Basket",
}
Basket.__index = Basket
--[[
	<description>
		This class is responsible for handling the standard Basket accessory functionality.
	</description> 
	
	<API>
		BasketObj:AddEgg(egg_id: string): string?
			-- Add an egg to player's basket
			egg_id: string -- The id of the egg type to add to basket

		BasketObj:PopEggs(amount: number): { string }
			-- Pop specified amount of eggs from player's basket and return list of id's popped. If
			amount specified greater than the amount of eggs in basket, all of the eggs in basket 
			are popped. 
			amount: number -- Number of eggs to pop

		BasketObj:ClearEggs(): nil
			-- Clear all of the eggs in player's basket

		BasketObj:GetEggs(): string?
			-- Return list/stack of egg id's in player's basket

		BasketObj:IsEmpty(): boolean?
			-- Return true if basket is empty and false if not 

		BasketObj:IsFull(): boolean?
			-- Return true if the basket if full else return false 

		BasketObj:GetToolObject() ---> Instance
			-- return the tool object 

		BasketObj:GetId() ---> string?
			-- return the tool id 

		BasketObj:Destroy() ---> nil
			-- Cleanup connections and objects of BasketObj

		Basket.new(player, player_object, tool_data) ---> BasketObj
			-- Create a new BasketObj
			player: Player -- player who owns the object 
			player_object: {} -- PlayerObject of player 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local types = require(script.Parent.Parent.Parent.ServerTypes)
local BASE_ACCESSORY: types.BaseAccessory = require(script.Parent.Components.BaseAccessory)

--*************************************************************************************************--

function Basket:AddEgg(egg_id: string): string?
	if #self._egg_stack < self._max_eggs then
		table.insert(self._egg_stack, egg_id)

		local object: Instance & (Part | MeshPart) = self.Core.Items:FindFirstChild(egg_id):Clone()
		if not object then
			return
		end

		object.CFrame = self._maid.BaseAccessory:GetTool().Handle["Egg" .. #self._egg_stack].WorldCFrame
			* CFrame.new(Vector3.new(0, object.Size.Y / 2, 0))
		object.Parent = self.Core.Utils.UtilityFunctions.GetTempsFolder(self._maid.BaseAccessory:GetTool())
		object.Name = "Egg" .. #self._egg_stack
		self.Core.Utils.UtilityFunctions.AttachObject(self._maid.BaseAccessory:GetTool().Handle, object)
		print("ADDING EGG TO BASKET!")
	end
	return
end

function Basket:PopEggs(amount: number): { string }
	print("Popping Eggs!")
	local egg_count: number = #self._egg_stack
	local remove_amount: number = math.min(amount, egg_count)
	local return_table: { string } = {}

	for i = #self._egg_stack, egg_count - remove_amount + 1, -1 do
		table.insert(return_table, #return_table, self._egg_stack[i])
		self._egg_stack[i] = nil
	end

	self.Core.Utils.UtilityFunctions.ClearTempFolder(self._maid.BaseAccessory:GetTool())
	return return_table
end

function Basket:ClearEggs(): nil
	print("Clearing Eggs!")
	self._egg_stack = nil
	self._egg_stack = {}
	self.Core.Utils.UtilityFunctions.ClearTempFolder(self._maid.BaseAccessory:GetTool())
	return
end

function Basket:GetEggs(): string?
	return self._egg_stack
end

function Basket:IsEmpty(): boolean?
	return #self._egg_stack < 1
end

function Basket:IsFull(): boolean?
	return #self._egg_stack >= self._max_eggs
end

function Basket:EventHandler(): nil
	return
end

function Basket:GetToolObject(): Instance
	return self._maid.BaseAccessory:GetTool()
end

function Basket:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Basket:Destroy(): nil
	self._maid:DoCleaning()

	self._maid = nil
	self._player = nil
	self._tool_data = nil
	self._player_object = nil
	self = nil

	return
end

function Basket.new(player: Player, player_object: types.PlayerObject, tool_data: types.ToolData): types.BasketObject
	local self: types.BasketObject = setmetatable({} :: types.BasketObject, Basket)

	self.Core = _G.Core

	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._max_eggs = 1
	self._egg_stack = {}

	self._maid.BaseAccessory = BASE_ACCESSORY.new(player, tool_data)

	if self._tool_data.EffectData then
		self._maid.EffectObject = self.Core.EffectManager.Create(tool_data.EffectPath)

		self._tool_effect_part = self.Core.Utils.UtilityFunctions.FindObjectWithPath(
			self._maid.BaseAccessory:GetTool(),
			tool_data.EffectPartPath
		)
	end

	if self._tool_data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)
	end

	self:EventHandler()

	return self
end

return Basket
