-- 用户控制器
-- 整合用户相关的远程通信和本地数据管理功能

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserController = {}

-- 本地数据缓存
local localData = {
    playerData = nil,
    shopData = nil,
    transactions = nil,
    isLoading = false
}

-- 缓存远程事件
local Events = nil
local RemoteEvents = {}

-- 内部事件系统
local internalEvents = {
    PlayerDataChanged = Instance.new("BindableEvent"),
    ShopDataChanged = Instance.new("BindableEvent"),
    TransactionsChanged = Instance.new("BindableEvent"),
    LoadingStateChanged = Instance.new("BindableEvent"),
    BuyResult = Instance.new("BindableEvent"),
    SellResult = Instance.new("BindableEvent"),
    DataRefreshed = Instance.new("BindableEvent")
}

-- 导出事件
UserController.Events = {}
for eventName, event in pairs(internalEvents) do
    UserController.Events[eventName] = event.Event
end

-- 初始化远程事件
local function initializeEvents()
    if not Events then
        local success, result = pcall(function()
            local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", 10)
            if not SharedModules then
                error("❌ 无法找到SharedModules文件夹")
            end
            local EventsModule = SharedModules:WaitForChild("ShopEvents", 10)
            if not EventsModule then
                error("❌ 无法找到ShopEvents模块")
            end
            return require(EventsModule)
        end)

        if success then
            Events = result
            RemoteEvents = {
                GetPlayerData = Events.User.GetPlayerData,
                GetShopData = Events.User.GetShopData,
                GetTransactions = Events.User.GetTransactions,
                BuyItem = Events.User.BuyItem,
                SellItem = Events.User.SellItem,
                RefreshData = Events.User.RefreshData
            }
            print("✅ [UserController] 远程事件初始化成功")
        else
            warn("❌ [UserController] 远程事件初始化失败:", result)
        end
    end
end

-- ==============================================
-- 数据状态管理
-- ==============================================

-- 设置加载状态
function UserController.setLoadingState(isLoading)
    if localData.isLoading ~= isLoading then
        localData.isLoading = isLoading
        internalEvents.LoadingStateChanged:Fire(isLoading)
        print("🔄 [UserController] 加载状态:", isLoading and "加载中" or "已完成")
    end
end

-- 获取加载状态
function UserController.isLoading()
    return localData.isLoading
end

-- 更新玩家数据
function UserController.updatePlayerData(newData)
    if newData then
        local oldData = localData.playerData
        localData.playerData = newData
        internalEvents.PlayerDataChanged:Fire(newData, oldData)
        print("✅ [UserController] 玩家数据已更新")
    end
end

-- 获取玩家数据
function UserController.getPlayerData()
    return localData.playerData
end

-- 更新商店数据
function UserController.updateShopData(newData)
    if newData then
        local oldData = localData.shopData
        localData.shopData = newData
        internalEvents.ShopDataChanged:Fire(newData, oldData)
        print("✅ [UserController] 商店数据已更新")
    end
end

-- 获取商店数据
function UserController.getShopData()
    return localData.shopData
end

-- 更新交易记录
function UserController.updateTransactions(newData)
    if newData then
        local oldData = localData.transactions
        localData.transactions = newData
        internalEvents.TransactionsChanged:Fire(newData, oldData)
        print("✅ [UserController] 交易记录已更新")
    end
end

-- 获取交易记录
function UserController.getTransactions()
    return localData.transactions
end

-- 获取玩家金币
function UserController.getPlayerCoins()
    if localData.playerData then
        return localData.playerData.coins or 0
    end
    return 0
end

-- 获取玩家库存
function UserController.getPlayerInventory()
    if localData.playerData then
        return localData.playerData.inventory or {}
    end
    return {}
end

-- 获取会员状态
function UserController.getMembershipStatus()
    if localData.playerData then
        return localData.playerData.membership
    end
    return nil
end

-- 根据ID获取物品信息
function UserController.getItemById(itemId)
    if localData.shopData and localData.shopData[itemId] then
        return localData.shopData[itemId]
    end
    return nil
end

-- 检查是否可以购买物品
function UserController.canBuyItem(itemId, quantity)
    local item = UserController.getItemById(itemId)
    if not item then
        return false, "物品不存在"
    end

    local playerCoins = UserController.getPlayerCoins()
    local totalCost = item.price * quantity

    if playerCoins < totalCost then
        return false, "金币不足"
    end

    if item.maxQuantity and item.maxQuantity > 0 and item.currentStock < quantity then
        return false, "库存不足"
    end

    return true, "可以购买"
end

-- 检查是否可以出售物品
function UserController.canSellItem(itemId, quantity)
    local item = UserController.getItemById(itemId)
    if not item then
        return false, "物品不存在"
    end

    if not item.canSell then
        return false, "该物品不可出售"
    end

    local inventory = UserController.getPlayerInventory()
    local ownedQuantity = inventory[itemId] or 0

    if ownedQuantity < quantity then
        return false, "库存不足"
    end

    return true, "可以出售"
end

-- ==============================================
-- 远程通信功能
-- ==============================================

-- 获取玩家数据
function UserController.requestPlayerData()
    initializeEvents()
    if RemoteEvents.GetPlayerData then
        RemoteEvents.GetPlayerData:FireServer()
        print("📡 [UserController] 请求玩家数据")
    end
end

-- 获取商店数据
function UserController.requestShopData()
    initializeEvents()
    if RemoteEvents.GetShopData then
        RemoteEvents.GetShopData:FireServer()
        print("📡 [UserController] 请求商店数据")
    end
end

