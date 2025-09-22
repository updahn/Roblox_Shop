-- 商品初始化模块
-- 包含所有来自 init.sql 的商品数据

local DataStoreManager = require(script.Parent.Parent.data.DataStoreManager)

local ItemsInitializer = {}

-- 根据 init.sql 定义的完整商品数据
local function getInitialItemsData()
    return {
        -- 武器类
        ["sword_basic"] = {
            id = "sword_basic",
            name = "基础剑",
            description = "一把普通的铁剑，适合新手使用。攻击力+10",
            price = 100,
            sellPrice = 80,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "weapons",
            imageUrl = "rbxasset://textures/sword_basic.png",
            isActive = true,
            sortOrder = 1,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["sword_steel"] = {
            id = "sword_steel",
            name = "钢剑",
            description = "锻造精良的钢剑，比基础剑更加锋利。攻击力+25",
            price = 250,
            sellPrice = 200,
            maxQuantity = nil,
            currentStock = 10,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "weapons",
            imageUrl = "rbxasset://textures/sword_steel.png",
            isActive = true,
            sortOrder = 2,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["sword_enchanted"] = {
            id = "sword_enchanted",
            name = "附魔剑",
            description = "被魔法力量加持的剑，散发着神秘光芒。攻击力+50 (每日限购1件，无法卖出)",
            price = 500,
            sellPrice = 0,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 1,
            canSell = false,
            category = "weapons",
            imageUrl = "rbxasset://textures/sword_enchanted.png",
            isActive = true,
            sortOrder = 3,
            createdAt = os.time(),
            updatedAt = os.time()
        },

        -- 防具类
        ["shield_wooden"] = {
            id = "shield_wooden",
            name = "木制盾牌",
            description = "简单的木制盾牌，提供基础防护。防御力+5",
            price = 80,
            sellPrice = 64,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "armor",
            imageUrl = "rbxasset://textures/shield_wooden.png",
            isActive = true,
            sortOrder = 4,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["shield_iron"] = {
            id = "shield_iron",
            name = "铁制盾牌",
            description = "坚固的铁制盾牌，能够抵挡更强的攻击。防御力+15",
            price = 180,
            sellPrice = 144,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "armor",
            imageUrl = "rbxasset://textures/shield_iron.png",
            isActive = true,
            sortOrder = 5,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["armor_leather"] = {
            id = "armor_leather",
            name = "皮甲",
            description = "轻便的皮革护甲，适合快速移动。防御力+8",
            price = 150,
            sellPrice = 120,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "armor",
            imageUrl = "rbxasset://textures/armor_leather.png",
            isActive = true,
            sortOrder = 6,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["armor_chainmail"] = {
            id = "armor_chainmail",
            name = "锁子甲",
            description = "金属制成的防具，提供优秀的保护。防御力+20",
            price = 300,
            sellPrice = 240,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "armor",
            imageUrl = "rbxasset://textures/armor_chainmail.png",
            isActive = true,
            sortOrder = 7,
            createdAt = os.time(),
            updatedAt = os.time()
        },

        -- 消耗品类
        ["potion_health"] = {
            id = "potion_health",
            name = "生命药水",
            description = "恢复50点生命值的药水，战斗必备 (每日限购5瓶)",
            price = 50,
            sellPrice = 40,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 5,
            canSell = true,
            category = "consumables",
            imageUrl = "rbxasset://textures/potion_health.png",
            isActive = true,
            sortOrder = 8,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["potion_mana"] = {
            id = "potion_mana",
            name = "魔法药水",
            description = "恢复30点魔法值的药水，施法者必备 (每日限购5瓶)",
            price = 60,
            sellPrice = 48,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 5,
            canSell = true,
            category = "consumables",
            imageUrl = "rbxasset://textures/potion_mana.png",
            isActive = true,
            sortOrder = 9,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["potion_strength"] = {
            id = "potion_strength",
            name = "力量药水",
            description = "临时增加攻击力的药水，持续5分钟 (每日限购3瓶)",
            price = 120,
            sellPrice = 96,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 3,
            canSell = true,
            category = "consumables",
            imageUrl = "rbxasset://textures/potion_strength.png",
            isActive = true,
            sortOrder = 10,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["scroll_teleport"] = {
            id = "scroll_teleport",
            name = "传送卷轴",
            description = "瞬间传送到指定地点的魔法卷轴 (每日限购2张，无法卖出)",
            price = 150,
            sellPrice = 0,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 2,
            canSell = false,
            category = "consumables",
            imageUrl = "rbxasset://textures/scroll_teleport.png",
            isActive = true,
            sortOrder = 11,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["food_bread"] = {
            id = "food_bread",
            name = "面包",
            description = "简单的食物，恢复少量生命值",
            price = 20,
            sellPrice = 16,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "consumables",
            imageUrl = "rbxasset://textures/food_bread.png",
            isActive = true,
            sortOrder = 12,
            createdAt = os.time(),
            updatedAt = os.time()
        },

        -- 材料类
        ["gem_ruby"] = {
            id = "gem_ruby",
            name = "红宝石",
            description = "珍贵的红色宝石，可用于装备强化 (每日限购2颗)",
            price = 200,
            sellPrice = 160,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 2,
            canSell = true,
            category = "materials",
            imageUrl = "rbxasset://textures/gem_ruby.png",
            isActive = true,
            sortOrder = 13,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["gem_sapphire"] = {
            id = "gem_sapphire",
            name = "蓝宝石",
            description = "稀有的蓝色宝石，蕴含魔法能量 (每日限购2颗)",
            price = 220,
            sellPrice = 176,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 2,
            canSell = true,
            category = "materials",
            imageUrl = "rbxasset://textures/gem_sapphire.png",
            isActive = true,
            sortOrder = 14,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["gem_emerald"] = {
            id = "gem_emerald",
            name = "绿宝石",
            description = "神秘的绿色宝石，据说有治愈能力 (每日限购2颗)",
            price = 250,
            sellPrice = 200,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 2,
            canSell = true,
            category = "materials",
            imageUrl = "rbxasset://textures/gem_emerald.png",
            isActive = true,
            sortOrder = 15,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["ore_iron"] = {
            id = "ore_iron",
            name = "铁矿石",
            description = "常见的金属矿石，用于制作装备",
            price = 30,
            sellPrice = 24,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "materials",
            imageUrl = "rbxasset://textures/ore_iron.png",
            isActive = true,
            sortOrder = 16,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["ore_gold"] = {
            id = "ore_gold",
            name = "金矿石",
            description = "珍贵的黄金矿石，价值不菲 (每日限购10个)",
            price = 100,
            sellPrice = 80,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 10,
            canSell = true,
            category = "materials",
            imageUrl = "rbxasset://textures/ore_gold.png",
            isActive = true,
            sortOrder = 17,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["wood_oak"] = {
            id = "wood_oak",
            name = "橡木",
            description = "坚硬的木材，制作工具的好材料",
            price = 25,
            sellPrice = 20,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "materials",
            imageUrl = "rbxasset://textures/wood_oak.png",
            isActive = true,
            sortOrder = 18,
            createdAt = os.time(),
            updatedAt = os.time()
        },

        -- 书籍类
        ["book_spells"] = {
            id = "book_spells",
            name = "法术书",
            description = "记录着各种魔法咒语的古老书籍 (每日限购1本，无法卖出)",
            price = 180,
            sellPrice = 0,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 1,
            canSell = false,
            category = "books",
            imageUrl = "rbxasset://textures/book_spells.png",
            isActive = true,
            sortOrder = 19,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["book_history"] = {
            id = "book_history",
            name = "历史书",
            description = "记录着这个世界历史的珍贵典籍",
            price = 80,
            sellPrice = 64,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "books",
            imageUrl = "rbxasset://textures/book_history.png",
            isActive = true,
            sortOrder = 20,
            createdAt = os.time(),
            updatedAt = os.time()
        },

        -- 工具类
        ["map_world"] = {
            id = "map_world",
            name = "世界地图",
            description = "详细的世界地图，探险者必备 (每日限购1张)",
            price = 120,
            sellPrice = 96,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 1,
            canSell = true,
            category = "tools",
            imageUrl = "rbxasset://textures/map_world.png",
            isActive = true,
            sortOrder = 21,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["pickaxe"] = {
            id = "pickaxe",
            name = "镐子",
            description = "挖掘矿石的工具，探矿必备",
            price = 90,
            sellPrice = 72,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "tools",
            imageUrl = "rbxasset://textures/pickaxe.png",
            isActive = true,
            sortOrder = 22,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["fishing_rod"] = {
            id = "fishing_rod",
            name = "钓鱼竿",
            description = "在河边湖边钓鱼的工具",
            price = 70,
            sellPrice = 56,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = nil,
            canSell = true,
            category = "tools",
            imageUrl = "rbxasset://textures/fishing_rod.png",
            isActive = true,
            sortOrder = 23,
            createdAt = os.time(),
            updatedAt = os.time()
        },

        -- 会员类商品
        ["monthly_membership"] = {
            id = "monthly_membership",
            name = "月卡会员",
            description = "购买后获得30天会员特权，每日登录可获得100金币奖励 (每日限购1张，无法卖出)",
            price = 1000,
            sellPrice = 0,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 1,
            canSell = false,
            category = "membership",
            imageUrl = "rbxasset://textures/monthly_membership.png",
            isActive = true,
            sortOrder = 24,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["weekly_membership"] = {
            id = "weekly_membership",
            name = "周卡会员",
            description = "购买后获得7天会员特权，每日登录可获得100金币奖励 (每日限购2张，无法卖出)",
            price = 300,
            sellPrice = 0,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 2,
            canSell = false,
            category = "membership",
            imageUrl = "rbxasset://textures/weekly_membership.png",
            isActive = true,
            sortOrder = 25,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["quarterly_membership"] = {
            id = "quarterly_membership",
            name = "季卡会员",
            description = "购买后获得90天会员特权，每日登录可获得100金币奖励，超值优惠！ (每日限购1张，无法卖出)",
            price = 2700,
            sellPrice = 0,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 1,
            canSell = false,
            category = "membership",
            imageUrl = "rbxasset://textures/quarterly_membership.png",
            isActive = true,
            sortOrder = 26,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["premium_membership"] = {
            id = "premium_membership",
            name = "高级月卡",
            description = "购买后获得30天高级会员特权，每日登录可获得200金币奖励 (每日限购1张，无法卖出)",
            price = 1800,
            sellPrice = 0,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 1,
            canSell = false,
            category = "membership",
            imageUrl = "rbxasset://textures/premium_membership.png",
            isActive = true,
            sortOrder = 27,
            createdAt = os.time(),
            updatedAt = os.time()
        },
        ["vip_membership"] = {
            id = "vip_membership",
            name = "VIP年卡",
            description = "购买后获得365天VIP会员特权，每日登录可获得150金币奖励，一年无忧！ (每日限购1张，无法卖出)",
            price = 10000,
            sellPrice = 0,
            maxQuantity = nil,
            currentStock = -1,
            dailyPurchaseLimit = 1,
            canSell = false,
            category = "membership",
            imageUrl = "rbxasset://textures/vip_membership.png",
            isActive = true,
            sortOrder = 28,
            createdAt = os.time(),
            updatedAt = os.time()
        }
    }
end

-- 初始化所有商品数据
function ItemsInitializer.initializeAllItems()
    local existingItems = DataStoreManager.getAllItems()

    -- 如果商品数据为空或者数量较少，则初始化所有商品
    local existingCount = 0
    for _ in pairs(existingItems) do
        existingCount = existingCount + 1
    end

    if existingCount < 5 then -- 如果现有商品少于5个，则进行初始化
        print("🛒 开始初始化商品数据...")

        local allItems = getInitialItemsData()
        local success = DataStoreManager.safeSetAsync("ITEMS", "all_items", allItems)

        if success then
            local totalCount = 0
            for _ in pairs(allItems) do
                totalCount = totalCount + 1
            end
            print("✅ 商品数据初始化成功！共初始化", totalCount, "个商品")

            -- 按类别统计商品数量
            local categoryCount = {}
            for _, item in pairs(allItems) do
                categoryCount[item.category] = (categoryCount[item.category] or 0) + 1
            end

            print("📦 商品分类统计:")
            for category, count in pairs(categoryCount) do
                print("   ", category, ":", count, "个")
            end
        else
            warn("❌ 商品数据初始化失败！")
        end
    else
        print("✅ 商品数据已存在，跳过初始化 (现有", existingCount, "个商品)")
    end
end

-- 获取特定类别的商品数量
function ItemsInitializer.getCategoryItemCount(category)
    local allItems = getInitialItemsData()
    local count = 0

    for _, item in pairs(allItems) do
        if item.category == category then
            count = count + 1
        end
    end

    return count
end

-- 获取所有商品类别
function ItemsInitializer.getAllCategories()
    local allItems = getInitialItemsData()
    local categories = {}

    for _, item in pairs(allItems) do
        if not categories[item.category] then
            categories[item.category] = true
        end
    end

    local categoryList = {}
    for category in pairs(categories) do
        table.insert(categoryList, category)
    end

    return categoryList
end

-- 获取商品总数
function ItemsInitializer.getTotalItemCount()
    local allItems = getInitialItemsData()
    local count = 0

    for _ in pairs(allItems) do
        count = count + 1
    end

    return count
end

return ItemsInitializer
