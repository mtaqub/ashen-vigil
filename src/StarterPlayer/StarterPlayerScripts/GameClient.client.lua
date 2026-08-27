local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RelicModelFactory = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RelicModelFactory"))
local CharacterAccessories = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CharacterAccessories"))
local remotes = ReplicatedStorage:WaitForChild("AshenVigilRemotes")
local stateUpdateRemote = remotes:WaitForChild("StateUpdate")
local levelUpRemote = remotes:WaitForChild("LevelUp")
local upgradeChoiceRemote = remotes:WaitForChild("UpgradeChoice")
local announcementRemote = remotes:WaitForChild("Announcement")
local openRollBoothRemote = remotes:WaitForChild("OpenRollBooth")
local rollCharacterRemote = remotes:WaitForChild("RollCharacter")
local reserveCurrentRemote = remotes:WaitForChild("ReserveCurrent")
local swapReservedRemote = remotes:WaitForChild("SwapReserved")

local COLORS = {
	ink = Color3.fromRGB(18, 14, 25),
	panel = Color3.fromRGB(31, 25, 43),
	panelLight = Color3.fromRGB(52, 42, 68),
	cream = Color3.fromRGB(245, 231, 209),
	muted = Color3.fromRGB(174, 157, 182),
	red = Color3.fromRGB(221, 44, 83),
	darkRed = Color3.fromRGB(117, 24, 48),
	gold = Color3.fromRGB(246, 190, 77),
	purple = Color3.fromRGB(131, 83, 210),
}

local function imageUri(assetId)
	local numericId = tonumber(assetId)
	if not numericId or numericId <= 0 then
		return nil
	end
	return "rbxassetid://" .. tostring(math.floor(numericId))
end

local function corner(parent, radius)
	local object = Instance.new("UICorner")
	object.CornerRadius = UDim.new(0, radius)
	object.Parent = parent
	return object
end

local function stroke(parent, color, thickness, transparency)
	local object = Instance.new("UIStroke")
	object.Color = color
	object.Thickness = thickness
	object.Transparency = transparency or 0
	object.Parent = parent
	return object
end

