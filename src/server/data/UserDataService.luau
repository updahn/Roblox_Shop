-- 普通用户数据服务 - 替换 userSQLOperations.js
-- 处理所有普通用户相关的数据操作

local DataStoreManager = require(script.Parent.DataStoreManager)
local HttpService = game:GetService("HttpService")

local UserDataService = {}

-- ==============================================
-- 用户数据管理
-- ==============================================

-- 创建或登录用户
function UserDataService.createOrLoginUser(userId, username, displayName)
    userId = tostring(userId)
    displayName = displayName or username

    local userData = DataStoreManager.safeGetAsync("USERS", userId, nil)

    if userData then
        -- 用户存在，更新最后登录时间
        userData.lastLogin = os.time()
        local success = DataStoreManager.safeSetAsync("USERS", userId, userData)

        if success then
            return {
                isNewUser = false,
                user = {
                    id = userData.userId,
                    username = userData.username,
                    displayName = userData.displayName,
                    coins = userData.coins,
                    isAdmin = userData.isAdmin,
                    lastLogin = userData.lastLogin
                }
            }
        end
    else
        -- 创建新用户
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Config = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Config"))
        local defaultCoins = Config.GAME.ECONOMY.STARTING_COINS

        local newUserData = DataStoreManager.getDefaultUserData()
        newUserData.userId = userId
        newUserData.username = username
        newUserData.displayName = displayName
        newUserData.coins = defaultCoins

        local success = DataStoreManager.safeSetAsync("USERS", userId, newUserData)

        if success then
            -- 更新用户索引
            DataStoreManager.safeUpdateAsync("USERS", "all_users_index", function(currentData)
                local userIndex = currentData or {}
                userIndex[userId] = true
                return userIndex
            end)

            return {
                isNewUser = true,
                user = {
                    id = newUserData.userId,
                    username = newUserData.username,
                    displayName = newUserData.displayName,
                    coins = newUserData.coins,
                    isAdmin = newUserData.isAdmin,
                    lastLogin = newUserData.lastLogin
                }
            }
        end
    end

    return nil
end

-- 获取用户详细信息
function UserDataService.getUserDetails(userId)
    userId = tostring(userId)

    if not userId or userId == "" then
        error("用户ID不能为空")
    end

    local userData = DataStoreManager.safeGetAsync("USERS", userId, nil)

    if userData then
        return {
            id = userData.userId,
            username = userData.username,
            displayName = userData.displayName,
            coins = userData.coins,
            isAdmin = userData.isAdmin,
            status = userData.status,
            createdAt = userData.createdAt,
            updatedAt = userData.updatedAt,
            lastLogin = userData.lastLogin,
            -- 统计信息
            total_purchases = userData.stats.totalPurchases,
            total_sales = userData.stats.totalSales,
            total_spent = userData.stats.totalSpent,
            total_earned = userData.stats.totalEarned
        }
    end

    return nil
end

-- 获取用户库存
function UserDataService.getUserInventory(userId)
    userId = tostring(userId)
    local userData = DataStoreManager.safeGetAsync("USERS", userId, nil)

    if not userData then
        return {}
    end

    local inventory = {}
    local allItems = DataStoreManager.getAllItems()

    for itemId, quantity in pairs(userData.inventory) do
        if quantity > 0 then
            local itemData = allItems[itemId]
            if itemData then
                local sellRate = tonumber(DataStoreManager.getSystemConfig("sell_rate", "0.8")) or 0.8
                local actualSellPrice = itemData.sellPrice > 0 and itemData.sellPrice or (itemData.price * sellRate)

                inventory[itemId] = {
                    item_id = itemId,
                    item_name = itemData.name,
                    description = itemData.description,
                    category = itemData.category,
                    quantity = quantity,
                    current_price = itemData.price,
                    actual_sell_price = actualSellPrice
                }
            end
        end
    end

    return inventory
end

-- ==============================================
-- 商品和交易操作
-- ==============================================

-- 获取商品列表
function UserDataService.getItems(activeOnly)
    if activeOnly == nil then activeOnly = true end

    local allItems = DataStoreManager.getAllItems()
    local items = {}

    for itemId, itemData in pairs(allItems) do
        if not activeOnly or itemData.isActive then
            items[itemId] = {
                id = itemData.id,
                name = itemData.name,
                description = itemData.description,
                price = itemData.price,
                category = itemData.category,
                max_quantity = itemData.maxQuantity,
                current_stock = itemData.currentStock,
                daily_purchase_limit = itemData.dailyPurchaseLimit,
                can_sell = itemData.canSell,
                is_active = itemData.isActive,
                image_url = itemData.imageUrl,
                created_at = itemData.createdAt,
                updated_at = itemData.updatedAt
            }
        end
    end

    return items
