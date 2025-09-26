-- 靶子系统客户端UI逻辑
-- 负责处理靶子的可视化显示和UI更新
-- 通过TargetController与服务端通信

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

-- 引入TargetController
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local TargetController = require(StarterPlayer.StarterPlayerScripts.Client.controller.TargetController)

local TargetUI = {}

-- 本地靶子UI数据存储
local targetUIs = {}

-- 靶子文件夹引用
local targetsFolder = nil

-- 初始化靶子UI系统
function TargetUI.initialize()
    print("🎯 初始化靶子UI系统...")

    -- 获取靶子文件夹引用
    targetsFolder = Workspace:WaitForChild("Targets", 10)
    if not targetsFolder then
        warn("⚠️ 无法找到靶子文件夹")
        return false
    end

    -- 绑定Controller事件而不是服务端事件
    TargetUI.bindControllerEvents()

    print("✅ 靶子UI系统初始化完成")
    return true
end

-- 绑定Controller事件
function TargetUI.bindControllerEvents()
    -- 靶子创建事件
    TargetController.Events.TargetCreated:Connect(function(targetId, targetData)
        TargetUI.createTargetUI(targetId, targetData)
    end)

    -- 靶子受损事件
    TargetController.Events.TargetDamaged:Connect(function(targetId, health, maxHealth, attackerId)
        TargetUI.updateTargetHealth(targetId, health, maxHealth)
        TargetUI.showDamageEffect(targetId, attackerId)
    end)

    -- 靶子摧毁事件
    TargetController.Events.TargetDestroyed:Connect(function(targetId, destroyerId)
        TargetUI.hideTargetUI(targetId)
        TargetUI.showDestroyEffect(targetId, destroyerId)
    end)

    -- 靶子重生事件
    TargetController.Events.TargetRespawned:Connect(function(targetId, targetData)
        TargetUI.showTargetUI(targetId, targetData)
    end)

    -- 靶子状态变化事件
    TargetController.Events.TargetStatusChanged:Connect(function(targetId, newStatus, oldStatus)
        TargetUI.handleStatusChanged(targetId, newStatus, oldStatus)
    end)
end

-- 创建靶子UI
function TargetUI.createTargetUI(targetId, targetData)
    -- 等待靶子模型创建
    local targetModel = targetsFolder:WaitForChild(targetId, 5)
    if not targetModel then
        warn("⚠️ 无法找到靶子模型:", targetId)
        return
    end

    local targetPart = targetModel:WaitForChild("Base", 5)
    if not targetPart then
        warn("⚠️ 无法找到靶子主体部分:", targetId)
        return
    end

    -- 等待服务端创建的血条UI
    local healthGui = targetPart:WaitForChild("BillboardGui", 5)
    local healthFill = nil
    if healthGui then
        local healthBar = healthGui:FindFirstChild("Frame")
        if healthBar then
            healthFill = healthBar:FindFirstChild("HealthFill")
        end
    end

    -- 创建UI数据结构
    local uiData = {
        targetId = targetId,
        targetPart = targetPart,
        targetModel = targetModel,
        gui = healthGui,  -- 使用服务端创建的UI
        healthBar = healthGui and healthGui:FindFirstChild("Frame"),
        healthFill = healthFill,
        textLabel = healthGui and healthGui:FindFirstChild("TextLabel")
    }

    targetUIs[targetId] = uiData
    print("🎯 创建靶子UI:", targetId, "血条UI:", healthGui and "已找到" or "未找到")
end


-- 更新靶子血量显示（服务端已处理，客户端仅记录）
function TargetUI.updateTargetHealth(targetId, health, maxHealth)
    local uiData = targetUIs[targetId]
    if not uiData then
        return
    end

    -- 血条更新由服务端处理，客户端仅记录状态
    print("🩸 靶子血量更新:", targetId, "血量:", health .. "/" .. maxHealth)
end

-- 显示伤害效果
function TargetUI.showDamageEffect(targetId, attackerId)
    local uiData = targetUIs[targetId]
    if not uiData or not uiData.targetPart then
        return
    end

    -- 创建伤害数字显示
    local damageGui = Instance.new("BillboardGui")
    damageGui.Size = UDim2.new(0, 50, 0, 30)
    damageGui.StudsOffset = Vector3.new(math.random(-2, 2), 6, math.random(-2, 2))
    damageGui.Parent = uiData.targetPart

    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = "💥"
    damageLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    damageLabel.TextSize = 24
    damageLabel.TextStrokeTransparency = 0
    damageLabel.Parent = damageGui

    -- 动画效果
    local tween = game:GetService("TweenService"):Create(
        damageGui,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {StudsOffset = damageGui.StudsOffset + Vector3.new(0, 3, 0)}
    )

    local fadeTween = game:GetService("TweenService"):Create(
        damageLabel,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 1}
    )

    tween:Play()
    fadeTween:Play()

    -- 清理
    game:GetService("Debris"):AddItem(damageGui, 1.2)
end

-- 显示摧毁效果
function TargetUI.showDestroyEffect(targetId, destroyerId)
    local uiData = targetUIs[targetId]
    if not uiData or not uiData.targetPart then
        return
    end

    -- 创建摧毁特效
    local explosionGui = Instance.new("BillboardGui")
    explosionGui.Size = UDim2.new(0, 80, 0, 80)
    explosionGui.StudsOffset = Vector3.new(0, 2, 0)
    explosionGui.Parent = uiData.targetPart

    local explosionLabel = Instance.new("TextLabel")
    explosionLabel.Size = UDim2.new(1, 0, 1, 0)
    explosionLabel.BackgroundTransparency = 1
    explosionLabel.Text = "💥"
    explosionLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    explosionLabel.TextSize = 48
    explosionLabel.TextStrokeTransparency = 0
    explosionLabel.Parent = explosionGui

    -- 爆炸动画
    local scaleTween = game:GetService("TweenService"):Create(
        explosionLabel,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {TextSize = 72}
    )

    local fadeTween = game:GetService("TweenService"):Create(
        explosionLabel,
        TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 1}
    )

    scaleTween:Play()
    wait(0.2)
    fadeTween:Play()

    -- 清理
    game:GetService("Debris"):AddItem(explosionGui, 1)

    -- 显示摧毁者信息（如果是玩家）
    if destroyerId then
        TargetUI.showDestroyerInfo(targetId, destroyerId)
    end
