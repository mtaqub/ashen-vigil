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
	},
	Power = {
		Title = "Tarnished Edge",
		Description = "+8 damage per ashen dart.",
	},
	Multishot = {
		Title = "Forked Hex",
		Description = "+1 projectile, up to five.",
	},
	Range = {
		Title = "Far-Reaching Oath",
		Description = "+12 attack range.",
	},
	Magnet = {
		Title = "Gravecall",
		Description = "+6 blood-shard pickup radius.",
	},
	Speed = {
		Title = "Exile's Step",
		Description = "+2 movement speed.",
	},
	Vitality = {
		Title = "Vessel of Ash",
		Description = "+25 maximum health and restore 25.",
	},
	GraveHalo = {
		Title = "Grave Halo",
		Description = "Periodically unleash a close-range ring of ruin.",
	},
	Blackflame = {
		Title = "Blackflame Testament",
		Description = "Periodically immolate a distant enemy group.",
	},
	CinderOath = {
		Title = "Cinder Oath",
		Description = "+18% damage, but sacrifice 8 maximum health.",
	},
}

return Config
