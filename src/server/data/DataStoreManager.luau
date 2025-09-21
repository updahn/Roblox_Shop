-- DataStore 管理器 - 替换 MySQL 和 API 调用
-- 统一管理所有数据存储操作，支持普通用户和管理员分离权限

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- 环境管理器
local EnvironmentManager = require(script.Parent.Parent.utils.EnvironmentManager)

local DataStoreManager = {}

-- ==============================================
-- DataStore 配置
-- ==============================================

-- 环境检测和配置
local isStudio = EnvironmentManager.isStudio()
local dataStoreConfig = EnvironmentManager.getDataStoreConfig()

-- DataStore 实例
local dataStores = {}
local mockDataStores = {} -- Studio环境中的模拟数据存储

-- DataStore 名称配置
local DATASTORE_NAMES = {
    USERS = "ShopUserData_v3",              -- 用户数据
    SYSTEM_CONFIG = "ShopSystemConfig_v3",   -- 系统配置
    ITEMS = "ShopItemData_v3",              -- 商品数据
    TRANSACTIONS = "ShopTransactions_v3",    -- 交易记录
    MEMBERSHIPS = "ShopMemberships_v3",     -- 会员数据
    ADMIN_DATA = "ShopAdminData_v3",        -- 管理员数据
    SYSTEM_STATS = "ShopSystemStats_v3",    -- 系统统计
    DAILY_REWARDS = "ShopDailyRewards_v3"   -- 每日奖励记录
}

-- 初始化 DataStores
local function initializeDataStores()
    local currentEnv = EnvironmentManager.getCurrentEnvironment()

    if dataStoreConfig.mockData or not dataStoreConfig.enabled then
        print("⚠️ " .. currentEnv .. "环境 - 使用模拟DataStore")
        -- 初始化模拟存储
        for name, storeName in pairs(DATASTORE_NAMES) do
            mockDataStores[name] = {}
        end
    else
        print("🚀 " .. currentEnv .. "环境 - 初始化DataStore")
        -- 初始化真实DataStore
        for name, storeName in pairs(DATASTORE_NAMES) do
            local success, dataStore = pcall(function()
                return DataStoreService:GetDataStore(storeName)
            end)

            if success then
                dataStores[name] = dataStore
                print("✅ DataStore 初始化成功:", storeName)
            else
                warn("❌ DataStore 初始化失败:", storeName, dataStore)
                -- 在初始化失败时，回退到模拟模式
                if not mockDataStores[name] then
                    mockDataStores[name] = {}
                    print("🔄 回退到模拟DataStore:", storeName)
                end
            end
        end
    end
end

-- ==============================================
-- 通用数据操作函数
-- ==============================================

-- 安全的数据获取（支持重试机制）
local function safeGetAsync(dataStore, key, defaultValue, maxRetries)
    maxRetries = maxRetries or dataStoreConfig.retryAttempts

    if isStudio then
        -- Studio环境
        return mockDataStores[dataStore][key] or defaultValue
    else
        -- 生产环境 - 带重试机制
        for attempt = 1, maxRetries do
            local success, data = pcall(function()
                return dataStores[dataStore]:GetAsync(key)
            end)

            if success then
                return data or defaultValue
            else
                warn("❌ 数据获取失败 (尝试 " .. attempt .. "/" .. maxRetries .. "):", dataStore, key, data)

                -- 如果是请求限制错误，等待更长时间
                if string.find(tostring(data), "throttled") or string.find(tostring(data), "limit") then
                    wait(attempt * 2) -- 递增等待时间
                else
                    wait(attempt * 0.5) -- 其他错误较短等待
                end

                -- 最后一次尝试失败后记录错误
                if attempt == maxRetries then
                    -- 记录错误到系统日志（如果可用）
                    spawn(function()
                        local success2, AdminDataService = pcall(function()
                            return require(script.Parent:WaitForChild("AdminDataService"))
                        end)
                        if success2 then
                            AdminDataService.logAdminAction("SYSTEM", "datastore_error", {
                                operation = "GetAsync",
                                datastore = dataStore,
                                key = key,
                                error = tostring(data),
                                attempts = maxRetries
                            })
                        end
                    end)
                end
            end
        end

        return defaultValue
    end
