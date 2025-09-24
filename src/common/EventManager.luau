-- 事件管理器
-- 提供统一的事件管理和通信机制

local EventManager = {}

-- 内部事件存储
local events = {}
local globalConnections = {}

-- 创建一个新的事件
function EventManager.createEvent(eventName)
    if events[eventName] then
        warn("⚠️ [EventManager] 事件已存在:", eventName)
        return events[eventName]
    end

    local bindableEvent = Instance.new("BindableEvent")
    events[eventName] = bindableEvent

    print("✅ [EventManager] 创建事件:", eventName)
    return bindableEvent
end

-- 获取事件
function EventManager.getEvent(eventName)
    return events[eventName]
end

-- 触发事件
function EventManager.fireEvent(eventName, ...)
    local event = events[eventName]
    if event then
        event:Fire(...)
        print("📡 [EventManager] 触发事件:", eventName)
    else
        warn("❌ [EventManager] 事件不存在:", eventName)
    end
end

-- 监听事件
function EventManager.connectEvent(eventName, callback)
    local event = events[eventName]
    if not event then
        warn("❌ [EventManager] 事件不存在:", eventName)
        return nil
    end

    local connection = event.Event:Connect(callback)

    -- 添加到全局连接管理
    if not globalConnections[eventName] then
        globalConnections[eventName] = {}
    end
    table.insert(globalConnections[eventName], connection)

    print("🔗 [EventManager] 连接事件:", eventName)
    return connection
end

-- 断开特定事件的所有连接
function EventManager.disconnectEvent(eventName)
    local connections = globalConnections[eventName]
    if connections then
        for _, connection in pairs(connections) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
        globalConnections[eventName] = {}
        print("🔌 [EventManager] 断开事件连接:", eventName)
    end
end

-- 断开所有连接
function EventManager.disconnectAll()
    for eventName, connections in pairs(globalConnections) do
        for _, connection in pairs(connections) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
    end
    globalConnections = {}
    print("🔌 [EventManager] 断开所有事件连接")
end

-- 销毁事件
function EventManager.destroyEvent(eventName)
    local event = events[eventName]
    if event then
        -- 先断开所有连接
        EventManager.disconnectEvent(eventName)

        -- 销毁事件对象
        event:Destroy()
        events[eventName] = nil

        print("🗑️ [EventManager] 销毁事件:", eventName)
    end
end

-- 销毁所有事件
function EventManager.destroyAll()
    EventManager.disconnectAll()

    for eventName, event in pairs(events) do
        if event and event.Destroy then
            event:Destroy()
        end
    end

    events = {}
    print("🗑️ [EventManager] 销毁所有事件")
end

-- 获取事件统计信息
function EventManager.getStats()
    local totalEvents = 0
    local totalConnections = 0

    for eventName, _ in pairs(events) do
        totalEvents = totalEvents + 1
        local connections = globalConnections[eventName]
        if connections then
            totalConnections = totalConnections + #connections
        end
    end

    return {
        totalEvents = totalEvents,
        totalConnections = totalConnections,
        eventNames = {}
    }
end

-- 列出所有事件
function EventManager.listEvents()
    local eventList = {}
    for eventName, _ in pairs(events) do
        local connectionCount = 0
        if globalConnections[eventName] then
            connectionCount = #globalConnections[eventName]
        end

        table.insert(eventList, {
            name = eventName,
            connections = connectionCount
        })
    end

    return eventList
end

-- 检查事件是否存在
function EventManager.hasEvent(eventName)
    return events[eventName] ~= nil
end

-- 一次性监听事件（只触发一次后自动断开）
function EventManager.connectOnce(eventName, callback)
    local connection
    connection = EventManager.connectEvent(eventName, function(...)
        callback(...)
        if connection then
            connection:Disconnect()

            -- 从全局连接中移除
            local connections = globalConnections[eventName]
            if connections then
                for i, conn in ipairs(connections) do
                    if conn == connection then
                        table.remove(connections, i)
                        break
                    end
                end
            end
        end
    end)

    return connection
end

-- 延迟触发事件
function EventManager.fireEventDelayed(eventName, delay, ...)
    local args = {...}
    spawn(function()
        wait(delay)
        EventManager.fireEvent(eventName, unpack(args))
    end)
end

-- 条件触发事件（只有当条件满足时才触发）
function EventManager.fireEventIf(eventName, condition, ...)
    if condition then
        EventManager.fireEvent(eventName, ...)
        return true
    end
    return false
end

return EventManager
