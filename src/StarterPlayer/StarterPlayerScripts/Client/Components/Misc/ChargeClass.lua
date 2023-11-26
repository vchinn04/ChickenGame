local ChargeClass = {}
ChargeClass.__index = ChargeClass
--[[
	<description>
		This class provides a way to interporlate between 0 and a specified threshold in a 
		specified duration. For every iteration a user can specify an update_callback and a callback
		to be called at the end of the "charge". 

		WARNING: This should only be used if an "update_callback" is neccessary. Use Promise.delay() or 
		another alternative if only a final callback is needed, that is, an update does not have to occur 
		every RenderStep. 
	</description> 
	
	<API>
	 	ChargeClassObject:GetCharge(): number
			-- Return the current _charge value

		ChargeClassObject:Charge(threshold: number, duration: number, update_func: (number) -> nil, callback: (number) -> nil) ---> nil
			-- Create a charge connection using RunService Heartbeat, call update_func per iteration and callback at end.
			duration : number -- The duration charging should take. 
			threshold : number -- The upper bound of the charge limit. Will be reached in "duration" (starting from 0)
			update_func : (number) -> nil -- This function will be passed in every Heartbeat, including the final one (when reaching threshold)
											 The current charge at that iteration is passed in as argument. 
			callback : (number) -> nil -- This function is called at the final iteration when _charge reaches "threshold". The current charge is passed 
										   as argument (equivalent to threshold).

		ChargeClassObject:CancelCharge() ---> nil
			-- Disconnect the charge connection and reset _charge to 0. 
		
		ChargeClass.new() --> ChargeClassObject
			-- Create and return a ChargeClassObject. Instantiate _charge with 0.
			
		ChargeClassObject:Destroy() --> void
			-- Destroy ChargeClassObject object and cancel connections.
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local RunService = game:GetService("RunService")

--*************************************************************************************************--

function ChargeClass:GetCharge(): number
	return self._charge
end

function ChargeClass:Charge(
	threshold: number,
	duration: number,
	update_func: (number) -> nil,
	callback: (number) -> nil
): nil
	self._connection_maid.ChargeConnection = RunService.Heartbeat:Connect(function(dt)
		self._charge += dt / duration * 100
		update_func(self._charge)
		if self._charge >= threshold then
			self:CancelCharge()
			self._charge = threshold
			callback(self._charge)
		end
	end)
	return
end

function ChargeClass:CancelCharge(): nil
	self._charge = 0
	self._connection_maid.ChargeConnection = nil
	return
end

function ChargeClass.new(): {}
	local self = setmetatable({}, ChargeClass)
	self.Core = _G.Core
	self._charge = 0
	self._connection_maid = self.Core.Utils.Maid.new()
	return self
end

--[[
	<description>
		Destroy instance of ChargeClass. Clear the table 
		and self.
	</description> 	
--]]
function ChargeClass:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._connection_maid = nil
	self = nil
	return
end

return ChargeClass
