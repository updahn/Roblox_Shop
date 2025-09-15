-- 商店UI公用工具类

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local ShopUtils = {}

-- 颜色主题 - 现代深色设计
ShopUtils.COLORS = {
    -- 主色调
    PRIMARY = Color3.fromRGB(25, 25, 35),       -- 深色背景
    SECONDARY = Color3.fromRGB(35, 35, 45),     -- 中等深色
    TERTIARY = Color3.fromRGB(45, 45, 55),      -- 浅一点的深色
    ACCENT = Color3.fromRGB(88, 166, 255),      -- 现代蓝色
    ACCENT_HOVER = Color3.fromRGB(108, 186, 255), -- 悬停蓝色
    SUCCESS = Color3.fromRGB(52, 211, 153),     -- 现代绿色
    WARNING = Color3.fromRGB(251, 191, 36),     -- 现代黄色
    ERROR = Color3.fromRGB(248, 113, 113),      -- 现代红色

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
}

-- 音效
local function createSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/" .. soundId
    sound.Volume = volume or 0.5
    sound.Parent = SoundService
    return sound
end

ShopUtils.SOUNDS = {
    click = createSound("electronicpingshort.wav", 0.3),
    success = createSound("victory.wav", 0.4),
    error = createSound("splat.wav", 0.3),
}

-- 创建圆角
function ShopUtils.createCorner(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
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
    button.Size = UDim2.new(0, 120, 0, 40)
    button.Parent = parent

    ShopUtils.createCorner(button, 12)

    -- 添加微妙的内阴影
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(255, 255, 255)
    innerStroke.Transparency = 0.9
    innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    innerStroke.Parent = button

    -- 悬停效果
    local originalColor = color
    local hoverColor = Color3.new(
        math.min(1, originalColor.R + 0.15),
        math.min(1, originalColor.G + 0.15),
        math.min(1, originalColor.B + 0.15)
    )

    button.MouseEnter:Connect(function()
        -- 悬停时的缩放和颜色变化
        local hoverTween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = hoverColor,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 4, button.Size.Y.Scale, button.Size.Y.Offset + 2)
        })
        hoverTween:Play()

        -- 边框发光效果
        TweenService:Create(innerStroke, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
    end)

    button.MouseLeave:Connect(function()
        -- 恢复原始状态
        local leaveTween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = originalColor,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 4, button.Size.Y.Scale, button.Size.Y.Offset - 2)
        })
        leaveTween:Play()

        -- 恢复边框
        TweenService:Create(innerStroke, TweenInfo.new(0.2), {Transparency = 0.9}):Play()
    end)

    -- 点击效果
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 2, button.Size.Y.Scale, button.Size.Y.Offset - 1)
        }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 2, button.Size.Y.Scale, button.Size.Y.Offset + 1)
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

-- 显示通知
function ShopUtils.showNotification(message, isSuccess, screenGui)
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 400, 0, 80)
    notification.Position = UDim2.new(0.5, -200, 0, -100)
    notification.BackgroundColor3 = isSuccess and ShopUtils.COLORS.SUCCESS or ShopUtils.COLORS.ERROR
    notification.BorderSizePixel = 0
    notification.Parent = screenGui

    ShopUtils.createCorner(notification, 12)

    local text = Instance.new("TextLabel")
    text.Text = message
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

    wait(3)

    local hideTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -200, 0, -100)
    })
    hideTween:Play()

    hideTween.Completed:Connect(function()
        notification:Destroy()
    end)

    -- if isSuccess then
    --     ShopUtils.SOUNDS.success:Play()
    -- else
    --     ShopUtils.SOUNDS.error:Play()
    -- end
end

return ShopUtils
