-- 商店UI公用工具类

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopUtils = {}

-- 等待配置模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

-- 引用UI配置
ShopUtils.COLORS = Config.UI.COLORS

-- 音效
local function createSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/" .. soundId
    sound.Volume = volume or 0.5
    sound.Parent = SoundService
    return sound
end

-- 使用配置中的音效设置
ShopUtils.SOUNDS = {
    click = createSound(Config.UI.SOUNDS.CLICK, Config.UI.SOUNDS.VOLUME.CLICK),
    success = createSound(Config.UI.SOUNDS.SUCCESS, Config.UI.SOUNDS.VOLUME.SUCCESS),
    error = createSound(Config.UI.SOUNDS.ERROR, Config.UI.SOUNDS.VOLUME.ERROR),
}

-- 创建圆角
function ShopUtils.createCorner(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Config.UI.SIZES.CORNER_RADIUS)
    corner.Parent = frame
    return corner
end

-- 创建现代按钮
function ShopUtils.createButton(text, color, parent, callback)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Size = UDim2.new(0, 120, 0, Config.UI.SIZES.BUTTON_HEIGHT)
    button.Parent = parent

    ShopUtils.createCorner(button, 12)

    -- 添加微妙的内阴影
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(255, 255, 255)
    innerStroke.Transparency = 0.9
    innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    innerStroke.Parent = button

    -- 存储按钮状态
    button:SetAttribute("OriginalColor", color)
    button:SetAttribute("IsActive", false)

    -- 计算颜色
    local hoverColor = Color3.new(
        math.min(1, color.R + 0.15),
        math.min(1, color.G + 0.15),
        math.min(1, color.B + 0.15)
    )

    -- 悬停效果 - 只改变颜色和边框，不改变大小
    button.MouseEnter:Connect(function()
        if not button:GetAttribute("IsActive") then
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = hoverColor
            }):Play()
        end
        -- 边框发光效果
        TweenService:Create(innerStroke, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
    end)

    button.MouseLeave:Connect(function()
        if not button:GetAttribute("IsActive") then
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = color
            }):Play()
        end
        -- 恢复边框（除非是激活状态）
        if not button:GetAttribute("IsActive") then
            TweenService:Create(innerStroke, TweenInfo.new(0.2), {Transparency = 0.9}):Play()
        end
    end)

    -- 点击效果 - 完全移除大小变化
    button.MouseButton1Down:Connect(function()
        -- 只有轻微的颜色变化表示点击
        local clickColor = Color3.new(
            math.max(0, color.R - 0.1),
            math.max(0, color.G - 0.1),
            math.max(0, color.B - 0.1)
        )
        TweenService:Create(button, TweenInfo.new(0.05), {
            BackgroundColor3 = clickColor
        }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        -- 恢复到适当的颜色
        local targetColor = button:GetAttribute("IsActive") and ShopUtils.COLORS.ACCENT or color
        TweenService:Create(button, TweenInfo.new(0.05), {
            BackgroundColor3 = targetColor
        }):Play()
    end)

    if callback then
        button.MouseButton1Click:Connect(function()
            ShopUtils.SOUNDS.click:Play()
            callback()
        end)
    end

    return button
end

-- 设置按钮激活状态
function ShopUtils.setButtonActive(button, isActive)
    if not button then return end

    button:SetAttribute("IsActive", isActive)

    local originalColor = button:GetAttribute("OriginalColor") or ShopUtils.COLORS.SECONDARY
    local innerStroke = button:FindFirstChild("UIStroke")

    if isActive then
        -- 激活状态：使用强调色，保持发光边框
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = ShopUtils.COLORS.ACCENT,
            TextColor3 = ShopUtils.COLORS.PRIMARY
        }):Play()

        if innerStroke then
            TweenService:Create(innerStroke, TweenInfo.new(0.2), {
                Transparency = 0.5,
                Color = ShopUtils.COLORS.PRIMARY
            }):Play()
        end
    else
        -- 非激活状态：恢复原始颜色
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = originalColor,
            TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        }):Play()

        if innerStroke then
            TweenService:Create(innerStroke, TweenInfo.new(0.2), {
                Transparency = 0.9,
                Color = Color3.fromRGB(255, 255, 255)
            }):Play()
        end
    end
