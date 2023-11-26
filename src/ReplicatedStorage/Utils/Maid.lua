---	Manages the cleaning of events and other things.
-- Useful for encapsulating state and make deconstructors easy
-- @classmod Maid
-- @see Signal
local ContextActionService = game:GetService("ContextActionService")
local Maid = {}
Maid.ClassName = "Maid"

--- Returns a new Maid object
-- @constructor Maid.new()
-- @treturn Maid
function Maid.new()
	return setmetatable({
		_tasks = {},
		__bind_action_names = {},
	}, Maid)
end

function Maid.isMaid(value)
	return type(value) == "table" and value.ClassName == "Maid"
end

--- Returns Maid[key] if not part of Maid metatable
-- @return Maid[key] value
function Maid:__index(index)
	if Maid[index] then
		return Maid[index]
	else
		return self._tasks[index]
	end
end

--- Add a task to clean up. Tasks given to a maid will be cleaned when
--  maid[index] is set to a different value.
-- @usage
-- Maid[key] = (function)         Adds a task to perform
-- Maid[key] = (event connection) Manages an event connection
-- Maid[key] = (Maid)             Maids can act as an event connection, allowing a Maid to have other maids to clean up.
-- Maid[key] = (Object)           Maids can cleanup objects with a `Destroy` method
-- Maid[key] = nil                Removes a named task. If the task is an event, it is disconnected. If it is an object,
--                                it is destroyed.
function Maid:__newindex(index, newTask)
	if Maid[index] ~= nil then
		error(("'%s' is reserved"):format(tostring(index)), 2)
	end

	local tasks = self._tasks
	local oldTask = tasks[index]

	if oldTask == newTask then
		return
	end

	tasks[index] = newTask

	if oldTask then
		if type(oldTask) == "function" then
			oldTask()
		elseif typeof(oldTask) ~= "RBXScriptConnection" and oldTask.Destroy ~= nil then
			oldTask:Destroy()
		elseif typeof(oldTask) == "RBXScriptConnection" or (type(task) == "table" and oldTask.Disconnect ~= nil) then
			oldTask:Disconnect()
		elseif type(oldTask) == "table" and oldTask.disconnect ~= nil then
			oldTask:disconnect()
		end
	end
end

--- Same as indexing, but uses an incremented number as a key.
-- @param task An item to clean
-- @treturn number taskId
function Maid:GiveTask(task)
	if not task then
		error("Task cannot be false or nil", 2)
	end

	local taskId = #self._tasks + 1
	self[taskId] = task

	if (type(task) == "table" and (task.Disconnect ~= nil and task.disconnect ~= nil)) and task.Destroy ~= nil then
		warn("[Maid.GiveTask] - Gave table task without .Destroy\n\n" .. debug.traceback())
	end

	return taskId
end

function Maid:GivePromise(promise)
	if not promise:IsPending() then
		return promise
	end

	local newPromise = promise.resolved(promise)
	local id = self:GiveTask(newPromise)

	-- Ensure GC
	newPromise:Finally(function()
		self[id] = nil
	end)

	return newPromise
end

--- Cleans up all tasks.
-- @alias Destroy
function Maid:DoCleaning()
	local tasks = self._tasks

	-- Disconnect all events first as we know this is safe
	for index, task in pairs(tasks) do
		if typeof(task) == "RBXScriptConnection" then
			tasks[index] = nil
			task:Disconnect()
		end
	end

	-- Clear out tasks table completely, even if clean up tasks add more tasks to the maid
	local index, task = next(tasks)
	while task ~= nil do
		tasks[index] = nil
		if type(task) == "function" then
			task()
		elseif typeof(task) ~= "RBXScriptConnection" and task.Destroy ~= nil then
			task:Destroy()
		elseif typeof(task) == "RBXScriptConnection" or (type(task) == "table" and task.Disconnect ~= nil) then
			task:Disconnect()
		elseif type(task) == "table" and task.disconnect ~= nil then
			task:disconnect()
		end
		index, task = next(tasks)
	end

	for ind, action_name in self.__bind_action_names do
		self.__bind_action_names[ind] = nil
		ContextActionService:UnbindAction(action_name)
	end
end

--- Add a BindAction name to a list which will be unbound when DoCleaning() is called
function Maid:GiveBindAction(action_name)
	local taskId = #self.__bind_action_names + 1
	self.__bind_action_names[taskId] = action_name
end

--- Alias for DoCleaning()
-- @function Destroy
Maid.Destroy = Maid.DoCleaning

return Maid
