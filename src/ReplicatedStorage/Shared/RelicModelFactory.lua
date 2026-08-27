-- Small, self-contained 3D icon models for the relic-choice screen, meant to
-- be rendered inside a ViewportFrame. Same Part/WedgePart construction
-- technique and dark-fantasy palette as ServerScriptService/MobModelFactory
-- (which builds the live enemy visuals), redeclared locally: a LocalScript
-- cannot require() anything under ServerScriptService (it isn't replicated
-- to clients at all), so this can't share that module directly.
--
-- Every model is built centered on CFrame.new(0, 0, 0) with all parts
-- Anchored (no physics/welds needed — a ViewportFrame is a static render
-- target, not a simulated world) and PrimaryPart set, so the caller can
-- rotate/bob the whole thing each frame with Model:PivotTo(...).

local COLORS = {
	void = Color3.fromRGB(38, 32, 50),
	slate = Color3.fromRGB(70, 58, 90),
	ash = Color3.fromRGB(82, 78, 86),
	bone = Color3.fromRGB(245, 231, 209),
	cinder = Color3.fromRGB(221, 44, 83),
	tarnishedGold = Color3.fromRGB(126, 88, 44),
	blackflame = Color3.fromRGB(107, 47, 139),
}

local RelicModelFactory = {}

local function makePiece(model, name, className, size, cframe, color, material, options)
	options = options or {}
	local piece = Instance.new(className)
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = color
	piece.Material = material
	piece.Anchored = true
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CastShadow = false
	if options.shape then
		piece.Shape = options.shape
	end
	if options.transparency then
		piece.Transparency = options.transparency
	end
	piece.Parent = model
	if options.light then
		local light = Instance.new("PointLight")
		light.Color = options.light.color or color
		light.Brightness = options.light.brightness or 2
		light.Range = options.light.range or 6
		light.Shadows = false
		light.Parent = piece
	end
	return piece
end

local function newModel(name)
	local model = Instance.new("Model")
	model.Name = name
	return model
end

local BUILDERS = {}

-- +20% attack speed: a glowing core with three dart-fragments circling it.
BUILDERS.RapidFire = function()
	local model = newModel("RapidFireRelic")
	local core = makePiece(model, "Core", "Part", Vector3.new(0.55, 0.55, 0.55), CFrame.new(0, 0, 0), COLORS.cinder, Enum.Material.Neon, {
		shape = Enum.PartType.Ball,
		light = { brightness = 2.2, range = 7 },
	})
	for index = 1, 3 do
		local angle = (index / 3) * math.pi * 2
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 1.05
		makePiece(model, "Dart" .. index, "WedgePart", Vector3.new(0.28, 0.28, 1.1), CFrame.new(offset) * CFrame.Angles(0, -angle, 0), COLORS.bone, Enum.Material.SmoothPlastic)
	end
	model.PrimaryPart = core
	return model
end

-- +8 damage: a small ornate blade.
BUILDERS.Power = function()
	local model = newModel("PowerRelic")
	local blade = makePiece(model, "Blade", "WedgePart", Vector3.new(0.35, 1.8, 0.5), CFrame.new(0, 0.5, 0), COLORS.ash, Enum.Material.Slate)
	makePiece(model, "Crossguard", "Part", Vector3.new(1, 0.2, 0.3), CFrame.new(0, -0.45, 0), COLORS.tarnishedGold, Enum.Material.CorrodedMetal)
	makePiece(model, "Hilt", "Part", Vector3.new(0.25, 0.7, 0.25), CFrame.new(0, -0.9, 0), COLORS.void, Enum.Material.Fabric)
	model.PrimaryPart = blade
	return model
end

