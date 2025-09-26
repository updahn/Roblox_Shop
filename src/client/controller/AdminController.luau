-- 管理员控制器 - 重构版本
-- 负责管理员相关的业务逻辑处理，不直接访问UI
-- 通过事件系统与UI层通信，实现分层架构

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminController = {}

-- 缓存远程事件
local Events = nil
local RemoteEvents = {}

-- 管理员数据事件系统（供UI监听）
local AdminDataEvents = {
    AllUsersReceived = Instance.new("BindableEvent"),
    UserCoinsSet = Instance.new("BindableEvent"),
    UserHistoryReceived = Instance.new("BindableEvent"),
    MembersListReceived = Instance.new("BindableEvent"),
    AllUsersWithMembershipReceived = Instance.new("BindableEvent"),
    MembershipStatusReceived = Instance.new("BindableEvent"),
    MembershipUpdated = Instance.new("BindableEvent"),
    MembershipAdded = Instance.new("BindableEvent"),
    MembershipCancelled = Instance.new("BindableEvent"),
    MembershipExtended = Instance.new("BindableEvent"),
    BatchMembershipOpCompleted = Instance.new("BindableEvent"),
    UserMembershipManaged = Instance.new("BindableEvent"),
    PermissionChecked = Instance.new("BindableEvent")
}

-- 导出事件供UI层监听
AdminController.Events = {}
for eventName, event in pairs(AdminDataEvents) do
    AdminController.Events[eventName] = event.Event
end

-- 初始化远程事件
local function initializeEvents()
    if not Events then
        local success, result = pcall(function()
            local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", 10)
            if not SharedModules then
                error("❌ 无法找到SharedModules文件夹")
            end
            local EventsModule = SharedModules:WaitForChild("ShopEvents", 10)
            if not EventsModule then
                error("❌ 无法找到ShopEvents模块")
            end
            return require(EventsModule)
        end)

        if success then
            Events = result
            RemoteEvents = {
                GetAllUsers = Events.Admin.GetAllUsers,
                SetUserCoins = Events.Admin.SetUserCoins,
                GetUserHistory = Events.Admin.GetUserHistory,
                GetMembersList = Events.Admin.GetMembersList,
                GetAllUsersWithMembership = Events.Admin.GetAllUsersWithMembership,
                GetMembershipStatus = Events.Admin.GetMembershipStatus,
                UpdateMembership = Events.Admin.UpdateMembership,
                AddMembership = Events.Admin.AddMembership,
                CancelMembership = Events.Admin.CancelMembership,
                ExtendMembership = Events.Admin.ExtendMembership,
                BatchMembershipOp = Events.Admin.BatchMembershipOp,
                ManageUserMembership = Events.Admin.ManageUserMembership,
                CheckPermission = Events.Admin.CheckPermission
            }
            print("✅ [AdminController] 管理员远程事件初始化成功")
        else
            warn("❌ [AdminController] 管理员远程事件初始化失败:", result)
        end
    end
end

-- ==============================================
-- 权限管理
-- ==============================================

-- 权限检查
function AdminController.checkPermission()
    initializeEvents()
    if RemoteEvents.CheckPermission then
        local success, result = pcall(function()
            return RemoteEvents.CheckPermission:InvokeServer()
        end)
        local hasPermission = success and result or false
        AdminDataEvents.PermissionChecked:Fire(hasPermission)
        return hasPermission
    end
    return false
end

-- ==============================================
-- 用户管理功能
-- ==============================================

-- 获取所有用户
function AdminController.getAllUsers()
    initializeEvents()
    if RemoteEvents.GetAllUsers then
        RemoteEvents.GetAllUsers:FireServer()
        print("📡 [AdminController] 请求获取所有用户")
    end
end

-- 设置用户金币
function AdminController.setUserCoins(userId, newCoins)
    initializeEvents()
    if RemoteEvents.SetUserCoins then
        RemoteEvents.SetUserCoins:FireServer(userId, newCoins)
        print("💰 [AdminController] 设置用户金币:", userId, newCoins)
    end
end

-- 获取用户历史记录
function AdminController.getUserHistory(userId)
    initializeEvents()
    if RemoteEvents.GetUserHistory then
        RemoteEvents.GetUserHistory:FireServer(userId)
        print("📊 [AdminController] 请求用户历史记录:", userId)
    end
end

-- ==============================================
-- 会员管理功能
-- ==============================================

-- 获取会员列表
function AdminController.getMembersList()
    initializeEvents()
    if RemoteEvents.GetMembersList then
        RemoteEvents.GetMembersList:FireServer()
        print("👑 [AdminController] 请求获取会员列表")
    end
end

