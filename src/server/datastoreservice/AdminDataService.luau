-- 管理员数据服务 - 替换 adminSQLOperations.js
-- 处理所有管理员相关的数据操作

local DataStoreManager = require(game:GetService("ServerScriptService").Server.datastoreservice.DataStoreManager)
local UserDataService = require(game:GetService("ServerScriptService").Server.datastoreservice.UserDataService)
local HttpService = game:GetService("HttpService")

local AdminDataService = {}

-- ==============================================
-- 用户管理功能
-- ==============================================

-- 获取所有用户（带分页）
function AdminDataService.getUsersWithPagination(options)
    options = options or {}
    local limit = math.min(1000, math.max(1, options.limit or 100))
    local offset = math.max(0, options.offset or 0)
    local status = options.status
    local search = options.search
    local sortBy = options.sortBy or "created_at"
    local sortOrder = options.sortOrder or "DESC"

    -- 获取所有用户数据（在实际应用中，可能需要使用 ListDataStoresAsync）
    local allUsersData = AdminDataService.getAllUsersData()
    local filteredUsers = {}

    -- 筛选用户
    for userId, userData in pairs(allUsersData) do
        local shouldInclude = true

        -- 状态筛选
        if status and userData.status ~= status then
            shouldInclude = false
        end

        -- 搜索筛选
        if search and shouldInclude then
            local searchLower = string.lower(search)
            local usernameLower = string.lower(userData.username or "")
            local displayNameLower = string.lower(userData.displayName or "")

            if not (string.find(usernameLower, searchLower) or string.find(displayNameLower, searchLower)) then
                shouldInclude = false
            end
        end

        if shouldInclude then
            -- 获取用户统计
            local userStats = AdminDataService.getUserStats(userId)
            local membershipStatus = UserDataService.getMembershipStatus(userId)

            table.insert(filteredUsers, {
                id = userData.userId,
                username = userData.username,
                display_name = userData.displayName,
                coins = userData.coins,
                status = userData.status,
                is_admin = userData.isAdmin,
                created_at = userData.createdAt,
                updated_at = userData.updatedAt,
                last_login = userData.lastLogin,

                -- 统计数据
                buy_count = userStats.buy_count,
                sell_count = userStats.sell_count,
                total_spent = userStats.total_spent,
                total_earned = userStats.total_earned,

                -- 会员状态
                membership_status = membershipStatus.isValid and "active" or (membershipStatus.hasMembership and "expired" or "none"),
                membership_end_date = membershipStatus.endDate,
                end_date = membershipStatus.endDate,
                days_remaining = membershipStatus.daysRemaining,
                daily_reward_coins = membershipStatus.dailyReward
            })
        end
    end

    -- 排序
    table.sort(filteredUsers, function(a, b)
        local aVal = a[sortBy] or 0
        local bVal = b[sortBy] or 0

        if sortOrder == "ASC" then
            return aVal < bVal
        else
            return aVal > bVal
        end
    end)

    -- 分页
    local paginatedUsers = {}
    local startIndex = offset + 1
    local endIndex = math.min(startIndex + limit - 1, #filteredUsers)

    for i = startIndex, endIndex do
        table.insert(paginatedUsers, filteredUsers[i])
    end

    return paginatedUsers
end

-- 获取用户总数
function AdminDataService.getUserCount(status)
    local allUsersData = AdminDataService.getAllUsersData()
    local count = 0

    for userId, userData in pairs(allUsersData) do
        if not status or userData.status == status then
            count = count + 1
        end
    end

    return count
end

-- 获取用户统计数据
function AdminDataService.getUserStats(userId)
    userId = tostring(userId)

    local userTransactionsKey = "user_transactions_" .. userId
    local transactions = DataStoreManager.safeGetAsync("TRANSACTIONS", userTransactionsKey, {})

    local stats = {
        buy_count = 0,
        sell_count = 0,
        total_spent = 0,
        total_earned = 0
    }

    for _, transaction in ipairs(transactions) do
        if transaction.type == "buy" then
            stats.buy_count = stats.buy_count + 1
            stats.total_spent = stats.total_spent + transaction.totalAmount
        elseif transaction.type == "sell" then
            stats.sell_count = stats.sell_count + 1
            stats.total_earned = stats.total_earned + transaction.totalAmount
        end
    end

    return stats
end

-- 批量获取多个用户的统计数据
function AdminDataService.getBatchUserStats(userIds)
    if not userIds or #userIds == 0 then
        return {}
    end

    local statsMap = {}

    for _, userId in ipairs(userIds) do
        local userStats = AdminDataService.getUserStats(userId)
        statsMap[userId] = userStats
    end

    return statsMap
end

-- 获取用户详细信息
function AdminDataService.getUserDetails(userId)
    return UserDataService.getUserDetails(userId)
end

-- 更新用户金币
function AdminDataService.updateUserCoins(userId, coins, reason, adminUserId)
    userId = tostring(userId)
    adminUserId = tostring(adminUserId)

    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        local coinsBefore = currentData.coins
        local coinsAfter = coins
        local coinsDifference = coinsAfter - coinsBefore

        currentData.coins = coins
        currentData.updatedAt = os.time()

        return currentData, coinsBefore, coinsAfter, coinsDifference
    end)

    if success and result then
        local coinsBefore, coinsAfter, coinsDifference = result[2], result[3], result[4]

        -- 记录交易
        UserDataService.addTransactionRecord(
            userId, "admin", nil, 1, coinsDifference, coinsDifference,
            coinsBefore, coinsAfter, reason or "管理员调整金币"
        )

        -- 记录管理员操作日志
        AdminDataService.logAdminAction(adminUserId, "update_coins", {
            target_user_id = userId,
            coins_before = coinsBefore,
            coins_after = coinsAfter,
            reason = reason
        })

        return true
    end

    return false
