local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local WorldScenery = require(script.Parent:WaitForChild("WorldScenery"))

local ArenaBuilder = {}

local function assetUri(assetId)
	local numericId = tonumber(assetId)
	if not numericId or numericId <= 0 then
		return nil
	end
	return "rbxassetid://" .. tostring(math.floor(numericId))
end

local function makePart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Builds (or rebuilds) the AshenVigilArena world: floor, walls, torches,
-- runestones, graves, ruined arches, shrine, lighting/atmosphere, and ambient
-- sound. Destroys any existing AshenVigilArena folder first, so re-running
-- this leaves a single clean instance. Returns the world folders gameplay
-- code needs to parent enemies/gems/effects into.
function ArenaBuilder.Build()
	local arena = workspace:FindFirstChild("AshenVigilArena")
	if arena then
		arena:Destroy()
	end
	arena = Instance.new("Folder")
	arena.Name = "AshenVigilArena"
	arena.Parent = workspace

	local floor = makePart(
		"ObsidianFloor",
		Vector3.new(Config.ARENA_SIZE, 1, Config.ARENA_SIZE),
		CFrame.new(0, -0.5, 0),
		Color3.fromRGB(18, 18, 27),
		Enum.Material.Slate,
		arena
	)
	floor.Locked = true
	if type(Config.FLOOR_MATERIAL_VARIANT) == "string" and Config.FLOOR_MATERIAL_VARIANT ~= "" then
		floor.MaterialVariant = Config.FLOOR_MATERIAL_VARIANT
	end
	local floorTextureId = assetUri(Config.AssetIds.Images.CrackedBasaltFloor)
	if floorTextureId then
		local floorTexture = Instance.new("Texture")
		floorTexture.Name = "CrackedBasalt"
		floorTexture.Texture = floorTextureId
		floorTexture.Face = Enum.NormalId.Top
		floorTexture.StudsPerTileU = 28
		floorTexture.StudsPerTileV = 28
		floorTexture.Color3 = Color3.fromRGB(96, 91, 106)
		floorTexture.Parent = floor
	end

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "SurvivorSpawn"
	spawnLocation.Size = Vector3.new(10, 0.5, 10)
	spawnLocation.CFrame = CFrame.new(0, 0.25, 0)
	spawnLocation.Color = Color3.fromRGB(126, 32, 55)
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Transparency = 0.35
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true
	spawnLocation.Neutral = true
	spawnLocation.Duration = 2
	spawnLocation.Parent = arena

	local halfArena = Config.ARENA_SIZE * 0.5
	local wallHeight = 26
	local walls = {
		{ size = Vector3.new(Config.ARENA_SIZE, wallHeight, 3), position = Vector3.new(0, wallHeight * 0.5, -halfArena) },
		{ size = Vector3.new(Config.ARENA_SIZE, wallHeight, 3), position = Vector3.new(0, wallHeight * 0.5, halfArena) },
		{ size = Vector3.new(3, wallHeight, Config.ARENA_SIZE), position = Vector3.new(-halfArena, wallHeight * 0.5, 0) },
		{ size = Vector3.new(3, wallHeight, Config.ARENA_SIZE), position = Vector3.new(halfArena, wallHeight * 0.5, 0) },
	}
	for index, wallInfo in ipairs(walls) do
		local wall = makePart(
			"Boundary" .. index,
			wallInfo.size,
			CFrame.new(wallInfo.position),
			Color3.fromRGB(68, 34, 66),
			Enum.Material.ForceField,
			arena
		)
		wall.Transparency = 0.72
	end

	-- Wall-mounted torches: broad, even light coverage across the full arena so
	-- players far from the central runestone ring can still see enemies clearly.
	local wallTorchColor = Color3.fromRGB(226, 133, 64)
	local torchesPerWall = 4
	for _, wallInfo in ipairs(walls) do
		local runsAlongX = wallInfo.size.X > wallInfo.size.Z
		local inward = (wallInfo.position.X > 0 or wallInfo.position.Z > 0) and -3 or 3
		for step = 1, torchesPerWall do
			local t = ((step - 0.5) / torchesPerWall - 0.5) * (Config.ARENA_SIZE * 0.85)
			local torchPosition = runsAlongX
				and Vector3.new(wallInfo.position.X + t, 9, wallInfo.position.Z + inward)
				or Vector3.new(wallInfo.position.X + inward, 9, wallInfo.position.Z + t)

			local torchArm = makePart(
				"WallTorchArm",
				Vector3.new(0.35, 0.35, 1.1),
				CFrame.new(torchPosition),
				Color3.fromRGB(60, 52, 46),
				Enum.Material.CorrodedMetal,
				arena
			)
			torchArm.CanCollide = false
			local torchFlame = makePart(
				"WallTorchFlame",
				Vector3.new(0.6, 0.85, 0.6),
				torchArm.CFrame * CFrame.new(0, 0.5, 0),
				wallTorchColor,
				Enum.Material.Neon,
				arena
			)
			torchFlame.Shape = Enum.PartType.Ball
			torchFlame.CanCollide = false
			local torchLight = Instance.new("PointLight")
			torchLight.Color = wallTorchColor
			torchLight.Brightness = 1.9
			torchLight.Range = 30
			torchLight.Shadows = false
			torchLight.Parent = torchFlame
		end
	end

	for index = 1, 16 do
		local angle = (index / 16) * math.pi * 2
		local radius = 90
		local position = Vector3.new(math.cos(angle) * radius, 5, math.sin(angle) * radius)
		local pillar = makePart(
			"Runestone",
			Vector3.new(3, 10 + (index % 3) * 2, 3),
			CFrame.new(position) * CFrame.Angles(0, -angle, math.rad(index % 2 == 0 and 4 or -4)),
			Color3.fromRGB(41, 35, 57),
			Enum.Material.Basalt,
			arena
		)
		pillar.CanCollide = false
		local rune = makePart(
			"Rune",
			Vector3.new(0.25, 3, 1.3),
			pillar.CFrame * CFrame.new(0, 0, -1.57),
			Color3.fromRGB(211, 45, 87),
			Enum.Material.Neon,
			arena
		)
		rune.CanCollide = false

		local brazierColor = index % 2 == 0 and Color3.fromRGB(235, 142, 60) or Color3.fromRGB(160, 98, 216)
		local brazierBowl = makePart(
			"BrazierBowl",
			Vector3.new(1.5, 0.7, 1.5),
			pillar.CFrame * CFrame.new(0, pillar.Size.Y * 0.5 + 0.4, 0),
			Color3.fromRGB(70, 60, 52),
			Enum.Material.CorrodedMetal,
			arena
		)
		brazierBowl.CanCollide = false
		local brazierFlame = makePart(
			"BrazierFlame",
			Vector3.new(0.85, 1.05, 0.85),
			brazierBowl.CFrame * CFrame.new(0, brazierBowl.Size.Y * 0.5 + 0.3, 0),
			brazierColor,
			Enum.Material.Neon,
			arena
		)
		brazierFlame.Shape = Enum.PartType.Ball
		brazierFlame.CanCollide = false
		local brazierLight = Instance.new("PointLight")
		brazierLight.Color = brazierColor
		brazierLight.Brightness = 1.9
		brazierLight.Range = 22
		brazierLight.Shadows = false
		brazierLight.Parent = brazierFlame
	end

	for index = 1, 24 do
		local angle = (index / 24) * math.pi * 2
		local position = Vector3.new(math.cos(angle) * 24, 0.18, math.sin(angle) * 24)
		local graveMark = makePart(
			"GraveMark",
			Vector3.new(4.6, 0.35, 1.1),
			CFrame.new(position) * CFrame.Angles(0, -angle, 0),
			index % 4 == 0 and Color3.fromRGB(128, 82, 48) or Color3.fromRGB(53, 48, 61),
			index % 4 == 0 and Enum.Material.Neon or Enum.Material.Cobblestone,
			arena
		)
		graveMark.CanCollide = false
	end

	for index = 1, 4 do
		local angle = (index / 4) * math.pi * 2 + math.pi * 0.25
		local position = Vector3.new(math.cos(angle) * 145, 9, math.sin(angle) * 145)
		local archLeft = makePart(
			"RuinedArch",
			Vector3.new(5, 18, 5),
			CFrame.new(position + Vector3.new(math.sin(angle) * 8, 0, -math.cos(angle) * 8)) * CFrame.Angles(0, -angle, math.rad(-4)),
			Color3.fromRGB(44, 41, 49),
			Enum.Material.Cobblestone,
			arena
		)
		local archRight = makePart(
			"RuinedArch",
			Vector3.new(5, 14, 5),
			CFrame.new(position - Vector3.new(math.sin(angle) * 8, 2, -math.cos(angle) * 8)) * CFrame.Angles(0, -angle, math.rad(7)),
			Color3.fromRGB(44, 41, 49),
			Enum.Material.Cobblestone,
			arena
		)
		archLeft.CanCollide = false
		archRight.CanCollide = false
	end

	local shrinePlinth = makePart(
		"VigilShrinePlinth",
		Vector3.new(4.2, 1.1, 2.6),
		CFrame.new(0, 0.55, 14),
		Color3.fromRGB(46, 40, 55),
		Enum.Material.Basalt,
		arena
	)
	shrinePlinth.CanCollide = false
	local shrineSigil = makePart(
		"VigilShrineSigil",
		Vector3.new(1.6, 2.2, 0.2),
		shrinePlinth.CFrame * CFrame.new(0, shrinePlinth.Size.Y * 0.5 + 1.1, 0),
		Color3.fromRGB(146, 92, 214),
		Enum.Material.Neon,
		arena
	)
	shrineSigil.CanCollide = false
	local shrineLight = Instance.new("PointLight")
	shrineLight.Color = shrineSigil.Color
	shrineLight.Brightness = 2
	shrineLight.Range = 26
	shrineLight.Shadows = false
	shrineLight.Parent = shrineSigil

	Lighting.ClockTime = 0
	Lighting.Brightness = 2.9
	Lighting.Ambient = Color3.fromRGB(80, 72, 102)
	Lighting.OutdoorAmbient = Color3.fromRGB(59, 54, 78)
	Lighting.FogColor = Color3.fromRGB(18, 14, 28)
	Lighting.FogStart = 150
	Lighting.FogEnd = 380

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Color = Color3.fromRGB(105, 86, 138)
	atmosphere.Decay = Color3.fromRGB(62, 32, 48)
	atmosphere.Density = 0.20
	atmosphere.Glare = 0
	atmosphere.Haze = 1.25
	atmosphere.Parent = Lighting

	local ambientSoundId = assetUri(Config.AssetIds.Audio.AmbientLoop)
	if ambientSoundId then
		local ambient = SoundService:FindFirstChild("AshenVigilAmbient") or Instance.new("Sound")
		ambient.Name = "AshenVigilAmbient"
		ambient.SoundId = ambientSoundId
		ambient.Volume = 0.32
		ambient.Looped = true
		ambient.Parent = SoundService
		ambient:Play()
	end

	local enemiesFolder = Instance.new("Folder")
	enemiesFolder.Name = "Enemies"
	enemiesFolder.Parent = arena

	local gemsFolder = Instance.new("Folder")
	gemsFolder.Name = "Experience"
	gemsFolder.Parent = arena

	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "Effects"
	effectsFolder.Parent = arena

	return {
		arena = arena,
		enemiesFolder = enemiesFolder,
		gemsFolder = gemsFolder,
		effectsFolder = effectsFolder,
	}
end

return ArenaBuilder