end

-- 显示摧毁者信息
function TargetUI.showDestroyerInfo(targetId, destroyerId)
    local destroyer = Players:GetPlayerByUserId(destroyerId)
    if not destroyer then
        return
    end

    local uiData = targetUIs[targetId]
    if not uiData or not uiData.targetPart then
        return
    end

    -- 创建摧毁者信息显示
    local infoGui = Instance.new("BillboardGui")
    infoGui.Size = UDim2.new(0, 120, 0, 25)
    infoGui.StudsOffset = Vector3.new(0, 8, 0)
    infoGui.Parent = uiData.targetPart

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 1, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "🏆 " .. destroyer.Name .. " 摧毁了靶子!"
    infoLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    infoLabel.TextSize = 14
    infoLabel.TextStrokeTransparency = 0.5
    infoLabel.TextScaled = true
    infoLabel.Parent = infoGui

    -- 淡出动画
    local fadeTween = game:GetService("TweenService"):Create(
        infoLabel,
        TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 1}
    )

    wait(1)
    fadeTween:Play()

    -- 清理
    game:GetService("Debris"):AddItem(infoGui, 4)
end

-- 隐藏靶子UI
function TargetUI.hideTargetUI(targetId)
    local uiData = targetUIs[targetId]
    if not uiData then
        return
    end

    -- 隐藏GUI
    if uiData.gui then
        uiData.gui.Enabled = false
    end

    print("🙈 隐藏靶子UI:", targetId)
end

-- 显示靶子UI
function TargetUI.showTargetUI(targetId, targetData)
    local uiData = targetUIs[targetId]
    if not uiData then
        -- 如果UI不存在，重新创建
        TargetUI.createTargetUI(targetId, targetData)
        return
    end

    -- 显示GUI
    if uiData.gui then
        uiData.gui.Enabled = true
    end

    -- 重置血条
    if uiData.healthFill then
        uiData.healthFill.Size = UDim2.new(1, 0, 1, 0)
        uiData.healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end

    print("👁️ 显示靶子UI:", targetId)
end

-- 处理状态变化事件
function TargetUI.handleStatusChanged(targetId, newStatus, oldStatus)
    if targetId == "all" then
        -- 全量状态更新
        TargetUI.syncAllTargetStatus(newStatus)
    else
        -- 单个靶子状态更新
        TargetUI.syncSingleTargetStatus(targetId, newStatus)
    end
end

-- 同步所有靶子状态
function TargetUI.syncAllTargetStatus(allTargetStatus)
    local activeCount = 0
    for _ in pairs(allTargetStatus) do
        activeCount = activeCount + 1
    end
    print("🔄 同步所有靶子状态，活跃靶子数量:", activeCount)

    -- 隐藏不存在的靶子UI
    for targetId, uiData in pairs(targetUIs) do
        if not allTargetStatus[targetId] then
            TargetUI.hideTargetUI(targetId)
        end
    end

    -- 显示/更新活跃靶子的UI
    for targetId, targetStatus in pairs(allTargetStatus) do
        if targetStatus.alive then
            if not targetUIs[targetId] then
                TargetUI.createTargetUI(targetId, targetStatus)
            else
                TargetUI.showTargetUI(targetId, targetStatus)
                TargetUI.updateTargetHealth(targetId, targetStatus.health, targetStatus.maxHealth)
            end
        else
            TargetUI.hideTargetUI(targetId)
        end
    end
end

-- 同步单个靶子状态
function TargetUI.syncSingleTargetStatus(targetId, targetStatus)
    if targetStatus.alive then
        if not targetUIs[targetId] then
            TargetUI.createTargetUI(targetId, targetStatus)
        else
            TargetUI.showTargetUI(targetId, targetStatus)
            TargetUI.updateTargetHealth(targetId, targetStatus.health, targetStatus.maxHealth)
        end
    else
        TargetUI.hideTargetUI(targetId)
    end
end

-- 请求靶子状态更新（通过Controller）
function TargetUI.requestStatusUpdate()
    return TargetController.requestTargetStatus()
end

-- 获取靶子状态（通过Controller）
function TargetUI.getTargetStatus(targetId)
    return TargetController.getTargetStatus(targetId)
end

-- 获取所有靶子状态（通过Controller）
function TargetUI.getAllTargetStatus()
    return TargetController.getAllTargetStatus()
end

-- 获取靶子统计信息（通过Controller）
function TargetUI.getTargetStats()
    return TargetController.getTargetStats()
end

-- 清理靶子UI系统
function TargetUI.cleanup()
    -- 清理所有UI
    for targetId, uiData in pairs(targetUIs) do
        if uiData.gui then
            uiData.gui:Destroy()
        end
    end

    targetUIs = {}
    targetsFolder = nil

    print("🧹 靶子UI系统已清理")
end

-- 获取靶子UI数据（用于调试）
function TargetUI.getTargetUIData(targetId)
    return targetUIs[targetId]
end

-- 获取所有靶子UI数据（用于调试）
function TargetUI.getAllTargetUIData()
    return targetUIs
end

return TargetUI
