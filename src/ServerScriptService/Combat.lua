local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Enemies = require(script.Parent:WaitForChild("Enemies"))

-- Player-side offense: the automatic dart attack and the two periodic relic
-- abilities (Grave Halo, Blackflame Testament). Picks targets and computes
-- damage/radius from relic ranks, then hands the actual hit off to Enemies.
local Combat = {}

function Combat.PerformAttack(player, state)
	local _, _, root = GameState.getLivingCharacter(player)
	if not root then
		return
	end

	local candidates = {}
	for part, enemyData in pairs(GameState.enemies) do
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
		Effects.CreateProjectileVisual(root.Position + Vector3.new(0, 1.2, 0), targetPosition)
		Enemies.Damage(player, enemyData, state.damage * state.damageMultiplier)
	end
end

function Combat.PerformGraveHalo(player, state)
	local _, _, root = GameState.getLivingCharacter(player)
	if not root then
		return
	end
	local effect = Config.Upgrades.GraveHalo.Effect
	local radius = effect.BaseRadius + state.graveHaloRank * effect.RadiusPerRank
	local damage = (effect.BaseDamage + state.graveHaloRank * effect.DamagePerRank) * state.damageMultiplier
	Effects.CreateRuinRing(root.Position, radius, Color3.fromRGB(181, 146, 92), 0.42)
	Effects.PlaySpatialSound("GraveHalo", root.Position, 0.7, 3)

	local targets = {}
	for part, enemyData in pairs(GameState.enemies) do
		if part.Parent and enemyData.health > 0 and (part.Position - root.Position).Magnitude <= radius then
			table.insert(targets, enemyData)
		end
	end
	for _, enemyData in ipairs(targets) do
		Enemies.Damage(player, enemyData, damage)
	end
end

function Combat.PerformBlackflame(player, state)
	local _, _, root = GameState.getLivingCharacter(player)
	if not root then
		return
	end

	local blackflameEffect = Config.Upgrades.Blackflame.Effect
	local targetData = nil
	local nearestDistance = blackflameEffect.TargetSearchRange
	for part, enemyData in pairs(GameState.enemies) do
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
	Effects.PlaySpatialSound("BlackflameTestament", center, 0.72, 3)
	Effects.CreateBlackflameBurst(center, radius)

	local targets = {}
	for part, enemyData in pairs(GameState.enemies) do
		if part.Parent and enemyData.health > 0 and (part.Position - center).Magnitude <= radius then
			table.insert(targets, enemyData)
		end
	end
	for _, enemyData in ipairs(targets) do
		Enemies.Damage(player, enemyData, damage)
	end
end

return Combat
