local SpatialUtils = {}
--[[
	<description>
		This class is responsible for handling the standard FoxHat functionality.
	</description> 
	
	<API>
		SpatialUtils.FindPlayer(part: Instance) ---> Player?
            -- Given a part, or other instance find the player associated with it or return nil if none 
            part: Instance -- Part used to find player 

        SpatialUtils:GetPlayersInRadius(hitbox_center, hitbox_size, overlap_params) ---> { Player }
            -- Find all the players in a radius and return a list. No duplicates in list.
            hitbox_center: Vector3 -- Center of query region 
            hitbox_size: number -- radius of region 
            overlap_params: OverlapParams? -- Overlap parameters for query 

        SpatialUtils:GetPlayersInBox(hitbox_center, hitbox_size, overlap_params) ---> { Player }
            -- Find all the players in a bounding box and return a list. No duplicates in list.
            hitbox_center: CFrame -- Center of query region 
            hitbox_size: Vector3 -- size of region 
            overlap_params: OverlapParams? -- Overlap parameters for query 	
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local Players = game:GetService("Players")
--*************************************************************************************************--

function SpatialUtils.FindPlayer(part: Instance): Player?
	local result_path = string.split(part:GetFullName(), ".")
	local character: Instance? = workspace:FindFirstChild(result_path[2])
	if not character then
		return nil
	end

	local player: Player? = Players:GetPlayerFromCharacter(character)
	if player == nil then
		return nil
	end

	return player
end

function SpatialUtils:GetPlayersInRadius(
	hitbox_center: Vector3,
	hitbox_size: number,
	overlap_params: OverlapParams?
): { Player }
	local hitbox_cache = setmetatable({}, { __mode = "k" })
	local return_list = setmetatable({}, { __mode = "k" })
	local hit_results = workspace:GetPartBoundsInRadius(hitbox_center, hitbox_size, overlap_params)

	for _, part in hit_results do
		local player: Player? = self:FindPlayerObject(part)
		if not player then
			continue
		end

		if hitbox_cache[player] then
			continue
		end

		hitbox_cache[player] = true
		table.insert(return_list, player)
	end

	return return_list
end

function SpatialUtils:GetPlayersInBox(
	hitbox_center: CFrame,
	hitbox_size: Vector3,
	overlap_params: OverlapParams?
): { Player }
	local hitbox_cache = setmetatable({}, { __mode = "k" })
	local return_list = setmetatable({}, { __mode = "k" })
	local hit_results = workspace:GetPartBoundsInBox(hitbox_center, hitbox_size, overlap_params)

	for _, part in hit_results do
		local player = self:FindPlayerObject(part)
		if not player then
			continue
		end

		if hitbox_cache[player] then
			continue
		end

		hitbox_cache[player] = true
		table.insert(return_list, player)
	end

	return return_list
end

return SpatialUtils
