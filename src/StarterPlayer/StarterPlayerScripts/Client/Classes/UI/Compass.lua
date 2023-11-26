local Compass = {}
Compass.__index = Compass

--[[
	<description>
		This class provides the functionalities for a Compass UI on screen.
	</description> 
	
	<API>
		CompassObj:mount()
			-- Mount the UI, make it transparent

		CompassObj:Enable(status: boolean)
			-- Hides/shows compass UI
			status: boolean -- If True: show. If False: hide

		CompassObj:Destroy() --> void
			-- Tares down all connections and destroys components used 

		Compass.new() --> CompassObj
			-- Creates a CompassObj
		
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

local RunService = game:GetService("RunService")

local DEFAULT_DIRECTION_COLOR: Color3 = Color3.fromRGB(200, 200, 200)
local DIRECTIONS = {
	N = math.pi / 4 * 0,
	NE = math.pi / 4 * 1,
	E = math.pi / 4 * 2,
	SE = math.pi / 4 * 3,
	S = math.pi / 4 * 4,
	SW = math.pi / 4 * 5,
	W = math.pi / 4 * 6,
	NW = math.pi / 4 * 7,
}

local COLORS = {
	N = {
		Size = UDim2.new(0.169, 0, 0.423, 0),
		Color = Color3.fromRGB(71, 97, 159),
	},

	S = {
		Size = UDim2.new(0.169, 0, 0.423, 0),
		Color = Color3.fromRGB(159, 71, 72),
	},

	W = {
		Size = UDim2.new(0.169, 0, 0.423, 0),
		Color = DEFAULT_DIRECTION_COLOR,
	},

	E = {
		Size = UDim2.new(0.169, 0, 0.423, 0),
		Color = DEFAULT_DIRECTION_COLOR,
	},

	All = {
		Size = UDim2.new(0.169, 0, 0.299, 0),
		Color = DEFAULT_DIRECTION_COLOR,
	},
}
local COMPASS_SPEED: number = 11
local SCREENGUI_NAME: string = "Compass"
--*************************************************************************************************--

function Compass:mount(): nil
	local item_arr: {} = self.Fusion.ForPairs(self.Directions, function(index, entry)
		local button_position = self.Fusion.Value(UDim2.new(math.cos(entry), 0, math.sin(entry), 0))
		self._directions[index] = button_position

		local color: Color3 = COLORS.All.Color
		local size: UDim2 = COLORS.All.Size

		if COLORS[index] then
			color = COLORS[index].Color
			size = COLORS[index].Size
		end

		return index,
			self.Fusion.New("TextLabel")({
				Name = index,
				Parent = self.Core.PlayerGui,
				Position = button_position,
				Size = size,
				TextColor3 = color,
				TextStrokeTransparency = 0.5,
				BackgroundTransparency = 1,
				TextScaled = true,
				Text = index,
				Font = Enum.Font.Fantasy,
			})
	end, function(_, button)
		button:Destroy()
	end)

	self._core_maid.InventoryScreenGui = self.Fusion.New("ScreenGui")({
		Name = SCREENGUI_NAME,
		Enabled = self._enable_status,
		Parent = self.Core.PlayerGui,
		[self.Fusion.Children] = self.Fusion.New("Frame")({
			Name = "Compass",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ClipsDescendants = true,
			Size = UDim2.new(0.178, 0, 0.134, 0),
			Position = UDim2.new(0.5, 0, 0.279, 0),
			[self.Fusion.Children] = {
				item_arr,
				self.Fusion.New("UIAspectRatioConstraint")({
					AspectRatio = 2.78,
					AspectType = Enum.AspectType.FitWithinMaxSize,
					DominantAxis = Enum.DominantAxis.Width,
				}),
			},
		}),
	})

	return
end

function Compass:Enable(status: boolean): nil
	self._connection_maid:DoCleaning()

	if status then
		local last_rot: number = 0

		self._connection_maid:GiveTask(
			RunService.Heartbeat:Connect(function(dt) -- Creation of a continuous loop of checking pla
				-- Camera Ordinance
				local camera_look: Vector3 = self.Core.CameraManager.GetLookVector()
				camera_look = Vector3.new(camera_look.X, 0, camera_look.Z).Unit --y is irrelevant as you're calculating the tangent of the X and Z not y

				-- Gets rotation
				local rot: numbet = math.atan2(camera_look.X, camera_look.Z) + math.pi
				local dif: number = rot - last_rot

				if dif > math.pi then
					dif = dif - math.pi * 2
				end -- calculating whether you crossed the plane of being on the left or right side of the

				if dif < -math.pi then
					dif = dif + math.pi * 2
				end

				rot = last_rot + dif * dt * COMPASS_SPEED -- Creates a radian degree of where you are currently looking using previous identified variables
				if rot < math.pi * 0 then
					rot = rot + math.pi * 2
				end -- Calculating whether your rotation is on the left or right plane of trig circle with 0pi is straight up understood
				if rot > math.pi * 2 then
					rot = rot - math.pi * 2
				end

				last_rot = rot

				-- Display directions
				for key, pos in self._directions do
					local current_position: number = DIRECTIONS[key]
					local new_pos: number = rot - current_position - math.pi / 2
					local cosPos: number = math.cos(new_pos)
					local sinPos: number = math.sin(new_pos)

					pos:set(UDim2.new(0.41 + cosPos / 2.2, 0, 1.3 + sinPos / 0.8, 0))
				end

				return
			end)
		)
	end

	self._enable_status:set(status)

	return
end

function Compass:Destroy(): nil
	self._connection_maid:DoCleaning()
	self._core_maid:DoCleaning()
	return
end

function Compass.new(): {}
	local self = setmetatable({}, Compass)

	self.Core = _G.Core
	self.Fusion = self.Core.Fusion

	self._core_maid = self.Core.Utils.Maid.new()
	self._connection_maid = self.Core.Utils.Maid.new()

	self._enable_status = self.Fusion.Value(false)

	self._directions = {}
	self.Directions = self.Fusion.Value(DIRECTIONS)

	return self
end

return Compass
