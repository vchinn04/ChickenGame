local CustomProximity = {
	Name = "CustomProximity",
}
local Core
local Maid

local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GamepadButtonImage = {
	[Enum.KeyCode.ButtonX] = "rbxasset://textures/ui/Controls/xboxX.png",
	[Enum.KeyCode.ButtonY] = "rbxasset://textures/ui/Controls/xboxY.png",
	[Enum.KeyCode.ButtonA] = "rbxasset://textures/ui/Controls/xboxA.png",
	[Enum.KeyCode.ButtonB] = "rbxasset://textures/ui/Controls/xboxB.png",
	[Enum.KeyCode.DPadLeft] = "rbxasset://textures/ui/Controls/dpadLeft.png",
	[Enum.KeyCode.DPadRight] = "rbxasset://textures/ui/Controls/dpadRight.png",
	[Enum.KeyCode.DPadUp] = "rbxasset://textures/ui/Controls/dpadUp.png",
	[Enum.KeyCode.DPadDown] = "rbxasset://textures/ui/Controls/dpadDown.png",
	[Enum.KeyCode.ButtonSelect] = "rbxasset://textures/ui/Controls/xboxView.png",
	[Enum.KeyCode.ButtonStart] = "rbxasset://textures/ui/Controls/xboxmenu.png",
	[Enum.KeyCode.ButtonL1] = "rbxasset://textures/ui/Controls/xboxLB.png",
	[Enum.KeyCode.ButtonR1] = "rbxasset://textures/ui/Controls/xboxRB.png",
	[Enum.KeyCode.ButtonL2] = "rbxasset://textures/ui/Controls/xboxLT.png",
	[Enum.KeyCode.ButtonR2] = "rbxasset://textures/ui/Controls/xboxRT.png",
	[Enum.KeyCode.ButtonL3] = "rbxasset://textures/ui/Controls/xboxLS.png",
	[Enum.KeyCode.ButtonR3] = "rbxasset://textures/ui/Controls/xboxRS.png",
	[Enum.KeyCode.Thumbstick1] = "rbxasset://textures/ui/Controls/xboxLSDirectional.png",
	[Enum.KeyCode.Thumbstick2] = "rbxasset://textures/ui/Controls/xboxRSDirectional.png",
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

local function getScreenGui()
	local screenGui = PlayerGui:FindFirstChild("ProximityPrompts")
	if screenGui == nil then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ProximityPrompts"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
	end
	return screenGui
end

local function createProgressBarGradient(parent, leftSide)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.5, 1)
	frame.Position = UDim2.fromScale(leftSide and 0 or 0.5, 0)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.Parent = parent

	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(2, 1)
	image.Position = UDim2.fromScale(leftSide and 0 or -1, 0)
	image.Image = "rbxasset://textures/ui/Controls/RadialFill.png"
	image.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4999, 0),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = leftSide and 180 or 0
	gradient.Parent = image

	return gradient
end

local function createCircularProgressBar()
	local bar = Instance.new("Frame")
	bar.Name = "CircularProgressBar"
	bar.Size = UDim2.fromOffset(58, 58)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.5)
	bar.BackgroundTransparency = 1

	local gradient1 = createProgressBarGradient(bar, true)
	local gradient2 = createProgressBarGradient(bar, false)

	local progress = Instance.new("NumberValue")
	progress.Name = "Progress"
	progress.Parent = bar
	progress.Changed:Connect(function(value)
		local angle = math.clamp(value * 360, 0, 360)
		gradient1.Rotation = math.clamp(angle, 180, 360)
		gradient2.Rotation = math.clamp(angle, 0, 180)
	end)

	return bar
end