end

-- 安全的数据保存（支持重试机制）
local function safeSetAsync(dataStore, key, value, maxRetries)
    maxRetries = maxRetries or dataStoreConfig.retryAttempts

    if isStudio then
        -- Studio环境
        mockDataStores[dataStore][key] = value
        return true
    else
        -- 生产环境 - 带重试机制
        for attempt = 1, maxRetries do
            local success, error = pcall(function()
                dataStores[dataStore]:SetAsync(key, value)
            end)

            if success then
                return true
            else
                warn("❌ 数据保存失败 (尝试 " .. attempt .. "/" .. maxRetries .. "):", dataStore, key, error)

                -- 如果是请求限制错误，等待更长时间
                if string.find(tostring(error), "throttled") or string.find(tostring(error), "limit") then
                    wait(attempt * 2) -- 递增等待时间
                else
                    wait(attempt * 0.5) -- 其他错误较短等待
                end

                -- 最后一次尝试失败后记录错误
                if attempt == maxRetries then
                    spawn(function()
                        local success2, AdminDataService = pcall(function()
                            return require(script.Parent:WaitForChild("AdminDataService"))
                        end)
                        if success2 then
                            AdminDataService.logAdminAction("SYSTEM", "datastore_error", {
                                operation = "SetAsync",
                                datastore = dataStore,
                                key = key,
                                error = tostring(error),
                                attempts = maxRetries
                            })
                        end
                    end)
                end
            end
        end

        return false
    end
end

-- 安全的数据更新（使用 UpdateAsync，支持重试机制）
local function safeUpdateAsync(dataStore, key, updateFunction, maxRetries)
    maxRetries = maxRetries or dataStoreConfig.retryAttempts

    if isStudio then
        -- Studio环境模拟UpdateAsync
        local currentData = mockDataStores[dataStore][key]
        local newData = updateFunction(currentData)
        mockDataStores[dataStore][key] = newData
        return true, newData
    else
        -- 生产环境 - 带重试机制
        for attempt = 1, maxRetries do
            local success, result = pcall(function()
                return dataStores[dataStore]:UpdateAsync(key, updateFunction)
            end)

            if success then
                return true, result
            else
                warn("❌ 数据更新失败 (尝试 " .. attempt .. "/" .. maxRetries .. "):", dataStore, key, result)

                -- 如果是请求限制错误，等待更长时间
                if string.find(tostring(result), "throttled") or string.find(tostring(result), "limit") then
                    wait(attempt * 2) -- 递增等待时间
                elseif string.find(tostring(result), "concurrent") then
                    -- 并发修改错误，较短等待后重试
                    wait(attempt * 0.2)
                else
                    wait(attempt * 0.5) -- 其他错误较短等待
                end

                -- 最后一次尝试失败后记录错误
                if attempt == maxRetries then
                    spawn(function()
                        local success2, AdminDataService = pcall(function()
                            return require(script.Parent:WaitForChild("AdminDataService"))
                        end)
                        if success2 then
                            AdminDataService.logAdminAction("SYSTEM", "datastore_error", {
                                operation = "UpdateAsync",
                                datastore = dataStore,
                                key = key,
                                error = tostring(result),
                                attempts = maxRetries
                            })
                        end
                    end)
                end
            end
        end

        return false, nil
    end
end

-- ==============================================
-- 生产环境数据备份机制
-- ==============================================

-- 备份关键数据到备份DataStore
local function backupData(originalStore, backupStore, key, data)
    if not isStudio then
        spawn(function()
            local timestamp = os.time()
            local backupKey = key .. "_backup_" .. timestamp
            local backupData = {
                originalData = data,
                timestamp = timestamp,
                originalKey = key,
                originalStore = originalStore
            }

            local success = safeSetAsync(backupStore, backupKey, backupData, 1) -- 只尝试一次
            if not success then
                warn("⚠️ 备份数据失败:", originalStore, key)
            end
        end)
    end