local function textLabel(parent, name, text, size, position, anchor, font, color, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.zero
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.GothamBold
	label.TextColor3 = color or COLORS.cream
	label.TextSize = textSize or 18
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "AshenVigilUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = COLORS.ink
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.ZIndex = 40
vignette.Parent = gui

local timerPanel = Instance.new("Frame")
timerPanel.Name = "TimerPanel"
timerPanel.Size = UDim2.fromOffset(188, 64)
timerPanel.Position = UDim2.fromScale(0.5, 0.03)
timerPanel.AnchorPoint = Vector2.new(0.5, 0)
timerPanel.BackgroundColor3 = COLORS.ink
timerPanel.BackgroundTransparency = 0.12
timerPanel.BorderSizePixel = 0
timerPanel.Parent = gui
corner(timerPanel, 12)
stroke(timerPanel, COLORS.darkRed, 2, 0.15)

local timerLabel = textLabel(
	timerPanel,
	"Timer",
	"00:00",
	UDim2.fromScale(1, 0.64),
	UDim2.fromScale(0.5, 0.05),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBlack,
	COLORS.cream,
	29
)
local threatLabel = textLabel(
	timerPanel,
	"Threat",
	"THE LONG NIGHT",
	UDim2.fromScale(1, 0.3),
	UDim2.fromScale(0.5, 0.66),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBold,
	COLORS.red,
	11
)

local objective = textLabel(
	gui,
	"Objective",
	"ENDURE THE ASHEN VIGIL",
	UDim2.fromOffset(320, 34),
	UDim2.fromScale(0.5, 0.145),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBold,
	COLORS.muted,
	15
)

-- Quest tracker: always visible (not gated on being in the Vigil, since
-- quest progress -- kills, level, boss defeats -- is earned there but the
-- tracker itself is just informational). Rows are rebuilt only when the
-- active quest set actually changes (day/week rollover), not on every
-- state push, to avoid destroy/recreate churn.
local questPanel = Instance.new("Frame")
questPanel.Name = "QuestPanel"
questPanel.Size = UDim2.fromOffset(240, 0)
questPanel.AutomaticSize = Enum.AutomaticSize.Y
questPanel.Position = UDim2.fromOffset(24, 24)
questPanel.BackgroundColor3 = COLORS.ink
questPanel.BackgroundTransparency = 0.18
questPanel.BorderSizePixel = 0
questPanel.Parent = gui
corner(questPanel, 10)
stroke(questPanel, COLORS.panelLight, 1, 0.3)

local questTitle = textLabel(
	questPanel,
	"QuestTitle",
	"VIGIL OATHS",
	UDim2.new(1, -20, 0, 22),
	UDim2.fromOffset(10, 8),
	Vector2.zero,
	Enum.Font.GothamBlack,
	COLORS.gold,
	13
)
questTitle.TextXAlignment = Enum.TextXAlignment.Left

local questList = Instance.new("Frame")
questList.Name = "QuestList"
questList.Size = UDim2.new(1, -20, 0, 0)
questList.AutomaticSize = Enum.AutomaticSize.Y
questList.Position = UDim2.fromOffset(10, 34)
questList.BackgroundTransparency = 1
questList.Parent = questPanel
local questListLayout = Instance.new("UIListLayout")
questListLayout.FillDirection = Enum.FillDirection.Vertical
questListLayout.Padding = UDim.new(0, 6)
questListLayout.Parent = questList
local questBottomPadding = Instance.new("UIPadding")
questBottomPadding.PaddingBottom = UDim.new(0, 12)
questBottomPadding.Parent = questList

local questRows = {}

local function updateQuestPanel(daily, weekly)
	local combined = {}
	for _, entry in ipairs(daily or {}) do
		table.insert(combined, entry)
	end
	for _, entry in ipairs(weekly or {}) do
		table.insert(combined, entry)
	end

	local sameShape = #combined == #questRows
	if sameShape then
		for index, entry in ipairs(combined) do
			if questRows[index].title ~= entry.title then
				sameShape = false
				break
			end
		end
	end

	if not sameShape then
		for _, row in ipairs(questRows) do
			row.frame:Destroy()
		end
		questRows = {}
		for _, entry in ipairs(combined) do
			local row = Instance.new("Frame")
			row.Name = "QuestRow"
			row.Size = UDim2.new(1, 0, 0, 30)
			row.BackgroundTransparency = 1
			row.Parent = questList

			local rowLabel = textLabel(
				row,
				"Title",
				entry.title,
				UDim2.new(1, 0, 0, 16),
				UDim2.fromOffset(0, 0),
				Vector2.zero,
				Enum.Font.GothamBold,
				COLORS.cream,
				12
			)
			rowLabel.TextXAlignment = Enum.TextXAlignment.Left

			local barBack = Instance.new("Frame")
			barBack.Name = "Bar"
			barBack.Size = UDim2.new(1, 0, 0, 8)
			barBack.Position = UDim2.fromOffset(0, 18)
			barBack.BackgroundColor3 = Color3.fromRGB(48, 40, 44)
			barBack.BorderSizePixel = 0
			barBack.ClipsDescendants = true
			barBack.Parent = row
			corner(barBack, 4)

			local barFill = Instance.new("Frame")
			barFill.Name = "Fill"
			barFill.Size = UDim2.fromScale(0, 1)
			barFill.BackgroundColor3 = COLORS.gold
			barFill.BorderSizePixel = 0
			barFill.Parent = barBack
			corner(barFill, 4)

			table.insert(questRows, { frame = row, title = entry.title, label = rowLabel, fill = barFill })
		end
	end

	for index, entry in ipairs(combined) do
		local row = questRows[index]
		if row then
			row.label.Text = string.format("%s  %d/%d", entry.title, entry.progress, entry.target)
			row.label.TextColor3 = entry.complete and COLORS.gold or COLORS.cream
			row.fill.Size = UDim2.fromScale(math.clamp(entry.progress / math.max(entry.target, 1), 0, 1), 1)
			row.fill.BackgroundColor3 = entry.complete and COLORS.gold or COLORS.purple
		end
	end
end

local bossPanel = Instance.new("Frame")
bossPanel.Name = "BossPanel"
bossPanel.Size = UDim2.fromOffset(520, 56)
bossPanel.Position = UDim2.fromScale(0.5, 0.185)
bossPanel.AnchorPoint = Vector2.new(0.5, 0)
bossPanel.BackgroundColor3 = COLORS.ink
bossPanel.BackgroundTransparency = 0.08
bossPanel.BorderSizePixel = 0
bossPanel.Visible = false
bossPanel.Parent = gui
corner(bossPanel, 7)
stroke(bossPanel, Color3.fromRGB(139, 93, 49), 2, 0.1)

local bossName = textLabel(
	bossPanel,
	"BossName",
	"THE CINDER WARDEN",
	UDim2.new(1, -24, 0, 24),
	UDim2.fromOffset(12, 5),
	Vector2.zero,
	Enum.Font.GothamBlack,
	COLORS.gold,
	14
)
bossName.TextXAlignment = Enum.TextXAlignment.Center
bossName.ZIndex = 4

local bossHealthBack = Instance.new("Frame")
bossHealthBack.Name = "BossHealthBack"
bossHealthBack.Size = UDim2.new(1, -26, 0, 14)
bossHealthBack.Position = UDim2.fromOffset(13, 34)
bossHealthBack.BackgroundColor3 = Color3.fromRGB(48, 33, 35)
bossHealthBack.BorderSizePixel = 0
bossHealthBack.ClipsDescendants = true
bossHealthBack.ZIndex = 3
bossHealthBack.Parent = bossPanel
corner(bossHealthBack, 4)

local bossHealthFill = Instance.new("Frame")
bossHealthFill.Name = "BossHealthFill"
bossHealthFill.Size = UDim2.fromScale(1, 1)
bossHealthFill.BackgroundColor3 = Color3.fromRGB(151, 44, 39)
bossHealthFill.BorderSizePixel = 0
bossHealthFill.ZIndex = 4
bossHealthFill.Parent = bossHealthBack
corner(bossHealthFill, 4)
local bossGradient = Instance.new("UIGradient")
bossGradient.Color = ColorSequence.new(Color3.fromRGB(83, 27, 31), Color3.fromRGB(208, 75, 41))
bossGradient.Parent = bossHealthFill

local bossFrameImageId = imageUri(Config.AssetIds.Images.BossBarFrame)
if bossFrameImageId then
	local bossFrameImage = Instance.new("ImageLabel")
	bossFrameImage.Name = "BossBarOrnament"
	bossFrameImage.Size = UDim2.new(1, 12, 0, 32)
	bossFrameImage.Position = UDim2.fromOffset(-6, 25)
	bossFrameImage.BackgroundTransparency = 1
	bossFrameImage.Image = bossFrameImageId
	bossFrameImage.ScaleType = Enum.ScaleType.Stretch
	bossFrameImage.ZIndex = 2
	bossFrameImage.Parent = bossPanel
end

local killsPanel = Instance.new("Frame")
killsPanel.Name = "KillsPanel"
killsPanel.Size = UDim2.fromOffset(154, 48)
killsPanel.Position = UDim2.new(1, -24, 0, 24)
killsPanel.AnchorPoint = Vector2.new(1, 0)
killsPanel.BackgroundColor3 = COLORS.ink
killsPanel.BackgroundTransparency = 0.18
killsPanel.BorderSizePixel = 0
killsPanel.Parent = gui
corner(killsPanel, 10)
stroke(killsPanel, COLORS.panelLight, 1, 0.3)
local killsLabel = textLabel(
	killsPanel,
	"Kills",
	"BANISHED  0",
	UDim2.fromScale(1, 1),
	UDim2.fromScale(0.5, 0.5),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamBlack,
	COLORS.cream,
	20
)

local embersPanel = Instance.new("Frame")
embersPanel.Name = "EmbersPanel"
embersPanel.Size = UDim2.fromOffset(154, 40)
embersPanel.Position = UDim2.new(1, -24, 0, 80)
embersPanel.AnchorPoint = Vector2.new(1, 0)
embersPanel.BackgroundColor3 = COLORS.ink
embersPanel.BackgroundTransparency = 0.18
embersPanel.BorderSizePixel = 0
embersPanel.Parent = gui
corner(embersPanel, 10)
stroke(embersPanel, Color3.fromRGB(246, 190, 77), 1, 0.3)
local embersLabel = textLabel(
	embersPanel,
	"Embers",
	"0 EMBERS",
	UDim2.fromScale(1, 1),
	UDim2.fromScale(0.5, 0.5),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamBlack,
	COLORS.gold,
	16
)

local relicPanel = Instance.new("Frame")
relicPanel.Name = "RelicPanel"
relicPanel.Size = UDim2.fromOffset(242, 104)
relicPanel.Position = UDim2.new(1, -22, 1, -62)
relicPanel.AnchorPoint = Vector2.new(1, 1)
relicPanel.BackgroundColor3 = COLORS.ink
relicPanel.BackgroundTransparency = 0.12
relicPanel.BorderSizePixel = 0
relicPanel.Parent = gui
corner(relicPanel, 12)
stroke(relicPanel, Color3.fromRGB(112, 79, 48), 1, 0.25)

local relicTitle = textLabel(
	relicPanel,
	"RelicTitle",
	"RELICS BOUND",
	UDim2.new(1, -24, 0, 22),
	UDim2.fromOffset(12, 7),
	Vector2.zero,
	Enum.Font.GothamBlack,
	COLORS.gold,
	12
)
relicTitle.TextXAlignment = Enum.TextXAlignment.Left
local dartRelic = textLabel(
	relicPanel,
	"DartRelic",
	"Ashen Dart  I",
	UDim2.new(1, -24, 0, 20),
	UDim2.fromOffset(12, 32),
	Vector2.zero,
	Enum.Font.GothamBold,
	COLORS.cream,
	13
)
dartRelic.TextXAlignment = Enum.TextXAlignment.Left
local haloRelic = textLabel(
	relicPanel,
	"HaloRelic",
	"Grave Halo  -",
	UDim2.new(1, -24, 0, 20),
	UDim2.fromOffset(12, 55),
	Vector2.zero,
	Enum.Font.GothamMedium,
	COLORS.muted,
	13
)
haloRelic.TextXAlignment = Enum.TextXAlignment.Left
local flameRelic = textLabel(
	relicPanel,
	"FlameRelic",
	"Blackflame Testament  -",
	UDim2.new(1, -24, 0, 20),
	UDim2.fromOffset(12, 78),
	Vector2.zero,
	Enum.Font.GothamMedium,
	COLORS.muted,
	13
)
flameRelic.TextXAlignment = Enum.TextXAlignment.Left

local statsPanel = Instance.new("Frame")
statsPanel.Name = "StatsPanel"
statsPanel.Size = UDim2.fromOffset(300, 92)
statsPanel.Position = UDim2.new(0, 22, 1, -62)
statsPanel.AnchorPoint = Vector2.new(0, 1)
statsPanel.BackgroundColor3 = COLORS.ink
statsPanel.BackgroundTransparency = 0.1
statsPanel.BorderSizePixel = 0
statsPanel.Parent = gui
corner(statsPanel, 12)
stroke(statsPanel, COLORS.panelLight, 1, 0.25)

local levelLabel = textLabel(
	statsPanel,
	"Level",
	"LEVEL 1",
	UDim2.fromOffset(110, 28),
	UDim2.fromOffset(16, 10),
	Vector2.zero,
	Enum.Font.GothamBlack,
	COLORS.gold,
	16
)
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
local healthText = textLabel(
	statsPanel,
	"HealthText",
	"100 / 100",
	UDim2.fromOffset(140, 28),
	UDim2.new(1, -16, 0, 10),
	Vector2.new(1, 0),
	Enum.Font.GothamBold,
	COLORS.cream,
	14
)
healthText.TextXAlignment = Enum.TextXAlignment.Right

local healthBack = Instance.new("Frame")
healthBack.Name = "HealthBack"
healthBack.Size = UDim2.new(1, -32, 0, 24)
healthBack.Position = UDim2.fromOffset(16, 50)
healthBack.BackgroundColor3 = Color3.fromRGB(56, 31, 42)
healthBack.BorderSizePixel = 0
healthBack.ClipsDescendants = true
healthBack.Parent = statsPanel
corner(healthBack, 7)

local healthFill = Instance.new("Frame")
healthFill.Name = "HealthFill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = COLORS.red
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
corner(healthFill, 7)

local healthGradient = Instance.new("UIGradient")
healthGradient.Color = ColorSequence.new(COLORS.darkRed, Color3.fromRGB(245, 62, 91))
healthGradient.Parent = healthFill

local xpBack = Instance.new("Frame")
xpBack.Name = "XPBack"
xpBack.Size = UDim2.new(1, -44, 0, 18)
xpBack.Position = UDim2.new(0.5, 0, 1, -25)
xpBack.AnchorPoint = Vector2.new(0.5, 1)
xpBack.BackgroundColor3 = COLORS.ink
xpBack.BackgroundTransparency = 0.05
xpBack.BorderSizePixel = 0
xpBack.ClipsDescendants = true
xpBack.Parent = gui
corner(xpBack, 7)
stroke(xpBack, COLORS.panelLight, 1, 0.35)

local xpFill = Instance.new("Frame")
xpFill.Name = "XPFill"
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = COLORS.purple
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBack
corner(xpFill, 7)

local xpGradient = Instance.new("UIGradient")
xpGradient.Color = ColorSequence.new(COLORS.purple, Color3.fromRGB(219, 65, 154))
xpGradient.Parent = xpFill

local xpText = textLabel(
	xpBack,
	"XPText",
	"0 / 5 XP",
	UDim2.fromScale(1, 1),
	UDim2.fromScale(0.5, 0.5),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamBold,
	COLORS.cream,
	11
)
xpText.ZIndex = 3

local controlsHint = textLabel(
	gui,
	"ControlsHint",
	UserInputService.TouchEnabled and "MOVE WITH THE JOYSTICK - RELICS STRIKE AUTOMATICALLY" or "WASD TO MOVE  -  RELICS STRIKE AUTOMATICALLY",
	UDim2.fromOffset(500, 26),
	UDim2.new(0.5, 0, 1, -49),
	Vector2.new(0.5, 1),
	Enum.Font.GothamMedium,
	COLORS.muted,
	12
)

local announcementPanel = Instance.new("Frame")
announcementPanel.Name = "AnnouncementPanel"
announcementPanel.Size = UDim2.fromOffset(660, 104)
announcementPanel.Position = UDim2.fromScale(0.5, 0.31)
announcementPanel.AnchorPoint = Vector2.new(0.5, 0.5)
announcementPanel.BackgroundColor3 = COLORS.ink
announcementPanel.BackgroundTransparency = 1
announcementPanel.BorderSizePixel = 0
announcementPanel.Visible = false
announcementPanel.ZIndex = 20
announcementPanel.Parent = gui

local announcementTitle = textLabel(
	announcementPanel,
	"AnnouncementTitle",
	"THE ASHEN VIGIL",
	UDim2.new(1, -30, 0, 50),
	UDim2.new(0.5, 0, 0, 2),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBlack,
	COLORS.gold,
	28
)
announcementTitle.ZIndex = 21
local announcementBody = textLabel(
	announcementPanel,
	"AnnouncementBody",
	"Endure the long night.",
	UDim2.new(1, -30, 0, 38),
	UDim2.new(0.5, 0, 0, 55),
	Vector2.new(0.5, 0),
	Enum.Font.GothamMedium,
	COLORS.cream,
	15
)
announcementBody.ZIndex = 21

-- A small side panel, not a full-screen modal: enemies are no longer frozen
-- out during a relic choice, so the player needs to keep seeing (and moving
-- through) the arena while picking. No full-viewport dimmer at all.
local levelPanel = Instance.new("Frame")
levelPanel.Name = "LevelPanel"
levelPanel.Size = UDim2.fromOffset(300, 0)
levelPanel.AutomaticSize = Enum.AutomaticSize.Y
levelPanel.Position = UDim2.new(0, 22, 0.5, 0)
levelPanel.AnchorPoint = Vector2.new(0, 0.5)
levelPanel.BackgroundColor3 = COLORS.panel
levelPanel.BackgroundTransparency = 0.14
levelPanel.BorderSizePixel = 0
levelPanel.Visible = false
levelPanel.ZIndex = 11
levelPanel.Parent = gui
corner(levelPanel, 16)
stroke(levelPanel, COLORS.gold, 2, 0.25)

local levelTitle = textLabel(
	levelPanel,
	"Title",
	"LEVEL UP",
	UDim2.new(1, -28, 0, 26),
	UDim2.new(0.5, 0, 0, 10),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBlack,
	COLORS.gold,
	18
)
levelTitle.ZIndex = 12

local choicesFrame = Instance.new("Frame")
choicesFrame.Name = "Choices"
choicesFrame.Size = UDim2.new(1, -28, 0, 0)
choicesFrame.AutomaticSize = Enum.AutomaticSize.Y
choicesFrame.Position = UDim2.new(0.5, 0, 0, 42)
choicesFrame.AnchorPoint = Vector2.new(0.5, 0)
choicesFrame.BackgroundTransparency = 1
choicesFrame.ZIndex = 12
choicesFrame.Parent = levelPanel
local choicesLayout = Instance.new("UIListLayout")
choicesLayout.FillDirection = Enum.FillDirection.Vertical
choicesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
choicesLayout.VerticalAlignment = Enum.VerticalAlignment.Top
choicesLayout.Padding = UDim.new(0, 8)
choicesLayout.Parent = choicesFrame
local choicesBottomPadding = Instance.new("UIPadding")
choicesBottomPadding.PaddingBottom = UDim.new(0, 14)
choicesBottomPadding.Parent = choicesFrame

-- Roll booth panel: opened by the OpenRollBooth remote when the player
-- interacts with the Lobby kiosk. A small centered panel (not a full-screen
-- blocker) rather than a HUD element, since it's only relevant while
-- standing at the booth.
local rollPanel = Instance.new("Frame")
rollPanel.Name = "RollPanel"
rollPanel.Size = UDim2.fromOffset(420, 450)
rollPanel.Position = UDim2.fromScale(0.5, 0.5)
rollPanel.AnchorPoint = Vector2.new(0.5, 0.5)
rollPanel.BackgroundColor3 = COLORS.panel
rollPanel.BackgroundTransparency = 0.06
rollPanel.BorderSizePixel = 0
rollPanel.Visible = false
rollPanel.ZIndex = 15
rollPanel.Parent = gui
corner(rollPanel, 16)
stroke(rollPanel, COLORS.gold, 2, 0.2)

local rollTitle = textLabel(
	rollPanel,
	"Title",
	"VIGIL-BOUND",
	UDim2.new(1, -40, 0, 32),
	UDim2.fromOffset(20, 14),
	Vector2.zero,
	Enum.Font.GothamBlack,
	COLORS.gold,
	22
)
rollTitle.ZIndex = 16

local rollCloseButton = Instance.new("TextButton")
rollCloseButton.Name = "Close"
rollCloseButton.Size = UDim2.fromOffset(28, 28)
rollCloseButton.Position = UDim2.new(1, -14, 0, 14)
rollCloseButton.AnchorPoint = Vector2.new(1, 0)
rollCloseButton.BackgroundColor3 = COLORS.panelLight
rollCloseButton.AutoButtonColor = false
rollCloseButton.Text = "X"
rollCloseButton.TextColor3 = COLORS.cream
rollCloseButton.Font = Enum.Font.GothamBold
rollCloseButton.TextSize = 14
rollCloseButton.ZIndex = 17
rollCloseButton.Parent = rollPanel
corner(rollCloseButton, 8)

-- Live preview models built with Players:CreateHumanoidModelFromDescription
-- -- a real (posed, R15) avatar rendered from the same HumanoidDescription
-- applySkinVisuals builds server-side, not a custom Part model. Equipped
-- gets a full-body shot; reserved gets a tight head-only crop, matching
-- "a little small preview icon of the head".
local equippedViewport = Instance.new("ViewportFrame")
equippedViewport.Name = "EquippedPreview"
equippedViewport.Size = UDim2.fromOffset(70, 70)
equippedViewport.Position = UDim2.fromOffset(20, 54)
equippedViewport.BackgroundColor3 = COLORS.ink
equippedViewport.BackgroundTransparency = 0.3
equippedViewport.ZIndex = 16
equippedViewport.Parent = rollPanel
corner(equippedViewport, 10)

local equippedLabel = textLabel(
	rollPanel, "Equipped", "Equipped: --",
	UDim2.fromOffset(300, 22), UDim2.fromOffset(100, 56), Vector2.zero,
	Enum.Font.GothamBold, COLORS.cream, 15
)
equippedLabel.TextXAlignment = Enum.TextXAlignment.Left
equippedLabel.ZIndex = 16
local equippedDesc = textLabel(
	rollPanel, "EquippedDesc", "",
	UDim2.fromOffset(300, 40), UDim2.fromOffset(100, 80), Vector2.zero,
	Enum.Font.GothamMedium, COLORS.muted, 12
)
equippedDesc.TextXAlignment = Enum.TextXAlignment.Left
equippedDesc.ZIndex = 16

local reservedIcon = Instance.new("ViewportFrame")
reservedIcon.Name = "ReservedHeadIcon"
reservedIcon.Size = UDim2.fromOffset(40, 40)
reservedIcon.Position = UDim2.fromOffset(20, 134)
reservedIcon.BackgroundColor3 = COLORS.ink
reservedIcon.BackgroundTransparency = 0.3
reservedIcon.ZIndex = 16
reservedIcon.Parent = rollPanel
corner(reservedIcon, 8)

local reservedLabel = textLabel(
	rollPanel, "Reserved", "Reserved: empty",
	UDim2.fromOffset(328, 22), UDim2.fromOffset(72, 136), Vector2.zero,
	Enum.Font.GothamBold, COLORS.cream, 15
)
reservedLabel.TextXAlignment = Enum.TextXAlignment.Left
reservedLabel.ZIndex = 16
local reservedDesc = textLabel(
	rollPanel, "ReservedDesc", "",
	UDim2.fromOffset(328, 34), UDim2.fromOffset(72, 158), Vector2.zero,
	Enum.Font.GothamMedium, COLORS.muted, 12
)
reservedDesc.TextXAlignment = Enum.TextXAlignment.Left
reservedDesc.ZIndex = 16

local function rollActionButton(name, text, yPos)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, -40, 0, 40)
	button.Position = UDim2.new(0.5, 0, 0, yPos)
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.BackgroundColor3 = COLORS.panelLight
	button.AutoButtonColor = false
	button.Text = text
	button.TextColor3 = COLORS.cream
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.ZIndex = 16
	button.Parent = rollPanel
	corner(button, 10)
	stroke(button, COLORS.purple, 1, 0.3)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(83, 49, 77) }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = COLORS.panelLight }):Play()
	end)
	return button