end

-- 获取单个商品信息
function UserDataService.getItem(itemId)
    local itemData = DataStoreManager.getItem(itemId)

    if itemData then
        return {
            id = itemData.id,
            name = itemData.name,
            description = itemData.description,
            price = itemData.price,
            category = itemData.category,
            max_quantity = itemData.maxQuantity,
            current_stock = itemData.currentStock,
            daily_purchase_limit = itemData.dailyPurchaseLimit,
            can_sell = itemData.canSell,
            is_active = itemData.isActive,
            image_url = itemData.imageUrl,
            created_at = itemData.createdAt,
            updated_at = itemData.updatedAt
        }
    end

    return nil
end

-- 购买商品
function UserDataService.buyItem(userId, itemId, quantity)
    if not userId or userId == "" then
        return {
            success = false,
            message = "用户ID不能为空"
        }
    end
    userId = tostring(userId)

    -- 检查是否为会员商品，如果是则调用专门的会员购买函数
    local membershipItems = {"monthly_membership", "weekly_membership", "quarterly_membership", "premium_membership", "vip_membership"}
    for _, membershipItemId in ipairs(membershipItems) do
        if itemId == membershipItemId then
            print("🎯 [buyItem] 检测到会员商品，调用专门的会员购买逻辑:", itemId)
            local success, result = pcall(function()
                return UserDataService.buyMembershipItem(userId, itemId, quantity)
            end)

            if success and result then
                print("✅ [buyItem] 会员商品购买成功:", itemId, "用户:", userId)
                return {
                    success = true,
                    message = "会员购买成功"
                }
            else
                print("❌ [buyItem] 会员商品购买失败:", itemId, "错误:", result)
                return {
                    success = false,
                    message = tostring(result) or "会员购买失败"
                }
            end
        end
    end

    -- 获取商品信息
    local itemData = DataStoreManager.getItem(itemId)
    if not itemData or not itemData.isActive then
        return {
            success = false,
            message = "商品不存在或已禁用"
        }
    end

    -- 检查库存
    if itemData.currentStock ~= -1 and itemData.currentStock < quantity then
        return {
            success = false,
            message = string.format("库存不足，当前库存: %d，尝试购买: %d", itemData.currentStock, quantity)
        }
    end

    -- 检查购买数量限制
    if itemData.maxQuantity and quantity > itemData.maxQuantity then
        return {
            success = false,
            message = string.format("购买数量超过限制，最大可购买: %d", itemData.maxQuantity)
        }
    end

    -- 检查每日限购（从交易记录中统计）
    if itemData.dailyPurchaseLimit then
        local todayPurchased = UserDataService.getTodayPurchaseCount(userId, itemId)
        if todayPurchased + quantity > itemData.dailyPurchaseLimit then
            local remaining = itemData.dailyPurchaseLimit - todayPurchased
            return {
                success = false,
                message = string.format("每日购买限额已达到，今日剩余可购买: %d，尝试购买: %d", remaining, quantity)
            }
        end
    end

    -- 计算总价
    local totalCost = itemData.price * quantity

    -- 先获取用户数据检查
    local currentUserData = DataStoreManager.safeGetAsync("USERS", userId, nil)
    if not currentUserData then
        return {
            success = false,
            message = "用户不存在"
        }
    end

    -- 检查金币
    if currentUserData.coins < totalCost then
        return {
            success = false,
            message = string.format("金币不足，需要: %d，当前: %d", totalCost, currentUserData.coins)
        }
    end

    -- 原子更新用户数据
    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            return nil  -- 返回 nil 表示取消更新
        end

        -- 再次检查金币（可能在此期间有变化）
        if currentData.coins < totalCost then
            return nil  -- 返回 nil 表示取消更新
        end

        -- 扣除金币
        local coinsBefore = currentData.coins
        currentData.coins = currentData.coins - totalCost

        -- 更新库存
        if not currentData.inventory[itemId] then
            currentData.inventory[itemId] = 0
        end
        currentData.inventory[itemId] = currentData.inventory[itemId] + quantity

        -- 更新统计
        currentData.stats.totalPurchases = currentData.stats.totalPurchases + 1
        currentData.stats.totalSpent = currentData.stats.totalSpent + totalCost
        currentData.updatedAt = os.time()

        return currentData
    end)

    if not success or not result then
        return {
            success = false,
            message = "购买失败：数据更新失败或金币不足"
        }
    end

    -- 更新商品库存（如果不是无限库存）
    if itemData.currentStock ~= -1 then
        local success = DataStoreManager.safeUpdateAsync("ITEMS", "all_items", function(currentData)
            local items = currentData or {}
            if items[itemId] then
                items[itemId].currentStock = items[itemId].currentStock - quantity
                items[itemId].updatedAt = os.time()
            end
            return items
        end)

        if not success then
            -- 如果商品库存更新失败，需要回滚用户数据
            warn("⚠️ 商品库存更新失败，但用户购买已完成")
        end
    end

    -- 记录交易
    UserDataService.addTransactionRecord(userId, "buy", itemId, quantity, itemData.price, totalCost, result.coins + totalCost, result.coins)

    return {
        success = true,
        totalCost = totalCost,
        itemPrice = itemData.price,
        quantity = quantity
    }
