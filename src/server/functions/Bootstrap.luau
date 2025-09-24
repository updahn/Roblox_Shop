-- 商店系统启动脚本 - 确保正确的加载顺序

print("商店系统启动中...")

-- 第一步: 设置共享模块
local ServerScriptService = game:GetService("ServerScriptService")
local utilsFolder = ServerScriptService:FindFirstChild("utils")
local setupScript = utilsFolder and utilsFolder:FindFirstChild("SetupReplicatedStorage")
if setupScript then
    require(setupScript)
    print("✅ 共享模块设置完成")
else
    warn("⚠️ 找不到SetupReplicatedStorage脚本")
end

-- 等待一帧，确保模块已创建
game:GetService("RunService").Heartbeat:Wait()

-- 第二步: 检查主服务端脚本是否存在
local mainScript = game:GetService("ServerScriptService").Server.functions:FindFirstChild("Main")
if mainScript then
    print("✅ 找到Main服务器脚本，将自动执行")
    -- 手动启动Main脚本
    require(mainScript)
else
    warn("⚠️ 找不到Main脚本")
end

print("商店系统启动完成")

-- 返回成功标识
return true
