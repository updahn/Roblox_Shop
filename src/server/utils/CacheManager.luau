--[[
    统一缓存管理器

    功能特性：
    - 统一管理所有类型的缓存
    - 基于 MessagingService 的跨服务器缓存同步
    - 自动缓存清理和过期处理
    - 支持不同缓存策略（TTL、LRU等）
    - 缓存统计和监控

    使用示例：
        local CacheManager = require(path.to.CacheManager)

        -- 设置缓存
        CacheManager.set("users", "123456", userData, 300) -- TTL 5分钟

        -- 获取缓存
        local cached = CacheManager.get("users", "123456")

        -- 清理特定缓存
        CacheManager.invalidate("users", "123456")

        -- 广播缓存更新
        CacheManager.broadcast("users", "123456", "update")
]]

local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- 环境管理器
local EnvironmentManager = require(script.Parent.EnvironmentManager)

local CacheManager = {}

-- ==============================================
-- 配置常量
-- ==============================================

-- 缓存类型枚举
local CacheType = {
    USER_DATA = "users",               -- 用户基础数据
    USER_INVENTORY = "inventory",      -- 用户库存
    MEMBERSHIP = "membership",         -- 会员状态
    ADMIN_PERMISSIONS = "admin",       -- 管理员权限
    SHOP_ITEMS = "shop_items",         -- 商品信息
    SYSTEM_CONFIG = "system_config",   -- 系统配置
    TRANSACTIONS = "transactions",      -- 交易记录缓存
    DAILY_REWARDS = "daily_rewards"    -- 每日奖励记录
}

-- 默认缓存配置
local DEFAULT_CONFIG = {
    ttl = 300,              -- 默认TTL 5分钟
    maxSize = 1000,         -- 最大缓存条目数
    cleanupInterval = 60,   -- 清理间隔（秒）
    enableBroadcast = true, -- 是否启用跨服务器广播
    enableStats = true      -- 是否启用统计
}

-- 不同缓存类型的专用配置
local CACHE_CONFIGS = {
    [CacheType.USER_DATA] = {
        ttl = 600,              -- 用户数据缓存10分钟
        maxSize = 500,
        enableBroadcast = true
    },
    [CacheType.USER_INVENTORY] = {
        ttl = 300,              -- 库存缓存5分钟
        maxSize = 500,
        enableBroadcast = true
    },
    [CacheType.MEMBERSHIP] = {
        ttl = 300,              -- 会员状态缓存5分钟
        maxSize = 200,
        enableBroadcast = true
    },
    [CacheType.ADMIN_PERMISSIONS] = {
        ttl = 180,              -- 管理员权限缓存3分钟
        maxSize = 50,
        enableBroadcast = true
    },
    [CacheType.SHOP_ITEMS] = {
        ttl = 1800,             -- 商品信息缓存30分钟
        maxSize = 200,
        enableBroadcast = true
    },
    [CacheType.SYSTEM_CONFIG] = {
        ttl = 3600,             -- 系统配置缓存1小时
        maxSize = 100,
        enableBroadcast = true
    },
    [CacheType.TRANSACTIONS] = {
        ttl = 180,              -- 交易记录缓存3分钟
        maxSize = 300,
        enableBroadcast = false  -- 交易记录不需要跨服务器同步
    },
    [CacheType.DAILY_REWARDS] = {
        ttl = 900,              -- 每日奖励缓存15分钟
        maxSize = 200,
        enableBroadcast = true
    }
}

-- ==============================================
-- 内部数据结构
-- ==============================================

-- 缓存存储 {cacheType: {key: cacheEntry}}
local caches = {}

-- 缓存统计
local stats = {
    hits = {},       -- 命中次数
    misses = {},     -- 未命中次数
    sets = {},       -- 设置次数
    invalidations = {}, -- 失效次数
    broadcasts = {},    -- 广播次数
    totalMemory = 0,    -- 总内存使用（估算）
    lastCleanup = 0     -- 上次清理时间
}

-- 服务器标识（用于避免广播回环）
local serverId = HttpService:GenerateGUID(false)

