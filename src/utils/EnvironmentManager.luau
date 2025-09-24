--[[
    环境管理器 - 统一管理开发和生产环境配置
    支持多种环境检测方式和配置管理
]]

local EnvironmentManager = {}

-- 服务引用
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==============================================
-- 环境检测
-- ==============================================

-- 环境类型枚举
local EnvironmentType = {
    STUDIO = "studio",
    DEVELOPMENT = "development",
    STAGING = "staging",
    PRODUCTION = "production"
}

-- 当前环境缓存
local currentEnvironment = nil
local environmentConfig = nil

-- 检测当前环境
local function detectEnvironment()
    if currentEnvironment then
        return currentEnvironment
    end

    -- 1. 首先检查是否在Studio
    if RunService:IsStudio() then
        currentEnvironment = EnvironmentType.STUDIO
        print("🔧 环境检测: Studio开发环境")
        return currentEnvironment
    end

    -- 2. 检查游戏ID来确定环境
    local gameId = game.GameId
    local placeId = game.PlaceId

    -- 这里可以根据实际的游戏ID配置不同环境
    -- 示例配置 - 需要根据实际情况修改
    local environmentPlaces = {
        -- 开发环境的PlaceID
        development = {
            gameIds = {},
            placeIds = {}
        },
        -- 测试环境的PlaceID
        staging = {
            gameIds = {},
            placeIds = {}
        },
        -- 生产环境的PlaceID
        production = {
            gameIds = {},
            placeIds = {}
        }
    }

    -- 检查Place ID匹配
    for envType, config in pairs(environmentPlaces) do
        for _, id in ipairs(config.placeIds) do
            if placeId == id then
                currentEnvironment = envType
                print("🌐 环境检测: " .. envType .. "环境 (PlaceID: " .. placeId .. ")")
                return currentEnvironment
            end
        end
    end

    -- 3. 如果没有明确配置，检查DataStore可用性来判断
    local hasDataStore = pcall(function()
        local testStore = DataStoreService:GetDataStore("EnvironmentTest")
        testStore:GetAsync("test")
    end)

    if hasDataStore then
        -- 默认为生产环境
        currentEnvironment = EnvironmentType.PRODUCTION
        print("🚀 环境检测: 生产环境 (默认)")
    else
        -- DataStore不可用，可能是开发环境
        currentEnvironment = EnvironmentType.DEVELOPMENT
        print("⚠️ 环境检测: 开发环境 (DataStore不可用)")
    end

    return currentEnvironment
end

-- ==============================================
-- 环境配置管理
-- ==============================================

-- 不同环境的配置
local environmentConfigs = {
    [EnvironmentType.STUDIO] = {
        dataStore = {
            enabled = false,
            mockData = true,
            saveInterval = 5, -- 更频繁的保存用于测试
            retryAttempts = 1
        },
        logging = {
            level = "debug",
            enableConsole = true,
            enableRemote = false
        },
        performance = {
            cacheTimeout = 60,
            batchSize = 10,
            rateLimitEnabled = false
        },
        features = {
            adminPanelEnabled = true,
            debugMode = true,
            testDataEnabled = true
        }
    },

    [EnvironmentType.DEVELOPMENT] = {
        dataStore = {
            enabled = true,
            mockData = false,
            saveInterval = 30,
            retryAttempts = 2,
            backupEnabled = false
        },
        logging = {
            level = "info",
            enableConsole = true,
            enableRemote = true
        },
        performance = {
            cacheTimeout = 300,
            batchSize = 50,
            rateLimitEnabled = true
        },
        features = {
            adminPanelEnabled = true,
            debugMode = true,
            testDataEnabled = false
        }
    },

    [EnvironmentType.STAGING] = {
        dataStore = {
            enabled = true,
            mockData = false,
            saveInterval = 60,
            retryAttempts = 3,
            backupEnabled = true
        },
        logging = {
            level = "warn",
            enableConsole = false,
            enableRemote = true
        },
        performance = {
            cacheTimeout = 600,
            batchSize = 100,
            rateLimitEnabled = true
        },
        features = {
            adminPanelEnabled = true,
            debugMode = false,
            testDataEnabled = false
        }
    },

    [EnvironmentType.PRODUCTION] = {
        dataStore = {
            enabled = true,
            mockData = false,
            saveInterval = 120,
            retryAttempts = 5,
            backupEnabled = true
        },
        logging = {
            level = "error",
            enableConsole = false,
            enableRemote = true
        },
        performance = {
            cacheTimeout = 1800,
            batchSize = 200,
            rateLimitEnabled = true
        },
        features = {
            adminPanelEnabled = false,
            debugMode = false,
            testDataEnabled = false
        }
    }
}

