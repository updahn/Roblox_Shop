-- 无人机系统客户端管理器
-- 处理无人机UI、控制和视觉效果

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local DroneManager = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 等待模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))

-- 使用统一的配置
local DroneConfig = Config.DRONE_CONFIG

-- UI元素
local screenGui
local droneFrame
local spawnButton
local recallButton
local modeButton
local statusLabel
local timerLabel

-- 无人机状态
local droneStatus = {
    isActive = false,
    mode = DroneConfig.MODES.FOLLOW,
    timeRemaining = 0
}

-- ==============================================
-- 内部工具函数
-- ==============================================

local function log(message, ...)
    Config.log("INFO", "[客户端] " .. message, {...})
end

-- 创建按钮
local function createButton(name, text, position, size, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true

    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    -- 添加阴影效果
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, -2, 0, 2)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = button.ZIndex - 1
    shadow.Parent = button

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 6)
    shadowCorner.Parent = shadow

    -- 点击动画
    button.MouseButton1Down:Connect(function()
        local pressedSize = UDim2.new(size.X.Scale * 0.95, size.X.Offset * 0.95, size.Y.Scale * 0.95, size.Y.Offset * 0.95)
        local tween = TweenService:Create(button, TweenInfo.new(0.1), {Size = pressedSize})
        tween:Play()
    end)

    button.MouseButton1Up:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.1), {Size = size})
        tween:Play()
    end)

    return button
end

-- 创建标签
local function createLabel(name, text, position, size)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Text = text
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextStrokeTransparency = 0.5

    return label
end

-- ==============================================
-- UI创建函数
-- ==============================================

-- 更新按钮状态
local function updateButtonStates()
    if droneStatus.isActive then
        spawnButton.BackgroundColor3 = DroneConfig.UI.COLORS.DISABLED
        spawnButton.Text = "无人机活跃"

        recallButton.BackgroundColor3 = DroneConfig.UI.COLORS.RECALL_BUTTON
        recallButton.Text = DroneConfig.UI.TEXT.RECALL

        modeButton.BackgroundColor3 = DroneConfig.UI.COLORS.MODE_BUTTON
        if droneStatus.mode == DroneConfig.MODES.FOLLOW then
            modeButton.Text = DroneConfig.UI.TEXT.SWITCH_TO_GUARD
        else
            modeButton.Text = DroneConfig.UI.TEXT.SWITCH_TO_FOLLOW
        end

        statusLabel.Text = "状态: " .. (droneStatus.mode == DroneConfig.MODES.FOLLOW and "跟随模式" or "驻守模式")
    else
        spawnButton.BackgroundColor3 = DroneConfig.UI.COLORS.SPAWN_BUTTON
        spawnButton.Text = DroneConfig.UI.TEXT.SPAWN

        recallButton.BackgroundColor3 = DroneConfig.UI.COLORS.DISABLED
        recallButton.Text = "无无人机"

        modeButton.BackgroundColor3 = DroneConfig.UI.COLORS.DISABLED
        modeButton.Text = "模式切换"

        statusLabel.Text = "状态: 待命"
        timerLabel.Text = "剩余时间: --"
    end
end

local function createDroneUI()
    -- 创建ScreenGui（但设置为隐藏状态）
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DroneUI"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false  -- 隐藏UI
    screenGui.Parent = playerGui

    -- 主框架
    droneFrame = Instance.new("Frame")
    droneFrame.Name = "DroneFrame"
    droneFrame.Size = UDim2.new(0, 280, 0, 200)
    droneFrame.Position = UDim2.new(1, -300, 1, -220)
    droneFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    droneFrame.BackgroundTransparency = 0.1
    droneFrame.BorderSizePixel = 0
    droneFrame.Parent = screenGui

    -- 添加圆角和阴影
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = droneFrame

    -- 标题
    local titleLabel = createLabel("TitleLabel", "🤖 无人机控制", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30))
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.Parent = droneFrame

    -- 召唤按钮
    spawnButton = createButton("SpawnButton", DroneConfig.UI.TEXT.SPAWN,
        UDim2.new(0, 10, 0, 40), UDim2.new(0.45, -7.5, 0, DroneConfig.UI.BUTTON_SIZE.Y.Offset),
        DroneConfig.UI.COLORS.SPAWN_BUTTON)
    spawnButton.Parent = droneFrame

    -- 收回按钮
    recallButton = createButton("RecallButton", DroneConfig.UI.TEXT.RECALL,
        UDim2.new(0.55, 7.5, 0, 40), UDim2.new(0.45, -7.5, 0, DroneConfig.UI.BUTTON_SIZE.Y.Offset),
        DroneConfig.UI.COLORS.RECALL_BUTTON)
    recallButton.Parent = droneFrame

    -- 模式切换按钮
    modeButton = createButton("ModeButton", DroneConfig.UI.TEXT.MODE_FOLLOW,
        UDim2.new(0, 10, 0, 90), UDim2.new(1, -20, 0, DroneConfig.UI.BUTTON_SIZE.Y.Offset),
        DroneConfig.UI.COLORS.MODE_BUTTON)
    modeButton.Parent = droneFrame

    -- 状态标签
    statusLabel = createLabel("StatusLabel", "状态: 待命",
        UDim2.new(0, 10, 0, 140), UDim2.new(1, -20, 0, 20))
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = droneFrame

    -- 计时器标签
    timerLabel = createLabel("TimerLabel", "剩余时间: --",
        UDim2.new(0, 10, 0, 165), UDim2.new(1, -20, 0, 20))
    timerLabel.TextXAlignment = Enum.TextXAlignment.Left
    timerLabel.Parent = droneFrame

    -- 初始化按钮状态
    updateButtonStates()
