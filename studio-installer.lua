-- ASHEN VIGIL: ROBLOX STUDIO INSTALLER
-- Paste this entire file into View > Command Bar, then press Enter once.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local function replace(className, name, parent, source)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local object = Instance.new(className)
	object.Name = name
	object.Source = source
	object.Parent = parent
	return object
end

local shared = ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder")
shared.Name = "Shared"
shared.Parent = ReplicatedStorage

-- ===== AssetIds: create once, then only ever merge newly added keys into it. =====
-- Existing uploaded IDs are never destroyed, zeroed, or renamed by this installer.
local ASSET_IDS_SOURCE = [====[
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
]====]

local function evaluateTable(source, tempName)
	local temp = Instance.new("ModuleScript")
	temp.Name = tempName
	temp.Source = source
	temp.Parent = shared
	local ok, result = pcall(require, temp)
	temp:Destroy()
	if ok and type(result) == "table" then
		return result
	end
	warn("Ashen Vigil installer: failed to evaluate " .. tempName .. " (" .. tostring(result) .. ")")
	return nil
end

local function mergeAssetIds(defaults, existing)
	local merged = { Audio = {}, Images = {} }
	for _, section in ipairs({ "Audio", "Images" }) do
		local defaultSection = (defaults and defaults[section]) or {}
		local existingSection = (existing and existing[section]) or {}
		for key, defaultValue in pairs(defaultSection) do
			local existingValue = existingSection[key]
			merged[section][key] = (type(existingValue) == "number") and existingValue or defaultValue
		end
	end
	return merged
end

local function serializeAssetIds(tbl)
	local function serializeSection(section)
		local keys = {}
		for key in pairs(section or {}) do
			table.insert(keys, key)
		end
		table.sort(keys)
		local lines = {}
		for _, key in ipairs(keys) do
			table.insert(lines, string.format("\t%s = %.0f,", key, section[key] or 0))
		end
		return table.concat(lines, "\n")
	end

	return table.concat({
		"local AssetIds = {}",
		"",
		"AssetIds.Audio = {",
		serializeSection(tbl.Audio),
		"}",
		"",
		"AssetIds.Images = {",
		serializeSection(tbl.Images),
		"}",
		"",
		"return AssetIds",
		"",
	}, "\n")
end

local defaultAssetIds = evaluateTable(ASSET_IDS_SOURCE, "AshenVigilAssetIdsDefaults") or { Audio = {}, Images = {} }
local existingAssetIdsModule = shared:FindFirstChild("AssetIds")
local existingConfigModule = shared:FindFirstChild("Config")

local existingValues = nil
if existingAssetIdsModule and existingAssetIdsModule:IsA("ModuleScript") then
	local ok, result = pcall(require, existingAssetIdsModule)
	if ok and type(result) == "table" then
		existingValues = result
	end
elseif existingConfigModule and existingConfigModule:IsA("ModuleScript") then
	-- Migration: an older install kept AssetIds inline inside Config. Recover any
	-- real IDs already uploaded there before Config gets replaced below.
	local ok, result = pcall(require, existingConfigModule)
	if ok and type(result) == "table" and type(result.AssetIds) == "table" then
		existingValues = result.AssetIds
	end
end

local mergedAssetIds = mergeAssetIds(defaultAssetIds, existingValues)
local assetIdsSource = serializeAssetIds(mergedAssetIds)

if existingAssetIdsModule and existingAssetIdsModule:IsA("ModuleScript") then
	existingAssetIdsModule.Source = assetIdsSource
else
	local assetIds = Instance.new("ModuleScript")
	assetIds.Name = "AssetIds"
	assetIds.Source = assetIdsSource
	assetIds.Parent = shared
end

-- ===== Config, GameServer, GameClient: always replaced with the latest version. =====
replace("ModuleScript", "Config", shared, [====[
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
]====])

