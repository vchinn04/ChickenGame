local Melee = {}
Melee.__index = Melee
--[[
	<description>
		This component provides the functionalities for the basic 
		Melee weapon.
	</description> 
	
	<API>
		Melee.new(tool_obj, attack_duration) --> MeleeObj
			-- Creates a MeleeObj given the tool instance and attack duration. 
			tool_obj : Tool -- Tool instance player is equipping 
			attack_duration : number -- Duration of each attack
			
		MeleeObj:Attack(custom_duration: number?) --> void
			-- Start raycast hit detection
			custom_duration: number? -- Overwrite default hit detection duration 

		MeleeObj:Block(status: boolean) --> void
			-- Fire the Block remote event and play the blocking animations. If there is idle and action 
			block, first play action and idle as soon as action ends. 
			status : boolean -- True if blocking, False if unblocking

		MeleeObj:Start() --> void
			-- Connect the connections
			
		MeleeObj:Stop() --> void
			-- Terminate all connections
			
		MeleeObj:HitDetection() --> void
			-- Detect raycast hit and report it to server. Fire the "MeleeHit" local event.
			
		MeleeObj:Destroy() --> void
			-- Destroy the core objects and connections and destroy the instance.
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

export type MeleeType = {
	Attack: () -> nil,
	HitDetection: () -> nil,
	Start: () -> nil,
	Stop: () -> nil,
	Init: () -> nil,
	Destroy: () -> nil,
}

local DEFAULT_ATTACK_ACTION: string = "Attack"

local BLOCK_SERVER_EVENT: string = "Block"

--*************************************************************************************************--

--[[
	<description>
		Start raycast hit detection
	</description> 	
--]]
function Melee:Attack(custom_duration: number?): nil
	local attack_duration: number = self._attack_duration
	if custom_duration then
		attack_duration = custom_duration
	end

	if self._core_maid and self._core_maid.HitboxManager then
		self._core_maid.HitboxManager:HitStart(attack_duration)
	end
	return
end

function Melee:Block(status: boolean): nil
	self.Core.Utils.Net:RemoteEvent(`{self.Core.Player.UserId}_tool`):FireServer(BLOCK_SERVER_EVENT, status)

	if status then
		if self._tool_data.AnimationData.Block then
			local anim: AnimationTrack = self.Animator:PlayAnimation(self._tool_data.AnimationData.Block)

			if self._tool_data.AnimationData.BlockIdle then
				self._connection_maid.BlockIdle = anim.Stopped:Connect(function()
					self._connection_maid.BlockIdle = nil

					self.Animator:SetPriority(
						self._tool_data.AnimationData.BlockIdle.Name,
						Enum.AnimationPriority.Action4
					)

					self.Animator:PlayAnimation(self._tool_data.AnimationData.BlockIdle)
				end)
			end
		end
	else
		self._connection_maid.BlockIdle = nil

		self.Animator:StopAnimation(self._tool_data.AnimationData.Block)
		self.Animator:StopAnimation(self._tool_data.AnimationData.BlockIdle)
	end

	return
end

--[[
	<description>
		Connect to the hitbox OnHit event and notify server when a hit is detected. 
		Fire the MeleeHit client event to notify the rest of the Managers that there was 
		a hit registered (E.g. EffectManager, CameraManager, etc)
	</description> 	
--]]
function Melee:HitDetection(): nil
	if self._core_maid and self._core_maid.HitboxManager then
		self._connection_maid:GiveTask(
			self._core_maid.HitboxManager.OnHit:Connect(
				function(hit_part: Instance, hit_humanoid: Humanoid, raycast_results: { [string]: any }, _): nil
					if not hit_humanoid then
						if hit_part.CanCollide then
							self.Core.Fire("ObstacleHit", raycast_results)
							-- if raycast_results.Instance.Name ~= "Terrain" then
							-- 	self._core_maid.HitboxManager:HitStop()
							-- end
						end
						return
					end

					self.Core.Utils.Net
						:RemoteEvent(`{self.Core.Player.UserId}_tool`)
						:FireServer(self._attack_remote, { HitHumanoid = hit_humanoid, HitPart = hit_part })
					return
				end
			)
		)
	end
	return
end

--[[
	<description>
		Start the connections
	</description> 	
--]]
function Melee:Start(): nil
	-- self._connection_maid:GiveTask(
	-- 	self.Core.Utils.Net
	-- 		:RemoteEvent(`{self.Core.Player.UserId}_tool`).OnClientEvent
	-- 		:Connect(function(action: string, hit_part: Instance)
	-- 		end)
	-- )
	self:HitDetection()
	return
end

--[[
	<description>
		Disconnect all events in maid.
	</description> 	
--]]
function Melee:Stop(): nil
	if self._connection_maid then
		self._connection_maid:DoCleaning()
	end
	return
end

function Melee:Init(): nil
	return
end

--[[
	<description>
		Creates a MeleeObj given the tool instance and attack duration. 
	</description> 
	
	<parameter name="tool_obj">
		Type: Tool
		Tool instance player is equipping 
	</parameter 

	<parameter name="attack_duration">
		Type: number
 		Duration of each attack
 	</parameter 
	
	<Return>
		Melee Instance
	</Return>
--]]
function Melee.new(
	tool_obj: Tool,
	tool_data: {},
	attack_duration: number,
	Animator: {},
	attack_remote: string?,
	custom_attachment_name: string?
): MeleeType
	local self = setmetatable({}, Melee)

	self.Core = _G.Core
	self._tool = tool_obj
	self._tool_data = tool_data

	self._attack_duration = attack_duration
	self._attack_remote = DEFAULT_ATTACK_ACTION
	if attack_remote then
		self._attack_remote = attack_remote
	end

	self.Animator = Animator
	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._core_maid.HitboxManager =
		self.Core.Components.RaycastHitboxV4.new(tool_obj, self.Core.Character, custom_attachment_name)

	return self
end

--[[
	<description>
		Destroy instance of Melee. Clear the instances 
		and self.
	</description> 	
--]]
function Melee:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()

	self._core_maid = nil
	self._connection_maid = nil
	self._tool_data = nil
	self.Animator = nil
	self._tool = nil

	self = nil
	return
end

return Melee
