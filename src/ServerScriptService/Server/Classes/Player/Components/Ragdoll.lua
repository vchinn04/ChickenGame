local Ragdoll = {}
Ragdoll.__index = Ragdoll

--[[
	<description>
		This manager is responsible for converting a character to a ragdoll.
	</description> 
	
	<API>
		RagdollObject:InsertSockets() ---> nil 
		-- Insert BallSockets where joints are and disable joints 

		RagdollObject:CreateAttachments() ---> nil
		-- Create neccessary attachment for ball sockets

		RagdollObject:SetupCollisions() ---> nil
		-- Create no collision constraints between specified parts 
		to create smoother ragdoll

		RagdollObject:Restore() ---> nil
		-- Restore Character back to normal 

		RagdollObject:Ragdoll(direction: Vector3) ---> nil
		-- Ragdoll Character  
		direction -- Direction on which to apply impulse on HRP when ragdolled 

		RagdollObject:Destroy() ---> nil
		-- Destroy ragdoll object and cleanup. Will call Restore()

		Ragdoll.new(player: Player, character: Model) ---> RagdollObject
		-- return a new RagdollObject
		player : Player -- player associated with ragdoll 
		character : Model -- character being ragdolled 
	</API>
	
	<Authors>
		Quenty
        Modified By: 
            RoGuruu (770772041) 
	</Authors>
--]]

local V3_UP = Vector3.new(0, 1, 0)
local V3_DOWN = Vector3.new(0, -1, 0)
local V3_RIGHT = Vector3.new(1, 0, 0)
local V3_LEFT = Vector3.new(-1, 0, 0)

local R6_ADDITIONAL_ATTACHMENTS = {
	{ "Head", "NeckAttachment", CFrame.new(0, -0.5, 0) },
	{ "Torso", "NeckAttachment", CFrame.new(0, 1, 0) },

	{ "Torso", "RightShoulderRagdollAttachment", CFrame.fromMatrix(Vector3.new(1, 0.5, 0), V3_RIGHT, V3_UP) },
	{ "Right Arm", "RightShoulderRagdollAttachment", CFrame.fromMatrix(Vector3.new(-0.5, 0.5, 0), V3_DOWN, V3_RIGHT) },

	{ "Torso", "LeftShoulderRagdollAttachment", CFrame.fromMatrix(Vector3.new(-1, 0.5, 0), V3_LEFT, V3_UP) },
	{ "Left Arm", "LeftShoulderRagdollAttachment", CFrame.fromMatrix(Vector3.new(0.5, 0.5, 0), V3_DOWN, V3_LEFT) },

	{ "Torso", "RightHipAttachment", CFrame.new(0.5, -1, 0) },
	{ "Right Leg", "RightHipAttachment", CFrame.new(0, 1, 0) },

	{ "Torso", "LeftHipAttachment", CFrame.new(-0.5, -1, 0) },
	{ "Left Leg", "LeftHipAttachment", CFrame.new(0, 1, 0) },
}

local NO_COLLISION = {
	{ "Left Leg", "Right Leg" },
	{ "Head", "Right Arm" },
	{ "Head", "Left Arm" },

	{ "HumanoidRootPart", "Head" },
	{ "HumanoidRootPart", "Right Leg" },
	{ "HumanoidRootPart", "Right Arm" },
	{ "HumanoidRootPart", "Left Leg" },
	{ "HumanoidRootPart", "Left Arm" },
}

local R6_HEAD_LIMITS = {
	UpperAngle = 30,
	TwistLowerAngle = -40,
	TwistUpperAngle = 40,
	FrictionTorque = 0.5,
}

local R6_SHOULDER_LIMITS = {
	UpperAngle = 110,
	TwistLowerAngle = -85,
	TwistUpperAngle = 85,
	FrictionTorque = 0.5,
}

local R6_HIP_LIMITS = {
	UpperAngle = 40,
	TwistLowerAngle = -5,
	TwistUpperAngle = 80,
	FrictionTorque = 0.5,
}

local R6_RAGDOLL_RIG = {
	{
		part0Name = "Torso",
		part1Name = "Head",
		attachmentName = "NeckAttachment",
		motorParentName = "Torso",
		motorName = "Neck",
		limits = R6_HEAD_LIMITS,
	},
	{
		part0Name = "Torso",
		part1Name = "Left Leg",
		attachmentName = "LeftHipAttachment",
		motorParentName = "Torso",
		motorName = "Left Hip",
		limits = R6_HIP_LIMITS,
	},
	{
		part0Name = "Torso",
		part1Name = "Right Leg",
		attachmentName = "RightHipAttachment",
		motorParentName = "Torso",
		motorName = "Right Hip",
		limits = R6_HIP_LIMITS,
	},
	{
		part0Name = "Torso",
		part1Name = "Left Arm",
		attachmentName = "LeftShoulderRagdollAttachment",
		motorParentName = "Torso",
		motorName = "Left Shoulder",
		limits = R6_SHOULDER_LIMITS,
	},
	{
		part0Name = "Torso",
		part1Name = "Right Arm",
		attachmentName = "RightShoulderRagdollAttachment",
		motorParentName = "Torso",
		motorName = "Right Shoulder",
		limits = R6_SHOULDER_LIMITS,
	},
}

