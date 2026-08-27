local Config = {}

-- Interval (seconds) between Warden spawns in the persistent Vigil: it recurs
-- forever rather than spawning once, since the arena itself never resets.
Config.BOSS_SPAWN_TIME = 240
Config.ARENA_SIZE = 440
Config.MAX_ENEMIES = 180
-- Extra live-enemy headroom granted per in-Vigil player beyond the first, so
-- a fuller Vigil can sustain more concurrent enemies without diluting
-- pressure on any one player.
Config.MAX_ENEMIES_PER_PLAYER = 60
-- Optional: after creating a MaterialVariant in Studio, put its exact name here.
Config.FLOOR_MATERIAL_VARIANT = ""
Config.STARTING_HEALTH = 100
Config.STARTING_DAMAGE = 12
Config.STARTING_ATTACK_SPEED = 1
Config.STARTING_RANGE = 48
Config.STARTING_PICKUP_RADIUS = 10
Config.STARTING_WALK_SPEED = 17
Config.STATE_UPDATE_INTERVAL = 0.15

Config.XP = {
	Base = 5,
	PerLevel = 4,
	Exponent = 1.22,
}

Config.Combat = {
	AttackPeriodBase = 0.78,
	AttackPeriodMin = 0.13,
	EnemyContactCooldown = 0.8,
	EnemyContactMinDistance = 3.3,
	EnemyContactDistancePadding = 2,
}

Config.Boss = {
	PulseRadius = 29,
	PulseTelegraphDelay = 0.82,
	PulseInterval = 5.5,
	PulseDamage = 22,
}

-- Enemy difficulty scales off the average level of players currently in the
-- Vigil (not elapsed time, since the arena runs forever) so a freshly
-- respawned level-1 player isn't dropped into a fight calibrated for
-- veterans. Same "divisor + cap" shape as before, just driven by
-- (averageLevel - 1) instead of elapsedTime.
Config.Difficulty = {
	HealthScaleDivisor = 15,
	SpeedScaleDivisor = 40,
	SpeedScaleCap = 1.35,
	DamageScaleDivisor = 30,
	DamageScaleCap = 1.5,
}

Config.Spawn = {
	BaseRate = 1.4,
	RatePerSecond = 0.022,
	MaxRate = 8,
	-- Additional spawn capacity (enemies/sec) per in-Vigil player beyond the
	-- first, so pressure-per-player stays roughly constant as people join.
	RatePerPlayer = 1,
	BruteUnlockTime = 120,
	BruteBaseChance = 0.08,
	BruteChancePerSecond = 1 / 2500,
	BruteChanceCap = 0.2,
	GhoulUnlockTime = 35,
	GhoulBaseChance = 0.34,
	GhoulChancePerSecond = 1 / 1000,
	GhoulChanceCap = 0.62,
}

Config.Gems = {
	Lifetime = 90,
	PickupMergeDistance = 2.8,
	MagnetBaseSpeed = 22,
	MagnetSpeedPerStud = 5,
}

-- Embers per roll at the Lobby's roll booth. Reserving/swapping between the
-- equipped and reserved skin is always free; only rolling costs Embers (or
-- Robux, via this Developer Product -- "Roll for a Vigil-Bound").
Config.RollCost = 150
Config.RobuxRollProductId = 3710061933

