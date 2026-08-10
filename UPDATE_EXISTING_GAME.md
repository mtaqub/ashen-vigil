# Updating an existing Roblox game with Ashen Vigil

This guide explains how to update a preexisting Roblox Studio place with the latest Ashen Vigil scripts and asset pack. It covers both the earlier prototype and games that have since been customized.

Last verified against Roblox Creator documentation: August 9, 2026.

## What the update changes

The update installs or updates these four objects:

```text
ReplicatedStorage
└── Shared
    ├── AssetIds                ModuleScript (created once, preserved after that)
    └── Config                  ModuleScript

ServerScriptService
└── GameServer                 Script

StarterPlayer
└── StarterPlayerScripts
    └── GameClient             LocalScript
```

Together, they control the arena, enemies, automatic weapons, XP, upgrades, boss encounter, top-down camera, HUD, asset IDs, floor art, and audio.

The installer replaces `Config`, `GameServer`, and `GameClient` outright whenever they have those exact names and locations. It does not merge custom edits inside them. `AssetIds` is handled differently on purpose: the installer never destroys or blanks it. If it already exists, the installer only merges in any ID keys that don't exist yet (leaving every ID you've already uploaded untouched); if it doesn't exist yet, the installer creates it and migrates any real IDs found in an older, pre-split `Config.AssetIds` table.

## Before changing anything

1. Open the exact place you intend to update in Roblox Studio.
2. Make sure no playtest is running. Select **Stop** if necessary.
3. Save a local `.rbxl` backup or duplicate the place before continuing.
4. If the experience is already published, confirm that you can access its **Version History** as an additional rollback option.
5. If multiple people edit the experience, tell them that you are replacing the gameplay scripts.

