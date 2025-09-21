-- 靶子系统服务端逻辑
-- 管理靶子的生成、销毁和状态同步

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))

-- 使用统一的配置
local DroneConfig = Config.DRONE_CONFIG

local TargetService = {}

-- 靶子数据存储
local targets = {}
local targetConnections = {}
local nextTargetId = 1

-- 靶子文件夹
local targetsFolder = Workspace:FindFirstChild("Targets")
if not targetsFolder then
    targetsFolder = Instance.new("Folder")
    targetsFolder.Name = "Targets"
    targetsFolder.Parent = Workspace
end

-- 创建单个靶子
function TargetService.createTarget(position)
    local targetId = "Target_" .. nextTargetId
    nextTargetId = nextTargetId + 1

    local targetData = {
        id = targetId,
        position = position,
        health = Config.TARGETS.MAX_HEALTH,
        maxHealth = Config.TARGETS.MAX_HEALTH,
        alive = true,
        respawnTime = 0,
        part = nil
    }

    -- 创建靶子模型
    local targetModel = Instance.new("Model")
    targetModel.Name = targetId
    targetModel.Parent = targetsFolder

    -- 主体部分
    local targetPart = Instance.new("Part")
    targetPart.Name = "Base"
    targetPart.Size = Config.TARGETS.APPEARANCE.SIZE
    targetPart.Position = position
    targetPart.Material = Config.TARGETS.APPEARANCE.MATERIAL
    targetPart.Color = Config.TARGETS.APPEARANCE.COLOR
    targetPart.Anchored = true
    targetPart.CanCollide = false
    targetPart.Parent = targetModel

    -- 添加圆形靶子纹理
    local frontDecal = Instance.new("Decal")
    frontDecal.Texture = "rbxasset://textures/face.png" -- 可以替换为自定义靶子纹理
    frontDecal.Face = Enum.NormalId.Front
    frontDecal.Parent = targetPart

    -- 添加支撑杆
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.5, 8, 0.5)
    pole.Position = position - Vector3.new(0, 4.5, 0)
    pole.Material = Enum.Material.Wood
    pole.Color = Color3.fromRGB(139, 69, 19) -- 棕色
    pole.Anchored = true
    pole.CanCollide = false
    pole.Parent = targetModel

    -- 添加底座
    local base = Instance.new("Part")
    base.Name = "Stand"
    base.Size = Vector3.new(3, 0.5, 3)
    base.Position = position - Vector3.new(0, 8.75, 0)
    base.Material = Enum.Material.Concrete
    base.Color = Color3.fromRGB(100, 100, 100) -- 灰色
    base.Anchored = true
    base.CanCollide = true
    base.Parent = targetModel

    -- 设置PrimaryPart为主要的靶子部分
    targetModel.PrimaryPart = targetPart

    -- 添加标识牌
    if Config.TARGETS.MARKER.ENABLED then
        local gui = Instance.new("BillboardGui")
        gui.Size = UDim2.new(0, 100, 0, 50)
        gui.StudsOffset = Vector3.new(0, 4, 0)
        gui.Parent = targetPart

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = Config.TARGETS.MARKER.TEXT
        textLabel.TextColor3 = Config.TARGETS.MARKER.TEXT_COLOR
        textLabel.TextSize = Config.TARGETS.MARKER.TEXT_SIZE
        textLabel.TextStrokeTransparency = 0.5
        textLabel.Parent = gui

        -- 血条
        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(0.8, 0, 0.2, 0)
        healthBar.Position = UDim2.new(0.1, 0, 1.2, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = gui

        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Name = "HealthFill"
        healthFill.Parent = healthBar
    end

    targetData.part = targetPart
    targetData.model = targetModel
    targets[targetId] = targetData

    print("🎯 创建靶子:", targetId, "位置:", position)

    -- 通知所有客户端靶子创建
    Events.Target.TargetCreated:FireAllClients(targetId, {
        position = position,
        health = targetData.health,
        maxHealth = targetData.maxHealth
    })

    return targetData
end

-- 损坏靶子
function TargetService.damageTarget(targetId, damage, attackerId)
    local target = targets[targetId]
    if not target or not target.alive then
        return false
    end

    target.health = math.max(0, target.health - damage)

    -- 更新血条显示
    if target.part then
        local gui = target.part:FindFirstChild("BillboardGui")
        if gui then
            local healthFill = gui:FindFirstChild("Frame"):FindFirstChild("HealthFill")
            if healthFill then
                local healthPercent = target.health / target.maxHealth
                healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)

                -- 根据血量改变颜色
                if healthPercent > 0.6 then
                    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                elseif healthPercent > 0.3 then
                    healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                else
                    healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end

    print("🎯 靶子", targetId, "受到", damage, "点伤害，剩余血量:", target.health)

    -- 通知所有客户端靶子受损
    Events.Target.TargetDamaged:FireAllClients(targetId, target.health, target.maxHealth, attackerId)

    -- 如果靶子被摧毁
    if target.health <= 0 then
        TargetService.destroyTarget(targetId, attackerId)
        return true
    end

    return false
