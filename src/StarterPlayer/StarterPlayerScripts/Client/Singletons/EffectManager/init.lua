local EffectManager = {
	Name = "EffectManager",
}
--[[
	<description>
		This manager is responsible for particle effects and other VFX
	</description> 
	
	<API>
		EffectManager.CloneInstance(object: Instance?, ignore_dict: { [number]: string }?, initial_position: CFrame?, initial_parent: Instance?) ---> Instance?
			-- Clone instance and remove the tags. 
			object: Instance ---> Instance to be cloned 
			ignore_dict : { [number]: string }? ---> An array of objects not to clone. 
			initial_position: CFrame? ---> A position to move cloned object to.
			initial_parent: Instance? ---> Object which one has to parent the cloned instance to.

		EffectManager.Emit(object: Instance?, emit_amount: number) ---> nil 
			-- Find all ParticleEmitter descendants of object and callt their Emit function with number specified 
			object: Instance? ---> Object which is being searched 
			emit_amount: number ---> Number of particles to be emitted per ParticleEmitter

		EffectManager.SetupInstanceForTween(object: Instance?, root_part: Instance?) ---> nil
			-- Creates welds between all the parts and the root part and makes them visible. 
			object: Instance? ---> Object which is being searched 
			root_part: Instance? ---> Root part to which others are welded to

		EffectManager.Splatter(center_part : Instance) ---> nil
			-- Use the Splatter3D Instance to splatter blood
			center_part : Instance -- Part from which to splatter

		EffectManager.TweenTranspareny(object: Instance, new_transparency: number?, duration: number?, dont_clone: boolean?) ---> Promise (A Promise containing all tweens.)
			-- Tween the transpecy of an object to specidied transparency. Skip tweening objects already at that transparency. 
			object: Instance  ---> Object whose descendants have to be tweened. 
			new_transparency: number? ---> Transparency to tween to. DEFAULT: 1
			duration: number? ---> duration of the tweens. DEFAULT: 0.25 
			dont_clone: boolean? ---> If set to true the items INSIDE THE PASSED IN OBJECT ARE TWEENED, ELSE THE OBJECT IS CLONED FIRST.

		EffectManager.TweenCFrame(object: Instance, new_cframe: CFrame, duration: number?, dont_clone: boolean?) ---> { [string]: any }
			-- Tween the CFrame of object, after cloning it. 
			object: Instance ---> Object to tween 
			new_cframe: CFrame ---> CFrame to tween to 
			duration: number? ---> Duration of tween. Optional. Default: 0.25
			dont_clone: boolean? ---> True: ignore cloning the object, False: dont tween original object and clone it, then tween clone.

		EffectManager.GetEffectList(effect_name: string, object: Instance): {}
			-- Iterate through descendants of object and return array of all instances with specified name.
			effect_name : string ---> Name of effect to find.
			object: Instance ---> Object to find effects in.

		EffectManager.FocusCharacter(object: Instance, object_position: Vector3?, distance_to_plr: number?, dont_move: boolean?) ---> Promise
			-- Focus character on specific object. Make player look at object and move the player closer to object. 
			object: Instance  ---> Object on which to focus
			object_position: Vector3? ---> specify position of object. If not specified it is found automatically. 
			distance_to_plr: number? ---> Distance at which player should stand from object. 
			dont_move : boolean? ---> True: Do not adjust postion of player. False: move player closer to focus if too far.
			The promise is also set to EffectManager._focus_tween 

		EffectManager.UnfocusCharacter() ---> nil 
			-- If EffectManager._focus_tween  is not nil, cancel it. Next set it to nil (regardless if it is nil or not). 

		EffectManager.PivotRotation(object: Instance?, direction: Vector3, duration: number?, pivot_object: Instance?) ---> Promise
			-- Rotate an object in a specified direction on either specified pivot point or on  base of object. 
			object: Instance  ---> Object being rotated
			direction: Vector3 ---> Direction in which to rotate 
			duration: number? ---> duration of the tweeb. DEFAULT: 0.25 
			pivot_object: Instance? ---> Object to pivot around, if not specified  

		EffectManager.ObstacleHit(hit_raycast_result: RaycastResult) ---> nil
			-- Create an object hit effect. If not terrain, found in MATERIAL_HIT_EFFECT_MAP. 
			hit_raycast_result : RaycastResult --->  Takes in a RaycastResult (or a table ;)) with information needed for effect.

		EffectManager.Create(path: string) ---> {[string]: any}
			-- Create a EffectObject instance with the folder being at a specified path. 
			path: string ---> Path to effects folder. Starts at Resources/Effects

		EffectManager.EventHandler() ---> nil
			-- Handle incoming events such as melee, movement, etc
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local EffectClass = require(script:WaitForChild("EffectObject"))
local ProjectileVisualiser = require(script:WaitForChild("ProjectileVisualiser"))

local Core
local Maid
local Splatter3DClass, Splatter3D = nil, nil
local EffectTable = nil
local PlayerTrapsarencyCache = {}
local MATERIAL_HIT_EFFECT_MAP = {
	[Enum.Material.WoodPlanks] = "WoodHit",
	[Enum.Material.Wood] = "WoodHit",
}

local TERRAIN_HIT_EFFECT: string = "TerrainHit"
local OBJECT_HIT_DECAL: string = "WallHit"
local PROJECTILE_TRAIL_NAME: string = "ProjectileTrail"

local OBJECT_HIT_EMIT_AMOUNT: number = 25
local TERRAIN_HIT_EMIT_AMOUNT: number = 35

local OBJECT_HIT_MIN_SIZE: number = 3.55
local OBJECT_HIT_MAX_SIZE: number = 5.2

local OBJECT_DECAL_TWEEN_DURATION: number = 0.5
local OBJECT_DECAL_TWEEN_TRANSPARENCY: number = 0

--*************************************************************************************************--
function EffectManager.CreateTestPart(pos)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Parent = Core.EffectsWorkFolder
	p.Size = Vector3.new(0.15, 0.15, 0.15)
	p.Position = pos
end

function EffectManager.CloneInstance(
	object: Instance?,
	ignore_dict: { [number]: string }?,
	initial_position: CFrame?,
	initial_parent: Instance?
): Instance?
	if not object then
		return
	end
	local cloned_object: Instance = object:Clone()

	for _, tag in CollectionService:GetTags(cloned_object) do
		CollectionService:RemoveTag(cloned_object, tag)
	end

	if initial_position then
		cloned_object:PivotTo(initial_position)
	end

	if initial_parent then
		cloned_object.Parent = initial_parent
	end

	if ignore_dict then
		for _, ignored in ignore_dict do
			local obj = cloned_object:FindFirstChild(ignored)
			if obj then
				obj:Destroy()
			end
		end
	end

	return cloned_object
end

function EffectManager.Emit(object: Instance?, emit_amount: number): nil
	if not object then
		return
	end

	for _, item in object:GetDescendants() do
		if item:IsA("ParticleEmitter") then
			item:Emit(emit_amount)
		end
	end

	return
end

function EffectManager.SetupInstanceForTween(object: Instance?, root_part: Instance?): nil
	if not object then
		return
	end

	if root_part then
		root_part.Anchored = true
	end

	for _, part in object:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false

			if root_part and part ~= root_part then
				local weld: WeldConstraint = Instance.new("WeldConstraint")
				weld.Part0 = root_part
				weld.Part1 = part
				weld.Name = part.Name
				weld.Parent = root_part
				part.Anchored = false
			end
			if part.Parent == object then
				part.Transparency = 0
			end
		end
	end

	if object:IsA("BasePart") then
		object.CanCollide = false
		object.CanQuery = false
		object.CanTouch = false
		object.Transparency = 0
	end

	return
end

function EffectManager.Splatter(center_part: Instance): nil
	local callback = function(res: {}): nil
		local blood_spill_clone: Instance = EffectTable.BloodSpill:Clone()
		blood_spill_clone.Anchored = true
		blood_spill_clone.Size = Vector3.new(0, 0, 0)
		blood_spill_clone.Parent = Core.EffectsWorkFolder

		local current_orientation = blood_spill_clone.Orientation

		local random_size: number = math.random(0.2, 2.5)
		local random_y_rotation: number = math.random(0, 2 * math.pi)

		blood_spill_clone.CFrame = CFrame.new(res.Position)
			* CFrame.Angles(current_orientation.X, random_y_rotation, current_orientation.Z)

		local size_tween: Tween = TweenService:Create(
			blood_spill_clone,
			TweenInfo.new(0.5),
			{ Size = Vector3.new(random_size, 0.1, random_size) }
		)
		size_tween:Play()

		Debris:AddItem(blood_spill_clone, 3)
		return
	end

	local splatter_name: string = (if center_part.Parent then center_part.Parent.Name else center_part.Name)

	Splatter3D:Splatter(center_part, callback, 0.05, 3, splatter_name)
	return
end

function EffectManager.TweenTranspareny(
	object: Instance,
	new_transparency: number?,
	duration: number?,
	dont_clone: boolean?,
	ignore_table: {}?,
	filter_transparency: boolean?
): { [string]: any }
	if not object then
		return
	end

	if not duration then
		duration = 0.25
	end

	if not ignore_table then
		ignore_table = {}
	end

	if not new_transparency then
		new_transparency = 1
	end

	local promise_array: {} = {}
	local clone_object: Instance = object
	local transparency_cache = {}

	if not dont_clone then
		clone_object = EffectManager.CloneInstance(object)
		clone_object.Parent = Core.EffectsWorkFolder
		clone_object:PivotTo(object:GetPivot())
	end

	for _, part in clone_object:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("Decal") then
			-- if part.Parent == object then
			-- 	part.Transparency = 0
			-- end
			if ignore_table[part.Name] then
				continue
			end

			local transparency = new_transparency
			if type(new_transparency) == "table" then
				if new_transparency[part.Name] then
					transparency = new_transparency[part.Name]
				else
					transparency = part.Transparency
				end
			end

			if part.Transparency == transparency then
				continue
			end

			if filter_transparency and part.Transparency >= transparency then
				continue
			end

			transparency_cache[part.Name] = part.Transparency

			local promise: {} = Core.Utils.Promise.new(function(resolve, _, _)
				local tween = TweenService:Create(part, TweenInfo.new(duration), { Transparency = transparency })

				tween.Completed:Connect(resolve)
				tween:Play()
			end)

			table.insert(promise_array, promise)
		end
	end

	if clone_object:IsA("BasePart") or clone_object:IsA("Decal") then
		local transparency = new_transparency
		if type(new_transparency) == "table" then
			if new_transparency[clone_object.Name] then
				transparency = new_transparency[clone_object.Name]
			else
				transparency = clone_object.Transparency
			end
		end

		if
			not ignore_table[clone_object.Name]
			and (
				clone_object.Transparency ~= transparency
				or (filter_transparency and clone_object.Transparency < transparency)
			)
		then
			transparency_cache[clone_object.Name] = clone_object.Transparency
			local promise: {} = Core.Utils.Promise.new(function(resolve, _, _)
				local tween =
					TweenService:Create(clone_object, TweenInfo.new(duration), { Transparency = transparency })

				tween.Completed:Connect(resolve)
				tween:Play()
			end)
			table.insert(promise_array, promise)
		end
	end

	local return_promise: {} = Core.Utils.Promise.all(promise_array)

	return return_promise, transparency_cache
end

function EffectManager.TweenCFrame(
	object: Instance,
	new_cframe: CFrame,
	duration: number?,
	dont_clone: boolean?
): { [string]: any }
	if not object then
		return
	end

	if not duration then
		duration = 0.25
	end

	local clone_object: Instance = object

	if not dont_clone then
		clone_object = EffectManager.CloneInstance(object)
		clone_object.Parent = Core.EffectsWorkFolder
		clone_object:PivotTo(object:GetPivot())
	end

	if clone_object:IsA("BasePart") then
		clone_object.Anchored = true
		return Core.Utils.Promise.new(function(resolve, _, _)
			local tween: Tween = TweenService:Create(clone_object, TweenInfo.new(duration), { CFrame = new_cframe })
			tween.Completed:Connect(resolve)
			tween:Play()
		end)
	elseif clone_object:IsA("Model") and clone_object.PrimaryPart then
		clone_object.PrimaryPart.Anchored = true
		return Core.Utils.Promise.new(function(resolve, _, _)
			local tween: Tween =
				TweenService:Create(clone_object.PrimaryPart, TweenInfo.new(duration), { CFrame = new_cframe })
			tween.Completed:Connect(resolve)
			tween:Play()
		end)
	end

	return nil
end

function EffectManager.GetEffectList(effect_name: string, object: Instance): {}
	local return_list: {} = {}
	for _, effect in object:GetDescendants() do
		if effect.Name == effect_name then
			table.insert(return_list, effect)
		end
	end
	return return_list
end

function EffectManager.FocusCharacter(
	object: Instance,
	object_position: Vector3?,
	distance_to_plr: number?,
	dont_move: boolean?
): { [string]: any }
	if not object_position then
		object_position = if object:IsA("Model") then object:GetPivot().Position else object.Position
	end

	if not distance_to_plr then
		distance_to_plr = 3.5
	end

	local player_pos: Vector3 = Core.HumanoidRootPart.Position
	local player_height: number = player_pos.Y
	local object_heightlesss_position: Vector3 = Vector3.new(object_position.X, player_height, object_position.Z)

	local direction_to_humroot: Vector3 = (Core.HumanoidRootPart.Position - object_heightlesss_position).Unit
	local new_pos: Vector3 = player_pos

	if not dont_move then
		new_pos = object_position + (direction_to_humroot * distance_to_plr)
	end

	EffectManager._focus_tween = Core.Utils.Promise.new(function(resolve, _, onCancel)
		local focus_tween: Tween = TweenService:Create(
			Core.HumanoidRootPart,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ CFrame = CFrame.new(Vector3.new(new_pos.X, player_height, new_pos.Z), object_heightlesss_position) }
		)

		if onCancel(function()
			print("Cancelled")
			focus_tween:Cancel()
		end) then
			return
		end

		focus_tween.Completed:Connect(resolve)

		focus_tween:Play()
	end)

	return EffectManager._focus_tween
