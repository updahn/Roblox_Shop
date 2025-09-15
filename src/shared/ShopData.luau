-- 商店系统共享数据结构

local ShopData = {}

-- 物品数据结构
export type Item = {
    id: string,
    name: string,
    price: number,
    maxQuantity: number?, -- nil表示无限
    description: string?,
    icon: string?,
    imageId: string?, -- 商品图片ID
    category: string?, -- 商品分类
    sellPrice: number? -- 卖出价格，如果nil则自动计算为原价80%
}

-- 玩家物品数据结构
export type PlayerItem = {
    itemId: string,
    quantity: number
}

-- 玩家数据
export type PlayerData = {
    coins: number,
    items: {[string]: PlayerItem}
}

-- 商店配置
local SHOP_ITEMS: {[string]: Item} = {
    ["sword"] = {
        id = "sword",
        name = "铁剑",
        price = 100,
        maxQuantity = 10,
        description = "一把锋利的铁剑，增加攻击力",
        icon = "⚔️",
        imageId = "rbxassetid://6031075938", -- 剑的图片
        category = "武器",
        sellPrice = 80
    },
    ["potion"] = {
        id = "potion",
        name = "生命药水",
        price = 50,
        maxQuantity = nil, -- 无限
        description = "恢复50点生命值的神奇药水",
        icon = "🧪",
        imageId = "rbxassetid://6031068421", -- 药水图片
        category = "消耗品",
        sellPrice = 40
    },
    ["shield"] = {
        id = "shield",
        name = "木盾",
        price = 80,
        maxQuantity = 15,
        description = "提供基础防御的木制盾牌",
        icon = "🛡️",
        imageId = "rbxassetid://6031068421", -- 盾牌图片
        category = "防具",
        sellPrice = 64
    },
    ["gem"] = {
        id = "gem",
        name = "魔法宝石",
        price = 200,
        maxQuantity = 5,
        description = "蕴含强大魔力的神秘宝石",
        icon = "💎",
        imageId = "rbxassetid://6031068421", -- 宝石图片
        category = "魔法",
        sellPrice = 160
    },
    ["armor"] = {
        id = "armor",
        name = "皮革护甲",
        price = 150,
        maxQuantity = 8,
        description = "轻便但有效的皮革护甲",
        icon = "🥼",
        imageId = "rbxassetid://6031068421", -- 护甲图片
        category = "防具",
        sellPrice = 120
    },
    ["bow"] = {
        id = "bow",
        name = "长弓",
        price = 120,
        maxQuantity = 12,
        description = "精准的远程武器",
        icon = "🏹",
        imageId = "rbxassetid://6031068421", -- 弓箭图片
        category = "武器",
        sellPrice = 96
    },
    ["scroll"] = {
        id = "scroll",
        name = "魔法卷轴",
        price = 75,
        maxQuantity = nil, -- 无限
        description = "记录着古老咒语的卷轴",
        icon = "📜",
        imageId = "rbxassetid://6031068421", -- 卷轴图片
        category = "魔法",
        sellPrice = 60
    },
    ["food"] = {
        id = "food",
        name = "面包",
        price = 25,
        maxQuantity = nil, -- 无限
        description = "美味的面包，恢复少量生命值",
        icon = "🍞",
        imageId = "rbxassetid://6031068421", -- 面包图片
        category = "消耗品",
        sellPrice = 20
    }
}

-- 获取商店物品
function ShopData.getShopItems(): {[string]: Item}
    return SHOP_ITEMS
end

-- 获取特定物品
function ShopData.getItem(itemId: string): Item?
    return SHOP_ITEMS[itemId]
end

-- 创建默认玩家数据
function ShopData.createDefaultPlayerData(): PlayerData
    return {
        coins = 3000, -- 初始金币
        items = {}
    }
end

-- 计算卖出价格（原价的80%）
function ShopData.calculateSellPrice(price: number): number
    return math.floor(price * 0.8)
end

-- 获取指定分类的物品
function ShopData.getItemsByCategory(category: string): {[string]: Item}
    local result = {}
    for itemId, item in pairs(SHOP_ITEMS) do
        if item.category == category then
            result[itemId] = item
        end
    end
    return result
end

-- 获取所有分类
function ShopData.getCategories(): {string}
    local categories = {}
    local seen = {}
    for _, item in pairs(SHOP_ITEMS) do
        if item.category and not seen[item.category] then
            table.insert(categories, item.category)
            seen[item.category] = true
        end
    end
    return categories
end

-- 获取物品的实际卖出价格
function ShopData.getActualSellPrice(item: Item): number
    return item.sellPrice or ShopData.calculateSellPrice(item.price)
end

-- 导出 SHOP_ITEMS 供直接访问
ShopData.SHOP_ITEMS = SHOP_ITEMS

return ShopData
