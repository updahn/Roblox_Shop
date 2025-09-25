-- 商店系统客户端逻辑 - 重构版本
-- 整合了UserController, AdminController, DroneController架构

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- 获取客户端模块的辅助函数
local function getClientModule(path)
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

-- 导入新架构的控制器
local UserController, AdminController, DroneController, TargetController
local success, result = pcall(function()
    UserController = require(getClientModule("controller/UserController"))
    AdminController = require(getClientModule("controller/AdminController"))
    DroneController = require(getClientModule("controller/DroneController"))
    TargetController = require(getClientModule("controller/TargetController"))
    return true
end)

if not success then
    warn("❌ [客户端] 控制器模块加载失败:", result)
    warn("⚠️ [客户端] 将使用简化模式启动")
end

-- 导入UI模块
local ShopUI, TutorialUI, DroneUI, ShopRecords, ShopAdminPanel, TargetUI
local uiSuccess, uiResult = pcall(function()
    ShopUI = require(getClientModule("ui/ShopUI"))
    TutorialUI = require(getClientModule("ui/TutorialUI"))
    DroneUI = require(getClientModule("ui/DroneUI"))
    ShopRecords = require(getClientModule("ui/ShopRecords"))
    ShopAdminPanel = require(getClientModule("ui/ShopAdminPanel"))
    TargetUI = require(getClientModule("ui/TargetUI"))
    return true
end)

if not uiSuccess then
    warn("❌ [客户端] UI模块加载失败:", uiResult)
    warn("⚠️ [客户端] 某些UI功能可能不可用")
end

-- UI状态管理
local uiState = {
    shopVisible = false,
    tutorialVisible = false,
    droneUIVisible = false
}

-- 等待服务端数据
local function waitForServerData()
    print("🔄 商店客户端加载中...")

    local success, sharedModules = pcall(function()
        local sharedModules = ReplicatedStorage:WaitForChild("SharedModules", 15)
        sharedModules:WaitForChild("ShopEvents", 10)
        return sharedModules
    end)

    if not success or not sharedModules then
        warn("❌ 客户端: 等待服务端数据超时")
        warn("💡 提示: 确保服务端已正确启动并设置了共享模块")
        return false
    end

    print("✅ 客户端: 服务端数据加载成功")
    return true
end

-- 设置控制器事件绑定
local function setupControllerBindings()
    if not UserController then return end

    -- 绑定用户数据变化到UI更新
    UserController.Events.PlayerDataChanged:Connect(function(newData)
        print("📊 [客户端] 玩家数据已变化")
        if ShopUI and ShopUI.updatePlayerData then
            ShopUI.updatePlayerData(newData)
        end
    end)

    UserController.Events.ShopDataChanged:Connect(function(newData)
        print("🏪 [客户端] 商店数据已变化")
        if ShopUI and ShopUI.updateShopData then
            ShopUI.updateShopData(newData)
        end
    end)

    UserController.Events.LoadingStateChanged:Connect(function(isLoading)
        print("⏳ [客户端] 加载状态:", isLoading and "加载中" or "已完成")
    end)

    -- 绑定购买和出售结果
    UserController.Events.BuyResult:Connect(function(success, message, newData)
        if success then
            print("✅ [客户端] 购买成功:", message)
        else
            print("❌ [客户端] 购买失败:", message)
        end
    end)

    UserController.Events.SellResult:Connect(function(success, message, newData)
        if success then
            print("✅ [客户端] 出售成功:", message)
        else
            print("❌ [客户端] 出售失败:", message)
        end
    end)

    print("✅ 控制器事件绑定完成")
end

-- 设置无人机控制器绑定
local function setupDroneBindings()
    if not DroneController then return end

    DroneController.Events.DroneStatusChanged:Connect(function(status)
        print("🤖 [客户端] 无人机状态变化:", status.isActive and "激活" or "待命")
        if DroneUI and DroneUI.updateStatus then
            DroneUI.updateStatus(status)
        end
    end)

    DroneController.Events.DroneSpawned:Connect(function(success)
        if success then
            print("✅ [客户端] 无人机召唤成功")
        else
            print("❌ [客户端] 无人机召唤失败")
        end
    end)

    print("✅ 无人机事件绑定完成")
