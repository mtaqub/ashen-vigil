-- Shared procedural scenery for both ArenaBuilder and LobbyBuilder: a
-- surrounding forest ring (so reaching a boundary reveals wilderness
-- instead of bare baseplate) and a distant castle silhouette matching the
-- reference key-art's skyline. Same Part-only technique used throughout
-- this project -- no uploaded assets needed. Lives here (not duplicated in
-- each builder) since both callers are server-side, unlike the
-- RelicModelFactory/CharacterAccessories split which was forced into
-- ReplicatedStorage by a client caller.
local WorldScenery = {}

local function makePart(name, size, cframe, color, material, parent, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide == nil or canCollide
	part.CanQuery = false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local TREE_COLOR = Color3.fromRGB(20, 18, 24)
local BRANCH_COLOR = Color3.fromRGB(16, 14, 20)
local CROWN_COLOR = Color3.fromRGB(13, 12, 17)
local SCRUB_COLOR = Color3.fromRGB(24, 21, 18)

local function buildTree(position, random, parent)
	local height = random:NextNumber(14, 26)
	local lean = math.rad(random:NextNumber(-4, 4))
	local facing = random:NextNumber(0, math.pi * 2)
	local trunk = makePart(
		"DeadTree",
		Vector3.new(random:NextNumber(0.9, 1.6), height, random:NextNumber(0.9, 1.6)),
		CFrame.new(position + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(lean, facing, 0),
		TREE_COLOR,
		Enum.Material.Slate,
		parent
	)

	local branchCount = random:NextInteger(3, 6)
	for _ = 1, branchCount do
		local branchAngle = random:NextNumber(0, math.pi * 2)
		local branchTilt = math.rad(random:NextNumber(30, 70))
		local branchHeight = random:NextNumber(0.4, 0.95) * height
		makePart(
			"Branch",
			Vector3.new(0.35, random:NextNumber(3, 7), 0.35),
			trunk.CFrame * CFrame.new(0, branchHeight - height * 0.5, 0) * CFrame.Angles(branchTilt, branchAngle, 0),
			BRANCH_COLOR,
			Enum.Material.Slate,
			parent,
			false
		)
	end

	-- A tangled mass of short flat shards clustered at the crown, so each
	-- tree reads as a silhouette with real volume from a distance or from
	-- above -- previously just bare sticks with gaps of empty sky between
	-- them. Deliberately irregular/gnarled rather than a rounded canopy, to
	-- keep the "dead and twisted" read rather than looking like a healthy
	-- tree.
	local crownPosition = trunk.Position + Vector3.new(0, height * 0.42, 0)
	local shardCount = random:NextInteger(5, 9)
	for _ = 1, shardCount do
		local shardAngle = random:NextNumber(0, math.pi * 2)
		local shardTilt = math.rad(random:NextNumber(0, 80))
		local shardOffset = random:NextNumber(0, height * 0.22)
		makePart(
			"CrownShard",
			Vector3.new(random:NextNumber(1.4, 3), 0.25, random:NextNumber(1.4, 3)),
			CFrame.new(crownPosition)
				* CFrame.Angles(0, shardAngle, 0)
				* CFrame.new(shardOffset, 0, 0)
				* CFrame.Angles(shardTilt, random:NextNumber(0, math.pi * 2), 0),
			CROWN_COLOR,
			Enum.Material.Slate,
			parent,
			false
		)
	end
end

-- A small cluster of low, irregular dead-scrub/rubble parts -- fills the
-- gap between open ground and the tree line so the boundary reads as a
-- natural transition rather than flat ground meeting bare trunks with
-- nothing between them.
local function buildScrub(position, random, parent)
	local clusterSize = random:NextInteger(2, 4)
	for _ = 1, clusterSize do
		local angle = random:NextNumber(0, math.pi * 2)
		local reach = random:NextNumber(0, 1.6)
		local height = random:NextNumber(0.6, 1.6)
		makePart(
			"DeadScrub",
			Vector3.new(random:NextNumber(0.6, 1.4), height, random:NextNumber(0.6, 1.4)),
			CFrame.new(position + Vector3.new(math.cos(angle) * reach, height * 0.5, math.sin(angle) * reach))
				* CFrame.Angles(
					math.rad(random:NextNumber(-25, 25)),
					random:NextNumber(0, math.pi * 2),
					math.rad(random:NextNumber(-25, 25))
				),
			SCRUB_COLOR,
			Enum.Material.Rock,
			parent,
			false
		)
	end
end

-- Scatters dead/twisted trees in an annulus from innerRadius to
-- innerRadius+depth around center, so reaching a boundary reveals a forest
-- rather than a hard edge into void. Trunks are collidable (a soft natural
-- barrier, redundant with whatever real boundary wall already exists, not
-- relied on for containment); branches aren't, so they don't snag movement.
function WorldScenery.BuildForestRing(center, innerRadius, depth, treeCount, parent, random)
	random = random or Random.new()

	-- Neither caller's own floor extends this far out (the arena/Lobby floor
	-- stops at innerRadius, the forest ring starts there) -- without this,
	-- every tree/scrub cluster sits over whatever pre-existing baseplate is
	-- underneath rather than any ground this game actually built, which can
	-- look deceptively fine under warm scene lighting until you look closely.
	-- One big square (not a true ring) is a deliberate simplification: it's
	-- fully hidden under the real floor in the covered area, and generous
	-- enough past the tree ring's outer edge that a player navigating within
	-- the (collidable) trees would never reach a corner.
	local outerRadius = innerRadius + depth
	local groundSize = (outerRadius + 30) * 2
	makePart(
		"ForestFloor",
		Vector3.new(groundSize, 2, groundSize),
		CFrame.new(center - Vector3.new(0, 1.1, 0)),
		Color3.fromRGB(26, 23, 20),
		Enum.Material.Ground,
		parent
	)

	for _ = 1, treeCount do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = innerRadius + random:NextNumber(0, depth)
		local position = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		buildTree(position, random, parent)
	end

	-- Scrub clustered toward the inner edge of the ring (biased slightly
	-- inside innerRadius through the first third of depth), scaled off
	-- treeCount so both existing callers benefit without passing a new
	-- parameter.
	local scrubClusters = math.max(6, math.floor(treeCount * 0.25))
	for _ = 1, scrubClusters do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = innerRadius + random:NextNumber(-6, depth * 0.35)
		local position = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		buildScrub(position, random, parent)
	end
end

-- A large, simple non-collidable keep-and-spires silhouette far outside
-- the play area -- unreachable background scenery, not a real building,
-- matching the reference key-art's distant gothic skyline.
function WorldScenery.BuildCastleSilhouette(position, parent)
	local color = Color3.fromRGB(12, 11, 16)
	local keepHeight = 90
	local keep = makePart(
		"CastleKeep",
		Vector3.new(60, keepHeight, 50),
		CFrame.new(position + Vector3.new(0, keepHeight * 0.5, 0)),
		color,
		Enum.Material.Slate,
		parent,
		false
	)

	local spires = {
		{ offset = Vector3.new(-22, 0, -18), height = 60 },
		{ offset = Vector3.new(20, 0, -16), height = 90 },
		{ offset = Vector3.new(0, 0, 22), height = 120 },
		{ offset = Vector3.new(-26, 0, 18), height = 75 },
		{ offset = Vector3.new(26, 0, 20), height = 100 },
	}
	for _, spire in ipairs(spires) do
		makePart(
			"CastleSpire",
			Vector3.new(9, spire.height, 9),
			keep.CFrame * CFrame.new(spire.offset.X, keep.Size.Y * 0.5 + spire.height * 0.5 - 8, spire.offset.Z),
			color,
			Enum.Material.Slate,
			parent,
			false
		)
	end

	local wallHeight = 24
	makePart(
		"CastleWall",
		Vector3.new(140, wallHeight, 6),
		keep.CFrame * CFrame.new(0, -keep.Size.Y * 0.5 + wallHeight * 0.5, -50),
		color,
		Enum.Material.Slate,
		parent,
		false
	)
end

return WorldScenery
