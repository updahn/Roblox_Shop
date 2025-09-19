-- 商店管理员界面模块

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local ShopEvents = require(SharedModules:WaitForChild("ShopEvents"))
local ShopUtils = require(script.Parent:WaitForChild("ShopUtils"))

local player = Players.LocalPlayer

local ShopAdmin = {}

-- 显示管理员面板
function ShopAdmin.showAdminPanel(screenGui, showNotification)
    -- 检查管理员权限
    if not Config.isValidAdmin(player) then
        if showNotification then
            showNotification("❌ 您没有管理员权限", false)
        end
        return
    end

    -- 创建管理员面板
    local adminFrame = Instance.new("Frame")
    adminFrame.Name = "AdminPanel"
    adminFrame.Size = UDim2.new(0, 800, 0, 600)
    adminFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    adminFrame.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    adminFrame.BorderSizePixel = 0
    adminFrame.ZIndex = 3000
    adminFrame.Parent = screenGui
    ShopUtils.createCorner(adminFrame, 12)

    -- 背景遮罩
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = ShopUtils.COLORS.OVERLAY
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 2999
    overlay.Parent = screenGui

    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = ShopUtils.COLORS.ACCENT
    titleBar.BorderSizePixel = 0
    titleBar.Parent = adminFrame
    ShopUtils.createCorner(titleBar, 12)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "👑 管理员控制面板"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = titleBar

    -- 关闭按钮
    local closeBtn = ShopUtils.createButton("✗", ShopUtils.COLORS.ERROR, titleBar, function()
        adminFrame:Destroy()
        overlay:Destroy()
    end)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.TextSize = 20

    -- 内容区域
    local contentArea = Instance.new("ScrollingFrame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -80)
    contentArea.Position = UDim2.new(0, 10, 0, 70)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.ScrollBarThickness = 8
    contentArea.ScrollBarImageColor3 = ShopUtils.COLORS.ACCENT
    contentArea.Parent = adminFrame

    -- 请求所有玩家数据
    ShopEvents.RemoteEvents.GetAllPlayersData:FireServer()

    -- 显示加载提示
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Text = "📡 正在加载玩家数据..."
    loadingLabel.Font = Enum.Font.SourceSans
    loadingLabel.TextSize = 16
    loadingLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
    loadingLabel.Size = UDim2.new(1, 0, 0, 100)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
    loadingLabel.Parent = contentArea

    -- 监听服务器响应
    local connection
    connection = ShopEvents.RemoteEvents.GetAllPlayersData.OnClientEvent:Connect(function(allPlayersData, errorMsg)
        connection:Disconnect()
        loadingLabel:Destroy()

        if errorMsg then
            -- 显示错误信息
            showNotification("❌ " .. errorMsg)
        elseif allPlayersData then
            ShopAdmin.displayAllPlayersData(contentArea, allPlayersData, showNotification)
        else
            showNotification("❌ 无法加载玩家数据")
        end
    end)
end

-- 显示所有玩家数据
function ShopAdmin.displayAllPlayersData(parentFrame, allPlayersData, showNotification)
    -- 检查管理员权限
    if not Config.isValidAdmin(player) then
        return
    end

    local yPos = 10

    for playerName, data in pairs(allPlayersData) do
        -- 玩家卡片
        local playerCard = Instance.new("Frame")
        playerCard.Name = "PlayerCard_" .. playerName
        playerCard.Size = UDim2.new(1, -20, 0, 120)
        playerCard.Position = UDim2.new(0, 10, 0, yPos)
        playerCard.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
        playerCard.BorderSizePixel = 0
        playerCard.Parent = parentFrame
        ShopUtils.createCorner(playerCard, 8)

        -- 玩家信息
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = "👤 " .. playerName .. " (ID: " .. data.userId .. ")"
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 16
        nameLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        nameLabel.Size = UDim2.new(0.4, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = playerCard

        -- 金币显示和修改
        local coinsLabel = Instance.new("TextLabel")
        coinsLabel.Text = "💰 " .. data.coins .. " 金币"
        coinsLabel.Font = Enum.Font.SourceSans
        coinsLabel.TextSize = 14
        coinsLabel.TextColor3 = ShopUtils.COLORS.WARNING
        coinsLabel.Size = UDim2.new(0.2, 0, 0, 20)
        coinsLabel.Position = UDim2.new(0, 10, 0, 30)
        coinsLabel.BackgroundTransparency = 1
        coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
        coinsLabel.Parent = playerCard

        -- 金币修改输入框
        local coinsInput = Instance.new("TextBox")
        coinsInput.Text = tostring(data.coins)
        coinsInput.Font = Enum.Font.SourceSans
        coinsInput.TextSize = 12
        coinsInput.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        coinsInput.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
        coinsInput.Size = UDim2.new(0, 80, 0, 25)
        coinsInput.Position = UDim2.new(0, 10, 0, 55)
        coinsInput.PlaceholderText = "新金币数"
        coinsInput.Parent = playerCard
        ShopUtils.createCorner(coinsInput, 4)

        -- 设置金币按钮
        local setCoinsBtn = ShopUtils.createButton("设置", ShopUtils.COLORS.SUCCESS, playerCard, function()
            local newCoins = tonumber(coinsInput.Text)
            if newCoins and newCoins >= 0 and newCoins <= 999999 then
                ShopEvents.RemoteEvents.SetPlayerCoins:FireServer(playerName, newCoins)
            else
                showNotification("❌ 金币数量必须在 0-999999 之间", false)
            end
        end)
        setCoinsBtn.Position = UDim2.new(0, 100, 0, 55)
        setCoinsBtn.Size = UDim2.new(0, 60, 0, 25)
        setCoinsBtn.TextSize = 12

        -- 查看记录按钮
        local viewRecordsBtn = ShopUtils.createButton("查看记录", ShopUtils.COLORS.ACCENT, playerCard, function()
            ShopEvents.RemoteEvents.GetPlayerPurchaseHistory:FireServer(playerName)
        end)
        viewRecordsBtn.Position = UDim2.new(0, 170, 0, 55)
        viewRecordsBtn.Size = UDim2.new(0, 80, 0, 25)
        viewRecordsBtn.TextSize = 12

        -- 统计信息
        local statsText = string.format(
            "📊 购买: %d次 | 消费: %d金币 | 卖出: %d次 | 收入: %d金币 | 库存: %d件",
            data.totalPurchases, data.totalSpent, data.totalSales, data.totalEarned, data.inventoryCount
        )
        local statsLabel = Instance.new("TextLabel")
        statsLabel.Text = statsText
        statsLabel.Font = Enum.Font.SourceSans
        statsLabel.TextSize = 12
        statsLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
        statsLabel.Size = UDim2.new(1, -20, 0, 30)
        statsLabel.Position = UDim2.new(0, 10, 0, 85)
        statsLabel.BackgroundTransparency = 1
        statsLabel.TextXAlignment = Enum.TextXAlignment.Left
        statsLabel.TextWrapped = true
        statsLabel.Parent = playerCard

        yPos = yPos + 130
    end

    parentFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

-- 显示其他玩家的购买记录
function ShopAdmin.showPlayerRecords(playerName, records, screenGui)
    -- 检查管理员权限
    if not Config.isValidAdmin(player) then
        return
    end

    -- 创建记录查看窗口
    local recordFrame = Instance.new("Frame")
    recordFrame.Name = "PlayerRecordFrame"
    recordFrame.Size = UDim2.new(0, 600, 0, 500)
    recordFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    recordFrame.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    recordFrame.BorderSizePixel = 0
    recordFrame.ZIndex = 3100
    recordFrame.Parent = screenGui
    ShopUtils.createCorner(recordFrame, 12)

    -- 背景遮罩
    local overlay = Instance.new("Frame")
    overlay.Name = "RecordOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = ShopUtils.COLORS.OVERLAY
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 3099
    overlay.Parent = screenGui

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
        overlay:Destroy()
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

    -- 显示记录
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
            timeLabel.Text = ShopUtils.formatTimestamp(record.timestamp)
            timeLabel.Font = Enum.Font.SourceSans
            timeLabel.TextSize = 11
            timeLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
            timeLabel.Size = UDim2.new(1, -10, 0, 15)
            timeLabel.Position = UDim2.new(0, 5, 0, 5)
            timeLabel.BackgroundTransparency = 1
            timeLabel.TextXAlignment = Enum.TextXAlignment.Left
            timeLabel.Parent = recordCard

            -- 交易类型和物品
            local actionLabel = Instance.new("TextLabel")
            local actionText = ""
            if record.action == "buy" then
                actionText = "🛒 购买 " .. (record.itemName or "未知物品") .. " x" .. (record.quantity or 1)
            elseif record.action == "sell" then
                actionText = "💰 卖出 " .. (record.itemName or "未知物品") .. " x" .. (record.quantity or 1)
            elseif record.action == "admin_edit" then
                actionText = "修改 管理员金币调整x" .. (record.quantity or 1)
            end
            actionLabel.Text = actionText
            actionLabel.Font = Enum.Font.SourceSansBold
            actionLabel.TextSize = 14
            actionLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
            actionLabel.Size = UDim2.new(0.7, 0, 0, 25)
            actionLabel.Position = UDim2.new(0, 5, 0, 25)
            actionLabel.BackgroundTransparency = 1
            actionLabel.TextXAlignment = Enum.TextXAlignment.Left
            actionLabel.Parent = recordCard

            -- 金额
            local amountLabel = Instance.new("TextLabel")
            local amountText = ""
            local amountColor = ShopUtils.COLORS.TEXT_SECONDARY
            if record.action == "buy" then
                amountText = "-" .. (record.totalCost or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.ERROR
            elseif record.action == "sell" then
                amountText = "+" .. (record.totalEarned or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.SUCCESS
            elseif record.action == "admin_edit" then
                amountText = "now" .. (record.balanceAfter or 0) .. "金币"
                amountColor = ShopUtils.COLORS.TEXT_PRIMARY
            end
            amountLabel.Text = amountText
            amountLabel.Font = Enum.Font.SourceSansBold
            amountLabel.TextSize = 13
            amountLabel.TextColor3 = amountColor
            amountLabel.Size = UDim2.new(0.25, 0, 0, 20)
            amountLabel.Position = UDim2.new(0.75, 0, 0, 30)
            amountLabel.BackgroundTransparency = 1
            amountLabel.TextXAlignment = Enum.TextXAlignment.Right
            amountLabel.Parent = recordCard

            -- 余额
            local balanceLabel = Instance.new("TextLabel")
            balanceLabel.Text = "余额: " .. (record.balanceAfter or 0)
            balanceLabel.Font = Enum.Font.SourceSans
            balanceLabel.TextSize = 11
            balanceLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
            balanceLabel.Size = UDim2.new(1, -10, 0, 15)
            balanceLabel.Position = UDim2.new(0, 5, 0, 60)
            balanceLabel.BackgroundTransparency = 1
            balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
            balanceLabel.Parent = recordCard

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

return ShopAdmin
