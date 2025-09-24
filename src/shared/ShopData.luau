-- 商店系统共享数据定义
-- 包含商店相关的数据结构、常量和工具函数

local ShopData = {}

-- ==============================================
-- 商品类别定义
-- ==============================================
ShopData.Categories = {
    WEAPONS = "weapons",        -- 武器类
    ARMOR = "armor",           -- 防具类
    CONSUMABLES = "consumables", -- 消耗品类
    MATERIALS = "materials",    -- 材料类
    BOOKS = "books",           -- 书籍类
    TOOLS = "tools",           -- 工具类
    MEMBERSHIP = "membership"   -- 会员类
}

-- 类别显示名称
ShopData.CategoryNames = {
    [ShopData.Categories.WEAPONS] = "⚔️ 武器",
    [ShopData.Categories.ARMOR] = "🛡️ 防具",
    [ShopData.Categories.CONSUMABLES] = "🧪 消耗品",
    [ShopData.Categories.MATERIALS] = "💎 材料",
    [ShopData.Categories.BOOKS] = "📚 书籍",
    [ShopData.Categories.TOOLS] = "🔧 工具",
    [ShopData.Categories.MEMBERSHIP] = "👑 会员"
}

-- ==============================================
-- 交易类型定义
-- ==============================================
ShopData.TransactionTypes = {
    BUY = "buy",
    SELL = "sell"
}

-- ==============================================
-- 数据验证函数
-- ==============================================

-- 验证商品数据结构
function ShopData.validateItem(item)
    if type(item) ~= "table" then
        return false, "商品数据必须是表格类型"
    end

    -- 必需字段验证
    local requiredFields = {"id", "name", "price", "category"}
    for _, field in ipairs(requiredFields) do
        if not item[field] then
            return false, "缺少必需字段: " .. field
        end
    end

    -- 类型验证
    if type(item.price) ~= "number" or item.price < 0 then
        return false, "价格必须是非负数字"
    end

    if not ShopData.Categories[string.upper(item.category)] and
       not ShopData.CategoryNames[item.category] then
        return false, "无效的商品类别: " .. tostring(item.category)
    end

    return true
end

-- 验证交易数据
function ShopData.validateTransaction(transaction)
    if type(transaction) ~= "table" then
        return false, "交易数据必须是表格类型"
    end

    local requiredFields = {"id", "playerId", "itemId", "quantity", "type", "timestamp"}
    for _, field in ipairs(requiredFields) do
        if not transaction[field] then
            return false, "缺少必需字段: " .. field
        end
    end

    -- 交易类型验证
    local validTypes = {
        [ShopData.TransactionTypes.BUY] = true,
        [ShopData.TransactionTypes.SELL] = true
    }

    if not validTypes[transaction.type] then
        return false, "无效的交易类型: " .. tostring(transaction.type)
    end

    return true
end

-- ==============================================
-- 工具函数
-- ==============================================

-- 获取类别显示名称
function ShopData.getCategoryDisplayName(category)
    return ShopData.CategoryNames[category] or category
end

-- 格式化价格显示
function ShopData.formatPrice(price)
    if not price or type(price) ~= "number" then
        return "0"
    end

    -- 格式化大数字（千、万、十万等）
    if price >= 10000 then
        return string.format("%.1f万", price / 10000)
    elseif price >= 1000 then
        return string.format("%.1fK", price / 1000)
    else
        return tostring(price)
    end
end

-- 计算卖出价格
function ShopData.calculateSellPrice(buyPrice, sellRate)
    sellRate = sellRate or 0.8 -- 默认80%的卖出率
    if not buyPrice or type(buyPrice) ~= "number" or buyPrice <= 0 then
        return 0
    end
    return math.max(1, math.floor(buyPrice * sellRate))
end

-- 检查商品是否可以卖出
function ShopData.canSellItem(item)
    if not item then return false end

    -- 检查canSell字段
    if item.canSell ~= nil then
        return item.canSell
    end

    -- 默认情况下，价格大于0的商品可以卖出
    return item.price and item.price > 0
end

-- 格式化库存显示
function ShopData.formatStock(stock)
    if not stock or stock == -1 then
        return "∞"
    elseif stock == 0 then
        return "售罄"
    else
        return tostring(stock)
    end
end

-- ==============================================
-- 常量定义
-- ==============================================

-- 默认配置
ShopData.Defaults = {
    SELL_RATE = 0.8,           -- 默认卖出率
    MAX_QUANTITY = 999,        -- 最大购买数量
    TRANSACTION_HISTORY_LIMIT = 50 -- 交易历史记录限制
}

-- UI相关常量
ShopData.UI = {
    ITEM_FRAME_HEIGHT = 120,   -- 商品框架高度
    PADDING = 10,              -- 内边距
    SCROLL_SPEED = 50          -- 滚动速度
}

print("📦 商店共享数据模块已加载")

return ShopData
