-- 靶子系统控制器
-- 管理靶子系统的客户端逻辑和服务端通信

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TargetController = {}

-- 等待模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))

-- 使用统一的配置
local TargetConfig = Config.TARGETS

-- 靶子状态管理
local targetStatus = {}

-- 内部事件系统
local internalEvents = {
    TargetCreated = Instance.new("BindableEvent"),
    TargetDestroyed = Instance.new("BindableEvent"),
    TargetDamaged = Instance.new("BindableEvent"),
    TargetRespawned = Instance.new("BindableEvent"),
    TargetStatusChanged = Instance.new("BindableEvent")
}

-- 导出事件
TargetController.Events = {}
for eventName, event in pairs(internalEvents) do
    TargetController.Events[eventName] = event.Event
end

-- ==============================================
-- 状态管理
-- ==============================================

-- 获取靶子状态
function TargetController.getTargetStatus(targetId)
    return targetStatus[targetId]
end

-- 获取所有靶子状态
function TargetController.getAllTargetStatus()
    return targetStatus
end

-- 设置靶子状态
function TargetController.setTargetStatus(targetId, newStatus)
    local oldStatus = targetStatus[targetId]
    targetStatus[targetId] = newStatus

    internalEvents.TargetStatusChanged:Fire(targetId, newStatus, oldStatus)
    print("🎯 [TargetController] 靶子状态已更新:", targetId, newStatus.health and ("血量: " .. newStatus.health .. "/" .. newStatus.maxHealth) or "")
end

-- 更新靶子血量
function TargetController.updateTargetHealth(targetId, health, maxHealth)
    if targetStatus[targetId] then
        targetStatus[targetId].health = health
        targetStatus[targetId].maxHealth = maxHealth

        internalEvents.TargetStatusChanged:Fire(targetId, targetStatus[targetId], targetStatus[targetId])
        print("🩸 [TargetController] 靶子血量更新:", targetId, health .. "/" .. maxHealth)
    end
end

-- 检查靶子是否存活
function TargetController.isTargetAlive(targetId)
    local status = targetStatus[targetId]
    return status and status.alive == true
end

-- 获取靶子数量
function TargetController.getTargetCount()
    local count = 0
    for _ in pairs(targetStatus) do
        count = count + 1
    end
    return count
end

-- 获取活跃靶子数量
function TargetController.getActiveTargetCount()
    local count = 0
    for _, status in pairs(targetStatus) do
        if status.alive then
            count = count + 1
        end
    end
    return count
end

-- ==============================================
-- 远程通信功能
-- ==============================================

-- 请求靶子状态更新
function TargetController.requestTargetStatus()
    if Events.Target.RequestTargetStatus then
        Events.Target.RequestTargetStatus:FireServer()
        print("🔄 [TargetController] 请求靶子状态更新")
        return true
    else
        warn("⚠️ [TargetController] 靶子状态请求事件不可用")
        return false
    end
end

-- ==============================================
-- 事件监听和处理
-- ==============================================

local eventConnections = {}

-- 服务端事件处理函数
local function handleTargetCreated(targetId, targetData)
    -- 更新本地状态
    TargetController.setTargetStatus(targetId, {
        id = targetId,
        position = targetData.position,
        height = targetData.height,
        health = targetData.health,
        maxHealth = targetData.maxHealth,
        alive = true
    })

    print("✅ [TargetController] 靶子已创建:", targetId)
    internalEvents.TargetCreated:Fire(targetId, targetData)
end

local function handleTargetDestroyed(targetId, destroyerId)
    -- 更新本地状态
    if targetStatus[targetId] then
        targetStatus[targetId].alive = false
        targetStatus[targetId].health = 0

        print("💥 [TargetController] 靶子已摧毁:", targetId, "摧毁者:", destroyerId or "未知")
        internalEvents.TargetDestroyed:Fire(targetId, destroyerId)
        internalEvents.TargetStatusChanged:Fire(targetId, targetStatus[targetId], targetStatus[targetId])
    end
end

local function handleTargetDamaged(targetId, health, maxHealth, attackerId)
    -- 更新本地状态
    TargetController.updateTargetHealth(targetId, health, maxHealth)

    print("⚔️ [TargetController] 靶子受到伤害:", targetId, "血量:", health .. "/" .. maxHealth, "攻击者:", attackerId or "未知")
    internalEvents.TargetDamaged:Fire(targetId, health, maxHealth, attackerId)
