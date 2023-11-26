local Torch = {
	Name = "Torch",
}
Torch.__index = Torch
--[[
	<description>
		This class is responsible for handling the standard Torch tool functionality.
	</description> 
	
	<API>
		TorchObj:Toggle() ---> nil 
			-- Toggle torch on and off 

		TorchObj:GetToolObject() ---> Instance
			-- return the tool object 

		TorchObj:GetId() ---> string?
			-- return the tool id 

		TorchObj:Equip() ---> Instance
			-- Setup event handling and equip tool 

		TorchObj:Unequip() ---> nil
			-- Disconnect connections 

		TorchObj:Destroy() ---> nil
			-- Cleanup connections and objects of TorchObj

		Torch.new(player, player_object, tool_data) ---> TorchObj
			-- Create a new TorchObj
			player: Player -- player who owns the object 
			player_object: {} -- PlayerObject of player 
			tool_data: {} -- data of tool being added
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local BASE_TOOL_PATH: string = "Tools/BaseTool"
--*************************************************************************************************--

function Torch:ToggleEffects(status: boolean)
	if not self._maid then
		return
	end

	if self._toggled_effects and self._maid.EffectObject then
		self._maid.EffectObject:Enable(
			self._toggled_effects.Name,
			self._tool_effect_part,
			status,
			self._toggled_effects.IgnoreAttachment
		)
	end
	if status then
		if self._maid._toggle_on_sound then
			self._maid.SoundObject:SinglePlay(self._maid._toggle_on_sound)
		end
	else
		if self._maid._toggle_off_sound then
			self._maid.SoundObject:SinglePlay(self._maid._toggle_off_sound)
		end
	end

	if self._maid._toggled_sound then
		self._maid._toggled_sound.Playing = status
	end
	-- Future: Add Warmth when toggled
end

function Torch:Toggle(): nil
	self._toggled = not self._toggled
	self:ToggleEffects(self._toggled)
	return
end

function Torch:EventHandler(): nil
	self._connection_maid:GiveTask(
		self.Core.Utils.Net
			:RemoteEvent(`{self._player.UserId}_tool`).OnServerEvent
			:Connect(function(player, event_name, ...)
				if event_name and self[event_name] then
					local params = { ... }
					self[event_name](self, params)
				end
			end)
	)
	return
end

function Torch:GetToolObject(): Instance
	return self._maid.BaseTool:GetTool()
end

function Torch:GetId(): string?
	if self._tool_data then
		return self._tool_data.Id
	end
	return
end

function Torch:Equip(): Instance
	self:EventHandler()
	self._maid.BaseTool:Equip()
	return self._maid.BaseTool:GetTool()
end

function Torch:Unequip(): nil
	self._toggled = false
	self._connection_maid:DoCleaning()
	self._maid.BaseTool:Unequip()
	self:ToggleEffects(false)
	return
end

function Torch:Destroy(): nil
	self._toggled = false
	self._connection_maid:DoCleaning()
	self._maid:DoCleaning()
	self:ToggleEffects(false)
	self._toggled = nil
	self._maid = nil
	self = nil
	return
end

function Torch.new(player, player_object, tool_data)
	local self = setmetatable({}, Torch)

	self.Core = _G.Core
	self._toggled = false

	self._connection_maid = self.Core.Utils.Maid.new()
	self._maid = self.Core.Utils.Maid.new()

	self._player = player
	self._tool_data = tool_data
	self._player_object = player_object

	self._maid.BaseTool = self.Core.Components[BASE_TOOL_PATH].new(player, tool_data)

	self._maid.NetObject = self.Core.Utils.Net.CreateTemp(self.Core.Utils.Maid)

	if self._tool_data.EffectData then
		self._toggled_effects = self._tool_data.EffectData.Server.Toggle

		self._maid.EffectObject = self.Core.EffectManager.Create(tool_data.EffectPath)

		self._tool_effect_part =
			self.Core.Utils.UtilityFunctions.FindObjectWithPath(self._maid.BaseTool:GetTool(), tool_data.EffectPartPath)
	end

	if self._tool_data.SoundData then
		self._maid.SoundObject = self.Core.SoundManager.Create(self._tool_data.SoundPath)

		if self._tool_data.SoundData.Server.Toggled then
			self._maid._toggled_sound = self._maid.SoundObject:CloneSound(
				self._tool_data.SoundData.Server.Toggled.Name,
				self._maid.BaseTool:GetTool()
			)
		end

		if self._tool_data.SoundData.Server.ToggleOn then
			self._maid._toggle_on_sound = self._maid.SoundObject:CloneSound(
				self._tool_data.SoundData.Server.ToggleOn.Name,
				self._maid.BaseTool:GetTool()
			)
		end
		if self._tool_data.SoundData.Server.ToggleOff then
			self._maid._toggle_off_sound = self._maid.SoundObject:CloneSound(
				self._tool_data.SoundData.Server.ToggleOff.Name,
				self._maid.BaseTool:GetTool()
			)
		end
	end

	return self
end

return Torch