local function createPrompt(prompt, inputType, gui)
	local tweensForButtonHoldBegin = {}
	local tweensForButtonHoldEnd = {}
	local tweensForFadeOut = {}
	local tweensForFadeIn = {}
	local tweenInfoInFullDuration =
		TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenInfoOutHalfSecond = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenInfoQuick = TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local promptUI = Instance.new("BillboardGui")
	promptUI.Name = "Prompt"
	promptUI.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.5, 1)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = Color3.new(0.07, 0.07, 0.07)
	frame.Parent = promptUI

	local roundedCorner = Instance.new("UICorner")
	roundedCorner.Parent = frame

	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.fromScale(1, 1)
	inputFrame.BackgroundTransparency = 1
	inputFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	inputFrame.Parent = frame

	local resizeableInputFrame = Instance.new("Frame")
	resizeableInputFrame.Size = UDim2.fromScale(1, 1)
	resizeableInputFrame.Position = UDim2.fromScale(0.5, 0.5)
	resizeableInputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	resizeableInputFrame.BackgroundTransparency = 1
	resizeableInputFrame.Parent = inputFrame

	local inputFrameScaler = Instance.new("UIScale")
	inputFrameScaler.Parent = resizeableInputFrame

	local inputFrameScaleFactor = inputType == Enum.ProximityPromptInputType.Touch and 1.6 or 1.33
	table.insert(
		tweensForButtonHoldBegin,
		TweenService:Create(inputFrameScaler, tweenInfoFast, { Scale = inputFrameScaleFactor })
	)
	table.insert(tweensForButtonHoldEnd, TweenService:Create(inputFrameScaler, tweenInfoFast, { Scale = 1 }))

	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.Size = UDim2.fromScale(1, 1)
	actionText.Font = Enum.Font.GothamSemibold
	actionText.TextSize = 19
	actionText.BackgroundTransparency = 1
	actionText.TextTransparency = 1
	actionText.TextColor3 = Color3.new(1, 1, 1)
	actionText.TextXAlignment = Enum.TextXAlignment.Left
	actionText.Parent = frame
	table.insert(tweensForButtonHoldBegin, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))
	table.insert(tweensForFadeOut, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))

	local objectText = Instance.new("TextLabel")
	objectText.Name = "ObjectText"
	objectText.Size = UDim2.fromScale(1, 1)
	objectText.Font = Enum.Font.GothamSemibold
	objectText.TextSize = 14
	objectText.BackgroundTransparency = 1
	objectText.TextTransparency = 1
	objectText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	objectText.TextXAlignment = Enum.TextXAlignment.Left
	objectText.Parent = frame

	table.insert(tweensForButtonHoldBegin, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))
	table.insert(tweensForFadeOut, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))

	table.insert(
		tweensForButtonHoldBegin,
		TweenService:Create(frame, tweenInfoFast, { Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1 })
	)
	table.insert(
		tweensForButtonHoldEnd,
		TweenService:Create(frame, tweenInfoFast, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.2 })
	)
	table.insert(
		tweensForFadeOut,
		TweenService:Create(frame, tweenInfoFast, { Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1 })
	)
	table.insert(
		tweensForFadeIn,
		TweenService:Create(frame, tweenInfoFast, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.2 })
	)

	local roundFrame = Instance.new("Frame")
	roundFrame.Name = "RoundFrame"
	roundFrame.Size = UDim2.fromOffset(48, 48)

	roundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	roundFrame.Position = UDim2.fromScale(0.5, 0.5)
	roundFrame.BackgroundTransparency = 1
	roundFrame.Parent = resizeableInputFrame

	local roundedFrameCorner = Instance.new("UICorner")
	roundedFrameCorner.CornerRadius = UDim.new(0.5, 0)
	roundedFrameCorner.Parent = roundFrame

	table.insert(tweensForFadeOut, TweenService:Create(roundFrame, tweenInfoQuick, { BackgroundTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(roundFrame, tweenInfoQuick, { BackgroundTransparency = 0.5 }))

	if inputType == Enum.ProximityPromptInputType.Gamepad then
		if GamepadButtonImage[prompt.GamepadKeyCode] then
			local icon = Instance.new("ImageLabel")
			icon.Name = "ButtonImage"
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Size = UDim2.fromOffset(24, 24)
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.BackgroundTransparency = 1
			icon.ImageTransparency = 1
			icon.Image = GamepadButtonImage[prompt.GamepadKeyCode]
			icon.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 0 }))
		end
	elseif inputType == Enum.ProximityPromptInputType.Touch then
		local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.BackgroundTransparency = 1
		buttonImage.ImageTransparency = 1
		buttonImage.Size = UDim2.fromOffset(25, 31)
		buttonImage.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonImage.Position = UDim2.fromScale(0.5, 0.5)
		buttonImage.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"
		buttonImage.Parent = resizeableInputFrame

		table.insert(tweensForFadeOut, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 0 }))
	else
		local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.BackgroundTransparency = 1
		buttonImage.ImageTransparency = 1
		buttonImage.Size = UDim2.fromOffset(28, 30)
		buttonImage.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonImage.Position = UDim2.fromScale(0.5, 0.5)
		buttonImage.Image = "rbxasset://textures/ui/Controls/key_single.png"
		buttonImage.Parent = resizeableInputFrame
		table.insert(tweensForFadeOut, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 0 }))

		local buttonTextString = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)

		local buttonTextImage = KeyboardButtonImage[prompt.KeyboardKeyCode]
		if buttonTextImage == nil then
			buttonTextImage = KeyboardButtonIconMapping[buttonTextString]
		end

		if buttonTextImage == nil then
			local keyCodeMappedText = KeyCodeToTextMapping[prompt.KeyboardKeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			local icon = Instance.new("ImageLabel")
			icon.Name = "ButtonImage"
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Size = UDim2.fromOffset(36, 36)
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.BackgroundTransparency = 1
			icon.ImageTransparency = 1
			icon.Image = buttonTextImage
			icon.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 0 }))
		elseif buttonTextString ~= nil and buttonTextString ~= "" then
			local buttonText = Instance.new("TextLabel")
			buttonText.Name = "ButtonText"
			buttonText.Position = UDim2.fromOffset(0, -1)
			buttonText.Size = UDim2.fromScale(1, 1)
			buttonText.Font = Enum.Font.GothamSemibold
			buttonText.TextSize = 14
			if string.len(buttonTextString) > 2 then
				buttonText.TextSize = 12
			end
			buttonText.BackgroundTransparency = 1
			buttonText.TextTransparency = 1
			buttonText.TextColor3 = Color3.new(1, 1, 1)
			buttonText.TextXAlignment = Enum.TextXAlignment.Center
			buttonText.Text = buttonTextString
			buttonText.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(buttonText, tweenInfoQuick, { TextTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(buttonText, tweenInfoQuick, { TextTransparency = 0 }))
		else
			error(
				"ProximityPrompt '"
					.. prompt.Name
					.. "' has an unsupported keycode for rendering UI: "
					.. tostring(prompt.KeyboardKeyCode)
			)
		end
	end

	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
		local button = Instance.new("TextButton")
		button.BackgroundTransparency = 1
		button.TextTransparency = 1
		button.Size = UDim2.fromScale(1, 1)
		button.Parent = promptUI

		local buttonDown = false

		button.InputBegan:Connect(function(input)
			if
				(
					input.UserInputType == Enum.UserInputType.Touch
					or input.UserInputType == Enum.UserInputType.MouseButton1
				) and input.UserInputState ~= Enum.UserInputState.Change
			then
				prompt:InputHoldBegin()
				buttonDown = true
			end
		end)
		button.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				if buttonDown then
					buttonDown = false
					prompt:InputHoldEnd()
				end
			end
		end)

		promptUI.Active = true
	end

	if prompt.HoldDuration > 0 then
		local circleBar = createCircularProgressBar()
		circleBar.Parent = resizeableInputFrame
		table.insert(
			tweensForButtonHoldBegin,
			TweenService:Create(circleBar.Progress, tweenInfoInFullDuration, { Value = 1 })
		)
		table.insert(
			tweensForButtonHoldEnd,
			TweenService:Create(circleBar.Progress, tweenInfoOutHalfSecond, { Value = 0 })
		)
	end

	local holdBeganConnection
	local holdEndedConnection
	local triggeredConnection
	local triggerEndedConnection

	if prompt.HoldDuration > 0 then
		holdBeganConnection = prompt.PromptButtonHoldBegan:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldBegin) do
				tween:Play()
			end
			local prompt_object = prompt.Parent
			if prompt_object.Parent.Name ~= "Workspace" then
				prompt_object = prompt_object.Parent
			end
			Core.Fire("InteractionTriggered", prompt.Name, prompt_object)
		end)

		holdEndedConnection = prompt.PromptButtonHoldEnded:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldEnd) do
				tween:Play()
			end
			local prompt_object = prompt.Parent
			if prompt_object.Parent.Name ~= "Workspace" then
				prompt_object = prompt_object.Parent
			end
			Core.Fire("InteractionTriggerEnded", prompt.Name, prompt_object)
		end)
	end

	triggeredConnection = prompt.Triggered:Connect(function()
		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end
		local prompt_object = prompt.Parent
		if prompt_object.Parent.Name ~= "Workspace" then
			prompt_object = prompt_object.Parent
		end
		Core.Fire("InteractionSuccess", prompt.Name, prompt_object)
	end)

	triggerEndedConnection = prompt.TriggerEnded:Connect(function()
		for _, tween in ipairs(tweensForFadeIn) do
			tween:Play()
		end
	end)

	local function updateUIFromPrompt()
		-- todo: Use AutomaticSize instead of GetTextSize when that feature becomes available
		local actionTextSize =
			TextService:GetTextSize(prompt.ActionText, 19, Enum.Font.GothamSemibold, Vector2.new(1000, 1000))
		local objectTextSize =
			TextService:GetTextSize(prompt.ObjectText, 14, Enum.Font.GothamSemibold, Vector2.new(1000, 1000))
		local maxTextWidth = math.max(actionTextSize.X, objectTextSize.X)
		local promptHeight = 72
		local promptWidth = 72
		local textPaddingLeft = 72

		if
			(prompt.ActionText ~= nil and prompt.ActionText ~= "")
			or (prompt.ObjectText ~= nil and prompt.ObjectText ~= "")
		then
			promptWidth = maxTextWidth + textPaddingLeft + 24
		end

		local actionTextYOffset = 0
		if prompt.ObjectText ~= nil and prompt.ObjectText ~= "" then
			actionTextYOffset = 9
		end
		actionText.Position = UDim2.new(0.5, textPaddingLeft - promptWidth / 2, 0, actionTextYOffset)
		objectText.Position = UDim2.new(0.5, textPaddingLeft - promptWidth / 2, 0, -10)

		actionText.Text = prompt.ActionText
		objectText.Text = prompt.ObjectText
		actionText.AutoLocalize = prompt.AutoLocalize
		actionText.RootLocalizationTable = prompt.RootLocalizationTable

		objectText.AutoLocalize = prompt.AutoLocalize
		objectText.RootLocalizationTable = prompt.RootLocalizationTable

		promptUI.Size = UDim2.fromOffset(promptWidth, promptHeight)
		promptUI.SizeOffset =
			Vector2.new(prompt.UIOffset.X / promptUI.Size.Width.Offset, prompt.UIOffset.Y / promptUI.Size.Height.Offset)
	end

	local changedConnection = prompt.Changed:Connect(updateUIFromPrompt)
	updateUIFromPrompt()

	promptUI.Adornee = prompt.Parent
	promptUI.Parent = gui

	for _, tween in ipairs(tweensForFadeIn) do
		tween:Play()
	end

	local function cleanup()
		print("Cleanup prompt!")
		if holdBeganConnection then
			holdBeganConnection:Disconnect()
		end

		if holdEndedConnection then
			holdEndedConnection:Disconnect()
		end

		triggeredConnection:Disconnect()
		triggerEndedConnection:Disconnect()
		changedConnection:Disconnect()

		for _, tween in tweensForFadeOut do
			tween:Play()
		end

		task.delay(0.2, function()
			promptUI.Parent = nil
		end)
	end

	return cleanup
end

local function onLoad()
	Maid:GiveTask(ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		--if prompt.Style == Enum.ProximityPromptStyle.Default then
		--return
		--end

		local gui = getScreenGui()

		local cleanupFunction = createPrompt(prompt, inputType, gui)

		prompt.PromptHidden:Wait()

		cleanupFunction()
	end))
end

function CustomProximity.Start()
	onLoad()
end

function CustomProximity.Init()
	Core = _G.Core
	Maid = Core.Utils.Maid.new()
end

function CustomProximity.Reset()
	Maid:DoCleaning()
end
return CustomProximity
