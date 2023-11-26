local Bayonet = {}
Bayonet.__index = Bayonet
--[[
	<description>
		This component provides the bayonet (or any other attachable 
		melee attachment) functionality.
	</description> 
	
	<API>
		Bayonet:Attack() ---> nil
			-- Route to the Bayonet's melee component attack

		Bayonet:IsAttached() ---> boolean
			-- Return if bayonet is attached 

		Bayonet:Attach(status: boolean) ---> nil
			-- Attach bayonet if player has one or detach it. 
			status : boolean -- True to attach, False to detach 

		Bayonet:Equip() --> void
			-- Sets up connections needed

		Bayonet:Unequip() --> void
			-- Tares down connections such as input, etc

		Bayonet.new(tool_obj: Tool, tool_data: { [string]: any }, bayonet_path: string, Animator: {}) --> BayonetObj
			-- Creates a Bayonet given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
			bayonet_path : string -- Path to the bayonet object in the tool_obj
			Animator : {} -- Animator object passed from parent. (Note: Has to be deleted in parent)

		Bayonet:Destroy() --> void
			-- Tares down all connections and destroys components used 
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local MELEE_COMPONENT_PATH = "Tools/Melee"
local DAMAGE_ATTACHMENT_NAME = "BayonetDmg"

local DEFAULT_SWING_DURATION: number = 0.65

local BAYONET_ID = "StandardBayonet"
local ATTACH_REMOTE_EVENT = "BayonetAttach"
--*************************************************************************************************--

function Bayonet:Attack(): nil
	self._core_maid.MeleeManager:Attack()
	return
end

function Bayonet:IsAttached(): boolean
	if self._item_data_entry.BayonetAttached then
		return true
	end
	return false
end

function Bayonet:Attach(status: boolean): nil
	if status == nil then
		status = not self:IsAttached()
	end

	if status then
		if not self._bayonet_data_entry then
			self._bayonet_data_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. self._attachment_id)
		end

		if not self._bayonet_data_entry or self._bayonet_data_entry.Amount <= 0 then
			return
		end

		if self._item_data_entry.BayonetAttached then
			return
		end

		if self._tool_data.AnimationData.BayonetAttach then
			local anim: AnimationTrack = self.Animator:PlayAnimation(self._tool_data.AnimationData.BayonetAttach)
			self._connection_maid:GiveTask(anim.Stopped:Connect(function()
				self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(ATTACH_REMOTE_EVENT, true)
			end))
		else
			self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(ATTACH_REMOTE_EVENT, true)
		end
	else
		if not self._item_data_entry.BayonetAttached then
			return
		end

		if self._tool_data.AnimationData.BayonetDetach then
			local anim: AnimationTrack = self.Animator:PlayAnimation(self._tool_data.AnimationData.BayonetDetach)
			self._connection_maid:GiveTask(anim.Stopped:Connect(function()
				self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(ATTACH_REMOTE_EVENT, false)
			end))
		else
			self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(ATTACH_REMOTE_EVENT, false)
		end
	end
end

function Bayonet:Equip(): nil
	self._core_maid.MeleeManager:Start()
	return
end

function Bayonet:Unequip(): nil
	self._core_maid.MeleeManager:Stop()
	self._connection_maid:DoCleaning()

	if self._tool_data.AnimationData.BayonetAttach then
		self.Animator:StopAnimation(self._tool_data.AnimationData.BayonetAttach)
	end

	if self._tool_data.AnimationData.BayonetDetach then
		self.Animator:StopAnimation(self._tool_data.AnimationData.BayonetDetach)
	end

	return
end

function Bayonet.new(tool_obj: Tool, tool_data: { [string]: any }, bayonet_path: string, Animator: {}): SwordType
	local self = setmetatable({}, Bayonet)

	self.Core = _G.Core
	self._tool_data = tool_data
	self._tool = tool_obj

	self._attachment_id = BAYONET_ID
	if tool_data.MeleeAttachment then
		self._attachment_id = tool_data.MeleeAttachment
	end

	self._item_data_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. tool_data.Id)
	self._bayonet_data_entry = self.Core.ReplicaServiceManager.GetItem("Items/" .. self._attachment_id)

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()
	self.Animator = Animator

	self._bayonet_obj = self.Core.Utils.UtilityFunctions.FindObjectWithPath(tool_obj, bayonet_path)
	self._core_maid.MeleeManager = self.Core.Components[MELEE_COMPONENT_PATH].new(
		self._bayonet_obj,
		DEFAULT_SWING_DURATION,
		nil,
		DAMAGE_ATTACHMENT_NAME
	)

	return self
end

function Bayonet:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	self._connection_maid = nil
	self.Animator = nil
	self._core_maid = nil
	self._bayonet_obj = nil
	self = nil

	return
end

return Bayonet