end

function EffectManager.UnfocusCharacter(): nil
	if EffectManager._focus_tween then
		EffectManager._focus_tween:cancel()
	end
	EffectManager._focus_tween = nil
	return
end

function EffectManager.PivotRotation(
	object: Instance?,
	direction: Vector3,
	duration: number?,
	pivot_object: Instance?
): { [string]: any }
	if not object then
		return
	end

	if not duration then
		duration = 0.25
	end

	local base_part: Instance = Instance.new("Part")
	base_part.Size = Vector3.new(0.1, 0.1, 0.1)
	base_part.CanCollide = false
	base_part.CanQuery = false
	base_part.CanTouch = false
	base_part.Transparency = 1

	local heightless_direction: Vector3 = Vector3.new(direction.X, 0, direction.Z).Unit

	if pivot_object then
		local size = if pivot_object:IsA("Model") then pivot_object:GetExtentsSize() else pivot_object.Size
		local object_pos: Vector3 = if object:IsA("Model")
			then pivot_object:GetPivot().Position
			else pivot_object.Position
		local new_pos: Vector3 = object_pos + Vector3.new(0, size.Y / 2, 0)
		base_part.CFrame = CFrame.new(new_pos, new_pos + heightless_direction * 5)
	else
		local size = if object:IsA("Model") then object:GetExtentsSize() else object.Size
		local object_pos: Vector3 = if object:IsA("Model") then object:GetPivot().Position else object.Position
		local new_pos: Vector3 = object_pos - Vector3.new(0, size.Y / 2, 0)
		base_part.CFrame = CFrame.new(new_pos, new_pos + heightless_direction * 5)
	end

	base_part.Parent = object
	EffectManager.SetupInstanceForTween(object, base_part)

	local promise: {} = Core.Utils.Promise.new(function(resolve, _, _)
		local tween: Tween =
			TweenService:Create(base_part, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				CFrame = base_part.CFrame * CFrame.Angles(math.rad(-97), 0, 0),
			})
		tween.Completed:Connect(resolve)
		tween:Play()
	end)

	return promise
