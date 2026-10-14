# Primeval Jungle — 550 × 550 stud movement arena

[Download/open PrimevalJungle.lua](PrimevalJungle.lua), put its contents into a **Script in ServerScriptService** in Roblox Studio, and press **Play**. The script generates `Workspace["Primeval Jungle"]` and runs its lifts, spawns, and fall reset. The file is self-contained; no package installation or texture uploads are needed.

`Guardian.lua` remains an identical copy for existing download links. Use only one generator script. When upgrading, replace your previous script; the new generator automatically replaces its older `Guardian` model.

[View the layout diagram](maps/PrimevalJungle-layout.png). This is a schematic of the generated geometry, not a Roblox screenshot. The layout follows your Guardian article and screenshots, with inferred geometry adapted for your game.

[View the forest scenery diagram](maps/PrimevalJungle-scenery.png). This shows the tree placement and leafy underlay; it is not a lighting render.

## Overcast forest and enclosed rooms

The baseplate beneath the arena now uses native **LeafyGrass** and green/brown fallen-leaf detail. A noncolliding underlay covers the view beneath the arena even if your place has no Baseplate. If `Workspace.Baseplate` exists, its material/color are updated and its top checker texture is hidden; its size, position, and collision settings are preserved.

The forest has **384 trees in four close, staggered bands**, with large trunks and overlapping foliage at player height, mid-height, and overhead. The lower crowns close the view between trunks to make a wall of trees around all four sides. Every trunk, canopy, vine, and leaf patch is anchored and has collision, touch, and query disabled. Forest geometry stays outside the playable square.

The supplied photo guides the grey-green weathered stone, inset wall panels, damp floor patterns, moss, cyan lights, and green haze. Blue, Sniper, Green's rear alcove, and the power-core galleries now have additional walls and roofs. Gold has more lower-room boundaries and side walls around its ledge. Doorways, the three lift routes, both sprint jumps, and the central upper disc remain open.

Lighting now uses **overcast noon**, nearly full cloud cover, dimmer grey-green ambient light, denser green Atmosphere haze, and no sun glare. Small room fixtures create pools of light in sheltered areas; cyan/gold accents still mark routes. The generator applies the preset before building geometry and refreshes existing effects on each run. FogStart/FogEnd also supply a fallback; Roblox uses Atmosphere for atmospheric rendering when present.

**To see the lighting in Studio:** replacing a server Script takes effect when you press **Play**. Changes made during Play disappear when you stop. To retain the same preset in the editor, open [PrimevalJungleLighting.lua](PrimevalJungleLighting.lua), copy its contents into Studio's **Command Bar while Play is stopped**, run it, and save your place. This optional file applies lighting only. Reuse or disable other scripts that continually control `Lighting`, since they can override the preset.

## Arena features

- The playable floor footprint is **exactly 550 × 550 studs**, centered around `CONFIG.Origin`. The forest scenery extends beyond that footprint.
- Rooms, platforms, ramps, bridges, and architecture have been reduced from the previous 800-stud version to a 550-stud footprint. Main floors remain 16 studs apart, Sniper's upper deck remains another 8 studs higher, and the two optional jump gaps remain **18 real studs** through extended approach runways.
- Added taller outer room boundaries, sheltered roofs, gallery walls, and recessed panel/moss details. The center remains an open upper arena; outer areas provide enclosed routes with doorways and clear running lanes.
- Removed duplicate lift-base floors and hallway lips. Flat floors now draw disjoint visible patches over their solid collision geometry, removing overlapping top faces that caused flicker. Main bridge ends extend into circular platforms for full-width floor joins.
- Lift triggers, destinations, lighting range, and fog are adjusted for the smaller layout. The three lift routes and all four spawns remain available.

## Map routes

Green/tree sits north, Blue south, Sniper west, and Gold east. Elbow connects **Sniper ↔ Green**; the separate L-shaped power-core hallway connects **Blue ↔ Gold**. Bottom Blue/Shotgun Hall connects the lower routes. Center has the open radial upper arena and enclosed Hammer room underneath.

The lift routes are **Gold lower → Gold upper**, **Bottom Blue → Sniper balcony**, and **Green → Gold's camo ledge**. Gold retains its two drop holes beside the shaft. Blue and the power-core hallway have openings into the lower passage. Floor openings resize with the surrounding rooms.

## Movement settings

