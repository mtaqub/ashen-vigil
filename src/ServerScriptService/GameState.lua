local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Shared, mutable per-match and per-player state, plus the small read-only
-- helpers nearly every gameplay module needs. Tables here are always mutated
-- in place (fields cleared/set, never rebound to a new table) so any module
-- holding GameState.enemies/gems keeps seeing the same table and its
-- mutations, instead of silently pointing at a stale one after a reset.
local GameState = {}

GameState.playerStates = {}
GameState.enemies = {}
GameState.gems = {}
GameState.enemyCount = 0
GameState.bossEnemy = nil
GameState.bossSpawned = false
GameState.bossDefeated = false
GameState.elapsedTime = 0
GameState.spawnAccumulator = 0
GameState.updateAccumulator = 0
GameState.gameEnded = false

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

function GameState.nearestLivingPlayer(position)
	local bestPlayer = nil
	local bestRoot = nil
	local bestDistance = math.huge
	for player, state in pairs(GameState.playerStates) do
		-- Players with a pending relic choice are excluded from targeting: enemies
		-- neither spawn toward them nor chase them while they're stuck in that menu.
		if state.alive and not state.pendingChoice then
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

function GameState.anyOtherPlayerAlive(excludedPlayer)
	for otherPlayer, otherState in pairs(GameState.playerStates) do
		if otherPlayer ~= excludedPlayer and otherState.alive then
			return true
		end
	end
	return false
end

function GameState.xpRequired(level)
	local xp = Config.XP
	return math.floor(xp.Base + (level - 1) * xp.PerLevel + ((level - 1) ^ xp.Exponent))
end

-- Resets a player's authoritative run stats back to fresh starting values in
-- place (same table identity), so both first spawn and a post-death restart
-- go through one definition of "the beginning of the run".
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
	return state
end

-- Clears every enemy, pickup, and boss/timer value back to a clean slate.
-- Only call this when it is safe to do so: either nobody else has a run in
-- progress (so there is nothing of theirs to disrupt), or the shared vigil
-- has already ended for the whole server (time-out), in which case the world
-- is already fully idle and restarting it can't interrupt anyone.
function GameState.resetMatch()
	for part, enemyData in pairs(GameState.enemies) do
		if enemyData.part then
			enemyData.part:Destroy()
		end
		GameState.enemies[part] = nil
	end
	GameState.enemyCount = 0

	for gem in pairs(GameState.gems) do
		gem:Destroy()
		GameState.gems[gem] = nil
	end

	GameState.bossEnemy = nil
	GameState.bossSpawned = false
	GameState.bossDefeated = false
	GameState.elapsedTime = 0
	GameState.spawnAccumulator = 0
	GameState.updateAccumulator = 0
	GameState.gameEnded = false
end

return GameState