-- 是否启用（在Studio环境中可能禁用MessagingService）
local isEnabled = not EnvironmentManager.isStudio()

-- ==============================================
-- 工具函数
-- ==============================================

-- 创建缓存条目
local function createCacheEntry(value, ttl)
    return {
        value = value,
        createdAt = os.time(),
        expiresAt = os.time() + (ttl or DEFAULT_CONFIG.ttl),
        accessCount = 0,
        lastAccessed = os.time(),
        size = string.len(HttpService:JSONEncode(value))
    }
end

-- 检查缓存条目是否过期
local function isExpired(entry)
    return os.time() > entry.expiresAt
end

-- 初始化缓存类型存储
local function initializeCacheType(cacheType)
    if not caches[cacheType] then
        caches[cacheType] = {}
        stats.hits[cacheType] = 0
        stats.misses[cacheType] = 0
        stats.sets[cacheType] = 0
        stats.invalidations[cacheType] = 0
        stats.broadcasts[cacheType] = 0
    end
end

-- 获取缓存配置
local function getCacheConfig(cacheType)
    local config = CACHE_CONFIGS[cacheType] or {}
    local merged = {}

    -- 合并默认配置
    for key, value in pairs(DEFAULT_CONFIG) do
        merged[key] = config[key] ~= nil and config[key] or value
    end

    return merged
end

-- 估算内存使用
local function updateMemoryStats()
    local totalSize = 0
    for cacheType, cache in pairs(caches) do
        for key, entry in pairs(cache) do
            totalSize = totalSize + entry.size
        end
    end
    stats.totalMemory = totalSize
end

-- ==============================================
-- MessagingService 广播系统
-- ==============================================

-- 广播消息类型
local MessageType = {
    CACHE_UPDATE = "cache_update",      -- 缓存更新
    CACHE_INVALIDATE = "cache_invalidate", -- 缓存失效
    CACHE_CLEAR = "cache_clear",        -- 缓存清空
    SYSTEM_UPDATE = "system_update"     -- 系统更新
}

-- 发送广播消息
local function broadcastMessage(messageType, cacheType, key, data)
    if not isEnabled then
        return false
    end

    local config = getCacheConfig(cacheType)
    if not config.enableBroadcast then
        return false
    end

    local message = {
        type = messageType,
        cacheType = cacheType,
        key = key,
        data = data,
        serverId = serverId,
        timestamp = os.time()
    }

    local success, error = pcall(function()
        MessagingService:PublishAsync("ShopCacheSync", message)
    end)

    if success then
        stats.broadcasts[cacheType] = (stats.broadcasts[cacheType] or 0) + 1
        print("📡 [CacheManager] 广播消息:", messageType, cacheType, key)
        return true
    else
        warn("❌ [CacheManager] 广播失败:", error)
        return false
    end
end

-- 处理接收到的广播消息
local function handleBroadcastMessage(message)
    -- 忽略来自自己的消息
    if message.serverId == serverId then
        return
    end

    local messageType = message.type
    local cacheType = message.cacheType
    local key = message.key
    local data = message.data

    print("📥 [CacheManager] 接收广播:", messageType, cacheType, key)

    if messageType == MessageType.CACHE_UPDATE and data then
        -- 远程缓存更新
        local config = getCacheConfig(cacheType)
        CacheManager.set(cacheType, key, data, config.ttl, false) -- 不再次广播
        print("🔄 [CacheManager] 远程更新缓存:", cacheType, key)

    elseif messageType == MessageType.CACHE_INVALIDATE then
        -- 远程缓存失效
        CacheManager.invalidate(cacheType, key, false) -- 不再次广播
        print("🗑️ [CacheManager] 远程失效缓存:", cacheType, key)

    elseif messageType == MessageType.CACHE_CLEAR then
        -- 远程缓存清空
        CacheManager.clear(cacheType, false) -- 不再次广播
        print("🧹 [CacheManager] 远程清空缓存:", cacheType)

    elseif messageType == MessageType.SYSTEM_UPDATE then
        -- 系统级更新，可以触发特定的处理逻辑
        print("⚡ [CacheManager] 系统更新事件:", data)
        if data and data.action then
            CacheManager.handleSystemUpdate(data.action, data.params)
        end
    end