end

local reserveButton = rollActionButton("Reserve", "Reserve Current", 212)
local swapButton = rollActionButton("Swap", "Swap to Reserved", 258)
local rollEmbersButton = rollActionButton("RollEmbers", "Roll", 304)
local rollRobuxButton = rollActionButton("RollRobux", "Roll -- Robux", 350)

local rollFooter = textLabel(
	rollPanel, "Footer",
	"Rolling replaces your equipped skin unless it's reserved first.",
	UDim2.new(1, -40, 0, 34), UDim2.fromOffset(20, 400), Vector2.zero,
	Enum.Font.GothamMedium, COLORS.muted, 11
)
rollFooter.ZIndex = 16

local rollBoothState = nil

-- Builds the same HumanoidDescription applySkinVisuals builds server-side,
-- from the same Config.Characters/AssetIds.Characters data (already
-- replicated to the client via ReplicatedStorage), purely for preview.
local function buildDescriptionForSkin(skinId)
	local skin
	for _, entry in ipairs(Config.Characters) do
		if entry.id == skinId then
			skin = entry
			break
		end
	end
	if not skin then
		return nil
	end

	local description = Instance.new("HumanoidDescription")
	description.HeadColor = skin.bodyColors.head
	description.TorsoColor = skin.bodyColors.torso
	description.LeftArmColor = skin.bodyColors.leftArm
	description.RightArmColor = skin.bodyColors.rightArm
	description.LeftLegColor = skin.bodyColors.leftLeg
	description.RightLegColor = skin.bodyColors.rightLeg

	local assetIds = Config.AssetIds.Characters[skinId]
	if assetIds then
		if assetIds.Shirt and assetIds.Shirt > 0 then
			description.Shirt = assetIds.Shirt
		end
		if assetIds.Pants and assetIds.Pants > 0 then
			description.Pants = assetIds.Pants
		end
		if assetIds.Face and assetIds.Face > 0 then
			description.Face = assetIds.Face
		end
		if assetIds.HairAccessory and assetIds.HairAccessory > 0 then
			description.HairAccessory = assetIds.HairAccessory
		end
		if assetIds.BackAccessory and assetIds.BackAccessory > 0 then
			description.BackAccessory = assetIds.BackAccessory
		end
	end
	return description