end

-- 更新用户状态
function AdminDataService.updateUserStatus(userId, status)
    userId = tostring(userId)

    local success = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        currentData.status = status
        currentData.updatedAt = os.time()

        return currentData
    end)

    return success
end

-- 检查用户是否存在
function AdminDataService.checkUserExists(userIdOrUsername, isUserId)
    if isUserId == nil then isUserId = true end

    if isUserId then
        local userData = DataStoreManager.safeGetAsync("USERS", tostring(userIdOrUsername), nil)
        if userData then
            return {
                id = userData.userId,
                username = userData.username,
                display_name = userData.displayName,
                is_admin = userData.isAdmin,
                status = userData.status,
                coins = userData.coins,
                created_at = userData.createdAt
            }
        end
    else
        -- 通过用户名查找需要遍历所有用户（在生产环境中可能需要优化）
        local allUsersData = AdminDataService.getAllUsersData()
        for userId, userData in pairs(allUsersData) do
            if userData.username == userIdOrUsername then
                return {
                    id = userData.userId,
                    username = userData.username,
                    display_name = userData.displayName,
                    is_admin = userData.isAdmin,
                    status = userData.status,
                    coins = userData.coins,
                    created_at = userData.createdAt
                }
            end
        end
    end

    return nil
end

-- 通过用户名查找用户
function AdminDataService.getUserByUsername(username)
    return AdminDataService.checkUserExists(username, false)
end

-- ==============================================
-- 管理员权限管理
-- ==============================================

-- 获取管理员列表
function AdminDataService.getAdminList()
    local allUsersData = AdminDataService.getAllUsersData()
    local adminList = {}

    for userId, userData in pairs(allUsersData) do
        if userData.isAdmin then
            table.insert(adminList, {
                id = userData.userId,
                username = userData.username,
                display_name = userData.displayName,
                created_at = userData.createdAt,
                last_login = userData.lastLogin
            })
        end
    end

    -- 按创建时间降序排序
    table.sort(adminList, function(a, b)
        return a.created_at > b.created_at
    end)

    return adminList
end

-- 添加管理员
function AdminDataService.addAdmin(userData)
    local userId = tostring(userData.user_id)
    local username = userData.username

    -- 创建或更新用户记录
    local success = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if currentData then
            -- 用户存在，提升为管理员
            currentData.isAdmin = true
            currentData.updatedAt = os.time()
            return currentData
        else
            -- 创建新用户
            local newUserData = DataStoreManager.getDefaultUserData()
            newUserData.userId = userId
            newUserData.username = username
            newUserData.displayName = username
            newUserData.isAdmin = true
            return newUserData
        end
    end)

    if success then
        return {success = true, message = "管理员添加成功"}
    else
        return {success = false, message = "管理员添加失败"}
    end
