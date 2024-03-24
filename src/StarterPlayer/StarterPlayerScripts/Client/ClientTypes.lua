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
	Trigger: (NestObject) -> nil,
	TriggerEnd: (NestObject) -> nil,
	GetObject: (NestObject) -> Instance?,
	GetPromptPart: (NestObject) -> Instance?,
	Destroy: (NestObject) -> nil,
	new: (Instance, Core, InteractionData) -> NestObject,
}

export type NestObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_instance: Instance?,
		_data: InteractionData,
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

------------------ACCESSORY------------------
export type AccessoryClass = {
	__index: AccessoryClass,
	GetId: (AccessoryObject) -> string?,
	Destroy: (AccessoryObject) -> nil,
	new: (Player, ToolData) -> AccessoryObject,
}

export type AccessoryObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_tool_data: ToolData,
		_tool: Instance,
	},
	{} :: AccessoryClass
)) & AccessoryClass
--******************************************--

------------------BASKET------------------
export type Basket = {
	__index: Basket,
	GetId: (BasketObject) -> string?,
	UserInput: (BasketObject) -> nil,
	Destroy: (BasketObject) -> nil,
	new: (Player, ToolData) -> BasketObject,
}

export type BasketObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_tool_data: ToolData,
		_tool: Instance,
	},
	{} :: Basket
)) & Basket
--******************************************--

------------------HATS------------------
export type BullHat = {
	__index: BullHat,
	SkillHandler: (BullHatObject) -> nil,
	GetId: (BullHatObject) -> string?,
	Destroy: (BullHatObject) -> nil,
	new: (Player, ToolData) -> BullHatObject,
}

export type BullHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_tool_data: ToolData,
		_tool: Instance,
	},
	{} :: BullHat
)) & BullHat

----------

export type ChickenHat = {
	__index: ChickenHat,
	GetId: (ChickenHatObject) -> string?,
	Destroy: (ChickenHatObject) -> nil,
	new: (Player, ToolData) -> ChickenHatObject,
}

export type ChickenHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_tool_data: ToolData,
		_tool: Instance,
	},
	{} :: ChickenHat
)) & ChickenHat

----------

export type FoxHat = {
	__index: FoxHat,
	SkillHandler: (FoxHatObject) -> nil,
	GetId: (FoxHatObject) -> string?,
	Destroy: (FoxHatObject) -> nil,
	new: (Player, ToolData) -> FoxHatObject,
}

export type FoxHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_tool_data: ToolData,
		_tool: Instance,
	},
	{} :: FoxHat
)) & FoxHat

----------

export type PiggyHat = {
	__index: PiggyHat,
	SkillHandler: (PiggyHatObject) -> nil,
	GetId: (PiggyHatObject) -> string?,
	Destroy: (PiggyHatObject) -> nil,
	new: (Player, ToolData) -> PiggyHatObject,
}

export type PiggyHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_tool_data: ToolData,
		_tool: Instance,
	},
	{} :: PiggyHat
)) & PiggyHat

----------

export type PlatypusHat = {
	__index: PlatypusHat,
	SkillHandler: (PiggyHatObject) -> nil,
	GetId: (PlatypusHatObject) -> string?,
	Destroy: (PlatypusHatObject) -> nil,
	new: (Player, ToolData) -> PlatypusHatObject,
}

export type PlatypusHatObject = typeof(setmetatable(
	{} :: ObjectSkeleton & {
		_tool_data: ToolData,
		_tool: Instance,
	},
	{} :: PlatypusHat
)) & PlatypusHat
--******************************************--

return {}
