-- 普通用户服务模块
-- 处理用户认证、数据获取、购买/出售等基础功能

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserService = {}

-- 等待模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))
local DataService = require(script.Parent:WaitForChild("DataService"))

-- 玩家会话管理
local playerSessions = {} -- 存储已登录的玩家

-- ==============================================
-- 内部工具函数
-- ==============================================

local function getPlayerSession(player: Player)
    return playerSessions[player]
end

-- ==============================================
-- 用户认证和管理
-- ==============================================

function UserService.authenticatePlayer(player: Player)
    local userId = tostring(player.UserId)
    local username = player.Name
    local displayName = player.DisplayName ~= player.Name and player.DisplayName or nil

    local success, userData = DataService.authenticateUser(userId, username, displayName)
    if success then
        -- 优先检查配置文件中的管理员用户名（立即生效）
        local SharedModules = game:GetService("ReplicatedStorage"):WaitForChild("SharedModules")
        local Config = require(SharedModules:WaitForChild("Config"))
        local defaultAdminUsernames = Config.ADMIN.DEFAULT_ADMIN_USERNAMES or {}

        local isConfigAdmin = false
        for _, adminUsername in ipairs(defaultAdminUsernames) do
            if player.Name == adminUsername then
                isConfigAdmin = true
                print("⚡ [认证] " .. player.Name .. " 通过配置文件确认为管理员（立即生效）")
                break
            end
        end

        -- 检查数据库中的管理员权限
        local isDataAdmin = userData and userData.isAdmin
        local isValidAdminCheck, _ = DataService.checkAdminPermission(userId)

        -- 最终管理员状态：配置文件优先
        local finalIsAdmin = isConfigAdmin or isDataAdmin or isValidAdminCheck

        if isConfigAdmin then
            print("✅ [认证] " .. player.Name .. " 管理员权限立即生效（来源：配置文件）")
            -- 异步确保数据库中也设置了管理员标识
            spawn(function()
                wait(1)
                local success = pcall(function()
                    local AdminDataService = require(script.Parent.Parent.data:WaitForChild("AdminDataService"))
                    AdminDataService.promoteToAdmin(userId)
                end)
                if success then
                    print("✅ [认证] " .. player.Name .. " 数据库管理员标识已同步设置")
                else
                    print("⚠️ [认证] " .. player.Name .. " 数据库管理员标识同步失败，但配置文件权限仍有效")
                end
            end)
        elseif isValidAdminCheck then
            print("⚡ [认证] " .. player.Name .. " 通过权限检查确认为管理员")
        elseif isDataAdmin then
            print("⚡ [认证] " .. player.Name .. " 通过用户数据确认为管理员")
        end

        playerSessions[player] = {
            userId = userId,
            userData = userData,
            authenticated = true,
            isAdmin = finalIsAdmin
        }

        -- 处理每日登录奖励（异步执行）
        spawn(function()
            local rewardSuccess, rewardMessage, rewardData = DataService.claimDailyRewards(userId)
            if rewardSuccess and rewardData and rewardData.totalRewards > 0 then
                print("🎁 [每日奖励] " .. player.Name .. " 领取了 " .. rewardData.totalRewards .. " 金币")
                if rewardData.rewardedDays and rewardData.rewardedDays > 1 then
                    print("📅 [补发奖励] " .. player.Name .. " 补发了 " .. (rewardData.rewardedDays - 1) .. " 天的奖励")
                end
                -- 可以在这里通知客户端
            end
        end)

        print("✅ [认证] " .. player.Name .. " 认证成功")
        return true
    else
        warn("❌ [认证] " .. player.Name .. " 认证失败")
        return false
    end
end

function UserService.cleanupPlayer(player: Player)
    if playerSessions[player] then
        local session = playerSessions[player]
        if session.userId then
            -- 清理用户会话数据 (DataService使用内部会话管理)
            pcall(function()
                DataService.clearUserSession(session.userId)
            end)
        end
        playerSessions[player] = nil
        print("🧹 [清理] " .. player.Name .. " 会话数据已清理")
    end
end

function UserService.isPlayerAuthenticated(player: Player): boolean
    local session = getPlayerSession(player)
    return session and session.authenticated and DataService.isAuthenticated(session.userId)
