local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

-- Daily/weekly quests: a random subset of Config.Quests.Daily/Weekly is
-- drawn each UTC day/week, progress accumulates via Quests.Progress calls
-- from wherever the relevant event already happens (Enemies.lua on a kill/
-- boss defeat, Upgrades.lua on level-up, GameServer.server.lua's Heartbeat
-- for time survived), and completing one awards Embers through PlayerData.
local Quests = {}

local random = Random.new()
local announcementRemote

function Quests.Init(announcementRemoteInstance)
	announcementRemote = announcementRemoteInstance
end

local function currentUtcDay()
	return os.date("!%Y-%m-%d")
end

local function currentUtcWeek()
	return os.date("!%Y-W%U")
end

local function pickRandomSet(pool, count)
	local indices = {}
	for index = 1, #pool do
		indices[index] = index
	end
	for index = #indices, 2, -1 do
		local other = random:NextInteger(1, index)
		indices[index], indices[other] = indices[other], indices[index]
	end
	local picked = {}
	for i = 1, math.min(count, #indices) do
		local template = pool[indices[i]]
		picked[template.id] = { progress = 0, complete = false }
	end
	return picked
end

-- Draws a fresh set of active quests if the stored UTC day/week has rolled
-- over since the player's last save. Call on player join.
function Quests.EnsureCurrentSet(player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local quests = profile.quests

	local day = currentUtcDay()
	if quests.dailyResetDay ~= day then
		quests.dailyResetDay = day
		quests.daily = pickRandomSet(Config.Quests.Daily, Config.Quests.DailyActiveCount)
	end

	local week = currentUtcWeek()
	if quests.weeklyResetWeek ~= week then
		quests.weeklyResetWeek = week
		quests.weekly = pickRandomSet(Config.Quests.Weekly, Config.Quests.WeeklyActiveCount)
	end
end

local function templateFor(id, pool)
	for _, template in ipairs(pool) do
		if template.id == id then
			return template
		end
	end
	return nil
end

local function progressSet(player, profile, activeSet, pool, kind, amount)
	for id, entry in pairs(activeSet) do
		if not entry.complete then
			local template = templateFor(id, pool)
			if template and template.kind == kind then
				-- "level" progress is a high-water mark (current level), every
				-- other kind is a delta to accumulate.
				entry.progress = kind == "level" and math.max(entry.progress, amount) or entry.progress + amount
				if entry.progress >= template.target then
					entry.progress = template.target
					entry.complete = true
					profile.embers += template.reward
					if announcementRemote then
						announcementRemote:FireClient(
							player,
							"QUEST COMPLETE",
							string.format("%s -- +%d Embers", template.title, template.reward),
							Color3.fromRGB(246, 190, 77)
						)
					end
				end
			end
		end
	end
end

-- Reports progress toward any active quest matching `kind`. For "level"
-- quests, `amount` is the player's current level; every other kind is a
-- delta to add (e.g. 1 kill, dt/60 minutes survived).
function Quests.Progress(player, kind, amount)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	progressSet(player, profile, profile.quests.daily, Config.Quests.Daily, kind, amount)
	progressSet(player, profile, profile.quests.weekly, Config.Quests.Weekly, kind, amount)
end

return Quests
