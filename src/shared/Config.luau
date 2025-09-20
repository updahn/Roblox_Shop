--[[
商店系统统一配置文件

本文件包含所有系统配置参数，用于统一管理商店系统的各种设置。

包含的配置模块：
- API服务器配置
- 管理员权限配置
- UI主题和样式配置
- 游戏玩法配置
- 调试和开发配置
- 本地化配置
- 安全配置

用法：
  local Config = require(路径到该文件)
  Config.API.BASE_URL -- 获取API基础URL
--]]

local Config = {}

-- ==============================================
-- API 服务器配置
-- 用于配置与后端 API 服务器的通信参数
-- ==============================================

Config.API = {
    -- 基础URL配置
    BASE_URL = "http://47.243.109.39/api",

    -- 请求超时配置 (秒)
    TIMEOUT = 30,

    -- 重试配置
    RETRY_ATTEMPTS = 3,
    RETRY_DELAY = 2,

    -- 请求头配置
    DEFAULT_HEADERS = {
        ["Content-Type"] = "application/json"
    },

    -- API端点配置
    ENDPOINTS = {
        AUTH = "/auth",
        USERS = "/users",
        ITEMS = "/items",
        ADMIN = "/admin"
    }
}

-- ==============================================
-- 管理员权限配置
-- 通过API动态加载管理员信息，支持缓存机制
-- ==============================================

Config.ADMIN = {
    -- 权限级别配置
    PERMISSIONS = {
        MANAGE_USERS = true,
        MANAGE_ITEMS = true,
        MANAGE_TRANSACTIONS = true,
        VIEW_ANALYTICS = true,
        SYSTEM_ADMIN = true
    },

    -- 配置是否已加载
    _LOADED = false,
    _LAST_UPDATE = 0,
    _CACHE_DURATION = 300 -- 缓存5分钟
}

-- ==============================================
-- 系统配置（从API动态加载）
-- 支持覆盖本地默认配置
-- ==============================================

