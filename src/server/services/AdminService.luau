-- 管理员服务模块
-- 处理管理员功能，包括用户管理、会员管理等

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminService = {}

-- 等待模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local UserService = require(script.Parent:WaitForChild("UserService"))

-- 导入缓存服务 - 使用统一缓存系统进行管理员权限缓存
local CacheService = nil -- 延迟加载避免循环依赖

-- 获取缓存服务（延迟初始化）
-- 管理员权限验证结果将被缓存3分钟，提高性能
local function getCacheService()
    if not CacheService then
        CacheService = require(script.Parent.CacheService)
    end
    return CacheService
end

-- ==============================================
-- 权限检查
-- ==============================================

-- 管理员权限验证函数（带缓存）
function AdminService.isValidAdmin(player: Player): boolean
    if not player or not player.UserId then
        return false
    end

    local userId = tostring(player.UserId)
    local cacheService = getCacheService()

    -- 检查缓存
    local cachedResult = cacheService.getAdminPermission(userId)
    if cachedResult ~= nil then
        return cachedResult
    end

    -- 优先检查配置文件中的管理员用户名（立即生效）
    local SharedModules = game:GetService("ReplicatedStorage"):WaitForChild("SharedModules")
    local Config = require(SharedModules:WaitForChild("Config"))
    local defaultAdminUsernames = Config.ADMIN.DEFAULT_ADMIN_USERNAMES or {}

    local isConfigAdmin = false
    for _, adminUsername in ipairs(defaultAdminUsernames) do
        if player.Name == adminUsername then
            isConfigAdmin = true
            break
        end
    end

    local isDataAdmin = false
    if not isConfigAdmin then
        -- 只有当配置文件检查不通过时才查询数据库
        isDataAdmin, _ = DataService.checkAdminPermission(userId)
    end

    local finalIsAdmin = isConfigAdmin or isDataAdmin

    -- 缓存结果
    cacheService.cacheAdminPermission(userId, finalIsAdmin, 180) -- 缓存3分钟

    if isConfigAdmin then
        print("✅ [AdminService]", player.Name, "管理员权限验证通过（配置文件）")
    elseif isDataAdmin then
        print("✅ [AdminService]", player.Name, "管理员权限验证通过（数据库）")
    else
        print("❌ [AdminService]", player.Name, "权限验证失败")
    end

    return finalIsAdmin
end

-- ==============================================
-- 用户管理功能
-- ==============================================