-- 获取当前环境配置
local function getEnvironmentConfig()
    if environmentConfig then
        return environmentConfig
    end

    local env = detectEnvironment()
    environmentConfig = environmentConfigs[env] or environmentConfigs[EnvironmentType.PRODUCTION]

    return environmentConfig
end

-- ==============================================
-- 公共接口
-- ==============================================

-- 获取当前环境类型
function EnvironmentManager.getCurrentEnvironment()
    return detectEnvironment()
end

-- 检查是否为特定环境
function EnvironmentManager.isStudio()
    return detectEnvironment() == EnvironmentType.STUDIO
end

function EnvironmentManager.isDevelopment()
    local env = detectEnvironment()
    return env == EnvironmentType.DEVELOPMENT or env == EnvironmentType.STUDIO
end

function EnvironmentManager.isStaging()
    return detectEnvironment() == EnvironmentType.STAGING
end

function EnvironmentManager.isProduction()
    return detectEnvironment() == EnvironmentType.PRODUCTION
end

-- 获取配置值
function EnvironmentManager.getConfig(configPath)
    local config = getEnvironmentConfig()

    -- 支持点分路径，如 "dataStore.enabled"
    local keys = string.split(configPath, ".")
    local value = config

    for _, key in ipairs(keys) do
        if type(value) == "table" and value[key] ~= nil then
            value = value[key]
        else
            return nil
        end
    end

    return value
end

-- 获取完整配置
function EnvironmentManager.getAllConfig()
    return getEnvironmentConfig()
end

-- 获取DataStore配置
function EnvironmentManager.getDataStoreConfig()
    return getEnvironmentConfig().dataStore
end

-- 获取日志配置
function EnvironmentManager.getLoggingConfig()
    return getEnvironmentConfig().logging
end

-- 获取性能配置
function EnvironmentManager.getPerformanceConfig()
    return getEnvironmentConfig().performance
end

-- 获取功能配置
function EnvironmentManager.getFeatureConfig()
    return getEnvironmentConfig().features
end

-- 强制重新检测环境（用于测试）
function EnvironmentManager.forceRedetect()
    currentEnvironment = nil
    environmentConfig = nil
    return detectEnvironment()
end

-- 设置环境（仅用于测试）
function EnvironmentManager.setEnvironment(envType)
    if EnvironmentManager.isStudio() then
        currentEnvironment = envType
        environmentConfig = nil
        print("🔧 手动设置环境为:", envType)
    else
        warn("⚠️ 只能在Studio环境中手动设置环境类型")
    end
end

-- ==============================================
-- 环境信息输出
-- ==============================================

-- 输出环境信息
function EnvironmentManager.printEnvironmentInfo()
    local env = detectEnvironment()
    local config = getEnvironmentConfig()

    print("=" .. string.rep("=", 50))
    print("🌍 环境信息")
    print("=" .. string.rep("=", 50))
    print("环境类型:", env)
    print("游戏ID:", game.GameId)
    print("场景ID:", game.PlaceId)
    print("DataStore启用:", config.dataStore.enabled)
    print("模拟数据:", config.dataStore.mockData)
    print("日志级别:", config.logging.level)
    print("调试模式:", config.features.debugMode)
    print("管理面板:", config.features.adminPanelEnabled)
    print("=" .. string.rep("=", 50))
end

-- 模块初始化
spawn(function()
    wait(1) -- 等待游戏完全加载
    EnvironmentManager.printEnvironmentInfo()
end)

return EnvironmentManager
