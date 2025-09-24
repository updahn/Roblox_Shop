-- 商店购买界面模块

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- 安全获取共享模块
local function getSharedModule(moduleName, timeout)
    timeout = timeout or 10
    local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", timeout)
    if SharedModules then
        local module = SharedModules:WaitForChild(moduleName, timeout)
        if module then return module end
    end
    error("❌ 无法找到共享模块: " .. moduleName)
end

local ShopData, ShopEvents
local success, result = pcall(function()
    ShopData = require(getSharedModule("ShopData"))
    ShopEvents = require(getSharedModule("ShopEvents"))
    return true
end)

if not success then
    warn("❌ [ShopBuy] 共享模块加载失败:", result)
    ShopData = {}
    ShopEvents = {User = {}, Admin = {}}
end
-- 获取ShopUtils模块
local function getShopUtils()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerScripts = player:WaitForChild("PlayerScripts")
    local clientFolder = playerScripts:FindFirstChild("Client")
    if not clientFolder then
        error("❌ 找不到Client文件夹")
    end

    local functionsFolder = clientFolder:FindFirstChild("functions")
    if functionsFolder and functionsFolder:FindFirstChild("ShopUtils") then
        return require(functionsFolder.ShopUtils)
    else
        error("❌ 找不到ShopUtils模块")
    end
end

local ShopUtils = getShopUtils()

local ShopBuy = {}

