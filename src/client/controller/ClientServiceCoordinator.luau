-- 客户端服务协调器
-- 协调远程服务、本地控制器和UI之间的通信

local ClientServiceCoordinator = {}

-- 引入依赖模块
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 使用绝对路径获取模块
local function getClientModule(path)
    local player = Players.LocalPlayer
    local playerScripts = player:WaitForChild("PlayerScripts")
    local clientFolder = playerScripts:FindFirstChild("Client")
    if not clientFolder then
        error("❌ 找不到Client文件夹")
    end

    local parts = string.split(path, "/")
    local module = clientFolder
    for _, part in ipairs(parts) do
        module = module:FindFirstChild(part)
        if not module then
            error("❌ 找不到模块路径: " .. path)
        end
    end
    return module
end

local UserRemoteService = require(getClientModule("remote/UserRemoteService"))
local AdminRemoteService = require(getClientModule("remote/AdminRemoteService"))
local DataController = require(getClientModule("controller/DataController"))
local UIController = require(getClientModule("controller/UIController"))

-- 初始化标志
local isInitialized = false

-- 前置声明本地函数
local setupRemoteServiceBindings, setupUIInteractionBindings, setupDataChangeBindings, handleAdminAction

-- 初始化服务协调器
function ClientServiceCoordinator.initialize()
    if isInitialized then
        print("⚠️ [ClientServiceCoordinator] 已经初始化过了")
        return
    end

    print("🚀 [ClientServiceCoordinator] 开始初始化...")

    -- 绑定远程服务事件到数据控制器
    setupRemoteServiceBindings()

    -- 绑定UI交互事件到远程服务
    setupUIInteractionBindings()

    -- 绑定数据变化事件到UI更新
    setupDataChangeBindings()

    isInitialized = true
    print("✅ [ClientServiceCoordinator] 初始化完成")
end

-- 设置远程服务绑定
function setupRemoteServiceBindings()
    -- 绑定用户数据接收
    UserRemoteService.onPlayerDataReceived(function(success, data)
        DataController.setLoadingState(false)
        if success and data then
            DataController.updatePlayerData(data)
        else
            warn("❌ [ClientServiceCoordinator] 获取玩家数据失败:", data)
        end
    end)

    -- 绑定商店数据接收
    UserRemoteService.onShopDataReceived(function(success, data)
        if success and data then
            DataController.updateShopData(data)
        else
            warn("❌ [ClientServiceCoordinator] 获取商店数据失败:", data)
        end
    end)

    -- 绑定交易记录接收
    UserRemoteService.onTransactionsReceived(function(success, data)
        if success and data then
            DataController.updateTransactions(data)
        else
            warn("❌ [ClientServiceCoordinator] 获取交易记录失败:", data)
        end
    end)

    -- 绑定购买结果
    UserRemoteService.onBuyResult(function(success, message, newData)
        if success then
            print("✅ [ClientServiceCoordinator] 购买成功:", message)
            if newData then
                DataController.updatePlayerData(newData)
            end
        else
            warn("❌ [ClientServiceCoordinator] 购买失败:", message)
        end
    end)

    -- 绑定出售结果
    UserRemoteService.onSellResult(function(success, message, newData)
        if success then
            print("✅ [ClientServiceCoordinator] 出售成功:", message)
            if newData then
                DataController.updatePlayerData(newData)
            end
        else
            warn("❌ [ClientServiceCoordinator] 出售失败:", message)
        end
    end)

    -- 绑定数据刷新
    UserRemoteService.onDataRefreshed(function(success, data)
        if success and data then
            print("🔄 [ClientServiceCoordinator] 数据已刷新")
            DataController.updatePlayerData(data.playerData)
            DataController.updateShopData(data.shopData)
            DataController.updateTransactions(data.transactions)
        end
    end)

    print("✅ [ClientServiceCoordinator] 远程服务绑定完成")
end

-- 设置UI交互绑定
function setupUIInteractionBindings()
    UIController.Events.UIInteraction:Connect(function(interaction)
        local interactionType = interaction.type
        local data = interaction.data

        if interactionType == UIController.InteractionTypes.BUY_ITEM then
            DataController.setLoadingState(true)
            UserRemoteService.buyItem(data.itemId, data.quantity)

        elseif interactionType == UIController.InteractionTypes.SELL_ITEM then
            DataController.setLoadingState(true)
            UserRemoteService.sellItem(data.itemId, data.quantity)

        elseif interactionType == UIController.InteractionTypes.REFRESH_DATA then
            DataController.setLoadingState(true)
            UserRemoteService.refreshData()

        elseif interactionType == UIController.InteractionTypes.ADMIN_ACTION then
            handleAdminAction(data.action, data.data)

        end
    end)

    print("✅ [ClientServiceCoordinator] UI交互绑定完成")
end

-- 设置数据变化绑定
function setupDataChangeBindings()
    -- 当玩家数据变化时，通知相关UI更新
    DataController.Events.PlayerDataChanged:Connect(function(newData, oldData)
        -- 这里可以添加通知UI更新的逻辑
        print("📊 [ClientServiceCoordinator] 玩家数据已变化")
    end)

    -- 当商店数据变化时，通知相关UI更新
    DataController.Events.ShopDataChanged:Connect(function(newData, oldData)
        print("🏪 [ClientServiceCoordinator] 商店数据已变化")
    end)

    -- 当交易记录变化时，通知相关UI更新
    DataController.Events.TransactionsChanged:Connect(function(newData, oldData)
        print("📝 [ClientServiceCoordinator] 交易记录已变化")
    end)

    -- 当加载状态变化时，通知UI更新
    DataController.Events.LoadingStateChanged:Connect(function(isLoading)
        print("⏳ [ClientServiceCoordinator] 加载状态:", isLoading and "加载中" or "已完成")
    end)

    print("✅ [ClientServiceCoordinator] 数据变化绑定完成")
end

-- 处理管理员操作
function handleAdminAction(action, data)
    if action == "check_permission" then
        local hasPermission = AdminRemoteService.checkPermission()
        if hasPermission then
            print("✅ [ClientServiceCoordinator] 管理员权限验证成功")
        else
            warn("❌ [ClientServiceCoordinator] 管理员权限验证失败")
        end

    elseif action == "get_all_users" then
        AdminRemoteService.getAllUsers()

    elseif action == "set_user_coins" then
        AdminRemoteService.setUserCoins(data.userId, data.coins)

    -- 可以添加更多管理员操作
    end
end

-- 初始化数据加载
function ClientServiceCoordinator.loadInitialData()
    if not isInitialized then
        warn("❌ [ClientServiceCoordinator] 未初始化，无法加载数据")
        return
    end

    print("📡 [ClientServiceCoordinator] 开始加载初始数据...")
    DataController.setLoadingState(true)

    -- 请求玩家数据
    UserRemoteService.getPlayerData()

    -- 请求商店数据
    UserRemoteService.getShopData()

    -- 请求交易记录
    UserRemoteService.getTransactions()
end

-- 获取服务状态
function ClientServiceCoordinator.getStatus()
    return {
        isInitialized = isInitialized,
        dataStats = DataController.getStats(),
        uiState = UIController.getUIState()
    }
end

-- 清理资源
function ClientServiceCoordinator.cleanup()
    DataController.clearData()
    UIController.closeAllUI()
    isInitialized = false
    print("🧹 [ClientServiceCoordinator] 资源已清理")
end

return ClientServiceCoordinator
