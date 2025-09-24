-- 商店系统共享类型定义
-- 本模块包含所有系统用到的类型定义和常量

local Types = {}

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

-- 会员数据类型
export type MembershipData = {
    hasMembership: boolean,
    isValid: boolean,
    daysRemaining: number,
    membershipType: string?,
    startDate: string?,
    endDate: string?,
    dailyReward: number
}

-- 交易记录类型
export type Transaction = {
    id: string,
    itemId: string,
    itemName: string,
    type: string, -- "buy" | "sell"
    quantity: number,
    unitPrice: number,
    totalAmount: number,
    transactionDate: string,
    createdAt: number,
    timestamp: number
}

-- 用户统计数据类型
export type UserStats = {
    totalPurchases: number,
    totalSales: number,
    totalSpent: number,
    totalEarned: number
}

-- 客户端玩家数据类型
export type ClientPlayerData = {
    coins: number,
    inventory: {[string]: number},
    membership: MembershipData,
    stats: UserStats,
    transactionHistory: {Transaction}?
}

-- 常量定义
Types.DEFAULT_SELL_RATE = 0.8

-- 工具函数

-- 计算卖出价格（使用默认的sell_rate）
function Types.calculateSellPrice(price: number, sellRate: number?): number
    local rate = sellRate or Types.DEFAULT_SELL_RATE
    return math.floor(price * rate)
end

return Types
