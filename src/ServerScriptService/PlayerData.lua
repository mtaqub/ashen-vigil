local DataStoreService = game:GetService("DataStoreService")

-- The project's first persistence layer: Embers, the equipped/reserved
-- skin, and quest progress all need to survive a player leaving and coming
-- back. Kept deliberately lean (no generic profile framework) since it's a
-- first-of-its-kind system in this project.
local PlayerData = {}

local store = DataStoreService:GetDataStore("AshenVigilPlayerData_v1")

local profiles = {}

local function defaultProfile()
	return {
		embers = 0,
		equippedCharacter = "Default",
		reservedCharacter = nil,
		-- PurchaseIds already granted by MarketplaceService.ProcessReceipt,
		-- so a retried receipt (or the same one delivered twice) never
		-- grants a roll more than once.
		processedPurchaseIds = {},
		quests = {
			dailyResetDay = "",
			weeklyResetWeek = "",
			daily = {},
			weekly = {},
		},
	}
end

-- Fills in any fields missing from a saved profile -- covers both a
-- brand-new player (nil profile) and an existing one saved before a field
-- was added -- without discarding what they already have.
local function withDefaults(saved)
	local fresh = defaultProfile()
	local profile = saved or {}
	for key, value in pairs(fresh) do
		if profile[key] == nil then
			profile[key] = value
		end
	end
	if type(profile.quests) ~= "table" then
		profile.quests = fresh.quests
	else
		for key, value in pairs(fresh.quests) do
			if profile.quests[key] == nil then
				profile.quests[key] = value
			end
		end
	end
	return profile
end

local function keyFor(player)
	return "Player_" .. tostring(player.UserId)
end

-- Loads (or lazily creates) a player's profile and holds it in memory for
-- the rest of the session. Never blocks/fails spawning -- a load error just
-- falls back to fresh defaults, matching every other "sensible defaults on
-- failure" pattern already used in this project (see GameState.lua).
function PlayerData.Load(player)
	local ok, result = pcall(function()
		return store:GetAsync(keyFor(player))
	end)
	local profile = withDefaults(ok and result or nil)
	profiles[player] = profile
	return profile
end

function PlayerData.Get(player)
	return profiles[player]
end

function PlayerData.Save(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	pcall(function()
		store:SetAsync(keyFor(player), profile)
	end)
end

-- Called once a player's profile no longer needs to stay in memory (after
-- PlayerData.Save on PlayerRemoving).
function PlayerData.Release(player)
	profiles[player] = nil
end

-- Saves every currently-loaded profile; used from game:BindToClose so a
-- server shutdown doesn't lose anyone's progress.
function PlayerData.SaveAll()
	for player in pairs(profiles) do
		PlayerData.Save(player)
	end
end

return PlayerData
