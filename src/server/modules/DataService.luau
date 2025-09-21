-- 数据服务模块 - 基于 DataStoreService 的统一数据管理

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local DataService = {}

-- 等待配置和数据服务模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

-- 导入数据服务模块
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))
local UserDataService = require(script.Parent:WaitForChild("UserDataService"))
local AdminDataService = require(script.Parent:WaitForChild("AdminDataService"))

-- 用户会话存储（替换令牌系统）
local userSessions = {}

-- 初始化 DataStore 管理器
DataStoreManager.initialize()

-- ==============================================
-- 认证相关
-- ==============================================

function DataService.authenticateUser(userId: string, username: string, displayName: string?)
    local success, result = pcall(function()
        return UserDataService.createOrLoginUser(userId, username, displayName)
    end)

    if success and result then
        -- 创建用户会话
        userSessions[userId] = {
            userId = userId,
            username = username,
            displayName = displayName,
            authenticated = true,
            createdAt = os.time()
        }

        return true, result.user
    end

    return false, nil
end

function DataService.isAuthenticated(userId: string): boolean
    return userSessions[userId] ~= nil and userSessions[userId].authenticated
end

-- 清理用户会话
function DataService.clearUserSession(userId: string)
    if userSessions[userId] then
        userSessions[userId] = nil
        print("🧹 [DataService] 清理用户会话:", userId)
    end
end

function DataService.getSession(userId: string)
    return userSessions[userId]
end

function DataService.removeSession(userId: string)
    userSessions[userId] = nil
end

-- ==============================================
-- 普通用户数据
-- ==============================================

function DataService.getUserData(userId: string)
    if not DataService.isAuthenticated(userId) then
        return nil
    end

    local success, userData = pcall(function()
        return UserDataService.getUserDetails(userId)
    end)

    return success and userData or nil
end

function DataService.getUserInventory(userId: string)
    if not DataService.isAuthenticated(userId) then
        return nil
    end

    local success, inventory = pcall(function()
        return UserDataService.getUserInventory(userId)
    end)

    if success and inventory then
        -- 转换格式
        local formattedInventory = {}
        for itemId, itemData in pairs(inventory) do
            formattedInventory[itemId] = itemData.quantity
        end
        return formattedInventory
    end

    return nil
end

function DataService.getShopItems()
    local success, items = pcall(function()
        return UserDataService.getItems(true) -- 只获取激活的商品
    end)

    if success and items then
        return items
    end

    return nil
end

function DataService.buyItem(userId: string, itemId: string, quantity: number): (boolean, string?)
    if not DataService.isAuthenticated(userId) then
        return false, "认证失败，请重新进入游戏"
    end

    local success, result = pcall(function()
        return UserDataService.buyItem(userId, itemId, quantity)
    end)

    if success and result and result.success then
        return true, "购买成功"
    else
        local errorMessage = (result and result.message) or "购买失败"
        return false, errorMessage
    end
end

function DataService.sellItem(userId: string, itemId: string, quantity: number): (boolean, string?)
    if not DataService.isAuthenticated(userId) then
        return false, "认证失败，请重新进入游戏"
    end

    local result, errorMessage = UserDataService.sellItem(userId, itemId, quantity)

    if result and result.success then
        return true, "出售成功"
    else
        return false, errorMessage or "出售失败"
    end
end

function DataService.claimDailyRewards(userId: string): (boolean, string?, any?)
    if not DataService.isAuthenticated(userId) then
        return false, "认证失败，请重新进入游戏", nil
    end

    local success, result = pcall(function()
        return UserDataService.processLoginRewards(userId)
    end)

    if success and result then
        if result.success then
            return true, result.message, {
                totalRewards = result.totalRewards,
                rewardAmount = result.rewardAmount,
                rewardedDays = result.rewardedDays,
                membershipType = result.membershipType
            }
        else
            -- 即使奖励领取失败（比如没有会员或已领取），也返回成功，避免阻塞登录流程
            return true, result.message or "无可领取的奖励", {totalRewards = 0}
        end
    end

    return true, "网络请求失败", {totalRewards = 0}
end

function DataService.getMembershipStatus(userId: string)
    if not DataService.isAuthenticated(userId) then
        return nil
    end

    local success, membershipStatus = pcall(function()
        return UserDataService.getMembershipStatus(userId)
    end)

    return success and membershipStatus or nil
end

-- ==============================================
-- 管理员功能
-- ==============================================

