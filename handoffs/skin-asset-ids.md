# Handoff: source real Roblox catalog asset IDs for the 5 character skins

**From:** Claude Code (Mac, `/Users/mtaqub/ashen-vigil`)
**To:** ChatGPT / Codex collaborator
**Date:** 2026-08-27
**Why delegated:** sourcing and verifying real Roblox catalog asset IDs needs live catalog
access and per-item moderation/type checking. Claude has no reliable way to confirm a given
numeric ID is actually a Classic Shirt vs. a moderated or mistyped asset, so this is yours.

---

## Goal

Fill in the placeholder `0`s in **`src/ReplicatedStorage/Shared/AssetIds.lua`**, the
`AssetIds.Characters` table (lines ~48–54), with real, verified Roblox catalog asset IDs so
the 5 themed character skins get actual clothing / face / accessories instead of only
recolored body parts + procedural geometry.

This is a **data-only** change. No code changes are needed or wanted — both consumers already
guard every field with `> 0` and skip it when unset, so partial fills are safe.

---

## The one file to edit

`src/ReplicatedStorage/Shared/AssetIds.lua`:

```lua
AssetIds.Characters = {
	Default     = { Shirt = 0, Pants = 0, Face = 0, HairAccessory = 0, BackAccessory = 0 },
	Hollowed    = { Shirt = 0, Pants = 0, Face = 0, HairAccessory = 0, BackAccessory = 0 },
	Cinderbound = { Shirt = 0, Pants = 0, Face = 0, HairAccessory = 0, BackAccessory = 0 },
	Nightbound  = { Shirt = 0, Pants = 0, Face = 0, HairAccessory = 0, BackAccessory = 0 },
	Oathsworn   = { Shirt = 0, Pants = 0, Face = 0, HairAccessory = 0, BackAccessory = 0 },
}
```

- `Config.AssetIds = require(.../AssetIds)` re-exports this; nothing else needs touching.
- Consumers: `applySkinVisuals` in `src/ServerScriptService/GameServer.server.lua` (spawn),
  and `buildDescriptionForSkin` in `src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua`
  (roll-booth preview). Both read `Config.AssetIds.Characters[skinId]` and apply each field
  only when it is a number `> 0`.
- Keep the existing file's tab indentation and one-line-per-skin style. Match it exactly.

---

## Hard technical constraints — read before picking anything

Each field maps directly onto a `HumanoidDescription` property, and each property wants a
**specific catalog asset type**. A wrong type, a moderated asset, or a deleted asset makes
`Humanoid:ApplyDescription` **throw**.

> As of this handoff the server call is now `pcall`-wrapped (bad ID → `warn` + fall back to
> body-colors-only, no crash), and the client preview was already wrapped. So a bad ID won't
> break the game — but it will silently show *no* clothing and spam warnings. Verify every ID.

| Field in `AssetIds.Characters` | `HumanoidDescription` prop | Must be exactly this catalog Type | Do **not** use |
|---|---|---|---|
| `Shirt`         | `.Shirt`         | **Classic Shirt** (AssetType 11) | UGC/layered top, "T-Shirt", or the uploaded template PNG/decal id |
| `Pants`         | `.Pants`         | **Classic Pants** (AssetType 12) | layered/UGC bottoms |
| `Face`          | `.Face`          | **Face** (AssetType 18)          | head accessory, decal, "Dynamic Head" |
| `HairAccessory` | `.HairAccessory` | **Hair** accessory (AssetType 41)| any other accessory slot |
| `BackAccessory` | `.BackAccessory` | **Back** accessory (AssetType 50)| "Shoulder" / "Front" / "Jacket" / "Waist" cloaks — different slots, will not apply here |

Notes:
- The code assigns a **single raw number** to `HairAccessory` / `BackAccessory` (Roblox
  coerces it). One ID per slot only — don't hand back comma-separated strings.
- **Classic Shirts/Pants are now rare** in default catalog search (Roblox pushes UGC layered
  clothing). Filter the catalog explicitly to **Classic Clothing → Classic Shirts / Classic
  Pants**, or use the marketplace API with `category=Clothing&subcategory=ClassicShirts` /
  `ClassicPants`.
- Ownership is **not** required for clothing / faces / accessories to render via
  `ApplyDescription` (only Gear needs ownership). Still: prefer **Free**, moderation-approved,
  currently-available items. Avoid Limited / limited-UGC (can be delisted → breaks later).

---

## Art direction — the skins must stay dark

The whole point of the re-skin is that the player never clashes with the enemy/environment
palette. The scene is dim and foggy (Lighting.Brightness ~2.9, Ambient `(80,72,102)`, fog
250–580). **Pick low-value, desaturated, dark clothing.** Anything bright, pastel, neon, or
high-contrast defeats the purpose and will be rejected.

Reference key-art the game is built toward: a dark hooded/cloaked figure, segmented dark
armor, tattered cape, glowing pale blue-white eyes. Tagline "Survive the night. Feed the
flame."

Each skin also already has **procedural geometry** welded on (`CharacterAccessories.lua`) —
clothing should complement it, not fight it. Especially **Oathsworn already gets large gold
pauldrons + a chest sigil** proceduraly; do not put a big-shoulder-armor shirt on it.

---

## Per-skin spec (theme, colors, priority)

Priority order per skin: **Shirt + Pants first** (biggest visual payoff). Face / Hair / Back
are bonus — leaving them `0` is fine and better than a wrong guess.

