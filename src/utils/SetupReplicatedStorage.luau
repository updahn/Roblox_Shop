-- Rojo 共享模块验证脚本 - 确保模块正确加载

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🔍 [SetupReplicatedStorage] 验证 Rojo 同步的共享模块...")

-- 等待 Rojo 同步的 SharedModules 文件夹
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", 10)
if not SharedModules then
    error("❌ [SetupReplicatedStorage] 无法找到 SharedModules 文件夹，请确保 Rojo 正常运行")
    return false
end

-- 验证必需的模块是否存在
local requiredModules = {
    "Config",
    "EnvironmentManager",
    "ShopEvents",
    "ShopData"
}

local allModulesPresent = true
local loadedModules = {}

for _, moduleName in ipairs(requiredModules) do
    local module = SharedModules:FindFirstChild(moduleName)
    if module then
        print("✅ [SetupReplicatedStorage] 发现模块: " .. moduleName)
        table.insert(loadedModules, moduleName)
    else
        warn("❌ [SetupReplicatedStorage] 缺少模块: " .. moduleName)
        allModulesPresent = false
    end
end

-- 显示所有可用模块
local availableModules = {}
for _, child in pairs(SharedModules:GetChildren()) do
    table.insert(availableModules, child.Name)
end

print("📦 [SetupReplicatedStorage] 可用模块列表: " .. table.concat(availableModules, ", "))

if allModulesPresent then
    print("✅ [SetupReplicatedStorage] 所有必需模块已通过 Rojo 成功加载")
    return true
else
    warn("⚠️ [SetupReplicatedStorage] 部分模块缺失，请检查 Rojo 配置")
    return false
end
