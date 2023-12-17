local ItemDataManager = {
	Name = "DataManager",
}

local Core
local Maid
local InteractableData = require(script.DataFolder:WaitForChild("InteractableData"))
local CraftingData = require(script.DataFolder:WaitForChild("CraftingData"))
local StoreData = require(script.DataFolder:WaitForChild("StoreData"))

local ItemCache = {}
local AttachmentCache = {}
local NameToId = {}
local DataTables = {}
local AttachmentTables = {}

local StoreItemCache = {}

local EQUIPABLE_CATEGORIES = {
	["Accessory"] = true,
	["Tool"] = true,
	["Melee"] = true,
	["Primary"] = true,
	["Healing"] = true,
	["Secondary"] = true,
}

local USABLE_CATEGORIES = {
	["Consumable"] = true,
}

function ItemDataManager.GenerateCache()
	print(DataTables)
	for table_index, data_table in DataTables do
		for key, data_entry in data_table do
			print(key, data_entry.Name)
			data_entry.Id = key
			NameToId[data_entry.Name] = key
			ItemCache[key] = data_entry
		end
		DataTables[table_index] = nil
	end
end

function ItemDataManager.NameToId(item_name: string)
	print(NameToId[item_name])
	print(NameToId, item_name)
	return NameToId[item_name]
end

function ItemDataManager.GetItem(item_id)
	print(item_id, ItemCache)
	local table_entry = ItemCache[item_id]
	if table_entry ~= nil then
		return table_entry
	end

	for _, data_table in DataTables do
		table_entry = data_table[item_id]

		if table_entry ~= nil then
			table_entry.Id = item_id
			NameToId[table_entry.Name] = item_id
			ItemCache[item_id] = table_entry
			return table_entry
		end
	end

	return nil
end

function ItemDataManager.GetAttachmentPosition(item_id)
	local table_entry = AttachmentCache[item_id]
	if table_entry ~= nil then
		return table_entry
	end

	for _, data_table in AttachmentTables do
		table_entry = data_table[item_id]

		if table_entry ~= nil then
			local offset_pos: Vector3? = table_entry.OffsetPosition
			local offset_rot: CFrame? = table_entry.OffsetRotation
			local offset: CFrame = nil
			if offset_pos then
				offset = CFrame.new(offset_pos)
			end
			if offset_rot then
				if offset then
					offset *= offset_rot
				else
					offset = offset_rot
				end
			end
			table_entry.Offset = offset
			AttachmentCache[item_id] = table_entry
			return table_entry
		end
	end

	return nil
end

function ItemDataManager.GetInteractable(interactable_id)
	return InteractableData[interactable_id]
end

function ItemDataManager.GetInteractableData()
	return InteractableData
end

function ItemDataManager.GetCraftingTable(table_name: string)
	return CraftingData[table_name]
end

function ItemDataManager.GetStoreEntry(table_name: string)
	return StoreData[table_name]
end

function ItemDataManager.GetStoreItem(item_path: string)
	if StoreItemCache[item_path] then
		return StoreItemCache[item_path]
	end

	local path_list = string.split(item_path, "/")
	if #path_list < 3 then
		return nil
	end

	local store_entry = StoreData[path_list[1]]
	if not store_entry then
		return nil
	end

	local section_entry = store_entry[path_list[2]]
	if not section_entry then
		return nil
	end

	local item_index = tonumber(path_list[3])
	if not item_index then
		return nil
	end

	local item_entry = section_entry.Items[item_index]
	StoreItemCache[item_path] = item_entry

	return item_entry
end

function ItemDataManager.GetAnims()
	return require(script.DataFolder:WaitForChild("AnimFolder"))
end

function ItemDataManager.IsEquippable(category: string): boolean
	if EQUIPABLE_CATEGORIES[category] then
		return true
	end
	return false
end

function ItemDataManager.IsUsable(category: string): boolean
	if USABLE_CATEGORIES[category] then
		return true
	end
	return false
end

function ItemDataManager.Init()
	Core = _G.Core
	for _, item_data_module in script.DataFolder.ItemData:GetChildren() do -- TODO: Binary Tree Search!
		table.insert(DataTables, require(item_data_module))
	end

	for _, item_data_module in script.DataFolder.AttachmentData:GetChildren() do -- TODO: Binary Tree Search!
		table.insert(AttachmentTables, require(item_data_module))
	end

	ItemDataManager.GenerateCache()
end

function ItemDataManager.Start() end

function ItemDataManager.Reset() end

return ItemDataManager