end

local function clearViewport(viewport)
	for _, child in ipairs(viewport:GetChildren()) do
		child:Destroy()
	end
end

-- headOnly=false frames a full-body shot (equipped); headOnly=true frames a
-- tight head-only crop (reserved icon).
local function showSkinPreview(viewport, skinId, headOnly)
	clearViewport(viewport)
	if not skinId then
		return
	end
	local description = buildDescriptionForSkin(skinId)
	if not description then
		return
	end
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		return
	end
	model.Parent = viewport

	local previewCamera = Instance.new("Camera")
	previewCamera.Parent = viewport
	viewport.CurrentCamera = previewCamera

	if headOnly then
		local head = model:FindFirstChild("Head")
		local headPosition = (head and head.Position) or Vector3.new(0, 0, 0)
		previewCamera.FieldOfView = 40
		previewCamera.CFrame = CFrame.new(headPosition + Vector3.new(0, 0, 1.6), headPosition)
	else
		local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		local center = (root and root.Position) or Vector3.new(0, 0, 0)
		previewCamera.FieldOfView = 50
		previewCamera.CFrame = CFrame.new(center + Vector3.new(0, 1.4, 5.5), center + Vector3.new(0, 0.9, 0))
	end
end

local function refreshRollPanelDisplay()
	if not rollBoothState then
		return
	end
	local equipped = rollBoothState.equipped
	local reserved = rollBoothState.reserved
	equippedLabel.Text = "Equipped: " .. (equipped and equipped.name or "--")
	equippedDesc.Text = equipped and equipped.description or ""
	reservedLabel.Text = "Reserved: " .. (reserved and reserved.name or "empty")
	reservedDesc.Text = reserved and reserved.description or "Nothing banked -- a roll will replace your equipped skin."
	showSkinPreview(equippedViewport, equipped and equipped.id, false)
	showSkinPreview(reservedIcon, reserved and reserved.id, true)
	rollEmbersButton.Text = string.format("Roll -- %d Embers", rollBoothState.rollCost)
	rollRobuxButton.Text = rollBoothState.robuxEnabled and "Roll -- Robux" or "Roll -- Robux (Coming Soon)"