end

-- 定期清理旧备份（保留最近30天）
local function cleanupOldBackups()
    if not isStudio then
        spawn(function()
            while true do
                wait(3600) -- 每小时检查一次

                local currentTime = os.time()
                local thirtyDaysAgo = currentTime - (30 * 24 * 3600)

                -- 这里可以实现备份清理逻辑
                -- 由于DataStore API限制，实际实现可能需要维护备份索引
                print("🧹 开始清理旧备份数据...")
            end
        end)
    end
end

-- 启动备份清理任务
spawn(cleanupOldBackups)

-- ==============================================
-- 默认数据结构定义
-- ==============================================

-- 默认用户数据结构
local function getDefaultUserData()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Config = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Config"))
    return {
        userId = "",
        username = "",
        displayName = "",
        coins = Config.GAME.ECONOMY.STARTING_COINS,
        isAdmin = false,
        status = "active",
        inventory = {}, -- {itemId = quantity}
        createdAt = os.time(),
        updatedAt = os.time(),
        lastLogin = os.time(),
        membership = {
            isActive = false,
            membershipId = nil,
            startDate = nil,
            endDate = nil,
            dailyReward = 100
        },
        stats = {
            totalPurchases = 0,
            totalSales = 0,
            totalSpent = 0,
            totalEarned = 0
        }
    }
end

-- 默认商品数据结构
local function getDefaultItemData()
    return {
        id = "",
        name = "",
        description = "",
        price = 0,
        sellPrice = 0, -- 如果为0则使用price * 0.8
        maxQuantity = nil, -- nil表示无限制
        currentStock = -1, -- -1表示无限库存
        dailyPurchaseLimit = nil, -- nil表示无限制
        canSell = true,
        category = "default",
        imageUrl = "",
        isActive = true,
        sortOrder = 0,
        createdAt = os.time(),
        updatedAt = os.time()
    }
end

-- 默认交易记录结构
local function createTransactionRecord(userId, transactionType, itemId, quantity, unitPrice, totalAmount, coinsBefore, coinsAfter, notes)
    return {
        id = HttpService:GenerateGUID(false), -- 生成唯一ID
        userId = userId,
        type = transactionType, -- "buy", "sell", "admin", "daily_reward", "membership_purchase"
        itemId = itemId,
        quantity = quantity or 1,
        unitPrice = unitPrice or 0,
        totalAmount = totalAmount or 0,
        coinsBefore = coinsBefore or 0,
        coinsAfter = coinsAfter or 0,
        transactionDate = os.date("%Y-%m-%d"),
        notes = notes or "",
        createdAt = os.time()
    }
end

-- 默认会员数据结构
local function createMembershipData(userId, startDate, endDate, dailyReward)
    return {
        id = HttpService:GenerateGUID(false),
        userId = userId,
        startDate = startDate,
        endDate = endDate,
        dailyRewardCoins = dailyReward or 100,
        isActive = true,
        createdAt = os.time(),
        updatedAt = os.time()
    }
end

-- ==============================================
-- 系统配置管理
-- ==============================================

-- 获取系统配置
function DataStoreManager.getSystemConfig(key, defaultValue)
    return safeGetAsync("SYSTEM_CONFIG", key, defaultValue)
end

-- 设置系统配置
function DataStoreManager.setSystemConfig(key, value, description)
    local configData = {
        value = value,
        description = description or "",
        updatedAt = os.time()
    }
    return safeSetAsync("SYSTEM_CONFIG", key, configData)
end

