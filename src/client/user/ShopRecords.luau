-- 商店记录界面模块

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local ShopEvents = require(SharedModules:WaitForChild("ShopEvents"))
local ShopUtils = require(script.Parent.Parent:WaitForChild("ShopUtils"))

local player = Players.LocalPlayer

local ShopRecords = {}

-- 存储当前显示的scrollFrame引用，用于更新
local currentScrollFrame = nil
local currentShowAdminPanel = nil

-- 请求状态管理，支持实时更新（优化版）
local isRequestingTransactions = false
local lastRequestTime = 0
local REQUEST_COOLDOWN = 2 -- 增加到2秒，避免过度请求
local pendingRequestCount = 0 -- 待处理请求计数器

-- 显示购买记录
function ShopRecords.showPurchaseRecords(scrollFrame, playerData, showAdminPanel)
    if not scrollFrame then return end

    -- 存储引用以供后续更新使用
    currentScrollFrame = scrollFrame
    currentShowAdminPanel = showAdminPanel

    -- 清空现有内容
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") and (child.Name:find("Record") or child.Name == "RecordTitle" or child.Name == "NoRecord" or child.Name == "LoadingRecord") then
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
    local isAdmin = Config.isValidAdmin(player)
    local hasAdminPanelFunction = showAdminPanel ~= nil

    if isAdmin and showAdminPanel then
        print("✅ [调试] 创建管理员按钮")
        local adminButton = ShopUtils.createButton("👑 管理", ShopUtils.COLORS.WARNING, titleFrame, function()
            showAdminPanel()
        end)
        adminButton.Position = UDim2.new(1, -100, 0, 5)
        adminButton.Size = UDim2.new(0, 90, 0, 30)
        adminButton.TextSize = 12
    end

    yPos = yPos + 60

    -- 显示加载提示
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Name = "LoadingRecord"
    loadingFrame.Size = UDim2.new(1, -40, 0, 60)
    loadingFrame.Position = UDim2.new(0, 20, 0, yPos)
    loadingFrame.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    loadingFrame.BorderSizePixel = 0
    loadingFrame.Parent = scrollFrame
    ShopUtils.createCorner(loadingFrame, 8)

    local loadingText = Instance.new("TextLabel")
    loadingText.Text = "⏳ 正在加载交易记录..."
    loadingText.Font = Enum.Font.SourceSans
    loadingText.TextSize = 16
    loadingText.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
    loadingText.Size = UDim2.new(1, 0, 1, 0)
    loadingText.BackgroundTransparency = 1
    loadingText.TextXAlignment = Enum.TextXAlignment.Center
    loadingText.Parent = loadingFrame

    -- 请求用户交易记录（优化防抖机制）
    local currentTime = tick()

    -- 增加待处理请求计数
    pendingRequestCount = pendingRequestCount + 1

    if isRequestingTransactions then
        print("⚠️ [交易记录] 请求正在进行中，跳过重复请求 (待处理:", pendingRequestCount, ")")
        return
    end

    if currentTime - lastRequestTime < REQUEST_COOLDOWN then
        print("⚠️ [交易记录] 请求冷却中，跳过重复请求 (冷却剩余:", math.ceil(REQUEST_COOLDOWN - (currentTime - lastRequestTime)), "秒)")
        return
    end

    print("📊 [交易记录] 请求获取交易记录 (待处理:", pendingRequestCount, ")")
    isRequestingTransactions = true
    lastRequestTime = currentTime
    pendingRequestCount = 0 -- 重置计数器
    ShopEvents.User.GetTransactions:FireServer(50, 0, nil) -- 获取最近50条记录

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 80)
end

-- 强制刷新交易记录（实时更新用 - 优化版）
function ShopRecords.forceRefreshTransactions()
    print("🔄 [交易记录] 强制刷新交易记录")

    -- 检查是否可以强制刷新（避免过度刷新）
    local currentTime = tick()
    if isRequestingTransactions and (currentTime - lastRequestTime) < 1 then
        print("⚠️ [交易记录] 强制刷新被限制，请求正在进行中")
        return
    end

    -- 重置冷却时间，允许立即刷新
    lastRequestTime = 0
    isRequestingTransactions = false
    pendingRequestCount = 0

    -- 如果有活动的scrollFrame，重新显示记录
    if currentScrollFrame and currentShowAdminPanel then
        ShopRecords.showPurchaseRecords(currentScrollFrame, nil, currentShowAdminPanel)
    end
end

