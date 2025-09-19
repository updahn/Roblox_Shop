-- 商店系统服务端逻辑 - 重构为API代理版本

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 等待共享模块（由Bootstrap脚本设置）
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local ShopData = require(SharedModules:WaitForChild("ShopData"))
local ShopEvents = require(SharedModules:WaitForChild("ShopEvents"))

-- 玩家会话管理
local playerSessions = {} -- 存储已登录的玩家

-- 检查玩家是否为管理员
local function isPlayerAdmin(player)
    return Config.isValidAdmin(player)
end

print("🏪 商店系统已初始化 (API模式)")

-- 玩家认证和数据获取
local function authenticatePlayer(player: Player)
    local userId = tostring(player.UserId)
    local username = player.Name
    local displayName = player.DisplayName ~= player.Name and player.DisplayName or nil

    local success, userData = ShopData.authenticateUser(userId, username, displayName)
    if success then
        playerSessions[player] = {
            userId = userId,
            userData = userData,
            authenticated = true,
            isAdmin = isPlayerAdmin(player)
        }
        print("✅ [认证] " .. player.Name .. " 认证成功 | 金币: " .. (userData.coins or 0))
        return true
    else
        warn("❌ [认证] " .. player.Name .. " 认证失败")
        warn("💡 可能原因：网络连接问题或HTTP服务未启用")
        warn("💡 API地址：" .. Config.getApiUrl("/auth/login"))
        return false
    end
end

-- 获取玩家会话
local function getPlayerSession(player: Player)
    return playerSessions[player]
end

-- 处理获取玩家数据请求
local function handleGetPlayerData(player: Player)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        -- 尝试重新认证
        if not authenticatePlayer(player) then
            ShopEvents.RemoteEvents.GetPlayerData:FireClient(player, nil)
            return
        end
        session = getPlayerSession(player)
    end

    -- 获取最新的用户数据
    local userData = ShopData.getUserData(session.userId)
    if userData then
        -- 获取用户库存
        local inventory = ShopData.getUserInventory(session.userId)

        -- 转换为旧格式以保持兼容性
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

        -- 获取交易记录（最近20条）
        local transactionData = ShopData.getTransactions(session.userId, 20, 0)
        if transactionData and transactionData.transactions then
            playerData.purchaseHistory = {}
            for _, transaction in ipairs(transactionData.transactions) do
                local action, totalCost, totalEarned = "", 0, 0

                if transaction.type == "buy" then
                    action = "buy"
                    totalCost = transaction.total_amount or 0
                elseif transaction.type == "sell" then
                    action = "sell"
                    totalEarned = transaction.total_amount or 0
                elseif transaction.type == "admin" then
                    action = "admin_edit"
                    -- 对于管理员操作，total_amount 表示金币变化量
                    if transaction.total_amount and transaction.total_amount > 0 then
                        totalEarned = transaction.total_amount
                    else
                        totalCost = math.abs(transaction.total_amount or 0)
                    end
                else
                    action = "unknown"
                end

                table.insert(playerData.purchaseHistory, {
                    action = action,
                    itemId = transaction.item_id,
                    itemName = transaction.item_name,
                    quantity = transaction.quantity,
                    totalCost = totalCost,
                    totalEarned = totalEarned,
                    timestamp = transaction.created_at,
                    balanceAfter = transaction.coins_after
                })
            end
        end

        session.userData = userData
        ShopEvents.RemoteEvents.GetPlayerData:FireClient(player, playerData)
    else
        ShopEvents.RemoteEvents.GetPlayerData:FireClient(player, nil)
    end
end

-- 处理获取商店数据请求
local function handleGetShopData(player: Player)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        ShopEvents.RemoteEvents.GetShopData:FireClient(player, {})
        return
    end

    local shopItems = ShopData.getShopItems()
    if shopItems then
        -- 转换格式以保持兼容性
        local shopData = {}
        for itemId, item in pairs(shopItems) do
            shopData[itemId] = {
                id = item.id,
                name = item.name,
                price = item.price,
                maxQuantity = item.max_quantity,
                currentStock = item.current_stock,  -- 直接使用数据库中的当前库存
                description = item.description,
                icon = item.icon,
                imageId = item.image_id,
                category = item.category,
                sellPrice = item.sell_price
            }
        end

        ShopEvents.RemoteEvents.GetShopData:FireClient(player, shopData)
    else
        ShopEvents.RemoteEvents.GetShopData:FireClient(player, {})
    end
end

--- 处理刷新商店数据请求
local function handleRefreshShopData(player: Player)
    -- 直接调用获取商店数据函数，这样会自动刷新
    handleGetShopData(player)
