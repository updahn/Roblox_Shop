--[[
商店系统统一配置文件

本文件包含所有系统配置参数，用于统一管理商店系统的各种设置。

包含的配置模块：
- 管理员权限配置
- UI主题和样式配置
- 游戏玩法配置
- 无人机系统配置
- 靶子系统配置
- 调试和开发配置
- 本地化配置

用法：
  local Config = require(路径到该文件)
--]]

local Config = {}


-- ==============================================
-- 管理员权限配置
-- 本地配置默认管理员用户名，在游戏初次加载时自动设置为管理员
-- ==============================================

Config.ADMIN = {
    -- 默认管理员用户名列表（在这里添加需要设置为管理员的用户名）
    DEFAULT_ADMIN_USERNAMES = {
        "updahn",
        -- 测试管理员
        "Player1",
        "Player2",
        -- 测试普通用户
        -- "Player3"
    },

    -- 配置是否已加载
    _LOADED = false,
    _LAST_UPDATE = 0,
    _CACHE_DURATION = 300 -- 缓存5分钟
}


-- ==============================================
-- UI 主题和样式配置
-- 定义商店界面的视觉样式和交互效果
-- ==============================================

Config.UI = {
    -- 颜色主题 - 现代深色设计
    COLORS = {
        -- 主色调
        PRIMARY = Color3.fromRGB(25, 25, 35),       -- 深色背景
        SECONDARY = Color3.fromRGB(35, 35, 45),     -- 中等深色
        TERTIARY = Color3.fromRGB(45, 45, 55),      -- 浅一点的深色
        ACCENT = Color3.fromRGB(88, 166, 255),      -- 现代蓝色
        ACCENT_HOVER = Color3.fromRGB(108, 186, 255), -- 悬停蓝色
        SUCCESS = Color3.fromRGB(52, 211, 153),     -- 现代绿色
        WARNING = Color3.fromRGB(251, 191, 36),     -- 现代黄色
        ERROR = Color3.fromRGB(248, 113, 113),      -- 现代红色
        DANGER = Color3.fromRGB(239, 68, 68),       -- 危险红色

        -- 文字颜色
        TEXT_PRIMARY = Color3.fromRGB(248, 250, 252),    -- 纯白
        TEXT_SECONDARY = Color3.fromRGB(203, 213, 225),  -- 浅灰
        TEXT_MUTED = Color3.fromRGB(148, 163, 184),      -- 中灰
        TEXT_DARK = Color3.fromRGB(71, 85, 105),         -- 深灰

        -- 背景和特效
        GLASS_BG = Color3.fromRGB(15, 15, 25),      -- 毛玻璃背景
        OVERLAY = Color3.fromRGB(0, 0, 0),          -- 遮罩
        GRADIENT_START = Color3.fromRGB(88, 166, 255), -- 渐变开始
        GRADIENT_END = Color3.fromRGB(147, 51, 234),   -- 渐变结束
    },

    -- 音效配置
    SOUNDS = {
        CLICK = "electronicpingshort.wav",
        SUCCESS = "victory.wav",
        ERROR = "splat.wav",
        VOLUME = {
            CLICK = 0.3,
            SUCCESS = 0.4,
            ERROR = 0.3
        }
    },

    -- 动画配置
    ANIMATIONS = {
        DURATION = {
            FAST = 0.2,
            NORMAL = 0.4,
            SLOW = 0.6
        },
        EASING = {
            DEFAULT = Enum.EasingStyle.Quad,
            BOUNCE = Enum.EasingStyle.Back,
            ELASTIC = Enum.EasingStyle.Elastic
        }
    },

    -- UI尺寸配置
    SIZES = {
        MAIN_FRAME = UDim2.new(0, 850, 0, 650),
        BUTTON_HEIGHT = 40,
        CORNER_RADIUS = 12,
        BORDER_WIDTH = 2
    }
}

