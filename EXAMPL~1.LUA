--[[
	ExampleUsage.lua (LocalScript)

	Quick demo of Countdown3D. Put this next to Countdown3D.lua in
	StarterPlayerScripts and press Play - a couple seconds after
	spawning you'll see 3... 2... 1... GO!

	Delete this once you've wired Show() into your own game.
]]

local Countdown3D = require(script.Parent:WaitForChild("Countdown3D"))

-- if Countdown3D lives in ReplicatedStorage instead, use this:
-- local Countdown3D = require(game:GetService("ReplicatedStorage"):WaitForChild("Countdown3D"))

local THEME_COLOR = Color3.fromRGB(255, 60, 60)

task.wait(2)

Countdown3D.Show("3", THEME_COLOR)
task.wait(1)
Countdown3D.Show("2", THEME_COLOR)
task.wait(1)
Countdown3D.Show("1", THEME_COLOR)
task.wait(1)
Countdown3D.Show("GO!", THEME_COLOR, { big = true })