local function handleGetAllUsers(player: Player)
    print("👑 [调试] 处理获取所有用户请求:", player.Name)

    if not AdminService.isValidAdmin(player) then
        print("❌ [权限错误] 用户", player.Name, "不是管理员")
        Events.Admin.GetAllUsers:FireClient(player, nil, "权限不足：您不是管理员")
        return
    end

    local userId = tostring(player.UserId)
    print("👑 [调试] 管理员权限验证通过，开始认证检查")

    -- 检查用户是否已认证，如果没有则尝试自动认证
    local session = UserService.isPlayerAuthenticated(player)
    if not session then
        print("👑 [调试] 管理员未认证，尝试自动认证")
        local authSuccess, userData = DataService.authenticateUser(userId, player.Name, player.DisplayName)
        if not authSuccess then
            print("❌ [认证失败] 管理员", player.Name, "认证失败")
            Events.Admin.GetAllUsers:FireClient(player, nil, "认证失败，请重新进入游戏")
            return
        end
        print("✅ [认证成功] 管理员", player.Name, "自动认证成功")
    end

    print("👑 [调试] 开始获取用户数据...")
    local success, allUsersData, errorMsg = DataService.getAllUsers(userId, 50, 0, true)

    if success and allUsersData then
        local allPlayersData = {}
        for _, user in ipairs(allUsersData.users) do
            -- 获取用户库存数据
            local inventory = DataService.getUserInventory(tostring(user.id))
            local inventoryCount = 0
            if inventory then
                for itemId, quantity in pairs(inventory) do
                    inventoryCount = inventoryCount + quantity
                end
            end

            local playerData = {
                userId = user.id,
                name = user.username,
                coins = user.coins or 0,
                totalPurchases = user.buy_count or 0,
                totalSpent = user.total_spent or 0,
                totalSales = user.sell_count or 0,
                totalEarned = user.total_earned or 0,
                inventoryCount = inventoryCount,
                -- 添加会员状态相关字段
                membership_status = user.membership_status or "none",
                end_date = user.membership_end_date or user.end_date,
                days_remaining = user.days_remaining or 0,
                daily_reward_coins = user.daily_reward_coins or 100
            }

            allPlayersData[user.username] = playerData
            print("👑 [调试] 添加玩家数据:", user.username, "->", playerData)
        end

        local playerCount = 0
        for _ in pairs(allPlayersData) do
            playerCount = playerCount + 1
        end

        print("👑 [调试] 准备发送数据给客户端，玩家数量:", playerCount)
        print("👑 [调试] 发送的数据:", allPlayersData)

        Events.Admin.GetAllUsers:FireClient(player, allPlayersData)
        print("👑 [管理员] " .. player.Name .. " 查看了所有用户数据")
    else
        local errorMessage = errorMsg or "无法获取用户数据"
        warn("❌ [数据错误] " .. errorMessage)

        -- 检查是否是认证问题
        if errorMsg and string.find(errorMsg, "认证") then
            print("❌ [认证问题] 管理员认证失败，发送认证错误")
            Events.Admin.GetAllUsers:FireClient(player, nil, "认证失败：" .. errorMessage)
            return
        end

        -- 如果数据服务不可用，发送错误信息给客户端
        print("👑 [调试] 数据服务不可用，发送错误信息给客户端")
        local detailedError = string.format(
            "数据加载失败：%s\n\n可能的原因：\n• 数据存储服务异常\n• 网络连接问题\n• 权限配置错误\n\n请稍后重试或联系管理员",
            errorMessage
        )
        Events.Admin.GetAllUsers:FireClient(player, nil, detailedError)

        -- 同时提供一些基本的模拟数据作为备选
        print("👑 [调试] 同时提供模拟数据作为备选")
        spawn(function()
            wait(1) -- 等待1秒后再发送模拟数据
            local mockData = {
                [player.Name] = {
                    userId = player.UserId,
                    name = player.Name,
                    coins = 1000,
                    totalPurchases = 5,
                    totalSpent = 500,
                    totalSales = 3,
                    totalEarned = 300,
                    inventoryCount = 10,
                    membership_status = "active",
                    end_date = "2024-12-31",
                    days_remaining = 30,
                    daily_reward_coins = 100
                },
                ["模拟用户1"] = {
                    userId = 12345,
                    name = "模拟用户1",
                    coins = 500,
                    totalPurchases = 2,
                    totalSpent = 200,
                    totalSales = 1,
                    totalEarned = 100,
                    inventoryCount = 5,
                    membership_status = "none",
                    end_date = nil,
                    days_remaining = 0,
                    daily_reward_coins = 100
                },
                ["模拟用户2"] = {
                    userId = 67890,
                    name = "模拟用户2",
                    coins = 2000,
                    totalPurchases = 10,
                    totalSpent = 1000,
                    totalSales = 8,
                    totalEarned = 800,
                    inventoryCount = 15,
                    membership_status = "active",
                    end_date = "2024-10-15",
                    days_remaining = 15,
                    daily_reward_coins = 150
                }
            }

            print("👑 [调试] 发送模拟数据:", mockData)
            -- 先发送一个提示，告知这是模拟数据
            Events.Admin.GetAllUsers:FireClient(player, nil, "注意：以下为模拟数据（数据服务离线）")
            wait(0.5)
            Events.Admin.GetAllUsers:FireClient(player, mockData)
            print("👑 [管理员] " .. player.Name .. " 查看了模拟用户数据（数据服务不可用）")
        end)
    end
end