end

function UserService.isPlayerAdmin(player: Player): boolean
    -- 使用权限检查
    local userId = tostring(player.UserId)
    local isValidAdminCheck, _ = DataService.checkAdminPermission(userId)

    if isValidAdminCheck then
        print("⚡ [UserService] " .. player.Name .. " 通过权限检查验证为管理员")
        return true
    end

    -- 备用：检查session中的isAdmin标志
    local session = getPlayerSession(player)
    local sessionAdmin = session and session.isAdmin

    if sessionAdmin then
        print("⚡ [UserService] " .. player.Name .. " 通过session验证为管理员")
        return true
    end

    print("❌ [UserService] " .. player.Name .. " 不是管理员")
    return false
end

-- 刷新玩家数据（用于实时更新会员状态等）
function UserService.refreshPlayerData(player: Player)
    print("🔄 [UserService] 刷新玩家数据:", player.Name)

    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        warn("❌ [UserService] 无法刷新未认证用户的数据:", player.Name)
        return
    end

    -- 清除会员状态缓存以确保获取最新数据
    local UserDataService = DataService.getUserDataService and DataService.getUserDataService() or require(script.Parent.Parent.data:WaitForChild("UserDataService"))
    if UserDataService.clearMembershipCache then
        UserDataService.clearMembershipCache(session.userId)
    end

    -- 发送最新的玩家数据
    handleGetPlayerData(player)

    print("✅ [UserService] 玩家数据刷新完成:", player.Name)
end

-- ==============================================
-- 数据处理函数
-- ==============================================

local function handleGetPlayerData(player: Player)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        -- 尝试重新认证
        if not UserService.authenticatePlayer(player) then
            Events.User.GetPlayerData:FireClient(player, nil)
            return
        end
        session = getPlayerSession(player)
    end

    -- 获取最新的用户数据
    local userData = DataService.getUserData(session.userId)
    if userData then
        local inventory = DataService.getUserInventory(session.userId)
        local membershipStatus = DataService.getMembershipStatus(session.userId)

        -- 获取用户交易记录
        local transactionSuccess, transactionData, _ = DataService.getUserTransactions(session.userId, 20, 0, nil)

        -- 转换为客户端格式
        local playerData = {
            coins = userData.coins,
            inventory = inventory or {},
            membership = membershipStatus or {
                hasMembership = false,
                isValid = false,
                daysRemaining = 0,
                membershipType = nil,
                startDate = nil,
                endDate = nil,
                dailyReward = 0
            },
            stats = {
                totalPurchases = userData.total_purchases or 0,
                totalSales = userData.total_sales or 0,
                totalSpent = userData.total_spent or 0,
                totalEarned = userData.total_earned or 0
            },
            transactionHistory = {}
        }

        -- 添加交易记录到玩家数据中
        if transactionSuccess and transactionData and transactionData.transactions then
            for _, transaction in ipairs(transactionData.transactions) do
                -- 确保时间戳字段存在和正确
                local createdAt = transaction.created_at or transaction.timestamp or os.time()
                local transactionDate = transaction.transaction_date or os.date("%Y-%m-%d", createdAt)

                table.insert(playerData.transactionHistory, {
                    id = transaction.id,
                    itemId = transaction.item_id,
                    itemName = transaction.item_name,
                    type = transaction.type,
                    quantity = transaction.quantity,
                    unitPrice = transaction.unit_price,
                    totalAmount = transaction.total_amount,
                    transactionDate = transactionDate,
                    createdAt = createdAt,
                    timestamp = createdAt -- 为了兼容性
                })
            end
        end

        session.userData = userData
        Events.User.GetPlayerData:FireClient(player, playerData)
    else
        Events.User.GetPlayerData:FireClient(player, nil)
    end
end

