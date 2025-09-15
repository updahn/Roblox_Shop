-- 商店UI系统主文件 - 模块化架构

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local ShopData = require(SharedModules:WaitForChild("ShopData"))
local ShopEvents = require(SharedModules:WaitForChild("ShopEvents"))

-- 导入拆分的模块
local ShopUtils = require(script.Parent:WaitForChild("ShopUtils"))
local ShopBuy = require(script.Parent:WaitForChild("ShopBuy"))
local ShopSell = require(script.Parent:WaitForChild("ShopSell"))
local ShopRecords = require(script.Parent:WaitForChild("ShopRecords"))
local ShopAdmin = require(script.Parent:WaitForChild("ShopAdmin"))

local ShopUI = {}
ShopUI.__index = ShopUI

-- UI状态
local currentTab = "buy" -- "buy", "sell", "records"
local playerData = nil
local shopData = nil -- 存储从服务器获取的商店数据（包含实时库存）
local isShopOpen = false

-- UI元素
local screenGui = nil
local mainFrame = nil
local coinLabel = nil
local tabButtons = {}
local contentFrame = nil
local scrollFrame = nil
local titleLabel = nil

-- 创建数量选择对话框
function ShopUI.showQuantityDialog(itemId, action)
    local item = ShopData.SHOP_ITEMS[itemId]
    if not item then return end

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
    itemInfo.Text = "📦 " .. item.name .. "\n💰 " .. (action == "buy" and item.price or math.floor(item.price * 0.8)) .. " 金币/个"
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
        currentQuantity = math.max(1, math.min(maxQuantity, newQuantity))
        quantityBox.Text = tostring(currentQuantity)

        local totalPrice = currentQuantity * (action == "buy" and item.price or math.floor(item.price * 0.8))
        itemInfo.Text = "📦 " .. item.name .. "\n💰 总计: " .. totalPrice .. " 金币"
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
            ShopEvents.RemoteEvents.PurchaseItem:FireServer(itemId, currentQuantity)
        else
            ShopEvents.RemoteEvents.SellItem:FireServer(itemId, currentQuantity)
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

-- 更新UI显示
function ShopUI.updateUI()
    if not screenGui or not mainFrame then return end

    -- 更新金币显示
    if coinLabel and playerData then
        coinLabel.Text = "💰 " .. playerData.coins .. " 金币"
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
        if tabName == currentTab then
            button.BackgroundColor3 = ShopUtils.COLORS.ACCENT
            button.TextColor3 = ShopUtils.COLORS.PRIMARY
        else
            button.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
            button.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        end
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
        ShopRecords.showPurchaseRecords(scrollFrame, playerData, function()
            ShopAdmin.showAdminPanel(screenGui, function(message, isSuccess)
                ShopUtils.showNotification(message, isSuccess, screenGui)
            end)
        end)
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
    mainFrame.Size = UDim2.new(0, 850, 0, 650)
    mainFrame.Position = UDim2.new(0.5, -425, 0.5, -325)
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

    -- 标签按钮 - 统一大小和位置
    local tabData = {
        {name = "buy", text = "🛒 购买", pos = UDim2.new(1, -480, 0, 25)},
        {name = "sell", text = "💰 卖出", pos = UDim2.new(1, -380, 0, 25)},
        {name = "records", text = "📊 记录", pos = UDim2.new(1, -280, 0, 25)}
    }

    for _, tab in ipairs(tabData) do
        local button = ShopUtils.createButton(tab.text, ShopUtils.COLORS.SECONDARY, topBar, function()
            currentTab = tab.name
            -- 切换标签时重新获取最新数据
            ShopEvents.RemoteEvents.GetPlayerData:FireServer()
            ShopEvents.RemoteEvents.GetShopData:FireServer()
            ShopUI.updateUI()
        end)
        button.Position = tab.pos
        -- 统一按钮大小
        button.Size = UDim2.new(0, 95, 0, 40)
        button.TextSize = 14
        button.Font = Enum.Font.SourceSansBold
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

    -- 获取玩家数据
    ShopEvents.RemoteEvents.GetPlayerData:FireServer()

    mainFrame.Visible = true

    -- 开启动画
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundTransparency = 1

    local openTween = TweenService:Create(mainFrame,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 850, 0, 650),
        Position = UDim2.new(0.5, -425, 0.5, -325),
        BackgroundTransparency = 0
    })

    -- 添加旋转效果
    local rotationTween = TweenService:Create(mainFrame,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
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
        -- 简化的关闭动画：只缩放和淡出
        local closeTween = TweenService:Create(mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
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
            mainFrame.Size = UDim2.new(0, 850, 0, 650)
            mainFrame.Position = UDim2.new(0.5, -425, 0.5, -325)
            mainFrame.Rotation = 0
        end)
    end

    ShopUtils.SOUNDS.click:Play()
end

-- 事件连接
function ShopUI.connectEvents()
    -- 获取玩家数据响应
    ShopEvents.RemoteEvents.GetPlayerData.OnClientEvent:Connect(function(data)
        playerData = data
        print("✅ [数据同步] 玩家数据已更新 | 金币: " .. (data.coins or 0))
        ShopUI.updateUI()
    end)

    -- 获取商店数据响应
    ShopEvents.RemoteEvents.GetShopData.OnClientEvent:Connect(function(data)
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
    ShopEvents.RemoteEvents.PurchaseItem.OnClientEvent:Connect(function(success, message, newData)
        if success then
            playerData = newData
            ShopUI.updateUI()
            ShopUtils.showNotification("✅ " .. message, true, screenGui)
        else
            ShopUtils.showNotification("❌ " .. message, false, screenGui)
        end
    end)

    -- 卖出响应
    ShopEvents.RemoteEvents.SellItem.OnClientEvent:Connect(function(success, message, newData)
        if success then
            playerData = newData
            ShopUI.updateUI()
            ShopUtils.showNotification("✅ " .. message, true, screenGui)
        else
            ShopUtils.showNotification("❌ " .. message, false, screenGui)
        end
    end)

    -- 管理员功能响应
    ShopEvents.RemoteEvents.SetPlayerCoins.OnClientEvent:Connect(function(success, message)
        if success then
            ShopUtils.showNotification("✅ " .. message, true, screenGui)
        else
            ShopUtils.showNotification("❌ " .. message, false, screenGui)
        end
    end)

    ShopEvents.RemoteEvents.GetPlayerPurchaseHistory.OnClientEvent:Connect(function(playerName, records, errorMsg)
        if errorMsg then
            ShopUtils.showNotification("❌ " .. errorMsg, false, screenGui)
        elseif records then
            ShopAdmin.showPlayerRecords(playerName, records, screenGui)
        end
    end)

    -- 键盘输入
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.E then
            if isShopOpen then
                ShopUI.closeShop()
            else
                ShopUI.openShop()
            end
        end
    end)
end

-- 初始化
function ShopUI.init()
    ShopUI.connectEvents()

    -- 请求玩家数据
    if ShopEvents.RemoteEvents.GetPlayerData then
        ShopEvents.RemoteEvents.GetPlayerData:FireServer()
        print("📡 [客户端] 正在同步玩家数据...")
    else
        warn("⚠️ GetPlayerData 远程事件未找到")
    end

    -- 请求商店数据
    if ShopEvents.RemoteEvents.GetShopData then
        ShopEvents.RemoteEvents.GetShopData:FireServer()
        print("📡 [客户端] 正在同步商店数据...")
    else
        warn("⚠️ GetShopData 远程事件未找到")
    end

    print("🎨 [商店UI] 商店系统已就绪")
    print("🔧 [控制] 按 E 键打开商店")
end

return ShopUI