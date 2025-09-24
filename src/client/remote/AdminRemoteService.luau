-- 管理员远程服务
-- 封装与服务端管理员相关的通信逻辑

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminRemoteService = {}

-- 缓存远程事件
local Events = nil
local RemoteEvents = {}

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
            print("✅ [AdminRemoteService] 管理员远程事件初始化成功")
        else
            warn("❌ [AdminRemoteService] 管理员远程事件初始化失败:", result)
        end
    end
end

-- 权限检查
function AdminRemoteService.checkPermission()
    initializeEvents()
    if RemoteEvents.CheckPermission then
        local success, result = pcall(function()
            return RemoteEvents.CheckPermission:InvokeServer()
        end)
        return success and result or false
    end
    return false
end

-- 获取所有用户
function AdminRemoteService.getAllUsers()
    initializeEvents()
    if RemoteEvents.GetAllUsers then
        RemoteEvents.GetAllUsers:FireServer()
    end
end

-- 设置用户金币
function AdminRemoteService.setUserCoins(userId, newCoins)
    initializeEvents()
    if RemoteEvents.SetUserCoins then
        RemoteEvents.SetUserCoins:FireServer(userId, newCoins)
    end
end

-- 获取用户历史
function AdminRemoteService.getUserHistory(userId)
    initializeEvents()
    if RemoteEvents.GetUserHistory then
        RemoteEvents.GetUserHistory:FireServer(userId)
    end
end

-- 会员管理相关方法
function AdminRemoteService.getMembersList()
    initializeEvents()
    if RemoteEvents.GetMembersList then
        RemoteEvents.GetMembersList:FireServer()
    end
end

function AdminRemoteService.getAllUsersWithMembership()
    initializeEvents()
    if RemoteEvents.GetAllUsersWithMembership then
        RemoteEvents.GetAllUsersWithMembership:FireServer()
    end
end

function AdminRemoteService.getMembershipStatus(userId)
    initializeEvents()
    if RemoteEvents.GetMembershipStatus then
        RemoteEvents.GetMembershipStatus:FireServer(userId)
    end
end

function AdminRemoteService.updateMembership(userId, membershipData)
    initializeEvents()
    if RemoteEvents.UpdateMembership then
        RemoteEvents.UpdateMembership:FireServer(userId, membershipData)
    end
end

function AdminRemoteService.addMembership(userId, membershipType, duration)
    initializeEvents()
    if RemoteEvents.AddMembership then
        RemoteEvents.AddMembership:FireServer(userId, membershipType, duration)
    end
end

function AdminRemoteService.cancelMembership(userId)
    initializeEvents()
    if RemoteEvents.CancelMembership then
        RemoteEvents.CancelMembership:FireServer(userId)
    end
end

function AdminRemoteService.extendMembership(userId, days)
    initializeEvents()
    if RemoteEvents.ExtendMembership then
        RemoteEvents.ExtendMembership:FireServer(userId, days)
    end
end

function AdminRemoteService.batchMembershipOperation(operation, userIds)
    initializeEvents()
    if RemoteEvents.BatchMembershipOp then
        RemoteEvents.BatchMembershipOp:FireServer(operation, userIds)
    end
end

function AdminRemoteService.manageUserMembership(userId, action, data)
    initializeEvents()
    if RemoteEvents.ManageUserMembership then
        RemoteEvents.ManageUserMembership:FireServer(userId, action, data)
    end
end

-- 监听服务端响应的方法
function AdminRemoteService.onAllUsersReceived(callback)
    initializeEvents()
    if RemoteEvents.GetAllUsers then
        RemoteEvents.GetAllUsers.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onUserCoinsSet(callback)
    initializeEvents()
    if RemoteEvents.SetUserCoins then
        RemoteEvents.SetUserCoins.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onUserHistoryReceived(callback)
    initializeEvents()
    if RemoteEvents.GetUserHistory then
        RemoteEvents.GetUserHistory.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onMembersListReceived(callback)
    initializeEvents()
    if RemoteEvents.GetMembersList then
        RemoteEvents.GetMembersList.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onAllUsersWithMembershipReceived(callback)
    initializeEvents()
    if RemoteEvents.GetAllUsersWithMembership then
        RemoteEvents.GetAllUsersWithMembership.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onMembershipStatusReceived(callback)
    initializeEvents()
    if RemoteEvents.GetMembershipStatus then
        RemoteEvents.GetMembershipStatus.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onMembershipUpdated(callback)
    initializeEvents()
    if RemoteEvents.UpdateMembership then
        RemoteEvents.UpdateMembership.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onMembershipAdded(callback)
    initializeEvents()
    if RemoteEvents.AddMembership then
        RemoteEvents.AddMembership.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onMembershipCancelled(callback)
    initializeEvents()
    if RemoteEvents.CancelMembership then
        RemoteEvents.CancelMembership.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onMembershipExtended(callback)
    initializeEvents()
    if RemoteEvents.ExtendMembership then
        RemoteEvents.ExtendMembership.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onBatchMembershipOpCompleted(callback)
    initializeEvents()
    if RemoteEvents.BatchMembershipOp then
        RemoteEvents.BatchMembershipOp.OnClientEvent:Connect(callback)
    end
end

function AdminRemoteService.onUserMembershipManaged(callback)
    initializeEvents()
    if RemoteEvents.ManageUserMembership then
        RemoteEvents.ManageUserMembership.OnClientEvent:Connect(callback)
    end
end

return AdminRemoteService
