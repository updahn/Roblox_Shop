-- 商店系统客户端逻辑

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- 等待服务端数据
local function waitForServerData()
    print("🔄 商店客户端加载中...")

    local success, data = pcall(function()
        local sharedModules = ReplicatedStorage:WaitForChild("SharedModules", 15)
        sharedModules:WaitForChild("ShopData", 5)
        sharedModules:WaitForChild("ShopEvents", 5)
        return sharedModules
    end)

    if not success then
        warn("❌ 客户端: 等待服务端数据超时")
        return false
    end

    return true
end

-- 初始化客户端
local function initializeClient()
    -- 等待服务端数据加载
    if not waitForServerData() then
        warn("❌ 客户端初始化失败: 无法获取服务端数据")
        return
    end

    -- 导入共享模块（由各子模块使用，这里只是预加载）
    require(ReplicatedStorage.SharedModules.ShopData)
    require(ReplicatedStorage.SharedModules.ShopEvents)

    -- 导入商店UI
    local ShopUI = require(script.user:WaitForChild("ShopUI"))
    local TutorialUI = require(script.user:WaitForChild("TutorialUI"))
    local DroneManager = require(script.user:WaitForChild("DroneManager"))

    -- 初始化商店UI
    ShopUI.init()

    -- 初始化教程UI（不启用键盘监听）
    TutorialUI.initialize()

    -- 初始化无人机管理器
    DroneManager.init()

    -- 统一键盘输入处理
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.H then
            -- H键优先处理教程UI
            if TutorialUI.isShowing() then
                TutorialUI.hideTutorial()
            else
                -- 如果教程未显示，则显示教程
                TutorialUI.showTutorial()
            end
        end
    end)

    print("✅ 商店系统已就绪！")
    print("⌨️  按 E 键打开/关闭商店")
    print("⌨️  按 H 键打开/关闭帮助")
    print("🤖 按 B 键召唤无人机")
    print("🤖 按 N 键收回无人机")
    print("🤖 按 M 键切换无人机模式")
end

-- 启动客户端
initializeClient()