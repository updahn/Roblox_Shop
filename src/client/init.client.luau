-- 商店系统客户端逻辑 - 新架构版本

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

-- 导入新架构的模块
local ClientServiceCoordinator, UIController, DataController
local success, result = pcall(function()
    ClientServiceCoordinator = require(getClientModule("controller/ClientServiceCoordinator"))
    UIController = require(getClientModule("controller/UIController"))
    DataController = require(getClientModule("controller/DataController"))
    return true
end)

if not success then
    warn("❌ [客户端] 控制器模块加载失败:", result)
    warn("⚠️ [客户端] 将使用简化模式启动")
end

-- 导入UI模块
local ShopUI, TutorialUI, DroneManager
local uiSuccess, uiResult = pcall(function()
    ShopUI = require(getClientModule("ui/ShopUI"))
    TutorialUI = require(getClientModule("ui/TutorialUI"))
    DroneManager = require(getClientModule("ui/DroneManager"))
    return true
end)

if not uiSuccess then
    warn("❌ [客户端] UI模块加载失败:", uiResult)
    warn("⚠️ [客户端] 某些UI功能可能不可用")
end

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

-- 设置UI事件绑定
local function setupUIBindings()
    -- 绑定UI显示/隐藏事件到实际的UI模块
    UIController.Events.ShopVisibilityChanged:Connect(function(visible)
        if ShopUI.setVisible then
            ShopUI.setVisible(visible)
        end
    end)

    UIController.Events.TutorialVisibilityChanged:Connect(function(visible)
        if visible then
            if TutorialUI.showTutorial then
                TutorialUI.showTutorial()
            end
        else
            if TutorialUI.hideTutorial then
                TutorialUI.hideTutorial()
            end
        end
    end)

    -- 绑定数据变化事件到UI更新
    DataController.Events.PlayerDataChanged:Connect(function(newData)
        if ShopUI.updatePlayerData then
            ShopUI.updatePlayerData(newData)
        end
    end)

    DataController.Events.ShopDataChanged:Connect(function(newData)
        if ShopUI.updateShopData then
            ShopUI.updateShopData(newData)
        end
    end)

    print("✅ UI事件绑定完成")
end

-- 设置键盘输入处理
local function setupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.E then
            -- E键切换商店显示
            UIController.toggleShop()

        elseif input.KeyCode == Enum.KeyCode.H then
            -- H键切换教程显示
            UIController.toggleTutorial()

        elseif input.KeyCode == Enum.KeyCode.B then
            -- B键召唤无人机
            UIController.triggerDroneAction("spawn")

        elseif input.KeyCode == Enum.KeyCode.N then
            -- N键收回无人机
            UIController.triggerDroneAction("recall")

        elseif input.KeyCode == Enum.KeyCode.M then
            -- M键切换无人机模式
            UIController.triggerDroneAction("switch_mode")
        end
    end)

    print("✅ 键盘输入处理设置完成")
end

-- 初始化客户端
local function initializeClient()
    -- 等待服务端数据加载
    if not waitForServerData() then
        warn("❌ 客户端初始化失败: 无法获取服务端数据")
        return
    end

    -- 初始化服务协调器（如果可用）
    if ClientServiceCoordinator and ClientServiceCoordinator.initialize then
        local coordSuccess, coordError = pcall(function()
            ClientServiceCoordinator.initialize()
        end)
        if not coordSuccess then
            warn("❌ [客户端] 服务协调器初始化失败:", coordError)
        end
    end

    -- 初始化UI模块（兼容旧接口）
    if ShopUI and ShopUI.init then
        local shopSuccess, shopError = pcall(function()
            ShopUI.init()
        end)
        if shopSuccess then
            print("✅ [客户端] ShopUI初始化成功")
        else
            warn("❌ [客户端] ShopUI初始化失败:", shopError)
        end
    end

    if TutorialUI and TutorialUI.initialize then
        local tutSuccess, tutError = pcall(function()
            TutorialUI.initialize()
        end)
        if not tutSuccess then
            warn("❌ [客户端] TutorialUI初始化失败:", tutError)
        end
    end

    if DroneManager and DroneManager.init then
        local droneSuccess, droneError = pcall(function()
            DroneManager.init()
        end)
        if not droneSuccess then
            warn("❌ [客户端] DroneManager初始化失败:", droneError)
        end
    end

    -- 设置UI绑定（如果模块可用）
    if UIController and DataController then
        local bindingSuccess, bindingError = pcall(function()
            setupUIBindings()
        end)
        if not bindingSuccess then
            warn("❌ [客户端] UI绑定设置失败:", bindingError)
        end
    end

    -- 设置键盘输入处理
    local inputSuccess, inputError = pcall(function()
        setupInputHandling()
    end)
    if not inputSuccess then
        warn("❌ [客户端] 键盘输入处理设置失败:", inputError)
    end

    -- 加载初始数据（如果协调器可用）
    if ClientServiceCoordinator and ClientServiceCoordinator.loadInitialData then
        local dataSuccess, dataError = pcall(function()
            ClientServiceCoordinator.loadInitialData()
        end)
        if not dataSuccess then
            warn("❌ [客户端] 初始数据加载失败:", dataError)
        end
    end

    print("✅ 商店系统已就绪！")
    print("⌨️  按 E 键打开/关闭商店")
    if TutorialUI then
        print("⌨️  按 H 键打开/关闭帮助")
    end
    if DroneManager then
        print("🤖 按 B 键召唤无人机")
        print("🤖 按 N 键收回无人机")
        print("🤖 按 M 键切换无人机模式")
    end
end

-- 启动客户端
initializeClient()