-- Themed characters applied via Humanoid:ApplyDescription() on spawn (see
-- GameServer.server.lua's applySkinVisuals), replacing the player's default
-- Roblox avatar so it never clashes with the enemy/environment palette.
-- Each carries one small, distinct gameplay bonus (statBoost) applied on top
-- of GameState.applyInitialState using the same fields the relic Effects
-- system already uses, so it stacks the same way. Shirt/Pants/accessory
-- asset ids are optional and live in AssetIds.Characters — unset (0) until
-- real catalog/uploaded assets are sourced; BodyColors alone already keep
-- every skin in the game's dark ashen palette.
-- Roll odds and display color/name per rarity tier. Config.Characters
-- entries reference these by key rather than duplicating weight/color, so
-- there's one place to rebalance odds.
Config.Rarities = {
	Common = { name = "Common", color = Color3.fromRGB(180, 178, 184), weight = 40 },
	Uncommon = { name = "Uncommon", color = Color3.fromRGB(110, 200, 120), weight = 27 },
	Rare = { name = "Rare", color = Color3.fromRGB(90, 150, 230), weight = 18 },
	Epic = { name = "Epic", color = Color3.fromRGB(170, 90, 220), weight = 11 },
	Legendary = { name = "Legendary", color = Color3.fromRGB(246, 190, 77), weight = 4 },
}

-- One skin per rarity tier. Higher rarity stacks more statBoost fields
-- (Common/Uncommon: 1, Rare/Epic: 2, Legendary: 3) rather than inventing new
-- mechanics -- every field here is one applySkinStatBoost already applies.
-- Visual distinctiveness beyond BodyColors comes from CharacterAccessories
-- (procedural Part geometry welded on, same technique as MobModelFactory/
-- RelicModelFactory -- no catalog assets needed).
Config.Characters = {
	{
		id = "Default",
		name = "Vigil-Bound",
		rarity = "Common",
		description = "The oath's first shape: ash-pale skin beneath a tattered dark cloak. +1 movement speed.",
		bodyColors = {
			head = Color3.fromRGB(207, 196, 190),
			torso = Color3.fromRGB(42, 38, 48),
			leftArm = Color3.fromRGB(42, 38, 48),
			rightArm = Color3.fromRGB(42, 38, 48),
			leftLeg = Color3.fromRGB(35, 32, 40),
			rightLeg = Color3.fromRGB(35, 32, 40),
		},
		glowColor = Color3.fromRGB(190, 210, 255),
		statBoost = { walkSpeedBonus = 1 },
	},
	{
		id = "Hollowed",
		name = "The Hollowed",
		rarity = "Uncommon",
		description = "A vessel worn thin by the long night, pale as bone. +25 maximum health.",
		bodyColors = {
			head = Color3.fromRGB(245, 231, 209),
			torso = Color3.fromRGB(70, 58, 90),
			leftArm = Color3.fromRGB(70, 58, 90),
			rightArm = Color3.fromRGB(70, 58, 90),
			leftLeg = Color3.fromRGB(56, 47, 72),
			rightLeg = Color3.fromRGB(56, 47, 72),
		},
		glowColor = Color3.fromRGB(226, 230, 235),
		statBoost = { maxHealthBonus = 25 },
	},
	{
		id = "Cinderbound",
		name = "Cinderbound",
		rarity = "Rare",
		description = "Ember runs beneath the skin, cracked with fading fire. +12% damage, +5% attack speed.",
		bodyColors = {
			head = Color3.fromRGB(200, 188, 182),
			torso = Color3.fromRGB(38, 32, 50),
			leftArm = Color3.fromRGB(38, 32, 50),
			rightArm = Color3.fromRGB(38, 32, 50),
			leftLeg = Color3.fromRGB(30, 26, 40),
			rightLeg = Color3.fromRGB(30, 26, 40),
		},
		glowColor = Color3.fromRGB(221, 44, 83),
		statBoost = { damageMultiplier = 1.12, attackSpeedMultiplier = 1.05 },
	},
	{
		id = "Nightbound",
		name = "Nightbound",
		rarity = "Epic",
		description = "Wreathed in blackflame smoke, reaching further than the eye follows. +15% attack speed, +3 blood-shard pickup radius.",
		bodyColors = {
			head = Color3.fromRGB(196, 186, 190),
			torso = Color3.fromRGB(38, 32, 50),
			leftArm = Color3.fromRGB(38, 32, 50),
			rightArm = Color3.fromRGB(38, 32, 50),
			leftLeg = Color3.fromRGB(30, 26, 40),
			rightLeg = Color3.fromRGB(30, 26, 40),
		},
		glowColor = Color3.fromRGB(107, 47, 139),
		statBoost = { attackSpeedMultiplier = 1.15, pickupRadiusBonus = 3 },
	},
	{
		id = "Oathsworn",
		name = "Oathsworn",
		rarity = "Legendary",
		description = "Tarnished gold marks an old, patient oath, gilded pauldron to sigil. +10% damage, +15 maximum health, +3 pickup radius.",
		bodyColors = {
			head = Color3.fromRGB(207, 196, 190),
			torso = Color3.fromRGB(52, 44, 40),
			leftArm = Color3.fromRGB(52, 44, 40),
			rightArm = Color3.fromRGB(52, 44, 40),
			leftLeg = Color3.fromRGB(40, 34, 32),
			rightLeg = Color3.fromRGB(40, 34, 32),
		},
		glowColor = Color3.fromRGB(246, 190, 77),
		statBoost = { damageMultiplier = 1.10, maxHealthBonus = 15, pickupRadiusBonus = 3 },
	},
}

-- Daily/weekly quests are randomly drawn from these template pools (see
-- Quests.lua). `kind` matches the event names Enemies.lua/Upgrades.lua/
-- GameServer.server.lua report progress under.
Config.Quests = {
	DailyActiveCount = 3,
	WeeklyActiveCount = 2,
	Daily = {
		{ id = "DailyKillsSmall", kind = "kills", target = 20, reward = 35, title = "Banish 20 Forsaken", description = "Slay 20 enemies in the Vigil." },
		{ id = "DailyKills", kind = "kills", target = 40, reward = 60, title = "Banish 40 Forsaken", description = "Slay 40 enemies in the Vigil." },
		{ id = "DailyLevel", kind = "level", target = 6, reward = 50, title = "Reach Level 6", description = "Reach level 6 in a single vigil." },
		{ id = "DailySurvive", kind = "vigilMinutes", target = 4, reward = 45, title = "Survive 4 Minutes", description = "Endure 4 minutes in a single vigil." },
		{ id = "DailyBoss", kind = "bossDefeats", target = 1, reward = 80, title = "Fell the Warden", description = "Defeat the Cinder Warden once." },
	},
	Weekly = {
		{ id = "WeeklyKills", kind = "kills", target = 300, reward = 350, title = "Banish 300 Forsaken", description = "Slay 300 enemies this week." },
		{ id = "WeeklyLevel", kind = "level", target = 12, reward = 300, title = "Reach Level 12", description = "Reach level 12 in a single vigil." },
		{ id = "WeeklyBoss", kind = "bossDefeats", target = 3, reward = 400, title = "Sunder the Oath Thrice", description = "Defeat the Cinder Warden 3 times." },
		{ id = "WeeklySurvive", kind = "vigilMinutes", target = 30, reward = 320, title = "Endure 30 Minutes", description = "Accumulate 30 minutes survived in the Vigil this week." },
	},
}

-- Asset IDs live in the sibling AssetIds ModuleScript, not inline here, so the
-- Studio installer can preserve every uploaded ID across reinstalls. See
-- ReplicatedStorage/Shared/AssetIds for the editable table.
Config.AssetIds = require(script.Parent:WaitForChild("AssetIds"))

Config.Enemies = {
	Bat = {
		Name = "Night Bat",
		Health = 20,
		Speed = 10,
		Damage = 7,
		XP = 1,
		Size = Vector3.new(3.2, 1.5, 2.2),
		Color = Color3.fromRGB(137, 77, 255),
	},
	Ghoul = {
		Name = "Ash Ghoul",
		Health = 65,
		Speed = 6.5,
		Damage = 13,
		XP = 3,
		Size = Vector3.new(4, 5, 4),
		Color = Color3.fromRGB(99, 197, 124),
	},
	Brute = {
		Name = "Oathless Brute",
		Health = 180,
		Speed = 4.5,
		Damage = 22,
		XP = 8,
		Size = Vector3.new(7, 7, 7),
		Color = Color3.fromRGB(201, 48, 70),
	},
	Warden = {
		Name = "The Cinder Warden",
		Health = 2600,
		Speed = 3.8,
		Damage = 30,
		XP = 60,
		Size = Vector3.new(10, 13, 8),
		Color = Color3.fromRGB(71, 63, 72),
	},
}

Config.Upgrades = {
	RapidFire = {
		Title = "Fervent Rite",
		Description = "+20% attack speed. The oath quickens.",
		Effect = { AttackSpeedMultiplier = 1.2 },
	},
	Power = {
		Title = "Tarnished Edge",
		Description = "+8 damage per ashen dart.",
		Effect = { DamageBonus = 8 },
	},
	Multishot = {
		Title = "Forked Hex",
		Description = "+1 projectile, up to five.",
		Effect = { MaxProjectiles = 5 },
	},
	Range = {
		Title = "Far-Reaching Oath",
		Description = "+12 attack range.",
		Effect = { RangeBonus = 12 },
	},
	Magnet = {
		Title = "Gravecall",
		Description = "+6 blood-shard pickup radius.",
		Effect = { PickupRadiusBonus = 6 },
	},
	Speed = {
		Title = "Exile's Step",
		Description = "+2 movement speed.",
		Effect = { WalkSpeedBonus = 2, MaxWalkSpeed = 28 },
	},
	Vitality = {
		Title = "Vessel of Ash",
		Description = "+25 maximum health and restore 25.",
		Effect = { MaxHealthBonus = 25 },
	},
	GraveHalo = {
		Title = "Grave Halo",
		Description = "Periodically unleash a close-range ring of ruin.",
		Effect = {
			MaxRank = 5,
			InitialClock = 2.5,
			BaseRadius = 17,
			RadiusPerRank = 3,
			BaseDamage = 18,
			DamagePerRank = 12,
			BasePeriod = 5.1,
			PeriodPerRank = 0.35,
			MinPeriod = 2.4,
		},
	},
	Blackflame = {
		Title = "Blackflame Testament",
		Description = "Periodically immolate a distant enemy group.",
		Effect = {
			MaxRank = 5,
			InitialClock = 4,
			BaseRadius = 9,
			RadiusPerRank = 2,
			BaseDamage = 24,
			DamagePerRank = 15,
			BasePeriod = 7,
			PeriodPerRank = 0.45,
			MinPeriod = 3.4,
			TargetSearchRange = 85,
		},
	},
	CinderOath = {
		Title = "Cinder Oath",
		Description = "+18% damage, but sacrifice 8 maximum health.",
		Effect = { DamageMultiplier = 1.18, MaxHealthPenalty = 8, MinMaxHealth = 35 },
	},
}

return Config
