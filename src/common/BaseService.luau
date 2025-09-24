-- 基础服务类
-- 提供通用的服务功能和接口

local BaseService = {}
BaseService.__index = BaseService

-- 创建新的服务实例
function BaseService.new(serviceName)
    local self = setmetatable({}, BaseService)
    self.name = serviceName or "UnknownService"
    self.isInitialized = false
    self.events = {}
    self.connections = {}
    return self
end

-- 初始化服务
function BaseService:initialize()
    if self.isInitialized then
        warn("⚠️ [" .. self.name .. "] 服务已经初始化过了")
        return false
    end

    print("🚀 [" .. self.name .. "] 服务开始初始化...")

    -- 子类可以重写此方法
    if self.onInitialize then
        local success, error = pcall(self.onInitialize, self)
        if not success then
            warn("❌ [" .. self.name .. "] 初始化失败:", error)
            return false
        end
    end

    self.isInitialized = true
    print("✅ [" .. self.name .. "] 服务初始化完成")
    return true
end

-- 销毁服务
function BaseService:destroy()
    if not self.isInitialized then
        return
    end

    print("🧹 [" .. self.name .. "] 服务开始销毁...")

    -- 断开所有连接
    for _, connection in pairs(self.connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    self.connections = {}

    -- 清理事件
    for _, event in pairs(self.events) do
        if event and event.Destroy then
            event:Destroy()
        end
    end
    self.events = {}

    -- 子类可以重写此方法
    if self.onDestroy then
        pcall(self.onDestroy, self)
    end

    self.isInitialized = false
    print("✅ [" .. self.name .. "] 服务销毁完成")
end

-- 检查服务是否已初始化
function BaseService:isReady()
    return self.isInitialized
end

-- 获取服务名称
function BaseService:getName()
    return self.name
end

-- 添加连接（自动管理生命周期）
function BaseService:addConnection(connection)
    if connection and connection.Disconnect then
        table.insert(self.connections, connection)
        return connection
    end
    warn("⚠️ [" .. self.name .. "] 尝试添加无效的连接")
    return nil
end

-- 创建并添加事件
function BaseService:createEvent(eventName)
    local event = Instance.new("BindableEvent")
    self.events[eventName] = event
    return event
end

-- 获取事件
function BaseService:getEvent(eventName)
    return self.events[eventName]
end

-- 触发事件
function BaseService:fireEvent(eventName, ...)
    local event = self.events[eventName]
    if event then
        event:Fire(...)
    else
        warn("⚠️ [" .. self.name .. "] 尝试触发不存在的事件:", eventName)
    end
end

-- 监听事件
function BaseService:connectEvent(eventName, callback)
    local event = self.events[eventName]
    if event then
        local connection = event.Event:Connect(callback)
        self:addConnection(connection)
        return connection
    else
        warn("⚠️ [" .. self.name .. "] 尝试监听不存在的事件:", eventName)
        return nil
    end
end

-- 记录日志（可以被重写）
function BaseService:log(level, message, ...)
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s] [%s] %s: %s", timestamp, level, self.name, message)

    if select("#", ...) > 0 then
        logMessage = logMessage .. " | " .. table.concat({...}, ", ")
    end

    if level == "ERROR" then
        warn(logMessage)
    else
        print(logMessage)
    end
end

-- 便捷的日志方法
function BaseService:logInfo(message, ...)
    self:log("INFO", message, ...)
end

function BaseService:logWarn(message, ...)
    self:log("WARN", message, ...)
end

function BaseService:logError(message, ...)
    self:log("ERROR", message, ...)
end

return BaseService
