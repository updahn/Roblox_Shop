-- 商店系统数据库初始化脚本
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
    `id` VARCHAR(255) NOT NULL PRIMARY KEY COMMENT '用户ID (Roblox UserId)',
    `username` VARCHAR(255) NOT NULL COMMENT '用户名',
    `display_name` VARCHAR(255) DEFAULT NULL COMMENT '显示名称',
    `coins` BIGINT NOT NULL DEFAULT 3000 COMMENT '用户金币',
    `is_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否为管理员',
    `status` ENUM('active', 'inactive', 'banned') NOT NULL DEFAULT 'active' COMMENT '用户状态',
    `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '最后登录时间',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY `idx_username` (`username`),
    KEY `idx_status` (`status`),
    KEY `idx_is_admin` (`is_admin`),
    KEY `idx_created_at` (`created_at`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户信息表（包含管理员功能）';
-- 商品表
DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
    `id` VARCHAR(255) NOT NULL PRIMARY KEY COMMENT '商品ID',
    `name` VARCHAR(255) NOT NULL COMMENT '商品名称',
    `description` TEXT COMMENT '商品描述',
    `price` INT NOT NULL COMMENT '商品价格',
    `sell_price` INT DEFAULT NULL COMMENT '出售价格(为空时使用price*0.8)',
    `max_quantity` INT DEFAULT NULL COMMENT '最大购买数量(为空表示无限)',
    `current_stock` INT DEFAULT -1 COMMENT '当前库存(-1表示无限)',
    `category` VARCHAR(255) DEFAULT 'default' COMMENT '商品分类',
    `image_url` VARCHAR(500) DEFAULT NULL COMMENT '商品图片URL',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否启用',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序权重',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    KEY `idx_category` (`category`),
    KEY `idx_is_active` (`is_active`),
    KEY `idx_sort_order` (`sort_order`),
    KEY `idx_price` (`price`),
    KEY `idx_current_stock` (`current_stock`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '商品信息表';
-- 插入初始商品数据
INSERT IGNORE INTO `items` (
        `id`,
        `name`,
        `description`,
        `price`,
        `sell_price`,
        `category`,
        `image_url`,
        `sort_order`
    )
VALUES (
        'sword_basic',
        '基础剑',
        '一把普通的铁剑，适合新手使用。攻击力+10',
        100,
        80,
        'weapons',
        'rbxasset://textures/sword_basic.png',
        1
    ),
    (
        'sword_steel',
        '钢剑',
        '锻造精良的钢剑，比基础剑更加锋利。攻击力+25',
        250,
        200,
        'weapons',
        'rbxasset://textures/sword_steel.png',
        2
    ),
    (
        'sword_enchanted',
        '附魔剑',
        '被魔法力量加持的剑，散发着神秘光芒。攻击力+50',
        500,
        400,
        'weapons',
        'rbxasset://textures/sword_enchanted.png',
        3
    ),
    (
        'shield_wooden',
        '木制盾牌',
        '简单的木制盾牌，提供基础防护。防御力+5',
        80,
        64,
        'armor',
        'rbxasset://textures/shield_wooden.png',
        4
    ),
    (
        'shield_iron',
        '铁制盾牌',
        '坚固的铁制盾牌，能够抵挡更强的攻击。防御力+15',
        180,
        144,
        'armor',
        'rbxasset://textures/shield_iron.png',
        5
    ),
    (
        'armor_leather',
        '皮甲',
        '轻便的皮革护甲，适合快速移动。防御力+8',
        150,
        120,
        'armor',
        'rbxasset://textures/armor_leather.png',
        6
    ),
    (
        'armor_chainmail',
        '锁子甲',
        '金属制成的防具，提供优秀的保护。防御力+20',
        300,
        240,
        'armor',
        'rbxasset://textures/armor_chainmail.png',
        7
    ),
    (
        'potion_health',
        '生命药水',
        '恢复50点生命值的药水，战斗必备',
        50,
        40,
        'consumables',
        'rbxasset://textures/potion_health.png',
        8
    ),
    (
        'potion_mana',
        '魔法药水',
        '恢复30点魔法值的药水，施法者必备',
        60,
        48,
        'consumables',
        'rbxasset://textures/potion_mana.png',
        9
    ),
    (
        'potion_strength',
        '力量药水',
        '临时增加攻击力的药水，持续5分钟',
        120,
        96,
        'consumables',
        'rbxasset://textures/potion_strength.png',
        10
    ),
    (
        'scroll_teleport',
        '传送卷轴',
        '瞬间传送到指定地点的魔法卷轴',
        150,
        120,
        'consumables',
        'rbxasset://textures/scroll_teleport.png',
        11
    ),
    (
        'food_bread',
        '面包',
        '简单的食物，恢复少量生命值',
        20,
        16,
        'consumables',
        'rbxasset://textures/food_bread.png',
        12
    ),
    (
        'gem_ruby',
        '红宝石',
        '珍贵的红色宝石，可用于装备强化',
        200,
        160,
        'materials',
        'rbxasset://textures/gem_ruby.png',
        13
    ),
    (
        'gem_sapphire',
        '蓝宝石',
        '稀有的蓝色宝石，蕴含魔法能量',
        220,
        176,
        'materials',
        'rbxasset://textures/gem_sapphire.png',
        14
    ),
    (
        'gem_emerald',
        '绿宝石',
        '神秘的绿色宝石，据说有治愈能力',
        250,
        200,
        'materials',
        'rbxasset://textures/gem_emerald.png',
        15
    ),
    (
        'ore_iron',
        '铁矿石',
        '常见的金属矿石，用于制作装备',
        30,
        24,
        'materials',
        'rbxasset://textures/ore_iron.png',
        16
    ),
    (
        'ore_gold',
        '金矿石',
        '珍贵的黄金矿石，价值不菲',
        100,
        80,
        'materials',
        'rbxasset://textures/ore_gold.png',
        17
    ),
    (
        'wood_oak',
        '橡木',
        '坚硬的木材，制作工具的好材料',
        25,
        20,
        'materials',
        'rbxasset://textures/wood_oak.png',
        18
    ),
    (
        'book_spells',
        '法术书',
        '记录着各种魔法咒语的古老书籍',
        180,
        144,
        'books',
        'rbxasset://textures/book_spells.png',
        19
    ),
    (
        'book_history',
        '历史书',
        '记录着这个世界历史的珍贵典籍',
        80,
        64,
        'books',
        'rbxasset://textures/book_history.png',
        20
    ),
    (
        'map_world',
        '世界地图',
        '详细的世界地图，探险者必备',
        120,
        96,
        'tools',
        'rbxasset://textures/map_world.png',
        21
    ),
    (
        'pickaxe',
        '镐子',
        '挖掘矿石的工具，探矿必备',
        90,
        72,
        'tools',
        'rbxasset://textures/pickaxe.png',
        22
    ),
    (
        'fishing_rod',
        '钓鱼竿',
        '在河边湖边钓鱼的工具',
        70,
        56,
        'tools',
        'rbxasset://textures/fishing_rod.png',
        23
    );
-- 用户物品表
DROP TABLE IF EXISTS `user_items`;
CREATE TABLE `user_items` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(255) NOT NULL COMMENT '用户ID',
    `item_id` VARCHAR(255) NOT NULL COMMENT '商品ID',
    `quantity` INT NOT NULL DEFAULT 0 COMMENT '拥有数量',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY `idx_user_item` (`user_id`, `item_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`item_id`) REFERENCES `items`(`id`) ON DELETE CASCADE,
    KEY `idx_user_id` (`user_id`),
    KEY `idx_item_id` (`item_id`),
    KEY `idx_quantity` (`quantity`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户物品拥有表';
-- 交易记录表
DROP TABLE IF EXISTS `transactions`;
CREATE TABLE `transactions` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(255) NOT NULL COMMENT '用户ID',
    `type` ENUM('buy', 'sell', 'admin') NOT NULL COMMENT '交易类型',
    `item_id` VARCHAR(255) NOT NULL COMMENT '商品ID',
    `quantity` INT NOT NULL COMMENT '交易数量',
    `unit_price` INT NOT NULL COMMENT '单价',
    `total_amount` INT NOT NULL COMMENT '总金额',
    `coins_before` BIGINT NOT NULL COMMENT '交易前金币',
    `coins_after` BIGINT NOT NULL COMMENT '交易后金币',
    `admin_user_id` VARCHAR(255) DEFAULT NULL COMMENT '管理员用户ID(如果是管理员操作)',
    `notes` TEXT DEFAULT NULL COMMENT '备注',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '交易时间',
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`item_id`) REFERENCES `items`(`id`) ON DELETE CASCADE,
    KEY `idx_user_id` (`user_id`),
    KEY `idx_type` (`type`),
    KEY `idx_item_id` (`item_id`),
    KEY `idx_created_at` (`created_at`),
    KEY `idx_admin_user_id` (`admin_user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '交易记录表';
-- 系统配置表
DROP TABLE IF EXISTS `system_config`;
CREATE TABLE `system_config` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `config_key` VARCHAR(255) NOT NULL COMMENT '配置键',
    `config_value` TEXT NOT NULL COMMENT '配置值',
    `description` VARCHAR(500) DEFAULT NULL COMMENT '配置描述',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否启用',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY `idx_config_key` (`config_key`),
    KEY `idx_is_active` (`is_active`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统配置表';
-- 插入默认系统配置
INSERT IGNORE INTO `system_config` (`config_key`, `config_value`, `description`)
VALUES ('shop_enabled', 'true', '商店是否启用'),
    ('default_user_coins', '3000', '新用户默认金币'),
    (
        'transaction_log_retention_days',
        '90',
        '交易日志保留天数'
    ),
    ('sell_rate', '0.8', '物品出售价格比例'),
    ('max_coins', '999999999', '用户最大金币数量'),
    ('api_version', '1.0.0', 'API版本号'),
    ('admin_default_coins', '999999', '管理员默认金币数'),
    ('shop_tax_rate', '0.05', '商店交易税率'),
    ('daily_login_bonus', '100', '每日登录奖励金币'),
    (
        'rate_limit_window_ms',
        '900000',
        'API请求限制时间窗口(毫秒)'
    ),
    ('rate_limit_max_requests', '100', 'API请求限制最大次数');
SET FOREIGN_KEY_CHECKS = 1;