export type CoreParams = {
	Players: Players,
	Lighting: Lighting,

	GRAVITY_VECTOR: Vector3,

	Resources: Folder,
	DataModules: Folder,
	AnimationFolder: Folder,
	EffectsFolder: Folder,
	SoundFolder: Folder,
	Items: Folder,
	Classes: Folder,
	[any]: any,
}

export type Core = typeof(setmetatable({} :: CoreParams, {} :: { [any]: any }))

export type ObjectSkeleton = {
	Core: Core,
	_maid: { [any]: any },
}

export type ToolData = {
	[any]: any,
}
export type InteractionData = {
	[any]: any,
}
export type ProjectileManagerObject = { [any]: any }
export type ProbabilityUtil = { [any]: any }
export type PromiseObject = { [any]: any }
export type InteractPromptData = { KeyCode: Enum.KeyCode?, Duration: number?, ObjectText: string?, ActionText: string? }

export type InteractionClass = Nest | UIInteractableObject
export type InteractionClassObject = NestObject | UIInteractable
-- Represents the function to determine piercing.
export type CanPierceFunction = (ActiveCast, RaycastResult, Vector3) -> boolean

export type PlayerDataItemEntry = { [any]: any }
export type PlayerData = {
	[any]: any,
}
------------------FASTCAST------------------
-- Represents a Caster :: https://etithespirit.github.io/FastCastAPIDocs/fastcast-objects/caster/
export type Caster = {
	WorldRoot: WorldRoot,
	LengthChanged: RBXScriptSignal,
	RayHit: RBXScriptSignal,
	RayPierced: RBXScriptSignal,
	CastTerminating: RBXScriptSignal,
	Fire: (Vector3, Vector3, Vector3 | number, FastCastBehavior) -> (),
}

-- Represents a FastCastBehavior :: https://etithespirit.github.io/FastCastAPIDocs/fastcast-objects/fcbehavior/
export type FastCastBehavior = {
	RaycastParams: RaycastParams?,
	MaxDistance: number,
	Acceleration: Vector3,
	HighFidelityBehavior: number,
	HighFidelitySegmentSize: number,
	CosmeticBulletTemplate: Instance?,
	CosmeticBulletProvider: any, -- Intended to be a PartCache. Dictated via TypeMarshaller.
	CosmeticBulletContainer: Instance?,
	AutoIgnoreContainer: boolean,
	CanPierceFunction: CanPierceFunction,
}

-- Represents a CastTrajectory :: https://etithespirit.github.io/FastCastAPIDocs/fastcast-objects/casttrajectory/
export type CastTrajectory = {
	StartTime: number,
	EndTime: number,
	Origin: Vector3,
	InitialVelocity: Vector3,
	Acceleration: Vector3,
}

-- Represents a CastStateInfo :: https://etithespirit.github.io/FastCastAPIDocs/fastcast-objects/caststateinfo/
export type CastStateInfo = {
	UpdateConnection: RBXScriptSignal,
	HighFidelityBehavior: number,
	HighFidelitySegmentSize: number,
	Paused: boolean,
	TotalRuntime: number,
	DistanceCovered: number,
	IsActivelySimulatingPierce: boolean,
	IsActivelyResimulating: boolean,
	CancelHighResCast: boolean,
	Trajectories: { [number]: CastTrajectory },
}

-- Represents a CastRayInfo :: https://etithespirit.github.io/FastCastAPIDocs/fastcast-objects/castrayinfo/
export type CastRayInfo = {
	Parameters: RaycastParams,
	WorldRoot: WorldRoot,
	MaxDistance: number,
	CosmeticBulletObject: Instance?,
	CanPierceCallback: CanPierceFunction,
}

-- Represents an ActiveCast :: https://etithespirit.github.io/FastCastAPIDocs/fastcast-objects/activecast/
export type ActiveCast = {
	Caster: Caster,
	StateInfo: CastStateInfo,
	RayInfo: CastRayInfo,
	UserData: { [any]: any },
}

export type LengthChangedCallback = (
	casterThatFired: ActiveCast,
	lastPoint: Vector3,
	rayDir: Vector3,
	displacement: number,
	segmentVelocity: Vector3,
	cosmeticBulletObjec: Instance
) -> ()

