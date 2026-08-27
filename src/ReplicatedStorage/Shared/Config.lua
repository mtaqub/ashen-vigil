local Config = {}

Config.GAME_DURATION = 300
Config.BOSS_SPAWN_TIME = 240
Config.ARENA_SIZE = 440
Config.MAX_ENEMIES = 180
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

Config.Difficulty = {
	HealthScaleDivisor = 260,
	SpeedScaleDivisor = 900,
	SpeedScaleCap = 1.35,
	DamageScaleDivisor = 600,
	DamageScaleCap = 1.5,
}

Config.Spawn = {
	BaseRate = 1.4,
	RatePerSecond = 0.022,
	MaxRate = 8,
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
