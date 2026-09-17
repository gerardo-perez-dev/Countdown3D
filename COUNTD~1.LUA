--[[
	Countdown3D.lua (ModuleScript)

	Chunky 3D-style countdown effect for Roblox - the "3... 2... 1... GO!"
	you'd see before a race or a fight starts. It's fake 3D: a handful of
	copies of the same text, stacked with a small offset and darkened
	toward the back, which reads as a solid extruded block from normal
	viewing distance.

	Usage:
		local Countdown3D = require(path.to.Countdown3D)
		Countdown3D.Show("3", Color3.fromRGB(80, 160, 255))
		Countdown3D.Show("GO!", Color3.fromRGB(80, 160, 255), { big = true })

	One color in, and the face, shading, outline, ring, and edge flashes
	all get derived from it. See ExampleUsage.lua for a full demo.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Countdown3D = {}

-- turns one base color into the lighter/darker shades the effect needs
local function lighten(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

local function darken(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

-- everything below is built once and reused - Show() never creates or
-- destroys instances, just recolors and retweens what's already there
local built = false
local canvas, canvasScale, layers, ring, ringStroke, edgeTop, edgeBottom
local DEPTH = 7 -- how many stacked layers make up the "thickness"

local function build(screenGui)
	if built then
		return
	end
	built = true

	-- top/bottom edge flashes
	local function makeEdge(size, position, gradientRotation)
		local frame = Instance.new("Frame")
		frame.Size = size
		frame.Position = position
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.ZIndex = 2
		frame.Parent = screenGui
		local gradient = Instance.new("UIGradient")
		gradient.Transparency = NumberSequence.new(0.35, 1)
		gradient.Rotation = gradientRotation
		gradient.Parent = frame
		return frame
	end
	edgeTop = makeEdge(UDim2.new(1, 0, 0, 90), UDim2.new(0, 0, 0, 0), 90)
	edgeBottom = makeEdge(UDim2.new(1, 0, 0, 90), UDim2.new(0, 0, 1, -90), -90)

	-- expanding ring behind the text
	ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.new(0.5, 0, 0.42, 0)
	ring.Size = UDim2.new(0, 0, 0, 0)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 3
	ring.Parent = screenGui
	ringStroke = Instance.new("UIStroke")
	ringStroke.Thickness = 6
	ringStroke.Transparency = 1
	ringStroke.Parent = ring
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(1, 0)
	ringCorner.Parent = ring

	-- CanvasGroup so the whole stack fades with one tween instead of
	-- tweening every layer separately
	canvas = Instance.new("CanvasGroup")
	canvas.AnchorPoint = Vector2.new(0.5, 0.5)
	canvas.Position = UDim2.new(0.5, 0, 0.42, 0)
	canvas.Size = UDim2.new(0, 720, 0, 320)
	canvas.BackgroundTransparency = 1
	canvas.GroupTransparency = 1
	canvas.ZIndex = 5
	canvas.Parent = screenGui
	canvasScale = Instance.new("UIScale")
	canvasScale.Parent = canvas

	-- the stack itself - each layer sits a few pixels further
	-- down-and-right than the last (shading handled in setColors)
	layers = {}
	for i = DEPTH, 0, -1 do
		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.new(0.5, i * 4, 0.5, i * 4)
		label.Size = UDim2.new(1, -60, 1, -60)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.Text = ""
		label.TextScaled = true
		label.ZIndex = 5 + (DEPTH - i)
		label.Parent = canvas
		if i == 0 then
			-- only the front face gets an outline, otherwise it looks muddy
			local outline = Instance.new("UIStroke")
			outline.Name = "FaceStroke"
			outline.Thickness = 3.5
			outline.Transparency = 0.2
			outline.Parent = label
		end
		layers[i] = label
	end
end

-- bright color up front, fading darker toward the back of the stack
local function setColors(text, faceColor, depthColor, strokeColor)
	for i = 0, DEPTH do
		local label = layers[i]
		label.Text = text
		if i == 0 then
			label.TextColor3 = faceColor
			label.FaceStroke.Color = strokeColor
		else
			local shade = 1 - (i / (DEPTH + 2)) * 0.9
			label.TextColor3 = Color3.new(depthColor.R * shade, depthColor.G * shade, depthColor.B * shade)
		end
	end
end

-- bumped on every Show() call, so an older call's delayed fade/shake
-- can tell it's been superseded and bail out instead of fighting a newer one
local activeGeneration = 0

--[[
	Countdown3D.Show(text, color, options)

	text    - "3", "GO!", "FINAL LAP", whatever you want on screen.
	color   - theme color, defaults to red. Everything else (shading,
	          outline, ring, edge flashes) is derived from this.
	options - big (bool, default false): bigger/shakier/longer reveal
	          holdTime (number): seconds before it fades, default 0.7
	          (0.8 if big)
	          parent (Instance): where to build the ScreenGui, defaults
	          to the local player's PlayerGui. Only matters on first call.
]]
function Countdown3D.Show(text, color, options)
	options = options or {}
	color = color or Color3.fromRGB(255, 60, 60)
	local big = options.big == true

	if not built then
		local parent = options.parent
		if parent == nil then
			local player = Players.LocalPlayer
			parent = player and player:WaitForChild("PlayerGui")
		end
		if parent == nil then
			warn("[Countdown3D] No PlayerGui to build into yet - pass options.parent, or call this from a LocalScript after the player has loaded in.")
			return
		end
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "Countdown3DGui"
		screenGui.ResetOnSpawn = false
		screenGui.DisplayOrder = 30
		screenGui.IgnoreGuiInset = true
		screenGui.Parent = parent
		build(screenGui)
	end

	activeGeneration += 1
	local myGeneration = activeGeneration
	canvas.Visible = true

	local faceColor = big and color or lighten(color, 0.55)
	local depthColor = darken(color, 0.55)
	local strokeColor = big and lighten(color, 0.5) or color
	setColors(text, faceColor, depthColor, strokeColor)

	canvas.GroupTransparency = 1
	canvasScale.Scale = big and 2.6 or 2.1
	canvas.Rotation = big and -6 or -3
	TweenService:Create(canvasScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = big and 1.2 or 1 }):Play()
	TweenService:Create(canvas, TweenInfo.new(0.13), { GroupTransparency = 0, Rotation = 0 }):Play()

	ring.Size = UDim2.new(0, 60, 0, 60)
	ringStroke.Color = color
	ringStroke.Transparency = 0.1
	ringStroke.Thickness = big and 10 or 8
	TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 560, 0, 560) }):Play()
	TweenService:Create(ringStroke, TweenInfo.new(0.45), { Transparency = 1, Thickness = 1 }):Play()

	for _, edge in ipairs({ edgeTop, edgeBottom }) do
		edge.BackgroundColor3 = color
		edge.BackgroundTransparency = big and 0.25 or 0.55
		TweenService:Create(edge, TweenInfo.new(big and 0.7 or 0.45), { BackgroundTransparency = 1 }):Play()
	end

	if big then
		-- short self-limiting shake, bails early if a newer Show() took over
		task.spawn(function()
			local shakeAmount = 6
			local start = os.clock()
			while os.clock() - start < 0.35 and myGeneration == activeGeneration do
				canvas.Position = UDim2.new(0.5, math.random(-shakeAmount, shakeAmount), 0.42, math.random(-shakeAmount, shakeAmount))
				task.wait(0.03)
			end
			if myGeneration == activeGeneration then
				canvas.Position = UDim2.new(0.5, 0, 0.42, 0)
			end
		end)
	end

	local holdTime = options.holdTime or (big and 0.8 or 0.7)
	task.delay(holdTime, function()
		if myGeneration ~= activeGeneration then
			return -- a newer Show() call already took over
		end
		TweenService:Create(canvas, TweenInfo.new(0.3), { GroupTransparency = 1 }):Play()
	end)
end

return Countdown3D