export type CasterHitCallback = (
	casterThatFired: ActiveCast,
	result: RaycastResult,
	segmentVelocity: Vector3,
	cosmeticBulletObjec: Instance
) -> ()

export type CasterTerminatingCallback = (casterThatFired: ActiveCast) -> ()

export type CasterPierceCallback = (
	casterThatFired: ActiveCast,
	result: RaycastResult,
	segmentVelocity: Vector3,
	cosmeticBulletObjec: Instance
) -> ()
--******************************************--

------------------INTERACTABLES------------------
export type Nest = {
	__index: Nest,
	Interact: (NestObject, Player) -> nil,
	GetObject: (NestObject) -> Instance?,
	Destroy: (NestObject) -> nil,
	new: (Instance, Core, InteractionData) -> NestObject,
}

export type NestObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_instance: Instance?,
		_data: InteractionData,
		_total_value: number,
		_success_sound: Sound?,
	},
	{} :: Nest
)) & Nest

export type UIInteractable = {
	__index: UIInteractable,
	Interact: (UIInteractableObject, Player) -> nil,
	GetObject: (UIInteractableObject) -> Instance?,
	GetPromptPart: (UIInteractableObject) -> Instance?,
	Destroy: (UIInteractableObject) -> nil,
	new: (Instance, Core, InteractionData) -> UIInteractableObject,
}

export type UIInteractableObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_instance: Instance?,
		_data: InteractionData,
	},
	{} :: UIInteractable
)) & UIInteractable
--******************************************--

------------------INTERACT PROMPT------------------
export type InteractPrompt = {
	__index: InteractPrompt,
	SetPromptEnabled: (InteractPromptObject, boolean) -> nil,
	GetPromptParent: (InteractPromptObject) -> Instance?,
	Destroy: (InteractPromptObject) -> nil,
	new: (Model | BasePart, string, InteractPromptData, boolean?, number?) -> InteractPromptObject,
}

export type InteractPromptObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_instance: Model | BasePart,
		_prompt: ProximityPrompt,
		_prompt_part: Model | Attachment | BasePart,
	},
	{} :: InteractPrompt
)) & InteractPrompt
--******************************************--

------------------BASE ACCESSORY------------------
export type BaseAccessory = {
	__index: BaseAccessory,
	GetTool: (BaseAccessoryObject) -> Accessory?,
	Destroy: (BaseAccessoryObject) -> nil,
	new: (Player, ToolData) -> BaseAccessoryObject,
}

export type BaseAccessoryObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player_object: PlayerObject,
		_id: string,
	},
	{} :: BaseAccessory
)) & BaseAccessory
--******************************************--

------------------BASE TOOL------------------
export type BaseTool = {
	__index: BaseTool,
	GetTool: (BaseToolObject) -> Tool?,
	Equip: (BaseToolObject) -> nil,
	Unequip: (BaseToolObject) -> nil,
	Destroy: (BaseToolObject) -> nil,
	new: (Player, ToolData) -> BaseToolObject,
}

export type BaseToolObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player_object: PlayerObject,
		_id: string,
	},
	{} :: BaseTool
)) & BaseTool
--******************************************--

------------------TOOL INTERSECTION------------------
export type ToolAccessoryClass = Accessory | FoxHat | ChickenHat | BullHat
--******************************************--

------------------EFFECT OBJECT------------------
export type EffectTable = { [string]: { [string]: { Instance } } }
export type EffectObjectClass = {
	__index: EffectObjectClass,
	GetEffect: (
		EffectObject,
		effect_name: string,
		parent: Instance,
		skip_attachment: boolean?,
		skip_cache: boolean?
	) -> Attachment? | { Instance }?,

	Emit: (
		EffectObject,
		effect_name: string,
		effect_parent: Instance,
		emit_amount: number,
		skip_attachment: boolean?
	) -> nil,
	Enable: (
		EffectObject,
		effect_name: string,
		effect_parent: Instance,
		status: boolean,
		skip_attachment: boolean?
	) -> nil,
	CloneEffect: (EffectObject, effect_name: string, effect_parent: Instance) -> Attachment? | { Instance }?,
	Destroy: (EffectObject) -> nil,
}