end

-- 提升用户为管理员
function AdminDataService.promoteToAdmin(userId)
    userId = tostring(userId)

    local success = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        currentData.isAdmin = true
        currentData.updatedAt = os.time()

        return currentData
    end)

    if success then
        return {success = true, message = "用户已提升为管理员"}
    else
        return {success = false, message = "提升管理员失败"}
    end
end

-- 移除管理员权限
function AdminDataService.removeAdmin(userId)
    userId = tostring(userId)

    local success = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("管理员不存在")
        end

        currentData.isAdmin = false
        currentData.updatedAt = os.time()

        return currentData
    end)

    if success then
        return {success = true, message = "管理员权限已移除"}
    else
        return {success = false, message = "移除管理员权限失败"}
    end
end

-- ==============================================
-- 系统管理功能
-- ==============================================

-- 获取完整系统统计
function AdminDataService.getCompleteSystemStats()
    local allUsersData = AdminDataService.getAllUsersData()
    local allItems = DataStoreManager.getAllItems()

    local stats = {}

    -- 用户统计
    local userStats = {
        total_users = 0,
        active_users = 0,
        banned_users = 0,
        admin_users = 0,
        active_last_week = 0,
        new_users_30_days = 0
    }

    local currentTime = os.time()
    local weekAgo = currentTime - (7 * 24 * 60 * 60)
    local monthAgo = currentTime - (30 * 24 * 60 * 60)

    for userId, userData in pairs(allUsersData) do
        userStats.total_users = userStats.total_users + 1

        if userData.status == "active" then
            userStats.active_users = userStats.active_users + 1
        elseif userData.status == "banned" then
            userStats.banned_users = userStats.banned_users + 1
        end

        if userData.isAdmin then
            userStats.admin_users = userStats.admin_users + 1
        end

        if userData.lastLogin and userData.lastLogin >= weekAgo then
            userStats.active_last_week = userStats.active_last_week + 1
        end

        if userData.createdAt and userData.createdAt >= monthAgo then
            userStats.new_users_30_days = userStats.new_users_30_days + 1
        end
    end

    stats.users = userStats

    -- 交易统计（需要遍历所有用户的交易记录）
    local transactionStats = {
        total_transactions = 0,
        total_buys = 0,
        total_sells = 0,
        total_spent = 0,
        total_earned = 0,
        transactions_24h = 0,
        transactions_7d = 0
    }

    local dayAgo = currentTime - (24 * 60 * 60)
    local sevenDaysAgo = currentTime - (7 * 24 * 60 * 60)

    for userId, userData in pairs(allUsersData) do
        local userTransactionsKey = "user_transactions_" .. userId
        local transactions = DataStoreManager.safeGetAsync("TRANSACTIONS", userTransactionsKey, {})

        for _, transaction in ipairs(transactions) do
            transactionStats.total_transactions = transactionStats.total_transactions + 1

            if transaction.type == "buy" then
                transactionStats.total_buys = transactionStats.total_buys + 1
                transactionStats.total_spent = transactionStats.total_spent + transaction.totalAmount
            elseif transaction.type == "sell" then
                transactionStats.total_sells = transactionStats.total_sells + 1
                transactionStats.total_earned = transactionStats.total_earned + transaction.totalAmount
            end

            if transaction.createdAt >= dayAgo then
                transactionStats.transactions_24h = transactionStats.transactions_24h + 1
            end

            if transaction.createdAt >= sevenDaysAgo then
                transactionStats.transactions_7d = transactionStats.transactions_7d + 1
            end
        end
    end

    stats.transactions = transactionStats

    -- 商品统计
    local itemStats = {
        total_items = 0,
        active_items = 0,
        out_of_stock_items = 0,
        average_price = 0
    }

    local totalPrice = 0
    for itemId, itemData in pairs(allItems) do
        itemStats.total_items = itemStats.total_items + 1
        totalPrice = totalPrice + itemData.price

        if itemData.isActive then
            itemStats.active_items = itemStats.active_items + 1
        end

        if itemData.currentStock == 0 then
            itemStats.out_of_stock_items = itemStats.out_of_stock_items + 1
        end
    end

    if itemStats.total_items > 0 then
        itemStats.average_price = totalPrice / itemStats.total_items
    end

    stats.items = itemStats

    -- 会员统计
    local membershipStats = {
        total_members = 0,
        active_members = 0,
        expired_members = 0
    }

    for userId, userData in pairs(allUsersData) do
        if userData.membership and userData.membership.membershipId then
            membershipStats.total_members = membershipStats.total_members + 1

            if userData.membership.isActive and userData.membership.endDate > currentTime then
                membershipStats.active_members = membershipStats.active_members + 1
            else
                membershipStats.expired_members = membershipStats.expired_members + 1
            end
        end
    end

    stats.membership = membershipStats

    return stats
