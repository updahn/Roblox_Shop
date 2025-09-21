-- DataStore 系统启动脚本
-- 替换原有的 MySQL + API 架构

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 等待共享模块加载
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")

-- 初始化 DataStore 管理器
local DataStoreManager = require(script.Parent.modules.DataStoreManager)
local UserDataService = require(script.Parent.modules.UserDataService)
local AdminDataService = require(script.Parent.modules.AdminDataService)
local ItemsInitializer = require(script.Parent.modules.ItemsInitializer)

-- 启动 DataStore 系统
DataStoreManager.initialize()

print("🚀 DataStore 商店系统启动中...")

-- 等待模块完全加载
wait(2)

-- 初始化管理员权限（根据配置文件自动设置）
spawn(function()
    wait(3) -- 等待AdminService完全初始化

    local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
    local Config = require(SharedModules:WaitForChild("Config"))

    -- 从配置文件获取默认管理员用户名
    local defaultAdminUsernames = Config.ADMIN.DEFAULT_ADMIN_USERNAMES or {}

    if #defaultAdminUsernames > 0 then
        print("🔧 [系统] 开始初始化默认管理员...")

        -- 等待玩家加入来设置管理员权限
        local function setupAdminForUsername(targetUsername)
            -- 检查玩家是否已经在线
            for _, player in pairs(Players:GetPlayers()) do
                if player.Name == targetUsername then
                    local success = pcall(function()
                        AdminDataService.promoteToAdmin(tostring(player.UserId))
                    end)

                    if success then
                        print("✅ [系统] 在线用户管理员设置成功:", targetUsername, "(" .. player.UserId .. ")")
                    else
                        print("❌ [系统] 在线用户管理员设置失败:", targetUsername)
                    end
                    return true
                end
            end
            return false
        end

        -- 处理当前在线的玩家
        for _, adminUsername in ipairs(defaultAdminUsernames) do
            if adminUsername and adminUsername ~= "" then
                if not setupAdminForUsername(adminUsername) then
                    print("📋 [系统] 管理员用户", adminUsername, "当前不在线，将在其加入时自动设置")
                end
            end
        end

        print("🔧 [系统] 默认管理员初始化配置完成，共", #defaultAdminUsernames, "个管理员用户名")
        print("📋 [系统] 管理员列表:", table.concat(defaultAdminUsernames, ", "))
    else
        print("⚠️ [系统] 没有配置默认管理员，请在Config.ADMIN.DEFAULT_ADMIN_USERNAMES中添加管理员用户名")
    end

    -- 将管理员用户名列表暴露给全局，供玩家连接处理使用
    _G.DefaultAdminUsernames = defaultAdminUsernames
end)

-- 玩家连接处理
Players.PlayerAdded:Connect(function(player)
    spawn(function()
        -- 等待一下确保系统完全启动
        wait(1)

        print("👋 玩家加入:", player.Name, "(" .. player.UserId .. ")")

        -- 检查是否需要设置管理员权限
        local defaultAdminUsernames = _G.DefaultAdminUsernames or {}
        local shouldPromoteToAdmin = false

        for _, adminUsername in ipairs(defaultAdminUsernames) do
            if player.Name == adminUsername then
                shouldPromoteToAdmin = true
                break
            end
        end

        -- 自动创建或登录用户
        local success, result = pcall(function()
            return UserDataService.createOrLoginUser(
                tostring(player.UserId),
                player.Name,
                player.DisplayName ~= player.Name and player.DisplayName or nil
            )
        end)

        if success and result then
            if result.isNewUser then
                print("🎉 新用户注册:", player.Name)
                -- 可以在这里给新用户一些欢迎奖励
            else
                print("✅ 用户登录:", player.Name)
            end

            -- 如果需要，设置管理员权限
            if shouldPromoteToAdmin then
                spawn(function()
                    wait(1) -- 等待用户数据完全加载
                    local adminSuccess = pcall(function()
                        AdminDataService.promoteToAdmin(tostring(player.UserId))
                    end)

                    if adminSuccess then
                        print("✅ [自动] 管理员权限设置成功:", player.Name, "(" .. player.UserId .. ")")
                    else
                        print("❌ [自动] 管理员权限设置失败:", player.Name)
                    end
                end)
            end

            -- 自动处理每日登录奖励
            spawn(function()
                wait(2) -- 等待一下再处理奖励
                local rewardSuccess, rewardResult = pcall(function()
                    return UserDataService.processLoginRewards(tostring(player.UserId))
                end)

                if rewardSuccess and rewardResult and rewardResult.success and rewardResult.totalRewards > 0 then
                    print("🎁 玩家", player.Name, "获得每日奖励:", rewardResult.totalRewards, "金币")
                end
            end)
        else
            warn("❌ 用户登录失败:", player.Name, result or "未知错误")
        end
    end)
end)

-- 玩家离开处理
Players.PlayerRemoving:Connect(function(player)
    print("👋 玩家离开:", player.Name)
    -- DataStore 会自动处理数据保存，这里不需要特别操作
end)

-- 定期保存系统统计（可选）
spawn(function()
    while true do
        wait(300) -- 每5分钟更新一次统计

        pcall(function()
            local stats = AdminDataService.getCompleteSystemStats()
            if stats then
                print("📊 系统统计更新:",
                    "用户数:", stats.users.total_users,
                    "活跃用户:", stats.users.active_users,
                    "总交易:", stats.transactions.total_transactions
                )
            end
        end)
    end
end)

print("🎯 DataStore 商店系统启动完成！")

-- 显示商品初始化统计
spawn(function()
    wait(3) -- 等待商品初始化完成
    local totalItems = ItemsInitializer.getTotalItemCount()
    local categories = ItemsInitializer.getAllCategories()

    print("🛒 商品系统统计：")
    print("   • 总商品数量：", totalItems, "个")
    print("   • 商品分类：", #categories, "个")
    for _, category in ipairs(categories) do
        local count = ItemsInitializer.getCategoryItemCount(category)
        print("     -", category .. ":", count, "个商品")
    end
end)

print("📝 系统说明：")
print("   • 用户数据存储在 DataStoreService 中")
print("   • Studio 环境使用模拟数据存储（数据不持久化）")
print("   • 生产环境使用真实 DataStore（数据持久化）")
print("   • 管理员权限通过用户数据中的 isAdmin 字段控制")
print("   • 系统配置可通过 DataStoreManager 修改")
print("   • 新用户初始金币：1000（根据 init.sql 配置）")
print("   • 商品数据已从 init.sql 完整迁移")
print("🔧 管理员设置方式：")
print("   1. 在 Config.ADMIN.DEFAULT_ADMIN_USERNAMES 中添加用户名")
print("   2. 重启服务器，系统会自动设置对应用户为管理员")
print("   3. 手动设置：require(ServerScriptService.modules.AdminDataService).promoteToAdmin('用户ID')")
print("⚠️ 注意：用户名设置的管理员需要该用户至少加入游戏一次才能生效")
