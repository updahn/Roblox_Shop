-- 会员管理界面模块 - 适配器模式
-- 现在使用统一的ShopAdminPanel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

-- 导入统一的管理面板
local ShopAdminPanel = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ui:WaitForChild("ShopAdminPanel"))

local player = Players.LocalPlayer

local ShopMembership = {}

-- 显示会员管理界面 - 现在直接调用统一面板
function ShopMembership.showMembershipUI(screenGui)
    print("👥 [会员管理适配器] 调用统一管理面板")

    -- 检查管理员权限 - 使用AdminController
    local isAdmin = false
    local success, AdminController = pcall(function()
        local Players = game:GetService("Players")
        local StarterPlayer = game:GetService("StarterPlayer")
        return require(StarterPlayer.StarterPlayerScripts.Client.controller.AdminController)
    end)

    if success and AdminController then
        local adminCheckSuccess, adminResult = pcall(function()
            return AdminController.checkPermission()
        end)
        if adminCheckSuccess then
            isAdmin = adminResult
        end
    end

    if not isAdmin then
        print("❌ [会员管理适配器] 管理员权限检查失败")
        return
    end

    -- 直接调用统一的管理面板，并切换到会员管理标签
    ShopAdminPanel.showAdminPanel(screenGui, function(message, isSuccess)
        print("📝 [会员管理] 通知:", message)
    end)

    -- 延迟切换到会员管理标签
    task.wait(0.1)
    ShopAdminPanel.switchTab("membership")
end

-- 其他函数保持存在以保证向后兼容性，但重定向到统一面板
function ShopMembership.createMembershipUI()
    print("⚠️ [废弃函数] createMembershipUI 被调用，建议使用统一管理面板")
    return nil
end

function ShopMembership.hideMembershipUI()
    print("⚠️ [废弃函数] hideMembershipUI 被调用")
end

function ShopMembership.refreshMembershipData()
    print("⚠️ [废弃函数] refreshMembershipData 被调用，建议使用统一管理面板")
end

function ShopMembership.updateMembershipList()
    print("⚠️ [废弃函数] updateMembershipList 被调用，建议使用统一管理面板")
end

print("👥 会员管理适配器模块已加载")

return ShopMembership