end

local function handleTargetRespawned(targetId, targetData)
    -- 更新本地状态
    TargetController.setTargetStatus(targetId, {
        id = targetId,
        position = targetData.position,
        height = targetData.height,
        health = targetData.health,
        maxHealth = targetData.maxHealth,
        alive = true
    })

    print("🔄 [TargetController] 靶子已重生:", targetId)
    internalEvents.TargetRespawned:Fire(targetId, targetData)
end

local function handleTargetStatusUpdate(activeTargets)
    -- 更新所有靶子状态
    targetStatus = {}
    for targetId, targetData in pairs(activeTargets) do
        targetStatus[targetId] = {
            id = targetId,
            position = targetData.position,
            height = targetData.height,
            health = targetData.health,
            maxHealth = targetData.maxHealth,
            alive = true
        }
    end

    local activeCount = 0
    for _ in pairs(activeTargets) do
        activeCount = activeCount + 1
    end

    print("📊 [TargetController] 靶子状态已同步，活跃靶子数量:", activeCount)
    internalEvents.TargetStatusChanged:Fire("all", targetStatus, {})
end

-- 初始化事件监听器
function TargetController.initializeEventListeners()
    -- 连接服务端事件
    if Events and Events.Target then
        eventConnections.targetCreated = Events.Target.TargetCreated.OnClientEvent:Connect(handleTargetCreated)
        eventConnections.targetDestroyed = Events.Target.TargetDestroyed.OnClientEvent:Connect(handleTargetDestroyed)
        eventConnections.targetDamaged = Events.Target.TargetDamaged.OnClientEvent:Connect(handleTargetDamaged)
        eventConnections.targetRespawned = Events.Target.TargetRespawned.OnClientEvent:Connect(handleTargetRespawned)
        eventConnections.targetStatusUpdate = Events.Target.TargetStatusUpdate.OnClientEvent:Connect(handleTargetStatusUpdate)

        print("✅ [TargetController] 服务端事件监听器初始化完成")
    else
        warn("❌ [TargetController] 无法连接服务端事件")
    end

    print("✅ [TargetController] 事件监听器初始化完成")
end

-- ==============================================
-- 高级功能
-- ==============================================

-- 获取靶子能力描述
function TargetController.getTargetCapabilities()
    return {
        count = TargetConfig.COUNT,
        maxHealth = TargetConfig.MAX_HEALTH,
        respawnTime = TargetConfig.RESPAWN_TIME,
        features = {
            "动态生成位置",
            "血量系统",
            "自动重生",
            "实时状态同步"
        }
    }
end

-- 获取靶子统计信息
function TargetController.getTargetStats()
    local stats = {
        totalTargets = 0,
        aliveTargets = 0,
        destroyedTargets = 0,
        totalHealth = 0,
        maxTotalHealth = 0
    }

    for _, status in pairs(targetStatus) do
        stats.totalTargets = stats.totalTargets + 1
        if status.alive then
            stats.aliveTargets = stats.aliveTargets + 1
            stats.totalHealth = stats.totalHealth + status.health
        else
            stats.destroyedTargets = stats.destroyedTargets + 1
        end
        stats.maxTotalHealth = stats.maxTotalHealth + status.maxHealth
    end

    return stats
end

-- 格式化靶子状态信息
function TargetController.getFormattedTargetInfo(targetId)
    local status = targetStatus[targetId]
    if not status then
        return "靶子不存在"
    end

    local healthPercent = status.health / status.maxHealth * 100
    local statusText = status.alive and "存活" or "已摧毁"

    return string.format("靶子 %s: %s (血量: %.1f%%)", targetId, statusText, healthPercent)
end

-- ==============================================
-- 初始化和清理
-- ==============================================

-- 初始化靶子控制器
function TargetController.initialize()
    print("🚀 [TargetController] 开始初始化...")

    -- 初始化事件监听
    TargetController.initializeEventListeners()

    -- 请求初始靶子状态
    wait(0.5) -- 等待服务端准备就绪
    TargetController.requestTargetStatus()

    print("✅ [TargetController] 初始化完成")
end

-- 清理资源
function TargetController.cleanup()
    -- 断开所有事件连接
    for _, connection in pairs(eventConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    eventConnections = {}

    -- 重置状态
    targetStatus = {}

    print("🧹 [TargetController] 资源已清理")
end

return TargetController
