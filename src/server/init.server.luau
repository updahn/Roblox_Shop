-- 商店系统服务端逻辑

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 等待共享模块（由Bootstrap脚本设置）
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local ShopData = require(SharedModules:WaitForChild("ShopData"))
local ShopEvents = require(SharedModules:WaitForChild("ShopEvents"))
local DataManager = require(script:WaitForChild("DataManager"))

-- 商店库存管理
local shopInventory = {}
local shopItems = ShopData.SHOP_ITEMS or {}
for itemId, item in pairs(shopItems) do
    shopInventory[itemId] = {
        available = item.maxQuantity or math.huge,
        maxQuantity = item.maxQuantity
    }
end

-- 管理员列表 (可以根据需要修改)
-- 💡 如何设置管理员:
-- 1. 获取玩家的 UserId: 在游戏中输入 print(Players.LocalPlayer.UserId)
-- 2. 将 UserId 添加到下面的列表中
-- 3. 或者直接使用用户名 (不推荐，因为用户名可能会改变)
local ADMIN_USER_IDS = {
    -- 在这里添加管理员的 UserId
    -- 示例: 123456789, 987654321
}

-- 管理员用户名列表 (备选方案，不推荐)
local ADMIN_USERNAMES = {
    -- 在这里添加管理员的用户名
    -- 示例: "YourUsername", "AdminName"
}

-- 检查玩家是否为管理员
local function isPlayerAdmin(player)
    -- 方法1: 检查 UserId
    for _, adminId in pairs(ADMIN_USER_IDS) do
        if player.UserId == adminId then
            return true
        end
    end

    -- 方法2: 检查用户名
    for _, adminName in pairs(ADMIN_USERNAMES) do
        if player.Name == adminName then
            return true
        end
    end

    -- 方法3: 检查开发者权限 (游戏创建者)
    if player.UserId == game.CreatorId then
        return true
    end

    -- 方法4: 检查 Roblox 管理员
    if player:GetRankInGroup(1) >= 100 then -- Roblox 员工组
        return true
    end

    return false
end

print("🏪 商店系统已初始化")
print("📦 库存概览:")
for itemId, inventory in pairs(shopInventory) do
    local item = ShopData.SHOP_ITEMS[itemId]
    if item then
        local stockText = inventory.available == math.huge and "无限" or tostring(inventory.available)
        print("  📦 " .. item.name .. " (" .. itemId .. "): " .. stockText)
    end
end

-- 获取玩家数据
local function getPlayerData(player: Player)
    local data = DataManager.getPlayerData(player)
    if not data then
        -- 创建默认玩家数据
        local defaultData = {
            coins = 3000,
            inventory = {},
            stats = {
                totalPurchases = 0,
                totalSales = 0,
                totalSpent = 0,
                totalEarned = 0
            }
        }
        data = DataManager.loadPlayerData(player, defaultData)
    end
    return data
end

-- 更新玩家数据并保存
local function updatePlayerData(player: Player, newData)
    DataManager.setPlayerData(player, newData)
    -- 立即保存以确保数据持久化
    DataManager.savePlayerData(player)
end

-- 处理获取玩家数据请求
local function handleGetPlayerData(player: Player)
    local playerData = getPlayerData(player)
    ShopEvents.RemoteEvents.GetPlayerData:FireClient(player, playerData)
end

-- 处理获取商店数据请求
local function handleGetShopData(player: Player)
    -- 创建包含实时库存的商店数据
    local shopData = {}
    for itemId, item in pairs(ShopData.SHOP_ITEMS) do
        local itemData = {}
        -- 复制所有物品属性
        for key, value in pairs(item) do
            itemData[key] = value
        end
        -- 添加实时库存信息
        if shopInventory[itemId] then
            itemData.currentStock = shopInventory[itemId].available
        else
            itemData.currentStock = item.maxQuantity or -1
        end
        shopData[itemId] = itemData
    end

    ShopEvents.RemoteEvents.GetShopData:FireClient(player, shopData)