Roblox exposes place Version History through Experience Settings, but a separate local copy remains the safest immediate rollback. See [Experience Settings](https://create.roblox.com/docs/studio/experience-settings) and [publishing places](https://create.roblox.com/docs/production/publishing/publish-games-and-places).

## Choose the correct update route

### Route A — Earlier Nightfall Survivors or Ashen Vigil prototype

Use this route when the existing place was created with the previous installer and the three scripts above have not been substantially customized.

The new installer can replace all three scripts together. This is the recommended route for this project.

### Route B — Customized or unrelated preexisting game

Use this route if your game already has its own camera, character loader, round system, enemies, arena, HUD, or scripts with the same responsibilities.

Do not immediately run the installer in a live production place. First make a duplicate place and review the conflict checklist below. The Ashen Vigil server script sets `Players.CharacterAutoLoads` to `false`, loads characters itself, builds an arena, changes Lighting, and runs its own enemy and round loop. The client script takes control of the camera and creates its own HUD.

## Route A: replace the previous prototype

### 1. Extract the latest package

Use either:

- `ashen-vigil-roblox.zip` for the complete project; or
- the uncompressed `nightfall-survivors` folder.

Locate this file:

```text
studio-installer.lua
```

### 2. Open the Studio Command Bar

In current Studio, the Command Bar is available from the **Script** toolbar or **Window → Script**, and the shortcut is **Ctrl+9** on Windows or **Command+9** on macOS. If multiline editing is unavailable, enable **File → Beta Features → Multi-line Command Bar** and restart Studio. See Roblox's [Studio interface guide](https://create.roblox.com/docs/studio/ui-overview).

### 3. Run the installer

1. Open `studio-installer.lua` in a text editor.
2. Select and copy the entire file.
3. Paste it into the Studio Command Bar.
4. Click **Run**, or press **Ctrl+Enter** on Windows / **Command+Enter** on macOS.
5. Open **Output** and confirm this message appears:

```text
Ashen Vigil installed! Press Play to begin.
```

### 4. Verify the script locations

In Explorer, confirm that all four objects exist:

- `ReplicatedStorage/Shared/AssetIds`
- `ReplicatedStorage/Shared/Config`
- `ServerScriptService/GameServer`
- `StarterPlayer/StarterPlayerScripts/GameClient`

Update `Config`, `GameServer`, and `GameClient` together. A new client with an old server, or an old client with a new server, can wait for remotes that never appear.

### Manual fallback

If the installer cannot run, create the objects manually and paste in the matching source files:

| Studio destination | Project source file |
|---|---|
| `ReplicatedStorage/Shared/AssetIds` | `src/ReplicatedStorage/Shared/AssetIds.lua` |
| `ReplicatedStorage/Shared/Config` | `src/ReplicatedStorage/Shared/Config.lua` |
| `ServerScriptService/GameServer` | `src/ServerScriptService/GameServer.server.lua` |
| `StarterPlayer/StarterPlayerScripts/GameClient` | `src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua` |

All four are **ModuleScripts** except `GameServer` (a **Script**) and `GameClient` (a **LocalScript**). If you're migrating manually from an older place where asset IDs still live inline in `Config.AssetIds`, copy those numeric values into the new `AssetIds` module before you overwrite `Config`.

## Route B: merge into a customized game

Perform this work in a duplicate or private test place.

### 1. Preserve customized scripts

If any of these already contain your work, rename copies before installing:

```text
Config_CustomBackup
GameServer_CustomBackup
GameClient_CustomBackup
```

Disable the backup Script and LocalScript copies so they do not run simultaneously.

### 2. Check for system conflicts

Only one active system should own each responsibility.

| Responsibility | Ashen Vigil owner | What to check in your game |
|---|---|---|
| Character spawning | `GameServer` | Existing lobby, respawn, checkpoint, or round loader |
| Camera | `GameClient` | Existing camera or lock-on LocalScripts |
| HUD | `GameClient` | Existing ScreenGuis, health bars, XP bars, result screens |
| Enemies | `GameServer` | Existing NPC spawners, AI, combat, damage handlers |
| Match flow | `GameServer` | Existing timers, waves, win conditions, teleport flow |
| World | `GameServer` | Existing arena generator, map loader, spawn locations |
| Lighting | `GameServer` | Existing day/night cycle, Atmosphere, fog, post-processing |
| Audio | `GameServer` | Existing ambience and sound manager |

For the fastest safe merge, keep Ashen Vigil's three scripts intact and disable the overlapping systems in the duplicate place. After the prototype works, reintroduce custom features one system at a time.

### 3. Merge custom configuration carefully

Move only intentional values into the new `Config`, such as match duration, health, damage, movement, and enemy tuning. Do not replace the entire new Config with an old copy because the current scripts require `BOSS_SPAWN_TIME`, `FLOOR_MATERIAL_VARIANT`, the Warden definition, and the newer relic definitions. Uploaded asset IDs live in the separate `AssetIds` module (see above) and are preserved automatically; you do not need to hand-copy them.

## Uploading the asset files

Use the prepared files under:

```text
assets/roblox-upload/
```

Roblox Studio's Asset Manager is available from the **Window** menu or **Home** tab. Its Import action accepts images and audio, and uploaded assets enter moderation before they can appear publicly. See the official [Asset Manager guide](https://create.roblox.com/docs/projects/assets/manager).

### Ownership selection

Upload assets under the same creator that owns the experience:

- For a personal experience, use your own creator account.
- For a group-owned experience, upload under that group when Studio offers the creator choice.

Private audio is permission-controlled. If audio was uploaded under a different owner, grant the target experience permission through Creator Dashboard or the current Asset Manager. See [asset privacy](https://create.roblox.com/docs/projects/assets/privacy) and [audio assets](https://create.roblox.com/docs/audio/assets).

### Import images

1. Open **Asset Manager**.
2. Select **Import**.
3. Import the current-use image files listed below.
4. Wait for each import to complete.
5. Right-click each uploaded item and select **Copy Asset ID**.
6. Record the numeric portion of every ID.

### Import audio

Import the eight WAV files from `assets/roblox-upload/audio/` the same way. The included files are mono, 44.1 kHz, shorter than Roblox's duration and size limits, and were created specifically for this project. Roblox documents support for WAV, MP3, OGG, and FLAC uploads in its [audio asset guide](https://create.roblox.com/docs/audio/assets).

Audio may remain silent until moderation finishes and the experience has usage permission.

## Files used by the current build

### Marketing files

These do not go into `Config`:

| Purpose | File |
|---|---|
| Experience icon | `roblox-upload/marketing/experience-icon-512.png` |
| Experience thumbnail | `roblox-upload/marketing/experience-thumbnail-1920x1080.png` |

Roblox recommends a 512×512 experience icon and an ideally 1920×1080, 16:9 image thumbnail. Upload the icon and thumbnail through Creator Dashboard for the correct place. See [experience icons](https://create.roblox.com/docs/production/publishing/experience-icons) and [thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails).

### Images currently connected to gameplay

| Config key | Upload file |
|---|---|
| `Images.CrackedBasaltFloor` | `roblox-upload/world/cracked-basalt-color-1024.png` |
| `Images.GraveHalo` | `roblox-upload/ui/relics/grave-halo-512.png` |
| `Images.BlackflameTestament` | `roblox-upload/ui/relics/blackflame-testament-512.png` |
| `Images.CinderOath` | `roblox-upload/ui/relics/cinder-oath-512.png` |
| `Images.BossBarFrame` | `roblox-upload/ui/ornaments/boss-bar-frame-1024x176.png` |
| `Images.LevelUpSigil` | `roblox-upload/ui/ornaments/level-up-sigil-512.png` |

### Audio currently connected to gameplay

| Config key | Upload file |
|---|---|
| `Audio.AmbientLoop` | `roblox-upload/audio/ashen-vigil-ambient-loop.wav` |
| `Audio.AshenDart` | `roblox-upload/audio/ashen-dart-cast.wav` |
| `Audio.BloodShardPickup` | `roblox-upload/audio/blood-shard-pickup.wav` |
| `Audio.GraveHalo` | `roblox-upload/audio/grave-halo.wav` |
| `Audio.BlackflameTestament` | `roblox-upload/audio/blackflame-testament.wav` |
| `Audio.WardenTelegraph` | `roblox-upload/audio/warden-telegraph.wav` |
| `Audio.WardenImpact` | `roblox-upload/audio/warden-impact.wav` |
| `Audio.RelicInherited` | `roblox-upload/audio/relic-inherited.wav` |

Other relic and enemy portraits are prepared for future inventory, bestiary, and character-selection screens. Uploading them now is optional.

## Enter the uploaded asset IDs

Open:

```text
ReplicatedStorage → Shared → AssetIds
```

Replace each required `0` with the matching numeric asset ID. This module is preserved by the installer across future updates, so entering IDs here is a one-time task per experience.

Example only:

```lua
AssetIds.Audio = {
	AmbientLoop = 1234567890,
	AshenDart = 1234567891,
	BloodShardPickup = 1234567892,
	GraveHalo = 1234567893,
	BlackflameTestament = 1234567894,
	WardenTelegraph = 1234567895,
	WardenImpact = 1234567896,
	RelicInherited = 1234567897,
}

AssetIds.Images = {
	CrackedBasaltFloor = 2234567890,
	GraveHalo = 2234567891,
	BlackflameTestament = 2234567892,
	CinderOath = 2234567893,
	BossBarFrame = 2234567894,
	LevelUpSigil = 2234567895,
	-- Optional and future-use keys can remain 0.
}
```

Use numbers only. Do not paste `rbxassetid://` into `AssetIds`; the scripts add that prefix automatically. A value of `0` is intentionally ignored.

## Optional: install the full PBR basalt material

The automatic setup needs only the color map above. For richer surface lighting, the pack also includes:

```text
cracked-basalt-color-1024.png
cracked-basalt-normal-1024.png
cracked-basalt-roughness-1024.png
cracked-basalt-metalness-1024.png
```

To use all four:

1. Open **Window → 3D → Material** to open Material Manager.
2. Select a stone-like base material such as Slate.
3. Create a new Material Variant.
4. Name it exactly `AshenBasalt`.
5. Import the color, normal, roughness, and metalness maps into their matching fields.
6. Adjust **Studs Per Tile** until it looks appropriate from the top-down camera.
7. In `Config`, set:

```lua
Config.FLOOR_MATERIAL_VARIANT = "AshenBasalt"
```

Roblox's PBR workflow maps these four images to `ColorMap`, `NormalMap`, `RoughnessMap`, and `MetalnessMap`. See [assembling an asset library](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library) and the [MaterialVariant reference](https://create.roblox.com/docs/reference/engine/classes/MaterialVariant/MaterialPattern).

If you use the full MaterialVariant, you may leave `Images.CrackedBasaltFloor` at `0` to avoid layering the basic top texture over the custom material.

## Update the public icon and thumbnail

### Icon

1. Open Creator Dashboard and select the experience.
2. Go to **Configure → Places**.
3. Select the start place marked with a star.
4. Select **Icon**, choose Image, and upload `experience-icon-512.png`.
5. Preview and save the change.

### Thumbnail

1. In the same place configuration, open **Thumbnails**.
2. Choose the Home Page or Experience Detail Page location.
3. Upload `experience-thumbnail-1920x1080.png`.
4. Add useful alt text, arrange it as desired, and save.

Both images must pass moderation before other users see them.

## Test before publishing

Open **Output** before testing so errors are visible. Roblox's solo playtest runs separate client and server simulations, and Studio lets you toggle between them. See [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes).

### Normal smoke test

Press **F5** and verify:

- the title reads **Ashen Vigil**;
- the camera moves to the top-down view;
- the player spawns at the ritual circle;
- enemies spawn and move toward the player;
- Ashen Dart attacks automatically;
- blood shards grant XP;
- the first level offers Grave Halo, Blackflame Testament, and Cinder Oath;
- uploaded relic icons appear on those choices;
- the floor texture or MaterialVariant appears;
- ambient, attack, pickup, upgrade, and ability audio plays;
- no red errors appear in Output on the client or server.

### Quick boss test

Temporarily change:

```lua
Config.GAME_DURATION = 90
Config.BOSS_SPAWN_TIME = 45
```

Verify that the Cinder Warden appears, the boss frame displays, the expanding warning ring precedes its impact, and both boss sounds play.

After testing, restore:

```lua
Config.GAME_DURATION = 300
Config.BOSS_SPAWN_TIME = 240
```

### Device test

Use Studio's Device Emulator to inspect at least one phone-sized display and one desktop display. Confirm the level-up choices, boss bar, relic panel, health panel, and controls hint remain visible.

## Troubleshooting

### The installer ran, but the game waits forever

Make sure all three scripts were updated together. The client waits for `AshenVigilRemotes`, which the current server creates.

### Two HUDs or two cameras appear

An older client, camera, or UI script is still enabled. Search StarterPlayerScripts and StarterGui for the previous system and disable it in the test copy.

### The player does not spawn correctly

Another script may be controlling character loading. Ashen Vigil sets `Players.CharacterAutoLoads = false` and calls `LoadCharacter()` itself. Disable one of the competing spawn systems.

### Two arenas or enemy groups appear

An older map or enemy spawner is still running. Disable the previous round/gameplay server script.

### Images are blank

- Confirm moderation has finished.
- Confirm the ID is in the correct `AssetIds` key.
- Use the numeric ID only.
- Confirm the upload belongs to the correct creator or is shared with the experience.

### Audio is silent

- Wait for moderation.
- Confirm the experience has permission to use the private audio.
- Check the numeric IDs and Output errors.
- Make sure Studio and in-game volume are not muted.

### The floor remains plain

- For the basic method, check `Images.CrackedBasaltFloor`.
- For PBR, confirm the MaterialVariant is under `MaterialService` and its name exactly matches `Config.FLOOR_MATERIAL_VARIANT`.
- Do not use both methods until each works independently.

### The level-up icons do not appear

The current interface uses only `Images.GraveHalo`, `Images.BlackflameTestament`, and `Images.CinderOath` during the guaranteed first relic choice. Check those three IDs first.

## Publish and rollback

When the private test is successful:

1. Stop the playtest.
2. Save the place.
3. Confirm the quick-test timer values were restored.
4. Publish to the same intended place—not a different experience or start place.
5. Join the published private experience once and perform a short live smoke test.
6. Make the update public only after images and audio have cleared moderation.

If the update fails, do not continue publishing fixes over the broken place. Restore the local `.rbxl` backup or open the previous place version from Version History, then retry the merge in a duplicate place.

## Final checklist

- [ ] Local or duplicate-place backup created
- [ ] Correct update route selected
- [ ] Config, GameServer, and GameClient updated together
- [ ] Current-use images uploaded
- [ ] Eight WAV files uploaded and permitted for the experience
- [ ] Numeric IDs entered into the correct AssetIds keys
- [ ] Icon and thumbnail updated in Creator Dashboard
- [ ] Desktop playtest passed
- [ ] Mobile layout test passed
- [ ] Quick boss test passed
- [ ] Match and boss timers restored to 300 and 240
- [ ] No client or server errors in Output
- [ ] Published private build smoke-tested before public release
