# Countdown3D

A 3D-looking countdown effect for Roblox - the chunky "3... 2... 1... GO!" text you see before a match starts. Just one script, no plugins, no extra assets.

![demo](demo.gif)

## Install

Drop `Countdown3D.lua` into ReplicatedStorage (or anywhere a LocalScript can require it). `ExampleUsage.lua` has a quick demo - delete it once you've wired up your own version.

## Usage

```lua
local Countdown3D = require(path.to.Countdown3D)

Countdown3D.Show("3", Color3.fromRGB(80, 160, 255))
Countdown3D.Show("2", Color3.fromRGB(80, 160, 255))
Countdown3D.Show("1", Color3.fromRGB(80, 160, 255))
Countdown3D.Show("GO!", Color3.fromRGB(80, 160, 255), { big = true })
```

`Show(text, color, options)` is the whole API:

- `text` - what shows up. "3", "GO!", "FINAL LAP", anything.
- `color` - theme color, defaults to red. Everything else (shading, outline, ring, edge flash) gets derived from it.
- `options.big` - bigger, shakier version for the big moment. Default false.
- `options.holdTime` - seconds before it fades out. Default 0.7 (0.8 if big).
- `options.parent` - where the ScreenGui gets built. Defaults to the player's PlayerGui.

Hook it up to whatever tells your game a tick happened - a RemoteEvent, a timer, a keypress:

```lua
remoteEvent.OnClientEvent:Connect(function(secondsLeft)
	if secondsLeft >= 1 and secondsLeft <= 3 then
		Countdown3D.Show(tostring(secondsLeft), Color3.fromRGB(255, 45, 45))
	elseif secondsLeft == 0 then
		Countdown3D.Show("GO!", Color3.fromRGB(80, 200, 120), { big = true })
	end
end)
```

## License

MIT, do whatever you want with it. See [LICENSE](LICENSE).