-- +1 projectile: a forked shard.
BUILDERS.Multishot = function()
	local model = newModel("MultishotRelic")
	local center = makePiece(model, "Shard", "WedgePart", Vector3.new(0.3, 1.4, 0.4), CFrame.new(0, 0.2, 0), COLORS.cinder, Enum.Material.Neon)
	makePiece(model, "ShardLeft", "WedgePart", Vector3.new(0.25, 1, 0.35), CFrame.new(-0.5, -0.1, 0) * CFrame.Angles(0, 0, math.rad(22)), COLORS.blackflame, Enum.Material.Neon)
	makePiece(model, "ShardRight", "WedgePart", Vector3.new(0.25, 1, 0.35), CFrame.new(0.5, -0.1, 0) * CFrame.Angles(0, 0, math.rad(-22)), COLORS.blackflame, Enum.Material.Neon)
	model.PrimaryPart = center
	return model
end

-- +12 range: a reaching rod topped with a watchful eye.
BUILDERS.Range = function()
	local model = newModel("RangeRelic")
	local rod = makePiece(model, "Rod", "Part", Vector3.new(0.22, 1.8, 0.22), CFrame.new(0, 0, 0), COLORS.void, Enum.Material.Metal)
	makePiece(model, "EyeRing", "Part", Vector3.new(0.7, 0.15, 0.7), rod.CFrame * CFrame.new(0, 1, 0), COLORS.tarnishedGold, Enum.Material.CorrodedMetal, { shape = Enum.PartType.Cylinder })
	makePiece(model, "Eye", "Part", Vector3.new(0.4, 0.4, 0.4), rod.CFrame * CFrame.new(0, 1, 0), COLORS.cinder, Enum.Material.Neon, {
		shape = Enum.PartType.Ball,
		light = { brightness = 2, range = 8 },
	})
	model.PrimaryPart = rod
	return model
end

-- +6 pickup radius: shards drawn inward toward a dark core.
BUILDERS.Magnet = function()
	local model = newModel("MagnetRelic")
	local core = makePiece(model, "Core", "Part", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 0, 0), COLORS.void, Enum.Material.Basalt, { shape = Enum.PartType.Ball })
	for index = 1, 4 do
		local angle = (index / 4) * math.pi * 2
		local offset = Vector3.new(math.cos(angle), math.sin(angle) * 0.4, math.sin(angle)) * 1.2
		makePiece(model, "Shard" .. index, "Part", Vector3.new(0.22, 0.22, 0.4), CFrame.new(offset):Lerp(CFrame.new(0, 0, 0), 0) * CFrame.Angles(0, -angle, 0), COLORS.cinder, Enum.Material.Neon)
	end
	model.PrimaryPart = core
	return model
end

-- +2 movement speed: a pair of flaring wings.
BUILDERS.Speed = function()
	local model = newModel("SpeedRelic")
	local spine = makePiece(model, "Spine", "Part", Vector3.new(0.2, 1, 0.2), CFrame.new(0, 0, 0), COLORS.void, Enum.Material.Metal)
	makePiece(model, "WingLeft", "WedgePart", Vector3.new(1.3, 0.15, 0.8), CFrame.new(-0.7, 0.1, 0) * CFrame.Angles(0, 0, math.rad(18)), COLORS.bone, Enum.Material.SmoothPlastic)
	makePiece(model, "WingRight", "WedgePart", Vector3.new(1.3, 0.15, 0.8), CFrame.new(0.7, 0.1, 0) * CFrame.Angles(0, 0, math.rad(-18)), COLORS.bone, Enum.Material.SmoothPlastic)
	model.PrimaryPart = spine
	return model
end

-- +25 max health: a vessel with a warm ember of life inside it.
BUILDERS.Vitality = function()
	local model = newModel("VitalityRelic")
	local urn = makePiece(model, "Urn", "Part", Vector3.new(1, 1.1, 1), CFrame.new(0, 0, 0), COLORS.ash, Enum.Material.Slate, { shape = Enum.PartType.Ball })
	makePiece(model, "Rim", "Part", Vector3.new(0.6, 0.15, 0.6), urn.CFrame * CFrame.new(0, 0.6, 0), COLORS.tarnishedGold, Enum.Material.CorrodedMetal, { shape = Enum.PartType.Cylinder })
	makePiece(model, "Ember", "Part", Vector3.new(0.35, 0.35, 0.35), urn.CFrame, COLORS.cinder, Enum.Material.Neon, {
		shape = Enum.PartType.Ball,
		light = { brightness = 2.4, range = 7 },
	})
	model.PrimaryPart = urn
	return model
