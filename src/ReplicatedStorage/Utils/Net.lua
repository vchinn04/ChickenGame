local Net = {}
local RunService = game:GetService("RunService")

local Events = {}
local TempNet = {}
TempNet.__index = TempNet

function TempNet:RemoteEvent(name: string, obj: any?): RemoteEvent
	name = "RE/" .. name
	if RunService:IsServer() then
		local r = Events[name]
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = name
			local parent_ob = if obj ~= nil then obj else script
			r.Parent = parent_ob
			Events[name] = r
			table.insert(self._remotes, name)
		end
		return r
	end
	return
end

function TempNet:RemoteFunction(name: string, obj: any?): RemoteEvent
	name = "RF/" .. name
	local parent_ob = if obj ~= nil then obj else script

	if RunService:IsServer() then
		local r = Events[name]
		if not r then
			r = Instance.new("RemoteFunction")
			r.Name = name
			r.Parent = parent_ob
			Events[name] = r
			table.insert(self._remotes, name)
		end
		return r
	end
	return
end

function TempNet:Destroy(): nil
	self._maid:DoCleaning()

	for _, remote in self._remotes do
		local event = Events[remote]
		Events[remote] = nil
		if event then
			event:Destroy()
		end
	end

	self._remotes = nil
	self._maid = nil
	self = nil
	return
end

function Net.CreateTemp(Maid)
	local self = setmetatable({}, TempNet)
	self._remotes = {}
	self._maid = Maid.new()
	return self
end

function Net:RemoteEvent(name: string, obj: any?): RemoteEvent
	name = "RE/" .. name
	if RunService:IsServer() then
		local r = Events[name]
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = name
			local parent_ob = if obj ~= nil then obj else script
			r.Parent = parent_ob
			Events[name] = r
		end
		return r
	else
		local parent_ob = if obj ~= nil then obj else script
		local r = parent_ob:WaitForChild(name, 10)
		if not r then
			error("Failed to find RemoteEvent: " .. name, 2)
		end
		return r
	end
end

function Net:RemoteFunction(name: string, obj: any?): RemoteFunction
	name = "RF/" .. name
	local parent_ob = if obj ~= nil then obj else script

	if RunService:IsServer() then
		local r = Events[name]
		if not r then
			r = Instance.new("RemoteFunction")
			r.Name = name
			r.Parent = parent_ob
			Events[name] = r
		end
		return r
	else
		local r = Events[name] or parent_ob:WaitForChild(name, 10)
		if not r then
			warn("Failed to find RemoteFunction: " .. name, 2)
		end
		return r
	end
end

function Net:Destroy()
	script:ClearAllChildren()
end

return Net
