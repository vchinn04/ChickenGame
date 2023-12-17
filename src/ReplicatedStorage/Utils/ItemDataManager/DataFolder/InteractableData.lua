local InteractableData = {
	Nest = {
		Name = "Nest",
		Class = "Nest",
		RequiredEvent = "Basket",

		PromptData = {
			Duration = 0.15,
			ObjectText = "Nest",
			ActionText = "Add the eggs to your nest!",
		},

		-- SoundPath = "./Tree",
		-- SoundData = {
		-- 	Server = {
		-- 		Success = {
		-- 			Name = "Fall",
		-- 		},
		-- 	},

		-- 	Client = {},
		-- },
		-- ItemDrop = "Log",
		-- DropAmount = "random",
		-- DropChances = { 1, 3 },
	},

	-- Tree = {
	-- 	Name = "Tree",
	-- 	Class = "Resource",
	-- 	RequiredEvent = "Tree",
	-- 	RespawnDuration = 5,
	-- 	PromptData = {
	-- 		Duration = 7,
	-- 		ObjectText = "Pine Tree",
	-- 		ActionText = "Chop Down Tree",
	-- 	},

	-- 	SoundPath = "./Tree",
	-- 	SoundData = {
	-- 		Server = {
	-- 			Success = {
	-- 				Name = "Fall",
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- 	ItemDrop = "Log",
	-- 	DropAmount = "random",
	-- 	DropChances = { 1, 3 },
	-- },

	-- ["Copper Ore"] = {
	-- 	Name = "Copper Ore",
	-- 	Class = "Resource",
	-- 	RequiredEvent = "Ore",
	-- 	RespawnDuration = 5,
	-- 	PromptData = {
	-- 		Duration = 7,
	-- 		ObjectText = "Copper Ore",
	-- 		ActionText = "Mine Copper Ore",
	-- 	},

	-- 	TriggerEvent = "MiningTrigger",

	-- 	SoundPath = "./Ore",
	-- 	SoundData = {
	-- 		Server = {
	-- 			Success = {
	-- 				Name = "Mined",
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- 	ItemDrop = "Copper Ore",
	-- 	DropAmount = "random",
	-- 	DropChances = { 1, 3 },
	-- },

	-- Revivable = {
	-- 	Name = "Revivable",
	-- 	Class = "Revivable",
	-- 	RequiredEvent = "Bandage",
	-- 	ItemId = "Bandage",
	-- 	PromptData = {
	-- 		KeyCode = Enum.KeyCode.E,
	-- 		Duration = 7,
	-- 		ObjectText = "Pine Tree",
	-- 		ActionText = "Chop Down Tree",
	-- 	},

	-- 	SoundPath = "./Tree",
	-- 	SoundData = {
	-- 		Server = {
	-- 			Success = {
	-- 				Name = "Fall",
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- },

	-- Healable = {
	-- 	Name = "Healable",
	-- 	Class = "Healable",
	-- 	RequiredEvent = "Bandage",
	-- 	ItemId = "Bandage",
	-- 	PromptData = {
	-- 		KeyCode = Enum.KeyCode.X,
	-- 		Duration = 7,
	-- 		ObjectText = "Pine Tree",
	-- 		ActionText = "Chop Down Tree",
	-- 	},

	-- 	SoundPath = "./Tree",
	-- 	SoundData = {
	-- 		Server = {
	-- 			Success = {
	-- 				Name = "Fall",
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},
	-- },

	-- Drop = {
	-- 	Name = "Drop",
	-- 	Class = "Drop",
	-- 	PromptData = {
	-- 		Duration = 0.25,
	-- 	},
	-- },

	-- Lootable = {
	-- 	Name = "Lootable",
	-- 	Class = "Lootable",
	-- 	UI = "LootingUI/Looting",
	-- 	IgnoreSelf = true,
	-- 	PromptData = {
	-- 		KeyCode = Enum.KeyCode.F,
	-- 		Duration = 3,
	-- 		ActionPrefix = "Loot ",
	-- 	},
	-- },

	-- GeneralStore = {
	-- 	Name = "GeneralStore",
	-- 	Class = "UIInteractable",
	-- 	UI = "GeneralStoreUI/GeneralStore",
	-- 	UIProps = "WaltersGeneralStore",
	-- 	PromptData = {
	-- 		ObjectText = "General Store",
	-- 		Duration = 0,
	-- 	},
	-- },

	-- Bank = {
	-- 	Name = "Bank",
	-- 	Class = "UIInteractable",
	-- 	UI = "BankUI/Bank",
	-- 	PromptData = {
	-- 		ObjectText = "Bank",
	-- 		Duration = 0,
	-- 	},
	-- },
}

return InteractableData