end

-- 出售商品
function UserDataService.sellItem(userId, itemId, quantity)
    userId = tostring(userId)

    -- 获取商品信息
    local itemData = DataStoreManager.getItem(itemId)
    if not itemData then
        return nil, "商品不存在"
    end

    -- 检查是否可以出售
    if not itemData.canSell then
        return nil, "该商品无法卖出"
    end

    -- 计算出售价格
    local sellRate = tonumber(DataStoreManager.getSystemConfig("sell_rate", "0.8")) or 0.8
    local unitSellPrice = itemData.sellPrice > 0 and itemData.sellPrice or (itemData.price * sellRate)
    local totalValue = unitSellPrice * quantity

    -- 原子更新用户数据
    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            return nil, "用户不存在"
        end

        -- 检查用户是否拥有足够的商品
        local ownedQuantity = currentData.inventory[itemId] or 0
        if ownedQuantity < quantity then
            return nil, string.format("拥有的物品数量不足，拥有: %d，尝试出售: %d", ownedQuantity, quantity)
        end

        -- 增加金币
        local coinsBefore = currentData.coins
        currentData.coins = currentData.coins + totalValue

        -- 减少库存
        currentData.inventory[itemId] = currentData.inventory[itemId] - quantity

        -- 更新统计
        currentData.stats.totalSales = currentData.stats.totalSales + 1
        currentData.stats.totalEarned = currentData.stats.totalEarned + totalValue
        currentData.updatedAt = os.time()

        return currentData
    end)

    if not success then
        return nil, "出售失败：数据更新失败"
    end

    -- 记录交易
    UserDataService.addTransactionRecord(userId, "sell", itemId, quantity, unitSellPrice, totalValue, result.coins - totalValue, result.coins)

    return {
        success = true,
        totalValue = totalValue,
        unitSellPrice = unitSellPrice,
        quantity = quantity
    }
end

-- ==============================================
-- 交易记录管理
-- ==============================================

-- 添加交易记录
function UserDataService.addTransactionRecord(userId, transactionType, itemId, quantity, unitPrice, totalAmount, coinsBefore, coinsAfter, notes)
    local transactionRecord = DataStoreManager.createTransactionRecord(
        userId, transactionType, itemId, quantity, unitPrice, totalAmount, coinsBefore, coinsAfter, notes
    )

    -- 将交易记录添加到用户的交易历史中
    local userTransactionsKey = "user_transactions_" .. userId
    local success, newData = DataStoreManager.safeUpdateAsync("TRANSACTIONS", userTransactionsKey, function(currentData)
        local transactions = currentData or {}
        table.insert(transactions, 1, transactionRecord) -- 最新的交易在前面

        -- 限制交易记录数量（保留最近50条）
        local maxRecords = 50
        if #transactions > maxRecords then
            for i = maxRecords + 1, #transactions do
                transactions[i] = nil
            end
        end

        return transactions
    end)

    return success
end

