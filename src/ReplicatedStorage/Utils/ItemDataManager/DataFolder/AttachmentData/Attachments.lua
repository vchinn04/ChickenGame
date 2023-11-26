local ATTACHMENT_POINTS = {
	HumanoidRootPart = "RootAttachment",
	WaistCenter = "WaistCenterAttachment",
	TorsoBack = "BodyBackAttachment",
	TorsoFront = "BodyFrontAttachment",
	Head = "FaceCenterAttachment",
	LeftArm = "LeftShoulderAttachment",
	RightArm = "RightShoulderAttachment",
	LeftLeg = "LeftFootAttachment",
	RightLeg = "RightFootAttachment",
}

local Attachments = {

	["Sabre"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(-1, 0, 0),
		OffsetRotation = Vector3.new(0, 0, 0),
	},

	["Tomahawk"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(1, 0, 0),
		OffsetRotation = Vector3.new(-45, 0, 0),
	},

	["Axe"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(1, 0.35, -0.45),
		OffsetRotation = Vector3.new(-37, 0, 0),
	},

	["Bandage"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(0, 0, 1),
		OffsetRotation = Vector3.new(0, 0, 0),
	},

	["Lantern"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(0.5, 0, -0.5),
		OffsetRotation = Vector3.new(0, 90, 0),
	},

	["Pocket Watch"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.TorsoFront,
		OffsetPosition = Vector3.new(0.5, -0.15, 0.025),
		OffsetRotation = Vector3.new(0, 0, 0),
	},

	["Snowshoes"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.TorsoBack,
		OffsetPosition = Vector3.new(0, 0, 0),
		OffsetRotation = Vector3.new(0, 0, 0),
	},

	["Medium Knapsack"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.TorsoBack,
		OffsetPosition = Vector3.new(0, -0.25, 0.43),
		OffsetRotation = Vector3.new(0, 180, 0),
	},

	["Torch"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(1, 0.35, -0.45),
		OffsetRotation = Vector3.new(37, 0, 0),
	},

	["Spyglass"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(1, 0.35, -0.45),
		OffsetRotation = Vector3.new(37, 0, 0),
	},

	["Compass"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(-0.5, 0, 1.15),
		OffsetRotation = Vector3.new(90, 0, 0),
	},

	["Pickaxe"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(0, 0.45, 1),
		OffsetRotation = Vector3.new(45, 90, 0),
	},

	["CharlevilleMusket"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.TorsoBack,
		OffsetPosition = Vector3.new(0, 0, 1),
		OffsetRotation = Vector3.new(0, 0, 0),
	},

	["SharpePistol"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.WaistCenter,
		OffsetPosition = Vector3.new(0, 0.25, -1),
		OffsetRotation = Vector3.new(-45, -90, 0),
	},

	["Sword1"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.TorsoBack,
		OffsetPosition = Vector3.new(0, 0, 0),
		OffsetRotation = Vector3.new(0, 0, 45),
	},

	["Basket"] = {
		AccessoryType = Enum.AccessoryType.Back,
		AttachmentPoint = ATTACHMENT_POINTS.TorsoBack,
		OffsetPosition = Vector3.new(0, 0, 0),
		OffsetRotation = Vector3.new(0, 0, 45),
	},
}

return Attachments