local function handleSetUserCoins(player: Player, targetPlayerName: string, newCoins: number)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试修改金币，但不是管理员")
        Events.Admin.SetUserCoins:FireClient(player, false, "权限不足")
        return
    end

    -- 查找目标玩家的ID和Player对象
    local targetUserId = nil
    local targetPlayer = nil
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer.Name == targetPlayerName then
            targetUserId = tostring(otherPlayer.UserId)
            targetPlayer = otherPlayer
            break
        end
    end

    if not targetUserId then
        Events.Admin.SetUserCoins:FireClient(player, false, "玩家 " .. targetPlayerName .. " 不在线")
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, message = DataService.setUserCoins(adminUserId, targetUserId, newCoins, "管理员调整 by " .. player.Name)

    if success then
        Events.Admin.SetUserCoins:FireClient(player, true, message)
        print("👑 [管理员操作] " .. player.Name .. " 修改了 " .. targetPlayerName .. " 的金币为 " .. newCoins)

        -- 立即通知目标玩家刷新数据
        if targetPlayer then
            print("🔄 [数据同步] 通知 " .. targetPlayerName .. " 刷新数据")

            -- 延迟一点时间确保数据已保存，然后通知目标玩家刷新
            spawn(function()
                task.wait(0.2) -- 稍等片刻确保数据已保存

                -- 通过事件触发目标玩家的数据刷新
                Events.User.RefreshData:FireClient(targetPlayer)
                print("✅ [数据同步] 已通知 " .. targetPlayerName .. " 刷新数据")
            end)
        end
    else
        Events.Admin.SetUserCoins:FireClient(player, false, message or "修改失败")
    end
end

-- ==============================================
-- 会员管理功能
-- ==============================================

local function handleGetMembersList(player: Player, page: number?, limit: number?, status: string?)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试获取会员列表，但不是管理员")
        Events.Admin.GetMembersList:FireClient(player, false, {error = "权限不足"})
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, response = DataService.getMembersList(adminUserId, page, limit, status)

    Events.Admin.GetMembersList:FireClient(player, success, response)

    if success then
        print("👑 [管理员] " .. player.Name .. " 查看了会员列表")
    else
        print("❌ [错误] " .. player.Name .. " 获取会员列表失败")
    end
end

local function handleUpdateMembership(player: Player, membershipData)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试更新会员信息，但不是管理员")
        Events.Admin.UpdateMembership:FireClient(player, false, "权限不足")
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, message, data = DataService.updatePlayerMembership(
        adminUserId,
        membershipData.playerName,
        membershipData.membershipType,
        membershipData.status,
        membershipData.endDate
    )

    Events.Admin.UpdateMembership:FireClient(player, success, message, data)

    if success then
        print("👑 [管理员] " .. player.Name .. " 更新了 " .. membershipData.playerName .. " 的会员信息")
    else
        print("❌ [错误] " .. player.Name .. " 更新会员信息失败: " .. (message or "未知错误"))
    end
end

local function handleAddMembership(player: Player, playerName: string, days: number)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试添加会员，但不是管理员")
        Events.Admin.AddMembership:FireClient(player, false, "权限不足")
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, message, data = DataService.addPlayerMembership(adminUserId, playerName, days)

    Events.Admin.AddMembership:FireClient(player, success, message, data)

    if success then
        print("👑 [管理员] " .. player.Name .. " 为 " .. playerName .. " 添加了 " .. days .. " 天会员")
    else
        print("❌ [错误] " .. player.Name .. " 添加会员失败: " .. (message or "未知错误"))
    end
end

local function handleCancelMembership(player: Player, playerName: string)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试取消会员，但不是管理员")
        Events.Admin.CancelMembership:FireClient(player, false, "权限不足")
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, message, data = DataService.cancelPlayerMembership(adminUserId, playerName)

    Events.Admin.CancelMembership:FireClient(player, success, message, data)

    if success then
        print("👑 [管理员] " .. player.Name .. " 取消了 " .. playerName .. " 的会员")
    else
        print("❌ [错误] " .. player.Name .. " 取消会员失败: " .. (message or "未知错误"))
    end
end

