-- Builds the shared safe hub players spawn into and return to between runs:
-- a small haunted town square, offset well clear of the Vigil arena so the
-- two spaces never overlap. Placeholder decor/NPCs only, meant to be
-- fleshed out later.
--
-- IMPORTANT: this module deliberately never touches Lighting/Atmosphere.
-- Roblox has exactly one global Lighting service for the whole place, not
-- one per area, and ArenaBuilder already sets its mood (Brightness/Ambient/
-- Fog) once at server start. If this module also wrote to those properties,
-- whichever builder ran last would silently win and override the other's
-- atmosphere everywhere, not just its own area. Instead, "more lit than the
-- Vigil" is achieved the same way the Vigil's own torches/braziers already
-- locally brighten a dim shared ambient: strong local PointLights.

-- Moved further out (was 700) now that both the Vigil and Lobby are bigger
-- and each has its own surrounding forest ring -- keeps a comfortable
-- buffer so the two rings can't visually collide.
local LOBBY_CENTER = Vector3.new(1400, 0, 0)
local LOBBY_SIZE = 200

local WorldScenery = require(script.Parent:WaitForChild("WorldScenery"))

local LobbyBuilder = {}

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

local function makeLampPost(position, parent)
	local pole = makePart(
		"LampPost",
		Vector3.new(0.6, 12, 0.6),
		CFrame.new(position + Vector3.new(0, 6, 0)),
		Color3.fromRGB(35, 33, 38),
		Enum.Material.Metal,
		parent
	)
	pole.CanCollide = false

	local lantern = makePart(
		"LampLantern",
		Vector3.new(1.4, 1.4, 1.4),
		pole.CFrame * CFrame.new(0, pole.Size.Y * 0.5 + 0.3, 0),
		Color3.fromRGB(255, 214, 140),
		Enum.Material.Neon,
		parent
	)
	lantern.Shape = Enum.PartType.Ball
	lantern.CanCollide = false

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 214, 140)
	-- Meaningfully brighter/further-reaching than the Vigil's torches
	-- (Brightness 1.9 / Range 22-30) so the town square reads as safe and
	-- well-lit purely through local light, without touching global Lighting.
	light.Brightness = 3.6
	light.Range = 40
	light.Shadows = false
	light.Parent = lantern
end

-- Simple leaning facade suggesting an old, slightly decrepit building front.
-- Placeholder massing only — not a real building interior. Roof is a peaked
-- gable (two angled slabs meeting at a ridge) rather than a flat cap, sits
-- on a foundation step instead of appearing to float on the ground plane,
-- and gets a weathering streak + nudged window placement so buildings don't
-- all read as identical boxes -- particularly noticeable from directly
-- above, where a flat roof cap is the only thing visible.
local function makeBuildingFacade(position, facingAngle, width, height, color, parent)
	local rng = Random.new()
	local lean = math.rad(2.5)
	local facade = makePart(
		"BuildingFacade",
		Vector3.new(width, height, 2),
		CFrame.new(position + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, facingAngle, 0) * CFrame.Angles(lean, 0, 0),
		color,
		Enum.Material.Concrete,
		parent
	)

	local foundation = makePart(
		"FacadeFoundation",
		Vector3.new(width + 1.2, 0.6, 2.8),
		facade.CFrame * CFrame.new(0, -height * 0.5 - 0.3, 0),
		Color3.fromRGB(34, 30, 30),
		Enum.Material.Slate,
		parent
	)
	foundation.CanCollide = false

	-- Two slabs sloping down from a center ridge (classic lean-to-gable
	-- massing) instead of one flat cap.
	local roofPitch = math.rad(rng:NextNumber(22, 34))
	local roofRun = width * 0.5 + 0.5
	local roofSlabLength = roofRun / math.cos(roofPitch)
	local ridgeCFrame = facade.CFrame * CFrame.new(0, height * 0.5, 0)
	for _, side in ipairs({ -1, 1 }) do
		local slab = makePart(
			"FacadeRoofSlab",
			Vector3.new(roofSlabLength, 0.5, 2.8),
			ridgeCFrame
				* CFrame.new(side * roofRun * 0.5, roofRun * 0.5 * math.tan(roofPitch), 0)
				* CFrame.Angles(0, 0, -side * roofPitch),
			Color3.fromRGB(40, 35, 39),
			Enum.Material.Slate,
			parent
		)
		slab.CanCollide = false
	end

	-- A single warm window glow per facade, another small local light source.
	-- Size/height nudged per building rather than identical every time.
	local window = makePart(
		"FacadeWindow",
		Vector3.new(width * 0.25, height * rng:NextNumber(0.25, 0.35), 0.2),
		facade.CFrame * CFrame.new(0, height * rng:NextNumber(0.05, 0.2), -1.05),
		Color3.fromRGB(255, 196, 120),
		Enum.Material.Neon,
		parent
	)
	window.CanCollide = false
	local windowLight = Instance.new("PointLight")
	windowLight.Color = Color3.fromRGB(255, 196, 120)
	windowLight.Brightness = 2
	windowLight.Range = 16
	windowLight.Shadows = false
	windowLight.Parent = window

	-- Cheap crack/stain suggestion so the wall isn't a flat uniform color.
	local streak = makePart(
		"FacadeWeathering",
		Vector3.new(rng:NextNumber(0.15, 0.3), height * rng:NextNumber(0.5, 0.85), 0.05),
		facade.CFrame
			* CFrame.new(rng:NextNumber(-width * 0.35, width * 0.35), rng:NextNumber(-height * 0.1, height * 0.15), -1.03)
			* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-6, 6))),
		Color3.fromRGB(0, 0, 0),
		Enum.Material.Concrete,
		parent
	)
	streak.CanCollide = false
	streak.Transparency = 0.4
