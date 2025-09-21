-- 数据持久化管理器

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataManager = {}

-- 数据存储配置
local DATA_STORE_NAME = "PlayerShopData"
local SAVE_INTERVAL = 30 -- 每30秒自动保存一次

-- 检测是否在Studio环境中
local isStudio = RunService:IsStudio()
local playerDataStore = nil
local mockDataStore = {} -- Studio环境中的模拟数据存储

if isStudio then
    print("⚠️ 检测到Studio环境，使用模拟数据存储")
else
    playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
end

-- 玩家数据缓存
local playerDataCache = {}
local lastSaveTime = {}

-- 获取玩家数据
function DataManager.getPlayerData(player: Player)
    if playerDataCache[player.UserId] then
        return playerDataCache[player.UserId]
    end
    return nil
end

-- 设置玩家数据
function DataManager.setPlayerData(player: Player, data)
    playerDataCache[player.UserId] = data
    lastSaveTime[player.UserId] = tick()
end

-- 从数据存储加载玩家数据
function DataManager.loadPlayerData(player: Player, defaultData)
    local success, data = false, nil

    if isStudio then
        -- Studio环境：使用模拟数据存储
        data = mockDataStore[tostring(player.UserId)]
        success = true
    else
        -- 生产环境：使用真实数据存储
        success, data = pcall(function()
            return playerDataStore:GetAsync(tostring(player.UserId))
        end)
    end

    if success and data then
        playerDataCache[player.UserId] = data
        print("✅ 成功加载玩家 " .. player.Name .. " 的数据")
    else
        playerDataCache[player.UserId] = defaultData
        print("📝 为玩家 " .. player.Name .. " 创建新数据")
    end

    lastSaveTime[player.UserId] = tick()
    return playerDataCache[player.UserId]
end

-- 保存玩家数据到数据存储
function DataManager.savePlayerData(player: Player)
    if not playerDataCache[player.UserId] then
        return false
    end

    local success, error = false, nil

    if isStudio then
        -- Studio环境：使用模拟数据存储
        mockDataStore[tostring(player.UserId)] = playerDataCache[player.UserId]
        success = true
    else
        -- 生产环境：使用真实数据存储
        success, error = pcall(function()
            playerDataStore:SetAsync(tostring(player.UserId), playerDataCache[player.UserId])
        end)
    end

    if success then
        print("💾 成功保存玩家 " .. player.Name .. " 的数据")
        return true
    else
        warn("❌ 保存玩家 " .. player.Name .. " 数据失败: " .. tostring(error))
        return false
    end
end

-- 强制保存所有玩家数据
function DataManager.saveAllPlayerData()
    for userId, data in pairs(playerDataCache) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            DataManager.savePlayerData(player)
        end
    end
end

-- 清理玩家数据缓存
function DataManager.clearPlayerData(player: Player)
    if playerDataCache[player.UserId] then
        DataManager.savePlayerData(player)
        playerDataCache[player.UserId] = nil
        lastSaveTime[player.UserId] = nil
    end
end

-- 自动保存系统
local function startAutoSave()
    spawn(function()
        while true do
            wait(SAVE_INTERVAL)

            local currentTime = tick()
            for userId, lastSave in pairs(lastSaveTime) do
                if currentTime - lastSave >= SAVE_INTERVAL then
                    local player = Players:GetPlayerByUserId(userId)
                    if player then
                        DataManager.savePlayerData(player)
                    end
                end
            end
        end
    end)
end

-- 玩家离开时保存数据
Players.PlayerRemoving:Connect(function(player)
    DataManager.clearPlayerData(player)
end)

-- 游戏关闭时保存所有数据
game:BindToClose(function()
    DataManager.saveAllPlayerData()
    wait(2) -- 等待保存完成
end)

-- 启动自动保存
startAutoSave()


return DataManager