Use your existing movement controller. The generator records walk 16, sprint 21.5 → 29 over 1.2 seconds, flow ×1.05, JumpHeight 7.5, airborne gravity ×0.85, and mantle height 8 as attributes. It does not replace that controller.

The two optional sprint jumps are 18 studs wide. At default Roblox gravity, the ideal JumpHeight/air-float model gives about 18.87 studs of range at speed 29 and 19.81 at full flow, so these shortcuts need a fully ramped sprint. Walking alternatives remain available. Sniper and the stump have marked 8-stud mantle stages; a new approach connects the stump's stages after resizing.

The chambers and corridors have room for running around cover. Most primary corridors are roughly 30–42 studs wide before their edge walls and cover; the deliberate jump runways are 18 studs wide. Upper slabs leave 15 studs of clearance below. Your game's air-float and steering can alter lift trajectories, so verify the landings with the controller active.

## Configuration

Edit `CONFIG` near the beginning of the file:

| Option | Effect |
| --- | --- |
| `FootprintStuds` | Default 550; changes the horizontal footprint. Jump gaps and vertical levels stay movement-sized. |
| `Origin` | Center position of the floor footprint; default `(0, 64, 0)`. |
| `RouteWallHeight` | Default 14 studs for main upper-route walls. |
| `SetAtmosphere` | Applies overcast lighting, cloud cover, and green fog; set false before running to keep your lighting. |
| `ForestDetail` | Disables surrounding trunks/canopies/vines when false. |
| `ForestBands` / `ForestTreesPerBand` | Defaults 4 / 96, giving 384 surrounding trees. Reduce these for fewer scenery parts. |
| `ForestEdgeGap` / `ForestBandSpacing` | Defaults 72 / 38 studs; close belts keep crowns outside the arena and close the forest silhouette. |
| `EnableLeafGround` | Adds the leafy underlay and updates an existing Baseplate's appearance. |
| `LeafGroundMargin` / `LeafClusters` | Defaults 330 / 180; controls the underlay's outer coverage and fallen-leaf detail. |
| `LeafTexture` | Optional permitted leaf-litter texture ID; empty uses native LeafyGrass and procedural leaves. |
| `LightingClockTime` / `LightingBrightness` | Defaults 12 / 1.35 for dim, overcast daylight with local room lights. |
| `MistDensity` | Default 0.40; controls the green forest fog. Lower it for less distant haze. |
| `EnableSpawns` | Enables four neutral spawns. Disable other spawn locations if you want everyone on this map. |
| `EnableLifts` | Enables the three launch routes and their approach pads. |
| `LiftGravityMultiplier` | Default 0.85 matches air float; use 1 when testing without it. |
| `EnableVoidReset` / `VoidDepth` | Resets players 40 studs below the map. Disable if other playable areas exist underneath. |
| `MetalTexture` / `StoneTexture` | Optional permitted Roblox texture IDs; otherwise native materials and procedural details supply the appearance. |

`Floors` contains solid collision geometry. Its flat slabs are intentionally invisible; `FloorSurfaces` contains their visible union. Editing one folder without updating the other can change the appearance or collision. Keep the generator as the source of truth when changing layout. Walls collide; forest, glyphs, surface details, and suspended scenery do not obstruct players.

Generated parts are recreated each time the server starts. To inspect or edit a static copy, copy `Workspace["Primeval Jungle"]` during Play, stop, paste it into Workspace, and disable the generator while editing. A pasted static model does not keep lift/fall callbacks, which require the active script or a separate controller.

## Validation

Offline checks parse and execute the Lua using a Roblox API double with real CFrame math. They check lift trajectories and character clearance, supported spawns, drop openings, jump paths, walking routes and ramp turns, safe regeneration, exact floor extent, and visible surface overlap. Surface checks compare actual WedgePart/Part face geometry with the intended polygons. The current revision passes all 39 walking routes, three lift paths, both jumps, four spawns, and four drop openings. Its floor footprint measures 550 × 550 studs; 133 solid wall/roof parts enclose the outer spaces. Forest checks confirm decorative collision flags, clearance from the arena, and foliage in every sampled viewing direction at three player heights. Both runtime and editor lighting presets were executed offline and checked for effect reuse.

Roblox Studio is unavailable in the cloud environment. Actual Humanoid/controller behavior, leaf/forest appearance, lighting visibility, visible floor quality in motion, multiplayer, and device performance still need Studio playtesting before publishing your place. The denser forest adds scenery geometry; check performance on your target devices and reduce the tree/leaf settings if needed.
