local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Upgrades = require(script.Parent:WaitForChild("Upgrades"))
local Gems = require(script.Parent:WaitForChild("Gems"))
local Enemies = require(script.Parent:WaitForChild("Enemies"))
local Combat = require(script.Parent:WaitForChild("Combat"))

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

-- World geometry, lighting, and ambience live in ArenaBuilder; gameplay
-- systems live in their own modules (GameState/Effects/Upgrades/Gems/
-- Enemies/Combat). This script wires them together and owns player
-- lifecycle, RemoteEvent handlers, and the main loop.
local worldFolders = ArenaBuilder.Build()
Effects.Init(worldFolders.effectsFolder)
Gems.Init(worldFolders.gemsFolder)
Enemies.Init(worldFolders.enemiesFolder, announcementRemote)
Upgrades.Init(levelUpRemote)

local function addPlayer(player)
	local state = GameState.applyInitialState({})
	GameState.playerStates[player] = state

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
				gameEndedRemote:FireClient(player, false, state.kills, GameState.elapsedTime)
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
	local state = GameState.playerStates[player]
	if not state then
		return
	end
	GameState.applyInitialState(state)
	player:LoadCharacter()
end

upgradeChoiceRemote.OnServerEvent:Connect(function(player, upgradeId)
	local state = GameState.playerStates[player]
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

	Upgrades.Apply(player, state, upgradeId)
	state.pendingChoice = nil
	state.unclaimedLevels = math.max(state.unclaimedLevels - 1, 0)
	task.delay(0.15, function()
		if player.Parent then
			Upgrades.OfferNext(player, state)
		end
	end)
end)

restartVigilRemote.OnServerEvent:Connect(function(player)
	local state = GameState.playerStates[player]
	if not state or state.alive then
		return
	end
	if GameState.gameEnded or not GameState.anyOtherPlayerAlive(player) then
		GameState.resetMatch()
		announcementRemote:FireAllClients(
			"THE VIGIL BEGINS ANEW",
			"A new night falls over the ashen court.",
			Color3.fromRGB(203, 169, 103)
		)
	end
	resetPlayerForNewVigil(player)
end)

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
	GameState.playerStates[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(addPlayer, player)
end

local function updatePlayers(dt)
	for player, state in pairs(GameState.playerStates) do
		if not state.alive then
			continue
		end
		local _, humanoid = GameState.getLivingCharacter(player)
		if humanoid then
			state.attackClock += dt
			local attackPeriod = math.max(Config.Combat.AttackPeriodMin, Config.Combat.AttackPeriodBase / state.attackSpeed)
			if state.attackClock >= attackPeriod then
				state.attackClock %= attackPeriod
				Combat.PerformAttack(player, state)
			end

			if state.graveHaloRank > 0 then
				state.graveHaloClock += dt
				local haloEffect = Config.Upgrades.GraveHalo.Effect
				local haloPeriod = math.max(haloEffect.MinPeriod, haloEffect.BasePeriod - state.graveHaloRank * haloEffect.PeriodPerRank)
				if state.graveHaloClock >= haloPeriod then
					state.graveHaloClock %= haloPeriod
					Combat.PerformGraveHalo(player, state)
				end
			end

			if state.blackflameRank > 0 then
				state.blackflameClock += dt
				local flameEffect = Config.Upgrades.Blackflame.Effect
				local flamePeriod = math.max(flameEffect.MinPeriod, flameEffect.BasePeriod - state.blackflameRank * flameEffect.PeriodPerRank)
				if state.blackflameClock >= flamePeriod then
					state.blackflameClock %= flamePeriod
					Combat.PerformBlackflame(player, state)
				end
			end
		end
	end
end

local function pushStateUpdates()
	for player, state in pairs(GameState.playerStates) do
		local _, humanoid = GameState.getLivingCharacter(player)
		stateUpdateRemote:FireClient(player, {
			elapsed = GameState.elapsedTime,
			duration = Config.GAME_DURATION,
			level = state.level,
			xp = state.xp,
			xpNeeded = state.xpNeeded,
			kills = state.kills,
			health = humanoid and humanoid.Health or 0,
			maxHealth = humanoid and humanoid.MaxHealth or Config.STARTING_HEALTH,
			enemies = GameState.enemyCount,
			graveHaloRank = state.graveHaloRank,
			blackflameRank = state.blackflameRank,
			damageMultiplier = state.damageMultiplier,
			bossActive = GameState.bossEnemy ~= nil and GameState.bossEnemy.health > 0,
			bossHealth = GameState.bossEnemy and math.max(GameState.bossEnemy.health, 0) or 0,
			bossMaxHealth = GameState.bossEnemy and GameState.bossEnemy.maxHealth or 1,
			bossName = "THE CINDER WARDEN",
			bossDefeated = GameState.bossDefeated,
		})
	end
end

RunService.Heartbeat:Connect(function(dt)
	if GameState.gameEnded then
		return
	end

	GameState.elapsedTime += dt
	if not GameState.bossSpawned and GameState.elapsedTime >= Config.BOSS_SPAWN_TIME then
		GameState.bossSpawned = Enemies.Spawn("Warden") ~= nil
	end
	GameState.spawnAccumulator += dt * math.min(Config.Spawn.BaseRate + GameState.elapsedTime * Config.Spawn.RatePerSecond, Config.Spawn.MaxRate)
	while GameState.spawnAccumulator >= 1 and GameState.enemyCount < Config.MAX_ENEMIES do
		GameState.spawnAccumulator -= 1
		Enemies.Spawn()
	end

	Enemies.Update(dt)
	Gems.Update(dt)
	updatePlayers(dt)

	GameState.updateAccumulator += dt
	if GameState.updateAccumulator >= Config.STATE_UPDATE_INTERVAL then
		GameState.updateAccumulator = 0
		pushStateUpdates()
	end

	if GameState.elapsedTime >= Config.GAME_DURATION then
		GameState.gameEnded = true
		for player, state in pairs(GameState.playerStates) do
			if state.alive then
				state.alive = false
				gameEndedRemote:FireClient(player, true, state.kills, GameState.elapsedTime, GameState.bossDefeated)
			end
		end
	end
end)
