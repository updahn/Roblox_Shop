-- DataStore顶级服务入口
-- 负责玩家数据加载和数据持久化管理

print("🚀 [DataStoreService] 数据服务启动中...")

-- 获取DataStore服务模块的辅助函数
local function getDataStoreModule(moduleName)
    local ServerScriptService = game:GetService("ServerScriptService")
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    if serverFolder then
        local datastoreFolder = serverFolder:FindFirstChild("datastoreservice")
        if datastoreFolder and datastoreFolder:FindFirstChild(moduleName) then
            return require(datastoreFolder[moduleName])
        end
    end
    error("❌ 无法加载数据服务模块: " .. moduleName)
end

-- 初始化DataStore管理器
local DataStoreManager = getDataStoreModule("DataStoreManager")
DataStoreManager.initialize()

-- 初始化用户数据服务
local UserDataService = getDataStoreModule("UserDataService")

-- 初始化管理员数据服务
local AdminDataService = getDataStoreModule("AdminDataService")

print("✅ [DataStoreService] 数据服务启动完成")

-- 导出服务模块供其他服务使用
return {
    DataStoreManager = DataStoreManager,
    UserDataService = UserDataService,
    AdminDataService = AdminDataService
}