end

function EffectManager.ObstacleHit(hit_raycast_result: RaycastResult): nil
	if hit_raycast_result.Instance.Name ~= "Terrain" then
		if MATERIAL_HIT_EFFECT_MAP[hit_raycast_result.Material] then
			Maid.MiscEffectObject:EmitAndDestroyObject(
				MATERIAL_HIT_EFFECT_MAP[hit_raycast_result.Material],
				hit_raycast_result.Instance,
				CFrame.new(hit_raycast_result.Position, hit_raycast_result.Position + hit_raycast_result.Normal),
				nil,
				OBJECT_HIT_EMIT_AMOUNT
			)
		end
	else
		Maid.MiscEffectObject:EmitAndDestroyObject(
			TERRAIN_HIT_EFFECT,
			hit_raycast_result.Instance,
			CFrame.new(hit_raycast_result.Position, hit_raycast_result.Position + hit_raycast_result.Normal),
			Core.Terrain:GetMaterialColor(hit_raycast_result.Material),
			TERRAIN_HIT_EMIT_AMOUNT
		)
	end

	local decal_folder: Folder =
		Maid.MiscEffectObject:AddDecal(OBJECT_HIT_DECAL, hit_raycast_result.Instance, nil, true)
	local tween_promises: {} = {}

	for _, decal in decal_folder:GetChildren() do
		decal.Size = Vector3.new(0, 0, 0)
		decal.CFrame = CFrame.new(hit_raycast_result.Position, hit_raycast_result.Position + hit_raycast_result.Normal)

		if not decal:GetAttribute("NoColor") then
			local hit_color: Color3 = hit_raycast_result.Instance.Color
			local darker_version: Color3 = Color3.fromRGB(
				math.clamp(hit_color.R * 255 - 15, 0, 255),
				math.clamp(hit_color.G * 255 - 15, 0, 255),
				math.clamp(hit_color.B * 255 - 15, 0, 255)
			)

			decal:FindFirstChildWhichIsA("Decal").Color3 = darker_version
		end

		decal:FindFirstChildWhichIsA("Decal").Transparency = 1

		local size: number = math.random(OBJECT_HIT_MIN_SIZE, OBJECT_HIT_MAX_SIZE)
		local tween_promise: {} = Maid.MiscEffectObject:TweenAndDestroyDecal(
			decal,
			OBJECT_DECAL_TWEEN_DURATION,
			Vector3.new(size, size, 0.1),
			OBJECT_DECAL_TWEEN_TRANSPARENCY
		)

		table.insert(tween_promises, tween_promise)
		tween_promise:finally(function()
			decal:Destroy()
			Maid.MiscEffectObject:RemoveDecal(OBJECT_HIT_DECAL, hit_raycast_result.Instance)
		end)
	end

	local combined_promise: {} = Core.Utils.Promise.all(tween_promises)

	combined_promise:finally(function()
		decal_folder:Destroy()
	end)

	return
