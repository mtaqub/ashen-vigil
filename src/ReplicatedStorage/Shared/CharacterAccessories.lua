-- Small procedural Part accessories that make each Config.Characters skin
-- visually distinct beyond BodyColors alone -- same technique as
-- MobModelFactory (enemies) and RelicModelFactory (relic icons): plain
-- Parts, no catalog/uploaded assets needed. Lives in ReplicatedStorage
-- (not ServerScriptService, where MobModelFactory lives) specifically so
-- both the server (live characters) and client (roll-booth preview models)
-- can call it -- a LocalScript can't require anything under
-- ServerScriptService.
--
-- Unlike MobModelFactory's anchored, manually-CFrame'd enemy parts, player
-- characters are physically simulated, so these pieces are unanchored and
-- follow via WeldConstraint to HumanoidRootPart/Head -- the two parts that
-- exist on every rig regardless of R6/R15, so this works without needing to
-- know the character's exact rig type.
local CharacterAccessories = {}

local function makePiece(name, size, cframe, color, material, anchorPart, parent, options)
	options = options or {}
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = color
	piece.Material = material
	piece.Anchored = false
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.Massless = true
	piece.CastShadow = false
	if options.shape then
		piece.Shape = options.shape
	end
	if options.transparency then
		piece.Transparency = options.transparency
	end
	piece.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchorPart
	weld.Part1 = piece
	weld.Parent = piece

	if options.light then
		local light = Instance.new("PointLight")
		light.Color = options.light.color or color
		light.Brightness = options.light.brightness or 2
		light.Range = options.light.range or 8
		light.Shadows = false
		light.Parent = piece
	end
	return piece
end

local BUILDERS = {}

-- Common -- a small dark shoulder mantle, matching the reference art's
-- tattered cloak silhouette.
BUILDERS.Default = function(root, head, folder)
	makePiece(
		"MantleLeft", Vector3.new(0.9, 0.35, 0.9),
		root.CFrame * CFrame.new(-0.85, 1.3, 0.15) * CFrame.Angles(math.rad(10), 0, math.rad(-8)),
		Color3.fromRGB(28, 24, 34), Enum.Material.Fabric, root, folder
	)
	makePiece(
		"MantleRight", Vector3.new(0.9, 0.35, 0.9),
		root.CFrame * CFrame.new(0.85, 1.3, 0.15) * CFrame.Angles(math.rad(10), 0, math.rad(8)),
		Color3.fromRGB(28, 24, 34), Enum.Material.Fabric, root, folder
	)
end

-- Uncommon -- a pale wisp trailing above the head, like a soul worn loose.
BUILDERS.Hollowed = function(root, head, folder)
	makePiece(
		"Wisp", Vector3.new(0.55, 0.7, 0.55),
		head.CFrame * CFrame.new(0, 1.05, 0.15),
		Color3.fromRGB(235, 235, 240), Enum.Material.Neon, head, folder,
		{
			shape = Enum.PartType.Ball,
			transparency = 0.4,
			light = { brightness = 1.6, range = 8, color = Color3.fromRGB(226, 230, 235) },
		}
	)
end

-- Rare -- glowing ember cracks across the chest.
BUILDERS.Cinderbound = function(root, head, folder)
	makePiece(
		"EmberCrackLeft", Vector3.new(0.12, 0.7, 0.08),
		root.CFrame * CFrame.new(-0.35, 0.9, -0.55) * CFrame.Angles(0, 0, math.rad(14)),
		Color3.fromRGB(221, 44, 83), Enum.Material.Neon, root, folder,
		{ light = { brightness = 1.8, range = 7, color = Color3.fromRGB(221, 44, 83) } }
	)
	makePiece(
		"EmberCrackRight", Vector3.new(0.12, 0.55, 0.08),
		root.CFrame * CFrame.new(0.3, 0.7, -0.55) * CFrame.Angles(0, 0, math.rad(-10)),
		Color3.fromRGB(221, 44, 83), Enum.Material.Neon, root, folder
	)
end

-- Epic -- dark blackflame-purple smoke wisps rising from the shoulders.
BUILDERS.Nightbound = function(root, head, folder)
	makePiece(
		"SmokeLeft", Vector3.new(0.5, 1.3, 0.5),
		root.CFrame * CFrame.new(-0.8, 1.6, 0.1) * CFrame.Angles(math.rad(-14), 0, math.rad(-10)),
		Color3.fromRGB(60, 32, 80), Enum.Material.Neon, root, folder,
		{ transparency = 0.25, light = { brightness = 1.6, range = 9, color = Color3.fromRGB(107, 47, 139) } }
	)
	makePiece(
		"SmokeRight", Vector3.new(0.5, 1.3, 0.5),
		root.CFrame * CFrame.new(0.8, 1.6, 0.1) * CFrame.Angles(math.rad(-14), 0, math.rad(10)),
		Color3.fromRGB(60, 32, 80), Enum.Material.Neon, root, folder,
		{ transparency = 0.25 }
	)
end

-- Legendary -- gold pauldrons and a chest sigil, the most adorned of the five.
BUILDERS.Oathsworn = function(root, head, folder)
	makePiece(
		"PauldronLeft", Vector3.new(0.85, 0.55, 0.85),
		root.CFrame * CFrame.new(-0.9, 1.35, 0),
		Color3.fromRGB(126, 88, 44), Enum.Material.CorrodedMetal, root, folder
	)
	makePiece(
		"PauldronRight", Vector3.new(0.85, 0.55, 0.85),
		root.CFrame * CFrame.new(0.9, 1.35, 0),
		Color3.fromRGB(126, 88, 44), Enum.Material.CorrodedMetal, root, folder
	)
	makePiece(
		"Sigil", Vector3.new(0.5, 0.5, 0.1),
		root.CFrame * CFrame.new(0, 0.85, -0.58),
		Color3.fromRGB(246, 190, 77), Enum.Material.Neon, root, folder,
		{ light = { brightness = 2, range = 8, color = Color3.fromRGB(246, 190, 77) } }
	)
end

-- Call after the character's HumanoidDescription has been applied (visuals
-- read correctly regardless of order, but this is the natural sequence).
-- Idempotent: clears any previously-attached set first, so it's safe to
-- call again on a still-live character after a re-roll.
function CharacterAccessories.Attach(character, skinId)
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not root or not head then
		return
	end

	local existing = character:FindFirstChild("SkinAccessories")
	if existing then
		existing:Destroy()
	end

	local builder = BUILDERS[skinId]
	if not builder then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "SkinAccessories"
	folder.Parent = character
	builder(root, head, folder)
end

return CharacterAccessories