export type EffectObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_effects: EffectTable,
		_folder: Folder,
	},
	{} :: EffectObjectClass
)) & EffectObjectClass
--******************************************--

------------------TIMED FUNC------------------
export type TimedFunction = {
	StartTimer: (TimedFunctionObject) -> nil,
	CancelTimer: (TimedFunctionObject) -> nil,
	Destroy: (TimedFunctionObject) -> nil,
	new: (number?, () -> ()?, () -> ()?) -> TimedFunctionObject,
}

export type TimedFunctionObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_interval: number,
		_destroy_callback: () -> ()?,
		_on_cancel_callback: () -> ()?,
		_timer: PromiseObject?,
	},
	{} :: TimedFunction
))
--******************************************--

------------------PROJECTILE------------------
export type Projectile = {
	__index: Projectile,
	Fire: (
		ProjectileObject,
		origin: Vector3,
		direction: Vector3,
		velocity: number? | Vector3?,
		acceleration: Vector3
	) -> ActiveCast,
	EventHandler: (ProjectileObject) -> nil,
	SetRayShape: (ProjectileObject, number) -> nil,
	SetFilter: (ProjectileObject, { Instance }) -> nil,
	AppendFilter: (ProjectileObject, { Instance }) -> nil,
	Destroy: (ProjectileObject, AccessoryObject) -> nil,
	new: (
		RaycastParams?,
		CasterHitCallback?,
		LengthChangedCallback?,
		CasterTerminatingCallback?,
		CasterPierceCallback?
	) -> ProjectileObject,

	GetProjectile: (
		projectile_id: string,
		RaycastParams?,
		CasterHitCallback?,
		LengthChangedCallback?,
		CasterTerminatingCallback?,
		CasterPierceCallback?
	) -> ProjectileObject,
}

export type ProjectileObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_id: string,
		_caster: Caster,
		_caster_behavior: FastCastBehavior,
		_ray_update_callback: LengthChangedCallback?,
		_ray_hit_callback: CasterHitCallback?,
		_on_terminating_callback: CasterTerminatingCallback?,
		_on_pierced_callback: CasterPierceCallback?,
	},
	{} :: Projectile
)) & Projectile
--******************************************--

------------------PLAYER------------------
export type PlayerClass = {
	__index: PlayerClass,
	AttachObject: (PlayerObject, object: Instance, item_id: string, dont_clone: boolean?) -> nil,
	HoldItem: (PlayerObject, object: Instance, attach_name: string) -> nil,
	DetachObject: (PlayerObject, object: Instance) -> nil,

	UnequipAll: (PlayerObject) -> nil,
	GetBasket: (PlayerObject) -> BasketObject?,
	EquipTool: (PlayerObject, tool_name: string) -> nil,
	UnequipTool: (PlayerObject, tool_name: string) -> nil,
	AddTool: (PlayerObject, string, { [string]: any }, ToolData) -> ToolAccessoryClass,
	RemoveTool: (PlayerObject, tool_name: string, no_update: boolean?) -> nil,

	AddEgg: (PlayerObject, egg_id: string) -> nil,
	GetEggs: (PlayerObject) -> { string },
	PopEggs: (PlayerObject, amount: number) -> { string }?,
	StealEggs: (PlayerObject, amount: number) -> { string }?,
	ClearEggs: (PlayerObject) -> nil,

	DoDamage: (
		PlayerObject,
		damage_amount: number,
		damage_message: string?,
		damage_part_name: string?,
		damage_impulse: Vector3
	) -> nil,
	Heal: (PlayerObject, heal_amount: number, heal_message: string?) -> boolean,
	Knockback: (PlayerObject, duration: number, direction: Vector3, force: number?) -> nil,
	Stun: (PlayerObject, duration: number) -> nil,
	IsStunned: (PlayerObject) -> boolean,
	RespawnTimer: (PlayerObject) -> nil,
	-- GetProjectile: (
	-- 	PlayerObject,
	-- 	projectile_id: string,
	-- 	RaycastParams,
	-- 	() -> nil,
	-- 	() -> nil,
	-- 	() -> nil,
	-- 	() -> nil
	-- ) -> ProjectileObject,
	CleanRespawn: (PlayerObject) -> nil,
	GetPosition: (PlayerObject) -> Vector3,
	GetCFrame: (PlayerObject) -> CFrame,

	GetPlayer: (PlayerObject) -> Player,
	GetCharacter: (PlayerObject) -> Model,
	GetHumanoid: (PlayerObject) -> Humanoid?,
	HandleCharacter: (PlayerObject) -> nil,
	ResetTools: (PlayerObject) -> nil,
	DeathHandler: (PlayerObject) -> nil,
	HandleCharacterAddition: (PlayerObject) -> nil,
	InitialLoading: (PlayerObject) -> nil,
	SpawnPlayer: (PlayerObject, spawn_position: CFrame?) -> nil,
	Destroy: (PlayerObject) -> nil,
	new: (Player, Core) -> PlayerObject,
}