-- 获取所有系统配置
function DataStoreManager.getAllSystemConfig()
    if isStudio then
        return mockDataStores["SYSTEM_CONFIG"] or {}
    else
        -- 在生产环境中，需要通过ListDataStoresAsync获取所有键
        -- 这里返回一些默认配置
        return {
            sell_rate = {value = "0.8", description = "物品出售价格比例"},
            rate_limit_window_ms = {value = "900000", description = "API请求限制时间窗口(毫秒)"},
            rate_limit_max_requests = {value = "100", description = "API请求限制最大次数"},
            membership_daily_reward = {value = "100", description = "月卡每日奖励金币"},
            membership_duration_days = {value = "30", description = "月卡有效期天数"},
            membership_max_missed_rewards = {value = "7", description = "月卡最多补发奖励天数"},
            weekly_membership_duration_days = {value = "7", description = "周卡有效期天数"},
            quarterly_membership_duration_days = {value = "90", description = "季卡有效期天数"},
            premium_membership_daily_reward = {value = "200", description = "高级月卡每日奖励金币"},
            vip_membership_duration_days = {value = "365", description = "VIP年卡有效期天数"},
            vip_membership_daily_reward = {value = "150", description = "VIP年卡每日奖励金币"},
            default_coins_for_new_user = {value = "3000", description = "新用户注册时的默认金币数量"}
        }
    end
end

-- 初始化默认系统配置
local function initializeSystemConfig()
    local defaultConfigs = {
        sell_rate = {value = "0.8", description = "物品出售价格比例"},
        rate_limit_window_ms = {value = "900000", description = "API请求限制时间窗口(毫秒)"},
        rate_limit_max_requests = {value = "100", description = "API请求限制最大次数"},
        membership_daily_reward = {value = "100", description = "月卡每日奖励金币"},
        membership_duration_days = {value = "30", description = "月卡有效期天数"},
        membership_max_missed_rewards = {value = "7", description = "月卡最多补发奖励天数"},
        weekly_membership_duration_days = {value = "7", description = "周卡有效期天数"},
        quarterly_membership_duration_days = {value = "90", description = "季卡有效期天数"},
        premium_membership_daily_reward = {value = "200", description = "高级月卡每日奖励金币"},
        vip_membership_duration_days = {value = "365", description = "VIP年卡有效期天数"},
        vip_membership_daily_reward = {value = "150", description = "VIP年卡每日奖励金币"},
        default_coins_for_new_user = {value = "3000", description = "新用户注册时的默认金币数量"}
    }

    for key, config in pairs(defaultConfigs) do
        local existingConfig = DataStoreManager.getSystemConfig(key)
        if not existingConfig then
            DataStoreManager.setSystemConfig(key, config.value, config.description)
        end
    end
    print("✅ 系统配置初始化完成")
end

-- ==============================================
-- 用户数据管理
-- ==============================================

-- 获取用户数据
function DataStoreManager.getUserData(userId)
    local userData = safeGetAsync("USERS", userId, nil)
    if not userData then
        -- 创建新用户数据
        userData = getDefaultUserData()
        userData.userId = userId
        userData.username = userId -- 临时使用userId作为用户名

        local success = safeSetAsync("USERS", userId, userData)
        if success then
            print("✅ 创建新用户数据:", userId)
            -- 为新用户数据创建备份
            backupData("USERS", "USER_BACKUPS", userId, userData)
        else
            warn("❌ 创建用户数据失败:", userId)
        end
    end
    return userData
end

-- 更新用户数据
function DataStoreManager.updateUserData(userId, updateFunction)
    local success, newData = safeUpdateAsync("USERS", userId, function(currentData)
        local userData = currentData or getDefaultUserData()
        userData.userId = userId
        userData.updatedAt = os.time()

        -- 调用更新函数
        local updatedData = updateFunction(userData)
        return updatedData
    end)

    if success and newData then
        -- 为重要的用户数据更新创建备份
        backupData("USERS", "USER_BACKUPS", userId, newData)
        print("✅ 用户数据更新成功:", userId)
    else
        warn("❌ 用户数据更新失败:", userId)
    end

    return success, newData
end

