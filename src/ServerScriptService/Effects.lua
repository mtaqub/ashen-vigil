local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Transient VFX/SFX helpers. No game-state coupling: everything here just
-- spawns short-lived Instances into the effects folder handed in via Init.
local Effects = {}

local effectsFolder

local function assetUri(assetId)
	local numericId = tonumber(assetId)
	if not numericId or numericId <= 0 then
		return nil
	end
	return "rbxassetid://" .. tostring(math.floor(numericId))
end

function Effects.Init(folder)
	effectsFolder = folder
end

function Effects.PlaySpatialSound(soundKey, position, volume, lifetime)
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

function Effects.ShowHitEffect(position, color)
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

function Effects.CreateProjectileVisual(fromPosition, toPosition)
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
	Effects.PlaySpatialSound("AshenDart", fromPosition, 0.28, 2)

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

function Effects.CreateRuinRing(position, radius, color, duration)
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

function Effects.CreateBlackflameBurst(center, radius)
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
end

return Effects
