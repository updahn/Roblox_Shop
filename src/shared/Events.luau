local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = {}

-- 创建事件文件夹
local eventsFolder = ReplicatedStorage:FindFirstChild("ShopEvents")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "ShopEvents"
    eventsFolder.Parent = ReplicatedStorage
end

-- 创建远程事件的辅助函数
local function createRemoteEvent(name)
    local event = eventsFolder:FindFirstChild(name)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = eventsFolder
    end
    return event
end

-- 创建远程函数的辅助函数
local function createRemoteFunction(name)
    local func = eventsFolder:FindFirstChild(name)
    if not func then
        func = Instance.new("RemoteFunction")
        func.Name = name
        func.Parent = eventsFolder
    end
    return func
end

-- ==============================================
-- 普通用户事件
-- ==============================================
Events.User = {
    -- 数据相关
    GetPlayerData = createRemoteEvent("GetPlayerData"),
    GetShopData = createRemoteEvent("GetShopData"),
    GetTransactions = createRemoteEvent("GetTransactions"),

    -- 交易相关
    BuyItem = createRemoteEvent("BuyItem"),
    SellItem = createRemoteEvent("SellItem"),

    -- 通用功能
    RefreshData = createRemoteEvent("RefreshData"),

    -- 会员状态通知
    MembershipStatusChanged = createRemoteEvent("MembershipStatusChanged"),
}

-- ==============================================
-- 管理员事件
-- ==============================================
Events.Admin = {
    -- 用户管理
    GetAllUsers = createRemoteEvent("AdminGetAllUsers"),
    SetUserCoins = createRemoteEvent("AdminSetUserCoins"),
    GetUserHistory = createRemoteEvent("AdminGetUserHistory"),

    -- 会员管理
    GetMembersList = createRemoteEvent("AdminGetMembersList"),
    GetAllUsersWithMembership = createRemoteEvent("AdminGetAllUsersWithMembership"),
    GetMembershipStatus = createRemoteEvent("AdminGetMembershipStatus"),
    UpdateMembership = createRemoteEvent("AdminUpdateMembership"),
    AddMembership = createRemoteEvent("AdminAddMembership"),
    CancelMembership = createRemoteEvent("AdminCancelMembership"),
    ExtendMembership = createRemoteEvent("AdminExtendMembership"),
    BatchMembershipOp = createRemoteEvent("AdminBatchMembershipOp"),
    ManageUserMembership = createRemoteEvent("AdminManageUserMembership"),

    -- 权限检查
    CheckPermission = createRemoteFunction("AdminCheckPermission"),
}

-- ==============================================
-- 无人机事件
-- ==============================================
Events.Drone = {
    -- 无人机控制
    SpawnDrone = createRemoteEvent("SpawnDrone"),
    RecallDrone = createRemoteEvent("RecallDrone"),
    SwitchDroneMode = createRemoteEvent("SwitchDroneMode"),

    -- 客户端回调事件
    DroneSpawned = createRemoteEvent("DroneSpawned"),
    DroneRecalled = createRemoteEvent("DroneRecalled"),
    DroneModeChanged = createRemoteEvent("DroneModeChanged"),
    DroneDestroyed = createRemoteEvent("DroneDestroyed"),
    DroneAttack = createRemoteEvent("DroneAttack"),
}

-- ==============================================
-- 靶子系统事件
-- ==============================================
Events.Target = {
    -- 靶子状态事件
    TargetCreated = createRemoteEvent("TargetCreated"),
    TargetDestroyed = createRemoteEvent("TargetDestroyed"),
    TargetDamaged = createRemoteEvent("TargetDamaged"),
    TargetRespawned = createRemoteEvent("TargetRespawned"),

    -- 靶子信息请求
    RequestTargetStatus = createRemoteEvent("RequestTargetStatus"),
    TargetStatusUpdate = createRemoteEvent("TargetStatusUpdate"),
}

-- ==============================================
-- 缓存同步事件
-- ==============================================
Events.Cache = {
    -- 数据刷新通知（服务端 -> 客户端）
    DataRefreshNotify = createRemoteEvent("CacheDataRefreshNotify"),

    -- 用户数据更新通知
    UserDataUpdated = createRemoteEvent("CacheUserDataUpdated"),

    -- 商店数据更新通知
    ShopDataUpdated = createRemoteEvent("CacheShopDataUpdated"),

    -- 会员状态更新通知
    MembershipUpdated = createRemoteEvent("CacheMembershipUpdated"),

    -- 系统配置更新通知
    SystemConfigUpdated = createRemoteEvent("CacheSystemConfigUpdated"),

    -- 强制刷新请求（客户端 -> 服务端）
    ForceRefresh = createRemoteEvent("CacheForceRefresh"),

    -- 缓存统计信息请求（管理员功能）
    GetCacheStats = createRemoteFunction("CacheGetStats"),

    -- 缓存管理操作（管理员功能）
    ManageCache = createRemoteEvent("CacheManageCache")
}

-- 删除了向后兼容代码 - 使用新的分离式事件结构

print("📡 商店事件系统已初始化 (简化版)")

return Events
