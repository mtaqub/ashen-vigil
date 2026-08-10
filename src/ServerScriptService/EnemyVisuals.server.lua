local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MobModelFactory = require(script.Parent:WaitForChild("MobModelFactory"))

local enemyIdByName = {}
for enemyId, enemyConfig in pairs(Config.Enemies) do
	enemyIdByName[enemyConfig.Name] = enemyId
end

local watchedArenas = setmetatable({}, { __mode = "k" })
local watchedEnemyFolders = setmetatable({}, { __mode = "k" })

local function decorateEnemy(root)
	if not root:IsA("BasePart") then
		return
	end
	local enemyId = enemyIdByName[root.Name]
	if not enemyId then
		return
	end

	task.defer(function()
		if not root.Parent then
			return
		end
		local ok, result = pcall(MobModelFactory.Attach, root, enemyId)
		if not ok then
			warn("Ashen Vigil enemy visual failed for " .. root.Name .. ": " .. tostring(result))
		end
	end)
end

local function watchEnemyFolder(enemyFolder)
	if watchedEnemyFolders[enemyFolder] then
		return
	end
	watchedEnemyFolders[enemyFolder] = true

	for _, child in ipairs(enemyFolder:GetChildren()) do
		decorateEnemy(child)
	end
	enemyFolder.ChildAdded:Connect(decorateEnemy)
end

local function watchArena(arena)
	if watchedArenas[arena] or arena.Name ~= "AshenVigilArena" then
		return
	end
	watchedArenas[arena] = true

	local existingEnemyFolder = arena:FindFirstChild("Enemies")
	if existingEnemyFolder then
		watchEnemyFolder(existingEnemyFolder)
	end
	arena.ChildAdded:Connect(function(child)
		if child.Name == "Enemies" then
			watchEnemyFolder(child)
		end
	end)
end

for _, child in ipairs(workspace:GetChildren()) do
	watchArena(child)
end
workspace.ChildAdded:Connect(watchArena)
