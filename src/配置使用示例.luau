-- 📋 Config模块使用示例
-- 这个文件展示如何正确使用统一配置文件

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 等待并引用配置模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

-- 示例：使用API配置
print("API基础URL:", Config.API.BASE_URL)
print("请求超时时间:", Config.API.TIMEOUT .. "秒")

-- 示例：构建完整API URL
local itemsUrl = Config.getApiUrl("/items")
print("商品API地址:", itemsUrl)

-- 示例：检查管理员权限
local function checkPlayerPermissions(player)
    if Config.isValidAdmin(player) then
        print("👑", player.Name, "是管理员")

        -- 检查具体权限
        if Config.ADMIN.PERMISSIONS.MANAGE_USERS then
            print("✓ 拥有用户管理权限")
        end

        if Config.ADMIN.PERMISSIONS.SYSTEM_ADMIN then
            print("✓ 拥有系统管理权限")
        end
    else
        print("👤", player.Name, "是普通用户")
    end
end

-- 示例：使用UI配置
local function createSampleButton()
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = Config.UI.COLORS.PRIMARY
    button.TextColor3 = Config.UI.COLORS.TEXT_PRIMARY
    button.Size = UDim2.new(0, 120, 0, Config.UI.SIZES.BUTTON_HEIGHT)

    -- 创建圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Config.UI.SIZES.CORNER_RADIUS)
    corner.Parent = button

    return button
end

-- 示例：使用经济配置
local function giveStartingCoins(player)
    local startingCoins = Config.GAME.ECONOMY.STARTING_COINS
    print("给予新玩家", Config.formatCurrency(startingCoins))
end

-- 示例：使用日志系统
Config.log("INFO", "配置示例脚本已加载")
Config.log("DEBUG", "当前调试模式", {enabled = Config.isDebugMode()})

-- 示例：检查环境配置
if Config.isDebugMode() then
    print("🔧 运行在开发环境")
    print("🔍 日志级别:", Config.DEBUG.LOG_LEVEL)
    print("📊 性能监控:", Config.DEBUG.PERFORMANCE_MONITORING and "开启" or "关闭")
else
    print("🚀 运行在生产环境")
end

-- 示例：使用本地化配置
print("默认语言:", Config.LOCALIZATION.DEFAULT_LANGUAGE)
print("货币符号:", Config.LOCALIZATION.CURRENCY_FORMAT.SYMBOL)

-- 示例：格式化货币显示
local sampleAmount = 12345
print("格式化前:", sampleAmount)
print("格式化后:", Config.formatCurrency(sampleAmount))

-- 示例：使用动画配置
local function createFadeAnimation(guiObject)
    local TweenService = game:GetService("TweenService")

    local fadeIn = TweenService:Create(
        guiObject,
        TweenInfo.new(
            Config.UI.ANIMATIONS.DURATION.NORMAL,
            Config.UI.ANIMATIONS.EASING.DEFAULT
        ),
        {BackgroundTransparency = 0}
    )

    return fadeIn
end

-- 示例：安全配置使用
print("速率限制:", Config.SECURITY.RATE_LIMITING.ENABLED and "开启" or "关闭")
print("最大请求大小:", Config.SECURITY.MAX_REQUEST_SIZE .. " bytes")

-- 示例：响应式配置
-- 在不同环境下使用不同配置
local function getEnvironmentConfig()
    if game:GetService("RunService"):IsStudio() then
        return {
            apiUrl = "http://localhost:3001/api",  -- 开发环境
            debugLevel = "DEBUG",
            enableMocking = true
        }
    else
        return {
            apiUrl = Config.API.BASE_URL,  -- 生产环境
            debugLevel = Config.DEBUG.LOG_LEVEL,
            enableMocking = false
        }
    end
end

local envConfig = getEnvironmentConfig()
print("当前环境API URL:", envConfig.apiUrl)

-- 示例：配置验证
local function validateConfig()
    local errors = {}

    -- 检查必需的配置
    if not Config.API.BASE_URL or Config.API.BASE_URL == "" then
        table.insert(errors, "API基础URL未配置")
    end

    if Config.GAME.ECONOMY.STARTING_COINS <= 0 then
        table.insert(errors, "初始金币数量必须大于0")
    end

    if #errors > 0 then
        warn("配置验证失败:")
        for _, error in ipairs(errors) do
            warn("❌", error)
        end
        return false
    else
        print("✅ 配置验证通过")
        return true
    end
end

-- 运行配置验证
validateConfig()

-- 示例：配置监听器（模拟）
-- 注意：实际项目中可能需要实现配置热重载
local function onConfigChange(configKey, oldValue, newValue)
    Config.log("INFO", "配置已更改", {
        key = configKey,
        oldValue = oldValue,
        newValue = newValue
    })

    -- 根据配置更改执行相应操作
    if configKey == "UI.COLORS.PRIMARY" then
        -- 更新所有UI元素的主色调
        print("🎨 正在更新UI主色调...")
    elseif configKey == "ADMIN.USER_IDS" then
        -- 重新验证管理员权限
        print("👑 正在更新管理员列表...")
    end
end

-- 导出示例函数供其他脚本使用
return {
    checkPlayerPermissions = checkPlayerPermissions,
    createSampleButton = createSampleButton,
    giveStartingCoins = giveStartingCoins,
    createFadeAnimation = createFadeAnimation,
    getEnvironmentConfig = getEnvironmentConfig,
    validateConfig = validateConfig,
    onConfigChange = onConfigChange
}