replace("Script", "GameServer", ServerScriptService, [====[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local random = Random.new()

local function assetUri(assetId)
	local numericId = tonumber(assetId)
	if not numericId or numericId <= 0 then
		return nil
	end
	return "rbxassetid://" .. tostring(math.floor(numericId))
end

Players.CharacterAutoLoads = false

local function getOrCreate(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local object = Instance.new(className)
	object.Name = name
	object.Parent = parent
	return object
end

local remotes = getOrCreate("Folder", "AshenVigilRemotes", ReplicatedStorage)
local stateUpdateRemote = getOrCreate("RemoteEvent", "StateUpdate", remotes)
local levelUpRemote = getOrCreate("RemoteEvent", "LevelUp", remotes)
local upgradeChoiceRemote = getOrCreate("RemoteEvent", "UpgradeChoice", remotes)
local gameEndedRemote = getOrCreate("RemoteEvent", "GameEnded", remotes)
local announcementRemote = getOrCreate("RemoteEvent", "Announcement", remotes)
local restartVigilRemote = getOrCreate("RemoteEvent", "RestartVigil", remotes)

local arena = workspace:FindFirstChild("AshenVigilArena")
if arena then
	arena:Destroy()
end
arena = Instance.new("Folder")
arena.Name = "AshenVigilArena"
arena.Parent = workspace

local function makePart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local floor = makePart(
	"ObsidianFloor",
	Vector3.new(Config.ARENA_SIZE, 1, Config.ARENA_SIZE),
	CFrame.new(0, -0.5, 0),
	Color3.fromRGB(18, 18, 27),
	Enum.Material.Slate,
	arena
)
floor.Locked = true
if type(Config.FLOOR_MATERIAL_VARIANT) == "string" and Config.FLOOR_MATERIAL_VARIANT ~= "" then
	floor.MaterialVariant = Config.FLOOR_MATERIAL_VARIANT
end
local floorTextureId = assetUri(Config.AssetIds.Images.CrackedBasaltFloor)
if floorTextureId then
	local floorTexture = Instance.new("Texture")
	floorTexture.Name = "CrackedBasalt"
	floorTexture.Texture = floorTextureId
	floorTexture.Face = Enum.NormalId.Top
	floorTexture.StudsPerTileU = 28
	floorTexture.StudsPerTileV = 28
	floorTexture.Color3 = Color3.fromRGB(96, 91, 106)
	floorTexture.Parent = floor
end

local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "SurvivorSpawn"
spawnLocation.Size = Vector3.new(10, 0.5, 10)
spawnLocation.CFrame = CFrame.new(0, 0.25, 0)
spawnLocation.Color = Color3.fromRGB(126, 32, 55)
spawnLocation.Material = Enum.Material.Neon
spawnLocation.Transparency = 0.35
spawnLocation.Anchored = true
spawnLocation.CanCollide = true
spawnLocation.Neutral = true
spawnLocation.Duration = 2
spawnLocation.Parent = arena

local halfArena = Config.ARENA_SIZE * 0.5
local wallHeight = 26
local walls = {
	{ size = Vector3.new(Config.ARENA_SIZE, wallHeight, 3), position = Vector3.new(0, wallHeight * 0.5, -halfArena) },
	{ size = Vector3.new(Config.ARENA_SIZE, wallHeight, 3), position = Vector3.new(0, wallHeight * 0.5, halfArena) },
	{ size = Vector3.new(3, wallHeight, Config.ARENA_SIZE), position = Vector3.new(-halfArena, wallHeight * 0.5, 0) },
	{ size = Vector3.new(3, wallHeight, Config.ARENA_SIZE), position = Vector3.new(halfArena, wallHeight * 0.5, 0) },
}
for index, wallInfo in ipairs(walls) do
	local wall = makePart(
		"Boundary" .. index,
		wallInfo.size,
		CFrame.new(wallInfo.position),
		Color3.fromRGB(68, 34, 66),
		Enum.Material.ForceField,
		arena
	)
	wall.Transparency = 0.72
end

-- Wall-mounted torches: broad, even light coverage across the full arena so
-- players far from the central runestone ring can still see enemies clearly.
local wallTorchColor = Color3.fromRGB(226, 133, 64)
local torchesPerWall = 4
for _, wallInfo in ipairs(walls) do
	local runsAlongX = wallInfo.size.X > wallInfo.size.Z
	local inward = (wallInfo.position.X > 0 or wallInfo.position.Z > 0) and -3 or 3
	for step = 1, torchesPerWall do
		local t = ((step - 0.5) / torchesPerWall - 0.5) * (Config.ARENA_SIZE * 0.85)
		local torchPosition = runsAlongX
			and Vector3.new(wallInfo.position.X + t, 9, wallInfo.position.Z + inward)
			or Vector3.new(wallInfo.position.X + inward, 9, wallInfo.position.Z + t)

		local torchArm = makePart(
			"WallTorchArm",
			Vector3.new(0.35, 0.35, 1.1),
			CFrame.new(torchPosition),
			Color3.fromRGB(60, 52, 46),
			Enum.Material.CorrodedMetal,
			arena
		)
		torchArm.CanCollide = false
		local torchFlame = makePart(
			"WallTorchFlame",
			Vector3.new(0.6, 0.85, 0.6),
			torchArm.CFrame * CFrame.new(0, 0.5, 0),
			wallTorchColor,
			Enum.Material.Neon,
			arena
		)
		torchFlame.Shape = Enum.PartType.Ball
		torchFlame.CanCollide = false
		local torchLight = Instance.new("PointLight")
		torchLight.Color = wallTorchColor
		torchLight.Brightness = 1.9
		torchLight.Range = 30
		torchLight.Shadows = false
		torchLight.Parent = torchFlame
	end
end

for index = 1, 16 do
	local angle = (index / 16) * math.pi * 2
	local radius = 90
	local position = Vector3.new(math.cos(angle) * radius, 5, math.sin(angle) * radius)
	local pillar = makePart(
		"Runestone",
		Vector3.new(3, 10 + (index % 3) * 2, 3),
		CFrame.new(position) * CFrame.Angles(0, -angle, math.rad(index % 2 == 0 and 4 or -4)),
		Color3.fromRGB(41, 35, 57),
		Enum.Material.Basalt,
		arena
	)
	pillar.CanCollide = false
	local rune = makePart(
		"Rune",
		Vector3.new(0.25, 3, 1.3),
		pillar.CFrame * CFrame.new(0, 0, -1.57),
		Color3.fromRGB(211, 45, 87),
		Enum.Material.Neon,
		arena
	)
	rune.CanCollide = false

	local brazierColor = index % 2 == 0 and Color3.fromRGB(235, 142, 60) or Color3.fromRGB(160, 98, 216)
	local brazierBowl = makePart(
		"BrazierBowl",
		Vector3.new(1.5, 0.7, 1.5),
		pillar.CFrame * CFrame.new(0, pillar.Size.Y * 0.5 + 0.4, 0),
		Color3.fromRGB(70, 60, 52),
		Enum.Material.CorrodedMetal,
		arena
	)
	brazierBowl.CanCollide = false
	local brazierFlame = makePart(
		"BrazierFlame",
		Vector3.new(0.85, 1.05, 0.85),
		brazierBowl.CFrame * CFrame.new(0, brazierBowl.Size.Y * 0.5 + 0.3, 0),
		brazierColor,
		Enum.Material.Neon,
		arena
	)
	brazierFlame.Shape = Enum.PartType.Ball
	brazierFlame.CanCollide = false
	local brazierLight = Instance.new("PointLight")
	brazierLight.Color = brazierColor
	brazierLight.Brightness = 1.9
	brazierLight.Range = 22
	brazierLight.Shadows = false
	brazierLight.Parent = brazierFlame
end

for index = 1, 24 do
	local angle = (index / 24) * math.pi * 2
	local position = Vector3.new(math.cos(angle) * 24, 0.18, math.sin(angle) * 24)
	local graveMark = makePart(
		"GraveMark",
		Vector3.new(4.6, 0.35, 1.1),
		CFrame.new(position) * CFrame.Angles(0, -angle, 0),
		index % 4 == 0 and Color3.fromRGB(128, 82, 48) or Color3.fromRGB(53, 48, 61),
		index % 4 == 0 and Enum.Material.Neon or Enum.Material.Cobblestone,
		arena
	)
	graveMark.CanCollide = false
end

for index = 1, 4 do
	local angle = (index / 4) * math.pi * 2 + math.pi * 0.25
	local position = Vector3.new(math.cos(angle) * 145, 9, math.sin(angle) * 145)
	local archLeft = makePart(
		"RuinedArch",
		Vector3.new(5, 18, 5),
		CFrame.new(position + Vector3.new(math.sin(angle) * 8, 0, -math.cos(angle) * 8)) * CFrame.Angles(0, -angle, math.rad(-4)),
		Color3.fromRGB(44, 41, 49),
		Enum.Material.Cobblestone,
		arena
	)
	local archRight = makePart(
		"RuinedArch",
		Vector3.new(5, 14, 5),
		CFrame.new(position - Vector3.new(math.sin(angle) * 8, 2, -math.cos(angle) * 8)) * CFrame.Angles(0, -angle, math.rad(7)),
		Color3.fromRGB(44, 41, 49),
		Enum.Material.Cobblestone,
		arena
	)
	archLeft.CanCollide = false
	archRight.CanCollide = false
end

local shrinePlinth = makePart(
	"VigilShrinePlinth",
	Vector3.new(4.2, 1.1, 2.6),
	CFrame.new(0, 0.55, 14),
	Color3.fromRGB(46, 40, 55),
	Enum.Material.Basalt,
	arena
)
shrinePlinth.CanCollide = false
local shrineSigil = makePart(
	"VigilShrineSigil",
	Vector3.new(1.6, 2.2, 0.2),
	shrinePlinth.CFrame * CFrame.new(0, shrinePlinth.Size.Y * 0.5 + 1.1, 0),
	Color3.fromRGB(146, 92, 214),
	Enum.Material.Neon,
	arena
)
shrineSigil.CanCollide = false
local shrineLight = Instance.new("PointLight")
shrineLight.Color = shrineSigil.Color
shrineLight.Brightness = 2
shrineLight.Range = 26
shrineLight.Shadows = false
shrineLight.Parent = shrineSigil

Lighting.ClockTime = 0
Lighting.Brightness = 2.9
Lighting.Ambient = Color3.fromRGB(80, 72, 102)
Lighting.OutdoorAmbient = Color3.fromRGB(59, 54, 78)
Lighting.FogColor = Color3.fromRGB(18, 14, 28)
Lighting.FogStart = 150
Lighting.FogEnd = 380

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Color = Color3.fromRGB(105, 86, 138)
atmosphere.Decay = Color3.fromRGB(62, 32, 48)
atmosphere.Density = 0.20
atmosphere.Glare = 0
atmosphere.Haze = 1.25
atmosphere.Parent = Lighting

local ambientSoundId = assetUri(Config.AssetIds.Audio.AmbientLoop)
if ambientSoundId then
	local ambient = SoundService:FindFirstChild("AshenVigilAmbient") or Instance.new("Sound")
	ambient.Name = "AshenVigilAmbient"
	ambient.SoundId = ambientSoundId
	ambient.Volume = 0.32
	ambient.Looped = true
	ambient.Parent = SoundService
	ambient:Play()
end

local enemiesFolder = Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = arena

local gemsFolder = Instance.new("Folder")
gemsFolder.Name = "Experience"
gemsFolder.Parent = arena

local effectsFolder = Instance.new("Folder")
effectsFolder.Name = "Effects"
effectsFolder.Parent = arena

local function playSpatialSound(soundKey, position, volume, lifetime)
	local soundId = assetUri(Config.AssetIds.Audio[soundKey])
	if not soundId then
		return
	end
	local emitter = Instance.new("Part")
	emitter.Name = soundKey .. "Sound"
	emitter.Size = Vector3.new(0.2, 0.2, 0.2)
	emitter.Position = position
	emitter.Transparency = 1
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.Parent = effectsFolder
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.7
	sound.RollOffMinDistance = 12
	sound.RollOffMaxDistance = 100
	sound.Parent = emitter
	sound:Play()
	Debris:AddItem(emitter, lifetime or 4)
end

local playerStates = {}
local enemies = {}
local gems = {}
local enemyCount = 0
local bossEnemy = nil
local bossSpawned = false
local bossDefeated = false
local elapsedTime = 0
local spawnAccumulator = 0
local updateAccumulator = 0
local gameEnded = false

local function getLivingCharacter(player)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return character, humanoid, root
end

local function xpRequired(level)
	return math.floor(5 + (level - 1) * 4 + ((level - 1) ^ 1.22))
end

-- Resets a player's authoritative run stats back to fresh starting values in
-- place (same table identity), so both first spawn and a post-death restart
-- go through one definition of "the beginning of the run".
local function applyInitialState(state)
	state.level = 1
	state.xp = 0
	state.xpNeeded = xpRequired(1)
	state.kills = 0
	state.damage = Config.STARTING_DAMAGE
	state.damageMultiplier = 1
	state.attackSpeed = Config.STARTING_ATTACK_SPEED
	state.range = Config.STARTING_RANGE
	state.pickupRadius = Config.STARTING_PICKUP_RADIUS
	state.walkSpeed = Config.STARTING_WALK_SPEED
	state.projectiles = 1
	state.attackClock = 0
	state.graveHaloRank = 0
	state.graveHaloClock = 0
	state.blackflameRank = 0
	state.blackflameClock = 0
	state.alive = true
	state.pendingChoice = nil
	state.unclaimedLevels = 0
	return state
end

local function createEnemyHealthBar(part, enemyData)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthBar"
	gui.Size = UDim2.fromOffset(44, 6)
	gui.StudsOffset = Vector3.new(0, part.Size.Y * 0.65, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = part

	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(30, 24, 34)
	background.BorderSizePixel = 0
	background.Parent = gui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(222, 48, 82)
	fill.BorderSizePixel = 0
	fill.Parent = background

	enemyData.healthFill = fill
end

local function nearestLivingPlayer(position)
	local bestPlayer = nil
	local bestRoot = nil
	local bestDistance = math.huge
	for player, state in pairs(playerStates) do
		-- Players with a pending relic choice are excluded from targeting: enemies
		-- neither spawn toward them nor chase them while they're stuck in that menu.
		if state.alive and not state.pendingChoice then
			local _, humanoid, root = getLivingCharacter(player)
			if humanoid and root then
				local distance = (root.Position - position).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					bestPlayer = player
					bestRoot = root
				end
			end
		end
	end
	return bestPlayer, bestRoot, bestDistance
end

local function chooseEnemyType()
	local roll = random:NextNumber()
	if elapsedTime >= 120 and roll < math.min(0.08 + elapsedTime / 2500, 0.2) then
		return "Brute"
	end
	if elapsedTime >= 35 and roll < math.min(0.34 + elapsedTime / 1000, 0.62) then
		return "Ghoul"
	end
	return "Bat"
end

local function spawnEnemy(forcedEnemyId)
	if gameEnded then
		return nil
	end
	local targetPlayer, targetRoot = nearestLivingPlayer(Vector3.zero)
	if not targetPlayer or not targetRoot then
		return nil
	end

	local enemyId = forcedEnemyId or chooseEnemyType()
	local template = Config.Enemies[enemyId]
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = enemyId == "Warden" and 72 or random:NextNumber(58, 86)
	local rawPosition = targetRoot.Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local spawnLimit = Config.ARENA_SIZE * 0.5 - 8
	local position = Vector3.new(
		math.clamp(rawPosition.X, -spawnLimit, spawnLimit),
		template.Size.Y * 0.5,
		math.clamp(rawPosition.Z, -spawnLimit, spawnLimit)
	)

	local part = Instance.new("Part")
	part.Name = template.Name
	part.Size = template.Size
	part.Position = position
	part.Color = template.Color
	part.Material = enemyId == "Bat" and Enum.Material.Neon or (enemyId == "Warden" and Enum.Material.CorrodedMetal or Enum.Material.SmoothPlastic)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = enemyId ~= "Bat"
	part.Parent = enemiesFolder

	if enemyId == "Bat" then
		part.Shape = Enum.PartType.Ball
	elseif enemyId == "Brute" then
		part.Shape = Enum.PartType.Ball
	end
	-- Visual decoration for every enemy type, including the Warden's crown and
	-- ember, is attached by EnemyVisuals.server.lua / MobModelFactory once this
	-- part lands in Workspace.AshenVigilArena.Enemies.

	local difficulty = enemyId == "Warden" and 1 or (1 + elapsedTime / 260)
	local enemyData = {
		id = enemyId,
		part = part,
		health = template.Health * difficulty,
		maxHealth = template.Health * difficulty,
		speed = template.Speed * math.min(1 + elapsedTime / 900, 1.35),
		damage = template.Damage * math.min(1 + elapsedTime / 600, 1.5),
		xp = template.XP,
		lastHit = 0,
		baseColor = template.Color,
		bobOffset = random:NextNumber(0, math.pi * 2),
		specialClock = 0,
	}
	enemies[part] = enemyData
	enemyCount += 1
	createEnemyHealthBar(part, enemyData)
	if enemyId == "Warden" then
		bossEnemy = enemyData
		announcementRemote:FireAllClients("THE CINDER WARDEN", "An ancient oath stirs beneath the ash.", Color3.fromRGB(214, 143, 62))
	end
	return enemyData
end

local function spawnGem(position, amount)
	local gem = Instance.new("Part")
	gem.Name = "BloodShard"
	gem.Size = amount >= 6 and Vector3.new(1.5, 1.5, 1.5) or Vector3.new(0.9, 0.9, 0.9)
	gem.CFrame = CFrame.new(position + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(45))
	gem.Color = amount >= 6 and Color3.fromRGB(255, 206, 66) or Color3.fromRGB(240, 42, 91)
	gem.Material = Enum.Material.Neon
	gem.Anchored = true
	gem.CanCollide = false
	gem.CanTouch = false
	gem.Parent = gemsFolder
	gems[gem] = {
		amount = amount,
		age = 0,
		baseY = gem.Position.Y,
		phase = random:NextNumber(0, math.pi * 2),
	}
end

local function showHitEffect(position, color)
	local burst = Instance.new("Part")
	burst.Name = "HitBurst"
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.new(1.2, 1.2, 1.2)
	burst.Position = position
	burst.Color = color
	burst.Material = Enum.Material.Neon
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.Parent = effectsFolder
	TweenService:Create(burst, TweenInfo.new(0.18), {
		Size = Vector3.new(3.5, 3.5, 3.5),
		Transparency = 1,
	}):Play()
	Debris:AddItem(burst, 0.22)
end

local function damageEnemy(player, enemyData, damage)
	local part = enemyData.part
	if not part or not part.Parent or enemyData.health <= 0 then
		return
	end

	enemyData.health -= damage
	if enemyData.healthFill then
		enemyData.healthFill.Size = UDim2.fromScale(math.max(enemyData.health / enemyData.maxHealth, 0), 1)
	end
	showHitEffect(part.Position, Color3.fromRGB(255, 230, 185))

	if enemyData.health <= 0 then
		local state = playerStates[player]
		if state then
			state.kills += 1
		end
		spawnGem(part.Position, enemyData.xp)
		if enemyData.id == "Warden" then
			bossDefeated = true
			bossEnemy = nil
			announcementRemote:FireAllClients("OATH SUNDERED", "The Warden returns to cinder.", Color3.fromRGB(235, 190, 93))
		end
		enemies[part] = nil
		enemyCount = math.max(enemyCount - 1, 0)
		part:Destroy()
	end
end

local function createProjectileVisual(fromPosition, toPosition)
	local projectile = Instance.new("Part")
	projectile.Name = "AshenDart"
	projectile.Shape = Enum.PartType.Ball
	projectile.Size = Vector3.new(0.75, 0.75, 0.75)
	projectile.Position = fromPosition
	projectile.Color = Color3.fromRGB(255, 229, 178)
	projectile.Material = Enum.Material.Neon
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CanQuery = false
	projectile.Parent = effectsFolder
	playSpatialSound("AshenDart", fromPosition, 0.28, 2)

	local light = Instance.new("PointLight")
	light.Color = projectile.Color
	light.Range = 7
	light.Brightness = 1.5
	light.Parent = projectile

	local travelTime = math.clamp((toPosition - fromPosition).Magnitude / 120, 0.08, 0.35)
	TweenService:Create(projectile, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
		Position = toPosition,
		Transparency = 0.2,
	}):Play()
	Debris:AddItem(projectile, travelTime + 0.05)
end

local function performAttack(player, state)
	local _, _, root = getLivingCharacter(player)
	if not root then
		return
	end

	local candidates = {}
	for part, enemyData in pairs(enemies) do
		if part.Parent and enemyData.health > 0 then
			local distance = (part.Position - root.Position).Magnitude
			if distance <= state.range then
				table.insert(candidates, {
					data = enemyData,
					distance = distance,
				})
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.distance < b.distance
	end)

	local projectileCount = math.min(state.projectiles, #candidates)
	for index = 1, projectileCount do
		local enemyData = candidates[index].data
		local targetPosition = enemyData.part.Position
		createProjectileVisual(root.Position + Vector3.new(0, 1.2, 0), targetPosition)
		damageEnemy(player, enemyData, state.damage * state.damageMultiplier)
	end
end

local function createRuinRing(position, radius, color, duration)
	local ring = Instance.new("Part")
	ring.Name = "RuinRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.18, 2, 2)
	ring.CFrame = CFrame.new(position.X, 0.18, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.25
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Parent = effectsFolder
	TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.18, radius * 2, radius * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, duration + 0.05)
end

local function performGraveHalo(player, state)
	local _, _, root = getLivingCharacter(player)
	if not root then
		return
	end
	local radius = 17 + state.graveHaloRank * 3
	local damage = (18 + state.graveHaloRank * 12) * state.damageMultiplier
	createRuinRing(root.Position, radius, Color3.fromRGB(181, 146, 92), 0.42)
	playSpatialSound("GraveHalo", root.Position, 0.7, 3)

	local targets = {}
	for part, enemyData in pairs(enemies) do
		if part.Parent and enemyData.health > 0 and (part.Position - root.Position).Magnitude <= radius then
			table.insert(targets, enemyData)
		end
	end
	for _, enemyData in ipairs(targets) do
		damageEnemy(player, enemyData, damage)
	end
end

local function performBlackflame(player, state)
	local _, _, root = getLivingCharacter(player)
	if not root then
		return
	end

	local targetData = nil
	local nearestDistance = 85
	for part, enemyData in pairs(enemies) do
		if part.Parent and enemyData.health > 0 then
			local distance = (part.Position - root.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				targetData = enemyData
			end
		end
	end
	if not targetData then
		return
	end

	local center = targetData.part.Position
	local radius = 9 + state.blackflameRank * 2
	local damage = (24 + state.blackflameRank * 15) * state.damageMultiplier
	playSpatialSound("BlackflameTestament", center, 0.72, 3)
	local flame = Instance.new("Part")
	flame.Name = "BlackflameTestament"
	flame.Shape = Enum.PartType.Ball
	flame.Size = Vector3.new(2, 2, 2)
	flame.Position = center
	flame.Color = Color3.fromRGB(107, 47, 139)
	flame.Material = Enum.Material.Neon
	flame.Transparency = 0.12
	flame.Anchored = true
	flame.CanCollide = false
	flame.CanQuery = false
	flame.Parent = effectsFolder
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(179, 77, 225)
	light.Brightness = 3
	light.Range = radius * 2
	light.Parent = flame
	TweenService:Create(flame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = Vector3.new(radius * 2, radius * 2, radius * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(flame, 0.55)

	local targets = {}
	for part, enemyData in pairs(enemies) do
		if part.Parent and enemyData.health > 0 and (part.Position - center).Magnitude <= radius then
			table.insert(targets, enemyData)
		end
	end
	for _, enemyData in ipairs(targets) do
		damageEnemy(player, enemyData, damage)
	end
end

local function shuffledUpgradeChoices(state)
	local ids = {}
	for id in pairs(Config.Upgrades) do
		local available = true
		if id == "Multishot" and state.projectiles >= 5 then
			available = false
		elseif id == "Speed" and state.walkSpeed >= 28 then
			available = false
		elseif id == "GraveHalo" and state.graveHaloRank >= 5 then
			available = false
		elseif id == "Blackflame" and state.blackflameRank >= 5 then
			available = false
		end
		if available then
			table.insert(ids, id)
		end
	end
	for index = #ids, 2, -1 do
		local other = random:NextInteger(1, index)
		ids[index], ids[other] = ids[other], ids[index]
	end

	local choices = {}
	for index = 1, math.min(3, #ids) do
		local id = ids[index]
		local upgrade = Config.Upgrades[id]
		table.insert(choices, {
			id = id,
			title = upgrade.Title,
			description = upgrade.Description,
		})
	end
	return choices
end

local function offerNextUpgrade(player, state)
	if state.unclaimedLevels <= 0 or state.pendingChoice or not state.alive then
		return
	end
	local choices
	if state.level == 2 and state.graveHaloRank == 0 and state.blackflameRank == 0 then
		choices = {}
		for _, id in ipairs({ "GraveHalo", "Blackflame", "CinderOath" }) do
			local upgrade = Config.Upgrades[id]
			table.insert(choices, {
				id = id,
				title = upgrade.Title,
				description = upgrade.Description,
			})
		end
	else
		choices = shuffledUpgradeChoices(state)
	end
	state.pendingChoice = choices
	levelUpRemote:FireClient(player, choices, state.level)
end

local function gainExperience(player, state, amount)
	state.xp += amount
	while state.xp >= state.xpNeeded do
		state.xp -= state.xpNeeded
		state.level += 1
		state.xpNeeded = xpRequired(state.level)
		state.unclaimedLevels += 1
	end
	offerNextUpgrade(player, state)
end

local function applyUpgrade(player, state, upgradeId)
	local _, humanoid, root = getLivingCharacter(player)
	if upgradeId == "RapidFire" then
		state.attackSpeed *= 1.2
	elseif upgradeId == "Power" then
		state.damage += 8
	elseif upgradeId == "Multishot" then
		state.projectiles = math.min(state.projectiles + 1, 5)
	elseif upgradeId == "Range" then
		state.range += 12
	elseif upgradeId == "Magnet" then
		state.pickupRadius += 6
	elseif upgradeId == "Speed" then
		state.walkSpeed = math.min(state.walkSpeed + 2, 28)
		if humanoid then
			humanoid.WalkSpeed = state.walkSpeed
		end
	elseif upgradeId == "Vitality" and humanoid then
		humanoid.MaxHealth += 25
		humanoid.Health = math.min(humanoid.Health + 25, humanoid.MaxHealth)
	elseif upgradeId == "GraveHalo" then
		state.graveHaloRank = math.min(state.graveHaloRank + 1, 5)
		state.graveHaloClock = math.max(state.graveHaloClock, 2.5)
	elseif upgradeId == "Blackflame" then
		state.blackflameRank = math.min(state.blackflameRank + 1, 5)
		state.blackflameClock = math.max(state.blackflameClock, 4)
	elseif upgradeId == "CinderOath" then
		state.damageMultiplier *= 1.18
		if humanoid then
			humanoid.MaxHealth = math.max(35, humanoid.MaxHealth - 8)
			humanoid.Health = math.min(humanoid.Health, humanoid.MaxHealth)
		end
	end
	if root then
		playSpatialSound("RelicInherited", root.Position, 0.82, 4)
	end
end

upgradeChoiceRemote.OnServerEvent:Connect(function(player, upgradeId)
	local state = playerStates[player]
	if not state or not state.pendingChoice or type(upgradeId) ~= "string" then
		return
	end
	local isValid = false
	for _, choice in ipairs(state.pendingChoice) do
		if choice.id == upgradeId then
			isValid = true
			break
		end
	end
	if not isValid then
		return
	end

	applyUpgrade(player, state, upgradeId)
	state.pendingChoice = nil
	state.unclaimedLevels = math.max(state.unclaimedLevels - 1, 0)
	task.delay(0.15, function()
		if player.Parent then
			offerNextUpgrade(player, state)
		end
	end)
end)

local function addPlayer(player)
	local state = applyInitialState({})
	playerStates[player] = state

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local root = character:WaitForChild("HumanoidRootPart")
		humanoid.MaxHealth = Config.STARTING_HEALTH
		humanoid.Health = Config.STARTING_HEALTH
		humanoid.WalkSpeed = state.walkSpeed
		root.CFrame = CFrame.new(0, 4, 0)

		-- Doubles as the player's personal torch: it travels everywhere they go,
		-- so approaching enemies stay visible no matter where in the arena a fight
		-- happens, rather than only near fixed environment light sources.
		local vigilLight = Instance.new("PointLight")
		vigilLight.Name = "VigilEmber"
		vigilLight.Color = Color3.fromRGB(220, 100, 48)
		vigilLight.Brightness = 2.7
		vigilLight.Range = 38
		vigilLight.Parent = root

		local outline = Instance.new("Highlight")
		outline.Name = "OathboundOutline"
		outline.FillTransparency = 1
		outline.OutlineColor = Color3.fromRGB(153, 112, 64)
		outline.OutlineTransparency = 0.5
		outline.DepthMode = Enum.HighlightDepthMode.Occluded
		outline.Parent = character

		humanoid.Died:Connect(function()
			if state.alive then
				state.alive = false
				gameEndedRemote:FireClient(player, false, state.kills, elapsedTime)
			end
		end)

		task.delay(1.8, function()
			if state.alive and player.Parent then
				announcementRemote:FireClient(player, "THE ASHEN VIGIL", "Endure the long night. Let no oath be forgotten.", Color3.fromRGB(203, 169, 103))
			end
		end)
	end)

	player:LoadCharacter()
end

-- Returns a dead player to a fresh vigil: stats reset to starting values, a
-- brand-new character spawned.
local function resetPlayerForNewVigil(player)
	local state = playerStates[player]
	if not state then
		return
	end
	applyInitialState(state)
	player:LoadCharacter()
end

local function anyOtherPlayerAlive(excludedPlayer)
	for otherPlayer, otherState in pairs(playerStates) do
		if otherPlayer ~= excludedPlayer and otherState.alive then
			return true
		end
	end
	return false
end

-- Clears every enemy, pickup, and boss/timer value back to a clean slate. Only
-- called when it is safe to do so: either nobody else has a run in progress
-- (so there is nothing of theirs to disrupt), or the shared vigil has already
-- ended for the whole server (time-out), in which case the world is already
-- fully idle and restarting it can't interrupt anyone.
local function resetMatchWorld()
	for _, enemyData in pairs(enemies) do
		if enemyData.part then
			enemyData.part:Destroy()
		end
	end
	enemies = {}
	enemyCount = 0

	for gem in pairs(gems) do
		gem:Destroy()
	end
	gems = {}

	bossEnemy = nil
	bossSpawned = false
	bossDefeated = false
	elapsedTime = 0
	spawnAccumulator = 0
	updateAccumulator = 0
	gameEnded = false

	announcementRemote:FireAllClients(
		"THE VIGIL BEGINS ANEW",
		"A new night falls over the ashen court.",
		Color3.fromRGB(203, 169, 103)
	)
end

restartVigilRemote.OnServerEvent:Connect(function(player)
	local state = playerStates[player]
	if not state or state.alive then
		return
	end
	if gameEnded or not anyOtherPlayerAlive(player) then
		resetMatchWorld()
	end
	resetPlayerForNewVigil(player)
end)

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(addPlayer, player)
end

local function beginWardenPulse(enemyData)
	local part = enemyData.part
	if not part or not part.Parent then
		return
	end
	local center = part.Position
	local radius = 29
	createRuinRing(center, radius, Color3.fromRGB(207, 48, 39), 0.9)
	playSpatialSound("WardenTelegraph", center, 0.9, 3)
	task.delay(0.82, function()
		if enemyData.health <= 0 or not part.Parent then
			return
		end
		showHitEffect(center, Color3.fromRGB(221, 79, 34))
		playSpatialSound("WardenImpact", center, 1, 4)
		for player, state in pairs(playerStates) do
			if state.alive and not state.pendingChoice then
				local _, humanoid, root = getLivingCharacter(player)
				if humanoid and root and (root.Position - center).Magnitude <= radius then
					humanoid:TakeDamage(22)
				end
			end
		end
	end)
end

local function updateEnemies(dt)
	for part, enemyData in pairs(enemies) do
		if not part.Parent then
			enemies[part] = nil
			enemyCount = math.max(enemyCount - 1, 0)
			continue
		end

		local targetPlayer, targetRoot, distance = nearestLivingPlayer(part.Position)
		if not targetPlayer or not targetRoot then
			continue
		end

		local offset = targetRoot.Position - part.Position
		local horizontal = Vector3.new(offset.X, 0, offset.Z)
		if horizontal.Magnitude > 0.1 then
			local direction = horizontal.Unit
			local newPosition = part.Position + direction * enemyData.speed * dt
			local hover = enemyData.id == "Bat" and (2.2 + math.sin(elapsedTime * 5 + enemyData.bobOffset) * 0.6) or (part.Size.Y * 0.5)
			newPosition = Vector3.new(newPosition.X, hover, newPosition.Z)
			part.CFrame = CFrame.lookAt(newPosition, newPosition + direction)
		end

		if enemyData.id == "Warden" then
			enemyData.specialClock += dt
			if enemyData.specialClock >= 5.5 then
				enemyData.specialClock = 0
				beginWardenPulse(enemyData)
			end
		end

		local contactDistance = math.max(3.3, part.Size.X * 0.5 + 2)
		if distance <= contactDistance and elapsedTime - enemyData.lastHit >= 0.8 then
			enemyData.lastHit = elapsedTime
			local _, humanoid = getLivingCharacter(targetPlayer)
			local targetState = playerStates[targetPlayer]
			if humanoid and targetState and not targetState.pendingChoice then
				humanoid:TakeDamage(enemyData.damage)
			end
		end
	end
end

local function updateGems(dt)
	for gem, gemData in pairs(gems) do
		if not gem.Parent then
			gems[gem] = nil
			continue
		end
		gemData.age += dt
		if gemData.age >= 90 then
			gems[gem] = nil
			gem:Destroy()
			continue
		end

		local collector = nil
		local collectorState = nil
		local collectorRoot = nil
		local nearestDistance = math.huge
		for player, state in pairs(playerStates) do
			if state.alive then
				local _, _, root = getLivingCharacter(player)
				if root then
					local distance = (root.Position - gem.Position).Magnitude
					if distance < state.pickupRadius and distance < nearestDistance then
						collector = player
						collectorState = state
						collectorRoot = root
						nearestDistance = distance
					end
				end
			end
		end

		if collector and collectorState and collectorRoot then
			if nearestDistance <= 2.8 then
				gainExperience(collector, collectorState, gemData.amount)
				playSpatialSound("BloodShardPickup", gem.Position, 0.42, 2)
				gems[gem] = nil
				gem:Destroy()
			else
				local direction = (collectorRoot.Position - gem.Position).Unit
				local speed = 22 + math.max(0, collectorState.pickupRadius - nearestDistance) * 5
				gem.Position += direction * speed * dt
			end
		else
			gem.CFrame = CFrame.new(gem.Position.X, gemData.baseY + math.sin(gemData.age * 3 + gemData.phase) * 0.25, gem.Position.Z)
				* CFrame.Angles(0, gemData.age * 2, math.rad(45))
		end
	end
end

local function updatePlayers(dt)
	for player, state in pairs(playerStates) do
		if not state.alive then
			continue
		end
		local _, humanoid = getLivingCharacter(player)
		if humanoid then
			state.attackClock += dt
			local attackPeriod = math.max(0.13, 0.78 / state.attackSpeed)
			if state.attackClock >= attackPeriod then
				state.attackClock %= attackPeriod
				performAttack(player, state)
			end

			if state.graveHaloRank > 0 then
				state.graveHaloClock += dt
				local haloPeriod = math.max(2.4, 5.1 - state.graveHaloRank * 0.35)
				if state.graveHaloClock >= haloPeriod then
					state.graveHaloClock %= haloPeriod
					performGraveHalo(player, state)
				end
			end

			if state.blackflameRank > 0 then
				state.blackflameClock += dt
				local flamePeriod = math.max(3.4, 7 - state.blackflameRank * 0.45)
				if state.blackflameClock >= flamePeriod then
					state.blackflameClock %= flamePeriod
					performBlackflame(player, state)
				end
			end
		end
	end
end

local function pushStateUpdates()
	for player, state in pairs(playerStates) do
		local _, humanoid = getLivingCharacter(player)
		stateUpdateRemote:FireClient(player, {
			elapsed = elapsedTime,
			duration = Config.GAME_DURATION,
			level = state.level,
			xp = state.xp,
			xpNeeded = state.xpNeeded,
			kills = state.kills,
			health = humanoid and humanoid.Health or 0,
			maxHealth = humanoid and humanoid.MaxHealth or Config.STARTING_HEALTH,
			enemies = enemyCount,
			graveHaloRank = state.graveHaloRank,
			blackflameRank = state.blackflameRank,
			damageMultiplier = state.damageMultiplier,
			bossActive = bossEnemy ~= nil and bossEnemy.health > 0,
			bossHealth = bossEnemy and math.max(bossEnemy.health, 0) or 0,
			bossMaxHealth = bossEnemy and bossEnemy.maxHealth or 1,
			bossName = "THE CINDER WARDEN",
			bossDefeated = bossDefeated,
		})
	end
end

RunService.Heartbeat:Connect(function(dt)
	if gameEnded then
		return
	end

	elapsedTime += dt
	if not bossSpawned and elapsedTime >= Config.BOSS_SPAWN_TIME then
		bossSpawned = spawnEnemy("Warden") ~= nil
	end
	spawnAccumulator += dt * math.min(1.4 + elapsedTime * 0.022, 8)
	while spawnAccumulator >= 1 and enemyCount < Config.MAX_ENEMIES do
		spawnAccumulator -= 1
		spawnEnemy()
	end

	updateEnemies(dt)
	updateGems(dt)
	updatePlayers(dt)

	updateAccumulator += dt
	if updateAccumulator >= 0.15 then
		updateAccumulator = 0
		pushStateUpdates()
	end

	if elapsedTime >= Config.GAME_DURATION then
		gameEnded = true
		for player, state in pairs(playerStates) do
			if state.alive then
				gameEndedRemote:FireClient(player, true, state.kills, elapsedTime, bossDefeated)
			end
		end
	end
end)
]====])

replace("LocalScript", "GameClient", StarterPlayer.StarterPlayerScripts, [====[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("AshenVigilRemotes")
local stateUpdateRemote = remotes:WaitForChild("StateUpdate")
local levelUpRemote = remotes:WaitForChild("LevelUp")
local upgradeChoiceRemote = remotes:WaitForChild("UpgradeChoice")
local gameEndedRemote = remotes:WaitForChild("GameEnded")
local announcementRemote = remotes:WaitForChild("Announcement")
local restartVigilRemote = remotes:WaitForChild("RestartVigil")

local COLORS = {
	ink = Color3.fromRGB(18, 14, 25),
	panel = Color3.fromRGB(31, 25, 43),
	panelLight = Color3.fromRGB(52, 42, 68),
	cream = Color3.fromRGB(245, 231, 209),
	muted = Color3.fromRGB(174, 157, 182),
	red = Color3.fromRGB(221, 44, 83),
	darkRed = Color3.fromRGB(117, 24, 48),
	gold = Color3.fromRGB(246, 190, 77),
	purple = Color3.fromRGB(131, 83, 210),
}

local CHOICE_IMAGE_KEYS = {
	GraveHalo = "GraveHalo",
	Blackflame = "BlackflameTestament",
	CinderOath = "CinderOath",
}

local function imageUri(assetId)
	local numericId = tonumber(assetId)
	if not numericId or numericId <= 0 then
		return nil
	end
	return "rbxassetid://" .. tostring(math.floor(numericId))
end

local function corner(parent, radius)
	local object = Instance.new("UICorner")
	object.CornerRadius = UDim.new(0, radius)
	object.Parent = parent
	return object
end

local function stroke(parent, color, thickness, transparency)
	local object = Instance.new("UIStroke")
	object.Color = color
	object.Thickness = thickness
	object.Transparency = transparency or 0
	object.Parent = parent
	return object
end

local function textLabel(parent, name, text, size, position, anchor, font, color, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.zero
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.GothamBold
	label.TextColor3 = color or COLORS.cream
	label.TextSize = textSize or 18
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "AshenVigilUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = COLORS.ink
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.ZIndex = 40
vignette.Parent = gui

local timerPanel = Instance.new("Frame")
timerPanel.Name = "TimerPanel"
timerPanel.Size = UDim2.fromOffset(188, 64)
timerPanel.Position = UDim2.fromScale(0.5, 0.03)
timerPanel.AnchorPoint = Vector2.new(0.5, 0)
timerPanel.BackgroundColor3 = COLORS.ink
timerPanel.BackgroundTransparency = 0.12
timerPanel.BorderSizePixel = 0
timerPanel.Parent = gui
corner(timerPanel, 12)
stroke(timerPanel, COLORS.darkRed, 2, 0.15)

local timerLabel = textLabel(
	timerPanel,
	"Timer",
	"00:00",
	UDim2.fromScale(1, 0.64),
	UDim2.fromScale(0.5, 0.05),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBlack,
	COLORS.cream,
	29
)
local threatLabel = textLabel(
	timerPanel,
	"Threat",
	"THE LONG NIGHT",
	UDim2.fromScale(1, 0.3),
	UDim2.fromScale(0.5, 0.66),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBold,
	COLORS.red,
	11
)

local objective = textLabel(
	gui,
	"Objective",
	"ENDURE THE ASHEN VIGIL",
	UDim2.fromOffset(320, 34),
	UDim2.fromScale(0.5, 0.145),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBold,
	COLORS.muted,
	15
)

local bossPanel = Instance.new("Frame")
bossPanel.Name = "BossPanel"
bossPanel.Size = UDim2.fromOffset(520, 56)
bossPanel.Position = UDim2.fromScale(0.5, 0.185)
bossPanel.AnchorPoint = Vector2.new(0.5, 0)
bossPanel.BackgroundColor3 = COLORS.ink
bossPanel.BackgroundTransparency = 0.08
bossPanel.BorderSizePixel = 0
bossPanel.Visible = false
bossPanel.Parent = gui
corner(bossPanel, 7)
stroke(bossPanel, Color3.fromRGB(139, 93, 49), 2, 0.1)

local bossName = textLabel(
	bossPanel,
	"BossName",
	"THE CINDER WARDEN",
	UDim2.new(1, -24, 0, 24),
	UDim2.fromOffset(12, 5),
	Vector2.zero,
	Enum.Font.GothamBlack,
	COLORS.gold,
	14
)
bossName.TextXAlignment = Enum.TextXAlignment.Center
bossName.ZIndex = 4

local bossHealthBack = Instance.new("Frame")
bossHealthBack.Name = "BossHealthBack"
bossHealthBack.Size = UDim2.new(1, -26, 0, 14)
bossHealthBack.Position = UDim2.fromOffset(13, 34)
bossHealthBack.BackgroundColor3 = Color3.fromRGB(48, 33, 35)
bossHealthBack.BorderSizePixel = 0
bossHealthBack.ClipsDescendants = true
bossHealthBack.ZIndex = 3
bossHealthBack.Parent = bossPanel
corner(bossHealthBack, 4)

local bossHealthFill = Instance.new("Frame")
bossHealthFill.Name = "BossHealthFill"
bossHealthFill.Size = UDim2.fromScale(1, 1)
bossHealthFill.BackgroundColor3 = Color3.fromRGB(151, 44, 39)
bossHealthFill.BorderSizePixel = 0
bossHealthFill.ZIndex = 4
bossHealthFill.Parent = bossHealthBack
corner(bossHealthFill, 4)
local bossGradient = Instance.new("UIGradient")
bossGradient.Color = ColorSequence.new(Color3.fromRGB(83, 27, 31), Color3.fromRGB(208, 75, 41))
bossGradient.Parent = bossHealthFill

local bossFrameImageId = imageUri(Config.AssetIds.Images.BossBarFrame)
if bossFrameImageId then
	local bossFrameImage = Instance.new("ImageLabel")
	bossFrameImage.Name = "BossBarOrnament"
	bossFrameImage.Size = UDim2.new(1, 12, 0, 32)
	bossFrameImage.Position = UDim2.fromOffset(-6, 25)
	bossFrameImage.BackgroundTransparency = 1
	bossFrameImage.Image = bossFrameImageId
	bossFrameImage.ScaleType = Enum.ScaleType.Stretch
	bossFrameImage.ZIndex = 2
	bossFrameImage.Parent = bossPanel
end

local killsPanel = Instance.new("Frame")
killsPanel.Name = "KillsPanel"
killsPanel.Size = UDim2.fromOffset(154, 48)
killsPanel.Position = UDim2.new(1, -24, 0, 24)
killsPanel.AnchorPoint = Vector2.new(1, 0)
killsPanel.BackgroundColor3 = COLORS.ink
killsPanel.BackgroundTransparency = 0.18
killsPanel.BorderSizePixel = 0
killsPanel.Parent = gui
corner(killsPanel, 10)
stroke(killsPanel, COLORS.panelLight, 1, 0.3)
local killsLabel = textLabel(
	killsPanel,
	"Kills",
	"BANISHED  0",
	UDim2.fromScale(1, 1),
	UDim2.fromScale(0.5, 0.5),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamBlack,
	COLORS.cream,
	20
)

local relicPanel = Instance.new("Frame")
relicPanel.Name = "RelicPanel"
relicPanel.Size = UDim2.fromOffset(242, 104)
relicPanel.Position = UDim2.new(1, -22, 1, -62)
relicPanel.AnchorPoint = Vector2.new(1, 1)
relicPanel.BackgroundColor3 = COLORS.ink
relicPanel.BackgroundTransparency = 0.12
relicPanel.BorderSizePixel = 0
relicPanel.Parent = gui
corner(relicPanel, 12)
stroke(relicPanel, Color3.fromRGB(112, 79, 48), 1, 0.25)

local relicTitle = textLabel(
	relicPanel,
	"RelicTitle",
	"RELICS BOUND",
	UDim2.new(1, -24, 0, 22),
	UDim2.fromOffset(12, 7),
	Vector2.zero,
	Enum.Font.GothamBlack,
	COLORS.gold,
	12
)
relicTitle.TextXAlignment = Enum.TextXAlignment.Left
local dartRelic = textLabel(
	relicPanel,
	"DartRelic",
	"Ashen Dart  I",
	UDim2.new(1, -24, 0, 20),
	UDim2.fromOffset(12, 32),
	Vector2.zero,
	Enum.Font.GothamBold,
	COLORS.cream,
	13
)
dartRelic.TextXAlignment = Enum.TextXAlignment.Left
local haloRelic = textLabel(
	relicPanel,
	"HaloRelic",
	"Grave Halo  -",
	UDim2.new(1, -24, 0, 20),
	UDim2.fromOffset(12, 55),
	Vector2.zero,
	Enum.Font.GothamMedium,
	COLORS.muted,
	13
)
haloRelic.TextXAlignment = Enum.TextXAlignment.Left
local flameRelic = textLabel(
	relicPanel,
	"FlameRelic",
	"Blackflame Testament  -",
	UDim2.new(1, -24, 0, 20),
	UDim2.fromOffset(12, 78),
	Vector2.zero,
	Enum.Font.GothamMedium,
	COLORS.muted,
	13
)
flameRelic.TextXAlignment = Enum.TextXAlignment.Left

local statsPanel = Instance.new("Frame")
statsPanel.Name = "StatsPanel"
statsPanel.Size = UDim2.fromOffset(300, 92)
statsPanel.Position = UDim2.new(0, 22, 1, -62)
statsPanel.AnchorPoint = Vector2.new(0, 1)
statsPanel.BackgroundColor3 = COLORS.ink
statsPanel.BackgroundTransparency = 0.1
statsPanel.BorderSizePixel = 0
statsPanel.Parent = gui
corner(statsPanel, 12)
stroke(statsPanel, COLORS.panelLight, 1, 0.25)

local levelLabel = textLabel(
	statsPanel,
	"Level",
	"LEVEL 1",
	UDim2.fromOffset(110, 28),
	UDim2.fromOffset(16, 10),
	Vector2.zero,
	Enum.Font.GothamBlack,
	COLORS.gold,
	16
)
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
local healthText = textLabel(
	statsPanel,
	"HealthText",
	"100 / 100",
	UDim2.fromOffset(140, 28),
	UDim2.new(1, -16, 0, 10),
	Vector2.new(1, 0),
	Enum.Font.GothamBold,
	COLORS.cream,
	14
)
healthText.TextXAlignment = Enum.TextXAlignment.Right

local healthBack = Instance.new("Frame")
healthBack.Name = "HealthBack"
healthBack.Size = UDim2.new(1, -32, 0, 24)
healthBack.Position = UDim2.fromOffset(16, 50)
healthBack.BackgroundColor3 = Color3.fromRGB(56, 31, 42)
healthBack.BorderSizePixel = 0
healthBack.ClipsDescendants = true
healthBack.Parent = statsPanel
corner(healthBack, 7)

local healthFill = Instance.new("Frame")
healthFill.Name = "HealthFill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = COLORS.red
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
corner(healthFill, 7)

local healthGradient = Instance.new("UIGradient")
healthGradient.Color = ColorSequence.new(COLORS.darkRed, Color3.fromRGB(245, 62, 91))
healthGradient.Parent = healthFill

local xpBack = Instance.new("Frame")
xpBack.Name = "XPBack"
xpBack.Size = UDim2.new(1, -44, 0, 18)
xpBack.Position = UDim2.new(0.5, 0, 1, -25)
xpBack.AnchorPoint = Vector2.new(0.5, 1)
xpBack.BackgroundColor3 = COLORS.ink
xpBack.BackgroundTransparency = 0.05
xpBack.BorderSizePixel = 0
xpBack.ClipsDescendants = true
xpBack.Parent = gui
corner(xpBack, 7)
stroke(xpBack, COLORS.panelLight, 1, 0.35)

local xpFill = Instance.new("Frame")
xpFill.Name = "XPFill"
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = COLORS.purple
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBack
corner(xpFill, 7)

local xpGradient = Instance.new("UIGradient")
xpGradient.Color = ColorSequence.new(COLORS.purple, Color3.fromRGB(219, 65, 154))
xpGradient.Parent = xpFill

local xpText = textLabel(
	xpBack,
	"XPText",
	"0 / 5 XP",
	UDim2.fromScale(1, 1),
	UDim2.fromScale(0.5, 0.5),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamBold,
	COLORS.cream,
	11
)
xpText.ZIndex = 3

local controlsHint = textLabel(
	gui,
	"ControlsHint",
	UserInputService.TouchEnabled and "MOVE WITH THE JOYSTICK - RELICS STRIKE AUTOMATICALLY" or "WASD TO MOVE  -  RELICS STRIKE AUTOMATICALLY",
	UDim2.fromOffset(500, 26),
	UDim2.new(0.5, 0, 1, -49),
	Vector2.new(0.5, 1),
	Enum.Font.GothamMedium,
	COLORS.muted,
	12
)

local announcementPanel = Instance.new("Frame")
announcementPanel.Name = "AnnouncementPanel"
announcementPanel.Size = UDim2.fromOffset(660, 104)
announcementPanel.Position = UDim2.fromScale(0.5, 0.31)
announcementPanel.AnchorPoint = Vector2.new(0.5, 0.5)
announcementPanel.BackgroundColor3 = COLORS.ink
announcementPanel.BackgroundTransparency = 1
announcementPanel.BorderSizePixel = 0
announcementPanel.Visible = false
announcementPanel.ZIndex = 20
announcementPanel.Parent = gui

local announcementTitle = textLabel(
	announcementPanel,
	"AnnouncementTitle",
	"THE ASHEN VIGIL",
	UDim2.new(1, -30, 0, 50),
	UDim2.new(0.5, 0, 0, 2),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBlack,
	COLORS.gold,
	28
)
announcementTitle.ZIndex = 21
local announcementBody = textLabel(
	announcementPanel,
	"AnnouncementBody",
	"Endure the long night.",
	UDim2.new(1, -30, 0, 38),
	UDim2.new(0.5, 0, 0, 55),
	Vector2.new(0.5, 0),
	Enum.Font.GothamMedium,
	COLORS.cream,
	15
)
announcementBody.ZIndex = 21

local levelOverlay = Instance.new("Frame")
levelOverlay.Name = "LevelOverlay"
levelOverlay.Size = UDim2.fromScale(1, 1)
levelOverlay.BackgroundColor3 = COLORS.ink
levelOverlay.BackgroundTransparency = 0.24
levelOverlay.BorderSizePixel = 0
levelOverlay.Visible = false
levelOverlay.ZIndex = 10
levelOverlay.Parent = gui

local levelPanel = Instance.new("Frame")
levelPanel.Name = "LevelPanel"
levelPanel.Size = UDim2.fromOffset(760, 330)
levelPanel.Position = UDim2.fromScale(0.5, 0.5)
levelPanel.AnchorPoint = Vector2.new(0.5, 0.5)
levelPanel.BackgroundColor3 = COLORS.panel
levelPanel.BorderSizePixel = 0
levelPanel.ZIndex = 11
levelPanel.Parent = levelOverlay
corner(levelPanel, 18)
stroke(levelPanel, COLORS.gold, 2, 0.2)

local levelTitle = textLabel(
	levelPanel,
	"Title",
	"LEVEL UP",
	UDim2.new(1, -40, 0, 52),
	UDim2.new(0.5, 0, 0, 18),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBlack,
	COLORS.gold,
	30
)
levelTitle.ZIndex = 12
local levelSubtitle = textLabel(
	levelPanel,
	"Subtitle",
	"Inherit one forsaken relic",
	UDim2.new(1, -40, 0, 30),
	UDim2.new(0.5, 0, 0, 66),
	Vector2.new(0.5, 0),
	Enum.Font.GothamMedium,
	COLORS.muted,
	15
)
levelSubtitle.ZIndex = 12

local levelSigilImageId = imageUri(Config.AssetIds.Images.LevelUpSigil)
if levelSigilImageId then
	local levelSigil = Instance.new("ImageLabel")
	levelSigil.Name = "LevelUpSigil"
	levelSigil.Size = UDim2.fromOffset(116, 116)
	levelSigil.Position = UDim2.new(0.5, 0, 0, -9)
	levelSigil.AnchorPoint = Vector2.new(0.5, 0)
	levelSigil.BackgroundTransparency = 1
	levelSigil.Image = levelSigilImageId
	levelSigil.ImageTransparency = 0.64
	levelSigil.ScaleType = Enum.ScaleType.Fit
	levelSigil.ZIndex = 11
	levelSigil.Parent = levelPanel
end

local choicesFrame = Instance.new("Frame")
choicesFrame.Name = "Choices"
choicesFrame.Size = UDim2.new(1, -48, 0, 190)
choicesFrame.Position = UDim2.fromOffset(24, 112)
choicesFrame.BackgroundTransparency = 1
choicesFrame.ZIndex = 12
choicesFrame.Parent = levelPanel
local choicesLayout = Instance.new("UIListLayout")
choicesLayout.FillDirection = Enum.FillDirection.Horizontal
choicesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
choicesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
choicesLayout.Padding = UDim.new(0, 14)
choicesLayout.Parent = choicesFrame

local resultOverlay = Instance.new("Frame")
resultOverlay.Name = "ResultOverlay"
resultOverlay.Size = UDim2.fromScale(1, 1)
resultOverlay.BackgroundColor3 = COLORS.ink
resultOverlay.BackgroundTransparency = 0.1
resultOverlay.BorderSizePixel = 0
resultOverlay.Visible = false
resultOverlay.ZIndex = 30
resultOverlay.Parent = gui

local resultTitle = textLabel(
	resultOverlay,
	"ResultTitle",
	"DAWN BREAKS",
	UDim2.new(1, -40, 0, 90),
	UDim2.fromScale(0.5, 0.35),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamBlack,
	COLORS.gold,
	48
)
resultTitle.ZIndex = 31
local resultText = textLabel(
	resultOverlay,
	"ResultText",
	"The vigil is complete.",
	UDim2.new(1, -40, 0, 90),
	UDim2.fromScale(0.5, 0.49),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamMedium,
	COLORS.cream,
	20
)
resultText.ZIndex = 31

local resultButton = Instance.new("TextButton")
resultButton.Name = "ResultButton"
resultButton.Size = UDim2.new(1, -40, 0, 56)
resultButton.Position = UDim2.fromScale(0.5, 0.66)
resultButton.AnchorPoint = Vector2.new(0.5, 0.5)
resultButton.BackgroundColor3 = COLORS.panelLight
resultButton.AutoButtonColor = false
resultButton.Text = "RETURN TO THE VIGIL"
resultButton.TextColor3 = COLORS.cream
resultButton.Font = Enum.Font.GothamBlack
resultButton.TextSize = 18
resultButton.Visible = false
resultButton.ZIndex = 31
resultButton.Parent = resultOverlay
corner(resultButton, 12)
local resultButtonStroke = stroke(resultButton, COLORS.gold, 2, 0.15)

local resultButtonSizeConstraint = Instance.new("UISizeConstraint")
resultButtonSizeConstraint.Name = "ResponsiveSize"
resultButtonSizeConstraint.MinSize = Vector2.new(200, 56)
resultButtonSizeConstraint.MaxSize = Vector2.new(300, 56)
resultButtonSizeConstraint.Parent = resultButton

local returnToVigilFrameImageId = imageUri(Config.AssetIds.Images.ReturnToVigilFrame)
local returnToVigilFrame = nil
if returnToVigilFrameImageId then
	returnToVigilFrame = Instance.new("ImageLabel")
	returnToVigilFrame.Name = "ReturnToVigilFrame"
	returnToVigilFrame.Size = UDim2.fromScale(1, 1)
	returnToVigilFrame.BackgroundTransparency = 1
	returnToVigilFrame.Image = returnToVigilFrameImageId
	returnToVigilFrame.ScaleType = Enum.ScaleType.Stretch
	returnToVigilFrame.Active = false
	returnToVigilFrame.Selectable = false
	returnToVigilFrame.ZIndex = resultButton.ZIndex + 1
	returnToVigilFrame.Parent = resultButton
	resultButtonStroke.Transparency = 0.65
end

local function setResultButtonHighlighted(highlighted)
	TweenService:Create(resultButton, TweenInfo.new(0.12), {
		BackgroundColor3 = highlighted and Color3.fromRGB(83, 49, 77) or COLORS.panelLight,
	}):Play()
	resultButtonStroke.Transparency = highlighted and (returnToVigilFrame and 0.25 or 0)
		or (returnToVigilFrame and 0.65 or 0.15)
end

resultButton.MouseEnter:Connect(function()
	setResultButtonHighlighted(true)
end)
resultButton.MouseLeave:Connect(function()
	setResultButtonHighlighted(false)
end)
resultButton.SelectionGained:Connect(function()
	setResultButtonHighlighted(true)
end)
resultButton.SelectionLost:Connect(function()
	setResultButtonHighlighted(false)
end)

local scale = Instance.new("UIScale")
scale.Name = "ResponsiveScale"
scale.Parent = levelPanel
local function updateScale()
	local viewport = camera.ViewportSize
	scale.Scale = math.min(1, math.max(0.62, viewport.X / 900))
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

local previousHealth = 100
local choiceLocked = false
local restartRequested = false

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function clearChoices()
	for _, child in ipairs(choicesFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function showLevelChoices(choices, level)
	choiceLocked = false
	clearChoices()
	levelTitle.Text = "LEVEL " .. tostring(level)
	levelOverlay.Visible = true
	levelPanel.Size = UDim2.fromOffset(700, 300)
	TweenService:Create(levelPanel, TweenInfo.new(0.24, Enum.EasingStyle.Back), {
		Size = UDim2.fromOffset(760, 330),
	}):Play()

	for index, choice in ipairs(choices) do
		local imageKey = CHOICE_IMAGE_KEYS[choice.id]
		local iconImage = imageKey and imageUri(Config.AssetIds.Images[imageKey]) or nil
		local button = Instance.new("TextButton")
		button.Name = choice.id
		button.Size = UDim2.fromOffset(218, 176)
		button.BackgroundColor3 = index == 1 and Color3.fromRGB(70, 42, 66) or COLORS.panelLight
		button.AutoButtonColor = false
		button.Text = iconImage and "" or (choice.title .. "\n\n" .. choice.description)
		button.TextColor3 = COLORS.cream
		button.TextSize = 17
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.ZIndex = 13
		button.Parent = choicesFrame
		corner(button, 14)
		local buttonStroke = stroke(button, index == 1 and COLORS.gold or COLORS.purple, 2, 0.2)

		if iconImage then
			local icon = Instance.new("ImageLabel")
			icon.Name = "RelicIcon"
			icon.Size = UDim2.fromOffset(66, 66)
			icon.Position = UDim2.new(0.5, 0, 0, 8)
			icon.AnchorPoint = Vector2.new(0.5, 0)
			icon.BackgroundTransparency = 1
			icon.Image = iconImage
			icon.ScaleType = Enum.ScaleType.Fit
			icon.ZIndex = 14
			icon.Parent = button

			local iconTitle = textLabel(
				button,
				"RelicName",
				choice.title,
				UDim2.new(1, -16, 0, 28),
				UDim2.fromOffset(8, 77),
				Vector2.zero,
				Enum.Font.GothamBold,
				COLORS.cream,
				15
			)
			iconTitle.ZIndex = 14
			local iconDescription = textLabel(
				button,
				"RelicDescription",
				choice.description,
				UDim2.new(1, -18, 0, 58),
				UDim2.fromOffset(9, 107),
				Vector2.zero,
				Enum.Font.GothamMedium,
				COLORS.muted,
				12
			)
			iconDescription.ZIndex = 14
		end

		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(83, 49, 77),
			}):Play()
			buttonStroke.Transparency = 0
		end)
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = index == 1 and Color3.fromRGB(70, 42, 66) or COLORS.panelLight,
			}):Play()
			buttonStroke.Transparency = 0.2
		end)
		button.Activated:Connect(function()
			if choiceLocked then
				return
			end
			choiceLocked = true
			upgradeChoiceRemote:FireServer(choice.id)
			levelOverlay.Visible = false
		end)
	end
end

stateUpdateRemote.OnClientEvent:Connect(function(data)
	local remaining = math.max(0, data.duration - data.elapsed)
	timerLabel.Text = formatTime(remaining)
	killsLabel.Text = "BANISHED  " .. tostring(data.kills)
	levelLabel.Text = "LEVEL " .. tostring(data.level)
	healthText.Text = string.format("%d / %d", math.ceil(data.health), math.ceil(data.maxHealth))
	healthFill.Size = UDim2.fromScale(math.clamp(data.health / math.max(data.maxHealth, 1), 0, 1), 1)
	xpFill.Size = UDim2.fromScale(math.clamp(data.xp / math.max(data.xpNeeded, 1), 0, 1), 1)
	xpText.Text = string.format("%d / %d XP", data.xp, data.xpNeeded)
	relicTitle.Text = data.damageMultiplier > 1.001
		and string.format("RELICS BOUND  -  %.2fx POWER", data.damageMultiplier)
		or "RELICS BOUND"
	haloRelic.Text = data.graveHaloRank > 0 and ("Grave Halo  " .. tostring(data.graveHaloRank)) or "Grave Halo  -"
	haloRelic.TextColor3 = data.graveHaloRank > 0 and COLORS.cream or COLORS.muted
	flameRelic.Text = data.blackflameRank > 0 and ("Blackflame Testament  " .. tostring(data.blackflameRank)) or "Blackflame Testament  -"
	flameRelic.TextColor3 = data.blackflameRank > 0 and COLORS.cream or COLORS.muted
	bossPanel.Visible = data.bossActive == true
	if data.bossActive then
		bossName.Text = data.bossName or "THE CINDER WARDEN"
		bossHealthFill.Size = UDim2.fromScale(math.clamp(data.bossHealth / math.max(data.bossMaxHealth, 1), 0, 1), 1)
	end

	if data.bossDefeated then
		threatLabel.Text = "OATH SUNDERED"
		threatLabel.TextColor3 = COLORS.gold
	elseif data.bossActive and remaining > 30 then
		threatLabel.Text = "THE WARDEN DESCENDS"
		threatLabel.TextColor3 = COLORS.red
	elseif remaining <= 30 then
		threatLabel.Text = "DAWN IS NEAR"
		threatLabel.TextColor3 = COLORS.gold
	elseif data.enemies >= 120 then
		threatLabel.Text = "OVERWHELMING"
	elseif data.elapsed >= 120 then
		threatLabel.Text = "THE HORDE RISES"
	else
		threatLabel.Text = "THE LONG NIGHT"
	end

	if data.health < previousHealth then
		vignette.BackgroundTransparency = 0.72
		TweenService:Create(vignette, TweenInfo.new(0.35), {
			BackgroundTransparency = 1,
		}):Play()
	end
	previousHealth = data.health
end)

levelUpRemote.OnClientEvent:Connect(showLevelChoices)

local announcementToken = 0
announcementRemote.OnClientEvent:Connect(function(title, body, accentColor)
	announcementToken += 1
	local token = announcementToken
	announcementPanel.Visible = true
	announcementPanel.BackgroundTransparency = 1
	announcementTitle.Text = title
	announcementTitle.TextColor3 = accentColor or COLORS.gold
	announcementTitle.TextTransparency = 1
	announcementBody.Text = body
	announcementBody.TextTransparency = 1
	TweenService:Create(announcementPanel, TweenInfo.new(0.35), {
		BackgroundTransparency = 0.3,
	}):Play()
	TweenService:Create(announcementTitle, TweenInfo.new(0.35), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(announcementBody, TweenInfo.new(0.5), {
		TextTransparency = 0,
	}):Play()
	task.delay(3.1, function()
		if token ~= announcementToken then
			return
		end
		TweenService:Create(announcementPanel, TweenInfo.new(0.5), {
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(announcementTitle, TweenInfo.new(0.5), {
			TextTransparency = 1,
		}):Play()
		TweenService:Create(announcementBody, TweenInfo.new(0.5), {
			TextTransparency = 1,
		}):Play()
		task.delay(0.55, function()
			if token == announcementToken then
				announcementPanel.Visible = false
			end
		end)
	end)
end)

gameEndedRemote.OnClientEvent:Connect(function(won, kills, survived, wardenDefeated)
	levelOverlay.Visible = false
	resultOverlay.Visible = true
	resultButton.Visible = not won
	restartRequested = false
	if won then
		resultTitle.Text = wardenDefeated and "THE OATH IS SUNDERED" or "THE VIGIL ENDURES"
		resultTitle.TextColor3 = COLORS.gold
		resultText.Text = wardenDefeated
			and string.format("The Cinder Warden has fallen.\n%d forsaken banished.", kills)
			or string.format("You endured until dawn. The Warden remains.\n%d forsaken banished.", kills)
	else
		resultTitle.Text = "YOUR VIGIL ENDS"
		resultTitle.TextColor3 = COLORS.red
		resultText.Text = string.format("Endured %s  -  %d forsaken banished.", formatTime(survived), kills)
	end
end)

resultButton.Activated:Connect(function()
	if restartRequested then
		return
	end
	restartRequested = true
	restartVigilRemote:FireServer()
	task.delay(2, function()
		restartRequested = false
	end)
end)

player.CharacterAdded:Connect(function()
	resultOverlay.Visible = false
	restartRequested = false
end)

local intro = textLabel(
	gui,
	"Intro",
	"ASHEN\nVIGIL",
	UDim2.fromOffset(520, 150),
	UDim2.fromScale(0.5, 0.5),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamBlack,
	COLORS.cream,
	40
)
intro.ZIndex = 50
intro.TextTransparency = 0
task.delay(1.1, function()
	TweenService:Create(intro, TweenInfo.new(0.8), {
		TextTransparency = 1,
	}):Play()
	task.delay(0.9, function()
		intro:Destroy()
	end)
end)

RunService:BindToRenderStep("AshenVigilCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 58
	local desiredPosition = root.Position + Vector3.new(0, 55, 39)
	local desired = CFrame.lookAt(desiredPosition, root.Position + Vector3.new(0, 0, -4))
	camera.CFrame = camera.CFrame:Lerp(desired, 0.13)
end)
]====])

print("Ashen Vigil installed! Press Play to begin.")