end

local rollAnimationRandom = Random.new()
local rollLocked = false

-- Slot-machine-style reveal: cycles the equipped preview through random
-- roster entries at decelerating intervals, then lands on the exact result
-- the server already picked (never decided client-side -- this is purely a
-- reveal effect over an outcome that's already final by the time this
-- plays). Currently a uniform spin since Config.Characters odds are flat;
-- if weighted odds are ever added, weighting this cycle would be the place.
local function playRollAnimation(payload)
	rollLocked = true
	local roster = payload.roster or {}
	local steps = 18
	local delay = 0.06
	task.spawn(function()
		for _ = 1, steps do
			if #roster > 0 then
				local pick = roster[rollAnimationRandom:NextInteger(1, #roster)]
				equippedLabel.Text = "Equipped: " .. pick.name
				equippedDesc.Text = pick.description
				showSkinPreview(equippedViewport, pick.id, false)
			end
			task.wait(delay)
			delay *= 1.12
		end
		rollBoothState = payload
		refreshRollPanelDisplay()
		rollLocked = false
	end)
end

openRollBoothRemote.OnClientEvent:Connect(function(payload)
	rollPanel.Visible = true
	if payload.rolled then
		playRollAnimation(payload)
	else
		rollBoothState = payload
		refreshRollPanelDisplay()
	end
end)

rollCloseButton.Activated:Connect(function()
	rollPanel.Visible = false
end)

reserveButton.Activated:Connect(function()
	if rollLocked then
		return
	end
	reserveCurrentRemote:FireServer()
end)

swapButton.Activated:Connect(function()
	if rollLocked then
		return
	end
	swapReservedRemote:FireServer()
end)

rollEmbersButton.Activated:Connect(function()
	if rollLocked then
		return
	end
	rollCharacterRemote:FireServer("embers")
end)

rollRobuxButton.Activated:Connect(function()
	if rollLocked then
		return
	end
	if rollBoothState and rollBoothState.robuxEnabled then
		rollCharacterRemote:FireServer("robux")
	end
end)

local scale = Instance.new("UIScale")
scale.Name = "ResponsiveScale"
scale.Parent = levelPanel
local function updateScale()
	local viewport = camera.ViewportSize
	scale.Scale = math.min(1, math.max(0.62, viewport.X / 900))
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

local previousHealth = 100
local choiceLocked = false
-- Currently-displayed relic icon models + a single shared animation
-- connection, so the "slight animation to liven it up" never leaks a loop
-- between choice screens: it starts when choices are shown and is
-- disconnected the moment they're cleared (picked, or panel closed on death).
local activeRelicModels = {}
local relicSpinConnection = nil
local relicSpinTime = 0

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function stopRelicSpin()
	if relicSpinConnection then
		relicSpinConnection:Disconnect()
		relicSpinConnection = nil
	end
	activeRelicModels = {}
end

local function startRelicSpin()
	if relicSpinConnection then
		return
	end
	relicSpinTime = 0
	relicSpinConnection = RunService.RenderStepped:Connect(function(dt)
		relicSpinTime += dt
		for _, entry in ipairs(activeRelicModels) do
			if entry.model.Parent then
				local bob = math.sin(relicSpinTime * 2 + entry.phase) * 0.08
				entry.model:PivotTo(CFrame.new(0, bob, 0) * CFrame.Angles(0, relicSpinTime * 1.1 + entry.phase, 0))
			end
		end
	end)
end

local function clearChoices()
	stopRelicSpin()
	for _, child in ipairs(choicesFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function showLevelChoices(choices, level)
	choiceLocked = false
	clearChoices()
	levelTitle.Text = "LEVEL " .. tostring(level)
	levelPanel.Visible = true

	for index, choice in ipairs(choices) do
		local button = Instance.new("TextButton")
		button.Name = choice.id
		button.Size = UDim2.new(1, 0, 0, 82)
		button.BackgroundColor3 = index == 1 and Color3.fromRGB(70, 42, 66) or COLORS.panelLight
		button.AutoButtonColor = false
		button.Text = ""
		button.ZIndex = 13
		button.Parent = choicesFrame
		corner(button, 12)
		local buttonStroke = stroke(button, index == 1 and COLORS.gold or COLORS.purple, 2, 0.2)

		-- Generated 3D model instead of a 2D icon, matching the enemy-visual
		-- technique/palette. Rendered live in a ViewportFrame; the shared
		-- RenderStepped loop above spins/bobs it slightly for "liveliness".
		local viewport = Instance.new("ViewportFrame")
		viewport.Name = "RelicViewport"
		viewport.Size = UDim2.fromOffset(64, 64)
		viewport.Position = UDim2.fromOffset(9, 9)
		viewport.BackgroundColor3 = COLORS.ink
		viewport.BackgroundTransparency = 0.3
		viewport.ZIndex = 14
		viewport.Parent = button
		corner(viewport, 10)

		local relicModel = RelicModelFactory.Build(choice.id)
		relicModel.Parent = viewport
		local viewCamera = Instance.new("Camera")
		viewCamera.FieldOfView = 50
		viewCamera.CFrame = CFrame.new(Vector3.new(2.1, 1.7, 2.1), Vector3.new(0, 0, 0))
		viewCamera.Parent = viewport
		viewport.CurrentCamera = viewCamera
		table.insert(activeRelicModels, { model = relicModel, phase = math.random() * math.pi * 2 })

		local iconTitle = textLabel(
			button,
			"RelicName",
			choice.title,
			UDim2.new(1, -92, 0, 22),
			UDim2.fromOffset(84, 9),
			Vector2.zero,
			Enum.Font.GothamBold,
			COLORS.cream,
			15
		)
		iconTitle.ZIndex = 14
		local iconDescription = textLabel(
			button,
			"RelicDescription",
			choice.description,
			UDim2.new(1, -92, 0, 48),
			UDim2.fromOffset(84, 31),
			Vector2.zero,
			Enum.Font.GothamMedium,
			COLORS.muted,
			12
		)
		iconDescription.ZIndex = 14

		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(83, 49, 77),
			}):Play()
			buttonStroke.Transparency = 0
		end)
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = index == 1 and Color3.fromRGB(70, 42, 66) or COLORS.panelLight,
			}):Play()
			buttonStroke.Transparency = 0.2
		end)
		button.Activated:Connect(function()
			if choiceLocked then
				return
			end
			choiceLocked = true
			upgradeChoiceRemote:FireServer(choice.id)
			levelPanel.Visible = false
		end)
	end

	startRelicSpin()
