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
	local xp = Config.XP
	return math.floor(xp.Base + (level - 1) * xp.PerLevel + ((level - 1) ^ xp.Exponent))
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
	local spawn = Config.Spawn
	local roll = random:NextNumber()
	if elapsedTime >= spawn.BruteUnlockTime and roll < math.min(spawn.BruteBaseChance + elapsedTime * spawn.BruteChancePerSecond, spawn.BruteChanceCap) then
		return "Brute"
	end
	if elapsedTime >= spawn.GhoulUnlockTime and roll < math.min(spawn.GhoulBaseChance + elapsedTime * spawn.GhoulChancePerSecond, spawn.GhoulChanceCap) then
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

	local difficulty = enemyId == "Warden" and 1 or (1 + elapsedTime / Config.Difficulty.HealthScaleDivisor)
	local enemyData = {
		id = enemyId,
		part = part,
		health = template.Health * difficulty,
		maxHealth = template.Health * difficulty,
		speed = template.Speed * math.min(1 + elapsedTime / Config.Difficulty.SpeedScaleDivisor, Config.Difficulty.SpeedScaleCap),
		damage = template.Damage * math.min(1 + elapsedTime / Config.Difficulty.DamageScaleDivisor, Config.Difficulty.DamageScaleCap),
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
	local effect = Config.Upgrades.GraveHalo.Effect
	local radius = effect.BaseRadius + state.graveHaloRank * effect.RadiusPerRank
	local damage = (effect.BaseDamage + state.graveHaloRank * effect.DamagePerRank) * state.damageMultiplier
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

	local blackflameEffect = Config.Upgrades.Blackflame.Effect
	local targetData = nil
	local nearestDistance = blackflameEffect.TargetSearchRange
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
	local radius = blackflameEffect.BaseRadius + state.blackflameRank * blackflameEffect.RadiusPerRank
	local damage = (blackflameEffect.BaseDamage + state.blackflameRank * blackflameEffect.DamagePerRank) * state.damageMultiplier
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
		if id == "Multishot" and state.projectiles >= Config.Upgrades.Multishot.Effect.MaxProjectiles then
			available = false
		elseif id == "Speed" and state.walkSpeed >= Config.Upgrades.Speed.Effect.MaxWalkSpeed then
			available = false
		elseif id == "GraveHalo" and state.graveHaloRank >= Config.Upgrades.GraveHalo.Effect.MaxRank then
			available = false
		elseif id == "Blackflame" and state.blackflameRank >= Config.Upgrades.Blackflame.Effect.MaxRank then
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
	local effect = Config.Upgrades[upgradeId].Effect
	if upgradeId == "RapidFire" then
		state.attackSpeed *= effect.AttackSpeedMultiplier
	elseif upgradeId == "Power" then
		state.damage += effect.DamageBonus
	elseif upgradeId == "Multishot" then
		state.projectiles = math.min(state.projectiles + 1, effect.MaxProjectiles)
	elseif upgradeId == "Range" then
		state.range += effect.RangeBonus
	elseif upgradeId == "Magnet" then
		state.pickupRadius += effect.PickupRadiusBonus
	elseif upgradeId == "Speed" then
		state.walkSpeed = math.min(state.walkSpeed + effect.WalkSpeedBonus, effect.MaxWalkSpeed)
		if humanoid then
			humanoid.WalkSpeed = state.walkSpeed
		end
	elseif upgradeId == "Vitality" and humanoid then
		humanoid.MaxHealth += effect.MaxHealthBonus
		humanoid.Health = math.min(humanoid.Health + effect.MaxHealthBonus, humanoid.MaxHealth)
	elseif upgradeId == "GraveHalo" then
		state.graveHaloRank = math.min(state.graveHaloRank + 1, effect.MaxRank)
		state.graveHaloClock = math.max(state.graveHaloClock, effect.InitialClock)
	elseif upgradeId == "Blackflame" then
		state.blackflameRank = math.min(state.blackflameRank + 1, effect.MaxRank)
		state.blackflameClock = math.max(state.blackflameClock, effect.InitialClock)
	elseif upgradeId == "CinderOath" then
		state.damageMultiplier *= effect.DamageMultiplier
		if humanoid then
			humanoid.MaxHealth = math.max(effect.MinMaxHealth, humanoid.MaxHealth - effect.MaxHealthPenalty)
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
				state.alive = false
				gameEndedRemote:FireClient(player, true, state.kills, elapsedTime, bossDefeated)
			end
		end
	end
end)