end

-- 广播商店数据给所有玩家
local function broadcastShopData()
    -- 创建包含实时库存的商店数据
    local shopData = {}
    for itemId, item in pairs(ShopData.SHOP_ITEMS) do
        local itemData = {}
        -- 复制所有物品属性
        for key, value in pairs(item) do
            itemData[key] = value
        end
        -- 添加当前库存信息
        if shopInventory[itemId] then
            itemData.currentStock = shopInventory[itemId].available
        else
            itemData.currentStock = item.maxQuantity or -1
        end
        shopData[itemId] = itemData
    end

    -- 发送给所有玩家
    for _, player in pairs(Players:GetPlayers()) do
        ShopEvents.RemoteEvents.GetShopData:FireClient(player, shopData)
    end

    print("📡 [广播] 商店数据已更新给所有玩家")
end

-- 处理购买物品
local function handlePurchaseItem(player: Player, itemId: string, quantity: number)
    local playerData = getPlayerData(player)
    local item = ShopData.SHOP_ITEMS[itemId]

    if not item then
        ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, false, "物品不存在", playerData)
        return
    end

    -- 验证数量
    if quantity <= 0 then
        ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, false, "数量必须大于0", playerData)
        return
    end

    -- 检查库存
    if item.maxQuantity ~= nil and item.maxQuantity ~= -1 and shopInventory[itemId].available < quantity then
        ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, false, "商店库存不足", playerData)
        return
    end

    -- 检查金币
    local totalCost = item.price * quantity
    if playerData.coins < totalCost then
        ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, false, "金币不足，需要 " .. totalCost .. " 金币", playerData)
        return
    end

    -- 执行购买
    playerData.coins = playerData.coins - totalCost

    -- 更新玩家库存
    if not playerData.inventory[itemId] then
        playerData.inventory[itemId] = 0
    end
    playerData.inventory[itemId] = playerData.inventory[itemId] + quantity

    -- 更新商店库存
    if item.maxQuantity ~= nil and item.maxQuantity ~= -1 then
        shopInventory[itemId].available = shopInventory[itemId].available - quantity
        if shopInventory[itemId].available < 0 then
            shopInventory[itemId].available = 0
        end
    end

    -- 更新统计数据
    playerData.stats.totalPurchases = playerData.stats.totalPurchases + quantity
    playerData.stats.totalSpent = playerData.stats.totalSpent + totalCost

    -- 记录交易历史
    if not playerData.purchaseHistory then
        playerData.purchaseHistory = {}
    end

    local record = {
        action = "buy",
        itemId = itemId,
        itemName = item.name,
        quantity = quantity,
        totalCost = totalCost,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        balanceAfter = playerData.coins
    }

    table.insert(playerData.purchaseHistory, 1, record) -- 插入到开头，最新的在前面

    -- 限制记录数量，只保留最近50条
    if #playerData.purchaseHistory > 50 then
        table.remove(playerData.purchaseHistory, #playerData.purchaseHistory)
    end

    -- 保存数据
    updatePlayerData(player, playerData)

    -- 通知所有玩家更新商店数据（如果商店库存发生变化）
    if item.maxQuantity ~= nil and item.maxQuantity ~= -1 then
        broadcastShopData()
    end

    local message = "成功购买 " .. quantity .. " 个 " .. item.name .. "，花费 " .. totalCost .. " 金币"
    ShopEvents.RemoteEvents.PurchaseItem:FireClient(player, true, message, playerData)
    print("🛒 [购买] " .. player.Name .. " 购买了 " .. item.name .. " x" .. quantity .. " | 总价: " .. totalCost .. " 金币 | 余额: " .. playerData.coins)
end

-- 处理卖出物品
local function handleSellItem(player: Player, itemId: string, quantity: number)
    local playerData = getPlayerData(player)
    local item = ShopData.SHOP_ITEMS[itemId]

    if not item then
        ShopEvents.RemoteEvents.SellItem:FireClient(player, false, "物品不存在", playerData)
        return
    end

    -- 验证数量
    if quantity <= 0 then
        ShopEvents.RemoteEvents.SellItem:FireClient(player, false, "数量必须大于0", playerData)
        return
    end

    -- 检查玩家是否拥有足够的物品
    local ownedQuantity = playerData.inventory[itemId] or 0
    if ownedQuantity < quantity then
        ShopEvents.RemoteEvents.SellItem:FireClient(player, false, "物品数量不足，你只有 " .. ownedQuantity .. " 个", playerData)
        return
    end

    -- 计算卖出价格（80%回收价）
    local sellPrice = math.floor(item.price * 0.8)
    local totalEarned = sellPrice * quantity

    -- 执行卖出
    playerData.inventory[itemId] = playerData.inventory[itemId] - quantity
    if playerData.inventory[itemId] <= 0 then
        playerData.inventory[itemId] = nil
    end

    playerData.coins = playerData.coins + totalEarned

    -- 更新商店库存（卖回商店）
    if item.maxQuantity ~= nil and item.maxQuantity ~= -1 then
        shopInventory[itemId].available = shopInventory[itemId].available + quantity
        -- 确保不超过最大库存（如果有设置）
        if shopInventory[itemId].maxQuantity and shopInventory[itemId].available > shopInventory[itemId].maxQuantity then
            shopInventory[itemId].available = shopInventory[itemId].maxQuantity
        end
    end

    -- 更新统计数据
    playerData.stats.totalSales = playerData.stats.totalSales + quantity
    playerData.stats.totalEarned = playerData.stats.totalEarned + totalEarned

    -- 记录交易历史
    if not playerData.purchaseHistory then
        playerData.purchaseHistory = {}
    end

    local record = {
        action = "sell",
        itemId = itemId,
        itemName = item.name,
        quantity = quantity,
        totalEarned = totalEarned,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        balanceAfter = playerData.coins
    }

    table.insert(playerData.purchaseHistory, 1, record) -- 插入到开头，最新的在前面

    -- 限制记录数量，只保留最近50条
    if #playerData.purchaseHistory > 50 then
        table.remove(playerData.purchaseHistory, #playerData.purchaseHistory)
    end

    -- 保存数据
    updatePlayerData(player, playerData)

    -- 通知所有玩家更新商店数据（如果商店库存发生变化）
    if item.maxQuantity ~= nil and item.maxQuantity ~= -1 then
        broadcastShopData()
    end

    local message = "成功卖出 " .. quantity .. " 个 " .. item.name .. "，获得 " .. totalEarned .. " 金币"
    ShopEvents.RemoteEvents.SellItem:FireClient(player, true, message, playerData)
    print("💰 [卖出] " .. player.Name .. " 卖出了 " .. item.name .. " x" .. quantity .. " | 收入: " .. totalEarned .. " 金币 | 余额: " .. playerData.coins)
end

-- 玩家加入游戏时
local function onPlayerAdded(player: Player)
    print("👤 [加入] " .. player.Name .. " 已连接到商店服务器")

    -- 等待一下确保客户端准备好
    wait(2)

    -- 加载玩家数据
    local playerData = getPlayerData(player)
    local itemCount = 0
    if playerData.inventory then
        for _, quantity in pairs(playerData.inventory) do
            itemCount = itemCount + quantity
        end
    end
    print("📊 [数据] " .. player.Name .. " | 金币: " .. playerData.coins .. " | 物品总数: " .. itemCount)

    -- 检查是否为管理员
    if isPlayerAdmin(player) then
        print("👑 [管理员] " .. player.Name .. " 已获得商店管理权限")
    end
end

-- 玩家离开游戏时
local function onPlayerRemoving(player: Player)
    print("👋 [离开] " .. player.Name .. " 已断开连接，数据已保存")
    -- DataManager会自动处理数据保存
end

-- 管理员功能：获取所有玩家数据
local function handleGetAllPlayersData(player: Player)
    if not isPlayerAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试获取所有玩家数据，但不是管理员")
        return
    end

    local allPlayersData = {}
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        local playerData = getPlayerData(targetPlayer)
        allPlayersData[targetPlayer.Name] = {
            userId = targetPlayer.UserId,
            name = targetPlayer.Name,
            coins = playerData.coins,
            totalPurchases = playerData.stats.totalPurchases,
            totalSpent = playerData.stats.totalSpent,
            totalSales = playerData.stats.totalSales,
            totalEarned = playerData.stats.totalEarned,
            inventoryCount = 0
        }

        -- 计算库存总数
        if playerData.inventory then
            for _, quantity in pairs(playerData.inventory) do
                allPlayersData[targetPlayer.Name].inventoryCount = allPlayersData[targetPlayer.Name].inventoryCount + quantity
            end
        end
    end

    ShopEvents.RemoteEvents.GetAllPlayersData:FireClient(player, allPlayersData)
    print("👑 [管理员] " .. player.Name .. " 查看了所有玩家数据")
end

-- 管理员功能：设置玩家金币
local function handleSetPlayerCoins(player: Player, targetPlayerName: string, newCoins: number)
    if not isPlayerAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试修改 " .. targetPlayerName .. " 的金币，但不是管理员")
        return
    end

    -- 查找目标玩家
    local targetPlayer = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == targetPlayerName then
            targetPlayer = p
            break
        end
    end

    if not targetPlayer then
        ShopEvents.RemoteEvents.SetPlayerCoins:FireClient(player, false, "玩家 " .. targetPlayerName .. " 不在线")
        return
    end

    -- 验证金币数量
    if newCoins < 0 or newCoins > 999999 then
        ShopEvents.RemoteEvents.SetPlayerCoins:FireClient(player, false, "金币数量必须在 0-999999 之间")
        return
    end

    -- 修改金币
    local targetPlayerData = getPlayerData(targetPlayer)
    local oldCoins = targetPlayerData.coins
    targetPlayerData.coins = newCoins

    -- 记录管理员操作
    if not targetPlayerData.purchaseHistory then
        targetPlayerData.purchaseHistory = {}
    end

    local record = {
        action = "admin_edit",
        itemName = "金币修改",
        quantity = newCoins - oldCoins,
        totalCost = 0,
        totalEarned = newCoins - oldCoins,
        timestamp = os.date("%Y-%m-%d %H:%M:%S") .. " (管理员: " .. player.Name .. ")",
        balanceAfter = newCoins
    }

    table.insert(targetPlayerData.purchaseHistory, 1, record)

    -- 保存数据
    updatePlayerData(targetPlayer, targetPlayerData)

    -- 通知目标玩家数据更新
    ShopEvents.RemoteEvents.GetPlayerData:FireClient(targetPlayer, targetPlayerData)

    -- 通知管理员操作成功
    ShopEvents.RemoteEvents.SetPlayerCoins:FireClient(player, true, "成功将 " .. targetPlayerName .. " 的金币从 " .. oldCoins .. " 修改为 " .. newCoins)

    print("👑 [管理员操作] " .. player.Name .. " 将 " .. targetPlayerName .. " 的金币从 " .. oldCoins .. " 修改为 " .. newCoins)
end

-- 管理员功能：获取玩家购买记录
local function handleGetPlayerPurchaseHistory(player: Player, targetPlayerName: string)
    if not isPlayerAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试查看 " .. targetPlayerName .. " 的购买记录，但不是管理员")
        return
    end

    -- 查找目标玩家
    local targetPlayer = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == targetPlayerName then
            targetPlayer = p
            break
        end
    end

    if not targetPlayer then
        ShopEvents.RemoteEvents.GetPlayerPurchaseHistory:FireClient(player, targetPlayerName, nil, "玩家不在线")
        return
    end

    local targetPlayerData = getPlayerData(targetPlayer)
    ShopEvents.RemoteEvents.GetPlayerPurchaseHistory:FireClient(player, targetPlayerName, targetPlayerData.purchaseHistory or {})
    print("👑 [管理员] " .. player.Name .. " 查看了 " .. targetPlayerName .. " 的购买记录")
end

-- 连接远程事件
ShopEvents.RemoteEvents.GetPlayerData.OnServerEvent:Connect(handleGetPlayerData)
ShopEvents.RemoteEvents.GetShopData.OnServerEvent:Connect(handleGetShopData)
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

print("✅ 商店服务端已启动")
print("💾 数据持久化: " .. (game:GetService("RunService"):IsStudio() and "Studio模拟模式" or "生产模式"))
print("🛒 支持购买和卖出功能")
print("📊 包含完整的玩家统计数据")

-- 服务端GUI界面系统
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- 创建服务端GUI
local function createServerGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopServerGUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true

    -- 主界面框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- 创建标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Text = "🏪 商店服务器管理界面"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Size = UDim2.new(0, 400, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- 状态显示
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Text = "🟢 服务器运行中"
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 16
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.Size = UDim2.new(0, 200, 1, 0)
    statusLabel.Position = UDim2.new(1, -220, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = titleBar

    -- 导航按钮区域
    local navFrame = Instance.new("Frame")
    navFrame.Name = "NavFrame"
    navFrame.Size = UDim2.new(1, 0, 0, 50)
    navFrame.Position = UDim2.new(0, 0, 0, 60)
    navFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    navFrame.BorderSizePixel = 0
    navFrame.Parent = mainFrame

    -- 商店概览按钮
    local shopOverviewBtn = Instance.new("TextButton")
    shopOverviewBtn.Name = "ShopOverviewBtn"
    shopOverviewBtn.Text = "📊 商店概览"
    shopOverviewBtn.Font = Enum.Font.SourceSansBold
    shopOverviewBtn.TextSize = 16
    shopOverviewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopOverviewBtn.Size = UDim2.new(0, 150, 0, 40)
    shopOverviewBtn.Position = UDim2.new(0, 10, 0, 5)
    shopOverviewBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    shopOverviewBtn.BorderSizePixel = 0
    shopOverviewBtn.Parent = navFrame

    -- 购买记录按钮
    local purchaseRecordsBtn = Instance.new("TextButton")
    purchaseRecordsBtn.Name = "PurchaseRecordsBtn"
    purchaseRecordsBtn.Text = "📝 购买记录"
    purchaseRecordsBtn.Font = Enum.Font.SourceSansBold
    purchaseRecordsBtn.TextSize = 16
    purchaseRecordsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    purchaseRecordsBtn.Size = UDim2.new(0, 150, 0, 40)
    purchaseRecordsBtn.Position = UDim2.new(0, 170, 0, 5)
    purchaseRecordsBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    purchaseRecordsBtn.BorderSizePixel = 0
    purchaseRecordsBtn.Parent = navFrame

    -- 内容区域
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -110)
    contentFrame.Position = UDim2.new(0, 0, 0, 110)
    contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 10
    contentFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    contentFrame.Parent = mainFrame

    return screenGui, contentFrame, shopOverviewBtn, purchaseRecordsBtn
end

-- 显示商店概览
local function showShopOverview(contentFrame)
    contentFrame:ClearAllChildren()

    -- 商店统计
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -20, 0, 200)
    statsFrame.Position = UDim2.new(0, 10, 0, 10)
    statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = contentFrame

    local statsTitle = Instance.new("TextLabel")
    statsTitle.Text = "📊 商店统计信息"
    statsTitle.Font = Enum.Font.SourceSansBold
    statsTitle.TextSize = 20
    statsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsTitle.Size = UDim2.new(1, 0, 0, 40)
    statsTitle.Position = UDim2.new(0, 0, 0, 0)
    statsTitle.BackgroundTransparency = 1
    statsTitle.TextXAlignment = Enum.TextXAlignment.Center
    statsTitle.Parent = statsFrame

    -- 商品库存列表
    local inventoryFrame = Instance.new("Frame")
    inventoryFrame.Name = "InventoryFrame"
    inventoryFrame.Size = UDim2.new(1, -20, 1, -220)
    inventoryFrame.Position = UDim2.new(0, 10, 0, 220)
    inventoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    inventoryFrame.BorderSizePixel = 0
    inventoryFrame.Parent = contentFrame

    local inventoryTitle = Instance.new("TextLabel")
    inventoryTitle.Text = "📦 商品库存"
    inventoryTitle.Font = Enum.Font.SourceSansBold
    inventoryTitle.TextSize = 18
    inventoryTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    inventoryTitle.Size = UDim2.new(1, 0, 0, 40)
    inventoryTitle.Position = UDim2.new(0, 0, 0, 0)
    inventoryTitle.BackgroundTransparency = 1
    inventoryTitle.TextXAlignment = Enum.TextXAlignment.Center
    inventoryTitle.Parent = inventoryFrame

    -- 显示每个商品的库存信息
    local yOffset = 50
    for itemId, inventory in pairs(shopInventory) do
        local item = ShopData.SHOP_ITEMS[itemId]
        if item then
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -20, 0, 30)
            itemFrame.Position = UDim2.new(0, 10, 0, yOffset)
            itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            itemFrame.BorderSizePixel = 0
            itemFrame.Parent = inventoryFrame

            local itemLabel = Instance.new("TextLabel")
            itemLabel.Text = item.icon .. " " .. item.name
            itemLabel.Font = Enum.Font.SourceSans
            itemLabel.TextSize = 14
            itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemLabel.Size = UDim2.new(0.3, 0, 1, 0)
            itemLabel.Position = UDim2.new(0, 10, 0, 0)
            itemLabel.BackgroundTransparency = 1
            itemLabel.TextXAlignment = Enum.TextXAlignment.Left
            itemLabel.Parent = itemFrame

            local priceLabel = Instance.new("TextLabel")
            priceLabel.Text = "💰 " .. item.price
            priceLabel.Font = Enum.Font.SourceSans
            priceLabel.TextSize = 14
            priceLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            priceLabel.Size = UDim2.new(0.2, 0, 1, 0)
            priceLabel.Position = UDim2.new(0.3, 0, 0, 0)
            priceLabel.BackgroundTransparency = 1
            priceLabel.TextXAlignment = Enum.TextXAlignment.Center
            priceLabel.Parent = itemFrame

            local stockLabel = Instance.new("TextLabel")
            local stockText = inventory.available == math.huge and "无限" or tostring(inventory.available)
            stockLabel.Text = "库存: " .. stockText
            stockLabel.Font = Enum.Font.SourceSans
            stockLabel.TextSize = 14
            stockLabel.TextColor3 = inventory.available == math.huge and Color3.fromRGB(100, 255, 100) or
                                  (inventory.available > 10 and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 100, 100))
            stockLabel.Size = UDim2.new(0.3, 0, 1, 0)
            stockLabel.Position = UDim2.new(0.5, 0, 0, 0)
            stockLabel.BackgroundTransparency = 1
            stockLabel.TextXAlignment = Enum.TextXAlignment.Center
            stockLabel.Parent = itemFrame

            yOffset = yOffset + 40
        end
    end
