# Paste this into a fresh ChatGPT conversation

(No repo/file/git access assumed on that side — this is copy-paste only. Send me back whatever it
returns and I'll wire it into the code myself. The full technical reference version of this task,
written for a coding agent with repo access, is in `handoffs/skin-asset-ids.md` if you ever get
Codex set up here — this file is the same task, reformatted for a plain chat conversation.)

---

I'm building a Roblox dark-fantasy survival game called **Ashen Vigil**. I need real Roblox
catalog asset IDs for 5 character skins, to plug into `Humanoid:ApplyDescription()` server-side. I
don't need code — just a clean list of catalog asset IDs with their source URLs. I'll do the
wiring myself.

**Important — tell me your confidence per item.** If you don't have live web browsing in this
conversation, say so up front, and for every ID you give me, mark it either "verified just now by
browsing the catalog page" or "recalled from training data, NOT verified live" — asset IDs get
deleted, moderated, or repurposed constantly, and a wrong/stale one will silently fail in-game
(no crash, just missing clothing), so I need to know exactly which ones I must re-check myself
before using them.

## The 5 target fields and their exact required catalog type

Each skin needs up to 5 optional slots. Getting the **type** wrong is the main failure mode — the
underlying API call throws on a type mismatch, so precision matters more than speed here:

| Slot | Roblox catalog type it must be | Do NOT use |
|---|---|---|
| Shirt | **Classic Shirt** | UGC/layered top, "T-Shirt", template PNG/decal |
| Pants | **Classic Pants** | UGC/layered bottoms |
| Face | **Face** | head accessory, decal, "Dynamic Head" |
| HairAccessory | **Hair** accessory | any other accessory slot |
| BackAccessory | **Back** accessory (capes/wings) | "Shoulder"/"Front"/"Jacket"/"Waist" cloaks — wrong slot, won't apply |

Notes:
- Classic Shirts/Pants are rare in default catalog search now (Roblox pushes UGC layered
  clothing) — search/filter specifically for "Classic Clothing."
- One numeric ID per slot, not a list.
- Prefer **Free** items. Avoid Limited/limited-UGC (can get delisted later). Ownership doesn't
  matter for these types (only Gear needs ownership) — moderation-approved and currently
  available is what matters.

## Art direction — must stay dark

The game is dim and foggy; character skins exist so players never clash with the enemy/environment
palette. **Pick low-value, desaturated, dark clothing only.** Bright, pastel, neon, or
high-contrast items are wrong for this and should not be suggested. Reference key-art: a dark
hooded/cloaked figure, segmented dark armor, a tattered cape, glowing pale blue-white eyes,
tagline "Survive the night. Feed the flame."

Each skin already has procedural geometry added separately (a shoulder mantle, a head wisp, chest
cracks, shoulder smoke, or — for the top-tier skin — gold pauldrons + a chest sigil). Don't
suggest anything that would visually fight those, especially don't add more shoulder armor to the
top-tier skin (it already has big gold pauldrons).

## The 5 skins — priority is Shirt + Pants; Face/Hair/Back are bonus, skip if unsure

**1. Vigil-Bound (Common)** — "The oath's first shape: ash-pale skin beneath a tattered dark
cloak." Near-black clothing, pale blue-white accents. Search: tattered tunic, ragged peasant
shirt (black), dark cloth pants. Optional Back: a Back-type black tattered cape.

**2. The Hollowed (Uncommon)** — "A vessel worn thin by the long night, pale as bone." Muted
purple-grey clothing. Search: bandage wrap shirt, torn grey linen shirt, wrapped/mummy-style
pants. Optional Face: hollow / blank / sunken face.

**3. Cinderbound (Rare)** — "Ember runs beneath the skin, cracked with fading fire." Dark base
with ember-red cracked detailing. Search: cracked ember armor shirt, dark magma armor, charred
robe, dark pants. Optional Face: ember-eye or glowing-crack face.

**4. Nightbound (Epic)** — "Wreathed in blackflame smoke, reaching further than the eye follows."
Dark, violet-tinged. Search: shadow robe shirt, void-weave shirt, dark sorcerer robe, dark pants.
Optional: void/shadow face, and a Back-type black smoke or shadow wings.

**5. Oathsworn (Legendary)** — "Tarnished gold marks an old, patient oath, gilded pauldron to
sigil." Dark base with **thin** tarnished-gold trim only (no big shoulder armor — see note above).
Search: dark knight shirt with gold trim, tarnished paladin armor, dark pants with gold trim.
Optional Face: stern or visored face. Skip Back entirely for this one.

## What to send back

A plain table, one row per item you're confident enough to include:

```
skin          slot    id            type            free?   confidence   url
Vigil-Bound   Shirt   1234567890    Classic Shirt   free    verified     https://www.roblox.com/catalog/1234567890/...
Vigil-Bound   Pants   ...
```

Partial is completely fine — better to leave a skin's slot blank than guess. If you can't verify
something live, still list it but mark it "unverified (training data)" so I know to check it
myself before using it.

