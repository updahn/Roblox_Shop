-- 商店UI系统主文件 - 模块化架构

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 获取共享模块的辅助函数
local function getSharedModule(moduleName, timeout)
    timeout = timeout or 10
    local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", timeout)
    if not SharedModules then
        error("❌ 无法找到SharedModules文件夹，请检查服务端设置")
    end

    local module = SharedModules:WaitForChild(moduleName, timeout)
    if not module then
        error("❌ 无法找到共享模块: " .. moduleName)
    end

    return module
end

-- 安全加载共享模块
local Config, ShopData, ShopEvents
local success, result = pcall(function()
    Config = require(getSharedModule("Config"))
    ShopData = require(getSharedModule("ShopData"))
    ShopEvents = require(getSharedModule("ShopEvents"))
    return true
end)

if not success then
    warn("❌ [ShopUI] 共享模块加载失败:", result)
    warn("❌ [ShopUI] 这通常表示服务端初始化未完成，请稍等片刻后重试")

    -- 创建简单的占位对象避免脚本崩溃
    Config = {UI = {SIZES = {}, ANIMATIONS = {}}, isValidAdmin = function() return false end}
    ShopData = {}
    ShopEvents = {User = {}, Admin = {}}
end

-- 导入拆分的模块
local function getUIModule(path)
    local player = Players.LocalPlayer
    local playerScripts = player:WaitForChild("PlayerScripts")
    local clientFolder = playerScripts:FindFirstChild("Client")
    if not clientFolder then
        error("❌ 找不到Client文件夹")
    end

    local parts = string.split(path, "/")
    local module = clientFolder
    for _, part in ipairs(parts) do
        module = module:FindFirstChild(part)
        if not module then
            error("❌ 找不到模块路径: " .. path)
        end
    end
    return module
end

local ShopUtils = require(getUIModule("functions/ShopUtils"))
local ShopBuy = require(getUIModule("ui/ShopBuy"))
local ShopSell = require(getUIModule("ui/ShopSell"))
local ShopRecords = require(getUIModule("ui/ShopRecords"))
local ShopAdminRecords = require(getUIModule("ui/ShopAdminRecords"))

local ShopUI = {}
ShopUI.__index = ShopUI

-- UI状态
local currentTab = "buy" -- "buy", "sell", "records"
local playerData = nil
local shopData = nil -- 存储从服务器获取的商店数据（包含实时库存）
local lastAdminStatus = false -- 记录上次的管理员状态，用于检测变化
local isShopOpen = false

-- UI元素
local screenGui = nil
local mainFrame = nil
local coinLabel = nil
local membershipLabel = nil
local tabButtons = {}
local contentFrame = nil
local scrollFrame = nil
local titleLabel = nil
local membershipData = nil

-- 事件连接管理
local eventConnections = {}
local eventsConnected = false

