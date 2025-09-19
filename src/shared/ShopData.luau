-- 商店系统共享数据结构 - 重构为API调用版本

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopData = {}

-- 等待配置模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

-- 物品数据结构
export type Item = {
    id: string,
    name: string,
    price: number,
    maxQuantity: number?, -- nil表示无限
    currentStock: number?, -- 当前库存
    description: string?,
    icon: string?,
    imageId: string?, -- 商品图片ID
    category: string?, -- 商品分类
    sellPrice: number? -- 卖出价格，如果nil则自动计算为原价*sell_rate（从系统配置获取）
}

-- 玩家物品数据结构
export type PlayerItem = {
    itemId: string,
    quantity: number
}

-- 玩家数据
export type PlayerData = {
    id: string,
    username: string,
    displayName: string?,
    coins: number,
    items: {[string]: number}, -- itemId -> quantity
    totalEarned: number?,
    totalSpent: number?,
    createdAt: string?,
    lastLogin: string?
}

-- HTTP请求工具
local function makeRequest(method: string, endpoint: string, data: any?, token: string?)
    -- 检查HTTP服务是否可用
    if not HttpService.HttpEnabled then
        warn("❌ HTTP服务未启用，无法连接到API服务器")
        warn("💡 解决方案：在Roblox Studio中启用HTTP请求")
        return false, nil
    end
    local url = Config.getApiUrl(endpoint)
    local headers = {}
    for key, value in pairs(Config.API.DEFAULT_HEADERS) do
        headers[key] = value
    end

    if token then
        headers["Authorization"] = "Bearer " .. token
    end

    local requestData = {
        Url = url,
        Method = method,
        Headers = headers
    }

    if data and (method == "POST" or method == "PUT") then
        requestData.Body = HttpService:JSONEncode(data)
    end

    local success, response = pcall(function()
        return HttpService:RequestAsync(requestData)
    end)

    if success then
        if response.Success then
            local responseData = response.Body and HttpService:JSONDecode(response.Body) or {}
            return responseData.success ~= false, responseData
        else
            warn("API请求失败 [HTTP " .. (response.StatusCode or "Unknown") .. "]: " .. (response.StatusMessage or "Unknown error"))
            warn("响应内容: " .. tostring(response.Body or "无响应内容"))

            -- 尝试解析错误响应中的错误信息
            local errorInfo = nil
            if response.Body then
                local success_parse, errorData = pcall(function()
                    return HttpService:JSONDecode(response.Body)
                end)
                if success_parse and errorData and errorData.error then
                    errorInfo = {
                        error = errorData.error,
                        statusCode = response.StatusCode
                    }
                end
            end

            return false, errorInfo
        end
    else
        -- 捕获网络连接错误
        local errorMsg = tostring(response)
        warn("网络请求异常: " .. errorMsg)

        -- 检查是否是HTTP服务未启用的错误
        if string.find(errorMsg, "HttpService") then
            warn("⚠️ 可能原因：HTTP服务未在游戏设置中启用")
            warn("解决方案：在Roblox Studio中启用HTTP请求或检查游戏的HTTP服务设置")
        elseif string.find(errorMsg, "restricted") then
            warn("⚠️ 可能原因：HTTP请求被Roblox安全策略阻止")
            warn("解决方案：检查API服务器地址是否在Roblox允许的域名列表中")
        elseif string.find(errorMsg, "not allowed") then
            warn("⚠️ 可能原因：使用了Roblox不允许的HTTP请求头")
            warn("解决方案：检查请求头配置，移除User-Agent等受限制的请求头")
        end

        return false, nil
    end
end

-- 用户认证
local userTokens = {} -- 存储用户的JWT token

function ShopData.authenticateUser(userId: string, username: string, displayName: string?)
    local success, response = makeRequest("POST", "/auth/login", {
        userId = userId,
        username = username,
        displayName = displayName
    })

    if success and response and response.data then
        userTokens[userId] = response.data.token
        return true, response.data.user
    end

    return false, nil
end

function ShopData.getUserToken(userId: string): string?
    return userTokens[userId]
end

-- API调用函数

-- 获取所有商店物品
function ShopData.getShopItems(): {[string]: Item}?
    local success, response = makeRequest("GET", "/items")
    if success and response and response.data then
        local items = {}
        for _, item in ipairs(response.data.items) do
            items[item.id] = item
        end
        return items
    end
    return nil
end

-- 获取特定物品
function ShopData.getItem(itemId: string): Item?
    local success, response = makeRequest("GET", "/items/" .. itemId)
    if success and response and response.data then
        return response.data.item
    end
    return nil
end

-- 获取用户数据
function ShopData.getUserData(userId: string): PlayerData?
    local token = userTokens[userId]
    if not token then return nil end

    local success, response = makeRequest("GET", "/users/me", nil, token)
    if success and response and response.data then
        return response.data
    end
    return nil
