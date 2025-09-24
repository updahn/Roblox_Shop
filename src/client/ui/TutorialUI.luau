-- 引导教程UI模块

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TutorialUI = {}

-- 私有变量
local tutorialGui = nil
local isShowing = false
local currentStep = 1

-- 教程步骤数据 - 精简的新手引导
local tutorialSteps = {
    {
        title = "🎉 欢迎来到商店系统",
        content = "欢迎体验功能完整的商店系统！\n\n🏪 丰富商品分类\n• 武器装备 • 消耗品\n• 珍贵材料 • 工具书籍\n• 会员特权\n\n✨ 核心功能\n• 智能交易 • 金币管理\n• 交易记录 • 会员系统",
        buttonText = "开始教程"
    },
    {
        title = "💰 金币经济系统",
        content = "💎 起始资金：1000 金币\n\n💰 获取金币\n• 出售物品（80% 回收价）\n• 会员每日奖励\n• 活动奖励\n\n💸 消费方式\n• 购买商品（含5%税费）\n• 升级会员\n• 限量稀有物品\n\n📊 实时余额显示",
        buttonText = "继续"
    },
    {
        title = "🛍️ 操作指南",
        content = "⌨️ 快捷键\n• E - 打开商店\n• H - 查看帮助\n• B - 召唤无人机\n• N - 收回无人机\n• M - 切换无人机模式\n\n🖱️ 鼠标操作\n• 左键 - 选择确认\n• 滚轮 - 浏览商品\n\n📱 界面布局\n• 顶部：余额信息\n• 左侧：分类导航\n• 中央：商品展示\n• 底部：操作按钮",
        buttonText = "明白了"
    },
    {
        title = "🛒 购买流程",
        content = "🏪 简单四步骤\n1️⃣ 浏览商品\n2️⃣ 选择物品\n3️⃣ 设定数量\n4️⃣ 确认购买\n\n🏷️ 商品信息\n• 价格和税费透明\n• 库存实时更新\n• 限购规则明确\n\n⚠️ 购买提示\n• 检查余额充足\n• 注意限购数量",
        buttonText = "继续"
    },
    {
        title = "💸 出售系统",
        content = "💰 出售规则\n• 80% 回收价格\n• 批量出售支持\n• 即时到账无延迟\n\n📦 库存管理\n• 分类显示所有物品\n• 显示数量和价值\n• 搜索筛选功能\n\n💡 出售建议\n• 优先出售过量普通物品\n• 保留稀有物品",
        buttonText = "下一步"
    },
    {
        title = "📊 交易记录",
        content = "📋 记录内容\n• 完整购买出售历史\n• 精确时间和金额\n• 金币变化详情\n\n🔍 查询功能\n• 时间范围筛选\n• 交易类型分类\n• 物品名称搜索\n• 导出交易数据\n\n📈 数据统计\n• 总交易次数和金额\n• 收入支出分析\n• 物品交易排行",
        buttonText = "了解了"
    },
    {
        title = "🤖 无人机系统",
        content = "🚁 无人机功能\n• 智能AI战斗伙伴\n• 自动跟随并保护玩家\n• 强大的自动攻击能力\n• 10秒生存时间\n\n⌨️ 无人机快捷键\n• B - 召唤无人机\n• N - 收回无人机\n• M - 切换模式(跟随/驻守)\n\n🎯 靶子训练场\n• 3个专用训练靶子\n• 无人机优先攻击靶子\n• 靶子自动重生\n\n🤖 智能模式\n• 跟随模式：贴身保护\n• 驻守模式：定点防守",
        buttonText = "太酷了"
    },
    {
        title = "👑 会员系统",
        content = "💎 会员类型\n• 周卡 - 7天 每日100金币\n• 月卡 - 30天 每日100金币\n• 季卡 - 90天 每日100金币\n• 高级月卡 - 30天 每日200金币\n• VIP年卡 - 365天 每日150金币\n\n🎁 会员特权\n• 每日登录奖励\n• 最多7天补发\n• 专属商品折扣\n\n⏰ 奖励机制\n• 首次登录自动领取\n• 离线奖励累积保存\n• 到期停止发放",
        buttonText = "很棒"
    },
    {
        title = "🎮 准备开始！",
        content = "🎓 恭喜！你已经掌握了所有核心功能\n\n✅ 基础操作\n• E键打开商店\n• H键查看帮助\n• B键召唤无人机\n• N键收回无人机\n• M键切换无人机模式\n\n✅ 交易系统\n• 购买出售完整流程\n• 交易记录查询方法\n\n✅ 进阶功能\n• 会员系统和每日奖励\n• 无人机战斗系统\n• 数据统计和趋势分析\n\n🚀 现在就开始你的商店之旅吧！\n💡 明智投资和交易是成功关键！",
        buttonText = "开始游戏"
    }
}

