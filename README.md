# OreGlow

A subtle golden screen-edge pulse when WoW Forever exposes a nearby mining
node, or when you hover a real ore blip. The center stays clear and the effect
never captures mouse or keyboard input.

**First test release for Forever 1.60.1, interface 16001.** Automated tests use
a synthetic client; in-game behavior still needs confirmation. Mining names
currently require an **English game client** (enUS/enGB). Settings can be English
or Swedish.

## Install

1. Download **OreGlow-0.1.0.zip** from [Releases](https://github.com/mar-schmidt/OreGlow/releases).
2. Unzip into `World of Warcraft/_forever_/Interface/AddOns/`.
3. Check that the result is `AddOns/OreGlow/OreGlow.toc`.
4. Start WoW or type `/reload`, then `/og test`.
5. For nearby alerts, enable **Interact Key** in **WoW Options > Controls**.
   OreGlow never changes this setting. **Find Minerals** is needed to see
   mining blips on the minimap.

On Mac the usual folder is
`/Applications/World of Warcraft/_forever_/Interface/AddOns/`.

## Detection

| Source | Evidence | Limitation |
| --- | --- | --- |
| Nearby | Live GameObject GUID and exact ore name from `softinteract` | One game-selected interaction target; Interact Key required. |
| Minimap hover | Recognized ore name from the native minimap tooltip | Your real mouse must hover the actual blip. |

Other addon authors report approximately 4–13 metres of nearby detection in
their tests. That range has **not been measured or guaranteed by OreGlow**.
Facing, other objects, terrain and settings may affect the chosen target.

Nearby objects are suppressed by GUID while observed, with a two-minute absence
window. Hover labels cannot identify individual nodes: same-name hovers use a
20-second cooldown and held hovering never repeats. An 8-second bridge suppresses
hover followed by the same kind of nearby ore. Different same-name hovered nodes
may produce one alert. Alerts have a two-second overall minimum interval.

Combat, death and flight taxi pause detection. Unknown/restricted data produces
no alert. No skill filter is applied: ore above your mining skill can alert.

## Controls

| Command | Action |
| --- | --- |
| `/og`, `/oreglow` | Settings |
| `/og test` | Preview one pulse |
| `/og on`, `/og off` | Enable/disable |
| `/og status` | Client, readiness, last detection |
| `/og sv`, `/og en` | Swedish/English |

Nearby and hover alerts have separate switches. Strength is 10–60%, duration
0.5–2 seconds. Default: one soft pulse at 28% for 1.1 seconds. Settings are per
character. No repeating flash mode or alert sound.

### Svenska

Packa upp **OreGlow** i **Interface/AddOns**, kör `/reload`, `/og sv` och
`/og test`. Aktivera **Interact Key** i **Options > Controls** för automatisk
närhetsvarning. Minimappen kräver att du själv hovrar en riktig miningprick.

## Restrictions and development

OreGlow does not use the minimap scan blocked in build 70862, move/resize the
minimap, simulate cursors, read pixels/memory, enumerate world objects or
automate mining. Historical coordinates never prove a live node.
The gold gradients leave Blizzard's low-health warning intact.
This independent project is not individual approval from Blizzard.
See [API references](docs/API.md) and [testing](docs/TESTING.md).

```sh
lua5.1 tests/run.lua
python3 scripts/build_release.py
```

LuaJIT in Lua 5.1 mode also works. No third-party addon is required.
Each push to `master` runs checks and builds a ZIP. A new version tag publishes
a prerelease. MIT licensed; not affiliated with Blizzard Entertainment.
