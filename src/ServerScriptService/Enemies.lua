local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Gems = require(script.Parent:WaitForChild("Gems"))

-- Enemy spawning, movement/AI, boss special attacks, and taking damage
-- (health, death, boss-defeat, gem drop on kill).
local Enemies = {}

local enemiesFolder
local announcementRemote
local random = Random.new()

function Enemies.Init(folder, announcementRemoteInstance)
	enemiesFolder = folder
	announcementRemote = announcementRemoteInstance
end

local function chooseEnemyType()
	local spawn = Config.Spawn
	local roll = random:NextNumber()
	if GameState.elapsedTime >= spawn.BruteUnlockTime and roll < math.min(spawn.BruteBaseChance + GameState.elapsedTime * spawn.BruteChancePerSecond, spawn.BruteChanceCap) then
		return "Brute"
	end
	if GameState.elapsedTime >= spawn.GhoulUnlockTime and roll < math.min(spawn.GhoulBaseChance + GameState.elapsedTime * spawn.GhoulChancePerSecond, spawn.GhoulChanceCap) then
		return "Ghoul"
	end
	return "Bat"
end

local function createHealthBar(part, enemyData)
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

-- Spawns near a random in-Vigil player (rather than always the one nearest
-- to the arena center) so pressure spreads across everyone in a multiplayer
-- Vigil instead of clustering on whoever happens to be closest to origin.
function Enemies.Spawn(forcedEnemyId)
	local targetPlayer = GameState.randomInVigilPlayer()
	if not targetPlayer then
		return nil
	end
	local _, _, targetRoot = GameState.getLivingCharacter(targetPlayer)
	if not targetRoot then
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

	-- Difficulty tracks the average level of players currently in the Vigil
	-- (not elapsed time, which never resets) so a freshly-respawned level-1
	-- player isn't dropped into a fight calibrated for veterans.
	local averageLevel = GameState.averageInVigilLevel()
	local difficulty = enemyId == "Warden" and 1 or (1 + (averageLevel - 1) / Config.Difficulty.HealthScaleDivisor)
	local enemyData = {
		id = enemyId,
		part = part,
		health = template.Health * difficulty,
		maxHealth = template.Health * difficulty,
		speed = template.Speed * math.min(1 + (averageLevel - 1) / Config.Difficulty.SpeedScaleDivisor, Config.Difficulty.SpeedScaleCap),
		damage = template.Damage * math.min(1 + (averageLevel - 1) / Config.Difficulty.DamageScaleDivisor, Config.Difficulty.DamageScaleCap),
		xp = template.XP,
		lastHit = 0,
		baseColor = template.Color,
		bobOffset = random:NextNumber(0, math.pi * 2),
		specialClock = 0,
	}
	GameState.enemies[part] = enemyData
	GameState.enemyCount += 1
	createHealthBar(part, enemyData)
	if enemyId == "Warden" then
		GameState.bossEnemy = enemyData
		GameState.bossDefeated = false
		announcementRemote:FireAllClients("THE CINDER WARDEN", "An ancient oath stirs beneath the ash.", Color3.fromRGB(214, 143, 62))
	end
	return enemyData
end

function Enemies.Damage(player, enemyData, damage)
	local part = enemyData.part
	if not part or not part.Parent or enemyData.health <= 0 then
		return
	end

	enemyData.health -= damage
	if enemyData.healthFill then
		enemyData.healthFill.Size = UDim2.fromScale(math.max(enemyData.health / enemyData.maxHealth, 0), 1)
	end
	Effects.ShowHitEffect(part.Position, Color3.fromRGB(255, 230, 185))

	if enemyData.health <= 0 then
		local state = GameState.playerStates[player]
		if state then
			state.kills += 1
		end
		Gems.Spawn(part.Position, enemyData.xp)
		if enemyData.id == "Warden" then
			GameState.bossDefeated = true
			GameState.bossEnemy = nil
			announcementRemote:FireAllClients("OATH SUNDERED", "The Warden returns to cinder.", Color3.fromRGB(235, 190, 93))
		end
		GameState.enemies[part] = nil
		GameState.enemyCount = math.max(GameState.enemyCount - 1, 0)
		part:Destroy()
	end
end

local function beginWardenPulse(enemyData)
	local part = enemyData.part
	if not part or not part.Parent then
		return
	end
	local boss = Config.Boss
	local center = part.Position
	local radius = boss.PulseRadius
	Effects.CreateRuinRing(center, radius, Color3.fromRGB(207, 48, 39), 0.9)
	Effects.PlaySpatialSound("WardenTelegraph", center, 0.9, 3)
	task.delay(boss.PulseTelegraphDelay, function()
		if enemyData.health <= 0 or not part.Parent then
			return
		end
		Effects.ShowHitEffect(center, Color3.fromRGB(221, 79, 34))
		Effects.PlaySpatialSound("WardenImpact", center, 1, 4)
		for player, state in pairs(GameState.playerStates) do
			if state.alive and not state.pendingChoice then
				local _, humanoid, root = GameState.getLivingCharacter(player)
				if humanoid and root and (root.Position - center).Magnitude <= radius then
					humanoid:TakeDamage(boss.PulseDamage)
				end
			end
		end
	end)
end

function Enemies.Update(dt)
	for part, enemyData in pairs(GameState.enemies) do
		if not part.Parent then
			GameState.enemies[part] = nil
			GameState.enemyCount = math.max(GameState.enemyCount - 1, 0)
			continue
		end

		local targetPlayer, targetRoot, distance = GameState.nearestLivingPlayer(part.Position)
		if not targetPlayer or not targetRoot then
			continue
		end

		local offset = targetRoot.Position - part.Position
		local horizontal = Vector3.new(offset.X, 0, offset.Z)
		if horizontal.Magnitude > 0.1 then
			local direction = horizontal.Unit
			local newPosition = part.Position + direction * enemyData.speed * dt
			local hover = enemyData.id == "Bat" and (2.2 + math.sin(GameState.elapsedTime * 5 + enemyData.bobOffset) * 0.6) or (part.Size.Y * 0.5)
			newPosition = Vector3.new(newPosition.X, hover, newPosition.Z)
			part.CFrame = CFrame.lookAt(newPosition, newPosition + direction)
		end

		if enemyData.id == "Warden" then
			enemyData.specialClock += dt
			if enemyData.specialClock >= Config.Boss.PulseInterval then
				enemyData.specialClock = 0
				beginWardenPulse(enemyData)
			end
		end

		local contactDistance = math.max(Config.Combat.EnemyContactMinDistance, part.Size.X * 0.5 + Config.Combat.EnemyContactDistancePadding)
		if distance <= contactDistance and GameState.elapsedTime - enemyData.lastHit >= Config.Combat.EnemyContactCooldown then
			enemyData.lastHit = GameState.elapsedTime
			local _, humanoid = GameState.getLivingCharacter(targetPlayer)
			local targetState = GameState.playerStates[targetPlayer]
			if humanoid and targetState and not targetState.pendingChoice then
				humanoid:TakeDamage(enemyData.damage)
			end
		end
	end
end

return Enemies