end

-- 显示购买记录
local function showPurchaseRecords(contentFrame)
    contentFrame:ClearAllChildren()

    local recordsFrame = Instance.new("Frame")
    recordsFrame.Name = "RecordsFrame"
    recordsFrame.Size = UDim2.new(1, -20, 1, -20)
    recordsFrame.Position = UDim2.new(0, 10, 0, 10)
    recordsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    recordsFrame.BorderSizePixel = 0
    recordsFrame.Parent = contentFrame

    local recordsTitle = Instance.new("TextLabel")
    recordsTitle.Text = "📝 玩家交易记录"
    recordsTitle.Font = Enum.Font.SourceSansBold
    recordsTitle.TextSize = 20
    recordsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    recordsTitle.Size = UDim2.new(1, 0, 0, 40)
    recordsTitle.Position = UDim2.new(0, 0, 0, 0)
    recordsTitle.BackgroundTransparency = 1
    recordsTitle.TextXAlignment = Enum.TextXAlignment.Center
    recordsTitle.Parent = recordsFrame

    -- 显示在线玩家统计
    local yOffset = 50
    for _, player in pairs(Players:GetPlayers()) do
        local playerData = getPlayerData(player)
        if playerData then
            local playerFrame = Instance.new("Frame")
            playerFrame.Size = UDim2.new(1, -20, 0, 100)
            playerFrame.Position = UDim2.new(0, 10, 0, yOffset)
            playerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            playerFrame.BorderSizePixel = 0
            playerFrame.Parent = recordsFrame

            local playerLabel = Instance.new("TextLabel")
            playerLabel.Text = "👤 " .. player.Name
            playerLabel.Font = Enum.Font.SourceSansBold
            playerLabel.TextSize = 16
            playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerLabel.Size = UDim2.new(1, 0, 0, 25)
            playerLabel.Position = UDim2.new(0, 10, 0, 5)
            playerLabel.BackgroundTransparency = 1
            playerLabel.TextXAlignment = Enum.TextXAlignment.Left
            playerLabel.Parent = playerFrame

            local statsText = string.format(
                "💰 金币: %d | 🛒 购买次数: %d | 💰 总支出: %d | 📦 总收入: %d",
                playerData.coins,
                playerData.stats.totalPurchases,
                playerData.stats.totalSpent,
                playerData.stats.totalEarned
            )

            local statsLabel = Instance.new("TextLabel")
            statsLabel.Text = statsText
            statsLabel.Font = Enum.Font.SourceSans
            statsLabel.TextSize = 12
            statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            statsLabel.Size = UDim2.new(1, -20, 0, 60)
            statsLabel.Position = UDim2.new(0, 10, 0, 30)
            statsLabel.BackgroundTransparency = 1
            statsLabel.TextXAlignment = Enum.TextXAlignment.Left
            statsLabel.TextWrapped = true
            statsLabel.Parent = playerFrame

            yOffset = yOffset + 110
        end
    end
