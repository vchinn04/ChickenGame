local TimedFunction = {}
TimedFunction.__index = TimedFunction
--[[
	<description>
		This class is responsible for handling timed functions which are called after _interval time passes. 
		Useful for things like recursive timers E.g hunger, bleeding, respawn
	</description> 
	
	<API>
		TimedFunctionObj:StartTimer(callback: () -> (), duration: number?) ---> nil
			-- Start a timed function which calls "callback" when _interval amount of time passed. 
			callback: () -> () -- Is called after _interval amount of time passes
			duration: number? -- If duration is passed, it is checked against 0. If it is <= 0 then the timer is cancelled.

	  	TimedFunctionObj:CancelTimer() ---> nil
			-- Cancel current timer and if _on_cancel_callback exists, call it.

		TimedFunctionObj:Destroy() ---> nil
			-- Destroy TimedFunctionObj and call _destroy_callback if it exists as well.
				WARNING: if _on_cancel_callback exists as well, it is called
			
		TimedFunction.new(interval: number?, on_cancel_callback: () -> (), destroy_callback: () -> ()) ---> TimedFunctionObj
			-- Create a new TimedFunctionObj
			interval: number? -- Custom interval, in seconds. DEFAULT is 1
			on_cancel_callback: () -> () -- Called whenever CancelTimer() is called
			destroy_callback: () -> () -- Called whenever Destroy() is called
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function TimedFunction:StartTimer(callback: () -> (), duration: number?): nil
	if self._timer then
		self._timer:cancel()
	end

	self._timer = self.Core.Utils.Promise.delay(self._interval)

	if duration ~= nil and duration <= 0 then
		self:CancelTimer()
		return
	end

	self._timer:andThen(callback)
	return
end

function TimedFunction:CancelTimer(): nil
	if self._timer then
		self._timer:cancel()
	end

	self._timer = nil

	if self._on_cancel_callback then
		self._on_cancel_callback()
	end

	return
end

function TimedFunction:Destroy(): nil
	self:CancelTimer()
	if self._destroy_callback then
		self._destroy_callback()
	end
	self._destroy_callback = nil
	self._interval = nil
	self = nil
	return
end

function TimedFunction.new(interval: number?, on_cancel_callback: () -> (), destroy_callback: () -> ())
	local self = setmetatable({}, TimedFunction)
	self.Core = _G.Core

	if not interval then
		interval = 1
	end

	self._interval = interval
	self._destroy_callback = destroy_callback
	self._on_cancel_callback = on_cancel_callback

	return self
end

return TimedFunction
