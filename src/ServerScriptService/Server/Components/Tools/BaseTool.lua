local BaseTool = {}
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

function BaseTool:GetTool()
	if not self._maid then
		return
	end

	return self._maid._tool
end

function BaseTool:Equip()
	self.Core.Utils.UtilityFunctions.MakeTransparent(self._maid._tool_accessory)
end

function BaseTool:Unequip()
	self.Core.Utils.UtilityFunctions.MakeVisible(self._maid._tool_accessory)
end

function BaseTool:Destroy()
	self._maid:DoCleaning()
	self._maid = nil
	self._player_object = nil
	return
end

function BaseTool.new(player: Player, tool_data: {})
	local self = setmetatable({}, BaseTool)
	self.Core = _G.Core
	self._player_object = self.Core.DataManager.GetPlayerObject(player)
	self._id = tool_data.Id

	self._maid = self.Core.Utils.Maid.new()

	self._maid._tool = self.Core.Items:FindFirstChild(tool_data.Id):Clone()
	self._maid._tool_accessory = self.Core.Utils.UtilityFunctions.ToAccessory(self._maid._tool:Clone())

	self._maid._tool.Name = tool_data.Name
	self._maid._tool.Parent = player.Backpack

	self._player_object:AttachObject(self._maid._tool_accessory, self._id, true)

	return self
end

return BaseTool
