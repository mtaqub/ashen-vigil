local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local LobbyBuilder = require(script.Parent:WaitForChild("LobbyBuilder"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Upgrades = require(script.Parent:WaitForChild("Upgrades"))
local Gems = require(script.Parent:WaitForChild("Gems"))
local Enemies = require(script.Parent:WaitForChild("Enemies"))
local Combat = require(script.Parent:WaitForChild("Combat"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Quests = require(script.Parent:WaitForChild("Quests"))

Players.CharacterAutoLoads = false

local random = Random.new()

-- Unchanged from before the Lobby existed: where a character lands inside
-- the Vigil arena when they enter through the gate.
local VIGIL_SPAWN_CFRAME = CFrame.new(0, 4, 0)
local DEATH_RESPAWN_DELAY = 2.5

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
local announcementRemote = getOrCreate("RemoteEvent", "Announcement", remotes)
local openRollBoothRemote = getOrCreate("RemoteEvent", "OpenRollBooth", remotes)
local rollCharacterRemote = getOrCreate("RemoteEvent", "RollCharacter", remotes)
local reserveCurrentRemote = getOrCreate("RemoteEvent", "ReserveCurrent", remotes)
local swapReservedRemote = getOrCreate("RemoteEvent", "SwapReserved", remotes)

-- World geometry, lighting, and ambience live in ArenaBuilder/LobbyBuilder;
-- gameplay systems live in their own modules (GameState/Effects/Upgrades/
-- Gems/Enemies/Combat/Quests). This script wires them together and owns
-- player lifecycle, RemoteEvent handlers, and the main loop.
local worldFolders = ArenaBuilder.Build()
local lobby = LobbyBuilder.Build()
Effects.Init(worldFolders.effectsFolder)
Gems.Init(worldFolders.gemsFolder)
Enemies.Init(worldFolders.enemiesFolder, announcementRemote)
Upgrades.Init(levelUpRemote)
Quests.Init(announcementRemote)

local function findSkin(skinId)
	for _, skin in ipairs(Config.Characters) do
		if skin.id == skinId then
			return skin
		end
	end
	return nil
end

-- Themed re-skin via Humanoid:ApplyDescription -- keeps the standard R15
-- rig and every default animation/movement behavior, just re-themes
-- appearance so it never clashes with the enemy/environment palette.
-- Shirt/Pants/Face/accessory ids are optional (see AssetIds.Characters);
-- BodyColors alone already keep the look on-theme.
local function applySkinVisuals(character, humanoid, skinId)
	local skin = findSkin(skinId)
	if not skin then
		return
	end

	local description = Instance.new("HumanoidDescription")
	description.HeadColor = skin.bodyColors.head
	description.TorsoColor = skin.bodyColors.torso
	description.LeftArmColor = skin.bodyColors.leftArm
	description.RightArmColor = skin.bodyColors.rightArm
	description.LeftLegColor = skin.bodyColors.leftLeg
	description.RightLegColor = skin.bodyColors.rightLeg

	local assetIds = Config.AssetIds.Characters[skinId]
	if assetIds then
		if assetIds.Shirt and assetIds.Shirt > 0 then
			description.Shirt = assetIds.Shirt
		end
		if assetIds.Pants and assetIds.Pants > 0 then
			description.Pants = assetIds.Pants
		end
		if assetIds.Face and assetIds.Face > 0 then
			description.Face = assetIds.Face
		end
		if assetIds.HairAccessory and assetIds.HairAccessory > 0 then
			description.HairAccessory = assetIds.HairAccessory
		end
		if assetIds.BackAccessory and assetIds.BackAccessory > 0 then
			description.BackAccessory = assetIds.BackAccessory
		end
	end

	humanoid:ApplyDescription(description)

	local outline = character:FindFirstChild("OathboundOutline")
	if outline then
		outline.OutlineColor = skin.glowColor
	end
end

-- Layers the equipped skin's small gameplay bonus onto a freshly-reset
-- state (called right after GameState.applyInitialState everywhere that's
-- invoked), using the same fields the relic Effects system already applies
-- so it stacks the same way. maxHealthBonus is stashed on state since
-- Humanoid.MaxHealth is set separately by each call site.
local function applySkinStatBoost(state, skinId)
	state.maxHealthBonus = 0
	local skin = findSkin(skinId)
	if not skin or not skin.statBoost then
		return
	end
	local boost = skin.statBoost
	if boost.walkSpeedBonus then
		state.walkSpeed += boost.walkSpeedBonus
	end
	if boost.damageMultiplier then
		state.damageMultiplier *= boost.damageMultiplier
	end
	if boost.attackSpeedMultiplier then
		state.attackSpeed *= boost.attackSpeedMultiplier
	end
	if boost.pickupRadiusBonus then
		state.pickupRadius += boost.pickupRadiusBonus
	end
	if boost.maxHealthBonus then
		state.maxHealthBonus = boost.maxHealthBonus
	end
end

local function addPlayer(player)
	local state = GameState.applyInitialState({})
	GameState.playerStates[player] = state

	local profile = PlayerData.Load(player)
	Quests.EnsureCurrentSet(player)
	applySkinStatBoost(state, profile.equippedCharacter)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local root = character:WaitForChild("HumanoidRootPart")
		humanoid.MaxHealth = Config.STARTING_HEALTH + state.maxHealthBonus
		humanoid.Health = Config.STARTING_HEALTH + state.maxHealthBonus
		humanoid.WalkSpeed = state.walkSpeed
		-- Every character spawn/respawn lands in the safe Lobby; entering the
		-- Vigil is a deliberate act via the gate's ProximityPrompt below.
		root.CFrame = lobby.spawnCFrame

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

		applySkinVisuals(character, humanoid, profile.equippedCharacter)

		humanoid.Died:Connect(function()
			if state.alive then
				state.alive = false
				state.inVigil = false
				announcementRemote:FireClient(
					player,
					"YOU HAVE FALLEN",
					string.format("%d kills. The town welcomes you back.", state.kills),
					Color3.fromRGB(203, 169, 103)
				)
				task.delay(DEATH_RESPAWN_DELAY, function()
					if player.Parent then
						player:LoadCharacter()
					end
				end)
			end
		end)
	end)

	player:LoadCharacter()
end

-- Server-side ProximityPrompt handler: no RemoteEvent needed, this fires
-- natively on the server for a server-owned prompt. Teleports the existing
-- character into the Vigil (no respawn/CharacterAdded refire) with a fresh
-- run's stats.
lobby.vigilGate.Triggered:Connect(function(player)
	local state = GameState.playerStates[player]
	local profile = PlayerData.Get(player)
	if not state or not profile or state.inVigil then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	GameState.applyInitialState(state)
	applySkinStatBoost(state, profile.equippedCharacter)
	state.inVigil = true
	state.vigilEnteredAt = GameState.elapsedTime
	humanoid.MaxHealth = Config.STARTING_HEALTH + state.maxHealthBonus
	humanoid.Health = Config.STARTING_HEALTH + state.maxHealthBonus
	humanoid.WalkSpeed = state.walkSpeed
	root.CFrame = VIGIL_SPAWN_CFRAME

	announcementRemote:FireClient(player, "THE ASHEN VIGIL", "Endure the long night. Let no oath be forgotten.", Color3.fromRGB(203, 169, 103))
end)

-- Roll booth: browsing, rolling, and reserving/swapping. Rolling always
-- replaces the equipped skin (the old one is lost unless it was already
-- reserved); reserving/swapping is free and only ever touches the reserve
-- slot. See PlayerData.lua for the profile shape.
local function characterSummary(skinId)
	local skin = findSkin(skinId)
	if not skin then
		return nil
	end
	return {
		id = skin.id,
		name = skin.name,
		description = skin.description,
		glowColor = skin.glowColor,
	}
end

local function buildRollBoothPayload(profile)
	local roster = {}
	for _, skin in ipairs(Config.Characters) do
		table.insert(roster, characterSummary(skin.id))
	end
	return {
		embers = profile.embers,
		rollCost = Config.RollCost,
		robuxEnabled = Config.RobuxRollProductId ~= 0,
		equipped = characterSummary(profile.equippedCharacter),
		reserved = profile.reservedCharacter and characterSummary(profile.reservedCharacter) or nil,
		roster = roster,
	}
end

local function refreshRollBooth(player, profile)
	openRollBoothRemote:FireClient(player, buildRollBoothPayload(profile))
end

local function performRoll(player, profile)
	local pool = {}
	for _, skin in ipairs(Config.Characters) do
		if skin.id ~= profile.equippedCharacter then
			table.insert(pool, skin.id)
		end
	end
	if #pool == 0 then
		return
	end
	profile.equippedCharacter = pool[random:NextInteger(1, #pool)]

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if character and humanoid then
		applySkinVisuals(character, humanoid, profile.equippedCharacter)
	end

	PlayerData.Save(player)
	refreshRollBooth(player, profile)
end

lobby.rollBooth.Triggered:Connect(function(player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	refreshRollBooth(player, profile)
end)

rollCharacterRemote.OnServerEvent:Connect(function(player, method)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	if method == "embers" then
		if profile.embers < Config.RollCost then
			return
		end
		profile.embers -= Config.RollCost
		performRoll(player, profile)
	elseif method == "robux" then
		if Config.RobuxRollProductId == 0 then
			return
		end
		MarketplaceService:PromptProductPurchase(player, Config.RobuxRollProductId)
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(player, productId, wasPurchased)
	if wasPurchased and productId == Config.RobuxRollProductId then
		local profile = PlayerData.Get(player)
		if profile then
			performRoll(player, profile)
		end
	end
end)

reserveCurrentRemote.OnServerEvent:Connect(function(player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	profile.reservedCharacter = profile.equippedCharacter
	PlayerData.Save(player)
	refreshRollBooth(player, profile)
end)

swapReservedRemote.OnServerEvent:Connect(function(player)
	local profile = PlayerData.Get(player)
	if not profile or not profile.reservedCharacter then
		return
	end
	profile.equippedCharacter, profile.reservedCharacter = profile.reservedCharacter, profile.equippedCharacter

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if character and humanoid then
		applySkinVisuals(character, humanoid, profile.equippedCharacter)
	end

	PlayerData.Save(player)
	refreshRollBooth(player, profile)
end)

upgradeChoiceRemote.OnServerEvent:Connect(function(player, upgradeId)
	local state = GameState.playerStates[player]
	if not state or not state.alive or not state.pendingChoice or type(upgradeId) ~= "string" then
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

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
	GameState.playerStates[player] = nil
	PlayerData.Save(player)
	PlayerData.Release(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(addPlayer, player)
end

game:BindToClose(function()
	PlayerData.SaveAll()
end)

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

local function summarizeQuests(activeSet, pool)
	local summary = {}
	for id, entry in pairs(activeSet) do
		for _, template in ipairs(pool) do
			if template.id == id then
				table.insert(summary, {
					title = template.title,
					description = template.description,
					progress = entry.progress,
					target = template.target,
					complete = entry.complete,
					reward = template.reward,
				})
				break
			end
		end
	end
	return summary
end

local function pushStateUpdates()
	for player, state in pairs(GameState.playerStates) do
		local _, humanoid = GameState.getLivingCharacter(player)
		local profile = PlayerData.Get(player)
		stateUpdateRemote:FireClient(player, {
			inVigil = state.inVigil,
			vigilElapsed = state.inVigil and (GameState.elapsedTime - state.vigilEnteredAt) or 0,
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
			embers = profile and profile.embers or 0,
			questsDaily = profile and summarizeQuests(profile.quests.daily, Config.Quests.Daily) or {},
			questsWeekly = profile and summarizeQuests(profile.quests.weekly, Config.Quests.Weekly) or {},
		})
	end
end

RunService.Heartbeat:Connect(function(dt)
	GameState.elapsedTime += dt

	-- The Warden recurs on an interval rather than spawning once, since the
	-- Vigil never resets. Only advance the schedule on a successful spawn,
	-- so an empty Vigil just keeps retrying instead of silently skipping a
	-- whole cycle.
	if GameState.bossEnemy == nil and GameState.elapsedTime >= GameState.nextBossSpawnTime then
		if Enemies.Spawn("Warden") then
			GameState.nextBossSpawnTime = GameState.elapsedTime + Config.BOSS_SPAWN_TIME
		end
	end

	-- Spawn pressure only accumulates while someone is actually in the Vigil,
	-- so an empty arena doesn't silently build up a burst that dumps on the
	-- next person to walk in.
	local inVigilPlayers = GameState.playersInVigil()
	local inVigilCount = #inVigilPlayers
	if inVigilCount > 0 then
		local baseRate = math.min(Config.Spawn.BaseRate + GameState.elapsedTime * Config.Spawn.RatePerSecond, Config.Spawn.MaxRate)
		GameState.spawnAccumulator += dt * (baseRate + math.max(0, inVigilCount - 1) * Config.Spawn.RatePerPlayer)
		local enemyCap = Config.MAX_ENEMIES + math.max(0, inVigilCount - 1) * Config.MAX_ENEMIES_PER_PLAYER
		while GameState.spawnAccumulator >= 1 and GameState.enemyCount < enemyCap do
			GameState.spawnAccumulator -= 1
			Enemies.Spawn()
		end
	end

	Enemies.Update(dt)
	Gems.Update(dt)
	updatePlayers(dt)

	GameState.updateAccumulator += dt
	if GameState.updateAccumulator >= Config.STATE_UPDATE_INTERVAL then
		-- "Survive N minutes" quest progress is tallied here rather than
		-- every frame, at the same cadence as the state push.
		for _, player in ipairs(inVigilPlayers) do
			Quests.Progress(player, "vigilMinutes", GameState.updateAccumulator / 60)
		end
		GameState.updateAccumulator = 0
		pushStateUpdates()
	end
end)
