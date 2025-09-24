-- 商店系统主服务器脚本
-- 简化后的统一入口点

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("🏪 商店系统启动中...")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", 5)
if not SharedModules then
    error("⚠️ 无法加载共享模块，系统无法启动")
    return
end

local Config = require(SharedModules:WaitForChild("Config"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))

-- 加载服务模块 - 使用重构后的路径
local ServicesFolder = game:GetService("ServerScriptService").Server:WaitForChild("services")
local UtilsFolder = game:GetService("ServerScriptService"):WaitForChild("utils")

local UserService = require(ServicesFolder:WaitForChild("UserService"))
local AdminService = require(ServicesFolder:WaitForChild("AdminService"))
local DroneService = require(ServicesFolder:WaitForChild("DroneService"))
local TargetService = require(UtilsFolder:WaitForChild("TargetService"))

-- 初始化靶子系统
TargetService.initialize()

print("✅ 商店系统已启动")
print("🛒 支持普通用户和管理员功能")
print("🤖 无人机系统已激活")
print("🎯 靶子系统已激活")
print("📊 数据存储在 DataStore 中")

-- 处理玩家连接事件
Players.PlayerAdded:Connect(function(player)
    print("👤 [加入] " .. player.Name .. " 已连接")

    -- 等待一下确保客户端准备好
    wait(2)

    -- 认证玩家
    UserService.authenticatePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 [离开] " .. player.Name .. " 已断开连接")
    UserService.cleanupPlayer(player)
    AdminService.cleanupPlayer(player)
end)

-- 处理已经在游戏中的玩家
for _, player in pairs(Players:GetPlayers()) do
    spawn(function()
        UserService.authenticatePlayer(player)
    end)
end

return true