end

-- UI控制功能
local function toggleShop()
    uiState.shopVisible = not uiState.shopVisible
    if ShopUI then
        if uiState.shopVisible then
            if ShopUI.openShop then
                ShopUI.openShop()
            end
        else
            if ShopUI.closeShop then
                ShopUI.closeShop()
            end
        end
    end
end

local function toggleTutorial()
    uiState.tutorialVisible = not uiState.tutorialVisible
    if TutorialUI then
        if uiState.tutorialVisible then
            if TutorialUI.showTutorial then
                TutorialUI.showTutorial()
            end
        else
            if TutorialUI.hideTutorial then
                TutorialUI.hideTutorial()
            end
        end
    end
end

local function handleDroneAction(action)
    if DroneController then
        DroneController.handleDroneAction(action)
    else
        warn("⚠️ [客户端] 无人机控制器不可用")
    end
end

-- 设置键盘输入处理
local function setupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.E then
            -- E键切换商店显示
            toggleShop()

        elseif input.KeyCode == Enum.KeyCode.H then
            -- H键切换教程显示
            toggleTutorial()

        elseif input.KeyCode == Enum.KeyCode.B then
            -- B键召唤无人机
            handleDroneAction("spawn")

        elseif input.KeyCode == Enum.KeyCode.N then
            -- N键收回无人机
            handleDroneAction("recall")

        elseif input.KeyCode == Enum.KeyCode.M then
            -- M键切换无人机模式
            handleDroneAction("switch_mode")
        end
    end)

    print("✅ 键盘输入处理设置完成")
end

-- 初始化控制器
local function initializeControllers()
    local initSuccess = true

    -- 初始化UserController
    if UserController and UserController.initialize then
        local success, error = pcall(function()
            UserController.initialize()
        end)
        if not success then
            warn("❌ [客户端] UserController初始化失败:", error)
            initSuccess = false
        else
            print("✅ [客户端] UserController初始化成功")
        end
    end

    -- 初始化AdminController
    if AdminController and AdminController.initialize then
        local success, error = pcall(function()
            AdminController.initialize()
        end)
        if not success then
            warn("❌ [客户端] AdminController初始化失败:", error)
        else
            print("✅ [客户端] AdminController初始化成功")
        end
    end

    -- 初始化DroneController
    if DroneController and DroneController.initialize then
        local success, error = pcall(function()
            DroneController.initialize()
        end)
        if not success then
            warn("❌ [客户端] DroneController初始化失败:", error)
        else
            print("✅ [客户端] DroneController初始化成功")
        end
    end

    -- 初始化TargetController
    if TargetController and TargetController.initialize then
        local success, error = pcall(function()
            TargetController.initialize()
        end)
        if not success then
            warn("❌ [客户端] TargetController初始化失败:", error)
            initSuccess = false
        else
            print("✅ [客户端] TargetController初始化成功")
        end
    end

    return initSuccess
end