-- 创建数量选择对话框
function ShopUI.showQuantityDialog(itemId, action, item)
    -- 如果没有传递item参数，尝试从shopData获取
    if not item then
        item = shopData and shopData[itemId]
    end
    if not item then
        warn("ShopUI: 无法找到物品数据 " .. tostring(itemId))
        return
    end

    -- 创建对话框背景
    local dialogBg = Instance.new("Frame")
    dialogBg.Name = "QuantityDialogBg"
    dialogBg.Size = UDim2.new(1, 0, 1, 0)
    dialogBg.Position = UDim2.new(0, 0, 0, 0)
    dialogBg.BackgroundColor3 = ShopUtils.COLORS.OVERLAY
    dialogBg.BackgroundTransparency = 0.5
    dialogBg.BorderSizePixel = 0
    dialogBg.ZIndex = 1000
    dialogBg.Parent = screenGui

    -- 对话框主体
    local dialog = Instance.new("Frame")
    dialog.Name = "QuantityDialog"
    dialog.Size = UDim2.new(0, 400, 0, 300)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -150)
    dialog.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 1001
    dialog.Parent = dialogBg

    ShopUtils.createCorner(dialog, 16)

    -- 毛玻璃效果
    local glassBg = Instance.new("Frame")
    glassBg.Size = UDim2.new(1, 0, 1, 0)
    glassBg.BackgroundColor3 = ShopUtils.COLORS.GLASS_BG
    glassBg.BackgroundTransparency = 0.2
    glassBg.BorderSizePixel = 0
    glassBg.ZIndex = 1001
    glassBg.Parent = dialog
    ShopUtils.createCorner(glassBg, 16)

    -- 标题
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = action == "buy" and "购买商品" or "卖出商品"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(1, -40, 0, 50)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.BackgroundTransparency = 1
    title.ZIndex = 1002
    title.Parent = dialog

    -- 商品信息
    local itemInfo = Instance.new("TextLabel")
    -- 安全地计算卖出价格
    local sellPrice = 0
    if item.price and type(item.price) == "number" and item.price > 0 then
        sellPrice = math.max(1, math.floor(item.price * 0.8)) -- 使用默认sell rate，确保至少为1
    end
    itemInfo.Text = "📦 " .. tostring(item.name or "未知商品") .. "\n💰 " .. (action == "buy" and (item.price or 0) or sellPrice) .. " 金币/个"
    itemInfo.Font = Enum.Font.SourceSans
    itemInfo.TextSize = 16
    itemInfo.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
    itemInfo.Size = UDim2.new(1, -40, 0, 50)
    itemInfo.Position = UDim2.new(0, 20, 0, 80)
    itemInfo.BackgroundTransparency = 1
    itemInfo.ZIndex = 1002
    itemInfo.Parent = dialog

    -- 数量控制区域
    local quantityFrame = Instance.new("Frame")
    quantityFrame.Size = UDim2.new(0, 200, 0, 60)
    quantityFrame.Position = UDim2.new(0.5, -100, 0, 140)
    quantityFrame.BackgroundTransparency = 1
    quantityFrame.ZIndex = 1002
    quantityFrame.Parent = dialog

    -- 减少按钮
    local minusButton = ShopUtils.createButton("-", ShopUtils.COLORS.ERROR, quantityFrame, nil)
    minusButton.Size = UDim2.new(0, 50, 0, 50)
    minusButton.Position = UDim2.new(0, 0, 0, 0)
    minusButton.TextSize = 24
    minusButton.ZIndex = 1002

    -- 数量输入框
    local quantityBox = Instance.new("TextBox")
    quantityBox.Name = "QuantityBox"
    quantityBox.Text = "1"
    quantityBox.Font = Enum.Font.SourceSansBold
    quantityBox.TextSize = 20
    quantityBox.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    quantityBox.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    quantityBox.BorderSizePixel = 0
    quantityBox.Size = UDim2.new(0, 100, 0, 50)
    quantityBox.Position = UDim2.new(0, 50, 0, 0)
    quantityBox.PlaceholderText = "数量"
    quantityBox.ZIndex = 1002
    quantityBox.Parent = quantityFrame

    ShopUtils.createCorner(quantityBox, 8)

    -- 增加按钮
    local plusButton = ShopUtils.createButton("+", ShopUtils.COLORS.SUCCESS, quantityFrame, nil)
    plusButton.Size = UDim2.new(0, 50, 0, 50)
    plusButton.Position = UDim2.new(0, 150, 0, 0)
    plusButton.TextSize = 24
    plusButton.ZIndex = 1002

    -- 数量控制逻辑
    local currentQuantity = 1
    local maxQuantity

    if action == "buy" then
        -- 购买时的最大数量限制
        if shopData and shopData[itemId] and shopData[itemId].currentStock ~= nil then
            maxQuantity = shopData[itemId].currentStock == -1 and 999 or shopData[itemId].currentStock
        elseif item.maxQuantity ~= nil then
            maxQuantity = item.maxQuantity == -1 and 999 or item.maxQuantity
        else
            maxQuantity = 999
        end
    else
        -- 卖出时的最大数量限制（玩家拥有的数量）
        maxQuantity = (playerData and playerData.inventory[itemId]) or 0
    end

    local function updateQuantity(newQuantity)
        currentQuantity = math.max(1, math.min(maxQuantity or 1, newQuantity))
        quantityBox.Text = tostring(currentQuantity)

        -- 安全地计算价格
        local sellPrice = 0
        if item.price and type(item.price) == "number" and item.price > 0 then
            sellPrice = math.max(1, math.floor(item.price * 0.8))
        end

        local unitPrice = action == "buy" and (item.price or 0) or sellPrice
        local totalPrice = currentQuantity * unitPrice
        itemInfo.Text = "📦 " .. tostring(item.name or "未知商品") .. "\n💰 总计: " .. totalPrice .. " 金币"
    end

    minusButton.MouseButton1Click:Connect(function()
        updateQuantity(currentQuantity - 1)
    end)

    plusButton.MouseButton1Click:Connect(function()
        updateQuantity(currentQuantity + 1)
    end)

    quantityBox.FocusLost:Connect(function()
        local newQuantity = tonumber(quantityBox.Text) or 1
        updateQuantity(newQuantity)
    end)

    -- 按钮区域
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, -40, 0, 50)
    buttonFrame.Position = UDim2.new(0, 20, 0, 220)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.ZIndex = 1002
    buttonFrame.Parent = dialog

    -- 确认按钮
    local confirmButton = ShopUtils.createButton("✓ 确认", ShopUtils.COLORS.SUCCESS, buttonFrame, function()
        if action == "buy" then
            ShopEvents.User.BuyItem:FireServer(itemId, currentQuantity)
        else
            ShopEvents.User.SellItem:FireServer(itemId, currentQuantity)
        end

        dialogBg:Destroy()
    end)
    confirmButton.Position = UDim2.new(0, 0, 0, 0)
    confirmButton.Size = UDim2.new(0, 150, 0, 40)
    confirmButton.ZIndex = 1002

    -- 取消按钮
    local cancelButton = ShopUtils.createButton("✗ 取消", ShopUtils.COLORS.ERROR, buttonFrame, function()
        dialogBg:Destroy()
    end)
    cancelButton.Position = UDim2.new(1, -150, 0, 0)
    cancelButton.Size = UDim2.new(0, 150, 0, 40)
    cancelButton.ZIndex = 1002

    -- 弹出动画
    dialog.Size = UDim2.new(0, 0, 0, 0)
    dialog.Position = UDim2.new(0.5, 0, 0.5, 0)

    local openTween = TweenService:Create(dialog, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150)
    })
    openTween:Play()

    updateQuantity(1)