end

-- ==============================================
-- 核心缓存操作
-- ==============================================

-- 设置缓存
function CacheManager.set(cacheType, key, value, ttl, shouldBroadcast)
    if not cacheType or not key or value == nil then
        warn("❌ [CacheManager] 无效的缓存参数")
        return false
    end

    initializeCacheType(cacheType)
    shouldBroadcast = shouldBroadcast ~= false -- 默认为true

    local config = getCacheConfig(cacheType)
    local actualTtl = ttl or config.ttl
    local entry = createCacheEntry(value, actualTtl)

    -- 检查缓存大小限制
    local currentSize = 0
    for _ in pairs(caches[cacheType]) do
        currentSize = currentSize + 1
    end

    if currentSize >= config.maxSize then
        -- 使用LRU策略清理最旧的条目
        CacheManager.evictLRU(cacheType, 1)
    end

    caches[cacheType][key] = entry
    stats.sets[cacheType] = stats.sets[cacheType] + 1

    -- 广播更新
    if shouldBroadcast and isEnabled then
        broadcastMessage(MessageType.CACHE_UPDATE, cacheType, key, value)
    end

    print("💾 [CacheManager] 设置缓存:", cacheType, key, "TTL:", actualTtl)
    return true
end

-- 获取缓存
function CacheManager.get(cacheType, key)
    if not cacheType or not key then
        return nil
    end

    initializeCacheType(cacheType)

    local entry = caches[cacheType][key]
    if not entry then
        stats.misses[cacheType] = stats.misses[cacheType] + 1
        return nil
    end

    -- 检查是否过期
    if isExpired(entry) then
        caches[cacheType][key] = nil
        stats.misses[cacheType] = stats.misses[cacheType] + 1
        print("⏰ [CacheManager] 缓存已过期:", cacheType, key)
        return nil
    end

    -- 更新访问信息
    entry.accessCount = entry.accessCount + 1
    entry.lastAccessed = os.time()

    stats.hits[cacheType] = stats.hits[cacheType] + 1
    print("📖 [CacheManager] 缓存命中:", cacheType, key)
    return entry.value
end

-- 使缓存失效
function CacheManager.invalidate(cacheType, key, shouldBroadcast)
    if not cacheType or not key then
        return false
    end

    initializeCacheType(cacheType)
    shouldBroadcast = shouldBroadcast ~= false -- 默认为true

    local existed = caches[cacheType][key] ~= nil
    caches[cacheType][key] = nil

    if existed then
        stats.invalidations[cacheType] = stats.invalidations[cacheType] + 1

        -- 广播失效
        if shouldBroadcast and isEnabled then
            broadcastMessage(MessageType.CACHE_INVALIDATE, cacheType, key, nil)
        end

        print("🗑️ [CacheManager] 失效缓存:", cacheType, key)
    end

    return existed
end

-- 清空特定类型的缓存
function CacheManager.clear(cacheType, shouldBroadcast)
    if not cacheType then
        return false
    end

    initializeCacheType(cacheType)
    shouldBroadcast = shouldBroadcast ~= false -- 默认为true

    local count = 0
    for key in pairs(caches[cacheType]) do
        count = count + 1
    end

    caches[cacheType] = {}

    -- 广播清空
    if shouldBroadcast and isEnabled then
        broadcastMessage(MessageType.CACHE_CLEAR, cacheType, nil, nil)
    end

    print("🧹 [CacheManager] 清空缓存:", cacheType, "清理条目:", count)
    return true
end

-- 清空所有缓存
function CacheManager.clearAll()
    local totalCount = 0

    for cacheType in pairs(caches) do
        local count = 0
        for key in pairs(caches[cacheType]) do
            count = count + 1
        end
        totalCount = totalCount + count
        caches[cacheType] = {}
    end

    -- 重置统计
    for cacheType in pairs(stats.hits) do
        stats.hits[cacheType] = 0
        stats.misses[cacheType] = 0
        stats.sets[cacheType] = 0
        stats.invalidations[cacheType] = 0
        stats.broadcasts[cacheType] = 0
    end

    stats.totalMemory = 0

    print("🧹 [CacheManager] 清空所有缓存，清理条目:", totalCount)
    return totalCount