function DataService.getAllUsers(adminUserId: string, limit: number?, offset: number?, includeStats: boolean?): (boolean, any?, string?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, nil, "认证失败，请重新进入游戏"
    end

    local success, users = pcall(function()
        return AdminDataService.getUsersWithPagination({
            limit = limit or 100,
            offset = offset or 0,
            includeStats = includeStats
        })
    end)

    if success and users then
        return true, {users = users}, nil
    else
        local errorMessage = users or "获取用户列表失败"
        return false, nil, errorMessage
    end
end

function DataService.setUserCoins(adminUserId: string, targetUserId: string, newCoins: number, reason: string?): (boolean, string?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, "认证失败，请重新进入游戏"
    end

    local success, result = pcall(function()
        return AdminDataService.updateUserCoins(targetUserId, newCoins, reason, adminUserId)
    end)

    if success then
        return true, "金币修改成功"
    else
        local errorMessage = result or "修改失败"
        return false, errorMessage
    end
end

function DataService.getMembersList(adminUserId: string, page: number?, limit: number?, status: string?): (boolean, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, {error = "认证失败，请重新进入游戏"}
    end

    local success, result = pcall(function()
        return AdminDataService.getMembersList(page, limit, status)
    end)

    if success and result then
        return true, result
    else
        return false, {error = result or "获取会员列表失败"}
    end
end

function DataService.getAllUsersWithMembership(adminUserId: string, page: number?, limit: number?, status: string?): (boolean, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, {error = "认证失败，请重新进入游戏"}
    end

    local success, result = pcall(function()
        return AdminDataService.getAllUsersWithMembershipStatus(page, limit, status)
    end)

    if success and result then
        return true, {success = true, data = result}
    else
        local errorMessage = result or "获取用户会员状态失败"
        warn("❌ [DataService] 获取用户会员状态失败:", errorMessage)
        return false, {success = false, error = errorMessage, message = errorMessage}
    end
end

function DataService.manageUserMembership(adminUserId: string, requestData: any): (boolean, any?)
    print("🔧 [ManageUserMembership] 开始处理请求:", HttpService:JSONEncode(requestData))

    if not DataService.isAuthenticated(adminUserId) then
        print("❌ [ManageUserMembership] 认证失败: 用户未认证")
        return false, {error = "认证失败，请重新进入游戏"}
    end

    local action = requestData.action
    print("🔧 [ManageUserMembership] 动作类型:", action)

    local playerName = requestData.playerName or requestData.username
    local userId = requestData.userId

    -- 如果只有userId，需要转换为用户名
    if not playerName and userId then
        local userData = AdminDataService.checkUserExists(userId, true)
        if userData then
            playerName = userData.username
            print("🔧 [ManageUserMembership] 获取到用户名:", playerName)
        else
            print("❌ [ManageUserMembership] 无法获取用户信息")
            return false, {error = "用户不存在"}
        end
    end

    if not playerName then
        print("❌ [ManageUserMembership] 缺少用户名信息")
        return false, {error = "缺少用户名信息"}
    end

    -- 通过用户名获取用户ID（因为我们的DataStore使用userId作为键）
    local userInfo = AdminDataService.getUserByUsername(playerName)
    if not userInfo then
        return false, {error = "用户不存在: " .. playerName}
    end

    local targetUserId = userInfo.id
    print("🔧 [ManageUserMembership] 目标用户ID:", targetUserId)

    local success, response

    if action == "activate" then
        local days = requestData.days or 30
        print("🔧 [ManageUserMembership] 激活会员，天数:", days)
        success, response = pcall(function()
            return AdminDataService.buyMembership(targetUserId, days, 100)
        end)

        if success and response then
            response = {success = true, message = "会员激活成功", data = response}
        else
            response = {success = false, error = response or "激活会员失败"}
        end

    elseif action == "deactivate" then
        print("🔧 [ManageUserMembership] 停用会员")
        success, response = pcall(function()
            return AdminDataService.cancelMembership(targetUserId)
        end)

        if success and response and response.success then
            response = {success = true, message = response.message, data = response}
        else
            response = {success = false, error = response or "停用会员失败"}
        end

    elseif action == "set_days" then
        local days = requestData.days or 0
        print("🔧 [ManageUserMembership] 设置会员天数（绝对值） - 目标用户ID:", targetUserId, "天数:", days)

        success, response = pcall(function()
            return AdminDataService.setMembershipDays(targetUserId, days)
        end)

        -- 详细错误诊断
        if not success then
            local errorMsg = "pcall失败: " .. tostring(response)
            print("❌ [ManageUserMembership] " .. errorMsg)
            response = {success = false, error = errorMsg}
        elseif not response then
            local errorMsg = "setMembershipDays返回nil"
            print("❌ [ManageUserMembership] " .. errorMsg)
            response = {success = false, error = errorMsg}
        elseif not response.success then
            local errorMsg = response.message or "setMembershipDays内部失败"
            print("❌ [ManageUserMembership] " .. errorMsg)
            response = {success = false, error = errorMsg}
        end

        if success and response and response.success then
            -- 记录更详细的操作信息
            local oldDays = response.oldDaysRemaining or 0
            local newDays = response.newDays or 0
            local changeDesc = ""

            if newDays == 0 then
                changeDesc = "会员已取消"
            elseif oldDays == 0 then
                changeDesc = "会员已激活，设置为 " .. newDays .. " 天"
            else
                changeDesc = "会员天数从 " .. oldDays .. " 天改为 " .. newDays .. " 天"
            end

            print("✅ [ManageUserMembership] " .. changeDesc)
            response = {success = true, message = response.message or changeDesc, data = response}
        else
            local errorMsg = response and response.message or "设置会员天数失败"
            print("❌ [ManageUserMembership] " .. errorMsg)
            response = {success = false, error = errorMsg}
        end

    elseif action == "set_reward" then
        local reward = requestData.dailyReward or 100
        print("🔧 [ManageUserMembership] 设置每日奖励:", reward)

        success, response = pcall(function()
            return AdminDataService.setMembershipReward(targetUserId, reward)
        end)

        if success and response and response.success then
            response = {success = true, message = response.message or "每日奖励设置成功", data = response}
        else
            response = {success = false, error = response or "设置每日奖励失败"}
        end
    else
        print("❌ [ManageUserMembership] 未知的操作类型:", action)
        return false, {error = "未知的操作类型: " .. tostring(action)}
    end

    print("🔧 [ManageUserMembership] 操作结果:", success, response and "有响应" or "无响应")
    if response then
        print("🔧 [ManageUserMembership] 响应内容:", HttpService:JSONEncode(response))
    end

    return true, response
end

function DataService.addPlayerMembership(adminUserId: string, playerName: string, days: number): (boolean, string?, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, "认证失败，请重新进入游戏", nil
    end

    -- 通过用户名获取用户ID
    local userInfo = AdminDataService.getUserByUsername(playerName)
    if not userInfo then
        return false, "用户不存在: " .. playerName, nil
    end

    local success, result = pcall(function()
        return AdminDataService.buyMembership(userInfo.id, days, 100)
    end)

    if success and result then
        return true, "会员添加成功", result
    else
        return false, result or "添加会员失败", nil
    end
end

function DataService.updatePlayerMembership(adminUserId: string, playerName: string, membershipType: string?, status: string?, endDate: string?): (boolean, string?, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, "认证失败，请重新进入游戏", nil
    end

    -- 通过用户名获取用户ID
    local userInfo = AdminDataService.getUserByUsername(playerName)
    if not userInfo then
        return false, "用户不存在: " .. playerName, nil
    end

    local success, result = pcall(function()
        return AdminDataService.updateMembershipInfo(userInfo.id, {
            membershipType = membershipType,
            status = status,
            endDate = endDate
        })
    end)

    if success and result and result.success then
        return true, "会员信息更新成功", result
    else
        return false, result and result.message or "更新会员信息失败", nil
    end
end

function DataService.cancelPlayerMembership(adminUserId: string, playerName: string): (boolean, string?, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, "认证失败，请重新进入游戏", nil
    end

    -- 通过用户名获取用户ID
    local userInfo = AdminDataService.getUserByUsername(playerName)
    if not userInfo then
        return false, "用户不存在: " .. playerName, nil
    end

    local success, result = pcall(function()
        return AdminDataService.cancelMembership(userInfo.id)
    end)

    if success and result and result.success then
        return true, result.message, result
    else
        return false, result and result.message or "取消会员失败", nil
    end
end

function DataService.extendPlayerMembership(adminUserId: string, playerName: string, days: number): (boolean, string?, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, "认证失败，请重新进入游戏", nil
    end

    -- 通过用户名获取用户ID
    local userInfo = AdminDataService.getUserByUsername(playerName)
    if not userInfo then
        return false, "用户不存在: " .. playerName, nil
    end

    local success, result = pcall(function()
        return AdminDataService.extendMembership(userInfo.id, days)
    end)

    if success and result and result.success then
        return true, result.message or "会员延长成功", result
    else
        return false, result and result.message or "延长会员失败", nil
    end
end

function DataService.batchMembershipOperation(adminUserId: string, playerNames: {string}, action: string, days: number?): (boolean, string?, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, "认证失败，请重新进入游戏", nil
    end

    local results = {}
    local successCount = 0
    local failureCount = 0

    for _, playerName in ipairs(playerNames) do
        local userInfo = AdminDataService.getUserByUsername(playerName)
        if userInfo then
            local success, result

            if action == "add" or action == "activate" then
                success, result = pcall(function()
                    return AdminDataService.buyMembership(userInfo.id, days or 30, 100)
                end)
            elseif action == "cancel" or action == "deactivate" then
                success, result = pcall(function()
                    return AdminDataService.cancelMembership(userInfo.id)
                end)
            elseif action == "extend" then
                success, result = pcall(function()
                    return AdminDataService.extendMembership(userInfo.id, days or 30)
                end)
            else
                success, result = false, "未知操作: " .. action
            end

            if success and result then
                successCount = successCount + 1
                results[playerName] = {success = true, message = "操作成功"}
            else
                failureCount = failureCount + 1
                results[playerName] = {success = false, message = result or "操作失败"}
            end
        else
            failureCount = failureCount + 1
            results[playerName] = {success = false, message = "用户不存在"}
        end
    end

    local message = string.format("批量操作完成，成功: %d，失败: %d", successCount, failureCount)
    return successCount > 0, message, {results = results, summary = {success = successCount, failure = failureCount}}
end

function DataService.getUserHistory(adminUserId: string, targetPlayerName: string, page: number?, limit: number?): (boolean, string?, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, "认证失败，请重新进入游戏", nil
    end

    -- 通过用户名获取用户ID
    local userInfo = AdminDataService.getUserByUsername(targetPlayerName)
    if not userInfo then
        return false, "用户不存在: " .. targetPlayerName, nil
    end

    local success, transactions = pcall(function()
        return UserDataService.getUserTransactions(userInfo.id, limit or 50)
    end)

    if success and transactions then
        return true, "获取交易历史成功", {
            transactions = transactions,
            pagination = {
                page = page or 1,
                limit = limit or 50,
                total = #transactions
            }
        }
    else
        return false, transactions or "获取交易历史失败", nil
    end
end

function DataService.getAdminMembershipStatus(adminUserId: string, targetPlayerName: string): (boolean, string?, any?)
    if not DataService.isAuthenticated(adminUserId) then
        return false, "认证失败，请重新进入游戏", nil
    end

    -- 通过用户名获取用户ID
    local userInfo = AdminDataService.getUserByUsername(targetPlayerName)
    if not userInfo then
        return false, "用户不存在: " .. targetPlayerName, nil
    end

    local success, membershipStatus = pcall(function()
        return UserDataService.getMembershipStatus(userInfo.id)
    end)

    if success and membershipStatus then
        return true, "获取会员状态成功", membershipStatus
    else
        return false, membershipStatus or "获取会员状态失败", nil
    end
end

-- ==============================================
-- 管理员权限验证
-- ==============================================

function DataService.checkAdminPermission(userId: string): (boolean, string?)
    local userData = AdminDataService.checkUserExists(userId, true)

    if userData then
        return userData.is_admin == true, userData.is_admin and "用户是管理员" or "用户不是管理员"
    else
        return false, "用户不存在"
    end
end

-- ==============================================
-- 用户交易记录功能
-- ==============================================

function DataService.getUserTransactions(userId: string, limit: number?, offset: number?, type: string?): (boolean, any?, string?)
    if not DataService.isAuthenticated(userId) then
        return false, nil, "认证失败，请重新进入游戏"
    end

    local success, transactions = pcall(function()
        return UserDataService.getUserTransactions(userId, limit or 50)
    end)

    if success and transactions then
        -- 根据类型筛选
        local filteredTransactions = transactions
        if type then
            filteredTransactions = {}
            for _, transaction in ipairs(transactions) do
                if transaction.type == type then
                    table.insert(filteredTransactions, transaction)
                end
            end
        end

        -- 应用偏移量和限制
        if offset and offset > 0 then
            local offsetTransactions = {}
            for i = offset + 1, #filteredTransactions do
                table.insert(offsetTransactions, filteredTransactions[i])
            end
            filteredTransactions = offsetTransactions
        end

        if limit and #filteredTransactions > limit then
            local limitedTransactions = {}
            for i = 1, limit do
                table.insert(limitedTransactions, filteredTransactions[i])
            end
            filteredTransactions = limitedTransactions
        end

        return true, {
            transactions = filteredTransactions,
            pagination = {
                offset = offset or 0,
                limit = limit or 50,
                total = #transactions
            }
        }, nil
    else
        return false, nil, transactions or "获取交易记录失败"
    end
end

print("💾 数据服务模块已加载（基于 DataStore）")

return DataService