-- 获取所有用户的会员信息
function AdminController.getAllUsersWithMembership()
    initializeEvents()
    if RemoteEvents.GetAllUsersWithMembership then
        RemoteEvents.GetAllUsersWithMembership:FireServer()
        print("👑 [AdminController] 请求获取所有用户会员信息")
    end
end

-- 获取用户会员状态
function AdminController.getMembershipStatus(userId)
    initializeEvents()
    if RemoteEvents.GetMembershipStatus then
        RemoteEvents.GetMembershipStatus:FireServer(userId)
        print("👑 [AdminController] 请求用户会员状态:", userId)
    end
end

-- 更新用户会员信息
function AdminController.updateMembership(userId, membershipData)
    initializeEvents()
    if RemoteEvents.UpdateMembership then
        RemoteEvents.UpdateMembership:FireServer(userId, membershipData)
        print("👑 [AdminController] 更新用户会员信息:", userId)
    end
end

-- 添加用户会员
function AdminController.addMembership(userId, membershipType, duration)
    initializeEvents()
    if RemoteEvents.AddMembership then
        RemoteEvents.AddMembership:FireServer(userId, membershipType, duration)
        print("👑 [AdminController] 添加用户会员:", userId, membershipType, duration)
    end
end

-- 取消用户会员
function AdminController.cancelMembership(userId)
    initializeEvents()
    if RemoteEvents.CancelMembership then
        RemoteEvents.CancelMembership:FireServer(userId)
        print("👑 [AdminController] 取消用户会员:", userId)
    end
end

-- 延长用户会员
function AdminController.extendMembership(userId, days)
    initializeEvents()
    if RemoteEvents.ExtendMembership then
        RemoteEvents.ExtendMembership:FireServer(userId, days)
        print("👑 [AdminController] 延长用户会员:", userId, days, "天")
    end
end

