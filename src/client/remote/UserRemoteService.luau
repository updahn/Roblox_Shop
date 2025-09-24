-- 用户远程服务
-- 封装与服务端用户相关的通信逻辑

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserRemoteService = {}

-- 缓存远程事件
local Events = nil
local RemoteEvents = {}

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
            print("✅ [UserRemoteService] 远程事件初始化成功")
        else
            warn("❌ [UserRemoteService] 远程事件初始化失败:", result)
        end
    end
end

-- 获取玩家数据
function UserRemoteService.getPlayerData()
    initializeEvents()
    if RemoteEvents.GetPlayerData then
        RemoteEvents.GetPlayerData:FireServer()
    end
end

-- 获取商店数据
function UserRemoteService.getShopData()
    initializeEvents()
    if RemoteEvents.GetShopData then
        RemoteEvents.GetShopData:FireServer()
    end
end

-- 获取交易记录
function UserRemoteService.getTransactions()
    initializeEvents()
    if RemoteEvents.GetTransactions then
        RemoteEvents.GetTransactions:FireServer()
    end
end

-- 购买物品
function UserRemoteService.buyItem(itemId, quantity)
    initializeEvents()
    if RemoteEvents.BuyItem then
        RemoteEvents.BuyItem:FireServer(itemId, quantity)
    end
end

-- 出售物品
function UserRemoteService.sellItem(itemId, quantity)
    initializeEvents()
    if RemoteEvents.SellItem then
        RemoteEvents.SellItem:FireServer(itemId, quantity)
    end
end

-- 刷新数据
function UserRemoteService.refreshData()
    initializeEvents()
    if RemoteEvents.RefreshData then
        RemoteEvents.RefreshData:FireServer()
    end
end

-- 监听服务端数据更新
function UserRemoteService.onPlayerDataReceived(callback)
    initializeEvents()
    if RemoteEvents.GetPlayerData then
        RemoteEvents.GetPlayerData.OnClientEvent:Connect(callback)
    end
end

function UserRemoteService.onShopDataReceived(callback)
    initializeEvents()
    if RemoteEvents.GetShopData then
        RemoteEvents.GetShopData.OnClientEvent:Connect(callback)
    end
end

function UserRemoteService.onTransactionsReceived(callback)
    initializeEvents()
    if RemoteEvents.GetTransactions then
        RemoteEvents.GetTransactions.OnClientEvent:Connect(callback)
    end
end

function UserRemoteService.onBuyResult(callback)
    initializeEvents()
    if RemoteEvents.BuyItem then
        RemoteEvents.BuyItem.OnClientEvent:Connect(callback)
    end
end

function UserRemoteService.onSellResult(callback)
    initializeEvents()
    if RemoteEvents.SellItem then
        RemoteEvents.SellItem.OnClientEvent:Connect(callback)
    end
end

function UserRemoteService.onDataRefreshed(callback)
    initializeEvents()
    if RemoteEvents.RefreshData then
        RemoteEvents.RefreshData.OnClientEvent:Connect(callback)
    end
end

return UserRemoteService