-- 创建教程UI
local function createTutorialGUI()
    if tutorialGui then
        tutorialGui:Destroy()
    end

    -- 主GUI
    tutorialGui = Instance.new("ScreenGui")
    tutorialGui.Name = "TutorialGUI"
    tutorialGui.ResetOnSpawn = false
    tutorialGui.IgnoreGuiInset = true -- 不遮盖核心GUI界面
    tutorialGui.Parent = playerGui

    -- 背景遮罩
    local overlay = Instance.new("TextButton")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.AutoButtonColor = false
    overlay.Parent = tutorialGui

    -- 主面板
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 580, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -290, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.new(0.98, 0.98, 0.98)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = overlay

    -- 阴影效果
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 10, 10)
    shadow.ZIndex = mainFrame.ZIndex - 1
    shadow.Parent = overlay

    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame

    -- 标题背景
    local titleBg = Instance.new("Frame")
    titleBg.Name = "TitleBackground"
    titleBg.Size = UDim2.new(1, 0, 0, 80)
    titleBg.Position = UDim2.new(0, 0, 0, 0)
    titleBg.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    titleBg.BorderSizePixel = 0
    titleBg.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 20)
    titleCorner.Parent = titleBg

    -- 标题文本
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tutorialSteps[1].title
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = titleBg

    -- 内容区域
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -40, 0, 240)
    contentFrame.Position = UDim2.new(0, 20, 0, 100)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "Content"
    contentLabel.Size = UDim2.new(1, 0, 1, 0)
    contentLabel.Position = UDim2.new(0, 0, 0, 0)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = tutorialSteps[1].content
    contentLabel.TextColor3 = Color3.fromRGB(44, 62, 80)
    contentLabel.TextSize = 16
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.Parent = contentFrame

    -- 步骤指示器
    local stepFrame = Instance.new("Frame")
    stepFrame.Name = "StepIndicator"
    stepFrame.Size = UDim2.new(1, -40, 0, 30)
    stepFrame.Position = UDim2.new(0, 20, 0, 350)
    stepFrame.BackgroundTransparency = 1
    stepFrame.Parent = mainFrame

    local stepLayout = Instance.new("UIListLayout")
    stepLayout.FillDirection = Enum.FillDirection.Horizontal
    stepLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    stepLayout.Padding = UDim.new(0, 10)
    stepLayout.Parent = stepFrame

    -- 创建步骤指示点
    for i = 1, #tutorialSteps do
        local dot = Instance.new("Frame")
        dot.Name = "Dot" .. i
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.BackgroundColor3 = i == 1 and Color3.new(0.2, 0.6, 1) or Color3.new(0.8, 0.8, 0.8)
        dot.BorderSizePixel = 0
        dot.Parent = stepFrame

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(0.5, 0)
        dotCorner.Parent = dot
    end

    -- 按钮
    local nextButton = Instance.new("TextButton")
    nextButton.Name = "NextButton"
    nextButton.Size = UDim2.new(0, 130, 0, 50)
    nextButton.Position = UDim2.new(1, -150, 1, -70)
    nextButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    nextButton.BorderSizePixel = 0
    nextButton.Text = tutorialSteps[1].buttonText
    nextButton.TextColor3 = Color3.new(1, 1, 1)
    nextButton.TextSize = 18
    nextButton.Font = Enum.Font.GothamSemibold
    nextButton.Parent = mainFrame

    -- 按钮阴影
    local btnShadow = Instance.new("Frame")
    btnShadow.Name = "ButtonShadow"
    btnShadow.Size = UDim2.new(1, 4, 1, 4)
    btnShadow.Position = UDim2.new(0, -2, 0, 2)
    btnShadow.BackgroundColor3 = Color3.new(0, 0, 0)
    btnShadow.BackgroundTransparency = 0.8
    btnShadow.BorderSizePixel = 0
    btnShadow.ZIndex = nextButton.ZIndex - 1
    btnShadow.Parent = nextButton

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 12)
    buttonCorner.Parent = nextButton

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 12)
    shadowCorner.Parent = btnShadow

    -- 按钮悬停效果
    nextButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            nextButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(39, 174, 96)}
        )
        hoverTween:Play()
    end)

    nextButton.MouseLeave:Connect(function()
        local hoverTween = TweenService:Create(
            nextButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(46, 204, 113)}
        )
        hoverTween:Play()
    end)

    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 35, 0, 35)
    closeButton.Position = UDim2.new(1, -45, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBg

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 17)
    closeCorner.Parent = closeButton

    -- 关闭按钮悬停效果
    closeButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            closeButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(192, 57, 43)}
        )
        hoverTween:Play()
    end)

    closeButton.MouseLeave:Connect(function()
        local hoverTween = TweenService:Create(
            closeButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(231, 76, 60)}
        )
        hoverTween:Play()
    end)

    -- 按钮事件
    nextButton.MouseButton1Click:Connect(function()
        nextStep()
    end)

    closeButton.MouseButton1Click:Connect(function()
        hideTutorial()
    end)

    -- 背景遮罩点击关闭
    overlay.MouseButton1Click:Connect(function()
        hideTutorial()
    end)

    -- 动画效果
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

    local openTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 350),
            Position = UDim2.new(0.5, -250, 0.5, -175)
        }
    )
    openTween:Play()

    return mainFrame