-- 获取用户交易记录
function UserDataService.getUserTransactions(userId, limit)
    userId = tostring(userId)
    limit = limit or 50

    local userTransactionsKey = "user_transactions_" .. userId
    local transactions = DataStoreManager.safeGetAsync("TRANSACTIONS", userTransactionsKey, {})

    -- 限制返回数量
    if limit and limit > 0 and #transactions > limit then
        local limitedTransactions = {}
        for i = 1, math.min(limit, #transactions) do
            limitedTransactions[i] = transactions[i]
        end
        transactions = limitedTransactions
    end

    -- 转换格式以匹配原有API
    local formattedTransactions = {}
    local allItems = DataStoreManager.getAllItems()

    for _, transaction in ipairs(transactions) do
        local itemData = allItems[transaction.itemId or ""]

        -- 确保时间戳字段存在和正确
        local createdAt = transaction.createdAt or transaction.timestamp or os.time()
        local transactionDate = transaction.transactionDate or os.date("%Y-%m-%d", createdAt)

        table.insert(formattedTransactions, {
            id = transaction.id,
            item_id = transaction.itemId,
            item_name = itemData and itemData.name or "未知商品",
            type = transaction.type,
            quantity = transaction.quantity,
            unit_price = transaction.unitPrice,
            total_amount = transaction.totalAmount,
            transaction_date = transactionDate,
            created_at = createdAt,
            timestamp = createdAt -- 添加timestamp字段以保证兼容性
        })
    end

    return formattedTransactions
end

-- 获取今日购买数量（用于每日限购检查）
function UserDataService.getTodayPurchaseCount(userId, itemId)
    userId = tostring(userId)
    local today = os.date("%Y-%m-%d")

    local userTransactionsKey = "user_transactions_" .. userId
    local transactions = DataStoreManager.safeGetAsync("TRANSACTIONS", userTransactionsKey, {})

    local todayCount = 0
    for _, transaction in ipairs(transactions) do
        if transaction.itemId == itemId and transaction.type == "buy" and transaction.transactionDate == today then
            todayCount = todayCount + transaction.quantity
        end
    end

    return todayCount
end

-- 获取用户交易统计
function UserDataService.getUserTransactionStats(userId)
    userId = tostring(userId)

    local userTransactionsKey = "user_transactions_" .. userId
    local transactions = DataStoreManager.safeGetAsync("TRANSACTIONS", userTransactionsKey, {})

    local stats = {
        buy = {count = 0, total_amount = 0},
        sell = {count = 0, total_amount = 0}
    }

    for _, transaction in ipairs(transactions) do
        if transaction.type == "buy" or transaction.type == "sell" then
            stats[transaction.type].count = stats[transaction.type].count + 1
            stats[transaction.type].total_amount = stats[transaction.type].total_amount + transaction.totalAmount
        end
    end

    return {
        {type = "buy", count = stats.buy.count, total_amount = stats.buy.total_amount},
        {type = "sell", count = stats.sell.count, total_amount = stats.sell.total_amount}
    }
end

-- ==============================================
-- 会员系统
-- ==============================================

-- 会员状态缓存（避免频繁查询数据库）
local membershipCache = {}
local cacheExpiry = {} -- 缓存过期时间
local CACHE_DURATION = 300 -- 缓存5分钟

-- 清理过期缓存
local function cleanupExpiredCache()
    local currentTime = os.time()
    for userId, expiry in pairs(cacheExpiry) do
        if currentTime > expiry then
            membershipCache[userId] = nil
            cacheExpiry[userId] = nil
        end
    end
end

-- 获取缓存的会员状态
local function getCachedMembershipStatus(userId)
    cleanupExpiredCache()

    local cached = membershipCache[userId]
    local expiry = cacheExpiry[userId]

    if cached and expiry and os.time() < expiry then
        return cached
    end

    return nil
end

-- 缓存会员状态
local function cacheMembershipStatus(userId, status)
    membershipCache[userId] = status
    cacheExpiry[userId] = os.time() + CACHE_DURATION
end

-- 清除特定用户的缓存
local function clearMembershipCache(userId)
    membershipCache[userId] = nil
    cacheExpiry[userId] = nil
end

-- 导出清除缓存函数供外部使用
function UserDataService.clearMembershipCache(userId)
    clearMembershipCache(userId)
    print("🧹 [UserDataService] 已清除用户会员缓存:", userId)
end

-- 清除所有缓存（管理员功能）
function UserDataService.clearAllMembershipCache()
    membershipCache = {}
    cacheExpiry = {}
    print("✅ [会员系统] 已清除所有会员状态缓存")
end

-- 获取缓存统计信息（调试用）
function UserDataService.getMembershipCacheStats()
    cleanupExpiredCache()
    local cacheCount = 0
    for _ in pairs(membershipCache) do
        cacheCount = cacheCount + 1
    end

    return {
        cachedUsers = cacheCount,
        cacheDuration = CACHE_DURATION
    }
end

-- 验证和修复会员数据完整性
function UserDataService.validateAndRepairMembershipData(userId)
    userId = tostring(userId)

    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            return nil
        end

        local repaired = false

        -- 确保会员数据结构存在
        if not currentData.membership then
            currentData.membership = {
                isActive = false,
                membershipId = nil,
                startDate = nil,
                endDate = nil,
                dailyReward = 100
            }
            repaired = true
        end

        -- 验证会员数据字段
        local membership = currentData.membership
        if type(membership.isActive) ~= "boolean" then
            membership.isActive = false
            repaired = true
        end

        if membership.dailyReward and type(membership.dailyReward) ~= "number" then
            membership.dailyReward = 100
            repaired = true
        end

        -- 检查数据一致性：如果有会员ID但没有结束日期，或者相反
        if membership.membershipId and not membership.endDate then
            warn("⚠️ [数据修复] 用户", userId, "有会员ID但没有结束日期，停用会员")
            membership.isActive = false
            membership.membershipId = nil
            repaired = true
        elseif not membership.membershipId and membership.endDate then
            warn("⚠️ [数据修复] 用户", userId, "有结束日期但没有会员ID，清除日期")
            membership.endDate = nil
            membership.startDate = nil
            membership.isActive = false
            repaired = true
        end

        -- 检查过期会员
        if membership.isActive and membership.endDate then
            local currentTime = os.time()
            if currentTime >= membership.endDate then
                membership.isActive = false
                repaired = true
            end
        end

        if repaired then
            currentData.updatedAt = os.time()
            print("🔧 [数据修复] 用户", userId, "的会员数据已修复")
        end

        return currentData
    end)

    if success then
        -- 清除缓存以确保获取最新数据
        clearMembershipCache(userId)
    end

    return success, result