end

-- ==============================================
-- 商品管理功能
-- ==============================================

-- 更新商品库存
function AdminDataService.updateItemStock(itemId, stock)
    local success = DataStoreManager.safeUpdateAsync("ITEMS", "all_items", function(currentData)
        local items = currentData or {}
        if items[itemId] then
            items[itemId].currentStock = stock
            items[itemId].updatedAt = os.time()
        end
        return items
    end)

    return success
end

-- 更新商品状态
function AdminDataService.updateItemStatus(itemId, active)
    local success = DataStoreManager.safeUpdateAsync("ITEMS", "all_items", function(currentData)
        local items = currentData or {}
        if items[itemId] then
            items[itemId].isActive = active
            items[itemId].updatedAt = os.time()
        end
        return items
    end)

    return success
end

-- 获取商品列表
function AdminDataService.getItemsList(page, limit, category, isActive)
    page = page or 1
    limit = limit or 20
    local offset = (page - 1) * limit

    local allItems = DataStoreManager.getAllItems()
    local filteredItems = {}

    for itemId, itemData in pairs(allItems) do
        local shouldInclude = true

        -- 状态筛选
        if isActive ~= nil and itemData.isActive ~= isActive then
            shouldInclude = false
        end

        -- 分类筛选
        if category and category ~= "" and itemData.category ~= category then
            shouldInclude = false
        end

        if shouldInclude then
            table.insert(filteredItems, {
                id = itemData.id,
                name = itemData.name,
                description = itemData.description,
                price = itemData.price,
                sell_price = itemData.sellPrice,
                max_quantity = itemData.maxQuantity,
                current_stock = itemData.currentStock,
                daily_purchase_limit = itemData.dailyPurchaseLimit,
                can_sell = itemData.canSell,
                category = itemData.category,
                image_url = itemData.imageUrl,
                is_active = itemData.isActive,
                sort_order = itemData.sortOrder,
                created_at = itemData.createdAt,
                updated_at = itemData.updatedAt
            })
        end
    end

    -- 排序：会员商品在前，然后按sortOrder降序
    table.sort(filteredItems, function(a, b)
        if a.category == "membership" and b.category ~= "membership" then
            return true
        elseif a.category ~= "membership" and b.category == "membership" then
            return false
        else
            return (a.sort_order or 0) > (b.sort_order or 0)
        end
    end)

    -- 分页
    local paginatedItems = {}
    local startIndex = offset + 1
    local endIndex = math.min(startIndex + limit - 1, #filteredItems)

    for i = startIndex, endIndex do
        table.insert(paginatedItems, filteredItems[i])
    end

    return {
        items = paginatedItems,
        total = #filteredItems,
        page = page,
        limit = limit,
        totalPages = math.ceil(#filteredItems / limit)
    }
end

-- 根据ID获取商品详情
function AdminDataService.getItemById(itemId)
    local itemData = DataStoreManager.getItem(itemId)

    if itemData then
        return {
            id = itemData.id,
            name = itemData.name,
            description = itemData.description,
            price = itemData.price,
            sell_price = itemData.sellPrice,
            max_quantity = itemData.maxQuantity,
            current_stock = itemData.currentStock,
            daily_purchase_limit = itemData.dailyPurchaseLimit,
            can_sell = itemData.canSell,
            category = itemData.category,
            image_url = itemData.imageUrl,
            is_active = itemData.isActive,
            sort_order = itemData.sortOrder,
            created_at = itemData.createdAt,
            updated_at = itemData.updatedAt
        }
    end

    return nil
end

-- 获取所有商品分类
function AdminDataService.getItemCategories()
    local allItems = DataStoreManager.getAllItems()
    local categories = {}
    local categorySet = {}

    for itemId, itemData in pairs(allItems) do
        if itemData.isActive and not categorySet[itemData.category] then
            categorySet[itemData.category] = true
            table.insert(categories, itemData.category)
        end
    end

    table.sort(categories)

    return categories
end

-- ==============================================
-- 会员管理功能
-- ==============================================

-- 获取会员列表
function AdminDataService.getMembersList(page, limit, status)
    page = page or 1
    limit = limit or 20
    local offset = (page - 1) * limit

    local allUsersData = AdminDataService.getAllUsersData()
    local members = {}

    for userId, userData in pairs(allUsersData) do
        if userData.membership and userData.membership.membershipId then
            local membershipStatus = UserDataService.getMembershipStatus(userId)

            -- 状态筛选
            local shouldInclude = true
            if status == "active" and not membershipStatus.isValid then
                shouldInclude = false
            elseif status == "expired" and membershipStatus.isValid then
                shouldInclude = false
            end

            if shouldInclude then
                table.insert(members, {
                    user_id = userData.userId,
                    username = userData.username,
                    display_name = userData.displayName,
                    membership_id = userData.membership.membershipId,
                    start_date = userData.membership.startDate and os.date("%Y-%m-%d", userData.membership.startDate) or nil,
                    end_date = userData.membership.endDate and os.date("%Y-%m-%d", userData.membership.endDate) or nil,
                    daily_reward_coins = userData.membership.dailyReward,
                    is_active = userData.membership.isActive,
                    created_at = userData.membership.createdAt,
                    updated_at = userData.updatedAt,
                    status = membershipStatus.isValid and "active" or "expired"
                })
            end
        end
    end

    -- 按创建时间降序排序
    table.sort(members, function(a, b)
        return (a.created_at or 0) > (b.created_at or 0)
    end)

    -- 分页
    local paginatedMembers = {}
    local startIndex = offset + 1
    local endIndex = math.min(startIndex + limit - 1, #members)

    for i = startIndex, endIndex do
        table.insert(paginatedMembers, members[i])
    end

    return {
        members = paginatedMembers,
        pagination = {
            page = page,
            limit = limit,
            total = #members,
            totalPages = math.ceil(#members / limit)
        }
    }
end

-- 获取所有用户及其会员状态
function AdminDataService.getAllUsersWithMembershipStatus(page, limit, status)
    page = page or 1
    limit = limit or 20
    local offset = (page - 1) * limit

    local allUsersData = AdminDataService.getAllUsersData()
    local users = {}

    for userId, userData in pairs(allUsersData) do
        local membershipStatus = UserDataService.getMembershipStatus(userId)

        -- 状态筛选
        local shouldInclude = true
        if status == "member" and not membershipStatus.isValid then
            shouldInclude = false
        elseif status == "expired" and (not membershipStatus.hasMembership or membershipStatus.isValid) then
            shouldInclude = false
        elseif status == "non_member" and membershipStatus.hasMembership then
            shouldInclude = false
        end

        if shouldInclude then
            table.insert(users, {
                user_id = userData.userId,
                username = userData.username,
                display_name = userData.displayName,
                coins = userData.coins,
                user_status = userData.status,
                is_admin = userData.isAdmin,
                user_created_at = userData.createdAt,

                membership_id = membershipStatus.membershipId,
                start_date = membershipStatus.startDate,
                end_date = membershipStatus.endDate,
                daily_reward_coins = membershipStatus.dailyReward,
                membership_active = membershipStatus.isActive,
                membership_created_at = userData.membership and userData.membership.createdAt or nil,

                membership_status = membershipStatus.isValid and "active" or (membershipStatus.hasMembership and "expired" or "none"),
                days_remaining = membershipStatus.daysRemaining
            })
        end
    end

    -- 按用户创建时间降序排序
    table.sort(users, function(a, b)
        return (a.user_created_at or 0) > (b.user_created_at or 0)
    end)

    -- 分页
    local paginatedUsers = {}
    local startIndex = offset + 1
    local endIndex = math.min(startIndex + limit - 1, #users)

    for i = startIndex, endIndex do
        table.insert(paginatedUsers, users[i])
    end

    return {
        users = paginatedUsers,
        pagination = {
            page = page,
            limit = limit,
            total = #users,
            totalPages = math.ceil(#users / limit)
        }
    }
end

-- 购买会员
function AdminDataService.buyMembership(userId, durationDays, dailyReward)
    userId = tostring(userId)
    durationDays = durationDays or 30
    dailyReward = dailyReward or 100

    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        -- 确保membership字段存在
        if not currentData.membership then
            currentData.membership = {
                isActive = false,
                membershipId = nil,
                startDate = nil,
                endDate = nil,
                dailyReward = 100
            }
        end

        local now = os.time()
        local startDate = now
        local endDate = now + (durationDays * 24 * 60 * 60)

        -- 如果有现有会员，从结束日期开始延期
        if currentData.membership.isActive and currentData.membership.endDate and currentData.membership.endDate > now then
            startDate = currentData.membership.endDate
            endDate = startDate + (durationDays * 24 * 60 * 60)
        end

        currentData.membership = {
            isActive = true,
            membershipId = HttpService:GenerateGUID(false),
            startDate = startDate,
            endDate = endDate,
            dailyReward = dailyReward,
            createdAt = now
        }

        currentData.updatedAt = now

        return currentData
    end)

    if success and result then
        -- 清除会员状态缓存确保下次获取最新数据
        local UserDataService = require(game:GetService("ServerScriptService").Server.datastoreservice:WaitForChild("UserDataService"))
        if UserDataService.clearMembershipCache then
            UserDataService.clearMembershipCache(userId)
        end

        return {
            membershipId = result.membership.membershipId,
            startDate = os.date("%Y-%m-%d", result.membership.startDate),
            endDate = os.date("%Y-%m-%d", result.membership.endDate),
            durationDays = durationDays,
            dailyReward = dailyReward
        }
    end

    return nil
end

-- 取消会员
function AdminDataService.cancelMembership(userId)
    userId = tostring(userId)
    local today = os.date("%Y-%m-%d")

    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        -- 确保membership字段存在
        if not currentData.membership then
            error("用户没有会员记录")
        end

        if not currentData.membership.isActive then
            error("用户没有活跃的会员记录")
        end

        currentData.membership.endDate = os.time() -- 设置为当前时间，立即过期
        currentData.membership.isActive = false
        currentData.updatedAt = os.time()

        return currentData
    end)

    if success then
        -- 清除会员状态缓存确保下次获取最新数据
        local UserDataService = require(game:GetService("ServerScriptService").Server.datastoreservice:WaitForChild("UserDataService"))
        if UserDataService.clearMembershipCache then
            UserDataService.clearMembershipCache(userId)
        end

        return {
            success = true,
            message = "会员已取消",
            endDate = today
        }
    else
        return {
            success = false,
            message = "取消会员失败"
        }
    end
end

-- 延长会员
function AdminDataService.extendMembership(userId, days)
    userId = tostring(userId)

    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        -- 确保membership字段存在
        if not currentData.membership then
            currentData.membership = {
                isActive = false,
                membershipId = nil,
                startDate = nil,
                endDate = nil,
                dailyReward = 100
            }
        end

        -- 如果没有活跃会员，创建新会员
        if not currentData.membership.isActive then
            local now = os.time()
            currentData.membership = {
                isActive = true,
                membershipId = HttpService:GenerateGUID(false),
                startDate = now,
                endDate = now + (days * 24 * 60 * 60),
                dailyReward = currentData.membership.dailyReward or 100,
                createdAt = now
            }
            currentData.updatedAt = now
            return currentData, nil, currentData.membership.endDate
        end

        local oldEndDate = currentData.membership.endDate
        local newEndDate = oldEndDate + (days * 24 * 60 * 60)

        currentData.membership.endDate = newEndDate
        currentData.updatedAt = os.time()

        return currentData, oldEndDate, newEndDate
    end)

    if success and result then
        local oldEndDate, newEndDate = result[2], result[3]

        -- 延长会员后立即发送当日奖励
        local UserDataService = require(game:GetService("ServerScriptService").Server.datastoreservice:WaitForChild("UserDataService"))
        local immediateReward = UserDataService.claimTodayMembershipReward(userId)
        if immediateReward and immediateReward.success then
            print("🎁 [extendMembership] 已为用户", userId, "发送当日会员奖励:", immediateReward.totalRewards)
        end

        return {
            success = true,
            oldEndDate = os.date("%Y-%m-%d", oldEndDate),
            newEndDate = os.date("%Y-%m-%d", newEndDate),
            extendedDays = days,
            immediateReward = immediateReward
        }
    else
        return {
            success = false,
            message = "延长会员失败"
        }
    end
end

-- 设置会员绝对天数（与延长会员不同，这是设置总天数）
function AdminDataService.setMembershipDays(userId, days)
    userId = tostring(userId)
    days = tonumber(days) or 0

    print("🔧 [setMembershipDays] 开始处理 - 用户ID:", userId, "天数:", days)

    if days < 0 then
        print("❌ [setMembershipDays] 天数验证失败:", days)
        return {
            success = false,
            message = "天数不能为负数"
        }
    end

    print("🔧 [setMembershipDays] 开始数据存储操作...")
    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            print("❌ [setMembershipDays] 用户数据不存在:", userId)
            error("用户不存在")
        end
        print("✅ [setMembershipDays] 找到用户数据，继续处理...")

        local now = os.time()

        -- 确保membership字段存在
        if not currentData.membership then
            currentData.membership = {
                isActive = false,
                membershipId = nil,
                startDate = nil,
                endDate = nil,
                dailyReward = 100
            }
        end

        local oldEndDate = currentData.membership.endDate
        local oldDaysRemaining = 0

        -- 计算原有剩余天数
        if oldEndDate and oldEndDate > now then
            oldDaysRemaining = math.ceil((oldEndDate - now) / (24 * 60 * 60))
        end

        if days == 0 then
            -- 设置为0天等于取消会员
            currentData.membership.isActive = false
            currentData.membership.endDate = now
            currentData.updatedAt = now

            return currentData, oldDaysRemaining, 0, false
        else
            -- 设置新的会员天数
            local newEndDate = now + (days * 24 * 60 * 60)

            currentData.membership.isActive = true
            if not currentData.membership.membershipId then
                currentData.membership.membershipId = HttpService:GenerateGUID(false)
            end
            if not currentData.membership.startDate then
                currentData.membership.startDate = now
            end
            currentData.membership.endDate = newEndDate
            currentData.updatedAt = now

            return currentData, oldDaysRemaining, days, true
        end
    end)

    if success and result then
        local oldDaysRemaining, newDays, isActive = result[2], result[3], result[4]

        -- 确保 newDays 不为 nil
        newDays = newDays or days or 0
        oldDaysRemaining = oldDaysRemaining or 0
        isActive = isActive ~= nil and isActive or false

        print("✅ [setMembershipDays] 数据存储成功 - 原天数:", oldDaysRemaining, "新天数:", newDays, "激活状态:", isActive)

        -- 清除会员状态缓存确保下次获取最新数据
        local UserDataService = require(game:GetService("ServerScriptService").Server.datastoreservice:WaitForChild("UserDataService"))
        if UserDataService.clearMembershipCache then
            UserDataService.clearMembershipCache(userId)
            print("✅ [setMembershipDays] 缓存已清除")
        end

        -- 如果是激活会员（天数大于0），立即发送当日奖励
        local immediateReward = nil
        if isActive and newDays > 0 then
            immediateReward = UserDataService.claimTodayMembershipReward(userId)
            if immediateReward and immediateReward.success then
                print("🎁 [setMembershipDays] 已为用户", userId, "发送当日会员奖励:", immediateReward.totalRewards)
            end
        end

        local resultData = {
            success = true,
            message = newDays == 0 and "会员已取消" or ("会员天数已设置为 " .. tostring(newDays) .. " 天"),
            oldDaysRemaining = oldDaysRemaining,
            newDays = newDays,
            isActive = isActive,
            immediateReward = immediateReward
        }
        print("✅ [setMembershipDays] 返回成功结果:", resultData.message)
        return resultData
    else
        print("❌ [setMembershipDays] 数据存储失败 - success:", success, "result:", result)
        return {
            success = false,
            message = "设置会员天数失败: " .. tostring(result or "未知错误")
        }
    end
end

-- 设置会员每日奖励
function AdminDataService.setMembershipReward(userId, dailyReward)
    userId = tostring(userId)
    dailyReward = tonumber(dailyReward) or 100

    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData then
            error("用户不存在")
        end

        -- 确保membership字段存在
        if not currentData.membership then
            currentData.membership = {
                isActive = false,
                membershipId = nil,
                startDate = nil,
                endDate = nil,
                dailyReward = 100
            }
        end

        local oldReward = currentData.membership.dailyReward or 100
        currentData.membership.dailyReward = dailyReward
        currentData.updatedAt = os.time()

        return currentData, oldReward, dailyReward
    end)

    if success and result then
        local oldReward, newReward = result[2], result[3]

        return {
            success = true,
            message = "每日奖励设置成功",
            oldReward = oldReward,
            newReward = newReward
        }
    else
        return {
            success = false,
            message = "设置每日奖励失败"
        }
    end
end

-- 更新会员信息
function AdminDataService.updateMembershipInfo(userId, updateData)
    userId = tostring(userId)

    local success, result = DataStoreManager.safeUpdateAsync("USERS", userId, function(currentData)
        if not currentData or not currentData.membership then
            error("用户没有激活的会员记录")
        end

        -- 更新结束日期
        if updateData.endDate or updateData.end_date then
            local endDate = updateData.endDate or updateData.end_date
            if type(endDate) == "string" then
                -- 假设日期格式为 YYYY-MM-DD，需要转换为时间戳
                local year, month, day = endDate:match("(%d+)-(%d+)-(%d+)")
                if year and month and day then
                    endDate = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day)})
                end
            end
            currentData.membership.endDate = endDate
        end

        -- 更新状态
        local finalStatus = updateData.status ~= nil and updateData.status or updateData.is_active
        if finalStatus ~= nil then
            currentData.membership.isActive = finalStatus == "active" or finalStatus == true
        end

        -- 更新每日奖励
        if updateData.daily_reward_coins ~= nil then
            currentData.membership.dailyReward = updateData.daily_reward_coins
        end

        currentData.updatedAt = os.time()

        return currentData
    end)

    if success then
        return {
            success = true,
            affectedRows = 1,
            membershipId = result.membership.membershipId
        }
    else
        return {
            success = false,
            message = "更新会员信息失败"
        }
    end
