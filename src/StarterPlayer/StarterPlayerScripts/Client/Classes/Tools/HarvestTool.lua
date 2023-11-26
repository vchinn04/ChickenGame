local HarvestTool = {}
HarvestTool.__index = HarvestTool
--[[
	<description>
		This class provides the functionalities for HarvestTool, which is a tool without 
		functionalities, such as Axes and Pickaxes (aka "Dummy Tool"), it is pretty much an
		animation manager and event firer.
	</description> 
	
	<API>
		HarvestToolObj:GetId()
			-- Returns id of tool assigned to instance

		HarvestToolObj:MarkerEvent(): nil
			-- Fired every time specified marker in animation is hit and creates effects such as bark for chopping. 

		HarvestToolObj:Trigger(status: boolean) ---> nil
			-- Plays or stops trigger animation if it exists. 
			status: boolean -- true to play and false to stop 

		HarvestToolObj:Equip() --> void
			-- Sets up connections needed to use the tool and plays equip animation if provided 

		HarvestToolObj:Unequip() --> void
			-- Tares down connections such as input, etc
			
		HarvestToolObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		HarvestTool.new(tool_obj: Tool, tool_data: { [string]: any }) --> HarvestToolObj
			-- Creates a HarvestTool given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

export type HarvestToolType = {
	UserInput: () -> nil,
	Equip: () -> nil,
	Unequip: () -> nil,
	Destroy: () -> nil,
}

local BASE_TOOL_PATH = "Tools/BaseTool"

local HIT_REMOTE_EVENT: string = "ResourceHit"
local EFFECT_PART_NAME: string = "HitEffects"

local CAM_SHAKE_EVENT: string = "CameraShake"
local CAM_SHAKE_MAGNITUDE: number = 0.25
local CAM_SHAKE_ROUGHNESS: number = 5
local CAM_SHAKE_FADEIN_TIME: number = 0.2
local CAM_SHAKE_FADEOUT_TIME: number = 0.45

--*************************************************************************************************--

function HarvestTool:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function HarvestTool:MarkerEvent(): nil
	if self._tool_data.EffectData and self._tool_data.EffectData.Client.Hit and self._tool_effect_part then
		self._core_maid.EffectObject:Emit(
			self._tool_data.EffectData.Client.Hit.Name,
			self._tool_effect_part,
			self._tool_data.EffectData.Client.Hit.Rate
		)
	end

	if self._resource_effect_part then -- If there are particles in object to emit, such as snow in trees
		self.Core.Fire("Emit", self._resource_effect_part, 3)
	end

	self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(HIT_REMOTE_EVENT)
	self.Core.Fire(
		CAM_SHAKE_EVENT,
		CAM_SHAKE_MAGNITUDE,
		CAM_SHAKE_ROUGHNESS,
		CAM_SHAKE_FADEIN_TIME,
		CAM_SHAKE_FADEOUT_TIME
	)
	return
end

function HarvestTool:Trigger(status: boolean): nil
	if status then
		if self._tool_data.AnimationData.Trigger then
			self._core_maid.Animator:PlayAnimation(self._tool_data.AnimationData.Trigger)
		end
	else
		if self._tool_data.AnimationData.Trigger then
			self._core_maid.Animator:StopAnimation(self._tool_data.AnimationData.Trigger)
		end
	end
	return
end

function HarvestTool:Equip(): nil
	print("Client Equipping HarvestTool!")
	self._core_maid._base_tool:Equip()
	self._resource_instance = nil

	for _, event in self._tool_data.EquipEvents do
		self.Core.Fire(event, true)
	end

	if self._tool_data.AnimationHitmark then
		self._connection_maid:GiveTask(
			self._core_maid.Animator:GetMarkerReachedSignal(
				self._tool_data.AnimationData.Trigger,
				self._tool_data.AnimationHitmark,
				function()
					self:MarkerEvent()
				end
			)
		)
	end

	self._connection_maid:GiveTask(
		self.Core.Subscribe("ResourceTriggerTool", function(status: boolean, prompt_part: Instance)
			self:Trigger(status)
			if status then
				self._resource_instance = prompt_part.Parent
				self._resource_effect_part = self._resource_instance:FindFirstChild(EFFECT_PART_NAME)
			else
				self._resource_instance = nil
				self._resource_effect_part = nil
			end
		end)
	)

	return
end

function HarvestTool:Unequip(): nil
	print("Client Unequipping HarvestTool!")
	self._connection_maid:DoCleaning()
	self._core_maid._base_tool:Unequip()

	self:Trigger(false)

	self._resource_instance = nil
	self._resource_effect_part = nil

	for _, event in self._tool_data.EquipEvents do
		self.Core.Fire(event, false)
	end

	return
end

function HarvestTool:Destroy(): nil
	self:Trigger(false)

	for _, event in self._tool_data.EquipEvents do
		self.Core.Fire(event, false)
	end

	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	self._tool_data = nil
	self._connection_maid = nil
	self._tool = nil
	self._tool_effect_part = nil
	self._core_maid = nil
	self._resource_instance = nil
	self._resource_effect_part = nil
	self = nil

	return
end

function HarvestTool.new(tool_obj: Tool, tool_data: { [string]: any }): HarvestToolType
	local self = setmetatable({}, HarvestTool)
	self.Core = _G.Core

	self._tool_data = tool_data
	self._tool = tool_obj

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid.EffectObject = self.Core.EffectManager.Create(tool_data.EffectPath)
	self._tool_effect_part = self.Core.Utils.UtilityFunctions.FindObjectWithPath(tool_obj, tool_data.EffectPartPath)

	self._core_maid.Animator = self.Core.AnimationHandler.Create(tool_data.AnimationData, tool_data.AnimationPath)
	self._core_maid._base_tool = self.Core.Components[BASE_TOOL_PATH].new(tool_obj, tool_data, self._core_maid.Animator)

	return self
end

return HarvestTool
