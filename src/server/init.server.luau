-- 商店系统服务端主启动脚本
-- 这是Roblox自动执行的主服务端脚本

print("🚀 [服务端] 商店系统正在启动...")

-- 第一步：启动DataStore服务（顶级数据服务）
print("📦 启动DataStore服务...")

-- 获取DataStore管理器模块
local function getDataStoreManager()
    local ServerScriptService = game:GetService("ServerScriptService")
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    if serverFolder then
        local datastoreFolder = serverFolder:FindFirstChild("datastoreservice")
        if datastoreFolder and datastoreFolder:FindFirstChild("DataStoreManager") then
            return require(datastoreFolder.DataStoreManager)
        end
    end
    error("❌ 无法找到DataStore管理器模块")
end

local DataStoreManager = getDataStoreManager()

-- 第二步：设置共享模块
local setupScript = nil

-- 从utils文件夹获取SetupReplicatedStorage
local success, result = pcall(function()
    local ServerScriptService = game:GetService("ServerScriptService")
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    if serverFolder then
        local srcFolder = serverFolder.Parent
        local utilsFolder = srcFolder:FindFirstChild("utils")
        if utilsFolder and utilsFolder:FindFirstChild("SetupReplicatedStorage") then
            return utilsFolder.SetupReplicatedStorage
        end
    end
    return nil
end)

if success and result then
    setupScript = result
    require(setupScript)
    print("✅ 共享模块设置完成")
else
    warn("⚠️ 找不到SetupReplicatedStorage脚本")
end

-- 等待一帧，确保模块已创建
game:GetService("RunService").Heartbeat:Wait()

-- 第三步：启动业务服务
print("🔧 启动业务服务...")

-- 获取服务模块的辅助函数
local function getServiceModule(serviceName)
    local ServerScriptService = game:GetService("ServerScriptService")
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    if serverFolder then
        local servicesFolder = serverFolder:FindFirstChild("services")
        if servicesFolder and servicesFolder:FindFirstChild(serviceName) then
            return require(servicesFolder[serviceName])
        end
    end
    error("❌ 无法找到服务模块: " .. serviceName)
end

local services = {
    AdminService = getServiceModule("AdminService"),
    CacheService = getServiceModule("CacheService"),
    DataService = getServiceModule("DataService"),
    DroneService = getServiceModule("DroneService"),
    UserService = getServiceModule("UserService"),
    TargetService = getServiceModule("TargetService")
}

-- 第四步：启动功能模块
print("⚙️ 启动功能模块...")

-- 获取Bootstrap模块
local function getBootstrap()
    local ServerScriptService = game:GetService("ServerScriptService")
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    if serverFolder then
        local functionsFolder = serverFolder:FindFirstChild("functions")
        if functionsFolder and functionsFolder:FindFirstChild("Bootstrap") then
            return require(functionsFolder.Bootstrap)
        end
    end
    error("❌ 无法找到Bootstrap模块")
end

local Bootstrap = getBootstrap()

-- 初始化靶子系统
if services.TargetService and services.TargetService.initialize then
    services.TargetService.initialize()
    print("🎯 靶子系统已初始化")
else
    warn("⚠️ TargetService 未找到或缺少 initialize 方法")
end

print("✅ [服务端] 商店系统已完全启动")
