-- 商店系统启动脚本 - 确保正确的加载顺序

print("商店系统启动中...")

-- 第一步: 设置共享模块
local setupScript = script.Parent:FindFirstChild("SetupReplicatedStorage")
if setupScript then
    require(setupScript)
end

-- 等待一帧，确保模块已创建
game:GetService("RunService").Heartbeat:Wait()

-- 第二步: 启动数据管理器
spawn(function()
    local dataManager = script.Parent:FindFirstChild("DataManager")
    if dataManager then
        require(dataManager)
    end
end)

-- 第三步: 启动主服务端逻辑（注意文件扩展名）
spawn(function()
    wait(0.1) -- 短暂延迟确保一切就绪
    local mainScript = script.Parent:FindFirstChild("init.server")
    if mainScript then
        require(mainScript)
    end
end)

print("商店系统启动完成")