local function handleGetShopData(player: Player)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        Events.User.GetShopData:FireClient(player, {})
        return
    end

    local shopItems = DataService.getShopItems()
    if shopItems then
        -- 转换格式以保持兼容性
        local shopData = {}
        for itemId, item in pairs(shopItems) do
            shopData[itemId] = {
                id = item.id,
                name = item.name,
                price = item.price,
                maxQuantity = item.max_quantity,
                currentStock = item.current_stock,
                description = item.description,
                icon = item.icon,
                imageId = item.image_id,
                category = item.category,
                sellPrice = item.sell_price
            }
        end

        Events.User.GetShopData:FireClient(player, shopData)
    else
        Events.User.GetShopData:FireClient(player, {})
    end
end

local function handleBuyItem(player: Player, itemId: string, quantity: number)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        Events.User.BuyItem:FireClient(player, false, "用户未认证", nil)
        return
    end

    -- 验证输入
    if not itemId or quantity <= 0 then
        Events.User.BuyItem:FireClient(player, false, "无效的参数", nil)
        return
    end

    -- 检查是否为会员商品
    local membershipItems = {"monthly_membership", "weekly_membership", "quarterly_membership", "premium_membership", "vip_membership"}
    local isMembershipItem = false
    for _, membershipItemId in ipairs(membershipItems) do
        if itemId == membershipItemId then
            isMembershipItem = true
            break
        end
    end

    local success, message = DataService.buyItem(session.userId, itemId, quantity)

    if success then
        -- 如果购买的是会员商品，特殊处理确保会员状态更新
        if isMembershipItem then
            local UserDataService = require(script.Parent.Parent.data:WaitForChild("UserDataService"))
            if UserDataService.clearMembershipCache then
                UserDataService.clearMembershipCache(session.userId)
                print("🧹 [购买] 清除会员缓存:", player.Name, itemId)
            end

            -- 稍等一下确保数据完全写入
            task.wait(0.2)
            print("✅ [购买] 会员商品购买成功，准备获取最新状态:", player.Name, itemId)

            -- 再次清除缓存确保获取最新数据
            if UserDataService.clearMembershipCache then
                UserDataService.clearMembershipCache(session.userId)
            end
        end

        -- 获取更新后的用户数据
        local userData = DataService.getUserData(session.userId)
        local inventory = DataService.getUserInventory(session.userId)
        local membershipStatus = DataService.getMembershipStatus(session.userId)

        -- 如果是会员商品，记录状态用于调试
        if isMembershipItem then
            if membershipStatus then
                print("🔍 [购买] 获取到的会员状态:", membershipStatus.hasMembership and "有会员" or "无会员",
                      "有效:", membershipStatus.isValid and "是" or "否",
                      "剩余天数:", membershipStatus.daysRemaining or 0)
            else
                print("⚠️ [购买] 无法获取会员状态，将再次尝试")
                task.wait(0.1)
                membershipStatus = DataService.getMembershipStatus(session.userId)
                if membershipStatus then
                    print("🔍 [购买] 重新获取会员状态成功:", membershipStatus.hasMembership and "有会员" or "无会员",
                          "剩余天数:", membershipStatus.daysRemaining or 0)
                end
            end
        end

        local playerData = {
            coins = userData.coins,
            inventory = inventory or {},
            membership = membershipStatus or {
                hasMembership = false,
                isValid = false,
                daysRemaining = 0,
                membershipType = nil,
                startDate = nil,
                endDate = nil,
                dailyReward = 0
            },
            stats = {
                totalPurchases = userData.total_purchases or 0,
                totalSales = userData.total_sales or 0,
                totalSpent = userData.total_spent or 0,
                totalEarned = userData.total_earned or 0
            }
        }

        session.userData = userData
        -- 为会员商品购买提供特殊消息
        local finalMessage = message
        if isMembershipItem then
            finalMessage = "会员购买成功！" .. message
        end

        Events.User.BuyItem:FireClient(player, true, finalMessage, playerData)
        print("🛒 [购买] " .. player.Name .. " 购买了 " .. itemId .. " x" .. quantity)

        -- 如果购买的是会员商品，打印会员状态信息
        if isMembershipItem and membershipStatus then
            print("👑 [会员] " .. player.Name .. " 购买会员后状态:",
                membershipStatus.isValid and "激活" or "未激活",
                "剩余天数:", membershipStatus.daysRemaining or 0)
        end

        -- 广播商店数据更新给所有玩家
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            handleGetShopData(otherPlayer)
        end
    else
        Events.User.BuyItem:FireClient(player, false, message or "购买失败", nil)
    end