Config.SYSTEM = {
    -- 动态获取的系统配置 (从API加载)
    _VALUES = {},

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
        USE_MOCK_API = false,
        MOCK_DELAY = 1000, -- 毫秒
        FAKE_NETWORK_ISSUES = false
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

-- 删除了未使用的安全配置 - 由后端API处理

-- ==============================================
-- 工具函数
-- 提供各种帮助函数用于配置管理和数据处理
-- ==============================================

-- 管理员验证缓存
local adminValidationCache = {}
local ADMIN_CACHE_DURATION = 30

-- 获取完整的API URL
function Config.getApiUrl(endpoint)
    return Config.API.BASE_URL .. endpoint
end

-- 检查调试模式
function Config.isDebugMode()
    return Config.DEBUG.ENABLED
end

-- 删除了本地化文本函数 - 现在使用中文

--[[
从API加载管理员配置

该函数从后端 API 获取最新的管理员配置信息，
并更新本地缓存。如果请求失败，将保持之前的配置。

@return boolean - 是否成功加载配置
--]]
function Config.loadAdminConfig()
    local HttpService = game:GetService("HttpService")
    local success, result = pcall(function()
        local response = HttpService:GetAsync(Config.getApiUrl("/config"))
        return HttpService:JSONDecode(response)
    end)

    if success and result.success then
        local adminConfig = result.data.admin
        if adminConfig then
            Config.ADMIN._LOADED = true
            Config.ADMIN._LAST_UPDATE = tick()

            Config.log("INFO", "管理员配置已从API加载", adminConfig)
            return true
        end
    else
        Config.log("ERROR", "加载管理员配置失败", result)
    end

    return false
end

--[[
从API加载系统配置

该函数从后端 API 获取最新的系统配置信息，
并更新本地缓存。可用于覆盖默认的游戏配置。

@return boolean - 是否成功加载配置
--]]
function Config.loadSystemConfig()
    local HttpService = game:GetService("HttpService")
    local success, result = pcall(function()
        local response = HttpService:GetAsync(Config.getApiUrl("/config"))
        return HttpService:JSONDecode(response)
    end)

    if success and result.success then
        local systemConfig = result.data.system
        if systemConfig then
            Config.SYSTEM._VALUES = systemConfig
            Config.SYSTEM._LOADED = true
            Config.SYSTEM._LAST_UPDATE = tick()

            -- 更新游戏配置中的相关值
            if systemConfig.default_user_coins then
                Config.GAME.ECONOMY.STARTING_COINS = tonumber(systemConfig.default_user_coins) or Config.GAME.ECONOMY.STARTING_COINS
            end
            if systemConfig.sell_rate then
                Config.GAME.ECONOMY.SELL_RATE = tonumber(systemConfig.sell_rate) or Config.GAME.ECONOMY.SELL_RATE
            end
            if systemConfig.max_coins then
                Config.GAME.ECONOMY.MAX_COINS = tonumber(systemConfig.max_coins) or Config.GAME.ECONOMY.MAX_COINS
            end

            Config.log("INFO", "系统配置已从API加载", systemConfig)
            return true
        end
    else
        Config.log("ERROR", "加载系统配置失败", result)
    end

    return false
end

--[[
确保系统配置已加载

检查配置是否已加载及是否过期，如果需要则重新加载。
使用缓存机制以避免频繁的 API 请求。

@return boolean - 配置是否可用
--]]
function Config.ensureSystemConfigLoaded()
    local currentTime = tick()
    if not Config.SYSTEM._LOADED or
       (currentTime - Config.SYSTEM._LAST_UPDATE) > Config.SYSTEM._CACHE_DURATION then
        return Config.loadSystemConfig()
    end
    return true
end

--[[
获取系统配置值

获取指定键的系统配置值，如果未找到则返回默认值。

@param key string - 配置键
@param defaultValue any - 默认值
@return any - 配置值
--]]
function Config.getSystemValue(key, defaultValue)
    Config.ensureSystemConfigLoaded()
    return Config.SYSTEM._VALUES[key] or defaultValue
end

--[[
确保管理员配置已加载

检查配置是否已加载及是否过期，如果需要则重新加载。
使用缓存机制以避免频繁的 API 请求。

@return boolean - 配置是否可用
--]]
function Config.ensureAdminConfigLoaded()
    local currentTime = tick()
    if not Config.ADMIN._LOADED or
       (currentTime - Config.ADMIN._LAST_UPDATE) > Config.ADMIN._CACHE_DURATION then
        return Config.loadAdminConfig()
    end
    return true
end

--[[
客户端管理员权限验证函数
通过 RemoteFunction 向服务器查询权限，带缓存机制
--]]
function Config.isValidAdmin(player)
    local RunService = game:GetService("RunService")

    if RunService:IsServer() then
        -- 服务器端直接返回false，应该使用 AdminService.isValidAdmin
        warn("在服务器端调用 Config.isValidAdmin，请使用 AdminService.isValidAdmin")
        return false
    else
        local cacheKey = player.Name
        local currentTime = tick()

        -- 检查缓存
        if adminValidationCache[cacheKey] then
            local cacheData = adminValidationCache[cacheKey]
            if (currentTime - cacheData.timestamp) < ADMIN_CACHE_DURATION then
                -- 缓存还有效，直接返回缓存结果
                return cacheData.isAdmin
            end
        end

        -- 客户端通过 RemoteFunction 查询
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        print("🔍 [Config] 客户端权限检查:", player.Name)

        local success, Events = pcall(function()
            return require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ShopEvents"))
        end)

        if not success or not Events then
            print("❌ [Config] 无法加载Events模块")
            return false
        end

        local checkAdminRemote = Events.Admin and Events.Admin.CheckPermission
        if not checkAdminRemote then
            print("❌ [Config] 找不到权限检查RemoteFunction")
            return false
        end

        local success, result = pcall(function()
            return checkAdminRemote:InvokeServer()
        end)

        if success then
            -- 缓存结果
            adminValidationCache[cacheKey] = {
                isAdmin = result,
                timestamp = currentTime
            }
            print("✅ [Config] 权限检查完成:", player.Name, "->", result)
            return result
        else
            print("❌ [Config] 权限检查失败:", player.Name, "错误:", result)
            return false
        end
    end
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

-- 删除了本地管理员管理函数 - 使用API验证

--[[
统一日志记录函数

根据配置的日志级别输出日志信息。
仅在调试模式启用时才会实际输出日志。

@param level string - 日志级别（"DEBUG", "INFO", "WARN", "ERROR"）
@param message string - 日志消息
@param data table|nil - 可选的附加数据，会被序列化为JSON

例子：
  Config.log("INFO", "系统启动")
  Config.log("ERROR", "API请求失败", {error = "timeout"})
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
            logMessage = logMessage .. " | Data: " .. game:GetService("HttpService"):JSONEncode(data)
        end

        print(logMessage)
    end
end

-- 自动初始化配置
spawn(function()
    wait(1) -- 等待游戏加载完成
    if game:GetService("RunService"):IsServer() then
        Config.ensureAdminConfigLoaded()
        Config.ensureSystemConfigLoaded()
        Config.log("INFO", "商店系统配置已初始化")
    end
end)

return Config
