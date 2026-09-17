--[[
	ExampleUsage.lua  (LocalScript)

	A minimal demo of Countdown3D. To try it:
	  1. Put this LocalScript and Countdown3D.lua both in
	     StarterPlayerScripts (or put Countdown3D in ReplicatedStorage
	     instead and switch the require() line below to match).
	  2. Press Play. A couple seconds after you spawn in, you'll see a
	     3... 2... 1... GO! countdown.

	This script is just a demo - delete it once you've wired
	Countdown3D.Show(...) into your own game's actual countdown moment
	(a RemoteEvent from the server, a round timer running out, a key
	press, whatever fits your game).
]]

-- If Countdown3D lives next to this script (e.g. both in
-- StarterPlayerScripts), this line just works:
local Countdown3D = require(script.Parent:WaitForChild("Countdown3D"))

-- If you put Countdown3D in ReplicatedStorage instead, use this line
-- instead of the one above:
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Countdown3D = require(ReplicatedStorage:WaitForChild("Countdown3D"))

-- Try changing this to any color - the whole effect re-themes itself.
local THEME_COLOR = Color3.fromRGB(255, 60, 60)

task.wait(2) -- just a moment to get your bearings after spawning in

Countdown3D.Show("3", THEME_COLOR)
task.wait(1)
Countdown3D.Show("2", THEME_COLOR)
task.wait(1)
Countdown3D.Show("1", THEME_COLOR)
task.wait(1)
Countdown3D.Show("GO!", THEME_COLOR, { big = true })
