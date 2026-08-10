local MobModelFactory = {}

local VISUAL_NAME = "EnemyVisual"
local VISUAL_VERSION = 2

local COLORS = {
	void = Color3.fromRGB(38, 32, 50),
	slate = Color3.fromRGB(70, 58, 90),
	ash = Color3.fromRGB(82, 78, 86),
	bone = Color3.fromRGB(245, 231, 209),
	cinder = Color3.fromRGB(221, 44, 83),
	darkCinder = Color3.fromRGB(117, 24, 48),
	tarnishedGold = Color3.fromRGB(126, 88, 44),
	blackflame = Color3.fromRGB(107, 47, 139),
}

local ROOT_SIZES = {
	Bat = Vector3.new(3.2, 1.5, 2.2),
	Ghoul = Vector3.new(4, 5, 4),
	Brute = Vector3.new(7, 7, 7),
	Warden = Vector3.new(10, 13, 8),
}

local DISPLAY_NAMES = {
	Bat = "Night Bat",
	Ghoul = "Ash Ghoul",
	Brute = "Oathless Brute",
	Warden = "The Cinder Warden",
}

local LEGACY_WARDEN_PARTS = {
	Crown = true,
	CrownSpike = true,
	OathEmber = true,
}

local function scaled(root, value)
	return Vector3.new(root.Size.X * value.X, root.Size.Y * value.Y, root.Size.Z * value.Z)
end

