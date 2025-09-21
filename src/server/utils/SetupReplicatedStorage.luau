-- 设置ReplicatedStorage中的共享模块

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- 从重构后的目录结构复制模块
local function copyModuleFromPath(sourcePath, targetName)
    local sourceModule = sharedFolderRojo

    -- 导航到源路径
    for _, pathPart in ipairs(sourcePath) do
        sourceModule = sourceModule:WaitForChild(pathPart, 5)
        if not sourceModule then
            warn("找不到路径: " .. table.concat(sourcePath, "/"))
            return
        end
    end

    -- 复制模块
    local targetModule = sharedFolder:FindFirstChild(targetName)
    if not targetModule then
        targetModule = sourceModule:Clone()
        targetModule.Name = targetName
        targetModule.Parent = sharedFolder
        print("✅ 复制模块: " .. targetName)
    end
end

-- 复制重构后的模块结构
copyModuleFromPath({"core", "Config"}, "Config")
copyModuleFromPath({"core", "Events"}, "ShopEvents") -- Events模块以ShopEvents名称复制，保持向后兼容
copyModuleFromPath({"core", "Types"}, "ShopData") -- Types模块以ShopData名称复制，保持向后兼容
copyModuleFromPath({"client", "ShopClient"}, "ShopDataClient")


-- 返回true表示成功
return true