### 1. `Default` — "Vigil-Bound" · Common
- **Theme:** "The oath's first shape: ash-pale skin beneath a tattered dark cloak."
- Body colors: head `(207,196,190)`, torso/arms `(42,38,48)`, legs `(35,32,40)`. Glow: pale blue-white `(190,210,255)`.
- Procedural: shoulder mantle.
- **Want:** ragged/rough dark tunic (Classic Shirt), plain dark cloth trousers (Classic Pants).
  Optional Back: a **Back**-slot black tattered cape (must be Back type, not Shoulder/Front).
- Search: `tattered tunic`, `ragged peasant shirt black`, `dark cloth pants`, `black tattered cape back`.

### 2. `Hollowed` — "The Hollowed" · Uncommon
- **Theme:** "A vessel worn thin by the long night, pale as bone."
- Body colors: head `(245,231,209)`, torso/arms `(70,58,90)`, legs `(56,47,72)`. Glow: bone white `(226,230,235)`.
- Procedural: pale head wisp.
- **Want:** worn wrappings / bandage-look shirt, tattered linen pants, optionally a hollow / blank / sunken **Face**.
- Search: `bandage wrap shirt`, `torn linen shirt grey`, `wrapped mummy pants`, `hollow face` / `blank white face`.

### 3. `Cinderbound` — "Cinderbound" · Rare
- **Theme:** "Ember runs beneath the skin, cracked with fading fire."
- Body colors: head `(200,188,182)`, torso/arms `(38,32,50)`, legs `(30,26,40)`. Glow: ember red `(221,44,83)`.
- Procedural: chest ember cracks.
- **Want:** dark armor / robe shirt with ember-crack or magma detailing (kept dark overall), dark pants, optional ember/glowing-eye **Face**.
- Search: `cracked ember armor shirt`, `magma armor dark`, `charred robe`, `ember eyes face`.

### 4. `Nightbound` — "Nightbound" · Epic
- **Theme:** "Wreathed in blackflame smoke, reaching further than the eye follows."
- Body colors: head `(196,186,190)`, torso/arms `(38,32,50)`, legs `(30,26,40)`. Glow: violet `(107,47,139)`.
- Procedural: shoulder blackflame smoke.
- **Want:** dark smoky robe / shadow-weave shirt, dark pants, optional void / shadow **Face**, optional **Back**-slot black smoke or shadow wings.
- Search: `shadow robe shirt`, `void weave`, `dark sorcerer robe`, `black smoke wings back`, `void face`.

### 5. `Oathsworn` — "Oathsworn" · Legendary
- **Theme:** "Tarnished gold marks an old, patient oath, gilded pauldron to sigil."
- Body colors: head `(207,196,190)`, torso/arms `(52,44,40)`, legs `(40,34,32)`. Glow: tarnished gold `(246,190,77)`.
- Procedural: **gold pauldrons + chest sigil already added** — do not double up on shoulder armor.
- **Want:** dark knight / paladin torso with **thin tarnished-gold trim** (dark base, gold accents only), dark pants with gold trim. Skip Back (cape would fight the pauldrons). Optional stern/visored **Face**.
- Search: `dark knight gold trim shirt`, `tarnished paladin armor`, `black gold crusader`, `gilded armor pants dark`.

---

## Verification checklist — per ID, before it goes in the file

1. Open the actual catalog page: `https://www.roblox.com/catalog/<ID>/<slug>`.
2. Confirm the **Type** shown on the page matches the required type in the table above
   *exactly* ("Classic Shirt", "Classic Pants", "Face", "Hair", "Back").
3. Confirm it is public, moderation-approved, and currently available (not off-sale / deleted).
4. Confirm it reads dark / low-value (see art direction).
5. Prefer Free. If paid, note the price. Skip anything Limited.
6. If possible, sanity-check in Studio: `Humanoid:ApplyDescription` with just that one field set
   on an R15 dummy should not error and should visibly change the avatar.

---

## Deliverable

Preferred: **edit `src/ReplicatedStorage/Shared/AssetIds.lua` directly** with the verified IDs,
**and** append a reference block (as a comment at the bottom of the file, or a separate
`handoffs/skin-asset-ids-sources.md`) listing, per ID:

```
skin        slot    id            type            free?   url
Default     Shirt   1234567890    Classic Shirt   free    https://www.roblox.com/catalog/1234567890/...
Default     Pants   ...
```

so Claude can spot-check. Partial is acceptable — fill what you can verify, leave the rest `0`.

After editing, run the project's Luau balance-check heuristic on `AssetIds.lua` (it's a trivial
file, but house rule) and confirm it still `return`s the table.

---

## Repo rules (from `ashen_vigil_workflow_rules` memory)

- **Never run `git config` or `git push`.** The auto-backup hook commits locally; the user
  pushes from their own terminal.
- **Never hand-edit `studio-installer.lua` / `enemy-model-installer.lua`.** They're generated,
  and currently stale anyway — ignore them; Rojo live-sync is the dev loop.
- Do **not** modify `Config.lua`, `GameServer.server.lua`, `GameClient.client.lua`, or
  `CharacterAccessories.lua` for this task. If a skin's theme text in `Config.Characters`
  genuinely needs a tweak to match a chosen asset, **flag it for Claude/the user** rather than
  editing it yourself.
- `rojo serve` is already running on `localhost:34872`; the user tests in Studio.
- Check `git log` / `git status` when you start in case files moved under you.

---

## Context Claude could not resolve (leave for the user if it blocks you)

- Whether the game runs under a **group** or the user's account — matters only if the user
  wants to **upload custom** Classic Shirt/Pants textures (ideal for theme fidelity, but costs
  Robux per upload and must be owned by the uploader/group). That's a user decision; don't act
  on it, just surface it.