end

-- 为特定玩家初始化服务端GUI
local function initServerGUIForPlayer(player)
    if not isPlayerAdmin(player) then
        return -- 不是管理员，不创建GUI
    end

    local screenGui, contentFrame, shopOverviewBtn, purchaseRecordsBtn = createServerGUI()

    -- 默认显示商店概览
    showShopOverview(contentFrame)

    -- 按钮事件
    shopOverviewBtn.MouseButton1Click:Connect(function()
        shopOverviewBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        purchaseRecordsBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
        showShopOverview(contentFrame)
    end)

    purchaseRecordsBtn.MouseButton1Click:Connect(function()
        purchaseRecordsBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        shopOverviewBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
        showPurchaseRecords(contentFrame)
    end)

    -- 将GUI添加到该玩家的PlayerGui
    screenGui.Parent = player:WaitForChild("PlayerGui")

    print("🖥️ [服务端GUI] 为管理员 " .. player.Name .. " 创建商店管理界面")
end

-- 当玩家加入时检查是否为管理员并创建GUI
local function checkAndCreateAdminGUI(player)
    -- 等待玩家完全加载
    wait(2)

    if isPlayerAdmin(player) then
        initServerGUIForPlayer(player)
        print("👑 [管理员] " .. player.Name .. " 已获得商店管理权限")
    end
end

-- 返回true表示启动成功
return true