end

-- Placeholder NPC standee: a crude static figure marking where a real
-- character/quest-giver will eventually stand. Not interactive yet.
local function makePlaceholderNpc(position, facingAngle, parent)
	local root = CFrame.new(position) * CFrame.Angles(0, facingAngle, 0)
	local robe = makePart(
		"PlaceholderNpc",
		Vector3.new(2, 4.4, 1.4),
		root * CFrame.new(0, 2.2, 0),
		Color3.fromRGB(60, 54, 64),
		Enum.Material.Fabric,
		parent
	)
	robe.CanCollide = false
	local head = makePart(
		"PlaceholderNpcHead",
		Vector3.new(1.2, 1.2, 1.2),
		root * CFrame.new(0, 4.6, 0),
		Color3.fromRGB(214, 198, 176),
		Enum.Material.SmoothPlastic,
		parent
	)
	head.Shape = Enum.PartType.Ball
	head.CanCollide = false
end

-- A small kiosk where the ProximityPrompt opens the roll-booth UI
-- (GameServer.server.lua fires OpenRollBooth on Triggered). Returns the
-- prompt so Build() can hand it back like vigilGate.
local function makeRollBooth(position, parent)
	local counter = makePart(
		"RollBoothCounter",
		Vector3.new(6, 3, 3),
		CFrame.new(position + Vector3.new(0, 1.5, 0)),
		Color3.fromRGB(52, 44, 40),
		Enum.Material.WoodPlanks,
		parent
	)

	local banner = makePart(
		"RollBoothBanner",
		Vector3.new(6, 2, 0.2),
		counter.CFrame * CFrame.new(0, 2.6, -1.3),
		Color3.fromRGB(126, 88, 44),
		Enum.Material.Fabric,
		parent
	)
	banner.CanCollide = false

	local sigil = makePart(
		"RollBoothSigil",
		Vector3.new(1, 1, 0.15),
		banner.CFrame * CFrame.new(0, 0, -0.18),
		Color3.fromRGB(246, 190, 77),
		Enum.Material.Neon,
		parent
	)
	sigil.CanCollide = false
	local sigilLight = Instance.new("PointLight")
	sigilLight.Color = Color3.fromRGB(246, 190, 77)
	sigilLight.Brightness = 2.2
	sigilLight.Range = 18
	sigilLight.Shadows = false
	sigilLight.Parent = sigil

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RollBoothPrompt"
	prompt.ActionText = "Browse"
	prompt.ObjectText = "Vigil-Bound"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter

	return prompt
end