end

stateUpdateRemote.OnClientEvent:Connect(function(data)
	-- TimerPanel is repurposed from a match countdown into a personal "how
	-- long have I been in this Vigil" stopwatch, since the Vigil itself never
	-- ends anymore.
	timerLabel.Text = formatTime(data.vigilElapsed)
	killsLabel.Text = "BANISHED  " .. tostring(data.kills)
	levelLabel.Text = "LEVEL " .. tostring(data.level)
	embersLabel.Text = tostring(data.embers or 0) .. " EMBERS"
	updateQuestPanel(data.questsDaily, data.questsWeekly)
	healthText.Text = string.format("%d / %d", math.ceil(data.health), math.ceil(data.maxHealth))
	healthFill.Size = UDim2.fromScale(math.clamp(data.health / math.max(data.maxHealth, 1), 0, 1), 1)
	xpFill.Size = UDim2.fromScale(math.clamp(data.xp / math.max(data.xpNeeded, 1), 0, 1), 1)
	xpText.Text = string.format("%d / %d XP", data.xp, data.xpNeeded)
	relicTitle.Text = data.damageMultiplier > 1.001
		and string.format("RELICS BOUND  -  %.2fx POWER", data.damageMultiplier)
		or "RELICS BOUND"
	haloRelic.Text = data.graveHaloRank > 0 and ("Grave Halo  " .. tostring(data.graveHaloRank)) or "Grave Halo  -"
	haloRelic.TextColor3 = data.graveHaloRank > 0 and COLORS.cream or COLORS.muted
	flameRelic.Text = data.blackflameRank > 0 and ("Blackflame Testament  " .. tostring(data.blackflameRank)) or "Blackflame Testament  -"
	flameRelic.TextColor3 = data.blackflameRank > 0 and COLORS.cream or COLORS.muted

	if data.bossDefeated then
		threatLabel.Text = "OATH SUNDERED"
		threatLabel.TextColor3 = COLORS.gold
	elseif data.bossActive then
		threatLabel.Text = "THE WARDEN DESCENDS"
		threatLabel.TextColor3 = COLORS.red
	elseif data.enemies >= 120 then
		threatLabel.Text = "OVERWHELMING"
		threatLabel.TextColor3 = COLORS.red
	elseif data.vigilElapsed >= 120 then
		threatLabel.Text = "THE HORDE RISES"
		threatLabel.TextColor3 = COLORS.red
	else
		threatLabel.Text = "THE LONG NIGHT"
		threatLabel.TextColor3 = COLORS.red
	end

	-- The Lobby is safe and has no combat state worth showing: hide the
	-- whole combat HUD there rather than displaying a stale boss bar/kill
	-- count/relic loadout from whatever run the player last had.
	local combatHudVisible = data.inVigil == true
	timerPanel.Visible = combatHudVisible
	objective.Visible = combatHudVisible
	killsPanel.Visible = combatHudVisible
	relicPanel.Visible = combatHudVisible
	statsPanel.Visible = combatHudVisible
	xpBack.Visible = combatHudVisible
	bossPanel.Visible = combatHudVisible and data.bossActive == true
	if data.bossActive and combatHudVisible then
		bossName.Text = data.bossName or "THE CINDER WARDEN"
		bossHealthFill.Size = UDim2.fromScale(math.clamp(data.bossHealth / math.max(data.bossMaxHealth, 1), 0, 1), 1)
	end
	controlsHint.Text = combatHudVisible
		and (UserInputService.TouchEnabled and "MOVE WITH THE JOYSTICK - RELICS STRIKE AUTOMATICALLY" or "WASD TO MOVE  -  RELICS STRIKE AUTOMATICALLY")
		or (UserInputService.TouchEnabled and "FIND THE GATE TO ENTER THE VIGIL" or "WASD TO MOVE  -  FIND THE GATE TO ENTER THE VIGIL")

	if data.health < previousHealth then
		vignette.BackgroundTransparency = 0.72
		TweenService:Create(vignette, TweenInfo.new(0.35), {
			BackgroundTransparency = 1,
		}):Play()
	end
	previousHealth = data.health
end)

