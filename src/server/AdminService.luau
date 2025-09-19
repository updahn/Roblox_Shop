--[[
管理员权限服务
负责处理管理员权限验证和配置管理
只在服务器端运行，通过RemoteFunction为客户端提供权限查询服务
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- 确保只在服务器端运行
if not RunService:IsServer() then
    error("AdminService 只能在服务器端运行")
end

local Config = require(ReplicatedStorage.Shared.Config)

local AdminService = {}

-- 管理员配置缓存
local adminCache = {
    usernames = {},
    lastUpdate = 0,
    cacheDuration = 300 -- 5分钟缓存
}

--[[
从API加载管理员配置
@return boolean - 是否成功加载
--]]
local function loadAdminConfigFromAPI()
    local success, result = pcall(function()
        local response = HttpService:GetAsync(Config.getApiUrl("/config"))
        return HttpService:JSONDecode(response)
    end)

    if success and result and result.success then
        local adminConfig = result.data and result.data.admin
        if adminConfig and adminConfig.usernames then
            adminCache.usernames = adminConfig.usernames
            adminCache.lastUpdate = tick()

            Config.log("INFO", "管理员配置已从API加载", {
                usernames = adminConfig.usernames,
                count = #adminConfig.usernames
            })
            return true
        end
    else
        Config.log("ERROR", "加载管理员配置失败", {
            success = success,
            result = result
        })
    end

    return false
end

--[[
确保管理员配置已加载且有效
@return boolean - 配置是否可用
--]]
local function ensureAdminConfigLoaded()
    local currentTime = tick()
    if #adminCache.usernames == 0 or
       (currentTime - adminCache.lastUpdate) > adminCache.cacheDuration then
        return loadAdminConfigFromAPI()
    end
    return true
end

--[[
检查玩家是否为管理员
@param player Player - 要检查的玩家
@return boolean - 是否为管理员
--]]
function AdminService.isPlayerAdmin(player)
    if not player or not player.Name then
        return false
    end

    -- 确保配置已加载
    if not ensureAdminConfigLoaded() then
        Config.log("WARN", "无法加载管理员配置")
        return false
    end

    -- 检查玩家是否在管理员列表中
    for _, adminName in pairs(adminCache.usernames) do
        if player.Name == adminName then
            Config.log("INFO", "管理员权限验证通过", {
                player = player.Name,
                userId = player.UserId
            })
            return true
        end
    end

    return false
end

--[[
获取当前管理员列表（仅供调试）
@return table - 管理员用户名列表
--]]
function AdminService.getAdminList()
    ensureAdminConfigLoaded()
    return adminCache.usernames
end

-- 创建RemoteFunction用于客户端查询
local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "CheckAdminPermission"
remoteFunction.Parent = ReplicatedStorage

-- 处理客户端的权限查询请求
remoteFunction.OnServerInvoke = function(player)
    return AdminService.isPlayerAdmin(player)
end

-- 初始化时预加载配置
spawn(function()
    wait(2) -- 等待游戏完全加载
    ensureAdminConfigLoaded()
    Config.log("INFO", "管理员服务已初始化")
end)

return AdminService
