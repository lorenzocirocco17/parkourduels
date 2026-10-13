# Guardian — 800 × 800 stud movement arena

[Download/open Guardian.lua](Guardian.lua), put its contents into a **Script in ServerScriptService** in Roblox Studio, and press **Play**. The script generates `Workspace.Guardian` and runs its lifts, spawns, and fall reset. The file is self-contained; no package installation or texture uploads are needed.

[View the layout diagram](maps/Guardian-layout.png). This is a schematic of the generated geometry, not a Roblox screenshot. The layout follows your Guardian article and screenshots, with inferred geometry adapted for your game.

## Changes in this version

- The playable floor footprint is **exactly 800 × 800 studs**, centered around `CONFIG.Origin`. The forest scenery extends beyond that footprint.
- Rooms, platforms, ramps, bridges, architecture, and scenery have been enlarged horizontally. Main floors remain 16 studs apart, Sniper's upper deck remains another 8 studs higher, and the two optional jump gaps remain **18 real studs** through extended approach runways.
- Added enclosing walls along the main bridges, lower routes, Elbow, outside ramps, and hallway. Added room boundaries and staggered cover with open doorways and clear running lanes.
- Removed duplicate lift-base floors and hallway lips. Flat floors now draw disjoint visible patches over their solid collision geometry, removing overlapping top faces that caused flicker. Main bridge ends extend into circular platforms for full-width floor joins.
- Lift triggers, destinations, lighting range, and fog are adjusted for the enlarged layout. The three lift routes and all four spawns remain available.

## Map routes

Green/tree sits north, Blue south, Sniper west, and Gold east. Elbow connects **Sniper ↔ Green**; the separate L-shaped power-core hallway connects **Blue ↔ Gold**. Bottom Blue/Shotgun Hall connects the lower routes. Center has the open radial upper arena and enclosed Hammer room underneath.

The lift routes are **Gold lower → Gold upper**, **Bottom Blue → Sniper balcony**, and **Green → Gold's camo ledge**. Gold retains its two drop holes beside the shaft. Blue and the power-core hallway have openings into the lower passage. Floor openings enlarge with the surrounding rooms.

## Movement settings

Use your existing movement controller. The generator records walk 16, sprint 21.5 → 29 over 1.2 seconds, flow ×1.05, JumpHeight 7.5, airborne gravity ×0.85, and mantle height 8 as attributes. It does not replace that controller.

The two optional sprint jumps are 18 studs wide. At default Roblox gravity, the ideal JumpHeight/air-float model gives about 18.87 studs of range at speed 29 and 19.81 at full flow, so these shortcuts need a fully ramped sprint. Walking alternatives remain available. Sniper and the stump have marked 8-stud mantle stages; a new approach connects the stump's stages after resizing.

The larger chambers and corridors have room for running around cover. Most primary corridors are roughly 43–61 studs wide before their edge walls and cover; the deliberate jump runways are 18 studs wide. Upper slabs leave 15 studs of clearance below. Your game's air-float and steering can alter lift trajectories, so verify the landings with the controller active.

## Configuration

Edit `CONFIG` near the beginning of the file:

| Option | Effect |
| --- | --- |
| `FootprintStuds` | Default 800; changes the horizontal footprint. Jump gaps and vertical levels stay movement-sized. |
| `Origin` | Center position of the floor footprint; default `(0, 64, 0)`. |
| `RouteWallHeight` | Default 14 studs for main upper-route walls. |
| `SetAtmosphere` | Applies forest lighting/haze; set false before running to keep your lighting. |
| `ForestDetail` | Disables surrounding trunks/canopies/vines when false. |
| `EnableSpawns` | Enables four neutral spawns. Disable other spawn locations if you want everyone on this map. |
| `EnableLifts` | Enables the three launch routes and their approach pads. |
| `LiftGravityMultiplier` | Default 0.85 matches air float; use 1 when testing without it. |
| `EnableVoidReset` / `VoidDepth` | Resets players 40 studs below the map. Disable if other playable areas exist underneath. |
| `MetalTexture` / `StoneTexture` | Optional permitted Roblox texture IDs; otherwise native materials and procedural details supply the appearance. |

`Floors` contains solid collision geometry. Its flat slabs are intentionally invisible; `FloorSurfaces` contains their visible union. Editing one folder without updating the other can change the appearance or collision. Keep the generator as the source of truth when changing layout. Walls collide; forest, glyphs, surface details, and suspended scenery do not obstruct players.

Generated parts are recreated each time the server starts. To inspect or edit a static copy, copy `Workspace.Guardian` during Play, stop, paste it into Workspace, and disable the generator while editing. A pasted static model does not keep lift/fall callbacks, which require the active script or a separate controller.

## Validation

Offline checks parse and execute the Lua using a Roblox API double with real CFrame math. They check lift trajectories and character clearance, supported spawns, drop openings, jump paths, walking routes and ramp turns, safe regeneration, exact floor extent, and visible surface overlap. Rendering checks compare actual WedgePart/Part face geometry with the intended polygons.

Roblox Studio is unavailable in the cloud environment. Actual Humanoid/controller behavior, visible floor quality in motion, multiplayer, and device performance still need Studio playtesting before publishing your place. This version has more geometry than the smaller map; check performance on your target devices.