end

-- 处理购买物品
local function handlePurchaseItem(player: Player, itemId: string, quantity: number)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, false, "用户未认证", nil)
        return
    end

    -- 验证输入
    if not itemId or quantity <= 0 then
        ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, false, "无效的参数", nil)
        return
    end

    local success, message = ShopData.buyItem(session.userId, itemId, quantity)

    if success then
        -- 获取更新后的用户数据
        local userData = ShopData.getUserData(session.userId)
        local inventory = ShopData.getUserInventory(session.userId)

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
        ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, true, message, playerData)
        print("🛒 [购买] " .. player.Name .. " 购买了 " .. itemId .. " x" .. quantity)

        -- 立即广播商店数据更新给所有玩家
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            handleGetShopData(otherPlayer)
        end
    else
        ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, false, message or "购买失败", nil)
    end
end

-- 处理卖出物品
local function handleSellItem(player: Player, itemId: string, quantity: number)
    local session = getPlayerSession(player)
    if not session or not session.authenticated then
        ShopEvents.RemoteEvents.SellItem:FireClient(player, false, "用户未认证", nil)
        return
    end

    -- 验证输入
    if not itemId or quantity <= 0 then
        ShopEvents.RemoteEvents.SellItem:FireClient(player, false, "无效的参数", nil)
        return
    end

    local success, message = ShopData.sellItem(session.userId, itemId, quantity)

    if success then
        -- 获取更新后的用户数据
        local userData = ShopData.getUserData(session.userId)
        local inventory = ShopData.getUserInventory(session.userId)

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
        ShopEvents.RemoteEvents.SellItem:FireClient(player, true, message, playerData)
        print("💰 [卖出] " .. player.Name .. " 卖出了 " .. itemId .. " x" .. quantity)

        -- 立即广播商店数据更新给所有玩家
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            handleGetShopData(otherPlayer)
        end
    else
        ShopEvents.RemoteEvents.SellItem:FireClient(player, false, message or "卖出失败", nil)
    end
end

-- 管理员功能：获取所有玩家数据
local function handleGetAllPlayersData(player: Player)
    local session = getPlayerSession(player)
    if not session or not session.authenticated or not session.isAdmin then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试获取所有玩家数据，但不是管理员")
        return
    end

    local success, allUsersData, errorMsg = ShopData.getAllUsers(session.userId, 50, 0)
    if success and allUsersData then
        local allPlayersData = {}
        for _, user in ipairs(allUsersData.users) do
            allPlayersData[user.username] = {
                userId = user.id,
                name = user.username,
                coins = user.coins or 0,
                totalPurchases = user.total_purchases or 0,
                totalSpent = user.total_spent or 0,
                totalSales = user.total_sales or 0,
                totalEarned = user.total_earned or 0,
                inventoryCount = 0 -- 需要单独查询库存
            }
        end

        ShopEvents.RemoteEvents.GetAllPlayersData:FireClient(player, allPlayersData)
        print("👑 [管理员] " .. player.Name .. " 查看了所有玩家数据")
    else
        local errorMessage = errorMsg or "无法获取玩家数据"
        warn("❌ [API错误] " .. errorMessage)
        -- 发送错误信息给客户端（作为第二个参数传递错误信息）
        ShopEvents.RemoteEvents.GetAllPlayersData:FireClient(player, nil, errorMessage)
    end
end

-- 管理员功能：设置玩家金币
local function handleSetPlayerCoins(player: Player, targetPlayerName: string, newCoins: number)
    local session = getPlayerSession(player)
    if not session or not session.authenticated or not session.isAdmin then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试修改 " .. targetPlayerName .. " 的金币，但不是管理员")
        return
    end

    -- 查找目标玩家的ID
    local targetUserId = nil
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer.Name == targetPlayerName then
            targetUserId = tostring(otherPlayer.UserId)
            break
        end
    end

    if not targetUserId then
        ShopEvents.RemoteEvents.SetPlayerCoins:FireClient(player, false, "玩家 " .. targetPlayerName .. " 不在线")
        return
    end

    local success, message = ShopData.setUserCoins(session.userId, targetUserId, newCoins, "管理员调整 by " .. player.Name)

    if success then
        ShopEvents.RemoteEvents.SetPlayerCoins:FireClient(player, true, message)

        -- 通知目标玩家数据更新
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer.Name == targetPlayerName then
                handleGetPlayerData(otherPlayer)
                break
            end
        end

        print("👑 [管理员操作] " .. player.Name .. " 修改了 " .. targetPlayerName .. " 的金币为 " .. newCoins)
    else
        ShopEvents.RemoteEvents.SetPlayerCoins:FireClient(player, false, message or "修改失败")
    end