end

-- 获取会员统计
function AdminDataService.getMembershipStats()
    local allUsersData = AdminDataService.getAllUsersData()
    local currentTime = os.time()

    local stats = {
        total_members = 0,
        active_members = 0,
        expired_members = 0
    }

    for userId, userData in pairs(allUsersData) do
        if userData.membership and userData.membership.membershipId then
            stats.total_members = stats.total_members + 1

            if userData.membership.isActive and userData.membership.endDate > currentTime then
                stats.active_members = stats.active_members + 1
            else
                stats.expired_members = stats.expired_members + 1
            end
        end
    end

    return stats
end

-- ==============================================
-- 管理员操作日志
-- ==============================================

-- 记录管理员操作日志
function AdminDataService.logAdminAction(adminUserId, action, details)
    local logEntry = {
        id = HttpService:GenerateGUID(false),
        admin_user_id = adminUserId,
        action = action,
        details = details,
        timestamp = os.time()
    }

    local success = DataStoreManager.safeUpdateAsync("ADMIN_DATA", "action_logs", function(currentData)
        local logs = currentData or {}
        table.insert(logs, 1, logEntry) -- 最新的日志在前面

        -- 只保留最近1000条日志
        if #logs > 1000 then
            for i = 1001, #logs do
                logs[i] = nil
            end
        end

        return logs
    end)

    return success
end

-- ==============================================
-- 工具函数
-- ==============================================

-- 获取所有用户数据（内部函数，用于统计和查询）
function AdminDataService.getAllUsersData()
    -- 尝试从全局用户索引获取用户列表
    local allUsersIndex = DataStoreManager.safeGetAsync("USERS", "all_users_index", {})
    local usersData = {}

    -- 如果有用户索引，逐个获取用户数据
    for userId, _ in pairs(allUsersIndex) do
        local userData = DataStoreManager.safeGetAsync("USERS", userId, nil)
        if userData then
            usersData[userId] = userData
        end
    end

    -- 如果没有找到任何用户，尝试从模拟数据存储获取（Studio模式）
    if next(usersData) == nil and DataStoreManager.isStudioMode then
        local mockUsers = DataStoreManager.getDataStore("USERS")
        return mockUsers or {}
    end

    return usersData
end

print("👑 管理员数据服务已加载")

return AdminDataService