end

-- 批量修复所有用户的会员数据（管理员功能）
function UserDataService.batchRepairMembershipData()
    local allUsers = DataStoreManager.safeGetAsync("USERS", "all_users", {})
    if not allUsers then
        return {success = false, message = "无法获取用户列表"}
    end

    local repairCount = 0
    local errorCount = 0

    for userId, _ in pairs(allUsers) do
        local success, _ = UserDataService.validateAndRepairMembershipData(userId)
        if success then
            repairCount = repairCount + 1
        else
            errorCount = errorCount + 1
        end
    end

    print(string.format("🔧 [批量修复] 完成会员数据修复，成功: %d，失败: %d", repairCount, errorCount))

    return {
        success = true,
        repaired = repairCount,
        errors = errorCount,
        total = repairCount + errorCount
    }
end

-- 诊断会员系统健康状态（管理员功能）
function UserDataService.diagnoseMembershipSystem()
    local stats = {
        totalUsers = 0,
        activeMembers = 0,
        expiredMembers = 0,
        corruptedData = 0,
        cacheStats = UserDataService.getMembershipCacheStats()
    }

    local allUsers = DataStoreManager.safeGetAsync("USERS", "all_users", {})
    if not allUsers then
        return {success = false, message = "无法获取用户列表", stats = stats}
    end

    for userId, _ in pairs(allUsers) do
        stats.totalUsers = stats.totalUsers + 1

        local membershipStatus = UserDataService.getMembershipStatus(userId)
        if membershipStatus.error then
            stats.corruptedData = stats.corruptedData + 1
        elseif membershipStatus.isValid then
            stats.activeMembers = stats.activeMembers + 1
        elseif membershipStatus.hasMembership then
            stats.expiredMembers = stats.expiredMembers + 1
        end
    end

    print("📊 [会员系统诊断]")
    print("  总用户数:", stats.totalUsers)
    print("  活跃会员:", stats.activeMembers)
    print("  过期会员:", stats.expiredMembers)
    print("  数据损坏:", stats.corruptedData)
    print("  缓存用户:", stats.cacheStats.cachedUsers)

    return {success = true, stats = stats}
end

