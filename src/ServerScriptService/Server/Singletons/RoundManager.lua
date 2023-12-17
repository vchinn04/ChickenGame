local RoundManager = {
	Name = "RoundManager",
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

function RoundManager.Start(): nil
	local cannon = require(Core.Classes["Cannon"]).new()
	cannon:Start()
	return
end

function RoundManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	return
end

function RoundManager.Reset(): nil
	return
end

return RoundManager