-- 保存用户数据
function DataStoreManager.saveUserData(userId, userData)
    userData.updatedAt = os.time()
    local success = safeSetAsync("USERS", userId, userData)

    if success then
        -- 为用户数据保存创建备份
        backupData("USERS", "USER_BACKUPS", userId, userData)
        print("✅ 用户数据保存成功:", userId)
    else
        warn("❌ 用户数据保存失败:", userId)
    end

    return success
end

-- 获取多个用户数据（批量操作）
function DataStoreManager.getBatchUserData(userIds)
    local results = {}
    local tasks = {}

    for i, userId in ipairs(userIds) do
        table.insert(tasks, spawn(function()
            results[userId] = DataStoreManager.getUserData(userId)
        end))
    end

    -- 等待所有任务完成
    for _, task in ipairs(tasks) do
        task.Completed:Wait()
    end

    return results
end

-- 删除用户数据（软删除）
function DataStoreManager.deleteUserData(userId, adminUserId)
    local success, deletedData = safeUpdateAsync("USERS", userId, function(currentData)
        if currentData then
            currentData.status = "deleted"
            currentData.deletedAt = os.time()
            currentData.deletedBy = adminUserId
            return currentData
        end
        return nil
    end)

    if success and deletedData then
        -- 为删除操作创建备份
        backupData("USERS", "USER_BACKUPS", userId .. "_deleted", deletedData)
        print("✅ 用户数据标记为删除:", userId)
    end

    return success
end

-- ==============================================
-- 商品数据管理
-- ==============================================

-- 获取所有商品
function DataStoreManager.getAllItems()
    local allItems = safeGetAsync("ITEMS", "all_items", {})
    return allItems
end

-- 获取单个商品
function DataStoreManager.getItem(itemId)
    local allItems = DataStoreManager.getAllItems()
    return allItems[itemId]
end

-- 更新商品
function DataStoreManager.updateItem(itemId, itemData)
    local success, newData = safeUpdateAsync("ITEMS", "all_items", function(currentData)
        local items = currentData or {}
        items[itemId] = itemData
        return items
    end)

    if success then
        -- 为商品数据更新创建备份
        backupData("ITEMS", "ITEM_BACKUPS", "all_items", newData)
        print("✅ 商品数据更新成功:", itemId)
    else
        warn("❌ 商品数据更新失败:", itemId)
    end

    return success
end

-- 批量更新商品
function DataStoreManager.updateBatchItems(itemUpdates)
    local success, newData = safeUpdateAsync("ITEMS", "all_items", function(currentData)
        local items = currentData or {}
        for itemId, itemData in pairs(itemUpdates) do
            items[itemId] = itemData
        end
        return items
    end)

    if success then
        backupData("ITEMS", "ITEM_BACKUPS", "all_items_batch", newData)
        print("✅ 批量商品数据更新成功")
    else
        warn("❌ 批量商品数据更新失败")
    end

    return success
end

-- 初始化默认商品数据
local function initializeItemsData()
    -- 使用外部 ItemsInitializer 模块来处理商品初始化
    local ItemsInitializer = require(script.Parent.Parent.utils.ItemsInitializer)
    ItemsInitializer.initializeAllItems()
end

-- ==============================================
-- 交易数据管理
-- ==============================================

-- 记录交易
function DataStoreManager.recordTransaction(transactionData)
    local transactionId = "txn_" .. os.time() .. "_" .. math.random(1000, 9999)
    transactionData.id = transactionId
    transactionData.timestamp = os.time()
    transactionData.status = transactionData.status or "completed"

    local success = safeSetAsync("TRANSACTIONS", transactionId, transactionData)
    if success then
        -- 为交易数据创建备份
        backupData("TRANSACTIONS", "TRANSACTION_BACKUPS", transactionId, transactionData)
        print("✅ 交易记录成功:", transactionId)
    else
        warn("❌ 交易记录失败:", transactionId)
    end

    return success, transactionId
end

