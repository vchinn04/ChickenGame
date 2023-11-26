local CooldownClass = {}
CooldownClass.__index = CooldownClass
--[[
	<description>
		This component is responsible for handling cooldowns. The default cooldown is 
		1 second, however, one can add their own custom cooldowns
	</description> 
	
	<API>
		CooldownClass:IsOver(cooldown_name: string) ---> boolean 
			-- Check if the current cooldown is over. 
			-- Returns true if there is no active cooldown or time passed since last set is longer than cooldown  

		CooldownClass:OneTimeCooldown(cooldown_name: string, cooldown_duration: number) ---> nil
			-- Add a custom cooldown duration for a single time. Only is set if there is no current cooldown or the custom cooldown 
			-- is longer than the ongoing cooldown. 
			cooldown_name: string ---> Name of the cooldown to set 
			cooldown_duration: number ---> Custom duration to set to 

		CooldownClass.new() --> CooldownObj
			-- Creates a ToolObj given the tool data and tool instance. 
			tool_obj : Tool -- Tool instance player is equipping 
			tool_data : table -- Table with tool data. Look: ReplicatedStorage/Utils/ItemDataManager
			
		CooldownObj:CheckCooldown(cooldown_val : string) --> bool
			-- Sets up connections needed to use the tool and plays equip animation if provided 
			-- returns true if cooldown is ONGOING, and false if cooldown is OVER 
			cooldown_val : string -- the name of the cooldown you are checking 
			
		CooldownObj:Destroy() --> void
			-- clear cooldowns and destroy object
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local DEFAULT_COOLDOWN = 1

export type CooldownClassType = {
	_cooldown_table: {
		Cooldowns: typeof(setmetatable({}, {
			__index = function()
				return DEFAULT_COOLDOWN
			end,
		})),
		Timers: { [string]: number },
	},
	CheckCooldown: (string) -> boolean,
	Destroy: () -> nil,
}
--*************************************************************************************************--
local CustomCooldowns = {}

function CooldownClass:IsOver(cooldown_name: string): boolean
	if not self._cooldown_table.Timers[cooldown_name] then
		return true
	end
	return (os.clock() - self._cooldown_table.Timers[cooldown_name]) >= self._cooldown_table.Cooldowns[cooldown_name]
end

function CooldownClass:OneTimeCooldown(cooldown_name: string, cooldown_duration: number): nil
	local current_timer_entry = self._cooldown_table.Timers[cooldown_name]
	local cooldown_default_duration = self._cooldown_table.Cooldowns[cooldown_name]
	local cooldown_entry = os.clock() + cooldown_duration - cooldown_default_duration

	if not current_timer_entry or self:IsOver(cooldown_name) then
		self._cooldown_table.Timers[cooldown_name] = cooldown_entry
		CustomCooldowns[cooldown_name] = os.clock()
		return
	end

	local cooldown_leftover = cooldown_default_duration - math.abs(os.clock() - current_timer_entry)

	if cooldown_leftover < cooldown_duration then
		self._cooldown_table.Timers[cooldown_name] = cooldown_entry
		CustomCooldowns[cooldown_name] = os.clock()
	end
	return
end

--[[
	<description>
		Check the cooldown, the default is 1. If the cooldown is NOT over
		return true, else return false and reset cooldown.
	</description> 
	
	<parameter name="cooldown_val">
		Type: string
		Description: name of the cooldown variable 
	</parameter 
	
	<Return>
		True if in cooldown, False if no cooldown 
	</Return>
--]]
function CooldownClass:CheckCooldown(cooldown_val: string): boolean
	if not self._cooldown_table.Timers[cooldown_val] or (self:IsOver(cooldown_val)) then -- If there is no "Timers" entry in the table that means the deboucne was never triggered, so create a "Timers" entry and return false, or if the time elapsed from the last "Timers" entry is greater or equal to the debounce value then reset the "Timers" entry and return false.
		self._cooldown_table.Timers[cooldown_val] = os.clock()
		if CustomCooldowns[cooldown_val] then
			print("Custom Cooldown: ", os.clock() - CustomCooldowns[cooldown_val])
			CustomCooldowns[cooldown_val] = nil
		end
		return false
	else -- Debounce is not over yet, have to wait, return true!
		return true
	end
end

--[[
	<description>
		Create an instance of CooldownClass.
		Can pass in a 2D array of custom cooldowns.
	</description> 
	
	<parameter name="custom_cooldowns">
		Type: table
		A 2D array of custom cooldowns in form {"cooldown_name" : string, cooldown_num : number}
	</parameter 
	
	<Return>
		CooldownClass Instance
	</Return>
--]]
function CooldownClass.new(custom_cooldowns: { [number]: { [number]: string | number } }): CooldownClassType
	local self = setmetatable({}, CooldownClass)

	--[[
	 	This is the debounce/cooldown table. By default, the cooldown length is 1 second. You cann simply add your own value to the Cooldowns dict to overwrite the default.
	 	How to use:
		1. If needed add custom entry to Cooldowns dict:
			Cooldowns{
				cooldown_name = length : number
			}
		2. To use the cooldown (custom or default) simply call: 
			CheckCooldown(cooldown_name : string)
		3. Note: You have to use the same cooldown_name to access the same debounce! 
	--]]
	self._cooldown_table = {
		Cooldowns = setmetatable({}, {
			__index = function()
				return DEFAULT_COOLDOWN
			end,
		}),

		Timers = {},
	}

	if custom_cooldowns then
		for _, custom_cool: { [number]: string | number } in custom_cooldowns do
			self._cooldown_table.Cooldowns[custom_cool[1]] = custom_cool[2]
		end
	end

	return self
end

--[[
	<description>
		Destroy instance of CooldownClass. Clear the table 
		and self.
	</description> 	
--]]
function CooldownClass:Destroy(): nil
	self._cooldown_table = nil
	self = nil
	return
end

return CooldownClass