local function angles(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

local function makePiece(context, name, className, sizeScale, offsetScale, color, material, options)
	options = options or {}
	local root = context.root
	local piece = Instance.new(className or "Part")
	piece.Name = name
	piece.Size = scaled(root, sizeScale)
	piece.CFrame = root.CFrame
		* CFrame.new(scaled(root, offsetScale))
		* (options.rotation or CFrame.new())
	piece.Color = color
	piece.Material = material
	piece.Transparency = options.transparency or 0
	piece.Anchored = false
	piece.Massless = true
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CastShadow = options.castShadow == true

	if piece:IsA("Part") and options.shape then
		piece.Shape = options.shape
	end

	piece.Parent = context.model

	local weld = Instance.new("WeldConstraint")
	weld.Name = "RootWeld"
	weld.Part0 = root
	weld.Part1 = piece
	weld.Parent = piece

	if options.light then
		local light = Instance.new("PointLight")
		light.Name = "CinderLight"
		light.Color = options.light.color or color
		light.Brightness = options.light.brightness or 1
		light.Range = options.light.range or 12
		light.Shadows = false
		light.Parent = piece
	end

	context.partCount += 1
	return piece
end

local function buildNightBat(context)
	local body = makePiece(
		context,
		"Body",
		"Part",
		Vector3.new(0.24, 0.46, 0.58),
		Vector3.new(0, 0, 0),
		COLORS.void,
		Enum.Material.Slate,
		{ rotation = angles(0, 0, 45) }
	)

	makePiece(
		context,
		"LeftWing",
		"WedgePart",
		Vector3.new(0.65, 0.11, 0.74),
		Vector3.new(-0.32, 0.07, 0.05),
		COLORS.slate,
		Enum.Material.Fabric,
		{ rotation = angles(-5, 14, -10) }
	)
	makePiece(
		context,
		"RightWing",
		"WedgePart",
		Vector3.new(0.65, 0.11, 0.74),
		Vector3.new(0.32, 0.07, 0.05),
		COLORS.slate,
		Enum.Material.Fabric,
		{ rotation = angles(-5, 166, 10) }
	)
	makePiece(
		context,
		"LeftEye",
		"Part",
		Vector3.new(0.045, 0.085, 0.045),
		Vector3.new(-0.065, 0.08, -0.32),
		COLORS.cinder,
		Enum.Material.Neon
	)
	makePiece(
		context,
		"RightEye",
		"Part",
		Vector3.new(0.045, 0.085, 0.045),
		Vector3.new(0.065, 0.08, -0.32),
		COLORS.cinder,
		Enum.Material.Neon
	)

	return body
end

local function buildAshGhoul(context)
	local torso = makePiece(
		context,
		"AshShroud",
		"Part",
		Vector3.new(0.42, 0.68, 0.36),
		Vector3.new(0, 0.02, 0.05),
		COLORS.slate,
		Enum.Material.Fabric,
		{ rotation = angles(-12, 0, 0) }
	)
	makePiece(
		context,
		"BowedHead",
		"WedgePart",
		Vector3.new(0.30, 0.24, 0.28),
		Vector3.new(0, 0.34, -0.18),
		COLORS.ash,
		Enum.Material.Slate,
		{ rotation = angles(-18, 180, 0), castShadow = true }
	)
	makePiece(
		context,
		"LongLeftArm",
		"Part",
		Vector3.new(0.12, 0.62, 0.12),
		Vector3.new(-0.30, -0.04, -0.08),
		COLORS.ash,
		Enum.Material.Slate,
		{ rotation = angles(8, 0, -7) }
	)
	makePiece(
		context,
		"LongRightArm",
		"Part",
		Vector3.new(0.12, 0.66, 0.12),
		Vector3.new(0.30, -0.08, -0.13),
		COLORS.ash,
		Enum.Material.Slate,
		{ rotation = angles(-7, 0, 8) }
	)
	makePiece(
		context,
		"TatteredHem",
		"WedgePart",
		Vector3.new(0.46, 0.34, 0.34),
		Vector3.new(0, -0.34, 0.05),
		COLORS.void,
		Enum.Material.Fabric,
		{ rotation = angles(0, 180, 0) }
	)

	return torso
end

local function buildOathlessBrute(context)
	local torso = makePiece(
		context,
		"BasaltTorso",
		"Part",
		Vector3.new(0.70, 0.66, 0.50),
		Vector3.new(0, -0.02, 0.02),
		COLORS.slate,
		Enum.Material.Slate,
		{ castShadow = true }
	)
	makePiece(
		context,
		"LeftPauldron",
		"WedgePart",
		Vector3.new(0.44, 0.20, 0.42),
		Vector3.new(-0.33, 0.19, 0),
		COLORS.ash,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 16, -7) }
	)
	makePiece(
		context,
		"RightPauldron",
		"WedgePart",
		Vector3.new(0.44, 0.20, 0.42),
		Vector3.new(0.33, 0.19, 0),
		COLORS.ash,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 164, 7) }
	)
	makePiece(
		context,
		"FacelessHelm",
		"Part",
		Vector3.new(0.24, 0.30, 0.24),
		Vector3.new(0, 0.31, -0.18),
		COLORS.void,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(-4, 0, 0) }
	)
	makePiece(
		context,
		"LeftArm",
		"Part",
		Vector3.new(0.18, 0.46, 0.20),
		Vector3.new(-0.35, -0.18, 0),
		COLORS.ash,
		Enum.Material.Slate,
		{ rotation = angles(0, 0, -6) }
	)
	makePiece(
		context,
		"RightArm",
		"Part",
		Vector3.new(0.18, 0.46, 0.20),
		Vector3.new(0.35, -0.18, 0),
		COLORS.ash,
		Enum.Material.Slate,
		{ rotation = angles(0, 0, 6) }
	)
	makePiece(
		context,
		"BrokenOathBrand",
		"Part",
		Vector3.new(0.15, 0.18, 0.03),
		Vector3.new(0, 0.05, -0.27),
		COLORS.cinder,
		Enum.Material.Neon,
		{ rotation = angles(0, 0, 45) }
	)

	return torso
end