-- 获取用户交易历史
function DataStoreManager.getUserTransactionHistory(userId, limit)
    limit = limit or 50

    -- 这里简化实现，实际可能需要更复杂的索引系统
    if isStudio then
        local userTransactions = {}
        for key, transaction in pairs(mockDataStores["TRANSACTIONS"] or {}) do
            if transaction.userId == userId then
                table.insert(userTransactions, transaction)
            end
        end

        -- 按时间排序
        table.sort(userTransactions, function(a, b)
            return a.timestamp > b.timestamp
        end)

        -- 限制数量
        local result = {}
        for i = 1, math.min(limit, #userTransactions) do
            table.insert(result, userTransactions[i])
        end

        return result
    else
        -- 生产环境需要更复杂的查询机制
        -- 这里返回空数组，实际应该实现基于索引的查询
        warn("⚠️ 生产环境交易历史查询需要额外实现")
        return {}
    end
end

-- 获取交易统计信息
function DataStoreManager.getTransactionStats(timeRange)
    timeRange = timeRange or 86400 -- 默认24小时
    local currentTime = os.time()
    local startTime = currentTime - timeRange

    local stats = {
        totalTransactions = 0,
        totalVolume = 0,
        buyTransactions = 0,
        sellTransactions = 0,
        avgTransactionValue = 0
    }

    if isStudio then
        for key, transaction in pairs(mockDataStores["TRANSACTIONS"] or {}) do
            if transaction.timestamp >= startTime then
                stats.totalTransactions = stats.totalTransactions + 1
                stats.totalVolume = stats.totalVolume + (transaction.amount or 0)

                if transaction.type == "buy" then
                    stats.buyTransactions = stats.buyTransactions + 1
                elseif transaction.type == "sell" then
                    stats.sellTransactions = stats.sellTransactions + 1
                end
            end
        end

        if stats.totalTransactions > 0 then
            stats.avgTransactionValue = stats.totalVolume / stats.totalTransactions
        end
    end

    return stats
end

-- ==============================================
-- 分析和监控数据
-- ==============================================

-- 记录性能指标
function DataStoreManager.recordPerformanceMetric(metricName, value, metadata)
    local metricData = {
        name = metricName,
        value = value,
        metadata = metadata or {},
        timestamp = os.time()
    }

    local metricKey = metricName .. "_" .. os.time()
    local success = safeSetAsync("PERFORMANCE_METRICS", metricKey, metricData, 1) -- 只尝试一次

    if not success then
        warn("⚠️ 性能指标记录失败:", metricName)
    end

    return success
end

-- 获取系统健康状态
function DataStoreManager.getSystemHealth()
    local health = {
        status = "healthy",
        lastChecked = os.time(),
        issues = {}
    }

    -- 检查 DataStore 连接
    if not isStudio then
        local testSuccess = safeGetAsync("SYSTEM_CONFIG", "health_check", "ok")
        if not testSuccess then
            health.status = "degraded"
            table.insert(health.issues, "DataStore连接异常")
        end
    end

    -- 可以添加更多健康检查
    return health
end

-- ==============================================
-- 模块初始化
-- ==============================================

function DataStoreManager.initialize()
    initializeDataStores()

    -- 延迟初始化，确保DataStore准备就绪
    spawn(function()
        wait(1)
        initializeSystemConfig()
        initializeItemsData()
        print("🎯 DataStoreManager 初始化完成")
    end)
end

-- ==============================================
-- 公共接口
-- ==============================================

-- 获取DataStore实例（供其他模块使用）
function DataStoreManager.getDataStore(name)
    if isStudio then
        return mockDataStores[name]
    else
        return dataStores[name]
    end
end

-- 检查是否为Studio环境
function DataStoreManager.isStudioMode()
    return isStudio
end

-- 安全操作的公共接口
DataStoreManager.safeGetAsync = safeGetAsync
DataStoreManager.safeSetAsync = safeSetAsync
DataStoreManager.safeUpdateAsync = safeUpdateAsync

-- 默认数据结构的公共接口
DataStoreManager.getDefaultUserData = getDefaultUserData
DataStoreManager.createTransactionRecord = createTransactionRecord
DataStoreManager.createMembershipData = createMembershipData

return DataStoreManager
