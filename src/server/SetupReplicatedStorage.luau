-- 设置ReplicatedStorage中的共享模块

local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Rojo已经将shared文件夹映射到ReplicatedStorage.Shared
-- 我们需要等待这些模块加载，然后复制到SharedModules文件夹供客户端使用

-- 等待Rojo同步的Shared文件夹
local sharedFolderRojo = ReplicatedStorage:WaitForChild("Shared", 10)
if not sharedFolderRojo then
    warn("无法找到Rojo同步的Shared文件夹")
    return true
end

-- 创建SharedModules文件夹
local sharedFolder = ReplicatedStorage:FindFirstChild("SharedModules")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "SharedModules"
    sharedFolder.Parent = ReplicatedStorage
end

-- 从Rojo的Shared文件夹复制模块到SharedModules
local function copyModule(moduleName)
    local sourceModule = sharedFolderRojo:WaitForChild(moduleName, 5)
    if sourceModule then
        local targetModule = sharedFolder:FindFirstChild(moduleName)
        if not targetModule then
            targetModule = sourceModule:Clone()
            targetModule.Parent = sharedFolder
        end
    else
        warn("找不到模块: " .. moduleName)
    end
end

-- 复制所需的模块
copyModule("ShopData")
copyModule("ShopEvents")


-- 返回true表示成功
return true