end

-- ==============================================
-- 缓存管理操作
-- ==============================================

-- LRU淘汰策略
function CacheManager.evictLRU(cacheType, count)
    count = count or 1

    if not caches[cacheType] then
        return 0
    end

    local entries = {}
    for key, entry in pairs(caches[cacheType]) do
        table.insert(entries, {key = key, entry = entry})
    end

    -- 按最后访问时间排序
    table.sort(entries, function(a, b)
        return a.entry.lastAccessed < b.entry.lastAccessed
    end)

    local evictedCount = 0
    for i = 1, math.min(count, #entries) do
        local key = entries[i].key
        caches[cacheType][key] = nil
        evictedCount = evictedCount + 1
        print("🗑️ [CacheManager] LRU淘汰:", cacheType, key)
    end

    return evictedCount
end

-- 清理过期缓存
function CacheManager.cleanupExpired()
    local totalCleaned = 0
    local currentTime = os.time()

    for cacheType, cache in pairs(caches) do
        local cleaned = 0
        local keysToRemove = {}

        for key, entry in pairs(cache) do
            if isExpired(entry) then
                table.insert(keysToRemove, key)
            end
        end

        for _, key in ipairs(keysToRemove) do
            cache[key] = nil
            cleaned = cleaned + 1
        end

        if cleaned > 0 then
            print("🧹 [CacheManager] 清理过期缓存:", cacheType, "清理数量:", cleaned)
        end

        totalCleaned = totalCleaned + cleaned
    end

    stats.lastCleanup = currentTime
    updateMemoryStats()

    if totalCleaned > 0 then
        print("✅ [CacheManager] 总计清理过期缓存:", totalCleaned)
    end

    return totalCleaned
end

-- ==============================================
-- 特殊缓存操作
-- ==============================================

-- 刷新用户相关的所有缓存
function CacheManager.refreshUserCache(userId)
    local userCacheTypes = {
        CacheType.USER_DATA,
        CacheType.USER_INVENTORY,
        CacheType.MEMBERSHIP,
        CacheType.DAILY_REWARDS
    }

    local clearedCount = 0
    for _, cacheType in ipairs(userCacheTypes) do
        if CacheManager.invalidate(cacheType, userId) then
            clearedCount = clearedCount + 1
        end
    end

    print("🔄 [CacheManager] 刷新用户缓存:", userId, "清理项目:", clearedCount)
    return clearedCount
end

-- 刷新商店相关缓存
function CacheManager.refreshShopCache()
    CacheManager.clear(CacheType.SHOP_ITEMS)

    -- 广播系统更新事件
    if isEnabled then
        broadcastMessage(MessageType.SYSTEM_UPDATE, "system", "shop_refresh", {
            action = "shop_refresh",
            timestamp = os.time()
        })
    end

    print("🛒 [CacheManager] 刷新商店缓存")
end

-- 处理系统更新事件
function CacheManager.handleSystemUpdate(action, params)
    if action == "shop_refresh" then
        -- 商店刷新：清空相关缓存
        CacheManager.clear(CacheType.SHOP_ITEMS, false) -- 避免循环广播
        print("🛒 [CacheManager] 处理商店刷新事件")

    elseif action == "user_logout" and params and params.userId then
        -- 用户登出：清理用户缓存
        CacheManager.refreshUserCache(params.userId)
        print("👤 [CacheManager] 处理用户登出事件:", params.userId)

    elseif action == "admin_update" then
        -- 管理员更新：清空管理员权限缓存
        CacheManager.clear(CacheType.ADMIN_PERMISSIONS, false)
        print("👑 [CacheManager] 处理管理员权限更新事件")

    elseif action == "config_update" then
        -- 配置更新：清空系统配置缓存
        CacheManager.clear(CacheType.SYSTEM_CONFIG, false)
        print("⚙️ [CacheManager] 处理系统配置更新事件")
    end
end

-- ==============================================
-- 统计和监控
-- ==============================================

-- 获取缓存统计信息
function CacheManager.getStats()
    updateMemoryStats()

    local detailedStats = {}
    for cacheType in pairs(caches) do
        local cache = caches[cacheType]
        local count = 0
        local expiredCount = 0

        for key, entry in pairs(cache) do
            count = count + 1
            if isExpired(entry) then
                expiredCount = expiredCount + 1
            end
        end

        detailedStats[cacheType] = {
            count = count,
            expired = expiredCount,
            hits = stats.hits[cacheType] or 0,
            misses = stats.misses[cacheType] or 0,
            sets = stats.sets[cacheType] or 0,
            invalidations = stats.invalidations[cacheType] or 0,
            broadcasts = stats.broadcasts[cacheType] or 0,
            hitRate = (stats.hits[cacheType] or 0) / math.max(1, (stats.hits[cacheType] or 0) + (stats.misses[cacheType] or 0))
        }
    end

    return {
        caches = detailedStats,
        totalMemory = stats.totalMemory,
        lastCleanup = stats.lastCleanup,
        serverId = serverId,
        isEnabled = isEnabled
    }
end

-- 打印缓存统计信息
function CacheManager.printStats()
    local stats = CacheManager.getStats()

    print("=" .. string.rep("=", 60))
    print("📊 缓存管理器统计信息")
    print("=" .. string.rep("=", 60))
    print("服务器ID:", stats.serverId)
    print("启用状态:", stats.isEnabled and "是" or "否")
    print("总内存使用:", math.floor(stats.totalMemory / 1024), "KB")
    print("上次清理:", os.date("%Y-%m-%d %H:%M:%S", stats.lastCleanup))
    print("")

    for cacheType, cacheStat in pairs(stats.caches) do
        print(string.format("📦 %s:", cacheType))
        print(string.format("  条目数: %d (过期: %d)", cacheStat.count, cacheStat.expired))
        print(string.format("  命中率: %.1f%% (%d/%d)", cacheStat.hitRate * 100, cacheStat.hits, cacheStat.hits + cacheStat.misses))
        print(string.format("  操作数: 设置=%d, 失效=%d, 广播=%d", cacheStat.sets, cacheStat.invalidations, cacheStat.broadcasts))
        print("")
    end
    print("=" .. string.rep("=", 60))
end

-- ==============================================
-- 模块初始化和清理
-- ==============================================

-- 初始化模块
function CacheManager.initialize()
    print("🚀 [CacheManager] 初始化缓存管理器...")

    -- 设置MessagingService监听器
    if isEnabled then
        local success, connection = pcall(function()
            return MessagingService:SubscribeAsync("ShopCacheSync", function(message)
                handleBroadcastMessage(message.Data)
            end)
        end)

        if success then
            print("✅ [CacheManager] MessagingService 监听器已启动")
        else
            warn("❌ [CacheManager] MessagingService 启动失败:", connection)
            isEnabled = false
        end
    else
        print("⚠️ [CacheManager] Studio环境，跳过MessagingService初始化")
    end

    -- 启动清理任务
    spawn(function()
        while true do
            wait(DEFAULT_CONFIG.cleanupInterval)
            CacheManager.cleanupExpired()
        end
    end)

    -- 启动统计任务（每5分钟打印一次统计）
    if EnvironmentManager.isStudio() then
        spawn(function()
            while true do
                wait(300) -- 5分钟
                CacheManager.printStats()
            end
        end)
    end

    print("✅ [CacheManager] 缓存管理器初始化完成")
end

-- 关闭模块
function CacheManager.shutdown()
    print("🛑 [CacheManager] 关闭缓存管理器...")

    -- 清空所有缓存
    CacheManager.clearAll()

    print("✅ [CacheManager] 缓存管理器已关闭")
end

-- ==============================================
-- 导出接口
-- ==============================================

-- 导出缓存类型常量
CacheManager.Types = CacheType

-- 导出消息类型常量
CacheManager.MessageType = MessageType

-- 启动初始化
spawn(function()
    wait(1) -- 等待其他服务启动
    CacheManager.initialize()
end)

return CacheManager
