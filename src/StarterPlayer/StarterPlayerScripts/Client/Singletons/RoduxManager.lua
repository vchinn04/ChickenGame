local StateManager = {
	Name = "StateManager",
}
--[[
	<description>
		This manager is responsible for managing the global client state.
	</description> 
	
	<API>
		StateManager.ActionDefaultState() ---> {[string] : any}
			-- Return the default actions global state for client. A dictionary.
			
		StateManager.InteractionDefaultState() ---> {[string] : any}
			-- Return the default interaction global state for client. A dictionary.

		StateManager.ToolsDefaultState() ---> { [string]: any }
			-- Return the default tools global state for client. A dictionary.

		StateManager.GetMovementAbility(state : {[string] : any}) 
			-- Return whether any of the entries in state with index in MovementAbilities is true, else return false
			-- Used to set the MovementAbility state
			
		StateManager.ActionReducer(old_state : {[string] : any}, action : {type : string, [string] : any}) : {[string] : any}
			-- Handle the actions sent to action Store. 
			old_state : {[string] : any} -- Old state of store
			action : {type : string, [string] : any} -- the action to process. type : name of action, parameters for that actions.
			-- returns new state

		StateManager.InteractionReducer(old_state : {[string] : any}, action : {type : string, [string] : any}) : {[string] : any}
			-- Handle the actions sent to interaction Store. 
			old_state : {[string] : any} -- Old state of store
			action : {type : string, [string] : any} -- the action to process. type : name of action, parameters for that actions.
			-- returns new state

		StateManager.ToolsReducer(old_state : {[string] : any}, action : {type : string, [string] : any}) : {[string] : any}
			-- Handle the actions sent to tools Store. 
			old_state : {[string] : any} -- Old state of store
			action : {type : string, [string] : any} -- the action to process. type : name of action, parameters for that actions.
			-- returns new state
			
		StateManager.EventHandler() : nil
			-- Handle incoming events for modifying states
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local MOVEMENT_ABILITIES = {
	"Sprinting",
	"Slide",
}

local Core
local Maid

local Current_Multipliers = {}
--*************************************************************************************************--

function StateManager.ActionDefaultState(): { [string]: any }
	return {
		Sprinting = false,
		Grounded = true,
		Stamina = 100,
		WalkSpeedMultiplier = 1,
	}
end

function StateManager.InteractionDefaultState(): { [string]: any }
	return {
		Hold = false,
		Tree = false,
		Bandage = false,
	}
end

function StateManager.ToolsDefaultState(): { [string]: any }
	return {
		EquippedItem = nil,
	}
end

function StateManager.GetMovementAbility(state: { [string]: any })
	for _, index: string in MOVEMENT_ABILITIES do
		if state[index] then
			return true
		end
	end

	return false
end

function StateManager.AdjustMultiplier(multiplier_name: string, multiplier: number)
	Current_Multipliers[multiplier_name] = multiplier

	local new_multiplier: number = 1
	for _, mult: number in Current_Multipliers do
		new_multiplier *= mult
	end

	return new_multiplier
end

function StateManager.ActionReducer(
	old_state: { [string]: any },
	action: { type: string, [string]: any }
): { [string]: any }
	local state = table.clone(old_state)
	local action_type: string = action.type
	if action_type == "ResetStore" then
		return action.new_state
	end

	if action_type == "Sprinting" then
		state.Sprinting = action.Sprinting
	elseif action_type == "Stamina" then
		state.Stamina = action.Stamina
	elseif action_type == "Grounded" then
		state.Grounded = action.Grounded
	elseif action_type == "SpeedAction" then
		state.WalkSpeedMultiplier = StateManager.AdjustMultiplier(action.name, action.Value)
	end

	return state
end

function StateManager.InteractionReducer(
	old_state: { [string]: any },
	action: { type: string, [string]: any }
): { [string]: any }
	local action_type: string = action.type
	if action_type == "ResetStore" then
		return action.new_state
	end

	if action_type == "Tree" then
		old_state.Tree = action.Tree
	elseif action_type == "Ore" then
		old_state.Ore = action.Ore
	elseif action_type == "Hold" then
		old_state.Hold = action.Hold
	elseif action_type == "Bandage" then
		old_state.Bandage = action.Bandage
	elseif action_type == "Basket" then
		old_state.Basket = action.Basket
	end

	return old_state
end

function StateManager.ToolsReducer(
	old_state: { [string]: any },
	action: { type: string, [string]: any }
): { [string]: any }
	local state = {}

	local action_type: string = action.type
	if action_type == "ResetStore" then
		return StateManager.ToolsDefaultState()
	end

	if action_type == "Equip" then
		state.EquippedItem = action.Item
	end

	return state
end

function StateManager.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("SpeedAction", function(action_name: string, multiplier: number?)
		Core.ActionStateManager:dispatch({ type = "SpeedAction", name = action_name, Value = multiplier })
	end))

	Maid:GiveTask(Core.Subscribe("Sprint", function(status: string)
		Core.ActionStateManager:dispatch({ type = "Sprinting", Sprinting = status })
	end))

	Maid:GiveTask(Core.Subscribe("Grounded", function(status: string)
		Core.ActionStateManager:dispatch({ type = "Grounded", Grounded = status })
	end))

	Maid:GiveTask(Core.Subscribe("Stamina", function(new_stamina: string)
		Core.ActionStateManager:dispatch({ type = "Stamina", Stamina = new_stamina })
	end))

	Maid:GiveTask(Core.Subscribe("Tree", function(status: string, ...)
		Core.InteractionStateManager:dispatch({ type = "Tree", Tree = status })
	end))

	Maid:GiveTask(Core.Subscribe("Ore", function(status: string, ...)
		Core.InteractionStateManager:dispatch({ type = "Ore", Ore = status })
	end))

	Maid:GiveTask(Core.Subscribe("Bandage", function(status: string, ...)
		Core.InteractionStateManager:dispatch({ type = "Bandage", Bandage = status })
	end))

	Maid:GiveTask(Core.Subscribe("Basket", function(status: string, ...)
		Core.InteractionStateManager:dispatch({ type = "Basket", Basket = status })
	end))

	Maid:GiveTask(Core.Subscribe("HoldInteraction", function(status: string, ...)
		if Core.InteractionStateManager:getState().Hold == status then
			return
		end
		Core.InteractionStateManager:dispatch({ type = "Hold", Hold = status })
	end))

	Maid:GiveTask(Core.Subscribe("ItemEquip", function(item_id: string, ...)
		if Core.Player:GetAttribute("Stun") then
			return
		end
		Core.ToolsStateManager:dispatch({ type = "Equip", Item = item_id })
	end))

	return
end

function StateManager.Start(): nil
	Core.ActionStateManager:dispatch({ type = "ResetStore", new_state = StateManager.ActionDefaultState() })
	Core.InteractionStateManager:dispatch({ type = "ResetStore", new_state = StateManager.InteractionDefaultState() })
	Core.ToolsStateManager:dispatch({ type = "ResetStore", new_state = StateManager.InteractionDefaultState() })

	StateManager.EventHandler()

	return
end

function StateManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
	return
end

function StateManager.Reset(): nil
	Maid:DoCleaning()
	return
end

return StateManager
