-- 数据序列化工具
-- 用于处理循环引用和数据传输优化

local DataSerializer = {}

-- 深度拷贝对象，避免循环引用
function DataSerializer.deepCopy(original, visited)
    visited = visited or {}

    -- 检查是否已经访问过这个对象（避免循环引用）
    if visited[original] then
        return visited[original]
    end

    local copy
    if type(original) == "table" then
        copy = {}
        visited[original] = copy  -- 先标记，防止循环引用

        for key, value in pairs(original) do
            copy[DataSerializer.deepCopy(key, visited)] = DataSerializer.deepCopy(value, visited)
        end

        -- 复制元表
        local metatable = getmetatable(original)
        if metatable then
            setmetatable(copy, DataSerializer.deepCopy(metatable, visited))
        end
    else
        copy = original
    end

    return copy
end

-- 清理数据中的循环引用
function DataSerializer.sanitizeData(data, maxDepth)
    maxDepth = maxDepth or 10
    local visited = {}

    local function sanitize(obj, depth)
        if depth > maxDepth then
            return "[MAX_DEPTH_EXCEEDED]"
        end

        if type(obj) ~= "table" then
            return obj
        end

        -- 检查循环引用
        for _, visitedObj in pairs(visited) do
            if visitedObj == obj then
                return "[CIRCULAR_REFERENCE]"
            end
        end

        table.insert(visited, obj)

        local sanitized = {}
        for key, value in pairs(obj) do
            sanitized[key] = sanitize(value, depth + 1)
        end

        table.remove(visited)  -- 移除当前对象
        return sanitized
    end

    return sanitize(data, 0)
end

-- 序列化为JSON安全格式
function DataSerializer.toJSONSafe(data)
    local HttpService = game:GetService("HttpService")

    -- 先清理循环引用
    local sanitized = DataSerializer.sanitizeData(data)

    -- 移除不能序列化的类型
    local function cleanForJSON(obj)
        if type(obj) ~= "table" then
            -- 检查是否是Roblox实例
            if typeof(obj) == "Instance" then
                return {
                    __type = "Instance",
                    __className = obj.ClassName,
                    __name = obj.Name
                }
            elseif typeof(obj) == "Vector3" then
                return {
                    __type = "Vector3",
                    x = obj.X,
                    y = obj.Y,
                    z = obj.Z
                }
            elseif typeof(obj) == "Color3" then
                return {
                    __type = "Color3",
                    r = obj.R,
                    g = obj.G,
                    b = obj.B
                }
            elseif type(obj) == "function" then
                return "[FUNCTION]"
            elseif type(obj) == "userdata" then
                return "[USERDATA]"
            end
            return obj
        end

        local cleaned = {}
        for key, value in pairs(obj) do
            if type(key) == "string" or type(key) == "number" then
                cleaned[key] = cleanForJSON(value)
            end
        end
        return cleaned
    end

    local cleaned = cleanForJSON(sanitized)

    local success, result = pcall(function()
        return HttpService:JSONEncode(cleaned)
    end)

    if success then
        return result
    else
        warn("❌ [DataSerializer] JSON序列化失败:", result)
        return nil
    end
end

-- 从JSON安全格式反序列化
function DataSerializer.fromJSONSafe(jsonString)
    local HttpService = game:GetService("HttpService")

    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)

    if not success then
        warn("❌ [DataSerializer] JSON反序列化失败:", data)
        return nil
    end

    -- 还原特殊类型
    local function restoreTypes(obj)
        if type(obj) ~= "table" then
            return obj
        end

        if obj.__type then
            if obj.__type == "Vector3" then
                return Vector3.new(obj.x, obj.y, obj.z)
            elseif obj.__type == "Color3" then
                return Color3.new(obj.r, obj.g, obj.b)
            elseif obj.__type == "Instance" then
                -- 实例不能完全还原，返回描述信息
                return {
                    type = "Instance",
                    className = obj.__className,
                    name = obj.__name
                }
            end
        end

        local restored = {}
        for key, value in pairs(obj) do
            restored[key] = restoreTypes(value)
        end
        return restored
    end

    return restoreTypes(data)
end

-- 移除敏感数据字段
function DataSerializer.removeSensitiveData(data, sensitiveFields)
    sensitiveFields = sensitiveFields or {
        "password", "token", "secret", "key", "auth",
        "userId", "ip", "email", "phone"
    }

    local function removeSensitive(obj)
        if type(obj) ~= "table" then
            return obj
        end

        local cleaned = {}
        for key, value in pairs(obj) do
            local keyStr = tostring(key):lower()
            local isSensitive = false

            for _, sensitive in pairs(sensitiveFields) do
                if keyStr:find(sensitive:lower()) then
                    isSensitive = true
                    break
                end
            end

            if isSensitive then
                cleaned[key] = "[REDACTED]"
            else
                cleaned[key] = removeSensitive(value)
            end
        end
        return cleaned
    end

    return removeSensitive(data)
end

-- 压缩数据（移除空值和不必要的字段）
function DataSerializer.compressData(data)
    local function compress(obj)
        if type(obj) ~= "table" then
            return obj
        end

        local compressed = {}
        for key, value in pairs(obj) do
            local compressedValue = compress(value)

            -- 跳过空值、空表和nil
            if compressedValue ~= nil and
               compressedValue ~= "" and
               not (type(compressedValue) == "table" and next(compressedValue) == nil) then
                compressed[key] = compressedValue
            end
        end
        return compressed
    end

    return compress(data)
end

-- 验证数据结构
function DataSerializer.validateStructure(data, schema)
    if not schema then
        return true, "无模式验证"
    end

    local function validate(obj, schemaObj, path)
        path = path or "root"

        if type(schemaObj) == "string" then
            -- 简单类型检查
            if type(obj) ~= schemaObj then
                return false, string.format("路径 %s: 期望类型 %s, 实际类型 %s", path, schemaObj, type(obj))
            end
            return true
        end

        if type(schemaObj) == "table" then
            if type(obj) ~= "table" then
                return false, string.format("路径 %s: 期望表类型, 实际类型 %s", path, type(obj))
            end

            for key, expectedType in pairs(schemaObj) do
                local newPath = path .. "." .. tostring(key)
                if obj[key] == nil then
                    return false, string.format("路径 %s: 缺少必需字段", newPath)
                end

                local success, error = validate(obj[key], expectedType, newPath)
                if not success then
                    return false, error
                end
            end
        end

        return true
    end

    return validate(data, schema)
end

-- 获取数据大小估计（字节）
function DataSerializer.getDataSize(data)
    local function getSize(obj, visited)
        visited = visited or {}

        if visited[obj] then
            return 0  -- 避免循环引用
        end

        if type(obj) == "table" then
            visited[obj] = true
            local size = 0
            for key, value in pairs(obj) do
                size = size + getSize(key, visited) + getSize(value, visited)
            end
            return size
        elseif type(obj) == "string" then
            return #obj
        elseif type(obj) == "number" then
            return 8  -- 双精度浮点数
        elseif type(obj) == "boolean" then
            return 1
        else
            return 0
        end
    end

    return getSize(data)
end

return DataSerializer
