local MouseHover = {}
MouseHover.__index = MouseHover

function MouseHover:Destroy(): nil
	return
end

function MouseHover.new()
	local self = setmetatable({}, MouseHover)

	return self
end

return MouseHover