local function buildCinderWarden(context)
	local torso = makePiece(
		context,
		"WardenTorso",
		"Part",
		Vector3.new(0.65, 0.62, 0.55),
		Vector3.new(0, 0, 0.04),
		COLORS.slate,
		Enum.Material.Slate,
		{ castShadow = true }
	)
	makePiece(
		context,
		"IronVisage",
		"Part",
		Vector3.new(0.34, 0.30, 0.06),
		Vector3.new(0, 0.28, -0.31),
		COLORS.void,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(-3, 0, 0), castShadow = true }
	)
	makePiece(
		context,
		"CinderEyeSlit",
		"Part",
		Vector3.new(0.20, 0.025, 0.025),
		Vector3.new(0, 0.30, -0.345),
		COLORS.cinder,
		Enum.Material.Neon
	)
	makePiece(
		context,
		"BrokenCrownBand",
		"Part",
		Vector3.new(0.38, 0.08, 0.34),
		Vector3.new(0, 0.51, -0.02),
		COLORS.tarnishedGold,
		Enum.Material.CorrodedMetal,
		{ castShadow = true }
	)

	local crownSpikes = {
		{ -0.15, 0.60, -7 },
		{ -0.075, 0.64, 4 },
		{ 0, 0.68, -2 },
		{ 0.08, 0.62, 6 },
		{ 0.15, 0.58, -5 },
	}
	for index, spike in ipairs(crownSpikes) do
		makePiece(
			context,
			"CrownTine" .. index,
			"WedgePart",
			Vector3.new(0.07, 0.25 - index * 0.008, 0.10),
			Vector3.new(spike[1], spike[2], -0.02),
			COLORS.tarnishedGold,
			Enum.Material.CorrodedMetal,
			{ rotation = angles(0, index % 2 == 0 and 180 or 0, spike[3]), castShadow = true }
		)
	end

	makePiece(
		context,
		"GreatPauldron",
		"WedgePart",
		Vector3.new(0.36, 0.25, 0.50),
		Vector3.new(0.23, 0.22, 0.05),
		COLORS.tarnishedGold,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 162, 8), castShadow = true }
	)
	makePiece(
		context,
		"BrokenPauldron",
		"WedgePart",
		Vector3.new(0.30, 0.18, 0.42),
		Vector3.new(-0.27, 0.18, 0.02),
		COLORS.ash,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 18, -7), castShadow = true }
	)
	makePiece(
		context,
		"ChainedUpperArm",
		"Part",
		Vector3.new(0.18, 0.36, 0.24),
		Vector3.new(0.35, -0.08, 0),
		COLORS.slate,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 0, 5), castShadow = true }
	)
	makePiece(
		context,
		"ChainedForearm",
		"Part",
		Vector3.new(0.20, 0.30, 0.26),
		Vector3.new(0.35, -0.31, -0.02),
		COLORS.ash,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 0, -4), castShadow = true }
	)
	makePiece(
		context,
		"OathGauntlet",
		"Part",
		Vector3.new(0.24, 0.18, 0.32),
		Vector3.new(0.35, -0.40, -0.03),
		COLORS.void,
		Enum.Material.CorrodedMetal,
		{ castShadow = true }
	)
	makePiece(
		context,
		"WitheredArm",
		"Part",
		Vector3.new(0.15, 0.48, 0.16),
		Vector3.new(-0.38, -0.17, -0.01),
		COLORS.slate,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 0, -5), castShadow = true }
	)
	makePiece(
		context,
		"CinderOathBrand",
		"Part",
		Vector3.new(0.18, 0.16, 0.03),
		Vector3.new(0, 0.07, -0.30),
		COLORS.cinder,
		Enum.Material.Neon,
		{
			rotation = angles(0, 0, 45),
			light = { color = COLORS.cinder, brightness = 1.25, range = 16 },
		}
	)
	makePiece(
		context,
		"OathFracture",
		"Part",
		Vector3.new(0.035, 0.24, 0.03),
		Vector3.new(0, -0.12, -0.30),
		COLORS.darkCinder,
		Enum.Material.Neon,
		{ rotation = angles(0, 0, -4) }
	)

	for index, x in ipairs({ -0.20, 0, 0.20 }) do
		makePiece(
			context,
			"TatteredMantle" .. index,
			"WedgePart",
			Vector3.new(0.18, 0.28 + index * 0.015, 0.18),
			Vector3.new(x, -0.33, 0.10 + math.abs(x) * 0.2),
			index == 2 and COLORS.blackflame or COLORS.void,
			Enum.Material.Fabric,
			{ rotation = angles(0, 180, (index - 2) * 4), castShadow = true }
		)
	end

	makePiece(
		context,
		"UpperChainBar",
		"Part",
		Vector3.new(0.08, 0.18, 0.08),
		Vector3.new(0.42, 0.04, -0.04),
		COLORS.tarnishedGold,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 0, 18), castShadow = true }
	)
	makePiece(
		context,
		"LowerChainBar",
		"Part",
		Vector3.new(0.08, 0.18, 0.08),
		Vector3.new(0.42, -0.20, -0.04),
		COLORS.tarnishedGold,
		Enum.Material.CorrodedMetal,
		{ rotation = angles(0, 0, -16), castShadow = true }
	)

	return torso