function LobbyBuilder.Build()
	local lobby = workspace:FindFirstChild("AshenVigilLobby")
	if lobby then
		lobby:Destroy()
	end
	lobby = Instance.new("Folder")
	lobby.Name = "AshenVigilLobby"
	lobby.Parent = workspace

	local ground = makePart(
		"LobbyGround",
		Vector3.new(LOBBY_SIZE, 1, LOBBY_SIZE),
		CFrame.new(LOBBY_CENTER - Vector3.new(0, 0.5, 0)),
		Color3.fromRGB(58, 54, 52),
		Enum.Material.Cobblestone,
		lobby
	)
	ground.Locked = true

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(10, 0.5, 10)
	spawnLocation.CFrame = CFrame.new(LOBBY_CENTER + Vector3.new(0, 0.25, 38))
	spawnLocation.Color = Color3.fromRGB(126, 32, 55)
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Transparency = 0.35
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true
	spawnLocation.Neutral = true
	spawnLocation.Duration = 2
	spawnLocation.Parent = lobby

	-- A loose ring of leaning facades around the square.
	local facadeColors = {
		Color3.fromRGB(64, 56, 52),
		Color3.fromRGB(70, 60, 58),
		Color3.fromRGB(58, 52, 50),
	}
	local facadePositions = {
		{ offset = Vector3.new(-76, 0, -58), angle = math.rad(20) },
		{ offset = Vector3.new(-19, 0, -84), angle = math.rad(0) },
		{ offset = Vector3.new(57, 0, -65), angle = math.rad(-25) },
		{ offset = Vector3.new(80, 0, 12), angle = math.rad(-90) },
		{ offset = Vector3.new(-80, 0, 19), angle = math.rad(90) },
		{ offset = Vector3.new(-45, 0, -80), angle = math.rad(10) },
		{ offset = Vector3.new(45, 0, -78), angle = math.rad(-10) },
		{ offset = Vector3.new(80, 0, -40), angle = math.rad(-70) },
		{ offset = Vector3.new(-80, 0, -35), angle = math.rad(70) },
	}
	for index, info in ipairs(facadePositions) do
		makeBuildingFacade(
			LOBBY_CENTER + info.offset,
			info.angle,
			10 + (index % 3) * 2,
			14,
			facadeColors[(index - 1) % #facadeColors + 1],
			lobby
		)
	end

	-- Lamp posts spread through the square for even, bright local coverage.
	local lampOffsets = {
		Vector3.new(-34, 0, -15),
		Vector3.new(34, 0, -15),
		Vector3.new(-34, 0, 22),
		Vector3.new(34, 0, 22),
		Vector3.new(0, 0, -38),
		Vector3.new(-34, 0, 48),
		Vector3.new(34, 0, 48),
		Vector3.new(0, 0, 15),
		Vector3.new(0, 0, 55),
	}
	for _, offset in ipairs(lampOffsets) do
		makeLampPost(LOBBY_CENTER + offset, lobby)
	end

	-- Two placeholder NPC standees flanking the path toward the Vigil gate.
	makePlaceholderNpc(LOBBY_CENTER + Vector3.new(-11, 0, -64), math.rad(15), lobby)
	makePlaceholderNpc(LOBBY_CENTER + Vector3.new(13, 0, -64), math.rad(-15), lobby)

	-- Roll booth, off to one side near spawn so it doesn't block the path to
	-- the Vigil gate.
	local rollBooth = makeRollBooth(LOBBY_CENTER + Vector3.new(-53, 0, 34), lobby)

	-- Gate to the Vigil: two pillars, a lintel, and the entry prompt.
	local gateCenter = LOBBY_CENTER + Vector3.new(0, 0, -90)
	local pillarColor = Color3.fromRGB(50, 44, 48)
	makePart("VigilGatePillar", Vector3.new(2, 12, 2), CFrame.new(gateCenter + Vector3.new(-5, 6, 0)), pillarColor, Enum.Material.Basalt, lobby)
	makePart("VigilGatePillar", Vector3.new(2, 12, 2), CFrame.new(gateCenter + Vector3.new(5, 6, 0)), pillarColor, Enum.Material.Basalt, lobby)
	makePart("VigilGateLintel", Vector3.new(12, 2, 2), CFrame.new(gateCenter + Vector3.new(0, 12, 0)), pillarColor, Enum.Material.Basalt, lobby)

	local gateSigil = makePart(
		"VigilGateSigil",
		Vector3.new(0.3, 3, 3),
		CFrame.new(gateCenter + Vector3.new(0, 6, 0)),
		Color3.fromRGB(211, 45, 87),
		Enum.Material.Neon,
		lobby
	)
	gateSigil.CanCollide = false
	local gateLight = Instance.new("PointLight")
	gateLight.Color = Color3.fromRGB(211, 45, 87)
	gateLight.Brightness = 2.4
	gateLight.Range = 24
	gateLight.Shadows = false
	gateLight.Parent = gateSigil

	local gateTrigger = makePart(
		"VigilGateTrigger",
		Vector3.new(8, 8, 2),
		CFrame.new(gateCenter + Vector3.new(0, 4, 0)),
		Color3.fromRGB(0, 0, 0),
		Enum.Material.SmoothPlastic,
		lobby
	)
	gateTrigger.Transparency = 1
	gateTrigger.CanCollide = false

	local vigilGate = Instance.new("ProximityPrompt")
	vigilGate.Name = "EnterVigilPrompt"
	vigilGate.ActionText = "Enter"
	vigilGate.ObjectText = "The Vigil"
	vigilGate.HoldDuration = 0.5
	vigilGate.MaxActivationDistance = 10
	vigilGate.RequiresLineOfSight = false
	vigilGate.Parent = gateTrigger

	-- Surrounding forest ring just past the town square, and a distant
	-- castle silhouette toward the Vigil gate -- so the far end of town
	-- fades into wilderness instead of bare baseplate, and reads as "that's
	-- where the vigil waits" rather than a random background prop.
	WorldScenery.BuildForestRing(LOBBY_CENTER, LOBBY_SIZE * 0.5 + 10, 80, 150, lobby)
	WorldScenery.BuildCastleSilhouette(LOBBY_CENTER + Vector3.new(0, 0, -260), lobby)

	return {
		lobby = lobby,
		spawnCFrame = spawnLocation.CFrame,
		vigilGate = vigilGate,
		rollBooth = rollBooth,
	}
end

return LobbyBuilder