-- 获取会员状态
function UserDataService.getMembershipStatus(userId)
    -- 参数验证
    if not userId or userId == "" then
        warn("❌ [会员状态] 无效的用户ID")
        return {
            hasMembership = false,
            isValid = false,
            daysRemaining = 0,
            membershipType = nil,
            startDate = nil,
            endDate = nil,
            dailyReward = 0,
            error = "无效的用户ID"
        }
    end

    userId = tostring(userId)

    -- 尝试从缓存获取
    local cached = getCachedMembershipStatus(userId)
    if cached then
        -- 对于无效会员或者没有结束日期的直接返回缓存
        if not cached.isValid or not cached.endDate then
            return cached
        end

        -- 验证缓存的会员是否真的过期（简单检查剩余天数）
        if cached.daysRemaining and cached.daysRemaining <= 0 then
            -- 缓存显示已过期，清除缓存重新查询
            clearMembershipCache(userId)
        else
            return cached
        end
    end

    -- 使用 pcall 包装数据获取以捕获异常
    local success, userData = pcall(function()
        return DataStoreManager.safeGetAsync("USERS", userId, nil)
    end)

    if not success then
        warn("❌ [会员状态] 获取用户数据失败:", userData)
        return {
            hasMembership = false,
            isValid = false,
            daysRemaining = 0,
            membershipType = nil,
            startDate = nil,
            endDate = nil,
            dailyReward = 0,
            error = "数据获取失败"
        }
    end

    -- 检查用户数据是否存在
    if not userData then
        warn("⚠️ [会员状态] 用户不存在:", userId)
        return {
            hasMembership = false,
            isValid = false,
            daysRemaining = 0,
            membershipType = nil,
            startDate = nil,
            endDate = nil,
            dailyReward = 0,
            error = "用户不存在"
        }
    end

    -- 检查会员数据结构
    if not userData.membership then
        -- 为用户初始化会员数据结构
        local initSuccess = pcall(function()
            DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
                if currentData then
                    currentData.membership = {
                        isActive = false,
                        membershipId = nil,
                        startDate = nil,
                        endDate = nil,
                        dailyReward = 100
                    }
                    currentData.updatedAt = os.time()
                end
                return currentData
            end)
        end)

        if not initSuccess then
            warn("⚠️ [会员状态] 初始化会员数据失败:", userId)
        end

        return {
            hasMembership = false,
            isValid = false,
            daysRemaining = 0,
            membershipType = nil,
            startDate = nil,
            endDate = nil,
            dailyReward = 100
        }
    end

    local membership = userData.membership

    -- 确保会员数据结构完整性
    if type(membership) ~= "table" then
        warn("❌ [会员状态] 会员数据结构损坏:", userId)
        return {
            hasMembership = false,
            isValid = false,
            daysRemaining = 0,
            membershipType = nil,
            startDate = nil,
            endDate = nil,
            dailyReward = 100,
            error = "会员数据结构损坏"
        }
    end

    -- 检查会员是否有效
    local isValid = false
    local daysRemaining = 0
    local currentTime = os.time()

    if membership.isActive and membership.endDate and type(membership.endDate) == "number" then
        local endTime = membership.endDate

        if currentTime < endTime then
            isValid = true
            daysRemaining = math.max(0, math.ceil((endTime - currentTime) / (24 * 60 * 60)))
        else
            -- 会员已过期，异步更新状态避免阻塞
            task.spawn(function()
                local deactivateSuccess = pcall(function()
                    UserDataService.deactivateMembership(userId)
                end)
                if not deactivateSuccess then
                    warn("⚠️ [会员状态] 停用过期会员失败:", userId)
                end
            end)
        end
    elseif membership.isActive and not membership.endDate then
        -- 数据不一致，会员激活但没有结束日期
        warn("⚠️ [会员状态] 数据不一致 - 会员激活但没有结束日期:", userId)
        isValid = false
    end

    -- 安全地格式化日期
    local function formatDate(timestamp)
        if not timestamp or type(timestamp) ~= "number" then
            return nil
        end
        local success, formattedDate = pcall(function()
            return os.date("%Y-%m-%d", timestamp)
        end)
        return success and formattedDate or nil
    end

    local result = {
        hasMembership = membership.membershipId ~= nil and membership.membershipId ~= "",
        isValid = isValid,
        membershipId = membership.membershipId,
        membershipType = "monthly",
        startDate = formatDate(membership.startDate),
        endDate = formatDate(membership.endDate),
        dailyReward = tonumber(membership.dailyReward) or 100,
        daysRemaining = daysRemaining,
        isActive = membership.isActive == true,
        createdAt = membership.createdAt
    }

    -- 添加调试信息（仅在开发环境）
    if game:GetService("RunService"):IsStudio() then
        print("🔍 [会员状态] 用户:", userId, "有效:", isValid, "剩余天数:", daysRemaining)
    end

    -- 缓存结果
    cacheMembershipStatus(userId, result)

    return result
end

-- 停用过期会员
function UserDataService.deactivateMembership(userId)
    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if currentData and currentData.membership then
            currentData.membership.isActive = false
            currentData.updatedAt = os.time()
        end
        return currentData
    end)

    -- 清除缓存
    if success then
        clearMembershipCache(userId)
    end

    return success
end

