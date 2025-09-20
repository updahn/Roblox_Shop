-- 商店卖出界面模块

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local ShopData = require(SharedModules:WaitForChild("ShopData"))
local ShopEvents = require(SharedModules:WaitForChild("ShopEvents"))
local ShopUtils = require(script.Parent.Parent:WaitForChild("ShopUtils"))

local ShopSell = {}

-- 创建商品卡片（卖出模式）
function ShopSell.createItemCard(item, itemId, shopData, playerData, showQuantityDialog)
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

    -- 卖出价格标签
    local sellPrice = math.floor(item.price * 0.8) -- 使用默认sell rate
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Text = "💰 " .. sellPrice .. " 金币"
    priceLabel.TextColor3 = ShopUtils.COLORS.SUCCESS
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 16
    priceLabel.Size = UDim2.new(0, 150, 0, 20)
    priceLabel.Position = UDim2.new(0, 120, 0, 60)
    priceLabel.BackgroundTransparency = 1
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.TextTruncate = Enum.TextTruncate.AtEnd
    priceLabel.Parent = card

    -- 卖出按钮
    local sellButton = ShopUtils.createButton("💰 卖出", ShopUtils.COLORS.WARNING, card, function()
        showQuantityDialog(itemId, "sell", item)
    end)
    sellButton.Position = UDim2.new(0, 300, 0, 85)
    sellButton.Size = UDim2.new(0, 100, 0, 25)

    -- 拥有数量显示
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

    local playerQuantity = (playerData and playerData.inventory[itemId]) or 0
    stockLabel.Text = "拥有: " .. playerQuantity

    -- 检查是否可以卖出
    local canSell = true -- 默认允许卖出，具体逻辑由服务器端控制

    if playerQuantity <= 0 then
        sellButton.BackgroundColor3 = ShopUtils.COLORS.TEXT_MUTED
        sellButton.Text = "无物品"
        sellButton.Active = false
    elseif not canSell then
        sellButton.BackgroundColor3 = ShopUtils.COLORS.TEXT_MUTED
        sellButton.Text = "无法出售"
        sellButton.Active = false
        stockLabel.Text = stockLabel.Text .. "\n(特殊物品)"
        stockLabel.TextWrapped = true
    end

    return card
end

-- 显示卖出商品列表
function ShopSell.showSellItems(scrollFrame, shopData, playerData, showQuantityDialog)
    if not scrollFrame then return end

    -- 清空现有内容
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Card") then
            child:Destroy()
        end
    end

    local yPos = 0
    local itemsToShow = {}

    -- 只显示玩家拥有的物品
    if playerData and playerData.inventory and type(playerData.inventory) == "table" then
        for itemId, quantity in pairs(playerData.inventory) do
            if quantity > 0 then
                -- 使用shopData中的物品数据
                local itemData = shopData and shopData[itemId]
                if itemData then
                    itemsToShow[itemId] = itemData
                end
            end
        end
    end

    if itemsToShow and type(itemsToShow) == "table" then
        for itemId, item in pairs(itemsToShow) do
            local card = ShopSell.createItemCard(item, itemId, shopData, playerData, showQuantityDialog)
            card.Position = UDim2.new(0, 20, 0, yPos + 20)
            card.Parent = scrollFrame
            yPos = yPos + 140
        end
    end

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 40)
end

return ShopSell