end

-- 格式化时间戳
function ShopUtils.formatTimestamp(timestamp)
    if not timestamp or timestamp == "" then
        return "未知时间"
    end

    -- 如果是数字时间戳(Unix timestamp)，转换为可读格式
    if type(timestamp) == "number" then
        -- 检查时间戳是否合理 (避免显示1970年或未来很远的时间)
        if timestamp > 0 and timestamp < 4102444800 then -- 2100年前
            return os.date("%Y-%m-%d %H:%M", timestamp)
        else
            return "无效时间"
        end
    end

    -- 如果是字符串，尝试不同的解析方式
    if type(timestamp) == "string" then
        -- 尝试转换为数字时间戳
        local numTimestamp = tonumber(timestamp)
        if numTimestamp and numTimestamp > 0 and numTimestamp < 4102444800 then
            return os.date("%Y-%m-%d %H:%M", numTimestamp)
        end

        -- 处理 MySQL 格式的时间戳 (YYYY-MM-DD HH:MM:SS)
        local year, month, day, hour, min, sec = timestamp:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
        if year then
            return string.format("%s-%s-%s %s:%s", year, month, day, hour, min)
        end

        -- 处理 ISO 格式 (YYYY-MM-DDTHH:MM:SS.sssZ)
        local isoYear, isoMonth, isoDay, isoHour, isoMin, isoSec = timestamp:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
        if isoYear then
            return string.format("%s-%s-%s %s:%s", isoYear, isoMonth, isoDay, isoHour, isoMin)
        end

        -- 处理日期格式 (YYYY-MM-DD)
        local dateYear, dateMonth, dateDay = timestamp:match("(%d+)-(%d+)-(%d+)")
        if dateYear then
            return string.format("%s-%s-%s", dateYear, dateMonth, dateDay)
        end

        -- 如果无法解析，返回原始字符串的前19个字符（通常是时间部分）
        if #timestamp > 19 then
            return timestamp:sub(1, 19)
        end

        -- 如果长度合适，直接返回
        if #timestamp > 0 then
            return timestamp
        end
    end

    return "格式错误"
end

-- 显示通知
function ShopUtils.showNotification(message, isSuccess, screenGui)
    if not screenGui then
        warn("ShopUtils.showNotification: screenGui参数为空")
        return
    end

    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 400, 0, 80)
    notification.Position = UDim2.new(0.5, -200, 0, -100)
    notification.BackgroundColor3 = isSuccess and ShopUtils.COLORS.SUCCESS or ShopUtils.COLORS.ERROR
    notification.BorderSizePixel = 0
    notification.Parent = screenGui

    ShopUtils.createCorner(notification, 12)

    local text = Instance.new("TextLabel")
    text.Text = tostring(message) -- 确保message是字符串
    text.Font = Enum.Font.SourceSansBold
    text.TextSize = 18
    text.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    text.Size = UDim2.new(1, -20, 1, 0)
    text.Position = UDim2.new(0, 10, 0, 0)
    text.BackgroundTransparency = 1
    text.TextWrapped = true
    text.Parent = notification

    -- 动画
    local showTween = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -200, 0, 50)
    })
    showTween:Play()

    -- 使用spawn来避免阻塞主线程
    spawn(function()
        wait(3)

        if notification and notification.Parent then
            local hideTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Position = UDim2.new(0.5, -200, 0, -100)
            })
            hideTween:Play()

            hideTween.Completed:Connect(function()
                if notification and notification.Parent then
                    notification:Destroy()
                end
            end)
        end
    end)

    -- 播放音效（如果可用）
    pcall(function()
        if isSuccess and ShopUtils.SOUNDS.success then
            ShopUtils.SOUNDS.success:Play()
        elseif not isSuccess and ShopUtils.SOUNDS.error then
            ShopUtils.SOUNDS.error:Play()
        end
    end)
end

return ShopUtils
