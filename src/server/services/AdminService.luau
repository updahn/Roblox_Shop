-- 管理员服务模块
-- 处理管理员功能，包括用户管理、会员管理等

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local AdminService = {}

-- 等待模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))
-- 从services文件夹获取服务模块
local function getServiceModule(moduleName)
    local ServerScriptService = game:GetService("ServerScriptService")
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    if serverFolder then
        local servicesFolder = serverFolder:FindFirstChild("services")
        if servicesFolder and servicesFolder:FindFirstChild(moduleName) then
            return require(servicesFolder[moduleName])
        end
    end
    error("❌ 无法加载服务模块: " .. moduleName)
end

-- 直接加载同层级服务模块
local DataService = getServiceModule("DataService")
local CacheService = getServiceModule("CacheService")

-- ==============================================
-- 权限检查
-- ==============================================

-- 管理员权限验证函数（带缓存）
function AdminService.isValidAdmin(player: Player): boolean
    if not player or not player.UserId then
        return false
    end

    local userId = tostring(player.UserId)

    -- 检查缓存
    local cachedResult = CacheService.getAdminPermission(userId)
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
    CacheService.cacheAdminPermission(userId, finalIsAdmin, 180) -- 缓存3分钟

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
        Events.Admin.GetAllUsers:FireClient(player, false, "权限不足：您不是管理员", nil)
        return
    end

    local userId = tostring(player.UserId)
    print("👑 [调试] 管理员权限验证通过，开始认证检查")

    -- 检查用户是否已认证，如果没有则尝试自动认证
    local session = DataService.isAuthenticated(userId)
    if not session then
        print("👑 [调试] 管理员未认证，尝试自动认证")
        local authSuccess, userData = DataService.authenticateUser(userId, player.Name, player.DisplayName)
        if not authSuccess then
            print("❌ [认证失败] 管理员", player.Name, "认证失败")
            Events.Admin.GetAllUsers:FireClient(player, false, "认证失败，请重新进入游戏", nil)
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

        Events.Admin.GetAllUsers:FireClient(player, true, "成功获取用户数据", allPlayersData)
        print("👑 [管理员] " .. player.Name .. " 查看了所有用户数据")
    else
        local errorMessage = errorMsg or "无法获取用户数据"
        warn("❌ [数据错误] " .. errorMessage)

        -- 检查是否是认证问题
        if errorMsg and string.find(errorMsg, "认证") then
            print("❌ [认证问题] 管理员认证失败，发送认证错误")
            Events.Admin.GetAllUsers:FireClient(player, false, "认证失败：" .. errorMessage, nil)
            return
        end

        -- 如果数据服务不可用，发送错误信息给客户端
        print("👑 [调试] 数据服务不可用，发送错误信息给客户端")
        local detailedError = string.format(
            "数据加载失败：%s\n\n可能的原因：\n• 数据存储服务异常\n• 网络连接问题\n• 权限配置错误\n\n请稍后重试或联系管理员",
            errorMessage
        )
        Events.Admin.GetAllUsers:FireClient(player, false, detailedError, nil)

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
                task.wait(0.3) -- 稍等片刻确保数据已保存

                -- 先清除用户缓存，确保获取到最新数据
                CacheService.refreshUserCache(tostring(targetPlayer.UserId), false)

                -- 通过DataService获取完整的用户数据，包括交易记录
                local userData = DataService.getUserData(tostring(targetPlayer.UserId))
                local inventory = DataService.getUserInventory(tostring(targetPlayer.UserId))
                local membershipStatus = DataService.getMembershipStatus(tostring(targetPlayer.UserId))

                -- 获取用户交易记录
                local transactionSuccess, transactionData, _ = DataService.getUserTransactions(tostring(targetPlayer.UserId), 20, 0, nil)

                if userData then
                    print("💰 [数据同步] 获取到 " .. targetPlayerName .. " 的最新金币数据:", userData.coins)

                    -- 构造完整的玩家数据，包含最新的交易记录
                    local playerData = {
                        coins = userData.coins,
                        inventory = inventory or {},
                        membership = membershipStatus or {
                            hasMembership = false,
                            isValid = false,
                            daysRemaining = 0,
                            membershipType = nil,
                            startDate = nil,
                            endDate = nil,
                            dailyReward = 0
                        },
                        stats = {
                            totalPurchases = userData.total_purchases or 0,
                            totalSales = userData.total_sales or 0,
                            totalSpent = userData.total_spent or 0,
                            totalEarned = userData.total_earned or 0
                        },
                        transactionHistory = {}
                    }

                    -- 添加交易记录到玩家数据中
                    if transactionSuccess and transactionData and transactionData.transactions then
                        for _, transaction in ipairs(transactionData.transactions) do
                            -- 确保时间戳字段存在和正确
                            local createdAt = transaction.created_at or transaction.timestamp or os.time()
                            local transactionDate = transaction.transaction_date or os.date("%Y-%m-%d", createdAt)

                            table.insert(playerData.transactionHistory, {
                                id = transaction.id,
                                itemId = transaction.item_id,
                                itemName = transaction.item_name,
                                type = transaction.type,
                                quantity = transaction.quantity,
                                unitPrice = transaction.unit_price,
                                totalAmount = transaction.total_amount,
                                transactionDate = transactionDate,
                                createdAt = createdAt,
                                timestamp = createdAt -- 为了兼容性
                            })
                        end
                    end

                    -- 通过GetPlayerData事件发送完整数据更新
                    Events.User.GetPlayerData:FireClient(targetPlayer, true, playerData)
                    print("✅ [数据同步] 已通知 " .. targetPlayerName .. " 完整数据刷新 | 金币: " .. playerData.coins .. " | 交易记录: " .. #playerData.transactionHistory .. " 条")
                else
                    -- 发送失败的刷新响应
                    Events.User.RefreshData:FireClient(targetPlayer, false, {
                        message = "数据刷新失败"
                    })
                    print("❌ [数据同步] " .. targetPlayerName .. " 数据刷新失败")
                end
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
        Events.Admin.GetMembersList:FireClient(player, false, "权限不足", {error = "权限不足"})
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, response = DataService.getMembersList(adminUserId, page, limit, status)

    if success then
        Events.Admin.GetMembersList:FireClient(player, true, "成功获取会员列表", response)
    else
        local errorMessage = "获取会员列表失败"
        if response and response.error then
            errorMessage = response.error
        end
        Events.Admin.GetMembersList:FireClient(player, false, errorMessage, response)
    end

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
        Events.Admin.GetAllUsersWithMembership:FireClient(player, false, "权限不足", {error = "权限不足"})
        return
    end

    local adminUserId = tostring(player.UserId)
    local success, response = DataService.getAllUsersWithMembership(adminUserId, page, limit, status)

    if success then
        -- 确保响应格式正确
        Events.Admin.GetAllUsersWithMembership:FireClient(player, true, "成功获取会员数据", response)
    else
        -- 处理失败情况，确保message字段存在
        local errorMessage = "获取会员数据失败"
        if response and response.message then
            errorMessage = response.message
        elseif response and response.error then
            errorMessage = response.error
        end
        Events.Admin.GetAllUsersWithMembership:FireClient(player, false, errorMessage, response)
    end

    if success then
        print("👑 [管理员] " .. player.Name .. " 查看了所有用户会员状态")
    else
        print("❌ [错误] " .. player.Name .. " 获取用户会员状态失败")
    end
end

local function handleManageUserMembership(player: Player, requestData)
    if not AdminService.isValidAdmin(player) then
        print("⚠️ [权限警告] " .. player.Name .. " 尝试管理用户会员，但不是管理员")
        Events.Admin.ManageUserMembership:FireClient(player, false, {error = "权限不足", message = "权限不足"})
        return
    end

    print("🔧 [HandleManageUserMembership] 收到请求数据:", HttpService:JSONEncode(requestData))

    local adminUserId = tostring(player.UserId)
    local success, response = DataService.manageUserMembership(adminUserId, requestData)

    -- 确保响应格式正确
    if success and response then
        if response.success then
            print("👑 [管理员] " .. player.Name .. " 管理了用户会员状态")
            Events.Admin.ManageUserMembership:FireClient(player, true, response.message or "操作成功", response)
        else
            local errorMsg = response.error or response.message or "操作失败"
            print("❌ [错误] " .. player.Name .. " 管理用户会员失败:", errorMsg)
            Events.Admin.ManageUserMembership:FireClient(player, false, errorMsg, {
                error = errorMsg,
                message = errorMsg,
                success = false
            })
        end
    else
        local errorMsg = "服务器内部错误"
        if response then
            errorMsg = response.error or response.message or errorMsg
        end
        print("❌ [错误] " .. player.Name .. " 管理用户会员失败:", errorMsg)
        Events.Admin.ManageUserMembership:FireClient(player, false, errorMsg, {
            error = errorMsg,
            message = errorMsg,
            success = false
        })
    end

    -- 如果操作成功，实时更新目标用户的状态
    if success and response and response.success then
        local targetPlayerName = requestData.playerName or requestData.username
        if targetPlayerName then
            -- 查找在线的目标玩家
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer.Name == targetPlayerName then
                    print("🔄 [实时更新] 为在线用户", targetPlayerName, "更新会员状态")

                    -- 异步刷新目标用户的数据并通知状态变更
                    spawn(function()
                        -- 先清除目标用户的会员缓存
                        local UserDataService = require(game:GetService("ServerScriptService").Server.datastoreservice:WaitForChild("UserDataService"))
                        if UserDataService.clearMembershipCache then
                            UserDataService.clearMembershipCache(tostring(targetPlayer.UserId))
                            print("🧹 [实时更新] 已清除", targetPlayerName, "的会员缓存")
                        end

                        -- 等待短暂时间确保数据保存完成
                        task.wait(0.3)

                        -- 通过DataService刷新用户数据（不依赖UserService）
                        CacheService.refreshUserCache(tostring(targetPlayer.UserId))

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