end

local function handleSellItem(player: Player, itemId: string, quantity: number)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        Events.User.SellItem:FireClient(player, false, "用户未认证", nil)
        return
    end

    -- 验证输入
    if not itemId or quantity <= 0 then
        Events.User.SellItem:FireClient(player, false, "无效的参数", nil)
        return
    end

    local success, message = DataService.sellItem(session.userId, itemId, quantity)

    if success then
        -- 获取更新后的用户数据
        local userData = DataService.getUserData(session.userId)
        local inventory = DataService.getUserInventory(session.userId)

        local playerData = {
            coins = userData.coins,
            inventory = inventory or {},
            stats = {
                totalPurchases = userData.total_purchases or 0,
                totalSales = userData.total_sales or 0,
                totalSpent = userData.total_spent or 0,
                totalEarned = userData.total_earned or 0
            }
        }

        session.userData = userData
        Events.User.SellItem:FireClient(player, true, message, playerData)
        print("💰 [卖出] " .. player.Name .. " 卖出了 " .. itemId .. " x" .. quantity)

        -- 广播商店数据更新给所有玩家
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            handleGetShopData(otherPlayer)
        end
    else
        Events.User.SellItem:FireClient(player, false, message or "卖出失败", nil)
    end
end

local function handleRefreshData(player: Player)
    -- 刷新玩家数据和商店数据
    handleGetPlayerData(player)
    handleGetShopData(player)
end

local function handleGetTransactions(player: Player, limit: number?, offset: number?, type: string?)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        Events.User.GetTransactions:FireClient(player, false, "用户未认证", nil)
        return
    end

    -- 设置默认值
    local actualLimit = limit or 50
    local actualOffset = offset or 0

    -- 验证参数
    if actualLimit <= 0 or actualLimit > 100 then
        actualLimit = 50
    end
    if actualOffset < 0 then
        actualOffset = 0
    end

    local success, data, errorMessage = DataService.getUserTransactions(
        session.userId,
        actualLimit,
        actualOffset,
        type
    )

    if success and data then
        -- 转换交易记录格式以供客户端使用
        local clientTransactions = {}

        if data.transactions then
            for i, transaction in ipairs(data.transactions) do
                -- 确保时间戳字段存在和正确
                local createdAt = transaction.created_at or transaction.timestamp or os.time()
                local transactionDate = transaction.transaction_date or os.date("%Y-%m-%d", createdAt)

                table.insert(clientTransactions, {
                    id = transaction.id,
                    itemId = transaction.item_id,
                    itemName = transaction.item_name,
                    type = transaction.type,
                    quantity = transaction.quantity,
                    unitPrice = transaction.unit_price,
                    totalAmount = transaction.total_amount,
                    transactionDate = transactionDate,
                    createdAt = createdAt,
                    timestamp = createdAt -- 为了兼容性
                })
            end
        end

        -- 包含分页和统计信息
        local responseData = {
            transactions = clientTransactions,
            pagination = data.pagination,
            stats = data.stats
        }

        Events.User.GetTransactions:FireClient(player, true, nil, responseData)
        print("📊 [交易记录] " .. player.Name .. " 获取了 " .. #clientTransactions .. " 条交易记录")
    else
        local errorMsg = errorMessage or "获取交易记录失败"
        Events.User.GetTransactions:FireClient(player, false, errorMsg, nil)
        print("❌ [交易记录] " .. player.Name .. " 获取交易记录失败: " .. errorMsg)
    end
end

-- ==============================================
-- 事件连接
-- ==============================================

-- 连接用户事件
Events.User.GetPlayerData.OnServerEvent:Connect(handleGetPlayerData)
Events.User.GetShopData.OnServerEvent:Connect(handleGetShopData)
Events.User.BuyItem.OnServerEvent:Connect(handleBuyItem)
Events.User.SellItem.OnServerEvent:Connect(handleSellItem)
Events.User.RefreshData.OnServerEvent:Connect(handleRefreshData)
Events.User.GetTransactions.OnServerEvent:Connect(handleGetTransactions)


print("👤 普通用户服务已启动")

return UserService
