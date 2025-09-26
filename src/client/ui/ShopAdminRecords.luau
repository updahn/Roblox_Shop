-- 商店管理员界面模块 - 适配器模式
-- 现在使用统一的ShopAdminPanel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local ShopUtils = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.functions:WaitForChild("ShopUtils"))

-- 导入统一的管理面板
local ShopAdminPanel = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ui:WaitForChild("ShopAdminPanel"))

local player = Players.LocalPlayer

local ShopAdminRecords = {}

-- 存储待处理的管理员查看记录请求（保持向后兼容）
ShopAdminRecords.pendingPlayerName = nil
ShopAdminRecords.pendingScreenGui = nil

-- 显示管理员面板 - 现在直接调用统一面板
function ShopAdminRecords.showAdminPanel(screenGui, showNotification)
    print("🔧 [管理员面板适配器] 调用统一管理面板")

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
        print("❌ [管理员面板适配器] 管理员权限检查失败")
        if showNotification then
            showNotification("❌ 您没有管理员权限", false)
        end
        return
    end

    -- 直接调用统一的管理面板
    ShopAdminPanel.showAdminPanel(screenGui, showNotification)
end

-- 显示其他玩家的购买记录（保持向后兼容性）
function ShopAdminRecords.showPlayerRecords(playerName, records, screenGui)
    print("📊 [管理员记录适配器] 显示玩家记录:", playerName, "记录数量:", records and #records or 0)

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
        print("❌ [管理员记录适配器] 权限检查失败")
        return
    end

    print("✅ [管理员记录适配器] 权限验证通过，使用普通用户记录格式")

    -- 创建记录查看窗口 - 使用普通用户交易记录的样式
    local recordFrame = Instance.new("Frame")
    recordFrame.Name = "PlayerRecordFrame"
    recordFrame.Size = UDim2.new(0, 600, 0, 500)
    recordFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    recordFrame.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    recordFrame.BorderSizePixel = 0
    recordFrame.ZIndex = 3100
    recordFrame.Parent = screenGui
    ShopUtils.createCorner(recordFrame, 12)

    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = ShopUtils.COLORS.ACCENT
    titleBar.BorderSizePixel = 0
    titleBar.Parent = recordFrame
    ShopUtils.createCorner(titleBar, 12)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "📊 " .. playerName .. " 的交易记录"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = titleBar

    -- 关闭按钮
    local closeBtn = ShopUtils.createButton("✗", ShopUtils.COLORS.ERROR, titleBar, function()
        recordFrame:Destroy()
    end)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.TextSize = 18

    -- 记录滚动区域
    local scrollArea = Instance.new("ScrollingFrame")
    scrollArea.Name = "ScrollArea"
    scrollArea.Size = UDim2.new(1, -20, 1, -70)
    scrollArea.Position = UDim2.new(0, 10, 0, 60)
    scrollArea.BackgroundTransparency = 1
    scrollArea.BorderSizePixel = 0
    scrollArea.ScrollBarThickness = 8
    scrollArea.ScrollBarImageColor3 = ShopUtils.COLORS.ACCENT
    scrollArea.Parent = recordFrame

    -- 显示记录 - 使用与普通用户记录相同的格式
    local yPos = 10
    if records and #records > 0 then
        for i, record in ipairs(records) do
            local recordCard = Instance.new("Frame")
            recordCard.Name = "Record" .. i
            recordCard.Size = UDim2.new(1, -20, 0, 80)
            recordCard.Position = UDim2.new(0, 10, 0, yPos)
            recordCard.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
            recordCard.BorderSizePixel = 0
            recordCard.Parent = scrollArea
            ShopUtils.createCorner(recordCard, 8)

            -- 时间戳
            local timeLabel = Instance.new("TextLabel")

            -- 调试时间戳问题
            local timestamp = record.timestamp or record.createdAt or record.transactionDate
            print("📊 [AdminRecords调试] 交易记录时间戳:",
                "timestamp=", record.timestamp,
                "createdAt=", record.createdAt,
                "transactionDate=", record.transactionDate,
                "使用=", timestamp)

            timeLabel.Text = ShopUtils.formatTimestamp(timestamp)
            timeLabel.Font = Enum.Font.SourceSans
            timeLabel.TextSize = 12
            timeLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
            timeLabel.Size = UDim2.new(0, 150, 0, 20)
            timeLabel.Position = UDim2.new(0, 10, 0, 5)
            timeLabel.BackgroundTransparency = 1
            timeLabel.TextXAlignment = Enum.TextXAlignment.Left
            timeLabel.Parent = recordCard

            -- 交易类型和物品 - 使用与普通用户记录相同的格式
            local actionLabel = Instance.new("TextLabel")
            local actionText = ""
            if record.type == "buy" or record.action == "buy" then
                actionText = "🛒 购买 " .. (record.itemName or record.item_name or "未知物品") .. " x" .. (record.quantity or 1)
            elseif record.type == "sell" or record.action == "sell" then
                actionText = "💰 卖出 " .. (record.itemName or record.item_name or "未知物品") .. " x" .. (record.quantity or 1)
            elseif record.type == "admin" or record.action == "admin_edit" then
                actionText = "⚙️ 管理员操作 x" .. (record.quantity or 1)
            elseif record.type == "daily_reward" then
                actionText = "🎁 每日奖励 x" .. (record.quantity or 1)
            elseif record.type == "membership_purchase" then
                actionText = "💎 购买会员 " .. (record.itemName or record.item_name or "未知会员") .. " x" .. (record.quantity or 1)
            end
            actionLabel.Text = actionText
            actionLabel.Font = Enum.Font.SourceSansBold
            actionLabel.TextSize = 16
            actionLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
            actionLabel.Size = UDim2.new(1, -20, 0, 25)
            actionLabel.Position = UDim2.new(0, 10, 0, 25)
            actionLabel.BackgroundTransparency = 1
            actionLabel.TextXAlignment = Enum.TextXAlignment.Left
            actionLabel.Parent = recordCard

            -- 金额 - 使用与普通用户记录相同的格式
            local amountLabel = Instance.new("TextLabel")
            local amountText = ""
            local amountColor = ShopUtils.COLORS.TEXT_SECONDARY
            if record.type == "buy" or record.action == "buy" then
                amountText = "-" .. (record.totalAmount or record.totalCost or record.total_amount or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.ERROR
            elseif record.type == "sell" or record.action == "sell" then
                amountText = "+" .. (record.totalAmount or record.totalEarned or record.total_amount or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.SUCCESS
            elseif record.type == "admin" or record.action == "admin_edit" then
                local coinChange = record.totalAmount or record.total_amount or 0
                if coinChange > 0 then
                    amountText = "+" .. coinChange .. " 金币"
                    amountColor = ShopUtils.COLORS.SUCCESS
                elseif coinChange < 0 then
                    amountText = coinChange .. " 金币"  -- 负数已经包含减号
                    amountColor = ShopUtils.COLORS.ERROR
                else
                    amountText = "0 金币"
                    amountColor = ShopUtils.COLORS.TEXT_MUTED
                end
            elseif record.type == "daily_reward" then
                amountText = "+" .. (record.totalAmount or record.total_amount or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.SUCCESS
            elseif record.type == "membership_purchase" then
                amountText = "-" .. (record.totalAmount or record.totalCost or record.total_amount or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.ERROR
            end
            amountLabel.Text = amountText
            amountLabel.Font = Enum.Font.SourceSansBold
            amountLabel.TextSize = 14
            amountLabel.TextColor3 = amountColor
            amountLabel.Size = UDim2.new(0, 120, 0, 20)
            amountLabel.Position = UDim2.new(1, -130, 0, 30)
            amountLabel.BackgroundTransparency = 1
            amountLabel.TextXAlignment = Enum.TextXAlignment.Right
            amountLabel.Parent = recordCard

            yPos = yPos + 90
        end
    else
        -- 无记录提示
        local noRecordLabel = Instance.new("TextLabel")
        noRecordLabel.Text = "📝 该玩家暂无交易记录"
        noRecordLabel.Font = Enum.Font.SourceSans
        noRecordLabel.TextSize = 16
        noRecordLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
        noRecordLabel.Size = UDim2.new(1, 0, 0, 100)
        noRecordLabel.BackgroundTransparency = 1
        noRecordLabel.TextXAlignment = Enum.TextXAlignment.Center
        noRecordLabel.Parent = scrollArea
        yPos = yPos + 120
    end

    scrollArea.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

-- 废弃的函数保持存在以保证兼容性，但重定向到统一面板
function ShopAdminRecords.displayAllPlayersData(parentFrame, allPlayersData, showNotification)
    print("⚠️ [废弃函数] displayAllPlayersData 被调用，建议使用统一管理面板")
    -- 这个函数保持存在但不执行任何操作，因为现在使用统一面板
end

return ShopAdminRecords