-- ==============================================
-- 游戏玩法配置
-- 定义游戏的经济系统、交易规则和数据同步参数
-- ==============================================

Config.GAME = {
    -- 经济系统配置
    ECONOMY = {
        STARTING_COINS = 3000,           -- 新玩家初始金币
        SELL_RATE = 0.8,                 -- 卖出价格比例 (原价的80%)
        MAX_COINS = 999999,              -- 金币上限
        MIN_COINS = 0                    -- 金币下限
    },

    -- 交易配置
    TRADING = {
        MIN_QUANTITY = 1,                -- 最小交易数量
        MAX_QUANTITY = 999,              -- 最大交易数量
        TRANSACTION_HISTORY_LIMIT = 50   -- 交易记录保留数量
    },

    -- 数据同步配置
    DATA_SYNC = {
        AUTO_SAVE_INTERVAL = 300,        -- 自动保存间隔(秒)
        RETRY_COUNT = 3,                 -- 失败重试次数
        CACHE_DURATION = 60              -- 缓存时间(秒)
    }
}

-- ==============================================
-- 调试和开发配置
-- 控制日志输出和调试功能，仅在Studio中启用
-- ==============================================

Config.DEBUG = {
    -- 是否启用调试模式
    ENABLED = game:GetService("RunService"):IsStudio(),

    -- 日志级别
    LOG_LEVEL = "INFO", -- "DEBUG", "INFO", "WARN", "ERROR"

    -- 是否显示详细错误信息
    VERBOSE_ERRORS = true,

    -- 是否启用性能监控
    PERFORMANCE_MONITORING = true,

    -- 测试数据
    TEST_DATA = {
        MOCK_DELAY = 1000, -- 毫秒
        FAKE_NETWORK_ISSUES = false
    }
}

-- ==============================================
-- 无人机系统配置
-- 包含无人机系统的所有配置参数
-- ==============================================

