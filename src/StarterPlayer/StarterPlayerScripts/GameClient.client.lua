local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RelicModelFactory = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RelicModelFactory"))
local remotes = ReplicatedStorage:WaitForChild("AshenVigilRemotes")
local stateUpdateRemote = remotes:WaitForChild("StateUpdate")
local levelUpRemote = remotes:WaitForChild("LevelUp")
local upgradeChoiceRemote = remotes:WaitForChild("UpgradeChoice")
local announcementRemote = remotes:WaitForChild("Announcement")

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

local levelOverlay = Instance.new("Frame")
levelOverlay.Name = "LevelOverlay"
levelOverlay.Size = UDim2.fromScale(1, 1)
levelOverlay.BackgroundColor3 = COLORS.ink
levelOverlay.BackgroundTransparency = 0.24
levelOverlay.BorderSizePixel = 0
levelOverlay.Visible = false
levelOverlay.ZIndex = 10
levelOverlay.Parent = gui

local levelPanel = Instance.new("Frame")
levelPanel.Name = "LevelPanel"
levelPanel.Size = UDim2.fromOffset(760, 330)
levelPanel.Position = UDim2.fromScale(0.5, 0.5)
levelPanel.AnchorPoint = Vector2.new(0.5, 0.5)
levelPanel.BackgroundColor3 = COLORS.panel
levelPanel.BorderSizePixel = 0
levelPanel.ZIndex = 11
levelPanel.Parent = levelOverlay
corner(levelPanel, 18)
stroke(levelPanel, COLORS.gold, 2, 0.2)

local levelTitle = textLabel(
	levelPanel,
	"Title",
	"LEVEL UP",
	UDim2.new(1, -40, 0, 52),
	UDim2.new(0.5, 0, 0, 18),
	Vector2.new(0.5, 0),
	Enum.Font.GothamBlack,
	COLORS.gold,
	30
)
levelTitle.ZIndex = 12
local levelSubtitle = textLabel(
	levelPanel,
	"Subtitle",
	"Inherit one forsaken relic",
	UDim2.new(1, -40, 0, 30),
	UDim2.new(0.5, 0, 0, 66),
	Vector2.new(0.5, 0),
	Enum.Font.GothamMedium,
	COLORS.muted,
	15
)
levelSubtitle.ZIndex = 12

local levelSigilImageId = imageUri(Config.AssetIds.Images.LevelUpSigil)
if levelSigilImageId then
	local levelSigil = Instance.new("ImageLabel")
	levelSigil.Name = "LevelUpSigil"
	levelSigil.Size = UDim2.fromOffset(116, 116)
	levelSigil.Position = UDim2.new(0.5, 0, 0, -9)
	levelSigil.AnchorPoint = Vector2.new(0.5, 0)
	levelSigil.BackgroundTransparency = 1
	levelSigil.Image = levelSigilImageId
	levelSigil.ImageTransparency = 0.64
	levelSigil.ScaleType = Enum.ScaleType.Fit
	levelSigil.ZIndex = 11
	levelSigil.Parent = levelPanel
end

