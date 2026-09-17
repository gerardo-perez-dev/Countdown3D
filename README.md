# Countdown3D

A punchy, 3D-extruded "slam" countdown effect for Roblox — the big,
chunky 3... 2... 1... GO! text you see before a race, a boss fight, or a
round starts. Built with plain Roblox UI instances (no plugins, no extra
assets, no dependencies) — one `ModuleScript`, drop it in and call one
function.

## What it does

- Stacks several copies of your text on top of each other, each one
  nudged and darkened slightly, to fake a solid, 3D-extruded look.
- Pops in with a bouncy scale animation, an expanding "shockwave" ring,
  and a flash along the top/bottom edges of the screen.
- Optional bigger, shakier `big` mode for the most dramatic reveal (the
  final number, "GO!", a buzzer-beater score, etc).
- Fades itself out automatically — nothing ever gets stuck on screen.
- Re-themes to **any** color from a single `Color3` — red for danger,
  blue for "go", gold for a win screen, whatever fits your game.

## Install

1. Copy `Countdown3D.lua` into your game. `ReplicatedStorage` is the
   usual spot since it's pure client-side visuals with no server
   dependency, but it works from anywhere a LocalScript can
   `require()` it.
2. (Optional) Look at `ExampleUsage.lua` for the smallest possible
   working example, then delete it once you've wired the real thing
   into your own game.

## Usage

```lua
local Countdown3D = require(path.to.Countdown3D)

Countdown3D.Show("3", Color3.fromRGB(80, 160, 255))
Countdown3D.Show("2", Color3.fromRGB(80, 160, 255))
Countdown3D.Show("1", Color3.fromRGB(80, 160, 255))
Countdown3D.Show("GO!", Color3.fromRGB(80, 160, 255), { big = true })
```

That's the whole API — one function.

### `Countdown3D.Show(text, color, options)`

| Argument | Type | Description |
|---|---|---|
| `text` | `string` | What to display: `"3"`, `"GO!"`, `"FINAL LAP"`, anything. |
| `color` | `Color3?` | The theme color for this reveal. Defaults to red. Every other color (face, depth shading, outline, ring, edge flashes) is derived from this one value. |
| `options` | `table?` | See below. |

`options` fields (all optional):

| Field | Type | Default | Description |
|---|---|---|---|
| `big` | `boolean` | `false` | A bigger, shakier, longer-held reveal for the important moment. |
| `holdTime` | `number` | `0.7` (`0.8` if `big`) | Seconds to stay fully visible before fading out. |
| `parent` | `Instance` | the local player's `PlayerGui` | Where to build the effect's `ScreenGui`. Only matters on the very first call. |

## Wiring it into your own game

This module is pure client-side visuals — it has no `RemoteEvent` of its
own and doesn't know anything about your game's rules. **You** decide
*when* a countdown tick should happen (a server round-timer, a
`RemoteEvent` firing, a local key press, whatever) — `Countdown3D.Show(...)`
is just what happens the instant you call it. A typical pattern:

```lua
-- somewhere that hears the server tell you time is running out
remoteEvent.OnClientEvent:Connect(function(secondsLeft)
	if secondsLeft >= 1 and secondsLeft <= 3 then
		Countdown3D.Show(tostring(secondsLeft), Color3.fromRGB(255, 45, 45))
	elseif secondsLeft == 0 then
		Countdown3D.Show("GO!", Color3.fromRGB(80, 200, 120), { big = true })
	end
end)
```

## License

MIT — do whatever you want with it, including in commercial games. See
[LICENSE](LICENSE).