end

local BUILDERS = {
	Bat = buildNightBat,
	Ghoul = buildAshGhoul,
	Brute = buildOathlessBrute,
	Warden = buildCinderWarden,
}

local function removeLegacyWardenDecoration(root)
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("BasePart") and LEGACY_WARDEN_PARTS[child.Name] then
			child:Destroy()
		end
	end
end

function MobModelFactory.Attach(root, enemyId)
	assert(root and root:IsA("BasePart"), "MobModelFactory.Attach requires a BasePart root")
	local builder = BUILDERS[enemyId]
	assert(builder, "Unknown enemy model id: " .. tostring(enemyId))

	local existing = root:FindFirstChild(VISUAL_NAME)
	if existing
		and existing:IsA("Model")
		and existing:GetAttribute("EnemyId") == enemyId
		and existing:GetAttribute("VisualVersion") == VISUAL_VERSION
	then
		return existing
	elseif existing then
		existing:Destroy()
	end

	if enemyId == "Warden" then
		removeLegacyWardenDecoration(root)
	end

	local visual = Instance.new("Model")
	visual.Name = VISUAL_NAME
	visual:SetAttribute("EnemyId", enemyId)
	visual:SetAttribute("VisualVersion", VISUAL_VERSION)

	local context = {
		root = root,
		model = visual,
		partCount = 0,
	}
	local ok, primaryPart = pcall(builder, context)
	if not ok then
		visual:Destroy()
		error(primaryPart)
	end

	visual.PrimaryPart = primaryPart
	visual:SetAttribute("VisiblePartCount", context.partCount)
	visual.Parent = root

	root.Transparency = 1
	root.CastShadow = false
	root:SetAttribute("EnemyVisualId", enemyId)
	root:SetAttribute("EnemyVisualVersion", VISUAL_VERSION)

	if enemyId == "Warden" then
		task.defer(function()
			if not root.Parent then
				return
			end
			removeLegacyWardenDecoration(root)
			local healthBar = root:FindFirstChild("HealthBar")
			if healthBar and healthBar:IsA("BillboardGui") then
				healthBar.StudsOffset = Vector3.new(0, root.Size.Y * 0.86, 0)
			end
		end)
	end

	return visual
end

function MobModelFactory.CreatePreview(enemyId, parent, cframe)
	assert(BUILDERS[enemyId], "Unknown enemy model id: " .. tostring(enemyId))
	local preview = Instance.new("Model")
	preview.Name = DISPLAY_NAMES[enemyId]
	preview:SetAttribute("EnemyId", enemyId)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = ROOT_SIZES[enemyId]
	root.CFrame = cframe or CFrame.new(0, root.Size.Y * 0.5, 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CastShadow = false
	root.Parent = preview
	preview.PrimaryPart = root

	MobModelFactory.Attach(root, enemyId)
	preview.Parent = parent
	return preview
end

function MobModelFactory.CreatePreviewSet(parent, origin)
	local previewFolder = Instance.new("Folder")
	previewFolder.Name = "AshenVigilMobPreview"
	local base = origin or CFrame.new()
	local placements = {
		{ "Bat", -19 },
		{ "Ghoul", -12 },
		{ "Brute", -3 },
		{ "Warden", 10 },
	}

	for _, placement in ipairs(placements) do
		local enemyId = placement[1]
		local size = ROOT_SIZES[enemyId]
		MobModelFactory.CreatePreview(
			enemyId,
			previewFolder,
			base * CFrame.new(placement[2], size.Y * 0.5, 0)
		)
	end

	previewFolder.Parent = parent
	return previewFolder
end

function MobModelFactory.GetVisiblePartBudgets()
	return {
		Bat = 5,
		Ghoul = 5,
		Brute = 7,
		Warden = 22,
	}
end

return MobModelFactory
