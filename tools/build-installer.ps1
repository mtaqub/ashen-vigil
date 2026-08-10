param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$assetIdsPath = Join-Path $ProjectRoot "src/ReplicatedStorage/Shared/AssetIds.lua"
$configPath = Join-Path $ProjectRoot "src/ReplicatedStorage/Shared/Config.lua"
$serverPath = Join-Path $ProjectRoot "src/ServerScriptService/GameServer.server.lua"
$clientPath = Join-Path $ProjectRoot "src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua"
$outputPath = Join-Path $ProjectRoot "studio-installer.lua"

$assetIds = Get-Content -LiteralPath $assetIdsPath -Raw -Encoding utf8
$config = Get-Content -LiteralPath $configPath -Raw -Encoding utf8
$server = Get-Content -LiteralPath $serverPath -Raw -Encoding utf8
$client = Get-Content -LiteralPath $clientPath -Raw -Encoding utf8

$template = @'
-- ASHEN VIGIL: ROBLOX STUDIO INSTALLER
-- Paste this entire file into View > Command Bar, then press Enter once.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local function replace(className, name, parent, source)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local object = Instance.new(className)
	object.Name = name
	object.Source = source
	object.Parent = parent
	return object
end

local shared = ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder")
shared.Name = "Shared"
shared.Parent = ReplicatedStorage

-- ===== AssetIds: create once, then only ever merge newly added keys into it. =====
-- Existing uploaded IDs are never destroyed, zeroed, or renamed by this installer.
local ASSET_IDS_SOURCE = [====[
__ASSET_IDS__
]====]

local function evaluateTable(source, tempName)
	local temp = Instance.new("ModuleScript")
	temp.Name = tempName
	temp.Source = source
	temp.Parent = shared
	local ok, result = pcall(require, temp)
	temp:Destroy()
	if ok and type(result) == "table" then
		return result
	end
	warn("Ashen Vigil installer: failed to evaluate " .. tempName .. " (" .. tostring(result) .. ")")
	return nil
end

local function mergeAssetIds(defaults, existing)
	local merged = { Audio = {}, Images = {} }
	for _, section in ipairs({ "Audio", "Images" }) do
		local defaultSection = (defaults and defaults[section]) or {}
		local existingSection = (existing and existing[section]) or {}
		for key, defaultValue in pairs(defaultSection) do
			local existingValue = existingSection[key]
			merged[section][key] = (type(existingValue) == "number") and existingValue or defaultValue
		end
	end
	return merged
end

local function serializeAssetIds(tbl)
	local function serializeSection(section)
		local keys = {}
		for key in pairs(section or {}) do
			table.insert(keys, key)
		end
		table.sort(keys)
		local lines = {}
		for _, key in ipairs(keys) do
			table.insert(lines, string.format("\t%s = %.0f,", key, section[key] or 0))
		end
		return table.concat(lines, "\n")
	end

	return table.concat({
		"local AssetIds = {}",
		"",
		"AssetIds.Audio = {",
		serializeSection(tbl.Audio),
		"}",
		"",
		"AssetIds.Images = {",
		serializeSection(tbl.Images),
		"}",
		"",
		"return AssetIds",
		"",
	}, "\n")
end

local defaultAssetIds = evaluateTable(ASSET_IDS_SOURCE, "AshenVigilAssetIdsDefaults") or { Audio = {}, Images = {} }
local existingAssetIdsModule = shared:FindFirstChild("AssetIds")
local existingConfigModule = shared:FindFirstChild("Config")

local existingValues = nil
if existingAssetIdsModule and existingAssetIdsModule:IsA("ModuleScript") then
	local ok, result = pcall(require, existingAssetIdsModule)
	if ok and type(result) == "table" then
		existingValues = result
	end
elseif existingConfigModule and existingConfigModule:IsA("ModuleScript") then
	-- Migration: an older install kept AssetIds inline inside Config. Recover any
	-- real IDs already uploaded there before Config gets replaced below.
	local ok, result = pcall(require, existingConfigModule)
	if ok and type(result) == "table" and type(result.AssetIds) == "table" then
		existingValues = result.AssetIds
	end
end

local mergedAssetIds = mergeAssetIds(defaultAssetIds, existingValues)
local assetIdsSource = serializeAssetIds(mergedAssetIds)

if existingAssetIdsModule and existingAssetIdsModule:IsA("ModuleScript") then
	existingAssetIdsModule.Source = assetIdsSource
else
	local assetIds = Instance.new("ModuleScript")
	assetIds.Name = "AssetIds"
	assetIds.Source = assetIdsSource
	assetIds.Parent = shared
end

-- ===== Config, GameServer, GameClient: always replaced with the latest version. =====
replace("ModuleScript", "Config", shared, [====[
__CONFIG__
]====])

replace("Script", "GameServer", ServerScriptService, [====[
__SERVER__
]====])

replace("LocalScript", "GameClient", StarterPlayer.StarterPlayerScripts, [====[
__CLIENT__
]====])

print("Ashen Vigil installed! Press Play to begin.")
'@

$template = $template.Replace("__ASSET_IDS__", $assetIds.TrimEnd())
$template = $template.Replace("__CONFIG__", $config.TrimEnd())
$template = $template.Replace("__SERVER__", $server.TrimEnd())
$template = $template.Replace("__CLIENT__", $client.TrimEnd())
Set-Content -LiteralPath $outputPath -Value $template -Encoding utf8
Write-Output "Built $outputPath"
