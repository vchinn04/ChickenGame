local UtilityFunctions = {
	Name = "UtilityFunctions",
}
--[[
	<description>
		This module is simply a collection of reusable utility functions.
	</description> 
	
	<API>
		UtilityFunctions.ToModel(object: Tool | BasePart) ---> Model
			-- Converts passed in object to a model. 
			object: Tool | BasePart ---> A tool or a BasePart to be converted

		UtilityFunctions.MakeTransparent(object: Instance) ---> nil
			-- Makes the passed in object transparent.
			object: Instance ---> Instance to be made transparent

		UtilityFunctions.MakeVisible(object: Instance, ignore_names: { [string]: boolean }?) ---> nil
			-- Makes the passed in object visible.
			object: Instance ---> Instance to be made visble 
			ignore_names: dictionary of part names that are to remain invisible. {[name] = true}

		UtilityFunctions.FindObjectWithPath(object: Instance, path: string) ---> nil
			-- Find an instance in the object given a path.
			object: Instance -- Object to search in 
			path: string -- path to item 

		UtilityFunctions.AnchorObject(object: Instance) ---> nil 
			-- Anchor the object if it is a part and everything in it.
			object : Instance -- Object to anchor.
		
		 UtilityFunctions.UnanchorObject(object: Instance): nil
			-- Unanchor the object if it is a part and everything in it.
			object : Instance -- Object to unanchor.

		UtilityFunctions.GetTempsFolder(object: Instance): Folder
			-- Finds or creates a folder in object that stores temp instances such as welds. NOTE: NOT ALL WELDS STORE HERE
			object : Instance -- Object to search in 

		UtilityFunctions.AttachObject(parent_object: Instance, object: Instance) ---> nil 
			-- Attach an object to another using a weld.
			parent_object: Instance -- Object to attach to.
			object : Instance -- Object to attach.

		UtilityFunctions.FindFirstDescendant(object: Instance, item_name: string) ---> nil 
			-- Return first descendant from object that matches name. 
			object: Instance -- object to search in 
			item_name: string -- name of descendant 

		UtilityFunctions.ClearTempFolder(object: Instance) ---> nil
			-- Destroys all children of the temps folder 
			object : Instance -- Object to clear folder of 

		UtilityFunctions.ConvertToProjectile(object: Instance) ---> Instance
			-- Convert object to be a projectile (be a part with children)
			object: Instance -- object to transform 
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function UtilityFunctions.ToModel(object: Tool | BasePart): Model
	if object:IsA("Tool") then
		local model_instance = Instance.new("Model")

		for _, item in object:GetChildren() do
			item.Parent = model_instance
		end

		model_instance.PrimaryPart = model_instance:FindFirstChild("Handle")
		model_instance.Name = object.Name
		object:Destroy()
		return model_instance
	end

	if object:IsA("Model") then
		return object
	end

	local model_instance = Instance.new("Model")
	model_instance.Name = object.Name

	object.Parent = model_instance
	model_instance.PrimaryPart = object
	return model_instance
end

function UtilityFunctions.ToAccessory(object: Tool | BasePart): Model
	if object:IsA("Accessory") then
		return object
	end

	if object:IsA("Model") or object:IsA("Tool") then
		local accessory_instance = Instance.new("Accessory")

		if not object:IsA("Tool") then
			object.PrimaryPart.Name = "Handle"
		end

		for _, item in object:GetChildren() do
			item.Parent = accessory_instance
		end

		accessory_instance.Name = object.Name
		object:Destroy()
		return accessory_instance
	end

	local accessory_instance = Instance.new("Accessory")

	for _, item in object:GetChildren() do
		if item:IsA("BasePart") then
			item.Parent = accessory_instance
		end
	end

	accessory_instance.Name = object.Name
	object.Name = "Handle"
	object.Parent = accessory_instance
	return accessory_instance
end

function UtilityFunctions.MakeTransparent(object: Instance): nil
	local transparency_cache = {}
	for _, part in object:GetDescendants() do
		if part:IsA("BasePart") then
			transparency_cache[part.Name] = part.Transparency
			part.Transparency = 1
		end
	end
	if object:IsA("BasePart") then
		transparency_cache[object.Name] = object.Transparency
		object.Transparency = 1
	end
	return transparency_cache
end

function UtilityFunctions.MakeVisible(object: Instance, ignore_names: { [string]: boolean }?): nil
	if not ignore_names then
		ignore_names = {}
	end
	for _, part in object:GetDescendants() do
		if part:IsA("BasePart") and not ignore_names[part.Name] then
			part.Transparency = 0
		end
	end
	if object:IsA("BasePart") and not ignore_names[object.Name] then
		object.Transparency = 0
	end
	return
end

function UtilityFunctions.FindObjectWithPath(object: Instance, path: string): nil
	print("SEARCH FOR: ", path, "IN: ", object.Name)
	local path_list = string.split(path, "/")
	local cur_part = object

	for _, key in path_list do
		cur_part = cur_part:WaitForChild(key, 5)
		if not cur_part then
			return nil
		end
	end

	return cur_part
end

function UtilityFunctions.AnchorObject(object: Instance): nil
	if object:IsA("BasePart") then
		object.Anchored = true
	end

	for _, item in object:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = true
		end
	end

	return
end

function UtilityFunctions.UnanchorObject(object: Instance): nil
	if object:IsA("BasePart") then
		object.Anchored = false
	end

	for _, item in object:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = false
		end
	end

	return
end

function UtilityFunctions.GetTempsFolder(object: Instance): Folder
	local folder: Folder? = object:FindFirstChild("TempsFolder")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TempsFolder"
		folder.Parent = object
	end

	return folder
end

function UtilityFunctions.ClearTempFolder(object: Instance): nil
	local folder: Folder = UtilityFunctions.GetTempsFolder(object)
	folder:ClearAllChildren()
	return
end

function UtilityFunctions.AttachObject(parent_object: Instance, object: Instance): nil
	local folder: Folder = UtilityFunctions.GetTempsFolder(object)
	local attachment_object: Instance = object

	if not attachment_object:IsA("BasePart") then
		attachment_object = object.PrimaryPart
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parent_object
	weld.Part1 = attachment_object
	weld.Name = parent_object.Name .. object.Name
	weld.Parent = folder

	return
end

function UtilityFunctions.FindFirstDescendant(object: Instance, item_name: string): nil
	for _, item in object:GetDescendants() do
		if item.Name == item_name then
			return item
		end
	end

	return
end

function UtilityFunctions.ConvertToProjectile(object: Instance): Instance
	if object:IsA("BasePart") then
		return object
	end

	local part_instance = Instance.new("Part")
	local orientation: CFrame, size: Vector3 = object:GetBoundingBox()

	part_instance.Size = size
	part_instance.CFrame = orientation
	part_instance.Transparency = 1
	part_instance.Name = object.Name
	part_instance.Anchored = true
	part_instance.CanCollide = false
	part_instance.Parent = workspace

	for _, part in object:GetDescendants() do
		part.Parent = part_instance
		if part:IsA("BasePart") then
			part.CanCollide = false
			local prompt_part_weld = Instance.new("WeldConstraint")
			prompt_part_weld.Part0 = part_instance
			prompt_part_weld.Part1 = part
			prompt_part_weld.Parent = part_instance
		end
	end

	object:Destroy()
	return part_instance
end

return UtilityFunctions