end

-- 更新教程内容
local function updateTutorialContent()
    if not tutorialGui then return end

    local mainFrame = tutorialGui.Overlay.MainFrame
    local titleLabel = mainFrame.TitleBackground.Title
    local contentLabel = mainFrame.ContentFrame.Content
    local nextButton = mainFrame.NextButton
    local stepFrame = mainFrame.StepIndicator

    -- 更新内容
    titleLabel.Text = tutorialSteps[currentStep].title
    contentLabel.Text = tutorialSteps[currentStep].content
    nextButton.Text = tutorialSteps[currentStep].buttonText

    -- 更新步骤指示器
    for i = 1, #tutorialSteps do
        local dot = stepFrame:FindFirstChild("Dot" .. i)
        if dot then
            dot.BackgroundColor3 = i == currentStep and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(189, 195, 199)

            -- 移除旧的高亮效果
            local oldHighlight = dot:FindFirstChild("Highlight")
            if oldHighlight then
                oldHighlight:Destroy()
            end

            -- 为当前步骤添加高亮效果
            if i == currentStep then
                local highlight = Instance.new("Frame")
                highlight.Name = "Highlight"
                highlight.Size = UDim2.new(1, 6, 1, 6)
                highlight.Position = UDim2.new(0, -3, 0, -3)
                highlight.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
                highlight.BackgroundTransparency = 0.6
                highlight.BorderSizePixel = 0
                highlight.ZIndex = dot.ZIndex - 1
                highlight.Parent = dot

                local highlightCorner = Instance.new("UICorner")
                highlightCorner.CornerRadius = UDim.new(0.5, 0)
                highlightCorner.Parent = highlight
            end
        end
    end
end

-- 下一步
function nextStep()
    currentStep = currentStep + 1

    if currentStep > #tutorialSteps then
        hideTutorial()
    else
        updateTutorialContent()
    end
end

-- 显示教程
function TutorialUI.showTutorial()
    if isShowing then return end

    isShowing = true
    currentStep = 1
    createTutorialGUI()
end

-- 隐藏教程
function hideTutorial()
    if not isShowing or not tutorialGui then return end

    local mainFrame = tutorialGui.Overlay.MainFrame

    local closeTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )

    closeTween:Play()
    closeTween.Completed:Connect(function()
        if tutorialGui then
            tutorialGui:Destroy()
            tutorialGui = nil
        end
        isShowing = false
    end)
end

-- 隐藏教程（公共接口）
function TutorialUI.hideTutorial()
    hideTutorial()
end

-- 检查是否正在显示
function TutorialUI.isShowing()
    return isShowing
end

-- 初始化
function TutorialUI.initialize()
    -- 延迟3秒显示教程，给玩家一些时间适应
    spawn(function()
        wait(3)
        TutorialUI.showTutorial()
    end)
end

return TutorialUI
