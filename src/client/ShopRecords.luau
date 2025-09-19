-- 商店记录界面模块

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local ShopEvents = require(SharedModules:WaitForChild("ShopEvents"))
local ShopUtils = require(script.Parent:WaitForChild("ShopUtils"))

local player = Players.LocalPlayer

local ShopRecords = {}

-- 显示购买记录
function ShopRecords.showPurchaseRecords(scrollFrame, playerData, showAdminPanel)
    if not scrollFrame then return end

    -- 清空现有内容
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") and (child.Name:find("Record") or child.Name == "RecordTitle" or child.Name == "NoRecord") then
            child:Destroy()
        end
    end

    local yPos = 20

    -- 标题
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "RecordTitle"
    titleFrame.Size = UDim2.new(1, -40, 0, 40)
    titleFrame.Position = UDim2.new(0, 20, 0, yPos)
    titleFrame.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = scrollFrame
    ShopUtils.createCorner(titleFrame, 8)

    local titleText = Instance.new("TextLabel")
    titleText.Text = "📊 交易记录"
    titleText.Font = Enum.Font.SourceSansBold
    titleText.TextSize = 18
    titleText.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextXAlignment = Enum.TextXAlignment.Center
    titleText.Parent = titleFrame

    -- 管理员控制按钮（仅管理员可见）
    if Config.isValidAdmin(player) and showAdminPanel then
        local adminButton = ShopUtils.createButton("👑 管理", ShopUtils.COLORS.WARNING, titleFrame, function()
            showAdminPanel()
        end)
        adminButton.Position = UDim2.new(1, -100, 0, 5)
        adminButton.Size = UDim2.new(0, 90, 0, 30)
        adminButton.TextSize = 12
    end

    yPos = yPos + 60

        -- 显示交易记录
    if playerData and playerData.purchaseHistory then
        for i, record in ipairs(playerData.purchaseHistory) do
            local recordFrame = Instance.new("Frame")
            recordFrame.Name = "Record" .. i
            recordFrame.Size = UDim2.new(1, -40, 0, 80)
            recordFrame.Position = UDim2.new(0, 20, 0, yPos)
            recordFrame.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
            recordFrame.BorderSizePixel = 0
            recordFrame.Parent = scrollFrame
            ShopUtils.createCorner(recordFrame, 8)

            -- 时间戳
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Text = ShopUtils.formatTimestamp(record.timestamp)
            timeLabel.Font = Enum.Font.SourceSans
            timeLabel.TextSize = 12
            timeLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
            timeLabel.Size = UDim2.new(0, 150, 0, 20)
            timeLabel.Position = UDim2.new(0, 10, 0, 5)
            timeLabel.BackgroundTransparency = 1
            timeLabel.TextXAlignment = Enum.TextXAlignment.Left
            timeLabel.Parent = recordFrame

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
            actionLabel.TextSize = 16
            actionLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
            actionLabel.Size = UDim2.new(1, -20, 0, 25)
            actionLabel.Position = UDim2.new(0, 10, 0, 25)
            actionLabel.BackgroundTransparency = 1
            actionLabel.TextXAlignment = Enum.TextXAlignment.Left
            actionLabel.Parent = recordFrame

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
            amountLabel.TextSize = 14
            amountLabel.TextColor3 = amountColor
            amountLabel.Size = UDim2.new(0, 120, 0, 20)
            amountLabel.Position = UDim2.new(1, -130, 0, 30)
            amountLabel.BackgroundTransparency = 1
            amountLabel.TextXAlignment = Enum.TextXAlignment.Right
            amountLabel.Parent = recordFrame

            yPos = yPos + 90
        end
    else
        -- 无记录提示
        local noRecordFrame = Instance.new("Frame")
        noRecordFrame.Name = "NoRecord"
        noRecordFrame.Size = UDim2.new(1, -40, 0, 100)
        noRecordFrame.Position = UDim2.new(0, 20, 0, yPos)
        noRecordFrame.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
        noRecordFrame.BorderSizePixel = 0
        noRecordFrame.Parent = scrollFrame
        ShopUtils.createCorner(noRecordFrame, 8)

        local noRecordText = Instance.new("TextLabel")
        noRecordText.Text = "📝 暂无交易记录"
        noRecordText.Font = Enum.Font.SourceSans
        noRecordText.TextSize = 16
        noRecordText.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
        noRecordText.Size = UDim2.new(1, 0, 1, 0)
        noRecordText.BackgroundTransparency = 1
        noRecordText.TextXAlignment = Enum.TextXAlignment.Center
        noRecordText.Parent = noRecordFrame

        yPos = yPos + 120
    end

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

return ShopRecords
