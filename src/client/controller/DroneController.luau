-- 无人机控制器
-- 整合无人机相关的远程通信和状态管理功能

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DroneController = {}

-- 等待模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))

-- 使用统一的配置
local DroneConfig = Config.DRONE_CONFIG

-- 缓存远程事件
local RemoteEvents = {}

-- 无人机状态管理
local droneStatus = {
    isActive = false,
    mode = DroneConfig.MODES.FOLLOW,
    timeRemaining = 0
}

-- 内部事件系统
local internalEvents = {
    DroneSpawned = Instance.new("BindableEvent"),
    DroneRecalled = Instance.new("BindableEvent"),
    DroneModeChanged = Instance.new("BindableEvent"),
    DroneDestroyed = Instance.new("BindableEvent"),
    DroneAttack = Instance.new("BindableEvent"),
    DroneStatusChanged = Instance.new("BindableEvent")
}

-- 导出事件
DroneController.Events = {}
for eventName, event in pairs(internalEvents) do
    DroneController.Events[eventName] = event.Event
end

-- 初始化远程事件
local function initializeEvents()
    if Events and Events.Drone then
        RemoteEvents = {
            SpawnDrone = Events.Drone.SpawnDrone,
            RecallDrone = Events.Drone.RecallDrone,
            SwitchDroneMode = Events.Drone.SwitchDroneMode
        }
        print("✅ [DroneController] 无人机远程事件初始化成功")
    else
        warn("❌ [DroneController] 无人机远程事件初始化失败")
    end
end

-- ==============================================
-- 状态管理
-- ==============================================

-- 获取无人机状态
function DroneController.getDroneStatus()
    return {
        isActive = droneStatus.isActive,
        mode = droneStatus.mode,
        timeRemaining = droneStatus.timeRemaining
    }
end

-- 设置无人机状态
function DroneController.setDroneStatus(newStatus)
    local oldStatus = {
        isActive = droneStatus.isActive,
        mode = droneStatus.mode,
        timeRemaining = droneStatus.timeRemaining
    }

    if newStatus.isActive ~= nil then
        droneStatus.isActive = newStatus.isActive
    end

    if newStatus.mode ~= nil then
        droneStatus.mode = newStatus.mode
    end

    if newStatus.timeRemaining ~= nil then
        droneStatus.timeRemaining = newStatus.timeRemaining
    end

    internalEvents.DroneStatusChanged:Fire(droneStatus, oldStatus)
    print("🤖 [DroneController] 无人机状态已更新:", droneStatus.isActive and "激活" or "待命", "模式:", droneStatus.mode)
end

-- 检查无人机是否激活
function DroneController.isDroneActive()
    return droneStatus.isActive
end

-- 获取无人机模式
function DroneController.getDroneMode()
    return droneStatus.mode
end

-- 获取剩余时间
function DroneController.getTimeRemaining()
    return droneStatus.timeRemaining
end

-- ==============================================
-- 远程通信功能
-- ==============================================

-- 召唤无人机
function DroneController.spawnDrone()
    initializeEvents()
    if RemoteEvents.SpawnDrone and not droneStatus.isActive then
        RemoteEvents.SpawnDrone:FireServer()
        print("🤖 [DroneController] 发送召唤无人机请求")
        return true
    else
        warn("⚠️ [DroneController] 无人机已激活或远程事件不可用")
        return false
    end
end

-- 收回无人机
function DroneController.recallDrone()
    initializeEvents()
    if RemoteEvents.RecallDrone and droneStatus.isActive then
        RemoteEvents.RecallDrone:FireServer()
        print("🤖 [DroneController] 发送收回无人机请求")
        return true
    else
        warn("⚠️ [DroneController] 无人机未激活或远程事件不可用")
        return false
    end
end

-- 切换无人机模式
function DroneController.switchDroneMode(newMode)
    initializeEvents()
    if RemoteEvents.SwitchDroneMode and droneStatus.isActive then
        local targetMode = newMode or (droneStatus.mode == DroneConfig.MODES.FOLLOW and DroneConfig.MODES.GUARD or DroneConfig.MODES.FOLLOW)
        RemoteEvents.SwitchDroneMode:FireServer(targetMode)
        print("🤖 [DroneController] 发送切换模式请求:", targetMode)
        return true
    else
        warn("⚠️ [DroneController] 无人机未激活或远程事件不可用")
        return false
    end
end

-- ==============================================
-- 事件监听和处理
-- ==============================================

local eventConnections = {}
local timerConnection = nil

-- 服务端事件处理函数
local function handleDroneSpawned(success)
    if success then
        DroneController.setDroneStatus({
            isActive = true,
            mode = DroneConfig.MODES.FOLLOW,
            timeRemaining = DroneConfig.LIFETIME
        })
        print("✅ [DroneController] 无人机已召唤")
    else
        print("❌ [DroneController] 无人机召唤失败")
    end
    internalEvents.DroneSpawned:Fire(success)
end

local function handleDroneRecalled(success)
    if success then
        DroneController.setDroneStatus({
            isActive = false,
            timeRemaining = 0
        })
        print("✅ [DroneController] 无人机已收回")
    end
    internalEvents.DroneRecalled:Fire(success)
end

