local types = require(script.Parent.Parent.Parent.Parent.ServerTypes)

local BaseTool: types.BaseTool = {} :: types.BaseTool
BaseTool.__index = BaseTool
--[[
	<description>
		This class is responsible for handling the common tool functionality, such as 
        as creating the tool clone and adding it to the player backpack.
	</description> 
	
	<API>
		BaseToolObj:GetTool() ---> nil
			-- Return tool object

		BaseToolObj:Destroy() ---> nil
			-- Cleanup and destroy BaseToolObj

		BaseTool.new(player, tool_data) ---> BaseToolObj
			-- Create a new BaseToolObj and tool object
			player: Player -- player who owns the object 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function BaseTool:GetTool(): Tool?
	if not self._maid then
		return
	end

	return self._maid._tool
end

function BaseTool:Equip(): nil
	self.Core.Utils.UtilityFunctions.MakeTransparent(self._maid._tool_accessory)
	return
end

function BaseTool:Unequip(): nil
	self.Core.Utils.UtilityFunctions.MakeVisible(self._maid._tool_accessory)
	return
end

function BaseTool:Destroy(): nil
	self._maid:DoCleaning()
	self._maid = nil
	self._player_object = nil
	return
end

function BaseTool.new(player: Player, tool_data: types.ToolData): types.BaseToolObject
	local self: types.BaseToolObject = setmetatable({} :: types.BaseToolObject, BaseTool)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	self._player_object = self.Core.DataManager.GetPlayerObject(player)
	self._id = tool_data.Id

	local tool_template: Instance? = self.Core.Items:FindFirstChild(tool_data.Id)
	if not tool_template then
		print("No tool template found for id: ", self._id)
		return self
	end

	self._maid._tool = tool_template:Clone()
	self._maid._tool_accessory = self.Core.Utils.UtilityFunctions.ToAccessory(tool_template:Clone())

	self._maid._tool.Name = tool_data.Name
	self._maid._tool.Parent = player.Backpack

	self._player_object:AttachObject(self._maid._tool_accessory, self._id, true)

	return self
end

return BaseTool
