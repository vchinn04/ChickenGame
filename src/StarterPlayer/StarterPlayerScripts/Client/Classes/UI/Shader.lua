local Shader = {
	UIType = "Core",
}
Shader.__index = Shader

--[[
	<description>
		This class provides the functionalities for shading on borders of screen.
	</description> 
	
	<API>
		ShaderObj:mount()
			-- Mount the UI, make it transparent

		Shader:GetFrameObject()
			-- Return the frame object 

		ShaderObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Shader.new() --> ShaderObj
			-- Creates a ShaderObj
		
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local SCREENGUI_NAME: string = "Shader"
local TEMPLATE_NAME: string = "Shading"

local ShadingTemplate: Instance? = nil

--*************************************************************************************************--
function Shader:mount(): {}
	self.frame = self.Fusion.Value()

	self._core_maid.BlindUI = self.Fusion.New("ScreenGui")({
		Parent = self.Core.PlayerGui,
		Name = SCREENGUI_NAME,
		IgnoreGuiInset = true,
		Enabled = true,
		[self.Fusion.Children] = {
			self.Fusion.Hydrate(ShadingTemplate:Clone())({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1.15, 1.15),
				ImageTransparency = 0.15,
				BackgroundTransparency = 1,
				[self.Fusion.Ref] = self.frame,
			}),
		},
	})

	return self.frame
end

function Shader:GetFrameObject(): {}
	return self.frame
end

function Shader.new(): {}
	local self = setmetatable({}, Shader)

	self.Core = _G.Core
	self.Fusion = self.Core.Fusion

	self._core_maid = self.Core.Utils.Maid.new()

	if not ShadingTemplate then
		ShadingTemplate = self.Core.UI:WaitForChild(TEMPLATE_NAME)
	end

	return self
end

function Shader:Destroy(): nil
	self._core_maid:DoCleaning()
	self._stat_bars = nil
	self._toolbar = nil
	return
end

return Shader
