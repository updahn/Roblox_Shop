-- 数据服务模块 - 统一处理所有API调用
-- 简化版本，集中管理HTTP请求

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = {}

-- 等待配置模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

-- 用户认证令牌存储
local userTokens = {}

-- ==============================================
-- HTTP请求工具
-- ==============================================

local function makeRequest(method: string, endpoint: string, data: any?, token: string?)
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
            return false, {error = "HTTP " .. (response.StatusCode or "Unknown")}
        end
    else
        warn("网络请求异常: " .. tostring(response))
        return false, {error = "Network error"}
    end
end

-- ==============================================
-- 认证相关
-- ==============================================

function DataService.authenticateUser(userId: string, username: string, displayName: string?)
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

function DataService.isAuthenticated(userId: string): boolean
    return userTokens[userId] ~= nil
end

function DataService.getToken(userId: string): string?
    return userTokens[userId]
end

function DataService.removeToken(userId: string)
    userTokens[userId] = nil
end

-- ==============================================
-- 普通用户数据
-- ==============================================

function DataService.getUserData(userId: string)
    local token = userTokens[userId]
    if not token then return nil end

    local success, response = makeRequest("GET", "/users/me", nil, token)
    if success and response and response.data then
        return response.data
    end
    return nil
end

function DataService.getUserInventory(userId: string)
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

function DataService.getShopItems()
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

function DataService.buyItem(userId: string, itemId: string, quantity: number): (boolean, string?)
    local token = userTokens[userId]
    if not token then
        return false, "认证失败，请重新进入游戏"
    end

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
        return false, response.error
    end
    return false, "网络请求失败"
end

function DataService.sellItem(userId: string, itemId: string, quantity: number): (boolean, string?)
    local token = userTokens[userId]
    if not token then
        return false, "认证失败，请重新进入游戏"
    end

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
        return false, response.error
    end
    return false, "网络请求失败"
end

function DataService.claimDailyRewards(userId: string): (boolean, string?, any?)
    local token = userTokens[userId]
    if not token then
        return false, "认证失败，请重新进入游戏", nil
    end

    local success, response = makeRequest("POST", "/users/membership/claim-rewards", nil, token)
    if success and response then
        if response.success then
            return true, response.message, response.data
        else
            -- 即使奖励领取失败（比如没有会员或已领取），也返回成功，避免阻塞登录流程
            return true, response.message or "无可领取的奖励", response.data or {totalRewards = 0}
        end
    elseif response and response.error then
        return true, response.error, {totalRewards = 0}
    end
    return true, "网络请求失败", {totalRewards = 0}
end

function DataService.getMembershipStatus(userId: string)
    local token = userTokens[userId]
    if not token then return nil end

    local success, response = makeRequest("GET", "/users/membership/status", nil, token)
    if success and response and response.data then
        return response.data
    end
    return nil
end

-- ==============================================
-- 管理员功能
-- ==============================================

function DataService.getAllUsers(adminUserId: string, limit: number?, offset: number?, includeStats: boolean?): (boolean, any?, string?)
    local token = userTokens[adminUserId]
    if not token then
        return false, nil, "认证失败，请重新进入游戏"
    end

    local endpoint = "/admin/users"
    local params = {}
    if limit then table.insert(params, "limit=" .. tostring(limit)) end
    if offset then table.insert(params, "offset=" .. tostring(offset)) end
    if includeStats then table.insert(params, "includeStats=true") end

    if #params > 0 then
        endpoint = endpoint .. "?" .. table.concat(params, "&")
    end

    local success, response = makeRequest("GET", endpoint, nil, token)
    if success and response and response.data then
        return true, response.data, nil
    elseif response and response.error then
        return false, nil, response.error
    end
    return false, nil, "网络请求失败"
end

function DataService.setUserCoins(adminUserId: string, targetUserId: string, newCoins: number, reason: string?): (boolean, string?)
    local token = userTokens[adminUserId]
    if not token then
        return false, "认证失败，请重新进入游戏"
    end

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
        return false, response.error
    end
    return false, "网络请求失败"
end