end

-- 更新会员状态数据
function ShopUI.updateMembershipStatus()
    if not playerData then return end

    -- 直接从playerData中获取会员状态信息
    if playerData.membership then
        membershipData = playerData.membership
        print("✅ [会员状态] 已更新会员信息:", membershipData.hasMembership and "有会员" or "无会员", membershipData.daysRemaining and ("剩余" .. membershipData.daysRemaining .. "天") or "")
    else
        membershipData = {
            hasMembership = false,
            isValid = false,
            daysRemaining = 0,
            membershipType = nil
        }
        print("ℹ️ [会员状态] 用户无会员状态")
    end

    -- 立即更新UI显示
    ShopUI.updateUI()
end

-- 上次检查管理员状态的时间
local lastAdminCheckTime = 0
local ADMIN_CHECK_INTERVAL = 30 -- 30秒检查一次

-- 检查管理员状态变化并更新UI（优化版）
local function checkAdminStatusChange()
    local currentTime = tick()

    -- 如果距离上次检查时间小于间隔，跳过检查
    if (currentTime - lastAdminCheckTime) < ADMIN_CHECK_INTERVAL then
        return false
    end

    lastAdminCheckTime = currentTime
    local currentAdminStatus = Config.isValidAdmin(player)

    if currentAdminStatus ~= lastAdminStatus then
        print("🔄 [调试] 管理员状态发生变化:", lastAdminStatus, "→", currentAdminStatus)
        lastAdminStatus = currentAdminStatus

        -- 清空管理员权限缓存，强制重新检查
        Config.refreshAdminCache(player)

        return true
    end
    return false
end

