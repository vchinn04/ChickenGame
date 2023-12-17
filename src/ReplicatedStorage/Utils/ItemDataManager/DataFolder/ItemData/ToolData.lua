local ToolData = {

	-- ["Axe"] = {
	-- 	Name = "Axe",
	-- 	Category = "Tool",
	-- 	Class = "HarvestTool",
	-- 	Price = 10,
	-- 	Weight = 5,
	-- 	EquipEvents = { "Tree" },

	-- 	AnimationPath = "./Axe",
	-- 	AnimationHitmark = "LoopHit",
	-- 	AnimationData = {
	-- 		Equip = {
	-- 			Name = "Equip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Idle = {
	-- 			Name = "Idle",
	-- 			Priority = Enum.AnimationPriority.Idle,
	-- 		},

	-- 		Unequip = {
	-- 			Name = "Unequip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Trigger = {
	-- 			Name = "Swing",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},
	-- 	},

	-- 	EffectPath = "./Axe",
	-- 	EffectPartPath = "MeshPart",
	-- 	EffectData = {
	-- 		Server = {},

	-- 		Client = {
	-- 			Hit = {
	-- 				Name = "Hit",
	-- 				Rate = 5,
	-- 			},
	-- 		},
	-- 	},

	-- 	SoundPath = "./Axe",
	-- 	SoundData = {
	-- 		Server = {
	-- 			Hit = {
	-- 				Name = "Chop",
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- },

	-- ["Pickaxe"] = {
	-- 	Name = "Pickaxe",
	-- 	Category = "Tool",
	-- 	Class = "HarvestTool",
	-- 	Price = 15,
	-- 	Weight = 10,
	-- 	EquipEvents = { "Ore" },

	-- 	AnimationPath = "./Pickaxe",
	-- 	AnimationHitmark = "LoopHit",
	-- 	AnimationData = {
	-- 		Equip = {
	-- 			Name = "Equip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Idle = {
	-- 			Name = "Idle",
	-- 			Priority = Enum.AnimationPriority.Idle,
	-- 		},

	-- 		Unequip = {
	-- 			Name = "Unequip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Trigger = {
	-- 			Name = "Swing",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},
	-- 	},

	-- 	EffectPath = "./Pickaxe",
	-- 	EffectPartPath = "MeshPart",
	-- 	EffectData = {
	-- 		Server = {},

	-- 		Client = {
	-- 			Hit = {
	-- 				Name = "Hit",
	-- 				Rate = 5,
	-- 			},
	-- 		},
	-- 	},

	-- 	SoundPath = "./Pickaxe",
	-- 	SoundData = {
	-- 		Server = {
	-- 			Hit = {
	-- 				Name = "Mine",
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- },

	-- ["Torch"] = {
	-- 	Name = "Torch",
	-- 	Category = "Tool",
	-- 	Class = "Torch",
	-- 	Price = 15,
	-- 	Weight = 10,

	-- 	AnimationPath = "./Torch",

	-- 	AnimationData = {
	-- 		Equip = {
	-- 			Name = "Equip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Idle = {
	-- 			Name = "Idle",
	-- 			Priority = Enum.AnimationPriority.Idle,
	-- 		},

	-- 		Toggle = {
	-- 			Name = "Toggle",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},
	-- 	},

	-- 	EffectPath = "./Torch",
	-- 	EffectPartPath = "Wrap",
	-- 	AnimationHitmark = "Trigger",
	-- 	EffectData = {
	-- 		Server = {
	-- 			Toggle = {
	-- 				Name = "Toggle",
	-- 				IgnoreAttachment = true,
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- },

	-- ["Spyglass"] = {
	-- 	Name = "Spyglass",
	-- 	Category = "Tool",
	-- 	Class = "Spyglass",
	-- 	Price = 0,
	-- 	Weight = 20,

	-- 	AnimationPath = "./Spyglass",

	-- 	AnimationData = {
	-- 		Equip = {
	-- 			Name = "Equip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Idle = {
	-- 			Name = "Idle",
	-- 			Priority = Enum.AnimationPriority.Idle,
	-- 		},
	-- 	},
	-- },

	-- ["Compass"] = {
	-- 	Name = "Compass",
	-- 	Category = "Tool",
	-- 	Class = "Compass",
	-- 	Price = 0,
	-- 	Weight = 100,

	-- 	AnimationPath = "./Compass",

	-- 	AnimationData = {
	-- 		Equip = {
	-- 			Name = "Equip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Idle = {
	-- 			Name = "Idle",
	-- 			Priority = Enum.AnimationPriority.Idle,
	-- 		},
	-- 	},
	-- },

	-- ["Pocket Watch"] = {
	-- 	Name = "Pocket Watch",
	-- 	Category = "Accessory",
	-- 	Class = "PocketWatch",
	-- 	Price = 0,
	-- 	Weight = 10,
	-- },

	-- ["Snowshoes"] = {
	-- 	Name = "Snowshoes",
	-- 	Category = "Accessory",
	-- 	Class = "Snowshoes",
	-- 	Price = 0,
	-- 	Weight = 10,
	-- },

	-- ["Medium Knapsack"] = {
	-- 	Name = "Medium Knapsack",
	-- 	Category = "Accessory",
	-- 	Class = "Backpack",
	-- 	SpaceAddition = 50,
	-- 	Price = 0,
	-- 	Weight = 10,
	-- },

	-- ["Lantern"] = {
	-- 	Name = "Lantern",
	-- 	Category = "Accessory",
	-- 	Class = "Lantern",
	-- 	Price = 0,
	-- 	Weight = 10,

	-- 	AnimationPath = "./Lantern",

	-- 	AnimationData = {
	-- 		Toggle = {
	-- 			Name = "Toggle",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},
	-- 	},

	-- 	EffectPath = "./Lantern",
	-- 	EffectPartPath = "Wrap",
	-- 	-- AnimationHitmark = "Trigger",
	-- 	EffectData = {
	-- 		Server = {
	-- 			Toggle = {
	-- 				Name = "Toggle",
	-- 				IgnoreAttachment = true,
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},

	-- 	SoundPath = "./Lantern",
	-- 	SoundData = {
	-- 		Server = {
	-- 			ToggleOn = {
	-- 				Name = "ToggleOn",
	-- 			},
	-- 			ToggleOff = {
	-- 				Name = "ToggleOff",
	-- 			},
	-- 			Toggled = {
	-- 				Name = "Toggled",
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- },
	["Basket"] = {
		Name = "Basket",
		Category = "Tool",
		Class = "Basket",
		EquipEvents = { "Basket" },

		AnimationPath = "./Basket",

		AnimationData = {
			Equip = {
				Name = "Equip",
				Priority = Enum.AnimationPriority.Action,
			},

			Idle = {
				Name = "Idle",
				Priority = Enum.AnimationPriority.Idle,
			},
		},
	},
	-- ["Bandage"] = {
	-- 	Name = "Bandage",
	-- 	Category = "Tool",
	-- 	Class = "Bandage",
	-- 	Price = 15,
	-- 	Weight = 10,
	-- 	HealAmount = 25,
	-- 	EquipEvents = { "Bandage" },

	-- 	AnimationPath = "./Bandage",

	-- 	AnimationData = {
	-- 		Equip = {
	-- 			Name = "Equip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Idle = {
	-- 			Name = "Idle",
	-- 			Priority = Enum.AnimationPriority.Idle,
	-- 		},

	-- 		Toggle = {
	-- 			Name = "Toggle",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},
	-- 	},

	-- 	SoundPath = "./Bandage",
	-- 	SoundData = {
	-- 		Server = {
	-- 			Trigger = {
	-- 				Name = "Trigger",
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- },
	["Cannon"] = {
		Name = "Cannon",
		SpinSpeed = 725,
	},
}

return ToolData
