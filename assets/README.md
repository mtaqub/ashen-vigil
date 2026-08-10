# Ashen Vigil asset pack

This folder contains original visual and audio assets created for **Ashen Vigil** from the project's style guide. The files are organized for Roblox upload and implementation.

## Folder layout

- `marketing/` — experience icon and wide discovery thumbnail.
- `ui/` — relic icon atlas, cropped relic icons, interface ornament sheet, and the Return to the Vigil button frame.
- `world/` — enemy portrait atlas, cropped enemy portraits, and basalt floor texture.
- `audio/` — lossless mono WAV masters for ambience, combat, pickups, relics, and the boss encounter.
- `roblox-upload/` — standardized upload copies: 512px icons, a 1920×1080 thumbnail, individual UI ornaments, 1024px PBR floor maps, and audio copies.
- `asset-manifest.json` — dimensions, byte sizes, and SHA-256 hashes for every prepared upload file.
- `GENERATION_PROMPTS.md` — the exact built-in image-generation prompt set.

## Connecting assets to the game

1. Upload the image and audio files through Roblox's creator tools under the same account or group that owns the experience.
2. Copy each resulting numeric asset ID into `ReplicatedStorage/Shared/AssetIds`.
3. Publish and test in a private version of the experience before making it public.

The code already supports:

- the cracked-basalt floor texture;
- ambient audio;
- Ashen Dart, Grave Halo, Blackflame Testament, pickup, relic-inheritance, and Warden sounds;
- relic artwork on the three major level-up choices;
- an optional responsive frame for the death screen's Return to the Vigil button.

IDs left as `0` are ignored, so the game still runs before anything is uploaded.

The marketing icon and thumbnail are configured in the experience's publishing/creator settings rather than in `AssetIds`.

For the basalt material, `roblox-upload/world/` contains color, normal, roughness, and metalness maps. The current prototype uses the color map through `AssetIds`; the full set can be applied later through a Roblox material workflow.

## File-to-AssetIds mapping

| File | AssetIds key |
|---|---|
| `roblox-upload/world/cracked-basalt-color-1024.png` | `Images.CrackedBasaltFloor` |
| `roblox-upload/ui/relics/ashen-dart-512.png` | `Images.AshenDart` |
| `roblox-upload/ui/relics/grave-halo-512.png` | `Images.GraveHalo` |
| `roblox-upload/ui/relics/blackflame-testament-512.png` | `Images.BlackflameTestament` |
| `roblox-upload/ui/relics/cinder-oath-512.png` | `Images.CinderOath` |
| `roblox-upload/ui/relics/bell-of-the-nameless-512.png` | `Images.BellOfTheNameless` |
| `roblox-upload/ui/relics/thorned-greatblade-512.png` | `Images.ThornedGreatblade` |
| `roblox-upload/ui/relics/widows-lantern-512.png` | `Images.WidowsLantern` |
| `roblox-upload/ui/relics/reliquary-shield-512.png` | `Images.ReliquaryShield` |
| `roblox-upload/ui/relics/blood-shard-512.png` | `Images.BloodShard` |
| `roblox-upload/ui/ornaments/boss-bar-frame-1024x176.png` | `Images.BossBarFrame` |
| `roblox-upload/ui/ornaments/level-up-sigil-512.png` | `Images.LevelUpSigil` |
| `roblox-upload/ui/ornaments/return-to-vigil-frame-1024x192.png` | `Images.ReturnToVigilFrame` |
| `roblox-upload/world/enemies/night-bat-512.png` | `Images.NightBat` |
| `roblox-upload/world/enemies/ash-ghoul-512.png` | `Images.AshGhoul` |
| `roblox-upload/world/enemies/oathless-brute-512.png` | `Images.OathlessBrute` |
| `roblox-upload/world/enemies/cinder-warden-512.png` | `Images.CinderWarden` |
| `roblox-upload/audio/ashen-vigil-ambient-loop.wav` | `Audio.AmbientLoop` |
| `roblox-upload/audio/ashen-dart-cast.wav` | `Audio.AshenDart` |
| `roblox-upload/audio/blood-shard-pickup.wav` | `Audio.BloodShardPickup` |
| `roblox-upload/audio/grave-halo.wav` | `Audio.GraveHalo` |
| `roblox-upload/audio/blackflame-testament.wav` | `Audio.BlackflameTestament` |
| `roblox-upload/audio/warden-telegraph.wav` | `Audio.WardenTelegraph` |
| `roblox-upload/audio/warden-impact.wav` | `Audio.WardenImpact` |
| `roblox-upload/audio/relic-inherited.wav` | `Audio.RelicInherited` |

## Usage and originality

These assets were created specifically for this prototype. They do not contain extracted commercial-game assets, logos, music, characters, or copied UI. Keep the editable masters with the project, and comply with Roblox's current upload and moderation requirements when publishing them.