-- 更新UI显示
function ShopUI.updateUI()
    if not screenGui or not mainFrame then return end

    -- 检查管理员状态是否变化
    local adminStatusChanged = checkAdminStatusChange()

    -- 更新金币显示
    if coinLabel and playerData then
        coinLabel.Text = "💰 " .. (playerData.coins or 0) .. " 金币"
    elseif coinLabel then
        coinLabel.Text = "💰 连接中..."
    end

    -- 更新会员状态显示
    if membershipLabel then
        if membershipData and membershipData.hasMembership and membershipData.isValid then
            local daysRemaining = membershipData.daysRemaining or 0
            membershipLabel.Text = "👑 会员剩余: " .. daysRemaining .. "天"
            membershipLabel.TextColor3 = ShopUtils.COLORS.SUCCESS
            membershipLabel.Visible = true
        else
            membershipLabel.Text = "普通用户"
            membershipLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
            membershipLabel.Visible = true
        end
    end

    -- 更新标题
    if titleLabel then
        if currentTab == "buy" then
            titleLabel.Text = "🛒 商店购买"
        elseif currentTab == "sell" then
            titleLabel.Text = "💰 物品卖出"
        elseif currentTab == "records" then
            titleLabel.Text = "📊 购买记录"
        end
    end

    -- 更新标签按钮状态
    for tabName, button in pairs(tabButtons) do
        ShopUtils.setButtonActive(button, tabName == currentTab)
    end

    -- 清空滚动框内容，防止界面元素混合
    if scrollFrame then
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end

    -- 根据当前标签页显示内容
    if currentTab == "buy" then
        ShopBuy.showBuyItems(scrollFrame, shopData, playerData, ShopUI.showQuantityDialog)
    elseif currentTab == "sell" then
        ShopSell.showSellItems(scrollFrame, shopData, playerData, ShopUI.showQuantityDialog)
    elseif currentTab == "records" then
        -- 如果管理员状态发生变化，强制刷新记录页面
        if adminStatusChanged then
            print("🔄 [调试] 由于管理员状态变化，强制刷新记录页面")
        end

        -- 总是先调用 showPurchaseRecords 来设置界面，然后处理数据
        ShopRecords.showPurchaseRecords(scrollFrame, playerData, function()
            ShopAdminRecords.showAdminPanel(screenGui, function(message, isSuccess)
                ShopUtils.showNotification(message, isSuccess, screenGui)
            end)
        end)

        -- 如果已有交易记录数据，使用已有数据（避免重复请求）
        if playerData and playerData.transactionHistory then
            print("📊 [交易记录] 使用已有数据显示记录，避免重复请求")
            ShopRecords.handleTransactionResponse(true, nil, {
                transactions = playerData.transactionHistory,
                stats = playerData.transactionStats
            })
        end
    end
end