end

-- 摧毁靶子
function TargetService.destroyTarget(targetId, destroyerId)
    local target = targets[targetId]
    if not target or not target.alive then
        return
    end

    target.alive = false
    target.respawnTime = tick() + Config.TARGETS.RESPAWN_TIME

    -- 隐藏靶子
    if target.model then
        -- 隐藏模型中的所有部件
        for _, part in pairs(target.model:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                part.CanCollide = false
            end
        end

        -- 隐藏GUI
        if target.part then
            local gui = target.part:FindFirstChild("BillboardGui")
            if gui then
                gui.Enabled = false
            end
        end
    end

    print("💥 靶子", targetId, "被摧毁，将在", Config.TARGETS.RESPAWN_TIME, "秒后重生")

    -- 通知所有客户端靶子被摧毁
    Events.Target.TargetDestroyed:FireAllClients(targetId, destroyerId)
end

-- 重生靶子
function TargetService.respawnTarget(targetId)
    local target = targets[targetId]
    if not target or target.alive then
        return
    end

    target.health = target.maxHealth
    target.alive = true
    target.respawnTime = 0

    -- 显示靶子
    if target.model then
        -- 显示模型中的所有部件并恢复原始属性
        for _, part in pairs(target.model:GetChildren()) do
            if part:IsA("BasePart") then
                if part.Name == "Base" then
                    part.Transparency = 0
                    part.CanCollide = false
                    part.Color = Config.TARGETS.APPEARANCE.COLOR
                elseif part.Name == "Pole" then
                    part.Transparency = 0
                    part.CanCollide = false
                    part.Color = Color3.fromRGB(139, 69, 19)
                elseif part.Name == "Stand" then
                    part.Transparency = 0
                    part.CanCollide = true
                    part.Color = Color3.fromRGB(100, 100, 100)
                end
            end
        end

        -- 显示GUI并重置血条
        if target.part then
            local gui = target.part:FindFirstChild("BillboardGui")
            if gui then
                gui.Enabled = true
                local healthFill = gui:FindFirstChild("Frame"):FindFirstChild("HealthFill")
                if healthFill then
                    healthFill.Size = UDim2.new(1, 0, 1, 0)
                    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                end
            end
        end
    end

    print("🔄 靶子", targetId, "已重生")

    -- 通知所有客户端靶子重生
    Events.Target.TargetRespawned:FireAllClients(targetId, {
        position = target.position,
        health = target.health,
        maxHealth = target.maxHealth
    })
end

-- 获取最近的靶子
function TargetService.getNearestTarget(position, maxDistance)
    local nearestTarget = nil
    local nearestDistance = maxDistance or math.huge

    for targetId, target in pairs(targets) do
        if target.alive and target.part then
            local distance = (position - target.part.Position).Magnitude
            if distance < nearestDistance then
                nearestTarget = target
                nearestDistance = distance
            end
        end
    end

    return nearestTarget, nearestDistance
end

-- 获取所有活跃靶子
function TargetService.getActiveTargets()
    local activeTargets = {}
    for targetId, target in pairs(targets) do
        if target.alive then
            activeTargets[targetId] = {
                id = targetId,
                position = target.position,
                health = target.health,
                maxHealth = target.maxHealth
            }
        end
    end
    return activeTargets
end

-- 初始化靶子系统
function TargetService.initialize()
    print("🎯 初始化靶子系统...")

    -- 生成靶子
    for i = 1, Config.TARGETS.COUNT do
        -- 在圆形区域内随机生成位置
        local angle = (i - 1) * (360 / Config.TARGETS.COUNT) + math.random(-30, 30)
        local distance = math.random(50, Config.TARGETS.SPAWN_RADIUS)

        local x = math.cos(math.rad(angle)) * distance
        local z = math.sin(math.rad(angle)) * distance
        local position = Vector3.new(x, Config.TARGETS.HEIGHT, z)

        TargetService.createTarget(position)
    end

    -- 启动重生检查循环
    spawn(function()
        while true do
            wait(1)

            for targetId, target in pairs(targets) do
                if not target.alive and target.respawnTime > 0 and tick() >= target.respawnTime then
                    TargetService.respawnTarget(targetId)
                end
            end
        end
    end)

    print("✅ 靶子系统初始化完成，共创建", Config.TARGETS.COUNT, "个靶子")
end

-- 清理靶子系统
function TargetService.cleanup()
    -- 清理所有靶子
    for targetId, target in pairs(targets) do
        if target.model then
            target.model:Destroy()
        elseif target.part then
            target.part:Destroy()
        end
    end

    targets = {}
    targetConnections = {}

    print("🧹 靶子系统已清理")
end

-- 处理客户端请求靶子状态
Events.Target.RequestTargetStatus.OnServerEvent:Connect(function(player)
    local activeTargets = TargetService.getActiveTargets()
    Events.Target.TargetStatusUpdate:FireClient(player, activeTargets)
end)

return TargetService
