-- 无人机UI管理器

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DroneUI = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 等待模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

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

-- DroneController引用（将在初始化时设置）
local DroneController = nil

-- ==============================================
-- 内部工具函数
-- ==============================================

local function log(message, ...)
    Config.log("INFO", "[DroneUI] " .. message, {...})
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
-- UI状态更新函数
-- ==============================================

-- 更新按钮状态
function DroneUI.updateButtonStates(droneStatus)
    if not screenGui or not droneStatus then return end

    -- 检查UI元素是否存在
    if not spawnButton or not recallButton or not modeButton or not statusLabel or not timerLabel then
        warn("❌ [DroneUI] UI元素未完全创建，跳过状态更新")
        return
    end

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

        -- 更新计时器
        DroneUI.updateTimer(droneStatus.timeRemaining)
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

-- 更新计时器显示
function DroneUI.updateTimer(timeRemaining)
    if not timerLabel then
        warn("❌ [DroneUI] timerLabel未创建，跳过计时器更新")
        return
    end

    if timeRemaining and timeRemaining > 0 then
        timerLabel.Text = string.format("剩余时间: %.1f秒", timeRemaining)
    else
        timerLabel.Text = "剩余时间: --"
    end
end

-- 更新状态显示（由DroneController调用）
function DroneUI.updateStatus(status)
    DroneUI.updateButtonStates(status)
end

-- ==============================================
-- UI创建函数
-- ==============================================

local function createDroneUI()
    -- 创建ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DroneUI"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = true
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

    -- 添加圆角
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

    log("无人机UI界面创建完成")
end

-- ==============================================
-- 事件处理函数
-- ==============================================

-- 连接按钮事件到控制器
local function connectButtonEvents()
    if not DroneController then
        warn("❌ [DroneUI] DroneController未设置")
        return
    end

    -- 检查按钮是否存在
    if not spawnButton then
        warn("❌ [DroneUI] spawnButton未创建")
        return
    end
    if not recallButton then
        warn("❌ [DroneUI] recallButton未创建")
        return
    end
    if not modeButton then
        warn("❌ [DroneUI] modeButton未创建")
        return
    end

    spawnButton.MouseButton1Click:Connect(function()
        DroneController.handleDroneAction("spawn")
    end)

    recallButton.MouseButton1Click:Connect(function()
        DroneController.handleDroneAction("recall")
    end)

    modeButton.MouseButton1Click:Connect(function()
        DroneController.handleDroneAction("switch_mode")
    end)

    log("按钮事件已连接到控制器")
end

-- ==============================================
-- 公共接口
-- ==============================================

-- 设置DroneController引用
function DroneUI.setDroneController(controller)
    DroneController = controller
    log("DroneController引用已设置")
end

-- 设置控制器（为了与其他UI模块保持一致的接口）
function DroneUI.setControllers(droneController)
    DroneUI.setDroneController(droneController)
    log("控制器已设置")
end

-- 显示/隐藏UI
function DroneUI.setVisible(visible)
    if screenGui then
        screenGui.Enabled = visible
        log("UI可见性设置为:", visible)
    end
end

-- 获取UI可见状态
function DroneUI.isVisible()
    return screenGui and screenGui.Enabled or false
end

-- ==============================================
-- 初始化函数
-- ==============================================

function DroneUI.init()
    log("开始初始化无人机UI...")

    -- 创建UI
    createDroneUI()

    -- 连接按钮事件（如果控制器已设置）
    if DroneController then
        connectButtonEvents()
    end

    log("无人机UI初始化完成")
end

-- 设置控制器并连接事件（延迟初始化）
function DroneUI.initWithController(controller)
    log("开始初始化无人机UI（带控制器）...")

    -- 创建UI（如果还没创建）
    if not screenGui then
        createDroneUI()
    end

    -- 设置控制器
    DroneUI.setDroneController(controller)

    -- 连接按钮事件
    connectButtonEvents()

    -- 获取初始状态并更新UI
    local initialStatus = controller.getDroneStatus()
    DroneUI.updateStatus(initialStatus)

    log("无人机UI与控制器连接完成")
end

function DroneUI.cleanup()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end

    -- 重置所有UI元素引用
    droneFrame = nil
    spawnButton = nil
    recallButton = nil
    modeButton = nil
    statusLabel = nil
    timerLabel = nil

    log("无人机UI已清理")
end

-- 初始化无人机管理器（禁用原始的）
function DroneUI.initialize()
    log("无人机管理器已禁用，使用新的UI架构")
    return
end

return DroneUI