end

-- 获取用户库存
function ShopData.getUserInventory(userId: string): {[string]: number}?
    local token = userTokens[userId]
    if not token then return nil end

    local success, response = makeRequest("GET", "/users/inventory", nil, token)
    if success and response and response.data then
        local inventory = {}
        for _, item in ipairs(response.data.inventory) do
            inventory[item.item_id] = item.quantity
        end
        return inventory
    end
    return nil
end

-- 购买物品
function ShopData.buyItem(userId: string, itemId: string, quantity: number): (boolean, string?)
    local token = userTokens[userId]
    if not token then return false, "未认证用户" end

    local success, response = makeRequest("POST", "/users/buy", {
        itemId = itemId,
        quantity = quantity
    }, token)

    if success and response then
        if response.success then
            return true, response.message
        else
            return false, response.error or "购买失败"
        end
    elseif response and response.error then
        -- API返回了错误信息（如HTTP 400, 403等）
        return false, response.error
    end
    return false, "网络请求失败"
end

-- 出售物品
function ShopData.sellItem(userId: string, itemId: string, quantity: number): (boolean, string?)
    local token = userTokens[userId]
    if not token then return false, "未认证用户" end

    local success, response = makeRequest("POST", "/users/sell", {
        itemId = itemId,
        quantity = quantity
    }, token)

    if success and response then
        if response.success then
            return true, response.message
        else
            return false, response.error or "出售失败"
        end
    elseif response and response.error then
        -- API返回了错误信息（如HTTP 400, 403等）
        return false, response.error
    end
    return false, "网络请求失败"
end

-- 获取交易记录
function ShopData.getTransactions(userId: string, limit: number?, offset: number?): any?
    local token = userTokens[userId]
    if not token then return nil end

    local endpoint = "/users/transactions"
    if limit or offset then
        endpoint = endpoint .. "?"
        local params = {}
        if limit then table.insert(params, "limit=" .. tostring(limit)) end
        if offset then table.insert(params, "offset=" .. tostring(offset)) end
        endpoint = endpoint .. table.concat(params, "&")
    end

    local success, response = makeRequest("GET", endpoint, nil, token)
    if success and response and response.data then
        return response.data
    end
    return nil
end

-- 管理员功能：获取所有用户
function ShopData.getAllUsers(userId: string, limit: number?, offset: number?): (boolean, any?, string?)
    local token = userTokens[userId]
    if not token then return false, nil, "未认证用户" end

    local endpoint = "/admin/users"
    if limit or offset then
        endpoint = endpoint .. "?"
        local params = {}
        if limit then table.insert(params, "limit=" .. tostring(limit)) end
        if offset then table.insert(params, "offset=" .. tostring(offset)) end
        endpoint = endpoint .. table.concat(params, "&")
    end

    local success, response = makeRequest("GET", endpoint, nil, token)
    if success and response and response.data then
        return true, response.data, nil
    elseif response and response.error then
        return false, nil, response.error
    end
    return false, nil, "网络请求失败"
end

-- 管理员功能：修改用户金币
function ShopData.setUserCoins(adminUserId: string, targetUserId: string, newCoins: number, reason: string?): (boolean, string?)
    local token = userTokens[adminUserId]
    if not token then return false, "未认证用户" end

    local success, response = makeRequest("PUT", "/admin/users/" .. targetUserId .. "/coins", {
        coins = newCoins,
        reason = reason
    }, token)

    if success and response then
        if response.success then
            return true, response.message
        else
            return false, response.error or "修改失败"
        end
    elseif response and response.error then
        -- API返回了错误信息（如HTTP 400, 404等）
        return false, response.error
    end
    return false, "网络请求失败"
end

-- 获取系统统计
function ShopData.getSystemStats(adminUserId: string): any?
    local token = userTokens[adminUserId]
    if not token then return nil end

    local success, response = makeRequest("GET", "/admin/stats", nil, token)
    if success and response and response.data then
        return response.data
    end
    return nil
end

-- 系统配置缓存
local systemConfig = {
    sell_rate = 0.8 -- 默认值
}

-- 获取系统配置
function ShopData.getSystemConfig(): any?
    local success, response = makeRequest("GET", "/items/config")
    if success and response and response.data then
        systemConfig.sell_rate = response.data.sell_rate or 0.8
        return response.data
    end
    return nil
end

-- 获取卖出价格比例
function ShopData.getSellRate(): number
    return systemConfig.sell_rate
end

-- 计算卖出价格（使用系统配置的sell_rate）
function ShopData.calculateSellPrice(price: number): number
    return math.floor(price * systemConfig.sell_rate)
end

return ShopData
