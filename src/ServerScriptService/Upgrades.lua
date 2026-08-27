local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Quests = require(script.Parent:WaitForChild("Quests"))

-- The leveling/relic system: offering choices, applying their effects, and
-- tracking XP. Effect magnitudes live in Config.Upgrades[id].Effect.
local Upgrades = {}

local random = Random.new()
local levelUpRemote

function Upgrades.Init(levelUpRemoteInstance)
	levelUpRemote = levelUpRemoteInstance
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

function Upgrades.OfferNext(player, state)
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

function Upgrades.GainExperience(player, state, amount)
	state.xp += amount
	while state.xp >= state.xpNeeded do
		state.xp -= state.xpNeeded
		state.level += 1
		state.xpNeeded = GameState.xpRequired(state.level)
		state.unclaimedLevels += 1
	end
	Upgrades.OfferNext(player, state)
end

function Upgrades.Apply(player, state, upgradeId)
	local _, humanoid, root = GameState.getLivingCharacter(player)
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
		Effects.PlaySpatialSound("RelicInherited", root.Position, 0.82, 4)
	end
end

return Upgrades
