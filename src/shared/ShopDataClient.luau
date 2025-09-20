-- 商店系统客户端数据模块

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopDataClient = {}

-- 等待共享模块，使用更短的超时时间防止无限等待
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", 5)
if not SharedModules then
    warn("⚠️ 无法加载共享模块，客户端数据模块将无法正常工作")
    return {}
end

local Events = require(SharedModules:WaitForChild("ShopEvents", 5))
if not Events then
    warn("⚠️ 无法加载Events模块，客户端数据模块将无法正常工作")
    return {}
end

-- 本地缓存
local playerData = nil
local shopData = {}
local membershipData = {}

-- 事件回调存储
local callbacks = {
    playerData = {},
    shopData = {},
    purchaseResult = {},
    sellResult = {},
    membershipData = {}
}

-- 添加回调函数
local function addCallback(callbackType, callback)
    table.insert(callbacks[callbackType], callback)
end

-- 触发回调
local function triggerCallbacks(callbackType, ...)
    for _, callback in ipairs(callbacks[callbackType]) do
        spawn(function()
            callback(...)
        end)
    end
end

-- 客户端API接口

-- 获取玩家数据（异步）
function ShopDataClient.getPlayerData(callback)
    if callback then
        addCallback("playerData", callback)
    end

    Events.User.GetPlayerData:FireServer()
end

-- 获取商店数据（异步）
function ShopDataClient.getShopData(callback)
    if callback then
        addCallback("shopData", callback)
    end

    Events.User.GetShopData:FireServer()
end

-- 刷新商店数据
function ShopDataClient.refreshShopData(callback)
    if callback then
        addCallback("shopData", callback)
    end

    Events.User.RefreshData:FireServer()
end

-- 购买物品（异步）
function ShopDataClient.buyItem(itemId, quantity, callback)
    if callback then
        addCallback("purchaseResult", callback)
    end

    Events.User.BuyItem:FireServer(itemId, quantity)
end

-- 卖出物品（异步）
function ShopDataClient.sellItem(itemId, quantity, callback)
    if callback then
        addCallback("sellResult", callback)
    end

    Events.User.SellItem:FireServer(itemId, quantity)
end

-- 管理员功能：获取所有玩家数据
function ShopDataClient.getAllPlayersData(callback)
    if callback then
        local connection
        connection = Events.Admin.GetAllUsers.OnClientEvent:Connect(function(data, errorMsg)
            connection:Disconnect()
            callback(data, errorMsg)
        end)
    end

    Events.Admin.GetAllUsers:FireServer()
end

-- 管理员功能：设置玩家金币
function ShopDataClient.setPlayerCoins(playerName, coins, callback)
    if callback then
        local connection
        connection = Events.Admin.SetUserCoins.OnClientEvent:Connect(function(success, message)
            connection:Disconnect()
            callback(success, message)
        end)
    end

    Events.Admin.SetUserCoins:FireServer(playerName, coins)
end

-- 管理员功能：获取会员列表
function ShopDataClient.getAdminMembersList(page, limit, status, callback)
    if callback then
        local connection
        connection = Events.Admin.GetMembersList.OnClientEvent:Connect(function(success, response)
            connection:Disconnect()
            if success then
                callback(true, response)
            else
                callback(false, response and response.error or "获取会员列表失败")
            end
        end)
    end

    Events.Admin.GetMembersList:FireServer(page, limit, status)
end

-- 获取缓存的数据（同步）
function ShopDataClient.getCachedPlayerData()
    return playerData
end

function ShopDataClient.getCachedShopData()
    return shopData
end

function ShopDataClient.getCachedMembershipData()
    return membershipData
end

-- 连接服务器事件
Events.User.GetPlayerData.OnClientEvent:Connect(function(data)
    playerData = data
    triggerCallbacks("playerData", data)
end)

Events.User.GetShopData.OnClientEvent:Connect(function(data)
    shopData = data or {}
    triggerCallbacks("shopData", data)
end)

Events.User.BuyItem.OnClientEvent:Connect(function(success, message, data)
    if success and data then
        playerData = data
    end
    triggerCallbacks("purchaseResult", success, message, data)
end)

Events.User.SellItem.OnClientEvent:Connect(function(success, message, data)
    if success and data then
        playerData = data
    end
    triggerCallbacks("sellResult", success, message, data)
end)

-- 初始化：自动获取数据
spawn(function()
    wait(1) -- 等待一下确保连接稳定
    ShopDataClient.getPlayerData()
    ShopDataClient.getShopData()
end)

print("📱 商店客户端数据模块已加载")

return ShopDataClient
