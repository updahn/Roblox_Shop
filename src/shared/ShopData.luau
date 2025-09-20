-- 商店系统共享数据类型定义
-- 本模块只包含类型定义和常量，不包含业务逻辑

local ShopData = {}

-- 物品数据结构
export type Item = {
    id: string,
    name: string,
    price: number,
    maxQuantity: number?, -- nil表示无限
    currentStock: number?, -- 当前库存
    description: string?,
    icon: string?,
    imageId: string?, -- 商品图片ID
    category: string?, -- 商品分类
    sellPrice: number? -- 卖出价格，如果nil则自动计算为原价*sell_rate（从系统配置获取）
}

-- 玩家物品数据结构
export type PlayerItem = {
    itemId: string,
    quantity: number
}

-- 玩家数据
export type PlayerData = {
    id: string,
    username: string,
    displayName: string?,
    coins: number,
    items: {[string]: number}, -- itemId -> quantity
    totalEarned: number?,
    totalSpent: number?,
    createdAt: string?,
    lastLogin: string?
}

-- 常量定义
ShopData.DEFAULT_SELL_RATE = 0.8

-- 工具函数

-- 计算卖出价格（使用默认的sell_rate）
function ShopData.calculateSellPrice(price: number, sellRate: number?): number
    local rate = sellRate or ShopData.DEFAULT_SELL_RATE
    return math.floor(price * rate)
end

return ShopData