end

-- 管理员功能：获取玩家购买记录
local function handleGetPlayerPurchaseHistory(player: Player, targetPlayerName: string)
    local session = getPlayerSession(player)
    if not session or not session.authenticated or not session.isAdmin then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试查看 " .. targetPlayerName .. " 的购买记录，但不是管理员")
        return
    end

    -- 查找目标玩家的ID
    local targetUserId = nil
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer.Name == targetPlayerName then
            targetUserId = tostring(otherPlayer.UserId)
            break
        end
    end

    if not targetUserId then
        ShopEvents.RemoteEvents.GetPlayerPurchaseHistory:FireClient(player, targetPlayerName, nil, "玩家不在线")
        return
    end

    local transactionData = ShopData.getTransactions(targetUserId, 50, 0)
    if transactionData then
        local purchaseHistory = {}
        for _, transaction in ipairs(transactionData.transactions) do
            local action, totalCost, totalEarned = "", 0, 0

            if transaction.type == "buy" then
                action = "buy"
                totalCost = transaction.total_amount or 0
            elseif transaction.type == "sell" then
                action = "sell"
                totalEarned = transaction.total_amount or 0
            elseif transaction.type == "admin" then
                action = "admin_edit"
                -- 对于管理员操作，total_amount 表示金币变化量
                if transaction.total_amount and transaction.total_amount > 0 then
                    totalEarned = transaction.total_amount
                else
                    totalCost = math.abs(transaction.total_amount or 0)
                end
            else
                action = "unknown"
            end

            table.insert(purchaseHistory, {
                action = action,
                itemId = transaction.item_id,
                itemName = transaction.item_name,
                quantity = transaction.quantity,
                totalCost = totalCost,
                totalEarned = totalEarned,
                timestamp = transaction.created_at,
                balanceAfter = transaction.coins_after
            })
        end

        ShopEvents.RemoteEvents.GetPlayerPurchaseHistory:FireClient(player, targetPlayerName, purchaseHistory)
        print("👑 [管理员] " .. player.Name .. " 查看了 " .. targetPlayerName .. " 的购买记录")
    end
end

-- 玩家加入游戏时
local function onPlayerAdded(player: Player)
    print("👤 [加入] " .. player.Name .. " 已连接到商店服务器")

    -- 等待一下确保客户端准备好
    wait(2)

    -- 认证玩家
    if authenticatePlayer(player) then
        local session = getPlayerSession(player)
        print("📊 [数据] " .. player.Name .. " | 金币: " .. (session.userData.coins or 0))

        -- 检查是否为管理员
        if session.isAdmin then
            print("👑 [管理员] " .. player.Name .. " 已获得商店管理权限")
        end
    else
        warn("⚠️ [警告] " .. player.Name .. " 无法连接到API服务器")
    end
end

-- 玩家离开游戏时
local function onPlayerRemoving(player: Player)
    print("👋 [离开] " .. player.Name .. " 已断开连接")
    -- 清除会话数据
    playerSessions[player] = nil
end

-- 连接远程事件
ShopEvents.RemoteEvents.GetPlayerData.OnServerEvent:Connect(handleGetPlayerData)
ShopEvents.RemoteEvents.GetShopData.OnServerEvent:Connect(handleGetShopData)
ShopEvents.RemoteEvents.RefreshShopData.OnServerEvent:Connect(handleRefreshShopData)
ShopEvents.RemoteEvents.PurchaseItem.OnServerEvent:Connect(handlePurchaseItem)
ShopEvents.RemoteEvents.SellItem.OnServerEvent:Connect(handleSellItem)

-- 管理员功能事件
ShopEvents.RemoteEvents.GetAllPlayersData.OnServerEvent:Connect(handleGetAllPlayersData)
ShopEvents.RemoteEvents.SetPlayerCoins.OnServerEvent:Connect(handleSetPlayerCoins)
ShopEvents.RemoteEvents.GetPlayerPurchaseHistory.OnServerEvent:Connect(handleGetPlayerPurchaseHistory)

-- 连接玩家事件
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- 处理已经在游戏中的玩家
for _, player in pairs(Players:GetPlayers()) do
    spawn(function()
        onPlayerAdded(player)
    end)
end

print("✅ 商店服务端已启动 (API模式)")
print("🌐 API服务器: " .. (ShopData and "已连接" or "未连接"))
print("🛒 支持购买和卖出功能")
print("📊 数据存储在MySQL数据库中")

-- 返回true表示启动成功
return true