local choicesFrame = Instance.new("Frame")
choicesFrame.Name = "Choices"
choicesFrame.Size = UDim2.new(1, -48, 0, 190)
choicesFrame.Position = UDim2.fromOffset(24, 112)
choicesFrame.BackgroundTransparency = 1
choicesFrame.ZIndex = 12
choicesFrame.Parent = levelPanel
local choicesLayout = Instance.new("UIListLayout")
choicesLayout.FillDirection = Enum.FillDirection.Horizontal
choicesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
choicesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
choicesLayout.Padding = UDim.new(0, 14)
choicesLayout.Parent = choicesFrame

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
local restartRequested = false

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function clearChoices()
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
	levelOverlay.Visible = true
	levelPanel.Size = UDim2.fromOffset(700, 300)
	TweenService:Create(levelPanel, TweenInfo.new(0.24, Enum.EasingStyle.Back), {
		Size = UDim2.fromOffset(760, 330),
	}):Play()

	for index, choice in ipairs(choices) do
		local imageKey = CHOICE_IMAGE_KEYS[choice.id]
		local iconImage = imageKey and imageUri(Config.AssetIds.Images[imageKey]) or nil
		local button = Instance.new("TextButton")
		button.Name = choice.id
		button.Size = UDim2.fromOffset(218, 176)
		button.BackgroundColor3 = index == 1 and Color3.fromRGB(70, 42, 66) or COLORS.panelLight
		button.AutoButtonColor = false
		button.Text = iconImage and "" or (choice.title .. "\n\n" .. choice.description)
		button.TextColor3 = COLORS.cream
		button.TextSize = 17
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.ZIndex = 13
		button.Parent = choicesFrame
		corner(button, 14)
		local buttonStroke = stroke(button, index == 1 and COLORS.gold or COLORS.purple, 2, 0.2)

		if iconImage then
			local icon = Instance.new("ImageLabel")
			icon.Name = "RelicIcon"
			icon.Size = UDim2.fromOffset(66, 66)
			icon.Position = UDim2.new(0.5, 0, 0, 8)
			icon.AnchorPoint = Vector2.new(0.5, 0)
			icon.BackgroundTransparency = 1
			icon.Image = iconImage
			icon.ScaleType = Enum.ScaleType.Fit
			icon.ZIndex = 14
			icon.Parent = button

			local iconTitle = textLabel(
				button,
				"RelicName",
				choice.title,
				UDim2.new(1, -16, 0, 28),
				UDim2.fromOffset(8, 77),
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
				UDim2.new(1, -18, 0, 58),
				UDim2.fromOffset(9, 107),
				Vector2.zero,
				Enum.Font.GothamMedium,
				COLORS.muted,
				12
			)
			iconDescription.ZIndex = 14
		end

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
			levelOverlay.Visible = false
		end)
	end
end

stateUpdateRemote.OnClientEvent:Connect(function(data)
	local remaining = math.max(0, data.duration - data.elapsed)
	timerLabel.Text = formatTime(remaining)
	killsLabel.Text = "BANISHED  " .. tostring(data.kills)
	levelLabel.Text = "LEVEL " .. tostring(data.level)
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
	bossPanel.Visible = data.bossActive == true
	if data.bossActive then
		bossName.Text = data.bossName or "THE CINDER WARDEN"
		bossHealthFill.Size = UDim2.fromScale(math.clamp(data.bossHealth / math.max(data.bossMaxHealth, 1), 0, 1), 1)
	end

	if data.bossDefeated then
		threatLabel.Text = "OATH SUNDERED"
		threatLabel.TextColor3 = COLORS.gold
	elseif data.bossActive and remaining > 30 then
		threatLabel.Text = "THE WARDEN DESCENDS"
		threatLabel.TextColor3 = COLORS.red
	elseif remaining <= 30 then
		threatLabel.Text = "DAWN IS NEAR"
		threatLabel.TextColor3 = COLORS.gold
	elseif data.enemies >= 120 then
		threatLabel.Text = "OVERWHELMING"
	elseif data.elapsed >= 120 then
		threatLabel.Text = "THE HORDE RISES"
	else
		threatLabel.Text = "THE LONG NIGHT"
	end

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

gameEndedRemote.OnClientEvent:Connect(function(won, kills, survived, wardenDefeated)
	levelOverlay.Visible = false
	resultOverlay.Visible = true
	resultButton.Visible = not won
	restartRequested = false
	if won then
		resultTitle.Text = wardenDefeated and "THE OATH IS SUNDERED" or "THE VIGIL ENDURES"
		resultTitle.TextColor3 = COLORS.gold
		resultText.Text = wardenDefeated
			and string.format("The Cinder Warden has fallen.\n%d forsaken banished.", kills)
			or string.format("You endured until dawn. The Warden remains.\n%d forsaken banished.", kills)
	else
		resultTitle.Text = "YOUR VIGIL ENDS"
		resultTitle.TextColor3 = COLORS.red
		resultText.Text = string.format("Endured %s  -  %d forsaken banished.", formatTime(survived), kills)
	end
end)

resultButton.Activated:Connect(function()
	if restartRequested then
		return
	end
	restartRequested = true
	restartVigilRemote:FireServer()
	task.delay(2, function()
		restartRequested = false
	end)
end)

player.CharacterAdded:Connect(function()
	resultOverlay.Visible = false
	restartRequested = false
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
