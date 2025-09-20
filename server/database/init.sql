-- 商店系统数据库初始化脚本
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
-- ================================================
-- 表结构创建
-- ================================================
-- 用户信息表（包含管理员功能）
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
-- 商品信息表
DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
    `id` VARCHAR(255) NOT NULL PRIMARY KEY COMMENT '商品ID',
    `name` VARCHAR(255) NOT NULL COMMENT '商品名称',
    `description` TEXT COMMENT '商品描述',
    `price` INT NOT NULL COMMENT '商品价格',
    `sell_price` INT DEFAULT NULL COMMENT '出售价格(为空时使用price*0.8)',
    `max_quantity` INT DEFAULT NULL COMMENT '最大购买数量(为空表示无限)',
    `current_stock` INT DEFAULT -1 COMMENT '当前库存(-1表示无限)',
    `daily_purchase_limit` INT DEFAULT NULL COMMENT '每日购买限制(为空表示无限制)',
    `can_sell` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否可以卖出(特殊物品设为false)',
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
-- 用户物品拥有表
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
-- 统一交易记录表（包含购买、出售、每日限购记录）
DROP TABLE IF EXISTS `daily_purchases`;
DROP TABLE IF EXISTS `transactions`;
CREATE TABLE `transactions` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(255) NOT NULL COMMENT '用户ID',
    `type` ENUM(
        'buy',
        'sell',
        'admin',
        'daily_reward',
        'membership_purchase'
    ) NOT NULL COMMENT '交易类型',
    `item_id` VARCHAR(255) DEFAULT NULL COMMENT '商品ID（奖励类型可为空）',
    `quantity` INT NOT NULL COMMENT '交易数量',
    `unit_price` INT NOT NULL DEFAULT 0 COMMENT '单价',
    `total_amount` INT NOT NULL COMMENT '总金额',
    `coins_before` BIGINT NOT NULL COMMENT '交易前金币',
    `coins_after` BIGINT NOT NULL COMMENT '交易后金币',
    `transaction_date` DATE NOT NULL COMMENT '交易日期',
    `admin_user_id` VARCHAR(255) DEFAULT NULL COMMENT '管理员用户ID(如果是管理员操作)',
    `related_id` BIGINT DEFAULT NULL COMMENT '关联ID（如月卡ID、奖励ID等）',
    `notes` TEXT DEFAULT NULL COMMENT '备注',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '交易时间',
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    KEY `idx_user_id` (`user_id`),
    KEY `idx_type` (`type`),
    KEY `idx_item_id` (`item_id`),
    KEY `idx_transaction_date` (`transaction_date`),
    KEY `idx_user_date` (`user_id`, `transaction_date`),
    KEY `idx_user_item_date` (`user_id`, `item_id`, `transaction_date`),
    KEY `idx_created_at` (`created_at`),
    KEY `idx_admin_user_id` (`admin_user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '统一交易记录表（包含购买、出售、每日限购记录）';
-- 月卡会员表
DROP TABLE IF EXISTS `monthly_memberships`;
CREATE TABLE `monthly_memberships` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(255) NOT NULL COMMENT '用户ID',
    `start_date` DATE NOT NULL COMMENT '开始日期',
    `end_date` DATE NOT NULL COMMENT '结束日期',
    `daily_reward_coins` INT NOT NULL DEFAULT 100 COMMENT '每日奖励金币',
    `last_reward_date` DATE DEFAULT NULL COMMENT '最后一次领取奖励的日期',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否激活',
    `purchase_transaction_id` BIGINT DEFAULT NULL COMMENT '购买交易ID',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    KEY `idx_user_active` (`user_id`, `is_active`),
    KEY `idx_end_date` (`end_date`),
    KEY `idx_last_reward_date` (`last_reward_date`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '月卡会员表';
-- 每日奖励记录表
DROP TABLE IF EXISTS `daily_rewards`;
CREATE TABLE `daily_rewards` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(255) NOT NULL COMMENT '用户ID',
    `reward_date` DATE NOT NULL COMMENT '奖励日期',
    `reward_coins` INT NOT NULL DEFAULT 0 COMMENT '奖励金币',
    `membership_id` BIGINT NOT NULL COMMENT '所属月卡ID',
    `claimed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '领取时间',
    UNIQUE KEY `idx_user_date` (`user_id`, `reward_date`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`membership_id`) REFERENCES `monthly_memberships`(`id`) ON DELETE CASCADE,
    KEY `idx_membership_date` (`membership_id`, `reward_date`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '每日奖励记录表';
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
-- ================================================
-- 初始数据插入
-- ================================================
-- 插入初始商品数据
INSERT IGNORE INTO `items` (
        `id`,
        `name`,
        `description`,
        `price`,
        `sell_price`,
        `category`,
        `image_url`,
        `sort_order`,
        `daily_purchase_limit`,
        `can_sell`
    )
VALUES (
        'sword_basic',
        '基础剑',
        '一把普通的铁剑，适合新手使用。攻击力+10',
        100,
        80,
        'weapons',
        'rbxasset://textures/sword_basic.png',
        1,
        NULL,
        TRUE
    ),
    (
        'sword_steel',
        '钢剑',
        '锻造精良的钢剑，比基础剑更加锋利。攻击力+25',
        250,
        200,
        'weapons',
        'rbxasset://textures/sword_steel.png',
        2,
        NULL,
        TRUE
    ),
    (
        'sword_enchanted',
        '附魔剑',
        '被魔法力量加持的剑，散发着神秘光芒。攻击力+50 (每日限购1件，无法卖出)',
        500,
        NULL,
        'weapons',
        'rbxasset://textures/sword_enchanted.png',
        3,
        1,
        FALSE
    ),
    (
        'shield_wooden',
        '木制盾牌',
        '简单的木制盾牌，提供基础防护。防御力+5',
        80,
        64,
        'armor',
        'rbxasset://textures/shield_wooden.png',
        4,
        NULL,
        TRUE
    ),
    (
        'shield_iron',
        '铁制盾牌',
        '坚固的铁制盾牌，能够抵挡更强的攻击。防御力+15',
        180,
        144,
        'armor',
        'rbxasset://textures/shield_iron.png',
        5,
        NULL,
        TRUE
    ),
    (
        'armor_leather',
        '皮甲',
        '轻便的皮革护甲，适合快速移动。防御力+8',
        150,
        120,
        'armor',
        'rbxasset://textures/armor_leather.png',
        6,
        NULL,
        TRUE
    ),
    (
        'armor_chainmail',
        '锁子甲',
        '金属制成的防具，提供优秀的保护。防御力+20',
        300,
        240,
        'armor',
        'rbxasset://textures/armor_chainmail.png',
        7,
        NULL,
        TRUE
    ),
    (
        'potion_health',
        '生命药水',
        '恢复50点生命值的药水，战斗必备 (每日限购5瓶)',
        50,
        40,
        'consumables',
        'rbxasset://textures/potion_health.png',
        8,
        5,
        TRUE
    ),
    (
        'potion_mana',
        '魔法药水',
        '恢复30点魔法值的药水，施法者必备 (每日限购5瓶)',
        60,
        48,
        'consumables',
        'rbxasset://textures/potion_mana.png',
        9,
        5,
        TRUE
    ),
    (
        'potion_strength',
        '力量药水',
        '临时增加攻击力的药水，持续5分钟 (每日限购3瓶)',
        120,
        96,
        'consumables',
        'rbxasset://textures/potion_strength.png',
        10,
        3,
        TRUE
    ),
    (
        'scroll_teleport',
        '传送卷轴',
        '瞬间传送到指定地点的魔法卷轴 (每日限购2张，无法卖出)',
        150,
        NULL,
        'consumables',
        'rbxasset://textures/scroll_teleport.png',
        11,
        2,
        FALSE
    ),
    (
        'food_bread',
        '面包',
        '简单的食物，恢复少量生命值',
        20,
        16,
        'consumables',
        'rbxasset://textures/food_bread.png',
        12,
        NULL,
        TRUE
    ),
    (
        'gem_ruby',
        '红宝石',
        '珍贵的红色宝石，可用于装备强化 (每日限购2颗)',
        200,
        160,
        'materials',
        'rbxasset://textures/gem_ruby.png',
        13,
        2,
        TRUE
    ),
    (
        'gem_sapphire',
        '蓝宝石',
        '稀有的蓝色宝石，蕴含魔法能量 (每日限购2颗)',
        220,
        176,
        'materials',
        'rbxasset://textures/gem_sapphire.png',
        14,
        2,
        TRUE
    ),
    (
        'gem_emerald',
        '绿宝石',
        '神秘的绿色宝石，据说有治愈能力 (每日限购2颗)',
        250,
        200,
        'materials',
        'rbxasset://textures/gem_emerald.png',
        15,
        2,
        TRUE
    ),
    (
        'ore_iron',
        '铁矿石',
        '常见的金属矿石，用于制作装备',
        30,
        24,
        'materials',
        'rbxasset://textures/ore_iron.png',
        16,
        NULL,
        TRUE
    ),
    (
        'ore_gold',
        '金矿石',
        '珍贵的黄金矿石，价值不菲 (每日限购10个)',
        100,
        80,
        'materials',
        'rbxasset://textures/ore_gold.png',
        17,
        10,
        TRUE
    ),
    (
        'wood_oak',
        '橡木',
        '坚硬的木材，制作工具的好材料',
        25,
        20,
        'materials',
        'rbxasset://textures/wood_oak.png',
        18,
        NULL,
        TRUE
    ),
    (
        'book_spells',
        '法术书',
        '记录着各种魔法咒语的古老书籍 (每日限购1本，无法卖出)',
        180,
        NULL,
        'books',
        'rbxasset://textures/book_spells.png',
        19,
        1,
        FALSE
    ),
    (
        'book_history',
        '历史书',
        '记录着这个世界历史的珍贵典籍',
        80,
        64,
        'books',
        'rbxasset://textures/book_history.png',
        20,
        NULL,
        TRUE
    ),
    (
        'map_world',
        '世界地图',
        '详细的世界地图，探险者必备 (每日限购1张)',
        120,
        96,
        'tools',
        'rbxasset://textures/map_world.png',
        21,
        1,
        TRUE
    ),
    (
        'pickaxe',
        '镐子',
        '挖掘矿石的工具，探矿必备',
        90,
        72,
        'tools',
        'rbxasset://textures/pickaxe.png',
        22,
        NULL,
        TRUE
    ),
    (
        'fishing_rod',
        '钓鱼竿',
        '在河边湖边钓鱼的工具',
        70,
        56,
        'tools',
        'rbxasset://textures/fishing_rod.png',
        23,
        NULL,
        TRUE
    ),
    (
        'monthly_membership',
        '月卡会员',
        '购买后获得30天会员特权，每日登录可获得100金币奖励 (每日限购1张，无法卖出)',
        1000,
        NULL,
        'membership',
        'rbxasset://textures/monthly_membership.png',
        24,
        1,
        FALSE
    ),
    (
        'weekly_membership',
        '周卡会员',
        '购买后获得7天会员特权，每日登录可获得100金币奖励 (每日限购2张，无法卖出)',
        300,
        NULL,
        'membership',
        'rbxasset://textures/weekly_membership.png',
        25,
        2,
        FALSE
    ),
    (
        'quarterly_membership',
        '季卡会员',
        '购买后获得90天会员特权，每日登录可获得100金币奖励，超值优惠！ (每日限购1张，无法卖出)',
        2700,
        NULL,
        'membership',
        'rbxasset://textures/quarterly_membership.png',
        26,
        1,
        FALSE
    ),
    (
        'premium_membership',
        '高级月卡',
        '购买后获得30天高级会员特权，每日登录可获得200金币奖励 (每日限购1张，无法卖出)',
        1800,
        NULL,
        'membership',
        'rbxasset://textures/premium_membership.png',
        27,
        1,
        FALSE
    ),
    (
        'vip_membership',
        'VIP年卡',
        '购买后获得365天VIP会员特权，每日登录可获得150金币奖励，一年无忧！ (每日限购1张，无法卖出)',
        10000,
        NULL,
        'membership',
        'rbxasset://textures/vip_membership.png',
        28,
        1,
        FALSE
    );
-- 插入默认系统配置
INSERT IGNORE INTO `system_config` (`config_key`, `config_value`, `description`)
VALUES ('sell_rate', '0.8', '物品出售价格比例'),
    ('shop_tax_rate', '0.05', '商店交易税率'),
    (
        'rate_limit_window_ms',
        '900000',
        'API请求限制时间窗口(毫秒)'
    ),
    ('rate_limit_max_requests', '100', 'API请求限制最大次数'),
    ('membership_daily_reward', '100', '月卡每日奖励金币'),
    ('membership_duration_days', '30', '月卡有效期天数'),
    (
        'membership_max_missed_rewards',
        '7',
        '月卡最多补发奖励天数'
    ),
    (
        'weekly_membership_duration_days',
        '7',
        '周卡有效期天数'
    ),
    (
        'quarterly_membership_duration_days',
        '90',
        '季卡有效期天数'
    ),
    (
        'premium_membership_daily_reward',
        '200',
        '高级月卡每日奖励金币'
    ),
    (
        'vip_membership_duration_days',
        '365',
        'VIP年卡有效期天数'
    ),
    (
        'vip_membership_daily_reward',
        '150',
        'VIP年卡每日奖励金币'
    ),
    (
        'default_coins_for_new_user',
        '1000',
        '新用户注册时的默认金币数量'
    );
SET FOREIGN_KEY_CHECKS = 1;