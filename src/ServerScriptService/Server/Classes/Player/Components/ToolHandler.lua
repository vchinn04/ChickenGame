local ToolHandler = {}
ToolHandler.__index = ToolHandler
--[[
	<description>
		This component handles tool related functionalities for the player.
	</description> 
	
	<API>
		ToolHandlerObject:UnequipAll() ---> nil
			-- Unequip any equipped tools
	
		ToolHandlerObject:GetBasket(): types.BasketObject?
			-- Return an equipped tool if it is in Basket group (Basket Class)

		ToolHandlerObject:EquipTool(tool_name: string) ---> nil
			-- Equip the tool specified. Unequip previously equipped tool first. 
			tool_name : string -- Name of the tool being equipped
			
		ToolHandlerObject:UnequipTool(tool_name : string, tool_object : Tool) ---> nil
			-- Unequip the tool specified
			tool_name : string -- Name of the tool being unequipped

		ToolHandlerObject:AddTool(tool_name: string, tool_object : Tool) ---> nil
			-- Add a tool object and unequip any tool on top of the toolstack if there if the max number of added tools is surpassed.
			tool_name : string -- Name of the tool being added
			tool_object :  {[string] : any} -- Instance of class for specified tool
			
		ToolHandlerObject:RemoveTool(tool_name: string) ---> nil
			-- Remove a tool from player, destroy its resources.
			tool_name : string -- Name of the tool being removed
			
		ToolHandlerObject:ResetTools() ---> nil
			-- Destroy the players current tool objects and re initialize them
			also recount space.
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local types = require(script.Parent.Parent.Parent.Parent.ServerTypes)

--*************************************************************************************************--

function ToolHandler:UnequipAll(): nil
	if self._equipped_tool and self._equipped_tool.Unequip then
		self._equipped_tool:Unequip()
	end

	self._equipped_tool = nil

	return
end

function ToolHandler:GetBasket(): types.BasketObject?
	local basket_name: string? = self._equipped_tool_group_cache["Basket"]

	if not basket_name then
		return nil
	end

	return self._maid[basket_name]
end

function ToolHandler:EquipTool(tool_name: string): nil
	local humanoid: Humanoid? = self._player_object:GetHumanoid()

	if not humanoid then
		return
	end

	if self._equipped_tool and self._equipped_tool.Unequip then
		humanoid:UnequipTools()
		self._equipped_tool:Unequip()
	end

	self._equipped_tool = self._maid[tool_name]

	if self._equipped_tool and self._equipped_tool.Equip then
		local character: Model? = self._player_object:GetCharacter()
		local tool_obj: Tool = self._equipped_tool:GetToolObject()
		self.Core.Utils.UtilityFunctions.ClearTempFolder(tool_obj)
		humanoid:EquipTool(tool_obj)
		local tool: Instance = self._equipped_tool:Equip()

		if not character then
			return
		end

		local right_arm: Instance? = character:WaitForChild("Right Arm", 3)
		if not right_arm then
			return
		end

		local right_grip: Instance? = right_arm:WaitForChild("RightGrip", 3)
		if not right_grip or not right_grip:IsA("Motor6D") then
			return
		end

		local Motor: Motor6D = Instance.new("Motor6D")
		Motor.Parent = right_arm
		local grip: Motor6D = right_grip
		Motor.Enabled = false
		Motor.C0 = grip.C0
		Motor.C1 = grip.C1
		Motor.Part0 = grip.Part0
		Motor.Part1 = grip.Part1
		Motor.Name = grip.Name
		grip.Enabled = false
		Motor.Enabled = true

		grip:Destroy()
	end
	return
end

function ToolHandler:UnequipTool(tool_name: string): nil
	local humanoid: Humanoid? = self._player_object:GetHumanoid()

	if not humanoid then
		return
	end

	if self._equipped_tool and self._equipped_tool.IsEmpty then
		if not self._equipped_tool:IsEmpty() then
			print("BASKET NOT EMPTY!")
			return
		end
	end

	humanoid:UnequipTools()

	if self._equipped_tool and self._equipped_tool.Unequip then
		self._equipped_tool:Unequip()
	end

	self._equipped_tool = nil
	return
end

function ToolHandler:AddTool(tool_name: string, tool_class: { [string]: any }, tool_data: types.ToolData)
	if self._maid[tool_name] then
		self:RemoveTool(tool_name, true)
	end

	local equip_group = tool_data.EquipGroup
	if equip_group and self._equipped_tool_group_cache[equip_group] then
		self:RemoveTool(self._equipped_tool_group_cache[equip_group])
		self._equipped_tool_group_cache[equip_group] = nil
	end

	if #self._equip_stack >= self._MAX_EQUIP then
		self:RemoveTool(self._equip_stack[#self._equip_stack])
		self._equip_stack[#self._equip_stack] = nil
	end

	local tool_object = nil
	if tool_class then
		tool_object = tool_class.new(self._player, self._player_object, tool_data) -- Create a new instance of the tool
	end

	self._maid[tool_name] = tool_object

	table.insert(self._equip_stack, tool_name)

	if equip_group then
		self._equipped_tool_group_cache[equip_group] = tool_name
	end

	local item_id: string = self.Core.ItemDataManager.NameToId(tool_name)
	if item_id then
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. item_id .. "/Equipped", true)
	elseif tool_object then
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. tool_object:GetId() .. "/Equipped", true)
	end

	return tool_object
end

function ToolHandler:RemoveTool(tool_name: string, no_update: boolean?): nil
	if self._equipped_tool == self._maid[tool_name] then
		self._equipped_tool = nil
	end

	self._maid[tool_name] = nil

	for index: number, name: string in self._equip_stack do
		if name == tool_name then
			table.remove(self._equip_stack, index)
			break
		end
	end

	if no_update then
		return
	end

	local item_id: string = self.Core.ItemDataManager.NameToId(tool_name)
	if item_id then
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. item_id .. "/Equipped", false)
	elseif self._maid[tool_name] then
		self.Core.DataManager.UpdateItem(self._player, "Items/" .. self._maid[tool_name]:GetId() .. "/Equipped", false)
	end

	return
end

function ToolHandler:ResetTools(): nil
	self._maid:DoCleaning()
	self._equip_stack = {}
	self._equipped_tool_group_cache = {}
	return
end

function ToolHandler:Destroy(): nil
	self._maid:DoCleaning()

	self.Core = nil
	self._maid = nil

	self._player_object = nil
	self._player = nil

	self._MAX_EQUIP = nil
	self._equipped_tool = nil

	self._equip_stack = nil
	self._equipped_tool_group_cache = nil

	return
end

function ToolHandler.new(player_object: types.PlayerObject): types.ToolHandlerObject
	local self: types.ToolHandlerObject = setmetatable({} :: types.ToolHandlerObject, ToolHandler)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	self._player_object = player_object
	self._player = player_object:GetPlayer()

	self._MAX_EQUIP = 10
	self._equipped_tool = nil
	self._equip_stack = {}
	self._equipped_tool_group_cache = {}

	return self
end

return ToolHandler
