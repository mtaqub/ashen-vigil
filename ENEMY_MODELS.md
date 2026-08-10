# Ashen Vigil enemy models

The project includes original, Roblox-native visual models for every current enemy. They use only built-in Parts and materials: no Toolbox imports, external mesh IDs, Humanoids, pathfinding rigs, or borrowed character designs.

## Included models

| Enemy | Visual parts | Readable silhouette |
|---|---:|---|
| Night Bat | 5 | Narrow cinder-eyed body with a broad ragged wing crescent |
| Ash Ghoul | 5 | Bowed head, long arms, and a tapered funeral shroud |
| Oathless Brute | 7 | Broad basalt torso, heavy pauldrons, and a fractured oath brand |
| Cinder Warden | 22 | Tall asymmetrical armor, five broken crown tines, a chained gauntlet, and a cinder chest fracture |

The existing enemy BasePart remains the invisible gameplay root. `EnemyVisuals.server.lua` attaches the generated model with welds and never replaces, resizes, unanchors, or reparents that root. This preserves movement, targeting, contact damage, health bars, drops, boss attacks, and server cleanup.

## Install in Studio

### Rojo

Both source files are already under `src/ServerScriptService`, so the current `default.project.json` mapping syncs them automatically:

- `MobModelFactory.lua`
- `EnemyVisuals.server.lua`

### Command Bar

After running the main `studio-installer.lua`, paste the complete contents of `enemy-model-installer.lua` into **View → Command Bar** and press **Enter** once. The installer is idempotent. It replaces only `MobModelFactory`, `EnemyVisuals`, and its own `ServerStorage/AshenVigilEnemyModels` template folder.

The template folder contains four real Roblox `Model` instances with a hidden `Root` PrimaryPart. You can clone or drag those models into Workspace for inspection; the live game continues to use the factory-attached versions so its existing gameplay roots remain authoritative.

## Preview all four models

After installation, run this once in Studio's Command Bar while not playing:

```lua
local factory = require(game.ServerScriptService.MobModelFactory)
local old = workspace:FindFirstChild("AshenVigilMobPreview")
if old then old:Destroy() end
factory.CreatePreviewSet(workspace, CFrame.new(0, 0, 0))
```

Delete `Workspace/AshenVigilMobPreview` when finished. During Play, the visual script automatically decorates enemies created inside `Workspace/AshenVigilArena/Enemies`.

## Performance design

Common mobs are static welded assemblies with no per-model animation loops, lights, particles, Humanoids, or collision. At the configured 180-enemy cap, the common-enemy mix stays near one thousand visible parts; the more detailed 22-part Warden exists only once. Only the Warden has one restrained PointLight.

`studio-installer.lua` and its existing builder are intentionally unchanged. The enemy models use their own generated installer so gameplay and model updates remain collision-safe.