function Ragdoll:InsertSockets(): nil
	for _, socket_info in pairs(R6_RAGDOLL_RIG) do
		local ballSocket: BallSocketConstraint = Instance.new("BallSocketConstraint")
		local part0: Instance = self._character:WaitForChild(socket_info.part0Name, 3)
		local part1: Instance = self._character:WaitForChild(socket_info.part1Name, 3)
		local attachment0: Attachment = part0:WaitForChild(socket_info.attachmentName, 3)
		local attachment1: Attachment = part1:WaitForChild(socket_info.attachmentName, 3)
		local motor_parent: Instance = self._character:FindFirstChild(socket_info.motorParentName)
		local motor: Motor6D = motor_parent:FindFirstChild(socket_info.motorName)

		ballSocket.Name = "RagdollBallSocket"
		ballSocket.Enabled = true
		ballSocket.LimitsEnabled = true
		ballSocket.UpperAngle = socket_info.limits.UpperAngle
		ballSocket.TwistLimitsEnabled = true
		ballSocket.TwistLowerAngle = socket_info.limits.TwistLowerAngle
		ballSocket.TwistUpperAngle = socket_info.limits.TwistUpperAngle
		ballSocket.Attachment0 = attachment0
		ballSocket.Attachment1 = attachment1
		ballSocket.Parent = part1

		motor.Enabled = false
		table.insert(self._motors, motor)
	end
	return
end

function Ragdoll:CreateAttachments(): nil
	for _, attachment_info in pairs(R6_ADDITIONAL_ATTACHMENTS) do
		local parent_name: string, attachment_name: string, cframe: CFrame = unpack(attachment_info)
		local parent: Instance? = self._character:WaitForChild(parent_name, 3)

		if not parent then
			continue
		end

		local attachment: Attachment = Instance.new("Attachment")
		attachment.Name = attachment_name
		attachment.CFrame = cframe
		attachment.Parent = parent

		self._maid:GiveTask(attachment)
	end
	return
end

function Ragdoll:SetupCollisions(): nil
	for _, part_name in pairs(NO_COLLISION) do
		local no_collide: NoCollisionConstraint = Instance.new("NoCollisionConstraint")
		local part0: Instance = self._character:WaitForChild(part_name[1], 3)
		local part1: Instance = self._character:WaitForChild(part_name[2], 3)

		if not part0 or not part1 then
			continue
		end

		no_collide.Name = "RagdollNoCollisionConstraint"
		no_collide.Part0 = part0
		no_collide.Part1 = part1
		no_collide.Parent = part1

		self._maid:GiveTask(no_collide)
	end
	return
end

function Ragdoll:Restore(): nil
	self._maid:DoCleaning()
	local humanoid: Humanoid? = self._character:FindFirstChild("Humanoid")

	for _, motor in self._motors do
		motor.Enabled = true
	end

	self._motors = {}

	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	return
end

function Ragdoll:Ragdoll(body_part_name: string, direction: Vector3): nil
	-- local humanoid: Humanoid? = self._character:FindFirstChild("Humanoid")

	-- if humanoid then
	-- 	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	-- end
	local humanoid_root_part: BasePart? = self._character:FindFirstChild("HumanoidRootPart")
	if humanoid_root_part then
		humanoid_root_part.Massless = true
	end

	self:CreateAttachments()
	self:InsertSockets()
	self:SetupCollisions()

	for _, part in self._character:GetDescendants() do
		if part:IsA("BasePart") then
			part:SetNetworkOwner(self._player)
		end
	end

	self.Core.Utils.Net:RemoteEvent("ApplyImpulse"):FireClient(self._player, body_part_name, direction)
	return
end

function Ragdoll:Destroy(): nil
	-- self:Restore()
	self._maid:DoCleaning()

	self._player = nil
	self._character = nil
	self._maid = nil
	self = nil

	return
end

function Ragdoll.new(player: Player, character: Model): {}
	local self = setmetatable({}, Ragdoll)

	self.Core = _G.Core
	self._player = player
	self._character = character

	self._maid = self.Core.Utils.Maid.new()

	self._motors = {}

	return self
end

return Ragdoll