end

-- Grave Halo: matches the ring VFX (createRuinRing) — a flat glowing disc.
BUILDERS.GraveHalo = function()
	local model = newModel("GraveHaloRelic")
	local ring = makePiece(model, "Ring", "Part", Vector3.new(0.2, 1.6, 1.6), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), COLORS.tarnishedGold, Enum.Material.Neon, { shape = Enum.PartType.Cylinder })
	makePiece(model, "Core", "Part", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 0, 0), COLORS.cinder, Enum.Material.Neon, {
		shape = Enum.PartType.Ball,
		light = { brightness = 2, range = 6 },
	})
	model.PrimaryPart = ring
	return model
end

-- Blackflame Testament: matches the flame-orb VFX — a dark flame with tendrils.
BUILDERS.Blackflame = function()
	local model = newModel("BlackflameRelic")
	local core = makePiece(model, "Core", "Part", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 0, 0), COLORS.blackflame, Enum.Material.Neon, {
		shape = Enum.PartType.Ball,
		light = { brightness = 2.6, range = 8 },
	})
	makePiece(model, "TendrilLeft", "WedgePart", Vector3.new(0.3, 0.9, 0.3), CFrame.new(-0.35, 0.55, 0) * CFrame.Angles(0, 0, math.rad(14)), COLORS.void, Enum.Material.Neon, { transparency = 0.15 })
	makePiece(model, "TendrilRight", "WedgePart", Vector3.new(0.3, 0.9, 0.3), CFrame.new(0.35, 0.55, 0) * CFrame.Angles(0, 0, math.rad(-14)), COLORS.void, Enum.Material.Neon, { transparency = 0.15 })
	model.PrimaryPart = core
	return model
end

-- +18% damage, -8 max health: a cracked skull with a cinder fissure.
BUILDERS.CinderOath = function()
	local model = newModel("CinderOathRelic")
	local skull = makePiece(model, "Skull", "Part", Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, 0, 0), COLORS.bone, Enum.Material.SmoothPlastic, { shape = Enum.PartType.Ball })
	makePiece(model, "EyeSocketLeft", "Part", Vector3.new(0.22, 0.22, 0.22), skull.CFrame * CFrame.new(-0.22, 0.05, -0.4), COLORS.void, Enum.Material.SmoothPlastic, { shape = Enum.PartType.Ball })
	makePiece(model, "EyeSocketRight", "Part", Vector3.new(0.22, 0.22, 0.22), skull.CFrame * CFrame.new(0.22, 0.05, -0.4), COLORS.void, Enum.Material.SmoothPlastic, { shape = Enum.PartType.Ball })
	makePiece(model, "Fissure", "Part", Vector3.new(0.08, 0.9, 0.08), skull.CFrame * CFrame.new(0.1, 0, -0.3) * CFrame.Angles(0, 0, math.rad(20)), COLORS.cinder, Enum.Material.Neon, {
		light = { brightness = 1.6, range = 5 },
	})
	model.PrimaryPart = skull
	return model
end

-- Fallback for any id without a dedicated builder yet — a plain glowing shard
-- rather than an error, so a new upgrade added later degrades gracefully.
local function buildFallback()
	local model = newModel("RelicPlaceholder")
	local core = makePiece(model, "Core", "Part", Vector3.new(0.6, 0.9, 0.4), CFrame.new(0, 0, 0), COLORS.slate, Enum.Material.Neon)
	model.PrimaryPart = core
	return model
end

function RelicModelFactory.Build(upgradeId)
	local builder = BUILDERS[upgradeId]
	local model = builder and builder() or buildFallback()
	return model
end

return RelicModelFactory
