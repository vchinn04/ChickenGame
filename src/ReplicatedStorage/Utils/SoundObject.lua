local SoundObject = {}
SoundObject.__index = SoundObject

function SoundObject:GetSound(sound: string): Sound?
	if typeof(sound) == "Instance" then
		self._sounds[sound] = sound
		return sound
	end
	local sound_object = self._sounds[sound]
	if sound_object then
		return sound_object
	end

	sound_object = self._folder:WaitForChild(sound, 10)
	self._sounds[sound] = sound_object
	return sound_object
end

function SoundObject:CloneSound(sound_name: string, sound_parent): Sound?
	local sound = self:GetSound(sound_name)
	if sound then
		local clone_sound = sound:Clone()
		clone_sound.Parent = sound_parent
		return clone_sound
	end
	return
end

function SoundObject:PlayAndDestroy(sound_name: string | Sound)
	local sound = self:Play(sound_name)
	local end_connection = nil
	if sound then
		end_connection = sound.Ended:Connect(function()
			end_connection:Disconnect()
			sound:Destroy()
		end)
	end
end

function SoundObject:SetLooping(sound_name: string | Sound, status: boolean): nil
	local sound = self:GetSound(sound_name)
	if sound then
		sound.Looped = status
	end
	return
end

function SoundObject:SinglePlay(sound_name: string | Sound): nil
	local sound = self:GetSound(sound_name)
	if sound then
		self:SetLooping(sound_name, false)
		sound:Play()
		return sound
	end
	return
end

function SoundObject:Play(sound_name: string | Sound): Sound?
	local sound = self:GetSound(sound_name)
	if sound then
		sound:Play()
		return sound
	end
	return
end

function SoundObject:Stop(sound_name: string | Sound): nil
	local sound = self:GetSound(sound_name)
	if sound then
		sound:Stop()
	end
end

function SoundObject:StopAll(): nil
	for _, sound in self._sounds do
		sound:Stop()
	end
	return
end

function SoundObject:Destroy(): nil
	self:StopAll()
	return
end

return SoundObject
