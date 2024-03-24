local InstanceLooper = {}
InstanceLooper.__index = InstanceLooper

function InstanceLooper:GetNext()
	local next_free = self:Peek()
	if next_free then
		self._items[next_free[1]][1] = false
		self._callback_remove(next_free[2])
		delay(self._cooldown, function()
			self._callback_add(next_free[2])
			self._items[next_free[1]][1] = true
		end)
	else
		print("NONE FREE!")
	end
end

function InstanceLooper:Peek()
	for item_num, i in self._items do
		if i[1] then
			return { item_num, i[2] }
		end
	end

	return nil
end

function InstanceLooper.new(instance_array, callback1, callback2, cooldown)
	local self = setmetatable({}, InstanceLooper)
	self._items = {}
	self._cooldown = if cooldown then cooldown else 3
	for _, i in instance_array do
		table.insert(self._items, { true, i }) -- {available, instance}
	end
	print(self._items)
	self._callback_remove = callback1
	self._callback_add = callback2
	return self
end

function InstanceLooper:Destroy(): nil
	return
end

return InstanceLooper
