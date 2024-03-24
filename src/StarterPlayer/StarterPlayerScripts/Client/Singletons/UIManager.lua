local UIManager = {
	Name = "UIManager",
}
--[[
	<description>
		This manager is responsible for managing the UI objects.
	</description> 
	
	<API>
		UIManager.OpenUI(ui_name: string)
			-- Open the current UI, create an object of its type and mount it 
			ui_name : string ---> Name of the UI to open
			init_prop : any ---> Any single property that is passed to the UI class instance. Can be any type including table. 

		UIManager.CloseUI(ui_name: string)
			-- Close the current UI, remove it from the object table 
			ui_name : string ---> Name of the UI to close
		
		UIManager.Blind(duration: number) ---> nil
			-- Create a "blinding" effect that lasts a specified duration 
			duration : number -- Duration it takes for the blinding screen to fade away

		UIManager.ShaderAdjust(duration: number, size: UDim2, transparency: number) ---> nil
			-- Adjust the shader border screen frame (E.g. for sprint and taking aim)
			duration : number -- Duration it takes to change size 
			size : UDim2 -- New size of border frame 
			transparency : number -- New transparency of shader frame

		UIManager.GetCursorBar() ---> CursorBarObject
			-- Return the cursor bar object, if it doesn't exist, create it. Used 
			for things like displaying charge status and cooldowns (follows cursor.)

		UIManager.GetCompass(): nil ---> CompassObject
			-- Return a newly created and mounted compass UI object. Display directions.

		UIManager.GetPocketWatch() ---> WatchObject
			-- Return a newly created and mounted pocket watch UI object. Display minutesaftermidnight.
			aka. game time 

		UIManager.ClearUI() : nil
			-- Clear all the UIs and make Maid destroy all objectsd.

		UIManager.Blind(duration: number): nil
			-- Blind the user for a certain duration (it takes 0.15 to tween in, and duration is the time it takes to disappear)
			duration : number ---> Time it takes for blinding effect to disappear. 

	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]
local TweenService = game:GetService("TweenService")
local Core
local Maid
local UIObjTable = {}

-- In charge of lazily loading in the UI classes when requested and throwing a warning if not class found
local UIClasses = {}

-- setmetatable({}, {
-- 	__index = function(self, obj_index)
-- 		local succ, res = pcall(function()
-- 			local ui_class = Core.Utils.UtilityFunctions.FindObjectWithPath(Core.Classes.UI, obj_index)
-- 			if ui_class then
-- 				local Obj = require(ui_class)
-- 				self[obj_index] = Obj
-- 				return Obj
-- 			end
-- 		end)

-- 		if succ then
-- 			return res
-- 		else
-- 			warn("UI OBJ: ", obj_index, " ERROR! ERROR: ", res)
-- 			return nil
-- 		end
-- 	end,
-- })

local BLIND_TRANSPARENCY: number = 0.45

local DEFAULT_ZOOM_SHADER_SIZE: UDim2 = UDim2.new(1.05, 0, 1.05, 0)
local DEFAULT_SHADER_SIZE: UDim2 = UDim2.new(1.15, 0, 1.15, 0)
local DEFAULT_SHADER_TRANSPARENCY: number = 0.15
local DEFAULT_SHADER_ADJUST_DURATION: number = 0.25
--*************************************************************************************************--

function UIManager.GetUI(ui_name: string): {}?
	local frame = UIClasses[ui_name]

	if frame then
		return frame
	end

	local succ, res = pcall(function()
		local ui_class = Core.Utils.UtilityFunctions.FindObjectWithPath(Core.Classes.UI, ui_name)
		if ui_class then
			local Obj = require(ui_class)
			UIClasses[ui_name] = Obj
			return Obj
		end
	end)

	if succ then
		if res then
			return res
		else
			warn("UI OBJ: ", ui_name, " NOT FOUND!")
			return nil
		end
	else
		warn("UI OBJ: ", ui_name, " ERROR! ERROR: ", res)
		return nil
	end
end

-- Open the current UI, create an object of its type and bring it to screen if TransformEnter exists
--ui_name ---> Name of the UI to open
function UIManager.OpenUI(ui_name: string, init_prop: any?): nil
	local Class = UIManager.GetUI(ui_name) -- UIClasses[ui_name] -- get the Class of the UI!

	if Class then
		local ui_type = Class.UIType and Class.UIType or "Default"

		Maid[ui_type] = Class.new(init_prop) -- Don't forget to add it to Maid!
		UIObjTable[ui_name] = ui_type -- Map the UI name to its type

		if (Maid[ui_type]).mount then
			(Maid[ui_type]):mount()
		end
	end
	return
end

--Close the current UI, remove it from the object table
--ui_name ---> Name of the UI to close
function UIManager.CloseUI(ui_name: string): nil
	if UIObjTable[ui_name] then
		local ui_type = UIObjTable[ui_name]
		UIObjTable[ui_name] = nil
		Maid[ui_type] = nil
	end
	return
end

function UIManager.Blind(duration: number): nil
	local Class = UIManager.GetUI("BlindScreen") -- UIClasses["BlindScreen"]

	if Class then
		local blind_object = Class.new()
		local blind_frame: Frame? = blind_object:mount():get()

		local blind_tween_in: Tween =
			TweenService:Create(blind_frame, TweenInfo.new(0.15), { BackgroundTransparency = BLIND_TRANSPARENCY })
		local blind_tween_out: Tween =
			TweenService:Create(blind_frame, TweenInfo.new(duration), { BackgroundTransparency = 1 })

		Core.Utils.Promise
			.new(function(resolve, _, _)
				blind_tween_in:Play()
				blind_tween_in.Completed:Wait()
				resolve()
			end)
			:andThen(function()
				return Core.Utils.Promise.new(function(resolve)
					blind_tween_out:Play()
					blind_tween_out.Completed:Wait()
					resolve()
				end)
			end)
			:finally(function()
				blind_frame = nil
				blind_object:Destroy()
			end)
	end

	return
end

function UIManager.ShaderAdjust(duration: number, size: UDim2, transparency: number): nil
	local shader_frame: Frame = Maid.ShaderObject:GetFrameObject():get()

	if shader_frame then
		TweenService:Create(shader_frame, TweenInfo.new(duration), { Size = size, ImageTransparency = transparency })
			:Play()
	end

	return
end

function UIManager.GetCursorBar(): {}?
	local CursorBarClass = UIManager.GetUI("CursorBar") -- UIClasses["CursorBar"]

	if CursorBarClass then
		local cursor_bar_object = CursorBarClass.new()
		cursor_bar_object:mount()
		return cursor_bar_object
	end

	return
end

function UIManager.EventHandler(): nil
	Maid:GiveTask(Core.Subscribe("OpenUI", function(ui_name: string, init_prop: any?)
		UIManager.OpenUI(ui_name, init_prop)
	end))

	Maid:GiveTask(Core.Subscribe("Blind", function(duration: number)
		UIManager.Blind(duration)
	end))

	-- Maid:GiveTask(Core.Subscribe("TakeAim", function(status: boolean, _): nil
	-- 	if status then
	-- 		UIManager.ShaderAdjust(DEFAULT_SHADER_ADJUST_DURATION, DEFAULT_ZOOM_SHADER_SIZE, 0)
	-- 	else
	-- 		UIManager.ShaderAdjust(DEFAULT_SHADER_ADJUST_DURATION, DEFAULT_SHADER_SIZE, DEFAULT_SHADER_TRANSPARENCY)
	-- 	end
	-- 	return
	-- end))

	-- Maid:GiveTask(Core.Subscribe("Sprint", function(status: string): nil
	-- 	if status then
	-- 		UIManager.ShaderAdjust(DEFAULT_SHADER_ADJUST_DURATION, DEFAULT_ZOOM_SHADER_SIZE, 0)
	-- 	else
	-- 		UIManager.ShaderAdjust(DEFAULT_SHADER_ADJUST_DURATION, DEFAULT_SHADER_SIZE, DEFAULT_SHADER_TRANSPARENCY)
	-- 	end
	-- 	return
	-- end))
	return
end

function UIManager.Start(): nil
	-- Maid.HUD = UIManager.GetUI("HUDUI/HUD").new() --  UIClasses["HUDUI/HUD"].new()
	-- Maid.HUD:mount()

	-- local ShaderClass = UIClasses["Shader"]

	-- if ShaderClass then
	-- 	Maid.ShaderObject = ShaderClass.new()
	-- 	Maid.ShaderObject:mount()
	-- end

	UIManager.EventHandler()
	return
end

function UIManager.Init(): nil
	Core = _G.Core
	Maid = Core.Utils.Maid.new()

	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	Core.Subscribe("PlayerDeath", function()
		print("Player Died")
		if not Maid.DeathScreen then
			Maid.DeathScreen = UIClasses["RespawnScreen"].new()
		end
		Maid.DeathScreen:mount()
	end)

	return
end

-- Clear all the UIs and make Maid destroy all objects
function UIManager.ClearUI(): nil
	Maid:DoCleaning()

	for ind, Obj in UIObjTable do
		-- Obj:Destroy()
		UIObjTable[ind] = nil
		print(ind, Obj)
	end

	return
end

function UIManager.Reset(): nil
	UIManager.ClearUI()
	-- UIManager.OpenUI("HUB")
	return
end

return UIManager
