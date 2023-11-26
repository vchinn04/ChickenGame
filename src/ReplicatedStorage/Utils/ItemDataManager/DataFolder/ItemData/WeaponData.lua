local WeaponData = {

	-- ["Sabre"] = {
	-- 	Name = "Sabre",
	-- 	Category = "Melee",
	-- 	Class = "StandardMelee",
	-- 	Price = 11,
	-- 	Weight = 10,

	-- 	AttackRange = 3,
	-- 	Damage = 20,
	-- 	Defense = 20,
	-- 	StandardStamina = 10,
	-- 	SwingDebounce = 0.61,
	-- 	StandardAttacks = { "Hit1", "Hit2", "Hit3" },

	-- 	AnimationPath = "./Sabre",
	-- 	AnimationData = {
	-- 		Block = {
	-- 			Name = "Block",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		BlockIdle = {
	-- 			Name = "BlockIdle",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Parry = {
	-- 			Name = "Parry",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

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

	-- 		Hit1 = {
	-- 			Name = "Hit1",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},

	-- 		Hit2 = {
	-- 			Name = "Hit2",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},

	-- 		Hit3 = {
	-- 			Name = "Hit3",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},
	-- 	},

	-- 	EffectPath = "./Sabre",
	-- 	EffectPartPath = "Handle",
	-- 	EffectData = {
	-- 		Server = {
	-- 			Block = {
	-- 				Name = "Block",
	-- 				Rate = 55,
	-- 			},

	-- 			Parry = {
	-- 				Name = "Parry",
	-- 				Rate = 65,
	-- 				IgnoreAttachment = true,
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},

	-- 	SoundPath = "./Sabre",
	-- 	SoundData = {
	-- 		Server = {
	-- 			DefaultAttack = {
	-- 				Name = "Hit",
	-- 			},

	-- 			Block = {
	-- 				Name = "Block",
	-- 			},

	-- 			Parry = {
	-- 				Name = "Parry",
	-- 			},
	-- 		},

	-- 		Client = {
	-- 			Swing = {
	-- 				Name = "Swing",
	-- 			},
	-- 		},
	-- 	},
	-- },

	-- ["Tomahawk"] = {
	-- 	Name = "Tomahawk",
	-- 	Category = "Melee",
	-- 	Class = "ThrowableMelee",
	-- 	Price = 11,
	-- 	Weight = 10,

	-- 	AttackRange = 3,
	-- 	Damage = 50,
	-- 	Defense = 20,

	-- 	SpinSpeed = 745,
	-- 	ChargeDuration = 0.5,
	-- 	StabilityDuration = 3,
	-- 	MaxVelocity = 125,

	-- 	StandardAttacks = { "Hit1", "Hit2", "Hit3" },

	-- 	AnimationPath = "./Tomahawk",
	-- 	AnimationData = {
	-- 		Block = {
	-- 			Name = "Block",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Throw = {
	-- 			Name = "Throw",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		BlockIdle = {
	-- 			Name = "BlockIdle",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

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

	-- 		Hit1 = {
	-- 			Name = "Hit1",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},

	-- 		Hit2 = {
	-- 			Name = "Hit2",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},

	-- 		Hit3 = {
	-- 			Name = "Hit3",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},
	-- 	},
	-- 	EffectPath = "./Sabre",
	-- 	EffectPartPath = "Handle",
	-- 	EffectData = {
	-- 		Server = {
	-- 			Block = {
	-- 				Name = "Block",
	-- 				Rate = 55,
	-- 			},

	-- 			Parry = {
	-- 				Name = "Parry",
	-- 				Rate = 65,
	-- 				IgnoreAttachment = true,
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},

	-- 	SoundPath = "./Sabre",
	-- 	SoundData = {
	-- 		Server = {
	-- 			DefaultAttack = {
	-- 				Name = "Hit",
	-- 			},

	-- 			Block = {
	-- 				Name = "Block",
	-- 			},

	-- 			Parry = {
	-- 				Name = "Parry",
	-- 			},
	-- 		},

	-- 		Client = {
	-- 			Swing = {
	-- 				Name = "Swing",
	-- 			},
	-- 		},
	-- 	},
	-- },

	-- ["CharlevilleMusket"] = {
	-- 	Name = "Charleville Musket",
	-- 	Category = "Primary",
	-- 	Class = "StandardMusket",
	-- 	Price = 11,
	-- 	Weight = 10,

	-- 	MaxBullets = 1,
	-- 	ProjectileAmount = 1,
	-- 	ProjectileVelocity = 950,
	-- 	DefaultDamage = 100,
	-- 	HeadshotMultiplier = 1.75,
	-- 	MaxBulletSpread = 0,
	-- 	AttackRange = 3,
	-- 	Damage = 50,
	-- 	Defense = 20,

	-- 	StandardAttacks = {
	-- 		{ Name = "Hit1" },
	-- 		{ Name = "Hit2" },
	-- 		{ Name = "Hit3" },
	-- 	},

	-- 	BayonetAttacks = {
	-- 		{ Name = "Hit1", Stamina = 10 },
	-- 		{ Name = "Hit2", Stamina = 10 },
	-- 	},

	-- 	AnimationPath = "./Musket",
	-- 	AnimationData = {
	-- 		Reload = {
	-- 			Name = "Reload",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Block = {
	-- 			Name = "Block",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		BlockIdle = {
	-- 			Name = "BlockIdle",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

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

	-- 		Hit1 = {
	-- 			Name = "Hit1",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},

	-- 		Hit2 = {
	-- 			Name = "Hit2",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},

	-- 		Hit3 = {
	-- 			Name = "Hit3",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},

	-- 		ShoulderArms = {
	-- 			Name = "Shoulder Arms",
	-- 			Priority = Enum.AnimationPriority.Action2,
	-- 		},

	-- 		Present = {
	-- 			Name = "Present",
	-- 			Priority = Enum.AnimationPriority.Action3,
	-- 		},
	-- 	},

	-- 	EffectPath = "./Sabre",
	-- 	EffectPartPath = "Handle",
	-- 	EffectData = {
	-- 		Server = {
	-- 			Block = {
	-- 				Name = "Block",
	-- 				Rate = 55,
	-- 			},

	-- 			Parry = {
	-- 				Name = "Parry",
	-- 				Rate = 65,
	-- 				IgnoreAttachment = true,
	-- 			},
	-- 		},

	-- 		Client = {},
	-- 	},

	-- 	SoundPath = "./Sabre",
	-- 	SoundData = {
	-- 		Server = {
	-- 			DefaultAttack = {
	-- 				Name = "Hit",
	-- 			},

	-- 			Block = {
	-- 				Name = "Block",
	-- 			},

	-- 			Parry = {
	-- 				Name = "Parry",
	-- 			},
	-- 		},

	-- 		Client = {
	-- 			Swing = {
	-- 				Name = "Swing",
	-- 			},
	-- 		},
	-- 	},
	-- },

	-- ["SharpePistol"] = {
	-- 	Name = "Sharpe Pistol",
	-- 	Category = "Secondary",
	-- 	Class = "StandardPistol",
	-- 	Price = 11,
	-- 	Weight = 10,

	-- 	MaxBullets = 1,
	-- 	ProjectileAmount = 1,
	-- 	ProjectileVelocity = 950,
	-- 	DefaultDamage = 30,
	-- 	HeadshotMultiplier = 1.75,
	-- 	MaxBulletSpread = 0,
	-- 	AttackRange = 3,
	-- 	Damage = 50,
	-- 	Defense = 20,

	-- 	AnimationPath = "./Pistol",
	-- 	AnimationData = {
	-- 		Reload = {
	-- 			Name = "Reload",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

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

	-- 		Present = {
	-- 			Name = "Present",
	-- 			Priority = Enum.AnimationPriority.Action3,
	-- 		},
	-- 	},

	-- 	EffectPath = "./Sabre",
	-- 	EffectPartPath = "Handle",
	-- 	EffectData = {
	-- 		Server = {},

	-- 		Client = {},
	-- 	},

	-- 	SoundPath = "./Sabre",
	-- 	SoundData = {
	-- 		Server = {},

	-- 		Client = {
	-- 			Swing = {
	-- 				Name = "Swing",
	-- 			},
	-- 		},
	-- 	},
	-- },

	-- ["Longbow"] = {
	-- 	Name = "Longbow",
	-- 	Category = "Primary",
	-- 	Class = "StandardBow",
	-- 	Price = 11,
	-- 	Weight = 10,

	-- 	AttackRange = 3,
	-- 	Damage = 50,
	-- 	Defense = 20,

	-- 	SpinSpeed = 0,
	-- 	ChargeDuration = 1.75,
	-- 	StabilityDuration = 3,
	-- 	MaxVelocity = 245,

	-- 	MaxBullets = 1,
	-- 	ProjectileAmount = 1,
	-- 	ProjectileVelocity = 950,
	-- 	DefaultDamage = 30,
	-- 	HeadshotMultiplier = 1.75,

	-- 	AnimationPath = "./Bow",
	-- 	AnimationData = {

	-- 		Equip = {
	-- 			Name = "Equip",
	-- 			Priority = Enum.AnimationPriority.Action,
	-- 		},

	-- 		Idle = {
	-- 			Name = "Idle",
	-- 			Priority = Enum.AnimationPriority.Idle,
	-- 		},

	-- 		Present = {
	-- 			Name = "Present",
	-- 			Priority = Enum.AnimationPriority.Action3,
	-- 		},
	-- 	},

	-- 	EffectPath = "./Sabre",
	-- 	EffectPartPath = "Handle",
	-- 	EffectData = {
	-- 		Server = {},

	-- 		Client = {},
	-- 	},

	-- 	SoundPath = "./Sabre",
	-- 	SoundData = {
	-- 		Server = {},

	-- 		Client = {
	-- 			Swing = {
	-- 				Name = "Swing",
	-- 			},
	-- 		},
	-- 	},
	-- },

	-- ["StandardBayonet"] = {
	-- 	Name = "Bayonet",
	-- 	Category = "Resource",
	-- 	Price = 0,
	-- 	Weight = 10,

	-- 	AttackRange = 3,
	-- 	Damage = 50,
	-- 	Defense = 20,
	-- },
}

return WeaponData