end

-- 更新计时器
local function updateTimer()
    if droneStatus.isActive and droneStatus.timeRemaining > 0 then
        timerLabel.Text = string.format("剩余时间: %.1f秒", droneStatus.timeRemaining)
    else
        timerLabel.Text = "剩余时间: --"
    end
end

-- ==============================================
-- 事件处理函数
-- ==============================================

local function handleSpawnButtonClick()
    if not droneStatus.isActive then
        log("请求召唤无人机")
        Events.Drone.SpawnDrone:FireServer()
    end
end

local function handleRecallButtonClick()
    if droneStatus.isActive then
        log("请求收回无人机")
        Events.Drone.RecallDrone:FireServer()
    end
end

local function handleModeButtonClick()
    if droneStatus.isActive then
        local newMode = droneStatus.mode == DroneConfig.MODES.FOLLOW and DroneConfig.MODES.GUARD or DroneConfig.MODES.FOLLOW
        log("请求切换无人机模式到:", newMode)
        Events.Drone.SwitchDroneMode:FireServer(newMode)
    end
end

-- 服务端事件处理
local function handleDroneSpawned(success)
    if success then
        droneStatus.isActive = true
        droneStatus.mode = DroneConfig.MODES.FOLLOW
        droneStatus.timeRemaining = DroneConfig.LIFETIME

        updateButtonStates()
        log("无人机已召唤")
    else
        log("无人机召唤失败")
    end
end

local function handleDroneRecalled(success)
    if success then
        droneStatus.isActive = false
        droneStatus.timeRemaining = 0

        updateButtonStates()
        log("无人机已收回")
    end
end

local function handleDroneModeChanged(newMode, oldMode)
    droneStatus.mode = newMode
    updateButtonStates()
    log("无人机模式已从", oldMode, "切换到", newMode)
end

local function handleDroneDestroyed(reason)
    droneStatus.isActive = false
    droneStatus.timeRemaining = 0

    updateButtonStates()
    log("无人机已销毁，原因:", reason)

    -- 可以在这里显示通知
end

local function handleDroneAttack(targetName)
    log("无人机攻击了目标:", targetName)
    -- 可以在这里添加攻击指示器或音效
end

-- ==============================================
-- 初始化函数
-- ==============================================

function DroneManager.init()
    -- 创建UI
    createDroneUI()

    -- 连接按钮事件
    spawnButton.MouseButton1Click:Connect(handleSpawnButtonClick)
    recallButton.MouseButton1Click:Connect(handleRecallButtonClick)
    modeButton.MouseButton1Click:Connect(handleModeButtonClick)

    -- 连接服务端事件
    Events.Drone.DroneSpawned.OnClientEvent:Connect(handleDroneSpawned)
    Events.Drone.DroneRecalled.OnClientEvent:Connect(handleDroneRecalled)
    Events.Drone.DroneModeChanged.OnClientEvent:Connect(handleDroneModeChanged)
    Events.Drone.DroneDestroyed.OnClientEvent:Connect(handleDroneDestroyed)
    Events.Drone.DroneAttack.OnClientEvent:Connect(handleDroneAttack)

    -- 启动计时器更新循环
    spawn(function()
        while true do
            if droneStatus.isActive and droneStatus.timeRemaining > 0 then
                droneStatus.timeRemaining = droneStatus.timeRemaining - 0.1
                updateTimer()

                if droneStatus.timeRemaining <= 0 then
                    -- 时间到，重置状态
                    droneStatus.isActive = false
                    updateButtonStates()
                end
            end
            wait(0.1)
        end
    end)

    -- 初始化无人机管理器（已禁用）
function DroneManager.initialize()
    log("无人机管理器已禁用，不创建UI界面")
    -- 完全禁用无人机功能以避免界面混乱
    return
end

log("无人机管理器初始化函数已禁用")
end

function DroneManager.cleanup()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end

    log("无人机管理器已清理")
end

-- 添加键盘快捷键支持
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.B then
        -- B键召唤无人机
        if not droneStatus.isActive then
            handleSpawnButtonClick()
        end
    elseif input.KeyCode == Enum.KeyCode.N then
        -- N键收回无人机
        if droneStatus.isActive then
            handleRecallButtonClick()
        end
    elseif input.KeyCode == Enum.KeyCode.M then
        -- M键切换模式
        if droneStatus.isActive then
            handleModeButtonClick()
        end
    end
end)

log("无人机客户端管理器已加载")

return DroneManager
