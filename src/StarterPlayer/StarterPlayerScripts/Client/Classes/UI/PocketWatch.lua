local Watch = {}
Watch.__index = Watch

--[[
	<description>
		This class provides the functionalities for pocket watch UI.
	</description> 
	
	<API>
		WatchObj:mount()
			-- Mount the UI, make it transparent

		WatchObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Watch.new() --> WatchObj
			-- Creates a WatchObj
		
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

local function time_format(time: number)
	local hours: number = math.floor(time / 60)
	local mins: number = math.floor(time % 60)

	if mins < 10 then
		mins = "0" .. mins
	end

	return `{hours}:{mins}`
end

function Watch:mount()
	local time_text: {} = self.Fusion.Value(time_format(self.Core.Lighting:GetMinutesAfterMidnight()))
	self._maid.TimeSignal = self.Core.Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
		time_text:set(time_format(self.Core.Lighting:GetMinutesAfterMidnight()))
	end)

	self._maid.WatchGui = self.Fusion.New("ScreenGui")({
		Name = "Watch",
		Enabled = true,
		Parent = self.Core.PlayerGui,
		[self.Fusion.Children] = self.Fusion.New("TextLabel")({
			Name = "Watch",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.077, 0, 0.049, 0),
			Position = UDim2.new(0.5, 0, 0.039, 0),
			Font = Enum.Font.Fantasy,
			TextStrokeTransparency = 0,
			TextTransparency = 0.2,
			TextColor3 = Color3.fromRGB(244, 244, 244),
			TextScaled = true,
			Text = time_text,
			Visible = true,
		}),
	})
end

function Watch:Destroy(): nil
	self._maid:DoCleaning()
	return
end

function Watch.new(): {}
	local self = setmetatable({}, Watch)
	self.Core = _G.Core
	self.Fusion = self.Core.Fusion
	self._maid = self.Core.Utils.Maid.new()

	return self
end

return Watch