-- 创建主界面
function ShopUI.createUI()
    if screenGui then
        screenGui:Destroy()
    end

    -- 创建ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = false
    screenGui.Parent = playerGui

    -- 主框架
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"

    -- 安全获取UI尺寸配置
    local mainFrameSize = UDim2.new(0, 1000, 0, 700) -- 默认尺寸
    if Config and Config.UI and Config.UI.SIZES and Config.UI.SIZES.MAIN_FRAME then
        mainFrameSize = Config.UI.SIZES.MAIN_FRAME
    end

    mainFrame.Size = mainFrameSize
    mainFrame.Position = UDim2.new(0.5, -mainFrameSize.X.Offset/2, 0.5, -mainFrameSize.Y.Offset/2)
    mainFrame.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    ShopUtils.createCorner(mainFrame, 20)

    -- 顶部栏
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, -4, 0, 90)
    topBar.Position = UDim2.new(0, 2, 0, 2)
    topBar.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    topBar.BorderSizePixel = 0
    topBar.ClipsDescendants = true
    topBar.Parent = mainFrame

    ShopUtils.createCorner(topBar, 20)

    -- 遮罩底部圆角
    local topBarMask = Instance.new("Frame")
    topBarMask.Size = UDim2.new(1, 0, 0, 20)
    topBarMask.Position = UDim2.new(0, 0, 1, -20)
    topBarMask.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    topBarMask.BorderSizePixel = 0
    topBarMask.Parent = topBar

    -- 标题
    titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Text = "🛒 商店购买"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 28
    titleLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    titleLabel.Size = UDim2.new(0, 350, 0, 90)
    titleLabel.Position = UDim2.new(0, 40, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar

    -- 金币显示
    coinLabel = Instance.new("TextLabel")
    coinLabel.Name = "CoinLabel"
    coinLabel.Text = "💰 加载中..."
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextSize = 16
    coinLabel.TextColor3 = ShopUtils.COLORS.WARNING
    coinLabel.Size = UDim2.new(0, 150, 0, 20)
    coinLabel.Position = UDim2.new(1, -210, 0, 15)
    coinLabel.BackgroundTransparency = 1
    coinLabel.TextXAlignment = Enum.TextXAlignment.Right
    coinLabel.TextTruncate = Enum.TextTruncate.AtEnd
    coinLabel.TextScaled = true
    coinLabel.Parent = topBar

    -- 会员状态显示
    membershipLabel = Instance.new("TextLabel")
    membershipLabel.Name = "MembershipLabel"
    membershipLabel.Text = "检查会员状态中..."
    membershipLabel.Font = Enum.Font.Gotham
    membershipLabel.TextSize = 12
    membershipLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
    membershipLabel.Size = UDim2.new(0, 150, 0, 18)
    membershipLabel.Position = UDim2.new(1, -210, 0, 40)
    membershipLabel.BackgroundTransparency = 1
    membershipLabel.TextXAlignment = Enum.TextXAlignment.Right
    membershipLabel.TextTruncate = Enum.TextTruncate.AtEnd
    membershipLabel.TextScaled = true
    membershipLabel.Parent = topBar


    -- 每日奖励按钮
    local rewardButton = ShopUtils.createButton("🎁 领取奖励", ShopUtils.COLORS.SUCCESS, topBar, function()
        ShopUI.claimDailyRewards()
    end)
    rewardButton.Name = "RewardButton"
    rewardButton.Size = UDim2.new(0, 90, 0, 25)
    rewardButton.Position = UDim2.new(1, -210, 0, 55)
    rewardButton.TextSize = 12
    rewardButton.Visible = false

    -- 创建按钮容器框架以确保一致的布局
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 320, 0, 50)
    tabContainer.Position = UDim2.new(1, -540, 0, 20)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = topBar

    -- 添加UIListLayout以确保按钮间距一致
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(0, 8) -- 8像素的统一间距
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = tabContainer

    -- 标签按钮数据 - 按正确顺序排列：购买、卖出、记录
    local tabData = {
        {name = "buy", text = "🛒 购买", order = 1},
        {name = "sell", text = "💰 卖出", order = 2},
        {name = "records", text = "📊 记录", order = 3}
    }

    for _, tab in ipairs(tabData) do
        local button = ShopUtils.createButton(tab.text, ShopUtils.COLORS.SECONDARY, tabContainer, function()
            print("🔄 [ShopUI] 标签按钮点击:", tab.name)
            currentTab = tab.name

            -- 安全地调用远程事件
            local success, error = pcall(function()
                if ShopEvents and ShopEvents.User then
                    if ShopEvents.User.GetPlayerData then
                        ShopEvents.User.GetPlayerData:FireServer()
                    end
                    if ShopEvents.User.GetShopData then
                        ShopEvents.User.GetShopData:FireServer()
                    end
                else
                    warn("⚠️ [ShopUI] ShopEvents 未正确加载，跳过数据请求")
                end
            end)

            if not success then
                warn("❌ [ShopUI] 远程事件调用失败:", error)
            end

            -- 立即更新UI（即使数据请求失败）
            ShopUI.updateUI()
        end)

        -- 确保所有按钮完全一致的大小和样式
        button.Size = UDim2.new(0, 100, 0, 40)
        button.TextSize = 14
        button.Font = Enum.Font.SourceSansBold
        button.TextScaled = false
        button.TextWrapped = false
        button.TextTruncate = Enum.TextTruncate.None
        button.LayoutOrder = tab.order

        tabButtons[tab.name] = button
    end

    -- 关闭按钮
    local closeButton = ShopUtils.createButton("✗", ShopUtils.COLORS.ERROR, topBar, function()
        ShopUI.closeShop()
    end)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.TextSize = 20

    -- 滚动区域
    scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -70, 1, -140)
    scrollFrame.Position = UDim2.new(0, 25, 0, 115)
    scrollFrame.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    scrollFrame.BackgroundTransparency = 0
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = ShopUtils.COLORS.ACCENT
    scrollFrame.ClipsDescendants = true
    scrollFrame.Parent = mainFrame

    -- 添加圆角到滚动框架
    ShopUtils.createCorner(scrollFrame, 12)

    return screenGui
end