-- 购买会员商品
function UserDataService.buyMembershipItem(userId, itemId, quantity)
    userId = tostring(userId)

    -- 支持的会员商品类型
    local validMembershipItems = {
        monthly_membership = {days = 30, reward = 100},
        weekly_membership = {days = 7, reward = 100},
        quarterly_membership = {days = 90, reward = 100},
        premium_membership = {days = 30, reward = 200},
        vip_membership = {days = 365, reward = 150}
    }

    if not validMembershipItems[itemId] then
        error("无效的会员商品ID")
    end

    -- 获取会员商品价格
    local itemData = DataStoreManager.getItem(itemId)
    if not itemData or not itemData.isActive then
        error("会员商品不存在或已下架")
    end

    local membershipConfig = validMembershipItems[itemId]
    local durationDays = membershipConfig.days * quantity
    local dailyReward = membershipConfig.reward
    local totalCost = itemData.price * quantity

    -- 原子更新用户数据
    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        -- 确保 membership 字段存在
        if not currentData.membership then
            currentData.membership = {
                isActive = false,
                membershipId = nil,
                startDate = nil,
                endDate = nil,
                dailyReward = 100
            }
        end

        -- 检查金币
        if currentData.coins < totalCost then
            error(string.format("金币不足，需要: %d，当前: %d", totalCost, currentData.coins))
        end

        -- 扣除金币
        local coinsBefore = currentData.coins
        currentData.coins = currentData.coins - totalCost

        -- 设置会员信息
        local now = os.time()
        local startDate = now
        local endDate = now + (durationDays * 24 * 60 * 60)

        -- 如果已有活跃会员，从结束日期开始延期
        if currentData.membership.isActive and currentData.membership.endDate and currentData.membership.endDate > now then
            startDate = currentData.membership.endDate
            endDate = startDate + (durationDays * 24 * 60 * 60)
        end

        -- 保留现有的 membershipId，如果没有则生成新的
        local membershipId = currentData.membership.membershipId or HttpService:GenerateGUID(false)

        currentData.membership = {
            isActive = true,
            membershipId = membershipId,
            startDate = startDate,
            endDate = endDate,
            dailyReward = dailyReward,
            createdAt = now
        }

        -- 确保统计数据存在
        if not currentData.stats then
            currentData.stats = {
                totalPurchases = 0,
                totalSpent = 0,
                totalSold = 0,
                totalEarned = 0
            }
        end

        -- 更新统计
        currentData.stats.totalPurchases = currentData.stats.totalPurchases + 1
        currentData.stats.totalSpent = currentData.stats.totalSpent + totalCost
        currentData.updatedAt = now

        print("✅ [buyMembershipItem] 会员数据已更新 - 用户:", userId, "商品:", itemId, "天数:", durationDays, "结束时间:", os.date("%Y-%m-%d %H:%M:%S", endDate))

        return currentData
    end)

    if not success then
        error("购买会员失败：数据更新失败")
    end

    -- 清除缓存
    clearMembershipCache(userId)

    -- 记录交易
    UserDataService.addTransactionRecord(userId, "membership_purchase", itemId, quantity, itemData.price, totalCost, result.coins + totalCost, result.coins, string.format("购买%d个月会员，有效期%d天", quantity, durationDays))

    -- 立即发送当日奖励
    local immediateReward = UserDataService.claimTodayMembershipReward(userId)

    return {
        success = true,
        totalCost = totalCost,
        membershipDays = durationDays,
        dailyReward = dailyReward,
        startDate = os.date("%Y-%m-%d", result.membership.startDate),
        endDate = os.date("%Y-%m-%d", result.membership.endDate),
        membershipId = result.membership.membershipId,
        immediateReward = immediateReward
    }
end