-- 获取交易记录
function UserController.requestTransactions()
    initializeEvents()
    if RemoteEvents.GetTransactions then
        RemoteEvents.GetTransactions:FireServer()
        print("📡 [UserController] 请求交易记录")
    end
end

-- 购买物品
function UserController.buyItem(itemId, quantity)
    initializeEvents()
    if RemoteEvents.BuyItem then
        UserController.setLoadingState(true)
        RemoteEvents.BuyItem:FireServer(itemId, quantity)
        print("🛒 [UserController] 发送购买请求:", itemId, "数量:", quantity)
    end
end

-- 出售物品
function UserController.sellItem(itemId, quantity)
    initializeEvents()
    if RemoteEvents.SellItem then
        UserController.setLoadingState(true)
        RemoteEvents.SellItem:FireServer(itemId, quantity)
        print("💰 [UserController] 发送出售请求:", itemId, "数量:", quantity)
    end
end

-- 刷新数据
function UserController.refreshData()
    initializeEvents()
    if RemoteEvents.RefreshData then
        UserController.setLoadingState(true)
        RemoteEvents.RefreshData:FireServer()
        print("🔄 [UserController] 请求刷新数据")
    end
end

-- ==============================================
-- 事件监听和处理
-- ==============================================

-- 监听服务端数据更新的回调函数
local eventConnections = {}

-- 初始化事件监听
function UserController.initializeEventListeners()
    initializeEvents()

    -- 监听玩家数据响应
    if RemoteEvents.GetPlayerData then
        eventConnections.getPlayerData = RemoteEvents.GetPlayerData.OnClientEvent:Connect(function(success, data)
            UserController.setLoadingState(false)
            if success and data then
                UserController.updatePlayerData(data)
            else
                warn("❌ [UserController] 获取玩家数据失败:", data)
            end
        end)
    end

    -- 监听商店数据响应
    if RemoteEvents.GetShopData then
        eventConnections.getShopData = RemoteEvents.GetShopData.OnClientEvent:Connect(function(success, data)
            if success and data then
                UserController.updateShopData(data)
            else
                warn("❌ [UserController] 获取商店数据失败:", data)
            end
        end)
    end

    -- 监听交易记录响应
    if RemoteEvents.GetTransactions then
        eventConnections.getTransactions = RemoteEvents.GetTransactions.OnClientEvent:Connect(function(success, errorMsg, responseData)
            if success and responseData then
                UserController.updateTransactions(responseData.transactions)
            else
                warn("❌ [UserController] 获取交易记录失败:", errorMsg)
            end
        end)
    end

    -- 监听购买结果
    if RemoteEvents.BuyItem then
        eventConnections.buyItem = RemoteEvents.BuyItem.OnClientEvent:Connect(function(success, message, newData)
            UserController.setLoadingState(false)
            if success then
                print("✅ [UserController] 购买成功:", message)
                if newData then
                    UserController.updatePlayerData(newData)
                end
            else
                warn("❌ [UserController] 购买失败:", message)
            end
            internalEvents.BuyResult:Fire(success, message, newData)
        end)
    end

    -- 监听出售结果
    if RemoteEvents.SellItem then
        eventConnections.sellItem = RemoteEvents.SellItem.OnClientEvent:Connect(function(success, message, newData)
            UserController.setLoadingState(false)
            if success then
                print("✅ [UserController] 出售成功:", message)
                if newData then
                    UserController.updatePlayerData(newData)
                end
            else
                warn("❌ [UserController] 出售失败:", message)
            end
            internalEvents.SellResult:Fire(success, message, newData)
        end)
    end

    -- 监听数据刷新
    if RemoteEvents.RefreshData then
        eventConnections.refreshData = RemoteEvents.RefreshData.OnClientEvent:Connect(function(success, data)
            UserController.setLoadingState(false)
            if success and data then
                print("🔄 [UserController] 数据已刷新")
                UserController.updatePlayerData(data.playerData)
                UserController.updateShopData(data.shopData)
                if data.transactions then
                    UserController.updateTransactions(data.transactions)
                end
            end
            internalEvents.DataRefreshed:Fire(success, data)
        end)
    end

    print("✅ [UserController] 事件监听器初始化完成")
end

-- ==============================================
-- 初始化和清理
-- ==============================================

-- 初始化用户控制器
function UserController.initialize()
    print("🚀 [UserController] 开始初始化...")

    -- 初始化事件监听
    UserController.initializeEventListeners()

    print("✅ [UserController] 初始化完成")
end

-- 加载初始数据
function UserController.loadInitialData()
    print("📡 [UserController] 开始加载初始数据...")
    UserController.setLoadingState(true)

    -- 请求玩家数据
    UserController.requestPlayerData()

    -- 请求商店数据
    UserController.requestShopData()

    -- 请求交易记录
    UserController.requestTransactions()
end

-- 清空本地数据
function UserController.clearData()
    localData.playerData = nil
    localData.shopData = nil
    localData.transactions = nil
    localData.isLoading = false
    print("🧹 [UserController] 本地数据已清空")
end

-- 获取统计信息
function UserController.getStats()
    return {
        hasPlayerData = localData.playerData ~= nil,
        hasShopData = localData.shopData ~= nil,
        hasTransactions = localData.transactions ~= nil,
        isLoading = localData.isLoading,
        itemCount = localData.shopData and #localData.shopData or 0,
        transactionCount = localData.transactions and #localData.transactions or 0
    }
end

-- 清理资源
function UserController.cleanup()
    -- 断开所有事件连接
    for _, connection in pairs(eventConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    eventConnections = {}

    UserController.clearData()
    print("🧹 [UserController] 资源已清理")
end

return UserController