-- 处理交易记录响应并更新UI
function ShopRecords.handleTransactionResponse(success, message, responseData)
    -- 重置请求状态
    isRequestingTransactions = false

    if not currentScrollFrame then
        print("❌ [交易记录] 没有活动的scrollFrame来更新")
        return
    end

    print("📊 [交易记录] 收到响应:", success, message)

    -- 移除加载提示
    local loadingFrame = currentScrollFrame:FindFirstChild("LoadingRecord")
    if loadingFrame then
        loadingFrame:Destroy()
    end

    local yPos = 80 -- 标题后的位置

    if success and responseData and responseData.transactions then
        local transactions = responseData.transactions
        print("📊 [交易记录] 显示", #transactions, "条交易记录")

        -- 显示交易记录
        for i, record in ipairs(transactions) do
            local recordFrame = Instance.new("Frame")
            recordFrame.Name = "Record" .. i
            recordFrame.Size = UDim2.new(1, -40, 0, 80)
            recordFrame.Position = UDim2.new(0, 20, 0, yPos)
            recordFrame.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
            recordFrame.BorderSizePixel = 0
            recordFrame.Parent = currentScrollFrame
            ShopUtils.createCorner(recordFrame, 8)

            -- 时间戳
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Text = ShopUtils.formatTimestamp(record.timestamp or record.createdAt)
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
            if record.type == "buy" then
                actionText = "🛒 购买 " .. (record.itemName or "未知物品") .. " x" .. (record.quantity or 1)
            elseif record.type == "sell" then
                actionText = "💰 卖出 " .. (record.itemName or "未知物品") .. " x" .. (record.quantity or 1)
            elseif record.type == "admin" then
                actionText = "⚙️ 管理员操作 x" .. (record.quantity or 1)
            elseif record.type == "daily_reward" then
                actionText = "🎁 每日奖励 x" .. (record.quantity or 1)
            elseif record.type == "membership_purchase" then
                actionText = "💎 购买会员 " .. (record.itemName or "未知会员") .. " x" .. (record.quantity or 1)
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
            if record.type == "buy" then
                amountText = "-" .. (record.totalAmount or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.ERROR
            elseif record.type == "sell" then
                amountText = "+" .. (record.totalAmount or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.SUCCESS
            elseif record.type == "admin" then
                amountText = (record.totalAmount or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.TEXT_PRIMARY
            elseif record.type == "daily_reward" then
                amountText = "+" .. (record.totalAmount or 0) .. " 金币"
                amountColor = ShopUtils.COLORS.SUCCESS
            elseif record.type == "membership_purchase" then
                amountText = "-" .. (record.totalAmount or 0) .. " 金币"
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
            amountLabel.Parent = recordFrame

            yPos = yPos + 90
        end

        if #transactions == 0 then
            -- 空记录提示
            ShopRecords._showNoRecordsMessage(yPos)
            yPos = yPos + 120
        end
    else
        -- 错误或无数据处理
        print("❌ [交易记录] 加载失败或无数据:", message)
        ShopRecords._showErrorMessage(yPos, message or "加载交易记录失败")
        yPos = yPos + 120
    end

    currentScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

-- 显示无记录消息
function ShopRecords._showNoRecordsMessage(yPos)
    local noRecordFrame = Instance.new("Frame")
    noRecordFrame.Name = "NoRecord"
    noRecordFrame.Size = UDim2.new(1, -40, 0, 100)
    noRecordFrame.Position = UDim2.new(0, 20, 0, yPos)
    noRecordFrame.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    noRecordFrame.BorderSizePixel = 0
    noRecordFrame.Parent = currentScrollFrame
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
end

-- 显示错误消息
function ShopRecords._showErrorMessage(yPos, errorMessage)
    local errorFrame = Instance.new("Frame")
    errorFrame.Name = "ErrorRecord"
    errorFrame.Size = UDim2.new(1, -40, 0, 100)
    errorFrame.Position = UDim2.new(0, 20, 0, yPos)
    errorFrame.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    errorFrame.BorderSizePixel = 0
    errorFrame.Parent = currentScrollFrame
    ShopUtils.createCorner(errorFrame, 8)

    local errorText = Instance.new("TextLabel")
    errorText.Text = "❌ " .. errorMessage
    errorText.Font = Enum.Font.SourceSans
    errorText.TextSize = 16
    errorText.TextColor3 = ShopUtils.COLORS.ERROR
    errorText.Size = UDim2.new(1, 0, 1, 0)
    errorText.BackgroundTransparency = 1
    errorText.TextXAlignment = Enum.TextXAlignment.Center
    errorText.Parent = errorFrame
end

-- 显示记录查看界面（为了兼容性）
function ShopRecords.showRecordsUI(playerName)
    print("📊 请求查看 " .. (playerName or "当前玩家") .. " 的记录")
    -- 请求服务器获取该玩家的记录
    if ShopEvents.Admin.GetUserHistory then
        ShopEvents.Admin.GetUserHistory:FireServer(playerName)
    end
end

-- 处理管理员查看用户历史记录的响应函数（由ShopUI.luau调用）
function ShopRecords.handleAdminHistoryResponse(success, message, data)
    print("📊 [管理员记录] 收到用户历史记录响应:", success, message)

    if success and data and data.transactions then
        -- 将API响应转换为与普通交易记录兼容的格式
        local formattedData = {
            transactions = {}
        }

        for _, transaction in ipairs(data.transactions) do
            local formattedTransaction = {
                type = transaction.type,
                itemName = transaction.item_name,
                quantity = transaction.quantity,
                totalAmount = transaction.total_amount,
                timestamp = transaction.created_at,
                createdAt = transaction.created_at
            }
            table.insert(formattedData.transactions, formattedTransaction)
        end

        -- 使用普通的交易记录响应处理函数来显示格式化的数据
        ShopRecords.handleTransactionResponse(true, "获取用户交易历史成功", formattedData)
    else
        -- 处理错误情况
        local errorMessage = message or "获取用户交易记录失败"
        ShopRecords.handleTransactionResponse(false, errorMessage, nil)
    end
end

return ShopRecords

