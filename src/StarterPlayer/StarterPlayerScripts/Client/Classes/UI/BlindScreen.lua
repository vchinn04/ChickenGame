local BlindScreen = {
	UIType = "Core",
}
BlindScreen.__index = BlindScreen

--[[
	<description>
		This class provides the functionalities for a Blinding effect (bright flash) on screen.
	</description> 
	
	<API>
		BlindScreenObj:mount()
			-- Mount the UI, make it transparent

		BlindScreenObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		BlindScreen.new() --> BlindScreenObj
			-- Creates a BlindScreenObj
		
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local SCREENGUI_NAME: string = "BlindScreen"
local FRAME_ANCHOR_POINT: Vector2 = Vector2.new(0.5, 0.5)
local FRAME_POSITION: UDim2 = UDim2.fromScale(0.5, 0.5)
local FRAME_SIZE: UDim2 = UDim2.fromScale(1, 1)
local DEFAULT_FRAME_TRANSPARENCY: number = 1
local FRAME_BACKGROUND_COLOR: Color3 = Color3.fromRGB(255, 255, 255)

--*************************************************************************************************--

function BlindScreen:mount()
	local frame_ref: {} = self.Fusion.Value()

	self._core_maid.BlindUI = self.Fusion.New("ScreenGui")({
		Parent = self.Core.PlayerGui,
		Name = SCREENGUI_NAME,
		IgnoreGuiInset = true,
		Enabled = true,

		[self.Fusion.Children] = {
			self.Fusion.New("Frame")({
				AnchorPoint = FRAME_ANCHOR_POINT,
				Position = FRAME_POSITION,
				Size = FRAME_SIZE,
				BackgroundTransparency = DEFAULT_FRAME_TRANSPARENCY,
				[self.Fusion.Ref] = frame_ref,
				BackgroundColor3 = FRAME_BACKGROUND_COLOR,
			}),
		},
	})

	return frame_ref
end

function BlindScreen:Destroy(): nil
	self._core_maid:DoCleaning()
	self._stat_bars = nil
	self._toolbar = nil
	return
end

function BlindScreen.new(): {}
	local self = setmetatable({}, BlindScreen)

	self.Core = _G.Core
	self.Fusion = self.Core.Fusion

	self._core_maid = self.Core.Utils.Maid.new()

	return self
end

return BlindScreen