Config.DRONE_CONFIG = {
    -- 生存时间配置
    LIFETIME = 10,  -- 无人机生存时间（秒）

    -- 移动配置
    FOLLOW_DISTANCE = 8,  -- 跟随模式下的距离
    FOLLOW_HEIGHT = 10,   -- 跟随高度
    HOVER_HEIGHT = 12,    -- 驻守模式下的悬停高度
    MOVEMENT_SPEED = 16,  -- 移动速度

    -- 高度控制配置
    HEIGHT_CONTROL = {
        AUTO_ADJUST = true,     -- 是否启用自动高度调节
        MIN_HEIGHT = 5,         -- 最小飞行高度
        MAX_HEIGHT = 30,        -- 最大飞行高度
        TARGET_OFFSET = 3,      -- 攻击靶子时的高度偏移
        ADJUSTMENT_SPEED = 2,   -- 高度调节速度
    },

    -- 攻击配置
    ATTACK_RANGE = 50,    -- 攻击范围
    ATTACK_INTERVAL = 1,  -- 攻击间隔（秒）
    ATTACK_DAMAGE = 30,   -- 攻击伤害

    -- 目标优先级配置
    TARGET_PRIORITY = {
        PLAYERS = 1,        -- 最高优先级：其他玩家
        NPCS = 2,          -- 中等优先级：NPC
        TARGETS = 3,       -- 最低优先级：靶子
    },

    -- 视觉效果配置
    SIZE_SCALE = 1,       -- 无人机大小缩放

    -- 无人机模式配置
    MODES = {
        FOLLOW = "follow",    -- 跟随模式
        GUARD = "guard"       -- 驻守模式
    },

    -- 无人机模型配置
    MODEL = {
        -- 使用Roblox免费模型库的无人机模型
        ASSET_ID = "rbxassetid://5129458730",

        -- 备用模型ID列表
        FALLBACK_ASSET_IDS = {
            "rbxassetid://5129458730",  -- 原始模型
            "rbxassetid://1390779",     -- Roblox官方汽车模型
            "rbxassetid://1374148",     -- 经典Roblox载具
            "rbxassetid://16159032",    -- 简单飞行器
            "rbxassetid://16384448",    -- 球形载具
        },

        -- 模型部件名称
        PARTS = {
            MAIN_BODY = "Body",
            PROPELLERS = {"Propeller1", "Propeller2", "Propeller3", "Propeller4"},
            LASER = "Laser"  -- 激光发射器部件
        }
    },

    -- 无人机音效配置
    SOUNDS = {
        SPAWN = "rbxasset://sounds/electronicpingshort.wav",
        ATTACK = "rbxasset://sounds/impact_water.mp3",  -- 使用更稳定的音效
        DESTROY = "rbxasset://sounds/snap.wav",
        HOVER = "rbxasset://sounds/ambient.ogg",
        VOLUME = {
            SPAWN = 0.5,
            ATTACK = 0.3,
            DESTROY = 0.4,
            HOVER = 0.2
        }
    },

    -- 无人机粒子效果配置
    EFFECTS = {
        SPAWN_EFFECT = {
            PARTICLE_COUNT = 50,
            LIFETIME = 2,
            COLOR = Color3.fromRGB(0, 162, 255)
        },
        ATTACK_EFFECT = {
            BEAM_COLOR = Color3.fromRGB(255, 0, 0),
            BEAM_WIDTH = 0.2,
            BEAM_DURATION = 0.1
        },
        EXPLOSION_EFFECT = {
            ENABLED = true,
            SPARK_PARTICLES = 200,
            SMOKE_PARTICLES = 50,
            LIGHT_BRIGHTNESS = 5,
            LIGHT_RANGE = 15,
            BALL_SIZE = Vector3.new(8, 8, 8),
            DURATION = 3
        },
        DESTROY_EFFECT = {
            PARTICLE_COUNT = 30,
            LIFETIME = 1.5,
            COLOR = Color3.fromRGB(255, 255, 255)
        }
    },

    -- 无人机UI配置
    UI = {
        BUTTON_SIZE = UDim2.new(0, 120, 0, 40),
        BUTTON_POSITION = UDim2.new(1, -140, 1, -60),

        COLORS = {
            SPAWN_BUTTON = Color3.fromRGB(52, 211, 153),    -- 绿色
            RECALL_BUTTON = Color3.fromRGB(248, 113, 113),  -- 红色
            MODE_BUTTON = Color3.fromRGB(88, 166, 255),     -- 蓝色
            DISABLED = Color3.fromRGB(100, 100, 100)        -- 灰色
        },

        TEXT = {
            SPAWN = "召唤无人机",
            RECALL = "收回无人机",
            MODE_FOLLOW = "跟随模式",
            MODE_GUARD = "驻守模式",
            SWITCH_TO_FOLLOW = "切换到跟随",
            SWITCH_TO_GUARD = "切换到驻守"
        }
    }
}


-- 靶子系统配置
Config.TARGETS = {
    COUNT = 3,  -- 靶子数量
    MAX_HEALTH = 100,  -- 靶子最大血量
    RESPAWN_TIME = 5,  -- 靶子重生时间（秒）

    -- 靶子生成范围配置
    SPAWN_AREA = {
        MIN_RADIUS = 30,     -- 最小生成半径
        MAX_RADIUS = 100,    -- 最大生成半径
        CENTER = Vector3.new(0, 0, 0),  -- 生成中心点
        EXCLUDE_RADIUS = 10, -- 排除玩家周围的半径
    },

    -- 靶子高度配置
    HEIGHT_CONFIG = {
        MIN_HEIGHT = 6,      -- 最小高度
        MAX_HEIGHT = 15,     -- 最大高度
        BASE_HEIGHT = 5,     -- 基础高度（支撑杆底部）
        RANDOM_OFFSET = true -- 是否启用随机高度偏移
    },

    -- 靶子外观
    APPEARANCE = {
        COLOR = Color3.fromRGB(255, 100, 100),  -- 红色
        SIZE = Vector3.new(4, 6, 1),  -- 宽x高x厚
        MATERIAL = Enum.Material.Neon,
    },

    -- 靶子标识
    MARKER = {
        ENABLED = true,
        TEXT = "靶子",
        TEXT_SIZE = 24,
        TEXT_COLOR = Color3.fromRGB(255, 255, 255)
    }
}

