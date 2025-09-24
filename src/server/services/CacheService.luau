--[[
    缓存服务 - 统一缓存操作接口

    本服务是 CacheManager 的高级包装器，提供：
    - 简化的缓存操作接口
    - 与现有服务的集成
    - 缓存事件处理
    - 客户端通知功能
    - 管理员缓存管理功能

    使用示例：
        local CacheService = require(path.to.CacheService)

        -- 缓存用户数据
        CacheService.cacheUserData(userId, userData)

        -- 获取用户数据
        local userData = CacheService.getUserData(userId)

        -- 刷新用户缓存
        CacheService.refreshUserCache(userId)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 导入依赖
local function getCacheManager()
    local ServerScriptService = game:GetService("ServerScriptService")
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    if serverFolder then
        local srcFolder = serverFolder.Parent
        local utilsFolder = srcFolder:FindFirstChild("utils")
        if utilsFolder and utilsFolder:FindFirstChild("CacheManager") then
            return require(utilsFolder.CacheManager)
        end
    end
    error("❌ 无法加载CacheManager模块")
end

local CacheManager = getCacheManager()
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Events = require(SharedModules:WaitForChild("ShopEvents"))

local CacheService = {}

-- ==============================================
-- 用户数据缓存操作
-- ==============================================

-- 缓存用户基础数据
function CacheService.cacheUserData(userId, userData, ttl)
    local success = CacheManager.set(CacheManager.Types.USER_DATA, userId, userData, ttl)
    if success then
        -- 通知客户端用户数据已更新
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            Events.Cache.UserDataUpdated:FireClient(player, {
                type = "user_data",
                userId = userId,
                timestamp = os.time()
            })
        end
    end
    return success
end

-- 获取用户基础数据
function CacheService.getUserData(userId)
    return CacheManager.get(CacheManager.Types.USER_DATA, userId)
end

-- 缓存用户库存数据
function CacheService.cacheUserInventory(userId, inventory, ttl)
    local success = CacheManager.set(CacheManager.Types.USER_INVENTORY, userId, inventory, ttl)
    if success then
        -- 通知客户端库存已更新
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            Events.Cache.UserDataUpdated:FireClient(player, {
                type = "inventory",
                userId = userId,
                timestamp = os.time()
            })
        end
    end
    return success
end

-- 获取用户库存数据
function CacheService.getUserInventory(userId)
    return CacheManager.get(CacheManager.Types.USER_INVENTORY, userId)
end

-- 缓存用户会员状态
function CacheService.cacheMembershipStatus(userId, membership, ttl)
    local success = CacheManager.set(CacheManager.Types.MEMBERSHIP, userId, membership, ttl)
    if success then
        -- 通知客户端会员状态已更新
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            Events.Cache.MembershipUpdated:FireClient(player, {
                type = "membership",
                userId = userId,
                membership = membership,
                timestamp = os.time()
            })
        end
    end
    return success
end

-- 获取用户会员状态
function CacheService.getMembershipStatus(userId)
    return CacheManager.get(CacheManager.Types.MEMBERSHIP, userId)
end

-- 缓存用户每日奖励记录
function CacheService.cacheDailyRewards(userId, rewards, ttl)
    return CacheManager.set(CacheManager.Types.DAILY_REWARDS, userId, rewards, ttl)
end

-- 获取用户每日奖励记录
function CacheService.getDailyRewards(userId)
    return CacheManager.get(CacheManager.Types.DAILY_REWARDS, userId)
end

-- 刷新用户相关的所有缓存
function CacheService.refreshUserCache(userId, notifyClient)
    notifyClient = notifyClient ~= false -- 默认为true

    local clearedCount = CacheManager.refreshUserCache(userId)

    if notifyClient then
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            Events.Cache.DataRefreshNotify:FireClient(player, {
                type = "user_refresh",
                userId = userId,
                clearedCount = clearedCount,
                timestamp = os.time()
            })
        end
    end

    return clearedCount
end

-- ==============================================
-- 商店数据缓存操作
-- ==============================================

-- 缓存商品数据
function CacheService.cacheShopItems(items, ttl)
    local success = CacheManager.set(CacheManager.Types.SHOP_ITEMS, "all_items", items, ttl)
    if success then
        -- 通知所有在线客户端商店数据已更新
        for _, player in pairs(Players:GetPlayers()) do
            Events.Cache.ShopDataUpdated:FireClient(player, {
                type = "shop_items",
                itemCount = 0, -- 可以设置实际数量
                timestamp = os.time()
            })
        end
    end
    return success
end

-- 获取商品数据
function CacheService.getShopItems()
    return CacheManager.get(CacheManager.Types.SHOP_ITEMS, "all_items")
end

-- 缓存单个商品数据
function CacheService.cacheShopItem(itemId, itemData, ttl)
    return CacheManager.set(CacheManager.Types.SHOP_ITEMS, itemId, itemData, ttl)
end

-- 获取单个商品数据
function CacheService.getShopItem(itemId)
    return CacheManager.get(CacheManager.Types.SHOP_ITEMS, itemId)
end

-- 刷新商店缓存
function CacheService.refreshShopCache(notifyClients)
    notifyClients = notifyClients ~= false -- 默认为true

    CacheManager.refreshShopCache()

    if notifyClients then
        for _, player in pairs(Players:GetPlayers()) do
            Events.Cache.DataRefreshNotify:FireClient(player, {
                type = "shop_refresh",
                timestamp = os.time()
            })
        end
    end
end

-- ==============================================
-- 管理员权限缓存操作
-- ==============================================

-- 缓存管理员权限
function CacheService.cacheAdminPermission(userId, isAdmin, ttl)
    return CacheManager.set(CacheManager.Types.ADMIN_PERMISSIONS, userId, isAdmin, ttl)
end

-- 获取管理员权限
function CacheService.getAdminPermission(userId)
    return CacheManager.get(CacheManager.Types.ADMIN_PERMISSIONS, userId)
end

-- 刷新管理员权限缓存
function CacheService.refreshAdminCache()
    CacheManager.clear(CacheManager.Types.ADMIN_PERMISSIONS)
    print("👑 [CacheService] 管理员权限缓存已刷新")
end

-- ==============================================
-- 系统配置缓存操作
-- ==============================================

-- 缓存系统配置
function CacheService.cacheSystemConfig(configKey, configValue, ttl)
    local success = CacheManager.set(CacheManager.Types.SYSTEM_CONFIG, configKey, configValue, ttl)
    if success then
        -- 通知所有客户端系统配置已更新
        for _, player in pairs(Players:GetPlayers()) do
            Events.Cache.SystemConfigUpdated:FireClient(player, {
                configKey = configKey,
                timestamp = os.time()
            })
        end
    end
    return success
end

-- 获取系统配置
function CacheService.getSystemConfig(configKey)
    return CacheManager.get(CacheManager.Types.SYSTEM_CONFIG, configKey)
end

-- 刷新系统配置缓存
function CacheService.refreshSystemConfig()
    CacheManager.clear(CacheManager.Types.SYSTEM_CONFIG)

    for _, player in pairs(Players:GetPlayers()) do
        Events.Cache.DataRefreshNotify:FireClient(player, {
            type = "config_refresh",
            timestamp = os.time()
        })
    end

    print("⚙️ [CacheService] 系统配置缓存已刷新")
end

-- ==============================================
-- 交易记录缓存操作
-- ==============================================

-- 缓存用户交易记录
function CacheService.cacheUserTransactions(userId, transactions, ttl)
    return CacheManager.set(CacheManager.Types.TRANSACTIONS, "user_" .. userId, transactions, ttl)
end

-- 获取用户交易记录
function CacheService.getUserTransactions(userId)
    return CacheManager.get(CacheManager.Types.TRANSACTIONS, "user_" .. userId)
end

-- ==============================================
-- 批量操作和特殊功能
-- ==============================================

-- 批量刷新多个用户的缓存
function CacheService.batchRefreshUserCache(userIds, notifyClients)
    notifyClients = notifyClients ~= false -- 默认为true

    local totalCleared = 0
    for _, userId in ipairs(userIds) do
        totalCleared = totalCleared + CacheService.refreshUserCache(userId, false)
    end

    -- 批量通知客户端
    if notifyClients then
        for _, userId in ipairs(userIds) do
            local player = Players:GetPlayerByUserId(tonumber(userId))
            if player then
                Events.Cache.DataRefreshNotify:FireClient(player, {
                    type = "batch_refresh",
                    userId = userId,
                    timestamp = os.time()
                })
            end
        end
    end

    print("🔄 [CacheService] 批量刷新用户缓存，用户数:", #userIds, "清理项目:", totalCleared)
    return totalCleared
end

-- 全局数据刷新（管理员功能）
function CacheService.globalRefresh()
    local stats = CacheManager.getStats()
    local totalCleared = CacheManager.clearAll()

    -- 通知所有客户端进行全局刷新
    for _, player in pairs(Players:GetPlayers()) do
        Events.Cache.DataRefreshNotify:FireClient(player, {
            type = "global_refresh",
            clearedCount = totalCleared,
            timestamp = os.time()
        })
    end

    print("🌐 [CacheService] 全局缓存刷新，清理项目:", totalCleared)
    return totalCleared
end

-- 预热缓存（在服务器启动时预加载常用数据）
function CacheService.warmupCache()
    print("🔥 [CacheService] 开始预热缓存...")

    -- 这里可以预加载一些常用数据，比如：
    -- - 商品信息
    -- - 系统配置
    -- - 在线用户的基础数据

    spawn(function()
        -- 预热商品数据
        local DataStoreManager = require(game:GetService("ServerScriptService").Server.datastoreservice.DataStoreManager)
        local shopItems = DataStoreManager.getAllItems()
        if shopItems then
            CacheService.cacheShopItems(shopItems, 1800) -- 30分钟
            print("🛒 [CacheService] 商品数据已预热")
        end

        -- 预热系统配置
        local allConfigs = DataStoreManager.getAllSystemConfig()
        if allConfigs then
            for key, config in pairs(allConfigs) do
                CacheService.cacheSystemConfig(key, config, 3600) -- 1小时
            end
            print("⚙️ [CacheService] 系统配置已预热")
        end

        -- 预热在线用户数据
        for _, player in pairs(Players:GetPlayers()) do
            local userId = tostring(player.UserId)
            local userData = DataStoreManager.getUserData(userId)
            if userData then
                CacheService.cacheUserData(userId, userData, 600) -- 10分钟
            end
        end
        print("👤 [CacheService] 在线用户数据已预热")
    end)

    print("✅ [CacheService] 缓存预热任务已启动")
end

-- ==============================================
-- 事件处理器
-- ==============================================

-- 处理客户端强制刷新请求
local function handleForceRefresh(player, refreshType, targetId)
    local userId = tostring(player.UserId)

    print("🔄 [CacheService] 收到强制刷新请求:", player.Name, refreshType, targetId)

    if refreshType == "user" then
        -- 刷新用户自己的缓存
        CacheService.refreshUserCache(userId)

    elseif refreshType == "shop" then
        -- 刷新商店缓存（需要管理员权限）
        local AdminService = require(game:GetService("ServerScriptService").Server.services.AdminService)
        if AdminService.isValidAdmin(player) then
            CacheService.refreshShopCache()
        else
            print("⚠️ [CacheService] 非管理员尝试刷新商店缓存:", player.Name)
        end

    elseif refreshType == "config" then
        -- 刷新系统配置缓存（需要管理员权限）
        local AdminService = require(game:GetService("ServerScriptService").Server.services.AdminService)
        if AdminService.isValidAdmin(player) then
            CacheService.refreshSystemConfig()
        else
            print("⚠️ [CacheService] 非管理员尝试刷新系统配置:", player.Name)
        end

    elseif refreshType == "all" then
        -- 全局刷新（需要管理员权限）
        local AdminService = require(game:GetService("ServerScriptService").Server.services.AdminService)
        if AdminService.isValidAdmin(player) then
            CacheService.globalRefresh()
        else
            print("⚠️ [CacheService] 非管理员尝试全局刷新:", player.Name)
        end
    end
end

-- 处理缓存统计信息请求
local function handleGetCacheStats(player)
    -- 需要管理员权限
    local AdminService = require(game:GetService("ServerScriptService").Server.services.AdminService)
    if not AdminService.isValidAdmin(player) then
        return {
            success = false,
            error = "权限不足"
        }
    end

    local stats = CacheManager.getStats()
    return {
        success = true,
        stats = stats
    }
end

-- 处理缓存管理操作
local function handleManageCache(player, action, params)
    -- 需要管理员权限
    local AdminService = require(game:GetService("ServerScriptService").Server.services.AdminService)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [CacheService] 非管理员尝试缓存管理操作:", player.Name, action)
        return
    end

    print("👑 [CacheService] 管理员缓存操作:", player.Name, action)

    if action == "clear_user" and params.userId then
        CacheService.refreshUserCache(params.userId)

    elseif action == "clear_type" and params.cacheType then
        CacheManager.clear(params.cacheType)

    elseif action == "clear_all" then
        CacheService.globalRefresh()

    elseif action == "warmup" then
        CacheService.warmupCache()

    elseif action == "cleanup" then
        CacheManager.cleanupExpired()

    elseif action == "stats" then
        CacheManager.printStats()

    else
        print("⚠️ [CacheService] 未知的缓存管理操作:", action)
    end
end

-- ==============================================
-- 玩家连接和断开处理
-- ==============================================

-- 处理玩家加入
function CacheService.onPlayerAdded(player)
    local userId = tostring(player.UserId)
    print("👤 [CacheService] 玩家加入，准备预热缓存:", player.Name)

    -- 异步预热用户数据
    spawn(function()
        wait(2) -- 等待玩家完全加载

        -- 预热用户基础数据
        local DataStoreManager = require(game:GetService("ServerScriptService").Server.datastoreservice.DataStoreManager)
        local userData = DataStoreManager.getUserData(userId)
        if userData then
            CacheService.cacheUserData(userId, userData)
            print("✅ [CacheService] 预热用户数据:", player.Name)
        end
    end)
end

-- 处理玩家离开
function CacheService.onPlayerRemoving(player)
    local userId = tostring(player.UserId)
    print("👤 [CacheService] 玩家离开，清理缓存:", player.Name)

    -- 延迟清理用户缓存（给其他服务器一些时间来同步数据）
    spawn(function()
        wait(300) -- 5分钟后清理
        CacheService.refreshUserCache(userId, false) -- 不通知客户端
        print("🧹 [CacheService] 已清理离线用户缓存:", userId)
    end)
end

-- ==============================================
-- 模块初始化
-- ==============================================

function CacheService.initialize()
    print("🚀 [CacheService] 初始化缓存服务...")

    -- 连接事件处理器
    Events.Cache.ForceRefresh.OnServerEvent:Connect(handleForceRefresh)
    Events.Cache.GetCacheStats.OnServerInvoke = handleGetCacheStats
    Events.Cache.ManageCache.OnServerEvent:Connect(handleManageCache)

    -- 连接玩家事件
    Players.PlayerAdded:Connect(CacheService.onPlayerAdded)
    Players.PlayerRemoving:Connect(CacheService.onPlayerRemoving)

    -- 启动缓存预热
    spawn(function()
        wait(5) -- 等待其他服务初始化完成
        CacheService.warmupCache()
    end)

    print("✅ [CacheService] 缓存服务初始化完成")
end

-- ==============================================
-- 导出接口
-- ==============================================

-- 导出缓存类型常量
CacheService.Types = CacheManager.Types

-- 导出底层CacheManager引用（高级用法）
CacheService.Manager = CacheManager

-- 启动初始化
spawn(function()
    wait(2) -- 等待CacheManager初始化
    CacheService.initialize()
end)

return CacheService
