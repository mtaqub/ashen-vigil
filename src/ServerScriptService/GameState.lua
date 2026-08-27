local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Shared, mutable per-match and per-player state, plus the small read-only
-- helpers nearly every gameplay module needs. Tables here are always mutated
-- in place (fields cleared/set, never rebound to a new table) so any module
-- holding GameState.enemies/gems keeps seeing the same table and its
-- mutations, instead of silently pointing at a stale one.
local GameState = {}

local random = Random.new()

GameState.playerStates = {}
GameState.enemies = {}
GameState.gems = {}
GameState.enemyCount = 0
GameState.bossEnemy = nil
GameState.bossDefeated = false
GameState.elapsedTime = 0
GameState.spawnAccumulator = 0
GameState.updateAccumulator = 0
-- The Vigil is persistent, so the Warden recurs on an interval rather than
-- spawning once. This is the elapsedTime value at which the next attempt
-- happens (advanced by Config.BOSS_SPAWN_TIME whenever a Warden spawns).
GameState.nextBossSpawnTime = Config.BOSS_SPAWN_TIME

function GameState.getLivingCharacter(player)
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

-- Nearest in-Vigil living player to a world position. Lobby-standing players
-- are never eligible targets, regardless of alive/level state.
function GameState.nearestLivingPlayer(position)
	local bestPlayer = nil
	local bestRoot = nil
	local bestDistance = math.huge
	for player, state in pairs(GameState.playerStates) do
		if state.alive and state.inVigil then
			local _, humanoid, root = GameState.getLivingCharacter(player)
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

-- Players currently alive and inside the Vigil (excludes anyone in the
-- Lobby). Used to scale spawn pressure/difficulty and to pick spawn anchors.
function GameState.playersInVigil()
	local players = {}
	for player, state in pairs(GameState.playerStates) do
		if state.alive and state.inVigil then
			table.insert(players, player)
		end
	end
	return players
end

function GameState.randomInVigilPlayer()
	local players = GameState.playersInVigil()
	if #players == 0 then
		return nil
	end
	return players[random:NextInteger(1, #players)]
end

-- Average level across everyone currently in the Vigil; defaults to 1 (the
-- starting level) when nobody's in, so difficulty formulas never divide by
-- zero or scale off a stale/empty population.
function GameState.averageInVigilLevel()
	local players = GameState.playersInVigil()
	if #players == 0 then
		return 1
	end
	local total = 0
	for _, player in ipairs(players) do
		total += GameState.playerStates[player].level
	end
	return total / #players
end

function GameState.xpRequired(level)
	local xp = Config.XP
	return math.floor(xp.Base + (level - 1) * xp.PerLevel + ((level - 1) ^ xp.Exponent))
end

-- Resets a player's authoritative run stats back to fresh starting values in
-- place (same table identity), so both first spawn and re-entering the Vigil
-- after a death go through one definition of "the beginning of a run".
-- Does NOT touch state.inVigil — callers set that explicitly depending on
-- whether the player is entering the Vigil or landing in the Lobby.
function GameState.applyInitialState(state)
	state.level = 1
	state.xp = 0
	state.xpNeeded = GameState.xpRequired(1)
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
	if state.inVigil == nil then
		state.inVigil = false
	end
	state.vigilEnteredAt = 0
	return state
end

return GameState
