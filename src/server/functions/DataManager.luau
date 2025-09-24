-- 数据持久化管理器
-- 集成缓存系统，提供高效的玩家数据管理
-- 支持自动保存、缓存管理和数据持久化

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

-- 导入缓存服务
local CacheService = nil -- 延迟加载避免循环依赖

-- 获取缓存服务（延迟初始化）
local function getCacheService()
    if not CacheService then
        CacheService = require(game:GetService("ServerScriptService").Server.services.CacheService)
    end
    return CacheService
end

-- 玩家数据保存时间记录
local lastSaveTime = {}

-- 获取玩家数据
function DataManager.getPlayerData(player: Player)
    local cacheService = getCacheService()
    local userId = tostring(player.UserId)
    return cacheService.getUserData(userId)
end

-- 设置玩家数据
function DataManager.setPlayerData(player: Player, data)
    local cacheService = getCacheService()
    local userId = tostring(player.UserId)
    cacheService.cacheUserData(userId, data, 600) -- 缓存10分钟
    lastSaveTime[player.UserId] = tick()
end

-- 从数据存储加载玩家数据
function DataManager.loadPlayerData(player: Player, defaultData)
    local success, data = false, nil
    local userId = tostring(player.UserId)

    if isStudio then
        -- Studio环境：使用模拟数据存储
        data = mockDataStore[userId]
        success = true
    else
        -- 生产环境：使用真实数据存储
        success, data = pcall(function()
            return playerDataStore:GetAsync(userId)
        end)
    end

    local finalData
    if success and data then
        finalData = data
        print("✅ 成功加载玩家 " .. player.Name .. " 的数据")
    else
        finalData = defaultData
        print("📝 为玩家 " .. player.Name .. " 创建新数据")
    end

    -- 缓存数据
    local cacheService = getCacheService()
    cacheService.cacheUserData(userId, finalData, 600) -- 缓存10分钟

    lastSaveTime[player.UserId] = tick()
    return finalData
end

-- 保存玩家数据到数据存储
function DataManager.savePlayerData(player: Player)
    local cacheService = getCacheService()
    local userId = tostring(player.UserId)
    local cachedData = cacheService.getUserData(userId)

    if not cachedData then
        return false
    end

    local success, error = false, nil

    if isStudio then
        -- Studio环境：使用模拟数据存储
        mockDataStore[userId] = cachedData
        success = true
    else
        -- 生产环境：使用真实数据存储
        success, error = pcall(function()
            playerDataStore:SetAsync(userId, cachedData)
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
    local cacheService = getCacheService()
    local allCachedUsers = cacheService.getAllCachedUsers()

    for _, userId in ipairs(allCachedUsers) do
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            DataManager.savePlayerData(player)
        end
    end
end

-- 清理玩家数据缓存
function DataManager.clearPlayerData(player: Player)
    local cacheService = getCacheService()
    local userId = tostring(player.UserId)
    local userData = cacheService.getUserData(userId)

    if userData then
        -- 先保存数据再清理
        DataManager.savePlayerData(player)
        cacheService.clearUserData(userId)
        lastSaveTime[player.UserId] = nil
        print("🧹 清理玩家 " .. player.Name .. " 的缓存数据")
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