export type PlayerObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player: Player,
		_tool_maid: { [any]: any },
		_spawn_position: CFrame?,
		-- _MAX_EQUIP: number,
		-- _equip_stack: { string },
		_projectile_manager: ProjectileManagerObject,
		-- _random_ragdoll_x: Random,
		-- _random_ragdoll_z: Random,
		_egg_handler: EggHandlerObject,
		_tool_handler: ToolHandlerObject,
		_character_handler: CharacterHandlerObject,
	},
	{} :: PlayerClass
)) & PlayerClass
------------------------------------------------------
export type EggHandler = {
	__index: EggHandler,
	AddEgg: (EggHandlerObject, egg_id: string) -> nil,
	GetEggs: (EggHandlerObject) -> { string },
	PopEggs: (EggHandlerObject, amount: number) -> { string }?,
	StealEggs: (EggHandlerObject, amount: number) -> { string }?,
	ClearEggs: (EggHandlerObject) -> nil,
	Destroy: (EggHandlerObject) -> nil,
	new: (PlayerObject) -> EggHandlerObject,
}

export type EggHandlerObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player_object: PlayerObject,
		_egg_steal_hits: number,
	},
	{} :: EggHandler
)) & EggHandler
------------------------------------------------------
export type ToolHandler = {
	__index: ToolHandler,
	UnequipAll: (ToolHandlerObject) -> nil,
	GetBasket: (ToolHandlerObject) -> BasketObject?,
	EquipTool: (ToolHandlerObject, tool_name: string) -> nil,
	UnequipTool: (ToolHandlerObject, tool_name: string) -> nil,
	AddTool: (ToolHandlerObject, string, { [string]: any }, ToolData) -> ToolAccessoryClass,
	RemoveTool: (ToolHandlerObject, tool_name: string, no_update: boolean?) -> nil,
	ResetTools: (ToolHandlerObject) -> nil,
	Destroy: (ToolHandlerObject) -> nil,
	new: (PlayerObject) -> ToolHandlerObject,
}

export type ToolHandlerObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player_object: PlayerObject,
		_player: Player,
		_MAX_EQUIP: number,
		_equipped_tool: Tool?,
		_equip_stack: { string },
		_equipped_tool_group_cache: { string },
	},
	{} :: ToolHandler
)) & ToolHandler
------------------------------------------------------
export type CharacterHandler = {
	__index: CharacterHandler,

	AttachObject: (CharacterHandlerObject, object: Instance, item_id: string, dont_clone: boolean?) -> nil,
	HoldItem: (CharacterHandlerObject, object: Model, attach_name: string) -> nil,
	DetachObject: (CharacterHandlerObject, object: Instance) -> nil,

	DoDamage: (
		CharacterHandlerObject,
		damage_amount: number,
		damage_message: string?,
		damage_part_name: string?,
		damage_impulse: Vector3
	) -> nil,
	Heal: (CharacterHandlerObject, heal_amount: number, heal_message: string?) -> boolean,

	Knockback: (CharacterHandlerObject, duration: number, direction: Vector3, force: number?) -> nil,

	Stun: (CharacterHandlerObject, duration: number) -> nil,
	IsStunned: (CharacterHandlerObject) -> boolean,

	Ragdoll: (CharacterHandlerObject) -> nil,
	DestroyRagdoll: (CharacterHandlerObject) -> nil,

	HandleCharacter: (CharacterHandlerObject, spawn_position: CFrame?) -> nil,

	GetPosition: (CharacterHandlerObject) -> Vector3,
	GetCFrame: (CharacterHandlerObject) -> CFrame,
	GetCharacter: (CharacterHandlerObject) -> Model,
	GetHumanoid: (CharacterHandlerObject) -> Humanoid?,

	Destroy: (CharacterHandlerObject) -> nil,
	new: (PlayerObject) -> CharacterHandlerObject,
}