function DataService.getMembersList(adminUserId: string, page: number?, limit: number?, status: string?): (boolean, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, {error = "认证失败，请重新进入游戏"}
    end

    local params = {}
    if page then params.page = tostring(page) end
    if limit then params.limit = tostring(limit) end
    if status then params.status = status end

    local queryString = ""
    local first = true
    for key, value in pairs(params) do
        if first then
            queryString = "?" .. key .. "=" .. value
            first = false
        else
            queryString = queryString .. "&" .. key .. "=" .. value
        end
    end

    local success, response = makeRequest("GET", "/admin/members-list" .. queryString, nil, token)
    return success, response
end

function DataService.getAllUsersWithMembership(adminUserId: string, page: number?, limit: number?, status: string?): (boolean, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, {error = "认证失败，请重新进入游戏"}
    end

    local params = {}
    if page then params.page = tostring(page) end
    if limit then params.limit = tostring(limit) end
    if status then params.status = status end

    local queryString = ""
    local first = true
    for key, value in pairs(params) do
        if first then
            queryString = "?" .. key .. "=" .. value
            first = false
        else
            queryString = queryString .. "&" .. key .. "=" .. value
        end
    end

    local success, response = makeRequest("GET", "/admin/all-users-membership" .. queryString, nil, token)
    return success, response
end

function DataService.manageUserMembership(adminUserId: string, requestData: any): (boolean, any?)
    print("🔧 [ManageUserMembership] 开始处理请求:", HttpService:JSONEncode(requestData))

    local token = userTokens[adminUserId]
    if not token then
        print("❌ [ManageUserMembership] 认证失败: 没有找到token")
        return false, {error = "认证失败，请重新进入游戏"}
    end

    -- 根据不同的动作路由到相应的API端点
    local action = requestData.action
    print("🔧 [ManageUserMembership] 动作类型:", action)
    local success, response

    -- 先获取用户名（如果只有userId，需要转换为playerName）
    local playerName = requestData.playerName or requestData.username
    print("🔧 [ManageUserMembership] 初始用户名:", playerName)

    if not playerName and requestData.userId then
        print("🔧 [ManageUserMembership] 通过userId获取用户名:", requestData.userId)
        -- 如果只有userId，需要先获取用户信息来得到用户名
        local userSuccess, userResponse = makeRequest("GET", "/admin/users/" .. requestData.userId, nil, token)
        print("🔧 [ManageUserMembership] 用户信息获取结果:", userSuccess, userResponse and "有响应" or "无响应")

        if userSuccess and userResponse and userResponse.data and userResponse.data.user then
            playerName = userResponse.data.user.username
            print("🔧 [ManageUserMembership] 获取到用户名:", playerName)
        else
            print("❌ [ManageUserMembership] 无法获取用户信息")
            return false, {error = "无法获取用户信息: " .. (userResponse and userResponse.error or "未知错误")}
        end
    end

    if not playerName then
        print("❌ [ManageUserMembership] 缺少用户名信息")
        return false, {error = "缺少用户名信息"}
    end

    print("🔧 [ManageUserMembership] 使用用户名:", playerName)

    if action == "activate" then
        -- 激活会员 - 使用add-membership
        local days = requestData.days or 30
        print("🔧 [ManageUserMembership] 激活会员，天数:", days)
        success, response = makeRequest("POST", "/admin/add-membership", {
            playerName = playerName,
            days = days
        }, token)
    elseif action == "deactivate" then
        -- 停用会员 - 使用cancel-membership
        print("🔧 [ManageUserMembership] 停用会员")
        success, response = makeRequest("POST", "/admin/cancel-membership", {
            playerName = playerName
        }, token)
    elseif action == "set_days" then
        -- 设置会员天数 - 使用extend-membership或add-membership
        local days = requestData.days or 0
        print("🔧 [ManageUserMembership] 设置会员天数:", days)
        if days > 0 then
            success, response = makeRequest("POST", "/admin/extend-membership", {
                playerName = playerName,
                days = days
            }, token)
        else
            -- 如果天数为0，相当于取消会员
            print("🔧 [ManageUserMembership] 天数为0，取消会员")
            success, response = makeRequest("POST", "/admin/cancel-membership", {
                playerName = playerName
            }, token)
        end
    elseif action == "set_reward" then
        -- 每日奖励是系统级配置，不支持单用户设置
        -- 暂时返回成功状态，提示用户需要在系统配置中修改
        print("🔧 [ManageUserMembership] set_reward操作，返回提示信息")
        return true, {
            success = true,
            message = "每日奖励是系统级配置，请在系统配置中修改全局设置"
        }
    else
        -- 未知动作，返回错误
        print("❌ [ManageUserMembership] 未知的操作类型:", action)
        return false, {error = "未知的操作类型: " .. tostring(action)}
    end

    print("🔧 [ManageUserMembership] API调用结果:", success, response and "有响应" or "无响应")
    if response then
        print("🔧 [ManageUserMembership] 响应内容:", HttpService:JSONEncode(response))
    end

    return success, response
end

function DataService.addPlayerMembership(adminUserId: string, playerName: string, days: number): (boolean, string?, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, "认证失败，请重新进入游戏", nil
    end

    local success, response = makeRequest("POST", "/admin/add-membership", {
        playerName = playerName,
        days = days
    }, token)

    if success and response then
        return response.success, response.message, response.data
    end
    return false, "网络请求失败", nil
end

function DataService.updatePlayerMembership(adminUserId: string, playerName: string, membershipType: string?, status: string?, endDate: string?): (boolean, string?, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, "认证失败，请重新进入游戏", nil
    end

    local success, response = makeRequest("PUT", "/admin/update-membership", {
        playerName = playerName,
        membershipType = membershipType,
        status = status,
        endDate = endDate
    }, token)

    if success and response then
        return response.success, response.message, response.data
    end
    return false, "网络请求失败", nil
end

function DataService.cancelPlayerMembership(adminUserId: string, playerName: string): (boolean, string?, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, "认证失败，请重新进入游戏", nil
    end

    local success, response = makeRequest("POST", "/admin/cancel-membership", {
        playerName = playerName
    }, token)

    if success and response then
        return response.success, response.message, response.data
    end
    return false, "网络请求失败", nil
end

function DataService.extendPlayerMembership(adminUserId: string, playerName: string, days: number): (boolean, string?, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, "认证失败，请重新进入游戏", nil
    end

    local success, response = makeRequest("POST", "/admin/extend-membership", {
        playerName = playerName,
        days = days
    }, token)

    if success and response then
        return response.success, response.message, response.data
    end
    return false, "网络请求失败", nil
end

function DataService.batchMembershipOperation(adminUserId: string, playerNames: {string}, action: string, days: number?): (boolean, string?, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, "认证失败，请重新进入游戏", nil
    end

    local success, response = makeRequest("POST", "/admin/batch-membership", {
        playerNames = playerNames,
        action = action,
        days = days
    }, token)

    if success and response then
        return response.success, response.message, response.data
    end
    return false, "网络请求失败", nil
end

function DataService.getUserHistory(adminUserId: string, targetPlayerName: string, page: number?, limit: number?): (boolean, string?, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, "认证失败，请重新进入游戏", nil
    end

    local params = {}
    if page then params.page = tostring(page) end
    if limit then params.limit = tostring(limit) end

    local queryString = ""
    local first = true
    for key, value in pairs(params) do
        if first then
            queryString = "?" .. key .. "=" .. value
            first = false
        else
            queryString = queryString .. "&" .. key .. "=" .. value
        end
    end

    local success, response = makeRequest("GET", "/admin/users/" .. targetPlayerName .. "/history" .. queryString, nil, token)

    if success and response then
        return response.success, response.message, response.data
    end
    return false, "网络请求失败", nil
end

function DataService.getAdminMembershipStatus(adminUserId: string, targetPlayerName: string): (boolean, string?, any?)
    local token = userTokens[adminUserId]
    if not token then
        return false, "认证失败，请重新进入游戏", nil
    end

    local success, response = makeRequest("GET", "/admin/users/" .. targetPlayerName .. "/membership", nil, token)

    if success and response then
        return response.success, response.message, response.data
    end
    return false, "网络请求失败", nil
end

-- ==============================================
-- 管理员权限验证
-- ==============================================

function DataService.checkAdminPermission(userId: string): (boolean, string?)
    local success, response = makeRequest("POST", "/auth/check-admin", {
        userId = userId
    })

    if success and response and response.data then
        return response.data.isAdmin == true, response.data.message
    elseif response and response.error then
        return false, response.error
    end

    return false, "网络请求失败"
end

-- ==============================================
-- 用户交易记录功能
-- ==============================================

function DataService.getUserTransactions(userId: string, limit: number?, offset: number?, type: string?): (boolean, any?, string?)
    local token = userTokens[userId]
    if not token then
        return false, nil, "认证失败，请重新进入游戏"
    end

    local endpoint = "/users/transactions"
    local params = {}

    if limit then params.limit = tostring(limit) end
    if offset then params.offset = tostring(offset) end
    if type then params.type = type end

    local queryString = ""
    local first = true
    for key, value in pairs(params) do
        if first then
            queryString = "?" .. key .. "=" .. value
            first = false
        else
            queryString = queryString .. "&" .. key .. "=" .. value
        end
    end

    local success, response = makeRequest("GET", endpoint .. queryString, nil, token)

    if success and response and response.data then
        return true, response.data, nil
    elseif response and response.error then
        return false, nil, response.error
    end
    return false, nil, "网络请求失败"
end

print("💾 数据服务模块已加载")

return DataService
