--[[
	Countdown3D.lua  (ModuleScript)

	A punchy, 3D-extruded "slam" number/text effect for Roblox - the kind
	of big chunky countdown you see before a race or a fight starts
	(3... 2... 1... GO!).

	HOW IT WORKS (plain English):
	Roblox UI is flat by default - there's no real 3D. This effect FAKES
	a 3D "extruded" look by stacking several copies of the same text on
	top of each other, each one nudged slightly down-and-right and
	colored a bit darker than the one in front of it. From a normal
	viewing distance that reads as a solid, chunky block of text with
	visible depth/thickness - like a 3D logo - even though it's really
	just several flat TextLabels stacked up.

	On top of that stack, this adds:
	  - A quick "pop" scale-in with a bouncy overshoot.
	  - An expanding, fading ring behind the text (like a shockwave).
	  - Two colored flash bars along the top and bottom edges of the
	    screen.
	  - An optional screen-shake wobble for extra-dramatic reveals (see
	    the `big` option below).
	  - A clean auto-fade-out, so nothing ever gets stuck on screen.

	USAGE:
		local Countdown3D = require(path.to.Countdown3D)

		Countdown3D.Show("3", Color3.fromRGB(80, 160, 255))
		Countdown3D.Show("2", Color3.fromRGB(80, 160, 255))
		Countdown3D.Show("1", Color3.fromRGB(80, 160, 255))
		Countdown3D.Show("GO!", Color3.fromRGB(80, 160, 255), { big = true })

	Only ever needs a text string and a Color3 - swap the color for any
	theme (red for danger, blue for "go", gold for a big win) and the
	face, depth-shading, outline, ring, and flash-bar colors all update
	together automatically.

	This is a LocalScript-side effect only (pure visuals, no server code,
	no RemoteEvents of its own) - call Countdown3D.Show(...) from any
	LocalScript, at whatever moment YOUR game decides a countdown tick
	(or big reveal) should happen. See ExampleUsage.lua alongside this
	file for a tiny working demo.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Countdown3D = {}

-- ============================================================
-- COLOR MATH - turns the ONE color you pass in into the several
-- shades the effect needs (a brighter "face", a darker "depth", etc.)
-- so you never have to think about more than one Color3.
-- ============================================================

local function lighten(color, amount)
	-- Blends toward white. amount = 0 gives back the same color,
	-- amount = 1 gives pure white.
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

local function darken(color, amount)
	-- Blends toward black - same idea as lighten() above, just the
	-- other direction.
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

-- ============================================================
-- BUILD THE UI ONCE - every later Show() call reuses these same
-- instances instead of creating/destroying anything, so calling this
-- a lot (once a second during a countdown) is essentially free.
-- ============================================================

local built = false
local canvas, canvasScale, layers, ring, ringStroke, edgeTop, edgeBottom
local DEPTH = 7 -- how many stacked layers make up the "thickness" of the text

local function build(screenGui)
	if built then
		return
	end
	built = true

	-- Two soft color bars along the top and bottom edges of the screen -
	-- they flash on and fade out, like a camera flash catching the edges
	-- of the frame.
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

	-- The expanding "shockwave" ring that blooms out from behind the text.
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

	-- A CanvasGroup lets us fade EVERY layer of the text stack at once by
	-- tweening just one property (GroupTransparency), instead of tweening
	-- all DEPTH+1 layers separately.
	canvas = Instance.new("CanvasGroup")
	canvas.AnchorPoint = Vector2.new(0.5, 0.5)
	canvas.Position = UDim2.new(0.5, 0, 0.42, 0)
	canvas.Size = UDim2.new(0, 720, 0, 320)
	canvas.BackgroundTransparency = 1
	canvas.GroupTransparency = 1 -- starts invisible
	canvas.ZIndex = 5
	canvas.Parent = screenGui
	canvasScale = Instance.new("UIScale")
	canvasScale.Parent = canvas

	-- The "3D" stack itself: DEPTH+1 copies of the same text, each one a
	-- few pixels further down-and-right than the last - see setColors()
	-- below for how the front-to-back darkening is calculated.
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
			-- Only the FRONT-most layer (the visible face) gets an
			-- outline - an outline on every layer would just look muddy.
			local outline = Instance.new("UIStroke")
			outline.Name = "FaceStroke"
			outline.Thickness = 3.5
			outline.Transparency = 0.2
			outline.Parent = label
		end
		layers[i] = label
	end
end

-- Paints the whole stack of layers for one Show() call: a bright face
-- color up front, fading down to a dark shade at the back of the stack.
local function setColors(text, faceColor, depthColor, strokeColor)
	for i = 0, DEPTH do
		local label = layers[i]
		label.Text = text
		if i == 0 then
			label.TextColor3 = faceColor
			label.FaceStroke.Color = strokeColor
		else
			-- Layers further back get progressively darker, which is
			-- what sells the illusion of a solid, lit-from-the-front
			-- 3D block instead of a stack of flat, identical labels.
			local shade = 1 - (i / (DEPTH + 2)) * 0.9
			label.TextColor3 = Color3.new(depthColor.R * shade, depthColor.G * shade, depthColor.B * shade)
		end
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Bumped on every Show() call. Background effects (the shake loop, the
-- delayed fade-out) check this before touching anything, so an OLDER
-- call can never fight with or cut off a NEWER one that started later.
local activeGeneration = 0

--[[
	Countdown3D.Show(text, color, options)

	text    - what to display, e.g. "3", "GO!", "FINAL LAP".
	color   - a Color3 theme for this reveal. Defaults to red if you
	          don't pass one. Everything else (face, depth shading,
	          outline, ring, edge flashes) is derived from this ONE
	          color, so a single Color3 re-themes the whole effect.
	options - optional table:
	            big      (boolean) - a bigger, shakier, longer-held
	                       reveal for the important moment (the last
	                       number, "GO!", a final score, etc). Defaults
	                       to false, which plays a quicker, calmer tick.
	            holdTime (number)  - seconds to stay fully visible
	                       before fading out. Defaults to 0.7 (0.8 if
	                       `big` is true).
	            parent   (Instance) - where to build this effect's
	                       ScreenGui. Defaults to the local player's
	                       PlayerGui. Only matters on the very first
	                       call - later calls reuse what was already
	                       built.
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

	-- Derive every other shade from the one color you passed in. A
	-- normal tick gets a bright, near-white face (easiest to read at a
	-- glance); a "big" reveal gets a bolder, fully-saturated face and a
	-- lighter outline instead, so it reads as more intense.
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
		-- A brief, self-limiting shake (max 0.35s) - not an infinite
		-- loop, and it bails out early if a newer Show() has already
		-- taken over.
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
			return -- a newer Show() call has already taken over the display
		end
		TweenService:Create(canvas, TweenInfo.new(0.3), { GroupTransparency = 1 }):Play()
	end)
end

return Countdown3D
