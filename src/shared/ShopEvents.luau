-- 商店系统远程事件定义

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopEvents = {}

-- 创建远程事件文件夹
local eventsFolder = ReplicatedStorage:FindFirstChild("ShopEvents")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "ShopEvents"
    eventsFolder.Parent = ReplicatedStorage
end

-- 创建远程事件的辅助函数
local function createRemoteEvent(name)
    local event = eventsFolder:FindFirstChild(name)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = eventsFolder
    end
    return event
end

-- 新版事件结构
ShopEvents.RemoteEvents = {
    -- 获取玩家数据
    GetPlayerData = createRemoteEvent("GetPlayerData"),

    -- 获取商店数据（包含实时库存）
    GetShopData = createRemoteEvent("GetShopData"),

    -- 刷新商店数据
    RefreshShopData = createRemoteEvent("RefreshShopData"),

    -- 购买物品
    PurchaseItem = createRemoteEvent("PurchaseItem"),

    -- 卖出物品
    SellItem = createRemoteEvent("SellItem"),

    -- 管理员功能
    GetAllPlayersData = createRemoteEvent("GetAllPlayersData"),
    SetPlayerCoins = createRemoteEvent("SetPlayerCoins"),
    GetPlayerPurchaseHistory = createRemoteEvent("GetPlayerPurchaseHistory"),
}

-- 向后兼容的旧版事件（保留现有功能）
ShopEvents.BuyItem = createRemoteEvent("BuyItem")
ShopEvents.SellItem = createRemoteEvent("SellItemOld")
ShopEvents.GetPlayerData = createRemoteEvent("GetPlayerDataOld")
ShopEvents.UpdatePlayerData = createRemoteEvent("UpdatePlayerData")
ShopEvents.BuyResult = createRemoteEvent("BuyResult")
ShopEvents.SellResult = createRemoteEvent("SellResult")

print("📡 商店远程事件已初始化")

return ShopEvents