-- 数据控制器
-- 管理客户端本地数据状态和缓存

local BindableEvent = Instance.new("BindableEvent")

local DataController = {}

-- 本地数据缓存
local localData = {
    playerData = nil,
    shopData = nil,
    transactions = nil,
    isLoading = false
}

-- 事件系统
DataController.Events = {
    PlayerDataChanged = BindableEvent.Event,
    ShopDataChanged = BindableEvent.Event,
    TransactionsChanged = BindableEvent.Event,
    LoadingStateChanged = BindableEvent.Event
}

-- 内部事件对象
local internalEvents = {
    PlayerDataChanged = Instance.new("BindableEvent"),
    ShopDataChanged = Instance.new("BindableEvent"),
    TransactionsChanged = Instance.new("BindableEvent"),
    LoadingStateChanged = Instance.new("BindableEvent")
}

-- 重新分配事件
for eventName, event in pairs(internalEvents) do
    DataController.Events[eventName] = event.Event
end

-- 设置加载状态
function DataController.setLoadingState(isLoading)
    if localData.isLoading ~= isLoading then
        localData.isLoading = isLoading
        internalEvents.LoadingStateChanged:Fire(isLoading)
        print("🔄 [DataController] 加载状态:", isLoading and "加载中" or "已完成")
    end
end

-- 获取加载状态
function DataController.isLoading()
    return localData.isLoading
end

-- 更新玩家数据
function DataController.updatePlayerData(newData)
    if newData then
        local oldData = localData.playerData
        localData.playerData = newData
        internalEvents.PlayerDataChanged:Fire(newData, oldData)
        print("✅ [DataController] 玩家数据已更新")
    end
end

-- 获取玩家数据
function DataController.getPlayerData()
    return localData.playerData
end

-- 更新商店数据
function DataController.updateShopData(newData)
    if newData then
        local oldData = localData.shopData
        localData.shopData = newData
        internalEvents.ShopDataChanged:Fire(newData, oldData)
        print("✅ [DataController] 商店数据已更新")
    end
end

-- 获取商店数据
function DataController.getShopData()
    return localData.shopData
end

-- 更新交易记录
function DataController.updateTransactions(newData)
    if newData then
        local oldData = localData.transactions
        localData.transactions = newData
        internalEvents.TransactionsChanged:Fire(newData, oldData)
        print("✅ [DataController] 交易记录已更新")
    end
end

-- 获取交易记录
function DataController.getTransactions()
    return localData.transactions
end

-- 获取玩家金币
function DataController.getPlayerCoins()
    if localData.playerData then
        return localData.playerData.coins or 0
    end
    return 0
end

-- 获取玩家库存
function DataController.getPlayerInventory()
    if localData.playerData then
        return localData.playerData.inventory or {}
    end
    return {}
end

-- 获取会员状态
function DataController.getMembershipStatus()
    if localData.playerData then
        return localData.playerData.membership
    end
    return nil
end

-- 根据ID获取物品信息
function DataController.getItemById(itemId)
    if localData.shopData and localData.shopData.items then
        return localData.shopData.items[itemId]
    end
    return nil
end

-- 检查是否可以购买物品
function DataController.canBuyItem(itemId, quantity)
    local item = DataController.getItemById(itemId)
    if not item then
        return false, "物品不存在"
    end

    local playerCoins = DataController.getPlayerCoins()
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
function DataController.canSellItem(itemId, quantity)
    local item = DataController.getItemById(itemId)
    if not item then
        return false, "物品不存在"
    end

    if not item.canSell then
        return false, "该物品不可出售"
    end

    local inventory = DataController.getPlayerInventory()
    local ownedQuantity = inventory[itemId] or 0

    if ownedQuantity < quantity then
        return false, "库存不足"
    end

    return true, "可以出售"
end

-- 清空本地数据
function DataController.clearData()
    localData.playerData = nil
    localData.shopData = nil
    localData.transactions = nil
    localData.isLoading = false
    print("🧹 [DataController] 本地数据已清空")
end

-- 获取统计信息
function DataController.getStats()
    return {
        hasPlayerData = localData.playerData ~= nil,
        hasShopData = localData.shopData ~= nil,
        hasTransactions = localData.transactions ~= nil,
        isLoading = localData.isLoading,
        itemCount = localData.shopData and #localData.shopData.items or 0,
        transactionCount = localData.transactions and #localData.transactions or 0
    }
end

return DataController