-- 初始化UI模块
local function initializeUI()
    -- 初始化ShopUI（使用新的控制器架构）
    if ShopUI and ShopUI.initWithControllers then
        local shopSuccess, shopError = pcall(function()
            ShopUI.initWithControllers(UserController, AdminController)
        end)
        if shopSuccess then
            print("✅ [客户端] ShopUI初始化成功")
        else
            warn("❌ [客户端] ShopUI初始化失败:", shopError)
        end
    elseif ShopUI and ShopUI.init then
        -- 后备方案：使用旧的初始化方法
        local shopSuccess, shopError = pcall(function()
            ShopUI.init()
        end)
        if shopSuccess then
            print("✅ [客户端] ShopUI初始化成功（使用兼容模式）")
        else
            warn("❌ [客户端] ShopUI初始化失败:", shopError)
        end
    end

    -- 为其他UI模块设置控制器
    if ShopRecords and ShopRecords.setControllers then
        pcall(function()
            ShopRecords.setControllers(UserController, AdminController)
        end)
    end

    if ShopAdminPanel and ShopAdminPanel.setControllers then
        pcall(function()
            ShopAdminPanel.setControllers(AdminController)
        end)
    end

    if DroneUI and DroneUI.setControllers then
        pcall(function()
            DroneUI.setControllers(DroneController)
        end)
    end

    if TutorialUI and TutorialUI.setControllers then
        pcall(function()
            TutorialUI.setControllers()
        end)
    end

    -- 初始化TutorialUI
    if TutorialUI and TutorialUI.initialize then
        local tutSuccess, tutError = pcall(function()
            TutorialUI.initialize()
        end)
        if not tutSuccess then
            warn("❌ [客户端] TutorialUI初始化失败:", tutError)
        else
            print("✅ [客户端] TutorialUI初始化成功")
        end
    end

    -- 初始化TargetUI
    if TargetUI and TargetUI.initialize then
        local targetSuccess, targetError = pcall(function()
            TargetUI.initialize()
        end)
        if not targetSuccess then
            warn("❌ [客户端] TargetUI初始化失败:", targetError)
        else
            print("✅ [客户端] TargetUI初始化成功")
        end
    end

    -- 初始化DroneUI（使用控制器连接）
    if DroneUI and DroneController then
        if DroneUI.initWithController then
            local droneSuccess, droneError = pcall(function()
                DroneUI.initWithController(DroneController)
            end)
            if not droneSuccess then
                warn("❌ [客户端] DroneUI初始化失败:", droneError)
            else
                print("✅ [客户端] DroneUI初始化成功")
            end
        elseif DroneUI.init then
            -- 后备方案：使用普通初始化
            local droneSuccess, droneError = pcall(function()
                DroneUI.init()
                if DroneUI.setDroneController then
                    DroneUI.setDroneController(DroneController)
                end
            end)
            if not droneSuccess then
                warn("❌ [客户端] DroneUI初始化失败:", droneError)
            else
                print("✅ [客户端] DroneUI初始化成功")
            end
        end
    end
end

-- 加载初始数据
local function loadInitialData()
    if UserController and UserController.loadInitialData then
        local dataSuccess, dataError = pcall(function()
            UserController.loadInitialData()
        end)
        if not dataSuccess then
            warn("❌ [客户端] 初始数据加载失败:", dataError)
        else
            print("✅ [客户端] 初始数据加载成功")
        end
    end
end

-- 初始化客户端
local function initializeClient()
    -- 等待服务端数据加载
    if not waitForServerData() then
        warn("❌ 客户端初始化失败: 无法获取服务端数据")
        return
    end

    -- 初始化控制器
    if not initializeControllers() then
        warn("⚠️ [客户端] 部分控制器初始化失败")
    end

    -- 设置控制器事件绑定
    local bindingSuccess, bindingError = pcall(function()
        setupControllerBindings()
        setupDroneBindings()
    end)
    if not bindingSuccess then
        warn("❌ [客户端] 控制器绑定设置失败:", bindingError)
    end

    -- 初始化UI模块
    local uiInitSuccess, uiInitError = pcall(function()
        initializeUI()
    end)
    if not uiInitSuccess then
        warn("❌ [客户端] UI初始化失败:", uiInitError)
    end

    -- 设置键盘输入处理
    local inputSuccess, inputError = pcall(function()
        setupInputHandling()
    end)
    if not inputSuccess then
        warn("❌ [客户端] 键盘输入处理设置失败:", inputError)
    end

    -- 加载初始数据
    local dataLoadSuccess, dataLoadError = pcall(function()
        loadInitialData()
    end)
    if not dataLoadSuccess then
        warn("❌ [客户端] 初始数据加载失败:", dataLoadError)
    end

    print("✅ 商店系统已就绪！")
    print("⌨️  按 E 键打开/关闭商店")
    if TutorialUI then
        print("⌨️  按 H 键打开/关闭帮助")
    end
    if DroneController then
        print("🤖 按 B 键召唤无人机")
        print("🤖 按 N 键收回无人机")
        print("🤖 按 M 键切换无人机模式")
    end
end

-- 启动客户端
initializeClient()