-- 处理登录奖励
function UserDataService.processLoginRewards(userId)
    userId = tostring(userId)

    -- 获取用户数据和会员状态
    local membershipStatus = UserDataService.getMembershipStatus(userId)

    -- 检查获取会员状态是否出错
    if membershipStatus.error then
        warn("⚠️ [登录奖励] 获取会员状态失败:", membershipStatus.error)
        return {
            success = false,
            message = "获取会员状态失败: " .. membershipStatus.error,
            canClaim = false,
            totalRewards = 0
        }
    end

    if not membershipStatus.isValid then
        return {
            success = false,
            message = "没有有效的会员资格",
            canClaim = false,
            totalRewards = 0
        }
    end

    local today = os.date("%Y-%m-%d")
    local dailyReward = membershipStatus.dailyReward

    -- 检查今日是否已领取
    local rewardsKey = "daily_rewards_" .. userId
    local rewardHistory = DataStoreManager.safeGetAsync("DAILY_REWARDS", rewardsKey, {})

    -- 检查今日是否已领取
    for _, record in ipairs(rewardHistory) do
        if record.date == today then
            return {
                success = false,
                message = "今日奖励已领取",
                canClaim = false,
                alreadyClaimed = true,
                totalRewards = 0
            }
        end
    end

    -- 原子更新用户金币
    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        local coinsBefore = currentData.coins
        currentData.coins = currentData.coins + dailyReward
        currentData.updatedAt = os.time()

        return currentData
    end)

    if not success then
        return {
            success = false,
            message = "奖励领取失败",
            canClaim = false,
            totalRewards = 0
        }
    end

    -- 记录每日奖励
    local success2 = DataStoreManager.safeUpdateAsync("DAILY_REWARDS", rewardsKey, function(currentData)
        local rewards = currentData or {}
        table.insert(rewards, 1, {
            date = today,
            reward_coins = dailyReward,
            membership_id = membershipStatus.membershipId,
            claimed_at = os.time()
        })

        -- 只保留最近30天的记录
        if #rewards > 30 then
            for i = 31, #rewards do
                rewards[i] = nil
            end
        end

        return rewards
    end)

    -- 记录交易
    UserDataService.addTransactionRecord(userId, "daily_reward", nil, 1, dailyReward, dailyReward, result.coins - dailyReward, result.coins, "每日登录奖励 (" .. today .. ")")

    return {
        success = true,
        message = "每日奖励领取成功",
        canClaim = true,
        rewardAmount = dailyReward,
        totalRewards = dailyReward,
        rewardedDays = 1,
        membershipType = "monthly"
    }
end

-- ==============================================
-- 系统配置相关
-- ==============================================

-- 获取系统配置
function UserDataService.getSystemConfig(configKey)
    local config = DataStoreManager.getSystemConfig(configKey)
    return config and config.value or nil
end

-- 获取出售比率
function UserDataService.getSellRate()
    return UserDataService.getSystemConfig("sell_rate") or "0.8"
end

-- 立即发送当日会员奖励（购买会员或管理员修改会员后调用）
function UserDataService.claimTodayMembershipReward(userId)
    userId = tostring(userId)

    -- 获取用户数据和会员状态
    local membershipStatus = UserDataService.getMembershipStatus(userId)

    -- 检查获取会员状态是否出错
    if membershipStatus.error then
        warn("⚠️ [立即奖励] 获取会员状态失败:", membershipStatus.error)
        return {
            success = false,
            message = "获取会员状态失败: " .. membershipStatus.error,
            totalRewards = 0
        }
    end

    if not membershipStatus.isValid then
        return {
            success = false,
            message = "没有有效的会员资格",
            totalRewards = 0
        }
    end

    local today = os.date("%Y-%m-%d")
    local dailyReward = membershipStatus.dailyReward

    -- 检查今日是否已领取
    local rewardsKey = "daily_rewards_" .. userId
    local rewardHistory = DataStoreManager.safeGetAsync("DAILY_REWARDS", rewardsKey, {})

    -- 检查今日是否已领取
    for _, record in ipairs(rewardHistory) do
        if record.date == today then
            return {
                success = false,
                message = "今日奖励已领取",
                alreadyClaimed = true,
                totalRewards = 0
            }
        end
    end

    -- 原子更新用户金币
    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        local coinsBefore = currentData.coins
        currentData.coins = currentData.coins + dailyReward
        currentData.updatedAt = os.time()

        return currentData
    end)

    if not success then
        return {
            success = false,
            message = "奖励领取失败",
            totalRewards = 0
        }
    end

    -- 记录每日奖励
    local success2 = DataStoreManager.safeUpdateAsync("DAILY_REWARDS", rewardsKey, function(currentData)
        if not currentData then
            currentData = {}
        end

        table.insert(currentData, {
            date = today,
            reward = dailyReward,
            timestamp = os.time(),
            membershipId = membershipStatus.membershipId
        })

        return currentData
    end)

    if success2 then
        -- 记录每日奖励交易
        UserDataService.addTransactionRecord(userId, "daily_reward", "daily_membership_reward", 1, dailyReward, dailyReward, result.coins - dailyReward, result.coins, "会员每日奖励")

        return {
            success = true,
            message = "每日奖励领取成功",
            totalRewards = dailyReward,
            newBalance = result.coins
        }
    else
        return {
            success = false,
            message = "奖励记录失败，但金币已发放",
            totalRewards = dailyReward,
            newBalance = result.coins
        }
    end
end

print("👤 用户数据服务已加载")

return UserDataService
