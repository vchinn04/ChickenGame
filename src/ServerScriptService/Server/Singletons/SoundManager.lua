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

function SoundManager.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("MeleeHit", function(hit_raycast_result: { [string]: any }): nil
		return
	end))

	return
end

function SoundManager.Start(): nil
	return
end

function SoundManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	return
end

function SoundManager.Reset(): nil
	Maid:DoCleaning()
	return
end

return SoundManager
