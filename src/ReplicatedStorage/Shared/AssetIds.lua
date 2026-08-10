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

return AssetIds
