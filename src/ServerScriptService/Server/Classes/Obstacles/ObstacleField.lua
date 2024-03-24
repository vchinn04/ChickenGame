local ObstacleField = {}
ObstacleField.__index = ObstacleField
local types = require(script.Parent.Parent.Parent.ServerTypes)
local ServerStorage = game:GetService("ServerStorage")
local ObstacleFields = ServerStorage:WaitForChild("ObstacleFields")

function ObstacleField:DecreaseProbability(decrease_key, decrease_percentage)
	local decrease_amount: number = 0

	for index, entry in self._probability_weights do
		if entry[1] == decrease_key then
			decrease_amount = decrease_percentage * entry[2]
			self._maid.TileProbabilities:AdjustProbability(index, entry[2] - decrease_amount)
			break
		end
	end

	for index, entry in self._probability_weights do
		if entry[1] ~= decrease_key then
			self._maid.TileProbabilities:AdjustProbability(index, entry[2] + decrease_amount)
		end
	end
end

function ObstacleField:GenerateField(): nil
	if not self._field_folder then
		return
	end

	local placed_count: number = 0
	local position_offset: Vector3 = self._tile_start_pos
	local decrease_percentage: number = 0.35

	while placed_count < self._tile_count do
		local tile_name: string = self._maid.TileProbabilities:GetPrediction()
		local tile = self._field_folder:WaitForChild(tile_name, 3)

		if not tile then
			warn("Couldn't find field tile: ", tile_name)
			continue
		end
		tile = tile:Clone()
		tile.Parent = self._maid.WorkFolder
		tile:PivotTo(CFrame.new(position_offset))

		local size: Vector3 = nil
		local snap_axis: Vector3 = tile:GetAttribute("SnapAxis")
		if tile:IsA("Model") then
			size = tile:GetExtentsSize()
		else
			size = tile.Size
		end

		position_offset += Vector3.new(size.X * snap_axis.X, size.Y * snap_axis.Y, size.Z * snap_axis.Z)

		self:DecreaseProbability(tile_name, decrease_percentage)
		placed_count += 1
	end
	return
end

function ObstacleField:Destroy(): nil
	self._maid:DoCleaning()
	self._maid = nil
	self._probability_weights = nil
	self = nil
	return
end

function ObstacleField.new(
	tile_count: number,
	tile_start_pos: Vector3,
	field_direction: Vector3,
	folder_id: string
): types.ObstacleFieldObject
	local self: types.ObstacleFieldObject = setmetatable({} :: types.ObstacleFieldObject, ObstacleField)

	self.Core = _G.Core
	self._maid = self.Core.Utils.Maid.new()

	self._tile_count = tile_count
	self._tile_start_pos = tile_start_pos
	self._field_direction = field_direction
	self._field_folder = ObstacleFields:WaitForChild(folder_id, 5)

	if not self._field_folder then
		warn("No obstacle folder with id: ", folder_id, " found!")
	else
		local field_children: { Instance } = self._field_folder:GetChildren()

		self._tile_count = math.min(tile_count, #field_children)
		self._probability_weights = {}

		local tile_weight: number = 100 / self._tile_count
		for _, tile in field_children do
			table.insert(self._probability_weights, { tile.Name, tile_weight })
		end

		self._maid.TileProbabilities = self.Core.Utils.ProbabilityUtil.new(self._probability_weights)
	end

	self._maid.WorkFolder = Instance.new("Folder")
	self._maid.WorkFolder.Name = "ObstacleField_" .. folder_id
	self._maid.WorkFolder.Parent = workspace

	return self
end

return ObstacleField
