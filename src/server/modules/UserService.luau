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
        -- 检查管理员权限（使用API验证）
        local isApiAdmin = userData and userData.isAdmin
        local isValidAdminCheck, _ = DataService.checkAdminPermission(userId)
        local finalIsAdmin = isApiAdmin or isValidAdminCheck

        if isValidAdminCheck then
            print("⚡ [认证] " .. player.Name .. " 通过API权限检查确认为管理员")
        elseif isApiAdmin then
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
            DataService.removeToken(session.userId)
        end
        playerSessions[player] = nil
    end
end

function UserService.isPlayerAuthenticated(player: Player): boolean
    local session = getPlayerSession(player)
    return session and session.authenticated and DataService.isAuthenticated(session.userId)
end

function UserService.isPlayerAdmin(player: Player): boolean
    -- 使用API权限检查
    local userId = tostring(player.UserId)
    local isValidAdminCheck, _ = DataService.checkAdminPermission(userId)

    if isValidAdminCheck then
        print("⚡ [UserService] " .. player.Name .. " 通过API权限检查验证为管理员")
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
                table.insert(playerData.transactionHistory, {
                    id = transaction.id,
                    itemId = transaction.item_id,
                    itemName = transaction.item_name,
                    type = transaction.type,
                    quantity = transaction.quantity,
                    unitPrice = transaction.unit_price,
                    totalAmount = transaction.total_amount,
                    transactionDate = transaction.transaction_date,
                    createdAt = transaction.created_at,
                    timestamp = transaction.created_at -- 为了兼容性
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

    local success, message = DataService.buyItem(session.userId, itemId, quantity)

    if success then
        -- 获取更新后的用户数据
        local userData = DataService.getUserData(session.userId)
        local inventory = DataService.getUserInventory(session.userId)
        local membershipStatus = DataService.getMembershipStatus(session.userId)

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
        Events.User.BuyItem:FireClient(player, true, message, playerData)
        print("🛒 [购买] " .. player.Name .. " 购买了 " .. itemId .. " x" .. quantity)

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
                table.insert(clientTransactions, {
                    id = transaction.id,
                    itemId = transaction.item_id,
                    itemName = transaction.item_name,
                    type = transaction.type,
                    quantity = transaction.quantity,
                    unitPrice = transaction.unit_price,
                    totalAmount = transaction.total_amount,
                    transactionDate = transaction.transaction_date,
                    createdAt = transaction.created_at,
                    timestamp = transaction.created_at -- 为了兼容性
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