export type CharacterHandlerObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player_object: PlayerObject,
		_player: Player,

		_ragdoll_impulse: Vector3?,
		_ragdoll_body_part_name: string?,
		_random_ragdoll_x: Random,
		_random_ragdoll_z: Random,

		_stun_promise: PromiseObject?,

		Character: Model?,
		HumanoidRootPart: BasePart?,
		Humanoid: Humanoid?,
	},
	{} :: CharacterHandler
)) & CharacterHandler
--******************************************--
------------------CANNON------------------
export type Cannon = {
	__index: Cannon,
	FindPlayerObject: (CannonObject, BullHatObject, Instance) -> PlayerObject?,
	OnHit: (CannonObject, {}, RaycastParams, Vector3?) -> nil,
	Fire: (CannonObject) -> nil,
	Start: (CannonObject) -> nil,
	Stop: (CannonObject) -> nil,
	Destroy: (CannonObject, AccessoryObject) -> nil,
	new: (number, { number }) -> CannonObject,
}

export type CannonObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_cannon_object: Model,
		_interval: number,
		_launch_amount: { number },
		_egg_chances: ProbabilityUtil,
		_projectile: ProjectileObject,
	},
	{} :: Cannon
)) & Cannon
--******************************************--

--******************************************--
------------------OBSTACLES------------------
export type ObstacleField = {
	__index: Cannon,
	GenerateField: (ObstacleFieldObject, {}, RaycastParams, Vector3?) -> nil,
	Clear: (ObstacleFieldObject) -> nil,
	Destroy: (ObstacleFieldObject, AccessoryObject) -> nil,
	new: (number, Vector3, Vector3, string) -> ObstacleFieldObject,
}

export type ObstacleFieldObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_tile_count: number,
		_tile_start_pos: Vector3,
		_field_direction: Vector3,
		_field_folder: Folder,
		_probability_weights: { { string | number } },
	},
	{} :: ObstacleField
)) & ObstacleField
--******************************************--

------------------ACCESSORY------------------
export type AccessoryClass = {
	__index: AccessoryClass,
	EventHandler: (AccessoryObject) -> nil,
	GetToolObject: (AccessoryObject) -> Instance,
	GetId: (AccessoryObject) -> string?,
	Destroy: (AccessoryObject) -> nil,
	new: (Player, PlayerObject, ToolData) -> AccessoryObject,
}

export type AccessoryObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player: Player,
		_tool_data: ToolData,
		_player_object: PlayerObject,
	},
	{} :: AccessoryClass
)) & AccessoryClass
--******************************************--

------------------BASKET------------------
export type Basket = {
	__index: Basket,
	PopEggs: (BasketObject, number) -> { string },
	ClearEggs: (BasketObject) -> nil,
	GetEggs: (BasketObject) -> string?,
	IsEmpty: (BasketObject) -> boolean?,
	IsFull: (BasketObject) -> boolean?,
	EventHandler: (BasketObject) -> nil,
	GetToolObject: (BasketObject) -> Instance,
	GetId: (BasketObject) -> string?,
	Destroy: (BasketObject) -> nil,
	new: (Player, PlayerObject, ToolData) -> BasketObject,
}

export type BasketObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player: Player,
		_tool_data: ToolData,
		_player_object: PlayerObject,
		_max_eggs: number,
		_egg_stack: { string },
		_tool_effect_part: Instance?,
	},
	{} :: Basket
)) & Basket
--******************************************--

