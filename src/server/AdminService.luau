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

local Config = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Config"))

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
确保管理员配置已加载
@return boolean - 配置是否可用
--]]
local function ensureAdminConfigLoaded()
    local currentTime = tick()

    -- 如果缓存过期或为空，尝试重新加载
    if currentTime - adminCache.lastUpdate > adminCache.cacheDuration or #adminCache.usernames == 0 then
        print("🔄 [调试] 管理员配置缓存过期，尝试重新加载")
        if loadAdminConfigFromAPI() then
            print("✅ [调试] 管理员配置重新加载成功")
        else
            print("❌ [调试] 管理员配置重新加载失败，使用现有缓存")
        end
    end

    return #adminCache.usernames > 0
end

--[[
本地检查玩家是否为管理员
@param player Player - 玩家对象
@return boolean - 是否为管理员
--]]
function AdminService.isPlayerAdminLocal(player)
    if not player or not player.Name then
        return false
    end

    -- 确保配置已加载
    if not ensureAdminConfigLoaded() then
        print("⚠️ [调试] 管理员配置未加载，无法进行本地检查")
        return false
    end

    -- 检查玩家名是否在管理员列表中
    for _, adminName in pairs(adminCache.usernames) do
        if player.Name == adminName then
            return true
        end
    end

    return false
end

--[[
检查玩家是否为管理员
优先使用本地检查，避免HTTP请求阻塞RemoteFunction
@param player Player - 要检查的玩家
@return boolean - 是否为管理员
--]]
function AdminService.isPlayerAdmin(player)
    if not player or not player.UserId then
        return false
    end

    print("🔍 [调试] 检查管理员权限:", player.Name)

    -- 直接使用本地检查，避免HTTP请求阻塞
    local isLocalAdmin = AdminService.isPlayerAdminLocal(player)
    if isLocalAdmin then
        print("⚡ [调试] " .. player.Name .. " 通过本地验证确认为管理员")
        return true
    end

    print("❌ [调试] " .. player.Name .. " 不是管理员（本地检查）")
    return false
end

--[[
获取所有管理员用户名列表
@return table - 管理员用户名数组
--]]
function AdminService.getAdminUsernames()
    ensureAdminConfigLoaded()
    return adminCache.usernames
end

--[[
手动刷新管理员配置缓存
@return boolean - 是否刷新成功
--]]
function AdminService.refreshAdminCache()
    print("🔄 [调试] 手动刷新管理员配置缓存")
    adminCache.lastUpdate = 0 -- 强制过期
    return ensureAdminConfigLoaded()
end

--[[
异步刷新管理员配置缓存（不阻塞调用）
--]]
function AdminService.refreshAdminCacheAsync(player)
    spawn(function()
        print("🔄 [调试] 异步刷新管理员配置缓存")
        AdminService.refreshAdminCache()

        -- 重新检查该玩家权限
        if player and AdminService.isPlayerAdminLocal(player) then
            print("✅ [调试] 异步更新后确认", player.Name, "为管理员")
        end
    end)
end

-- 使用Events系统进行权限查询
local Events = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ShopEvents"))

-- 处理客户端的权限查询请求
if Events.Admin.CheckPermission then
    Events.Admin.CheckPermission.OnServerInvoke = function(player)
        print("🔄 [调试] 服务端收到管理员权限查询请求:", player.Name)

        -- 优先使用本地缓存进行快速检查，完全避免HTTP请求阻塞RemoteFunction
        local success, result = pcall(function()
            -- 确保本地缓存已加载，如果没有则尝试快速加载
            if #adminCache.usernames == 0 and tick() - adminCache.lastUpdate > 2 then
                -- 使用非阻塞方式尝试快速加载
                spawn(function()
                    loadAdminConfigFromAPI()
                end)
            end

            return AdminService.isPlayerAdminLocal(player)
        end)

        if success then
            print("✅ [调试] 权限查询完成:", player.Name, "结果:", result)

            -- 如果本地缓存为空或过期，异步刷新缓存（不阻塞当前请求）
            if #adminCache.usernames == 0 or tick() - adminCache.lastUpdate > adminCache.cacheDuration then
                spawn(function()
                    print("🔄 [调试] 异步刷新管理员配置缓存")
                    loadAdminConfigFromAPI()

                    -- 重新检查该玩家权限
                    if AdminService.isPlayerAdminLocal(player) then
                        print("✅ [调试] 异步更新后确认", player.Name, "为管理员")
                    end
                end)
            end

            return result
        else
            print("❌ [调试] 权限查询出错:", player.Name, "错误:", result)
            -- 出错时返回false，但不阻塞
            return false
        end
    end
    print("✅ [调试] AdminService CheckPermission RemoteFunction 已连接")
else
    print("❌ [调试] 警告: CheckPermission RemoteFunction 未找到")
end

-- 初始化时预加载配置
spawn(function()
    wait(2) -- 等待游戏完全加载
    print("🚀 [调试] 开始初始化 AdminService...")

    -- 多次尝试加载管理员配置
    local loadAttempts = 0
    local maxAttempts = 5

    while loadAttempts < maxAttempts do
        loadAttempts = loadAttempts + 1
        print("🔄 [调试] 尝试加载管理员配置 (第" .. loadAttempts .. "/" .. maxAttempts .. "次)")

        if loadAdminConfigFromAPI() then
            print("✅ [调试] 管理员配置加载成功，当前管理员列表:")
            for i, username in pairs(adminCache.usernames) do
                print("  " .. i .. ": " .. tostring(username))
            end
            break
        else
            print("❌ [调试] 管理员配置加载失败，等待2秒后重试...")
            wait(2)
        end
    end

    if #adminCache.usernames == 0 then
        print("⚠️ [调试] 无法从API加载管理员配置，将依赖数据库首次创建用户时的管理员设置")
    end

    print("🚀 [调试] AdminService 初始化完成")
end)

return AdminService