local types = require(script.Parent.Parent.Parent.Parent.ServerTypes)

local BaseAccessory: types.BaseAccessory = {} :: types.BaseAccessory
BaseAccessory.__index = BaseAccessory
--[[
	<description>
		This class is responsible for handling the common accessory functionality.
	</description> 
	
	<API>
		BaseAccessoryObj:GetTool() ---> nil
			-- Return tool object

		BaseAccessoryObj:Destroy() ---> nil
			-- Cleanup and destroy BaseAccessoryObj

		BaseAccessory.new(player, tool_data) ---> BaseAccessoryObj
			-- Create a new BaseAccessoryObj and accessory object
			player: Player -- player who owns the object 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function BaseAccessory:GetTool(): Accessory?
	if not self._maid then
		return nil
	end

	return self._maid._tool_accessory
end

function BaseAccessory:Destroy(): nil
	self._maid:DoCleaning()
	self._maid = nil
	self._player_object = nil
	return
end

function BaseAccessory.new(player: Player, tool_data: types.ToolData): types.BaseAccessoryObject
	local self: types.BaseAccessoryObject = setmetatable({} :: types.BaseAccessoryObject, BaseAccessory)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	self._player_object = self.Core.DataManager.GetPlayerObject(player)
	self._id = tool_data.Id

	local tool_template: Instance? = self.Core.Items:FindFirstChild(tool_data.Id)
	if not tool_template then
		print("No accessory template found for id: ", self._id)
		return self
	end

	-- self._maid._tool = tool_template:Clone()
	self._maid._tool_accessory = self.Core.Utils.UtilityFunctions.ToAccessory(tool_template:Clone())

	-- self._maid._tool = nil

	self._player_object:AttachObject(self._maid._tool_accessory, self._id, true)

	return self
end

return BaseAccessory
