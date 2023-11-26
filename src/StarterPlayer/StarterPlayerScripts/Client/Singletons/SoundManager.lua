local SoundManager = {
	Name = "SoundManager",
}
--[[
	<description>
		This manager is in charge of creates SoundObjects
	</description> 
	
	<API>
		SoundManager.Create(path)
			-- Create a SoundObject for specified folder
			path : string ---> Path to the sound folder
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local Core
local Maid
local MiscSoundManager

local MATERIAL_HIT_SOUND_MAP = {
	[Enum.Material.WoodPlanks] = "WoodHit",
	[Enum.Material.Wood] = "WoodHit",
}

--*************************************************************************************************--

function SoundManager.Create(path)
	local self = setmetatable({}, Core.Utils.SoundObject)
	self._sounds = {}
	self._folder = Core.SoundFolder

	if path then
		for _, i in string.split(path, "/") do
			if i == "." then
				continue
			end
			self._folder = self._folder[i]
		end
	end

	return self
end

function SoundManager.ObstacleHit(hit_raycast_result)
	if MATERIAL_HIT_SOUND_MAP[hit_raycast_result.Material] then
		local cloned_sound: Instance? = MiscSoundManager:CloneSound(
			MATERIAL_HIT_SOUND_MAP[hit_raycast_result.Material],
			hit_raycast_result.Instance
		)
		if cloned_sound then
			MiscSoundManager:PlayAndDestroy(cloned_sound)
		end
	end
end

function SoundManager.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("MeleeHit", function(hit_raycast_result: { [string]: any }): nil
		return
	end))

	Maid:GiveTask(Core.Subscribe("ObstacleHit", function(hit_raycast_result)
		SoundManager.ObstacleHit(hit_raycast_result)
	end))

	Maid:GiveTask(Core.Utils.Net:RemoteEvent("ObstacleHit").OnClientEvent:Connect(function(hit_raycast_result)
		SoundManager.ObstacleHit(hit_raycast_result)
	end))

	Maid:GiveTask(Core.Subscribe("DropInteraction", function(...): nil
		MiscSoundManager:Play("ItemPickup")
		return
	end))
	return
end

function SoundManager.Start(): nil
	SoundManager.EventHandler()
	return
end

function SoundManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	MiscSoundManager = SoundManager.Create("Misc")
	return
end

function SoundManager.Reset(): nil
	Maid:DoCleaning()
	return
end

return SoundManager
