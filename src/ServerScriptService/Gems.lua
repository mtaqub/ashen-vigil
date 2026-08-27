local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Upgrades = require(script.Parent:WaitForChild("Upgrades"))

-- Blood-shard economy: spawning XP pickups and their per-frame aging/magnet/
-- collection behavior.
local Gems = {}

local gemsFolder
local random = Random.new()

function Gems.Init(folder)
	gemsFolder = folder
end

function Gems.Spawn(position, amount)
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
	GameState.gems[gem] = {
		amount = amount,
		age = 0,
		baseY = gem.Position.Y,
		phase = random:NextNumber(0, math.pi * 2),
	}
end

function Gems.Update(dt)
	for gem, gemData in pairs(GameState.gems) do
		if not gem.Parent then
			GameState.gems[gem] = nil
			continue
		end
		gemData.age += dt
		if gemData.age >= Config.Gems.Lifetime then
			GameState.gems[gem] = nil
			gem:Destroy()
			continue
		end

		local collector = nil
		local collectorState = nil
		local collectorRoot = nil
		local nearestDistance = math.huge
		for player, state in pairs(GameState.playerStates) do
			if state.alive then
				local _, _, root = GameState.getLivingCharacter(player)
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
			if nearestDistance <= Config.Gems.PickupMergeDistance then
				Upgrades.GainExperience(collector, collectorState, gemData.amount)
				Effects.PlaySpatialSound("BloodShardPickup", gem.Position, 0.42, 2)
				GameState.gems[gem] = nil
				gem:Destroy()
			else
				local direction = (collectorRoot.Position - gem.Position).Unit
				local speed = Config.Gems.MagnetBaseSpeed + math.max(0, collectorState.pickupRadius - nearestDistance) * Config.Gems.MagnetSpeedPerStud
				gem.Position += direction * speed * dt
			end
		else
			gem.CFrame = CFrame.new(gem.Position.X, gemData.baseY + math.sin(gemData.age * 3 + gemData.phase) * 0.25, gem.Position.Z)
				* CFrame.Angles(0, gemData.age * 2, math.rad(45))
		end
	end
end

return Gems