local function handleDroneModeChanged(newMode, oldMode)
    DroneController.setDroneStatus({
        mode = newMode
    })
    print("🔄 [DroneController] 无人机模式已从", oldMode, "切换到", newMode)
    internalEvents.DroneModeChanged:Fire(newMode, oldMode)
end

local function handleDroneDestroyed(reason)
    DroneController.setDroneStatus({
        isActive = false,
        timeRemaining = 0
    })
    print("💥 [DroneController] 无人机已销毁，原因:", reason)
    internalEvents.DroneDestroyed:Fire(reason)
end

local function handleDroneAttack(targetName)
    print("⚔️ [DroneController] 无人机攻击了目标:", targetName)
    internalEvents.DroneAttack:Fire(targetName)
end

-- 启动计时器
local function startTimer()
    if timerConnection then
        timerConnection:Disconnect()
    end

    local lastUpdateTime = 0
    timerConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        if droneStatus.isActive and droneStatus.timeRemaining > 0 then
            droneStatus.timeRemaining = droneStatus.timeRemaining - deltaTime
            lastUpdateTime = lastUpdateTime + deltaTime

            -- 每0.1秒更新一次UI显示（平衡性能和流畅度）
            if lastUpdateTime >= 0.1 then
                lastUpdateTime = 0
                internalEvents.DroneStatusChanged:Fire(droneStatus, {
                    isActive = droneStatus.isActive,
                    mode = droneStatus.mode,
                    timeRemaining = droneStatus.timeRemaining + deltaTime
                })
            end

            if droneStatus.timeRemaining <= 0 then
                -- 时间到，重置状态
                DroneController.setDroneStatus({
                    isActive = false,
                    timeRemaining = 0
                })
                print("⏰ [DroneController] 无人机时间到期，自动销毁")
            end
        end
    end)
end

-- 初始化事件监听器
function DroneController.initializeEventListeners()
    initializeEvents()

    -- 连接服务端事件
    if Events and Events.Drone then
        eventConnections.droneSpawned = Events.Drone.DroneSpawned.OnClientEvent:Connect(handleDroneSpawned)
        eventConnections.droneRecalled = Events.Drone.DroneRecalled.OnClientEvent:Connect(handleDroneRecalled)
        eventConnections.droneModeChanged = Events.Drone.DroneModeChanged.OnClientEvent:Connect(handleDroneModeChanged)
        eventConnections.droneDestroyed = Events.Drone.DroneDestroyed.OnClientEvent:Connect(handleDroneDestroyed)
        eventConnections.droneAttack = Events.Drone.DroneAttack.OnClientEvent:Connect(handleDroneAttack)

        print("✅ [DroneController] 服务端事件监听器初始化完成")
    else
        warn("❌ [DroneController] 无法连接服务端事件")
    end

    -- 启动计时器
    startTimer()

    print("✅ [DroneController] 事件监听器初始化完成")
end

-- ==============================================
-- 高级控制功能
-- ==============================================

-- 处理无人机操作
function DroneController.handleDroneAction(action, data)
    if action == "spawn" then
        return DroneController.spawnDrone()

    elseif action == "recall" then
        return DroneController.recallDrone()

    elseif action == "switch_mode" then
        local newMode = data and data.mode or nil
        return DroneController.switchDroneMode(newMode)

    else
        warn("❌ [DroneController] 未知无人机操作:", action)
        return false
    end
end

-- 获取无人机能力描述
function DroneController.getDroneCapabilities()
    return {
        modes = {
            follow = DroneConfig.MODES.FOLLOW,
            guard = DroneConfig.MODES.GUARD
        },
        lifetime = DroneConfig.LIFETIME,
        features = {
            "自动跟随玩家",
            "定点驻守",
            "攻击敌对目标",
            "自动销毁超时"
        }
    }
end

-- 格式化剩余时间
function DroneController.getFormattedTimeRemaining()
    if not droneStatus.isActive or droneStatus.timeRemaining <= 0 then
        return "未激活"
    end

    local minutes = math.floor(droneStatus.timeRemaining / 60)
    local seconds = math.floor(droneStatus.timeRemaining % 60)

    if minutes > 0 then
        return string.format("%d:%02d", minutes, seconds)
    else
        return string.format("%.1f秒", droneStatus.timeRemaining)
    end
end

-- 获取无人机模式描述
function DroneController.getModeDescription()
    if droneStatus.mode == DroneConfig.MODES.FOLLOW then
        return "跟随模式"
    elseif droneStatus.mode == DroneConfig.MODES.GUARD then
        return "驻守模式"
    else
        return "未知模式"
    end
end

-- ==============================================
-- 初始化和清理
-- ==============================================

-- 初始化无人机控制器
function DroneController.initialize()
    print("🚀 [DroneController] 开始初始化...")

    -- 初始化事件监听
    DroneController.initializeEventListeners()

    -- 重置无人机状态
    DroneController.setDroneStatus({
        isActive = false,
        mode = DroneConfig.MODES.FOLLOW,
        timeRemaining = 0
    })

    print("✅ [DroneController] 初始化完成")
end

-- 清理资源
function DroneController.cleanup()
    -- 断开所有事件连接
    for _, connection in pairs(eventConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    eventConnections = {}

    -- 停止计时器
    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end

    -- 重置状态
    droneStatus.isActive = false
    droneStatus.timeRemaining = 0

    print("🧹 [DroneController] 资源已清理")
end

return DroneController