------------------HATS------------------
export type BullHat = {
	__index: BullHat,
	FindPlayerObject: (BullHatObject, Instance) -> PlayerObject?,
	SetActive: (BullHatObject, boolean) -> nil,
	HatSkill: (BullHatObject) -> string?,
	EventHandler: (BullHatObject) -> nil,
	GetToolObject: (BullHatObject) -> Instance,
	GetId: (BullHatObject) -> string?,
	Destroy: (BullHatObject) -> nil,
	new: (Player, PlayerObject, ToolData) -> BullHatObject,
}

export type BullHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player: Player,
		_tool_data: ToolData,
		_player_object: PlayerObject,
		_connection_maid: { [any]: any },
		_active: boolean,
		_active_duration: number,
		_transparency_cache: { [string]: number },
		OverlapParams: OverlapParams,
	},
	{} :: BullHat
)) & BullHat

----------

export type ChickenHat = {
	__index: ChickenHat,
	-- HatSkill: (ChickenHatObject) -> string?,
	EventHandler: (ChickenHatObject) -> nil,
	GetToolObject: (ChickenHatObject) -> Instance,
	GetId: (ChickenHatObject) -> string?,
	Destroy: (ChickenHatObject) -> nil,
	new: (Player, PlayerObject, ToolData) -> ChickenHatObject,
}

export type ChickenHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player: Player,
		_tool_data: ToolData,
		_player_object: PlayerObject,
	},
	{} :: ChickenHat
)) & ChickenHat

----------

export type FoxHat = {
	__index: FoxHat,
	FindPlayerObject: (FoxHatObject, Instance) -> PlayerObject?,
	SetActive: (FoxHatObject, boolean) -> nil,
	HatSkill: (FoxHatObject) -> string?,
	Steal: (FoxHatObject) -> nil,
	EventHandler: (FoxHatObject) -> nil,
	GetToolObject: (FoxHatObject) -> Instance,
	GetId: (FoxHatObject) -> string?,
	Destroy: (FoxHatObject) -> nil,
	new: (Player, PlayerObject, ToolData) -> FoxHatObject,
}

export type FoxHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player: Player,
		_tool_data: ToolData,
		_player_object: PlayerObject,
		_connection_maid: { [any]: any },
		_active: boolean,
		_active_duration: number,
		_transparency_cache: { [string]: number },
		OverlapParams: OverlapParams,
	},
	{} :: FoxHat
)) & FoxHat

----------

export type PiggyHat = {
	__index: PiggyHat,
	FindPlayerObject: (PiggyHatObject, Instance) -> Player?,
	SetActive: (PiggyHatObject, boolean) -> nil,
	HatSkill: (PiggyHatObject) -> string?,
	EventHandler: (PiggyHatObject) -> nil,
	GetToolObject: (PiggyHatObject) -> Instance,
	GetId: (PiggyHatObject) -> string?,
	Destroy: (PiggyHatObject) -> nil,
	new: (Player, PlayerObject, ToolData) -> PiggyHatObject,
}

export type PiggyHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player: Player,
		_tool_data: ToolData,
		_player_object: PlayerObject,
		_connection_maid: { [any]: any },
		_active: boolean,
		_active_duration: number,
		_hitbox_size: number,
		_transparency_cache: { [string]: number },
		OverlapParams: OverlapParams,
	},
	{} :: PiggyHat
)) & PiggyHat

----------

export type PlatypusHat = {
	__index: PlatypusHat,
	FindPlayerObject: (PlatypusHatObject, Instance) -> PlayerObject?,
	SetActive: (PlatypusHatObject, boolean) -> nil,
	HatSkill: (PlatypusHatObject) -> string?,
	EventHandler: (PlatypusHatObject) -> nil,
	GetToolObject: (PlatypusHatObject) -> Instance,
	GetId: (PlatypusHatObject) -> string?,
	Destroy: (PlatypusHatObject) -> nil,
	new: (Player, PlayerObject, ToolData) -> PlatypusHatObject,
}

export type PlatypusHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_player: Player,
		_tool_data: ToolData,
		_player_object: PlayerObject,
		_connection_maid: { [any]: any },
		_active: boolean,
		_active_duration: number,
		_hitbox_size: number,
		_transparency_cache: { [string]: number },
		OverlapParams: OverlapParams,
	},
	{} :: PlatypusHat
)) & PlatypusHat
--******************************************--

return {}