-- 打开商店
function ShopUI.openShop()
    if isShopOpen then return end
    isShopOpen = true

    if not screenGui then
        ShopUI.createUI()
    end

    -- 重新加载商品信息
    ShopEvents.User.RefreshData:FireServer()

    -- 获取玩家数据
    ShopEvents.User.GetPlayerData:FireServer()

    -- 更新会员状态
    ShopUI.updateMembershipStatus()

    mainFrame.Visible = true

    -- 开启动画
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundTransparency = 1

    -- 安全获取UI尺寸配置
    local mainFrameSize = UDim2.new(0, 1000, 0, 700) -- 默认尺寸
    if Config and Config.UI and Config.UI.SIZES and Config.UI.SIZES.MAIN_FRAME then
        mainFrameSize = Config.UI.SIZES.MAIN_FRAME
    end

    -- 安全获取动画配置
    local animDuration = 0.5 -- 默认持续时间
    local animEasing = Enum.EasingStyle.Bounce -- 默认缓动
    if Config and Config.UI and Config.UI.ANIMATIONS then
        if Config.UI.ANIMATIONS.DURATION and Config.UI.ANIMATIONS.DURATION.SLOW then
            animDuration = Config.UI.ANIMATIONS.DURATION.SLOW
        end
        if Config.UI.ANIMATIONS.EASING and Config.UI.ANIMATIONS.EASING.BOUNCE then
            animEasing = Config.UI.ANIMATIONS.EASING.BOUNCE
        end
    end

    local openTween = TweenService:Create(mainFrame,
        TweenInfo.new(animDuration, animEasing, Enum.EasingDirection.Out), {
        Size = mainFrameSize,
        Position = UDim2.new(0.5, -mainFrameSize.X.Offset/2, 0.5, -mainFrameSize.Y.Offset/2),
        BackgroundTransparency = 0
    })

    -- 添加旋转效果
    local rotationTween = TweenService:Create(mainFrame,
        TweenInfo.new(animDuration, animEasing, Enum.EasingDirection.Out), {
        Rotation = 0
    })

    -- 设置初始旋转
    mainFrame.Rotation = -5

    openTween:Play()
    rotationTween:Play()
end

-- 关闭商店
function ShopUI.closeShop()
    if not isShopOpen then return end
    isShopOpen = false

    if mainFrame then
        -- 安全获取UI尺寸配置
        local mainFrameSize = UDim2.new(0, 1000, 0, 700) -- 默认尺寸
        if Config and Config.UI and Config.UI.SIZES and Config.UI.SIZES.MAIN_FRAME then
            mainFrameSize = Config.UI.SIZES.MAIN_FRAME
        end

        -- 简化的关闭动画：只缩放和淡出
        local closeAnimDuration = 0.3 -- 默认持续时间
        local closeAnimEasing = Enum.EasingStyle.Quad -- 默认缓动
        if Config and Config.UI and Config.UI.ANIMATIONS then
            if Config.UI.ANIMATIONS.DURATION and Config.UI.ANIMATIONS.DURATION.NORMAL then
                closeAnimDuration = Config.UI.ANIMATIONS.DURATION.NORMAL
            end
            if Config.UI.ANIMATIONS.EASING and Config.UI.ANIMATIONS.EASING.DEFAULT then
                closeAnimEasing = Config.UI.ANIMATIONS.EASING.DEFAULT
            end
        end

        local closeTween = TweenService:Create(mainFrame,
            TweenInfo.new(closeAnimDuration, closeAnimEasing, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        })

        closeTween:Play()

        closeTween.Completed:Connect(function()
            -- 确保界面完全隐藏
            mainFrame.Visible = false

            -- 重置主框架属性为初始状态
            mainFrame.BackgroundTransparency = 0.1
            mainFrame.Size = mainFrameSize
            mainFrame.Position = UDim2.new(0.5, -mainFrameSize.X.Offset/2, 0.5, -mainFrameSize.Y.Offset/2)
            mainFrame.Rotation = 0
        end)
    end

    ShopUtils.SOUNDS.click:Play()
end

-- 领取每日奖励
function ShopUI.claimDailyRewards()
    if not playerData or not playerData.id then
        ShopUtils.showNotification("❌ 玩家数据未加载", false, screenGui)
        return
    end

    local success, message, rewardData = nil, nil, nil
    local callSuccess, callResult = pcall(function()
        return false, "功能暂时不可用"
    end)

    if callSuccess then
        success, message, rewardData = callResult
    else
        success = false
        message = "认证失败，请重新进入游戏或检查网络连接"
    end

    if success then
        if rewardData and rewardData.totalRewards > 0 then
            ShopUtils.showNotification("✅ " .. message .. " 获得 " .. rewardData.totalRewards .. " 金币", true, screenGui)
            -- 刷新玩家数据
            ShopEvents.User.GetPlayerData:FireServer()
        else
            ShopUtils.showNotification("ℹ️ 今日奖励已领取完毕", true, screenGui)
        end
    else
        ShopUtils.showNotification("❌ " .. (message or "领取失败"), false, screenGui)
    end