-- 批量会员操作
function AdminController.batchMembershipOperation(operation, userIds)
    initializeEvents()
    if RemoteEvents.BatchMembershipOp then
        RemoteEvents.BatchMembershipOp:FireServer(operation, userIds)
        print("👑 [AdminController] 批量会员操作:", operation, "用户数量:", #userIds)
    end
end

-- 管理用户会员
function AdminController.manageUserMembership(requestData)
    initializeEvents()
    if RemoteEvents.ManageUserMembership then
        RemoteEvents.ManageUserMembership:FireServer(requestData)
        print("👑 [AdminController] 管理用户会员:", requestData.userId or requestData.playerName, requestData.action)
    end
end

-- ==============================================
-- 事件监听和处理
-- ==============================================

local eventConnections = {}

-- 初始化事件监听器
function AdminController.initializeEventListeners()
    initializeEvents()

    -- 监听所有用户响应
    if RemoteEvents.GetAllUsers then
        eventConnections.getAllUsers = RemoteEvents.GetAllUsers.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 获取所有用户成功")
                AdminDataEvents.AllUsersReceived:Fire(success, message, data)
            else
                warn("❌ [AdminController] 获取所有用户失败:", message)
                AdminDataEvents.AllUsersReceived:Fire(success, message, nil)
            end
        end)
    end

    -- 监听设置用户金币响应
    if RemoteEvents.SetUserCoins then
        eventConnections.setUserCoins = RemoteEvents.SetUserCoins.OnClientEvent:Connect(function(success, message)
            if success then
                print("✅ [AdminController] 设置用户金币成功:", message)
            else
                warn("❌ [AdminController] 设置用户金币失败:", message)
            end
            AdminDataEvents.UserCoinsSet:Fire(success, message)
        end)
    end

    -- 监听用户历史记录响应
    if RemoteEvents.GetUserHistory then
        eventConnections.getUserHistory = RemoteEvents.GetUserHistory.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 获取用户历史记录成功")
                AdminDataEvents.UserHistoryReceived:Fire(success, message, data)
            else
                warn("❌ [AdminController] 获取用户历史记录失败:", message)
                AdminDataEvents.UserHistoryReceived:Fire(success, message, nil)
            end
        end)
    end

    -- 监听会员列表响应
    if RemoteEvents.GetMembersList then
        eventConnections.getMembersList = RemoteEvents.GetMembersList.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 获取会员列表成功")
                AdminDataEvents.MembersListReceived:Fire(success, message, data)
            else
                warn("❌ [AdminController] 获取会员列表失败:", message)
                AdminDataEvents.MembersListReceived:Fire(success, message, nil)
            end
        end)
    end

    -- 监听所有用户会员信息响应
    if RemoteEvents.GetAllUsersWithMembership then
        eventConnections.getAllUsersWithMembership = RemoteEvents.GetAllUsersWithMembership.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 获取所有用户会员信息成功")
                AdminDataEvents.AllUsersWithMembershipReceived:Fire(success, message, data)
            else
                warn("❌ [AdminController] 获取所有用户会员信息失败:", message)
                AdminDataEvents.AllUsersWithMembershipReceived:Fire(success, message, nil)
            end
        end)
    end

    -- 监听用户会员状态响应
    if RemoteEvents.GetMembershipStatus then
        eventConnections.getMembershipStatus = RemoteEvents.GetMembershipStatus.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 获取用户会员状态成功")
                AdminDataEvents.MembershipStatusReceived:Fire(success, message, data)
            else
                warn("❌ [AdminController] 获取用户会员状态失败:", message)
                AdminDataEvents.MembershipStatusReceived:Fire(success, message, nil)
            end
        end)
    end

    -- 监听更新会员响应
    if RemoteEvents.UpdateMembership then
        eventConnections.updateMembership = RemoteEvents.UpdateMembership.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 更新用户会员成功:", message)
            else
                warn("❌ [AdminController] 更新用户会员失败:", message)
            end
            AdminDataEvents.MembershipUpdated:Fire(success, message, data)
        end)
    end

    -- 监听添加会员响应
    if RemoteEvents.AddMembership then
        eventConnections.addMembership = RemoteEvents.AddMembership.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 添加用户会员成功:", message)
            else
                warn("❌ [AdminController] 添加用户会员失败:", message)
            end
            AdminDataEvents.MembershipAdded:Fire(success, message, data)
        end)
    end

    -- 监听取消会员响应
    if RemoteEvents.CancelMembership then
        eventConnections.cancelMembership = RemoteEvents.CancelMembership.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 取消用户会员成功:", message)
            else
                warn("❌ [AdminController] 取消用户会员失败:", message)
            end
            AdminDataEvents.MembershipCancelled:Fire(success, message, data)
        end)
    end

    -- 监听延长会员响应
    if RemoteEvents.ExtendMembership then
        eventConnections.extendMembership = RemoteEvents.ExtendMembership.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 延长用户会员成功:", message)
            else
                warn("❌ [AdminController] 延长用户会员失败:", message)
            end
            AdminDataEvents.MembershipExtended:Fire(success, message, data)
        end)
    end

    -- 监听批量会员操作响应
    if RemoteEvents.BatchMembershipOp then
        eventConnections.batchMembershipOp = RemoteEvents.BatchMembershipOp.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 批量会员操作成功:", message)
            else
                warn("❌ [AdminController] 批量会员操作失败:", message)
            end
            AdminDataEvents.BatchMembershipOpCompleted:Fire(success, message, data)
        end)
    end

    -- 监听用户会员管理响应
    if RemoteEvents.ManageUserMembership then
        eventConnections.manageUserMembership = RemoteEvents.ManageUserMembership.OnClientEvent:Connect(function(success, message, data)
            if success then
                print("✅ [AdminController] 用户会员管理成功:", message)
            else
                warn("❌ [AdminController] 用户会员管理失败:", message)
            end
            AdminDataEvents.UserMembershipManaged:Fire(success, message, data)
        end)
    end

    print("✅ [AdminController] 事件监听器初始化完成")
end

-- ==============================================
-- 高级管理功能
-- ==============================================

-- 处理管理员操作
function AdminController.handleAdminAction(action, data)
    if action == "check_permission" then
        return AdminController.checkPermission()

    elseif action == "get_all_users" then
        AdminController.getAllUsers()

    elseif action == "set_user_coins" then
        AdminController.setUserCoins(data.userId, data.coins)

    elseif action == "get_user_history" then
        AdminController.getUserHistory(data.userId)

    elseif action == "get_members_list" then
        AdminController.getMembersList()

    elseif action == "add_membership" then
        AdminController.addMembership(data.userId, data.membershipType, data.duration)

    elseif action == "cancel_membership" then
        AdminController.cancelMembership(data.userId)

    elseif action == "extend_membership" then
        AdminController.extendMembership(data.userId, data.days)

    else
        warn("❌ [AdminController] 未知管理员操作:", action)
    end
end

-- ==============================================
-- 初始化和清理
-- ==============================================

-- 初始化管理员控制器
function AdminController.initialize()
    print("🚀 [AdminController] 开始初始化...")

    -- 初始化事件监听
    AdminController.initializeEventListeners()

    print("✅ [AdminController] 初始化完成")
end

-- 清理资源
function AdminController.cleanup()
    -- 断开所有事件连接
    for _, connection in pairs(eventConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    eventConnections = {}

    print("🧹 [AdminController] 资源已清理")
end

return AdminController