local function handleExtendMembership(player: Player, playerName: string, days: number)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试延长会员，但不是管理员")
        Events.Admin.ExtendMembership:FireClient(player, false, "权限不足")
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, message, data = DataService.extendPlayerMembership(adminUserId, playerName, days)

    Events.Admin.ExtendMembership:FireClient(player, success, message, data)

    if success then
        print("👑 [管理员] " .. player.Name .. " 为 " .. playerName .. " 延长了 " .. days .. " 天会员")
    else
        print("❌ [错误] " .. player.Name .. " 延长会员失败: " .. (message or "未知错误"))
    end
end

local function handleBatchMembershipOp(player: Player, playerNames: {string}, action: string, days: number?)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试批量操作会员，但不是管理员")
        Events.Admin.BatchMembershipOp:FireClient(player, false, "权限不足")
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, message, data = DataService.batchMembershipOperation(adminUserId, playerNames, action, days)

    Events.Admin.BatchMembershipOp:FireClient(player, success, message, data)

    if success then
        print("👑 [管理员] " .. player.Name .. " 对 " .. #playerNames .. " 个玩家执行了批量" .. action .. "操作")
    else
        print("❌ [错误] " .. player.Name .. " 批量操作失败: " .. (message or "未知错误"))
    end
end

local function handleGetAllUsersWithMembership(player: Player, page: number?, limit: number?, status: string?)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试获取用户会员数据，但不是管理员")
        Events.Admin.GetAllUsersWithMembership:FireClient(player, false, {error = "权限不足"})
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, response = DataService.getAllUsersWithMembership(adminUserId, page, limit, status)

    Events.Admin.GetAllUsersWithMembership:FireClient(player, success, response)

    if success then
        print("👑 [管理员] " .. player.Name .. " 查看了所有用户会员状态")
    else
        print("❌ [错误] " .. player.Name .. " 获取用户会员状态失败")
    end
end

local function handleManageUserMembership(player: Player, requestData)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试管理用户会员，但不是管理员")
        Events.Admin.ManageUserMembership:FireClient(player, false, {error = "权限不足"})
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, response = DataService.manageUserMembership(adminUserId, requestData)

    Events.Admin.ManageUserMembership:FireClient(player, success, response)

    if success and response and response.success then
        print("👑 [管理员] " .. player.Name .. " 管理了用户会员状态")

        -- 实时更新目标用户的状态（如果该用户在线）
        local targetPlayerName = requestData.playerName or requestData.username
        if targetPlayerName then
            -- 查找在线的目标玩家
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer.Name == targetPlayerName then
                    print("🔄 [实时更新] 为在线用户", targetPlayerName, "更新会员状态")

                    -- 异步刷新目标用户的数据并通知状态变更
                    local UserService = require(script.Parent:WaitForChild("UserService"))
                    spawn(function()
                        -- 先清除目标用户的会员缓存
                        local UserDataService = require(script.Parent.Parent.data:WaitForChild("UserDataService"))
                        if UserDataService.clearMembershipCache then
                            UserDataService.clearMembershipCache(tostring(targetPlayer.UserId))
                            print("🧹 [实时更新] 已清除", targetPlayerName, "的会员缓存")
                        end

                        -- 等待短暂时间确保数据保存完成
                        task.wait(0.2)

                        -- 刷新用户数据
                        UserService.refreshPlayerData(targetPlayer)

                        -- 发送会员状态变更通知
                        if Events.User.MembershipStatusChanged then
                            task.wait(0.1) -- 再等待一点确保数据刷新完成
                            Events.User.MembershipStatusChanged:FireClient(targetPlayer, {
                                action = requestData.action,
                                success = true,
                                message = "您的会员状态已由管理员更新",
                                admin = player.Name
                            })
                            print("📤 [实时更新] 已通知", targetPlayerName, "会员状态变更")
                        end
                    end)
                    break
                end
            end
        end
    else
        print("❌ [错误] " .. player.Name .. " 管理用户会员失败")
    end
end

-- 处理获取用户交易历史
local function handleGetUserHistory(player: Player, targetPlayerName: string, page: number?, limit: number?)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试获取用户交易历史，但不是管理员")
        Events.Admin.GetUserHistory:FireClient(player, false, "权限不足")
        return
    end

    print("📜 [管理员] " .. player.Name .. " 正在获取 " .. targetPlayerName .. " 的交易历史")

    local adminUserId = tostring(player.UserId)
    local success, message, data = DataService.getUserHistory(adminUserId, targetPlayerName, page or 1, limit or 50)

    Events.Admin.GetUserHistory:FireClient(player, success, message, data)

    if success then
        print("✅ [管理员] 成功获取 " .. targetPlayerName .. " 的交易历史")
    else
        print("❌ [错误] " .. player.Name .. " 获取交易历史失败: " .. (message or "未知错误"))
    end
end

-- 处理获取会员状态
local function handleGetMembershipStatus(player: Player, targetPlayerName: string)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试获取会员状态，但不是管理员")
        Events.Admin.GetMembershipStatus:FireClient(player, false, "权限不足")
        return
    end

    print("👤 [管理员] " .. player.Name .. " 正在获取 " .. targetPlayerName .. " 的会员状态")

    local adminUserId = tostring(player.UserId)
    local success, message, data = DataService.getAdminMembershipStatus(adminUserId, targetPlayerName)

    Events.Admin.GetMembershipStatus:FireClient(player, success, message, data)

    if success then
        print("✅ [管理员] 成功获取 " .. targetPlayerName .. " 的会员状态")
    else
        print("❌ [错误] " .. player.Name .. " 获取会员状态失败: " .. (message or "未知错误"))
    end
end

-- ==============================================
-- 清理函数
-- ==============================================

-- 清理玩家权限缓存
function AdminService.clearPlayerCache(userId: string)
    local cacheService = getCacheService()
    cacheService.Manager.invalidate(cacheService.Types.ADMIN_PERMISSIONS, userId)
    print("🧹 [AdminService] 已清理玩家权限缓存:", userId)
end

-- 清理所有过期缓存
function AdminService.cleanupExpiredCache()
    local cacheService = getCacheService()
    local cleanedCount = cacheService.Manager.cleanupExpired()

    if cleanedCount > 0 then
        print("🧹 [AdminService] 清理了", cleanedCount, "个过期缓存")
    end
end

function AdminService.cleanupPlayer(player: Player)
    if player and player.UserId then
        local userId = tostring(player.UserId)
        AdminService.clearPlayerCache(userId)
    end
end

-- ==============================================
-- 事件连接
-- ==============================================

-- 权限检查远程函数
Events.Admin.CheckPermission.OnServerInvoke = function(player)
    print("🔍 [AdminService] 收到权限检查请求:", player.Name)
    return AdminService.isValidAdmin(player)
end

-- 管理员事件
Events.Admin.GetAllUsers.OnServerEvent:Connect(handleGetAllUsers)
Events.Admin.SetUserCoins.OnServerEvent:Connect(handleSetUserCoins)
Events.Admin.GetMembersList.OnServerEvent:Connect(handleGetMembersList)
Events.Admin.GetAllUsersWithMembership.OnServerEvent:Connect(handleGetAllUsersWithMembership)
Events.Admin.GetUserHistory.OnServerEvent:Connect(handleGetUserHistory)
Events.Admin.GetMembershipStatus.OnServerEvent:Connect(handleGetMembershipStatus)
Events.Admin.UpdateMembership.OnServerEvent:Connect(handleUpdateMembership)
Events.Admin.AddMembership.OnServerEvent:Connect(handleAddMembership)
Events.Admin.CancelMembership.OnServerEvent:Connect(handleCancelMembership)
Events.Admin.ExtendMembership.OnServerEvent:Connect(handleExtendMembership)
Events.Admin.BatchMembershipOp.OnServerEvent:Connect(handleBatchMembershipOp)
Events.Admin.ManageUserMembership.OnServerEvent:Connect(handleManageUserMembership)




-- 注意：缓存清理现在由CacheManager自动处理

print("👑 管理员服务已启动")

return AdminService