end

-- 断开所有事件连接
function ShopUI.disconnectEvents()
    for _, connection in pairs(eventConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    eventConnections = {}
    eventsConnected = false
    print("🔌 [事件管理] 已断开所有事件连接")
end

-- 事件连接
function ShopUI.connectEvents()
    -- 如果已经连接过事件，先断开旧连接
    if eventsConnected then
        print("🔄 [事件管理] 检测到重复连接，正在清理旧连接...")
        ShopUI.disconnectEvents()
    end

    -- 获取玩家数据响应
    eventConnections.getPlayerData = ShopEvents.User.GetPlayerData.OnClientEvent:Connect(function(data)
        if data then
            local oldCoins = playerData and playerData.coins or 0
            playerData = data
            print("✅ [数据同步] 玩家数据已更新 | 金币: " .. (data.coins or 0) .. " (之前: " .. oldCoins .. ")")

            -- 如果金币发生变化，显示通知
            if oldCoins ~= data.coins then
                local coinDiff = data.coins - oldCoins
                local message = coinDiff > 0 and "💰 金币增加 +" .. coinDiff or "💰 金币减少 " .. coinDiff
                print("💰 [金币变化] " .. message)
            end

            -- 更新会员状态
            ShopUI.updateMembershipStatus()

            -- 更新UI
            ShopUI.updateUI()
        else
            warn("⚠️ [数据同步] 玩家数据为空，可能存在网络连接问题")
            -- 设置默认数据防止空指针错误
            playerData = {
                coins = 0,
                inventory = {},
                membership = {
                    hasMembership = false,
                    isValid = false,
                    daysRemaining = 0,
                    membershipType = nil
                },
                stats = {
                    totalPurchases = 0,
                    totalSales = 0,
                    totalSpent = 0,
                    totalEarned = 0
                }
            }
            ShopUI.updateMembershipStatus()
            ShopUI.updateUI()
        end
    end)

    -- 获取商店数据响应
    eventConnections.getShopData = ShopEvents.User.GetShopData.OnClientEvent:Connect(function(data)
        shopData = data
        local itemCount = 0
        if data then
            for _ in pairs(data) do
                itemCount = itemCount + 1
            end
        end
        print("✅ [数据同步] 商店数据已更新 | 商品种类: " .. itemCount)
        ShopUI.updateUI()
    end)

    -- 购买响应
    eventConnections.buyItem = ShopEvents.User.BuyItem.OnClientEvent:Connect(function(success, message, newData)
        if success then
            playerData = newData

            -- 检查是否购买了会员商品（通过消息或其他方式判断）
            local isMembershipPurchase = message and (message:find("会员") or message:find("membership"))

            if isMembershipPurchase then
                print("🎯 [购买] 检测到会员商品购买，特殊处理状态更新")

                -- 延迟一点时间确保服务端数据完全同步
                task.wait(0.2)

                -- 强制刷新数据
                ShopEvents.User.RefreshData:FireServer()

                -- 再次等待数据刷新
                task.wait(0.1)
            end

            -- 立即更新会员状态（特别是购买会员商品后）
            ShopUI.updateMembershipStatus()

            -- 刷新商店数据
            if not isMembershipPurchase then
                ShopEvents.User.RefreshData:FireServer()
            end
            ShopUI.updateUI()

            ShopUtils.showNotification("✅ " .. message, true, screenGui)

            -- 实时刷新交易记录
            ShopRecords.forceRefreshTransactions()
        else
            ShopUtils.showNotification("❌ " .. message, false, screenGui)
        end
    end)

    -- 卖出响应
    eventConnections.sellItem = ShopEvents.User.SellItem.OnClientEvent:Connect(function(success, message, newData)
        if success then
            playerData = newData
            -- 刷新商店数据
            ShopEvents.User.RefreshData:FireServer()
            ShopUI.updateUI()
            ShopUtils.showNotification("✅ " .. message, true, screenGui)

            -- 实时刷新交易记录
            ShopRecords.forceRefreshTransactions()
        else
            ShopUtils.showNotification("❌ " .. message, false, screenGui)
        end
    end)

    -- 管理员功能响应
    eventConnections.setPlayerCoins = ShopEvents.Admin.SetUserCoins.OnClientEvent:Connect(function(success, message)
        if success then
            ShopUtils.showNotification("✅ " .. message, true, screenGui)
        else
            ShopUtils.showNotification("❌ " .. message, false, screenGui)
        end
    end)

    -- 会员状态变更通知
    eventConnections.membershipStatusChanged = ShopEvents.User.MembershipStatusChanged.OnClientEvent:Connect(function(statusData)
        if statusData and statusData.success then
            print("🔄 [会员状态] 收到状态变更通知:", statusData.message)

            -- 显示通知
            if statusData.message then
                ShopUtils.showNotification("✅ " .. statusData.message, true, screenGui)
            end

            -- 立即刷新玩家数据
            ShopEvents.User.GetPlayerData:FireServer()
        end
    end)

    eventConnections.getPlayerPurchaseHistory = ShopEvents.Admin.GetUserHistory.OnClientEvent:Connect(function(success, message, data)
        print("📊 [ShopUI] GetUserHistory事件响应:", success, message, data and "有数据" or "无数据")

        if not success then
            -- 当失败时，message 包含错误信息
            local errorMsg = message or "获取用户历史记录失败"
            ShopUtils.showNotification("❌ " .. errorMsg, false, screenGui)
            ShopRecords.handleAdminHistoryResponse(success, errorMsg, nil)
        elseif data then
            -- 当成功时，使用统一的处理函数
            ShopRecords.handleAdminHistoryResponse(success, message, data)
        end
    end)

    -- 数据刷新请求
    eventConnections.refreshData = ShopEvents.User.RefreshData.OnClientEvent:Connect(function()
        print("🔄 [数据刷新] 收到服务端刷新请求")
        if playerData then
            print("🔄 [数据刷新] 当前金币:", playerData.coins)
        end
        -- 立即请求最新数据
        ShopEvents.User.GetPlayerData:FireServer()
        ShopEvents.User.GetShopData:FireServer()
        print("🔄 [数据刷新] 已发送数据请求")
    end)

    -- 用户交易记录响应
    eventConnections.getTransactions = ShopEvents.User.GetTransactions.OnClientEvent:Connect(function(success, errorMsg, responseData)
        print("📊 [交易记录] 事件响应:", success, errorMsg, responseData and "有数据" or "无数据")

        if success and responseData then
            -- 更新 playerData 以包含交易记录
            if playerData then
                playerData.transactionHistory = responseData.transactions
                playerData.transactionStats = responseData.stats

                print("📊 [交易记录] 已获取 " .. #responseData.transactions .. " 条交易记录")

                -- 通知ShopRecords模块更新UI
                ShopRecords.handleTransactionResponse(success, errorMsg, responseData)

                -- 刷新其他UI显示
                ShopUI.updateUI()
            end
        else
            local error = errorMsg or "获取交易记录失败"
            print("❌ [交易记录] 失败:", error)

            -- 通知ShopRecords模块显示错误
            ShopRecords.handleTransactionResponse(success, error, responseData)

            ShopUtils.showNotification("❌ " .. tostring(error), false, screenGui)
        end
    end)

    -- 键盘输入
    eventConnections.keyboardInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.E then
            if isShopOpen then
                ShopUI.closeShop()
            else
                ShopUI.openShop()
            end
        end
    end)

    -- 标记事件已连接
    eventsConnected = true
    print("🔗 [事件管理] 所有事件已成功连接")
end

-- 初始化
function ShopUI.init()
    ShopUI.connectEvents()

    -- 获取系统配置（包括sell_rate）
    -- 系统配置将由服务器端管理
    print("📡 [客户端] 正在获取系统配置...")

    -- 请求玩家数据
    if ShopEvents.User.GetPlayerData then
        ShopEvents.User.GetPlayerData:FireServer()
        print("📡 [客户端] 正在同步玩家数据...")
    else
        warn("⚠️ GetPlayerData 远程事件未找到")
    end

    -- 请求商店数据
    if ShopEvents.User.GetShopData then
        ShopEvents.User.GetShopData:FireServer()
        print("📡 [客户端] 正在同步商店数据...")
    else
        warn("⚠️ GetShopData 远程事件未找到")
    end

    print("🎨 [商店UI] 商店系统已就绪")
    print("🔧 [控制] 按 E 键打开商店")
end

return ShopUI