end

function EffectManager.Create(path: string)
	return EffectClass.new(path)
end

function EffectManager.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("ObstacleHit", function(hit_raycast_result)
		EffectManager.ObstacleHit(hit_raycast_result)
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("ObstacleHit").OnClientEvent:Connect(function(hit_raycast_result)
		EffectManager.ObstacleHit(hit_raycast_result)
	end))

	Maid:GiveTask(Core.Subscribe("MeleeHit", function(hit_raycast_result)
		-- EffectManager.Splatter(hit_raycast_result)
	end))

	Maid:GiveTask(Core.Subscribe("Emit", function(object: Instance?, emit_amount: number)
		EffectManager.Emit(object, emit_amount)
	end))

	Maid:GiveTask(Core.Subscribe("DropInteraction", function(object: Instance): nil
		local clone_object: Instance =
			EffectManager.CloneInstance(object, { "PromptAttach" }, object:GetPivot(), Core.EffectsWorkFolder)

		EffectManager.TweenCFrame(clone_object, Core.HumanoidRootPart.CFrame, 0.75, true)
		local transparency_promise: {} = EffectManager.TweenTranspareny(clone_object, 1, 0.25, true)

		transparency_promise:finally(function()
			print("Destroying Interaction Drop!")
			if clone_object then
				clone_object:Destroy()
			end
			clone_object = nil
		end)
		return
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("PiggyHatSkill").OnClientEvent:Connect(function(is_hit: boolean)
		if is_hit then
			Core.Fire("CameraBlur", 5)
			Core.Fire("Blind", 5)
		end
	end))

	Maid:GiveTask(Core.Subscribe("MiningTrigger", function(status: boolean, inst: Instance): nil
		if status then
			EffectManager.FocusCharacter(inst, nil, nil, true)
		else
			EffectManager.UnfocusCharacter()
		end
		return
	end))

	Maid:GiveTask(Core.Subscribe("ResourceTrigger", function(status: boolean, inst: Instance): nil
		if status then
			EffectManager.FocusCharacter(inst)
		else
			EffectManager.UnfocusCharacter()
		end
		return
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("AttackSuccess").OnClientEvent:Connect(function(hit_object: Instance)
		Core.Fire("MeleeHit", hit_object)
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("TreeInteract").OnClientEvent:Connect(function(object)
		local object_cframe: CFrame, _ = object:GetBoundingBox()
		local clone_object: Instance =
			EffectManager.CloneInstance(object, { "Stump", "PromptAttach" }, object_cframe, Core.EffectsWorkFolder)

		local tilt_promise: {} = EffectManager.PivotRotation(
			clone_object,
			Core.HumanoidRootPart.CFrame.LookVector,
			3.15,
			object:FindFirstChild("Stump")
		)

		local transparency_promise: {} = EffectManager.TweenTranspareny(clone_object, 1, 7, true)
		local promise: {} = Core.Utils.Promise.all({ tilt_promise, transparency_promise })

		tilt_promise:andThen(function()
			Core.Fire("CameraShake", 0.35, 5, 0.2, 0.45)
		end)

		promise:finally(function()
			print("Destruction")
			if clone_object then
				clone_object:Destroy()
			end
			clone_object = nil
		end)
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("DefaultInteract").OnClientEvent:Connect(function(object)
		local object_cframe: CFrame, _ = object:GetBoundingBox()
		local clone_object: Instance =
			EffectManager.CloneInstance(object, { "PromptAttach" }, object_cframe, Core.EffectsWorkFolder)

		EffectManager.SetupInstanceForTween(clone_object)

		local transparency_promise: Promise = EffectManager.TweenTranspareny(clone_object, 1, 3, true)

		transparency_promise:finally(function()
			print("Destruction")
			if clone_object then
				clone_object:Destroy()
			end
			clone_object = nil
		end)
	end))

	Maid:GiveTask(
		Core.Utils.Net:RemoteEvent("ProjectileVisualize").OnClientEvent:Connect(
			function(
				server_tick: number,
				tool_name: string,
				projectile_id: string,
				origin_position: Vector3,
				direction: Vector3,
				velocity: number? | Vector3?,
				acceleration: Vector3?,
				target: Vector3
			): nil
				local object_key = `{tool_name}_{projectile_id}`
				if not Maid[object_key] then
					local bullet_template = Core.Utils.UtilityFunctions.ConvertToProjectile(
						Core.Items:FindFirstChild(projectile_id):Clone():Clone()
					)
					bullet_template.Parent = game.ReplicatedStorage
					local tool_data: {} = Core.ItemDataManager.GetItem(Core.ItemDataManager.NameToId(tool_name))
					local spin_speed: number = 0
					if tool_data and tool_data.SpinSpeed then
						spin_speed = tool_data.SpinSpeed
					end

					for _, effect in EffectManager.GetEffectList(PROJECTILE_TRAIL_NAME, bullet_template) do
						effect.Enabled = true
					end

					if spin_speed > 0 then
						Maid[object_key] = ProjectileVisualiser.new(
							nil,
							bullet_template,
							function(active_cast, segmentOrigin, segmentDirection, length, _, cosmeticBulletObject)
								if cosmeticBulletObject == nil then
									return
								end

								local bulletLength: number = cosmeticBulletObject.Size.Z / 2
								local baseCFrame: CFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)

								local dist: number = (origin_position - (baseCFrame * CFrame.new(
									0,
									0,
									-(length - bulletLength)
								)).Position).Magnitude

								local time_passed: number = dist / velocity
								local angle: number = time_passed * spin_speed

								cosmeticBulletObject.CFrame = baseCFrame
									* CFrame.new(0, 0, -(length - bulletLength))
									* CFrame.fromOrientation(math.rad(-angle), 0, 0)

								if active_cast.UserData.TargetDecals then
									local percentage_travelled = 1
										- (
											(cosmeticBulletObject.CFrame.Position - active_cast.UserData.Target).Magnitude
											/ 100
										)
									for _, decal in active_cast.UserData.TargetDecals:GetChildren() do
										decal.Size =
											Vector3.new(4.5 * percentage_travelled, 4.5 * percentage_travelled, 0.1)

										-- local size: number = math.random(OBJECT_HIT_MIN_SIZE, OBJECT_HIT_MAX_SIZE)

										-- Maid.MiscEffectObject:TweenDecal(decal, 0.5, Vector3.new(4.5, 4.5, 0.1), 0)
									end
								end

								return
							end
						)
					else
						Maid[object_key] = ProjectileVisualiser.new(nil, bullet_template)
					end
				end

				local target_decals: Folder? = nil
				if target then
					target_decals = Maid.MiscEffectObject:AddDecal("EggTarget", workspace, true, true)
					-- local tween_promises: {} = {}

					for _, decal in target_decals:GetChildren() do
						decal.Size = Vector3.new(0, 0, 0.1)
						decal.CFrame = CFrame.new(target, target + Vector3.new(0, 10, 0))

						-- decal:FindFirstChildWhichIsA("Decal").Transparency = 1

						-- local size: number = math.random(OBJECT_HIT_MIN_SIZE, OBJECT_HIT_MAX_SIZE)

						-- Maid.MiscEffectObject:TweenDecal(decal, 0.5, Vector3.new(4.5, 4.5, 0.1), 0)
					end
				end

				local active_cast: {} =
					Maid[object_key]:Fire(origin_position, direction, velocity, tick() - server_tick, acceleration)

				active_cast.UserData.TargetDecals = target_decals
				active_cast.UserData.Target = target
				return
			end
		)
	)

	Maid:GiveTask(
		Core.Utils.Net
			:RemoteEvent("HidePlayer").OnClientEvent
			:Connect(function(status: boolean, char: Character, base_transparency: {})
				if status then
					if char.Name ~= Core.Player.Name then
						_, _ = EffectManager.TweenTranspareny(char, 1, 0.25, true, { HumanoidRootPart = true })
					else
						_, _ = EffectManager.TweenTranspareny(char, 0.5, 0.25, true, { HumanoidRootPart = true }, true)
					end
				else
					_, _ =
						EffectManager.TweenTranspareny(char, base_transparency, 0.25, true, { HumanoidRootPart = true })
				end
			end)
	)
	return
end

function EffectManager.Start(): nil
	Maid.MiscEffectObject = EffectManager.Create("Misc")
	EffectManager.EventHandler()
	return
end

function EffectManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	EffectTable = {}
	Splatter3DClass = require(script:WaitForChild("Splatter3D"))
	EffectTable.BloodSpill = Core.Resources.Effects:WaitForChild("BloodSpill")
	Splatter3D = Splatter3DClass.new(
		nil,
		Core.Resources.Effects:WaitForChild("BloodDrop"),
		{ -6.5, 6.5 },
		{ 3, 7 },
		{ -6.5, 6.5 },
		-15
	)
	return
end

function EffectManager.Reset(): nil
	return
end

return EffectManager