-- 创建商品卡片（购买模式）
function ShopBuy.createItemCard(item, itemId, shopData, playerData, showQuantityDialog)
    local card = Instance.new("Frame")
    card.Name = itemId .. "Card"
    card.Size = UDim2.new(1, -50, 0, 120)
    card.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    card.BorderSizePixel = 0
    card.ClipsDescendants = true

    ShopUtils.createCorner(card, 16)

    -- 添加渐变背景
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, ShopUtils.COLORS.SECONDARY),
        ColorSequenceKeypoint.new(1, ShopUtils.COLORS.TERTIARY)
    }
    gradient.Rotation = 135
    gradient.Parent = card

    -- 添加边框发光
    local stroke = Instance.new("UIStroke")
    stroke.Color = ShopUtils.COLORS.ACCENT
    stroke.Transparency = 0.8
    stroke.Thickness = 2
    stroke.Parent = card

    -- 悬停效果
    card.MouseEnter:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.3), {
            Transparency = 0.3,
            Thickness = 3
        }):Play()
    end)

    card.MouseLeave:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.3), {
            Transparency = 0.8,
            Thickness = 2
        }):Play()
    end)

    -- 商品图片容器
    local imageContainer = Instance.new("Frame")
    imageContainer.Name = "ImageContainer"
    imageContainer.Size = UDim2.new(0, 90, 0, 90)
    imageContainer.Position = UDim2.new(0, 20, 0, 20)
    imageContainer.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    imageContainer.BorderSizePixel = 0
    imageContainer.Parent = card
    ShopUtils.createCorner(imageContainer, 12)

    -- 添加图片容器的发光边框
    local imageStroke = Instance.new("UIStroke")
    imageStroke.Color = ShopUtils.COLORS.ACCENT
    imageStroke.Transparency = 0.7
    imageStroke.Thickness = 2
    imageStroke.Parent = imageContainer

    -- 商品图片
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ItemImage"
    imageLabel.Size = UDim2.new(1, -4, 1, -4)
    imageLabel.Position = UDim2.new(0, 2, 0, 2)
    imageLabel.Image = item.imageId or ""
    imageLabel.BackgroundTransparency = 1
    imageLabel.BorderSizePixel = 0
    imageLabel.Parent = imageContainer
    ShopUtils.createCorner(imageLabel, 10)

    -- 商品名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ItemName"
    nameLabel.Text = item.name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    nameLabel.Size = UDim2.new(0, 300, 0, 25)
    nameLabel.Position = UDim2.new(0, 120, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card

    -- 商品描述
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "ItemDesc"
    descLabel.Text = item.description
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 13
    descLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
    descLabel.Size = UDim2.new(0, 300, 0, 20)
    descLabel.Position = UDim2.new(0, 120, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.TextTruncate = Enum.TextTruncate.AtEnd
    descLabel.Parent = card

    -- 价格标签
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Text = "💰 " .. item.price .. " 金币"
    priceLabel.TextColor3 = ShopUtils.COLORS.WARNING
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 16
    priceLabel.Size = UDim2.new(0, 150, 0, 20)
    priceLabel.Position = UDim2.new(0, 120, 0, 60)
    priceLabel.BackgroundTransparency = 1
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.TextTruncate = Enum.TextTruncate.AtEnd
    priceLabel.Parent = card

    -- 购买按钮
    local buyButton = ShopUtils.createButton("🛒 购买", ShopUtils.COLORS.SUCCESS, card, function()
        showQuantityDialog(itemId, "buy", item)
    end)
    buyButton.Position = UDim2.new(0, 300, 0, 85)
    buyButton.Size = UDim2.new(0, 100, 0, 25)

    -- 库存显示
    local stockLabel = Instance.new("TextLabel")
    stockLabel.Name = "StockLabel"
    stockLabel.Font = Enum.Font.Gotham
    stockLabel.TextSize = 12
    stockLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
    stockLabel.Size = UDim2.new(0, 120, 0, 20)
    stockLabel.Position = UDim2.new(1, -130, 0, 85)
    stockLabel.BackgroundTransparency = 1
    stockLabel.TextXAlignment = Enum.TextXAlignment.Right
    stockLabel.TextTruncate = Enum.TextTruncate.AtEnd
    stockLabel.Parent = card

    -- 使用从服务器获取的实时库存数据
    local stock = nil
    if shopData and shopData[itemId] and shopData[itemId].currentStock ~= nil then
        stock = shopData[itemId].currentStock
    elseif item.maxQuantity ~= nil then
        stock = item.maxQuantity
    end

    -- 检查每日限购信息
    local dailyPurchaseStatus = nil
    if playerData and playerData.id then
        local success, result = pcall(function()
            return nil
        end)

        if success then
            dailyPurchaseStatus = result
        else
            warn("⚠️ 获取每日购买状态失败，可能需要重新认证")
        end
    end

    -- 显示库存和每日限购信息
    local stockText = ""
    if stock == nil or stock == -1 then
        stockText = "库存: ∞"
    else
        stockText = "库存: " .. stock
        if stock <= 0 then
            buyButton.BackgroundColor3 = ShopUtils.COLORS.TEXT_MUTED
            buyButton.Text = "缺货"
            buyButton.Active = false
        end
    end

    -- 添加每日限购信息
    if dailyPurchaseStatus and dailyPurchaseStatus.hasLimit then
        stockText = stockText .. "\n今日限购: " .. dailyPurchaseStatus.remaining .. "/" .. dailyPurchaseStatus.dailyLimit

        if dailyPurchaseStatus.remaining <= 0 then
            buyButton.BackgroundColor3 = ShopUtils.COLORS.TEXT_MUTED
            buyButton.Text = "限购已满"
            buyButton.Active = false
        end
    end

    stockLabel.Text = stockText
    stockLabel.TextWrapped = true

    return card
end

-- 显示购买商品列表
function ShopBuy.showBuyItems(scrollFrame, shopData, playerData, showQuantityDialog)
    if not scrollFrame then return end

    -- 清空现有内容
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Card") then
            child:Destroy()
        end
    end

    local yPos = 0
    local itemsToShow = shopData or {}

    -- 将商品转换为数组并排序，确保membership类型商品排在最前面
    local sortedItems = {}
    if itemsToShow and type(itemsToShow) == "table" then
        for itemId, item in pairs(itemsToShow) do
            table.insert(sortedItems, {id = itemId, data = item})
        end

        -- 排序：membership优先，然后按分类，最后按名称
        table.sort(sortedItems, function(a, b)
            local aCategory = a.data.category or "default"
            local bCategory = b.data.category or "default"

            -- membership类型优先
            if aCategory == "membership" and bCategory ~= "membership" then
                return true
            elseif aCategory ~= "membership" and bCategory == "membership" then
                return false
            end

            -- 如果都是或都不是membership，按分类排序
            if aCategory ~= bCategory then
                return aCategory < bCategory
            end

            -- 同分类内按名称排序
            return (a.data.name or "") < (b.data.name or "")
        end)

        -- 显示排序后的商品
        for _, itemInfo in ipairs(sortedItems) do
            local card = ShopBuy.createItemCard(itemInfo.data, itemInfo.id, shopData, playerData, showQuantityDialog)
            card.Position = UDim2.new(0, 20, 0, yPos + 20)
            card.Parent = scrollFrame
            yPos = yPos + 140
        end
    end

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 40)
end

return ShopBuy
