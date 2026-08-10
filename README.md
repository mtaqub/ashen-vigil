# Ashen Vigil

An original ruined dark-fantasy Roblox survival prototype. Cross a moonless burial court, strike automatically with cursed relics, collect blood shards, inherit forbidden rites, and endure a five-minute vigil.

## Fast setup in Roblox Studio

1. Open **Roblox Studio** and create a new **Baseplate** experience.
2. Open **View → Command Bar**.
3. Open `studio-installer.lua`, copy the entire file, paste it into the Command Bar, and press **Enter** once.
4. Open `enemy-model-installer.lua`, copy the entire file, paste it into the Command Bar, and press **Enter** once.
5. Press **Play**.

The installer adds four objects to the experience:

- `ReplicatedStorage/Shared/AssetIds` (created once; preserved on every later run)
- `ReplicatedStorage/Shared/Config`
- `ServerScriptService/GameServer`
- `StarterPlayer/StarterPlayerScripts/GameClient`

The enemy-model installer adds two independent scripts and one template folder without modifying the gameplay script:

- `ServerScriptService/MobModelFactory`
- `ServerScriptService/EnemyVisuals`
- `ServerStorage/AshenVigilEnemyModels` containing four reusable model templates

You can safely run the installer again. It always replaces `Config`, `GameServer`, and `GameClient` with the latest version. `AssetIds` is different: the installer never destroys or blanks it, so any asset IDs you've already uploaded and entered are kept. Re-running the installer only adds newly introduced ID keys to it, defaulted to `0`.

## How to play

- Move with **WASD**, arrow keys, a controller, or the mobile joystick.
- Your Ashen Dart attacks the closest enemies automatically.
- Collect glowing blood shards to gain XP.
- Inherit one of three forsaken relics whenever you level up.
- The **Cinder Warden** arrives at **4:00** with a telegraphed area attack.
- Endure until **5:00** to complete the vigil. Defeating the Warden earns the stronger ending.
- If you fall, select **Return to the Vigil** on the result screen to respawn with a clean slate (starting level, health, and relics) and keep playing in the same server.

## Relics and rites

- **Ashen Dart:** fast automatic projectiles aimed at nearby enemies.
- **Grave Halo:** a recurring close-range ring that damages surrounding foes.
- **Blackflame Testament:** a recurring distant blast that damages clustered foes.
- **Cinder Oath:** a risk/reward rite that increases damage while sacrificing maximum health.
- Other relics increase projectile count, attack speed, range, movement, health, and shard collection.

## Tuning the game

Open `ReplicatedStorage/Shared/Config` in Studio to change the match duration, boss arrival time, arena size, starting stats, enemy health, damage, speed, colors, XP rewards, or relic wording.

For a quick boss test, temporarily set `GAME_DURATION` to `90` and `BOSS_SPAWN_TIME` to `45`.

## Art and audio assets

The project includes an original production asset pack in `assets/`: marketing art, nine relic icons, four enemy portraits, UI ornaments, a seamless floor texture with derived PBR maps, and eight original WAV files. Use the prepared files under `assets/roblox-upload/`, then place the resulting numeric IDs into `ReplicatedStorage/Shared/AssetIds`. See `assets/README.md` for the complete mapping.

When updating an earlier or customized place, follow `UPDATE_EXISTING_GAME.md` before replacing any scripts. It includes backup, installation, conflict checking, asset upload, testing, publishing, troubleshooting, and rollback instructions.

## Enemy models

Night Bat, Ash Ghoul, Oathless Brute, and Cinder Warden now have original Roblox-native 3D models built from low-cost Parts, slate, corroded metal, fabric, and restrained cinder accents. A separate visual script welds each model to the existing gameplay root, so targeting, movement, damage, drops, and boss behavior remain unchanged. See `ENEMY_MODELS.md` for model budgets, installation, and the Studio preview command.

## Rojo workflow (optional)

This folder is also a standard Rojo project. If you already use Rojo, serve `default.project.json` and sync it into a place. The one-file Studio installer is included so Rojo is not required.

## Version control

This project is a git repository. Every change is committed automatically, so the full edit history is available to any tool, editor, or AI assistant you continue the project with — not just a single frozen snapshot.

## Originality note

This prototype draws from the general survivor-like and ruined dark-fantasy genres, but its title, lore, characters, relics, interface, arena, and code are original. Do not import names, characters, logos, maps, music, UI artwork, or other assets from existing commercial games. Use original or properly licensed sounds and artwork before publishing.