levelUpRemote.OnClientEvent:Connect(showLevelChoices)

local announcementToken = 0
announcementRemote.OnClientEvent:Connect(function(title, body, accentColor)
	announcementToken += 1
	local token = announcementToken
	announcementPanel.Visible = true
	announcementPanel.BackgroundTransparency = 1
	announcementTitle.Text = title
	announcementTitle.TextColor3 = accentColor or COLORS.gold
	announcementTitle.TextTransparency = 1
	announcementBody.Text = body
	announcementBody.TextTransparency = 1
	TweenService:Create(announcementPanel, TweenInfo.new(0.35), {
		BackgroundTransparency = 0.3,
	}):Play()
	TweenService:Create(announcementTitle, TweenInfo.new(0.35), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(announcementBody, TweenInfo.new(0.5), {
		TextTransparency = 0,
	}):Play()
	task.delay(3.1, function()
		if token ~= announcementToken then
			return
		end
		TweenService:Create(announcementPanel, TweenInfo.new(0.5), {
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(announcementTitle, TweenInfo.new(0.5), {
			TextTransparency = 1,
		}):Play()
		TweenService:Create(announcementBody, TweenInfo.new(0.5), {
			TextTransparency = 1,
		}):Play()
		task.delay(0.55, function()
			if token == announcementToken then
				announcementPanel.Visible = false
			end
		end)
	end)
end)

-- Death (and any other end-of-run event) is now just a light Announcement
-- toast fired by the server, handled by the connection above — there's no
-- more full-screen result modal or manual restart button, since the server
-- auto-returns the player to the Lobby a couple seconds after dying.
player.CharacterAdded:Connect(function()
	levelPanel.Visible = false
	clearChoices()
end)

local intro = textLabel(
	gui,
	"Intro",
	"ASHEN\nVIGIL",
	UDim2.fromOffset(520, 150),
	UDim2.fromScale(0.5, 0.5),
	Vector2.new(0.5, 0.5),
	Enum.Font.GothamBlack,
	COLORS.cream,
	40
)
intro.ZIndex = 50
intro.TextTransparency = 0
task.delay(1.1, function()
	TweenService:Create(intro, TweenInfo.new(0.8), {
		TextTransparency = 1,
	}):Play()
	task.delay(0.9, function()
		intro:Destroy()
	end)
end)

RunService:BindToRenderStep("AshenVigilCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 58
	local desiredPosition = root.Position + Vector3.new(0, 55, 39)
	local desired = CFrame.lookAt(desiredPosition, root.Position + Vector3.new(0, 0, -4))
	camera.CFrame = camera.CFrame:Lerp(desired, 0.13)
end)
