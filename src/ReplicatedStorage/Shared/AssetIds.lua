-- Persistent Roblox asset-ID bindings.
--
-- This module is intentionally separate from Config so the Studio installer can
-- preserve every ID you upload here across reinstalls and version updates. The
-- installer only ever creates this module if it is missing, or merges newly
-- added keys into it -- it never destroys or blanks an existing AssetIds module.
--
-- Upload the matching files from the assets folder, then replace each 0 with
-- its Roblox asset ID. The game remains fully playable while these are 0.
local AssetIds = {}

AssetIds.Audio = {
	AmbientLoop = 98712843823565,
	AshenDart = 119710337369154,
	BloodShardPickup = 99242437948595,
	GraveHalo = 136083841619004,
	BlackflameTestament = 131762630077344,
	WardenTelegraph = 134810841210436,
	WardenImpact = 92413204062663,
	RelicInherited = 98814738694091,
}

AssetIds.Images = {
	CrackedBasaltFloor = 75542242194712,
	AshenDart = 87992621506340,
	GraveHalo = 140539256054693,
	BlackflameTestament = 93144476185663,
	CinderOath = 138658408005069,
	BellOfTheNameless = 117052258283478,
	ThornedGreatblade = 116834845281187,
	WidowsLantern = 113787177390537,
	ReliquaryShield = 137039293149986,
	BloodShard = 80102189370590,
	BossBarFrame = 138449954536966,
	LevelUpSigil = 138161294671061,
	ReturnToVigilFrame = 129167933301092,
	NightBat = 96290830183351,
	AshGhoul = 94752802248532,
	OathlessBrute = 72961047904128,
	CinderWarden = 130595313908517,
}

-- Optional clothing/accessory ids per Config.Characters skin id. BodyColors
-- alone already keep every skin in the game's dark palette (see Config.lua),
-- so the game looks correct with all of these left at 0 -- fill them in once
-- real catalog or custom-uploaded assets exist for a skin, no code changes
-- needed elsewhere (see GameServer.server.lua's applySkinVisuals).
-- Shirt/Pants sourced 2026-08-27 (ChatGPT catalog search, independently
-- verified against economy.roblox.com/v2/assets/<id>/details -- AssetTypeId
-- 11/12 confirmed for every id below, all for-sale and not moderated).
-- Face/HairAccessory/BackAccessory intentionally left unset -- no confident
-- match found; the game reads them defensively so this is fine as-is.
AssetIds.Characters = {
	Default = { Shirt = 5101768107, Pants = 15962675091, Face = 0, HairAccessory = 0, BackAccessory = 0 },
	Hollowed = { Shirt = 127533745306436, Pants = 132581778104117, Face = 0, HairAccessory = 0, BackAccessory = 0 },
	Cinderbound = { Shirt = 78824205944743, Pants = 103730476523038, Face = 0, HairAccessory = 0, BackAccessory = 0 },
	Nightbound = { Shirt = 12865457840, Pants = 12865516849, Face = 0, HairAccessory = 0, BackAccessory = 0 },
	Oathsworn = { Shirt = 11277693358, Pants = 11277693922, Face = 0, HairAccessory = 0, BackAccessory = 0 },
}

return AssetIds