-- ==============================================
-- 本地化配置
-- ==============================================

Config.LOCALIZATION = {
    -- 货币显示格式
    CURRENCY_FORMAT = {
        SYMBOL = "💰",
        SEPARATOR = ",",
        DECIMAL_PLACES = 0
    }
}

-- ==============================================
-- 工具函数
-- 提供各种帮助函数用于配置管理和数据处理
-- ==============================================

-- 导入缓存服务（仅在服务端可用）
local RunService = game:GetService("RunService")
local CacheService = nil

-- 获取缓存服务（延迟初始化，仅服务端）
local function getCacheService()
    if not CacheService and RunService:IsServer() then
        pcall(function()
            local ServerScriptService = game:GetService("ServerScriptService")
            CacheService = require(ServerScriptService.Server.services.CacheService)
        end)
    end
    return CacheService
end

-- 客户端管理员验证缓存（保持兼容性）
local adminValidationCache = {}
local ADMIN_CACHE_DURATION = 30

-- 检查调试模式
function Config.isDebugMode()
    return Config.DEBUG.ENABLED
end

--[[
格式化货币显示

将数字金额转换为格式化的货币字符串。
会自动添加千位分隔符和货币符号。

@param amount number - 要格式化的金额
@return string - 格式化后的货币字符串

例子：
  Config.formatCurrency(12345) -> "💰 12,345"
--]]
function Config.formatCurrency(amount)
    local formatted = tostring(amount)
    local symbol = Config.LOCALIZATION.CURRENCY_FORMAT.SYMBOL
    local separator = Config.LOCALIZATION.CURRENCY_FORMAT.SEPARATOR

    -- 添加千位分隔符
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1" .. separator .. "%2")
        if k == 0 then break end
    end

    return symbol .. " " .. formatted
end

--[[
强制刷新管理员权限缓存
用于实现实时更新管理员权限判断

@param player Player - 要刷新权限的玩家
--]]
function Config.refreshAdminCache(player)
    if player and player.Name then
        local cacheKey = player.Name
        -- 清除缓存
        adminValidationCache[cacheKey] = nil
        print("🔄 [调试] 已清除", player.Name, "的管理员权限缓存")
    else
        -- 清除所有缓存
        adminValidationCache = {}
        print("🔄 [调试] 已清除所有管理员权限缓存")
    end
end

--[[
统一日志记录函数

根据配置的日志级别输出日志信息。
仅在调试模式启用时才会实际输出日志。

@param level string - 日志级别（"DEBUG", "INFO", "WARN", "ERROR"）
@param message string - 日志消息
@param data table|nil - 可选的附加数据，会被序列化为JSON

例子：
  Config.log("INFO", "系统启动")
  Config.log("ERROR", "数据加载失败", {error = "timeout"})
--]]
function Config.log(level, message, data)
    if not Config.DEBUG.ENABLED then return end

    local levels = {DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4}
    local currentLevel = levels[Config.DEBUG.LOG_LEVEL] or 2
    local messageLevel = levels[level] or 2

    if messageLevel >= currentLevel then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local logMessage = string.format("[%s] %s: %s", timestamp, level, message)

        if data then
            local success, jsonData = pcall(game:GetService("HttpService").JSONEncode, game:GetService("HttpService"), data)
            if success then
                logMessage = logMessage .. " | Data: " .. jsonData
            else
                logMessage = logMessage .. " | Data: [序列化失败]"
            end
        end

        print(logMessage)
    end
end


return Config
