-- 商店系统启动脚本 - 确保正确的加载顺序

print("商店系统启动中...")

-- 第一步: 设置共享模块
local setupScript = script.Parent:FindFirstChild("SetupReplicatedStorage")
if setupScript then
    require(setupScript)
end

-- 等待一帧，确保模块已创建
game:GetService("RunService").Heartbeat:Wait()

-- 第二步: 检查主服务端脚本是否存在
local mainScript = script.Parent:FindFirstChild("Main")
if mainScript then
    print("✅ 找到Main服务器脚本，将自动执行")
else
    warn("⚠️ 找不到Main脚本")
end

print("商店系统启动完成")
