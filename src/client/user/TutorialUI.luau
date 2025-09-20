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

-- 教程步骤数据 - 完整的新手引导
local tutorialSteps = {
    {
        title = "🎉 欢迎来到商店系统！",
        content = "欢迎来到这个功能完整的商店系统！\n\n🏪 商品种类丰富：\n• 武器装备 - 剑类、盾牌、护甲\n• 消耗品 - 药水、食物、卷轴\n• 材料 - 宝石、矿石、木材\n• 工具书籍 - 法术书、历史书、地图\n• 会员卡 - 月卡、周卡、季卡等\n\n✨ 核心功能：\n• 智能买卖系统\n• 实时金币管理\n• 完整交易记录\n• 会员特权系统",
        buttonText = "开始教程"
    },
    {
        title = "💰 金币与经济系统",
        content = "💎 初始资金：每个新玩家都有 1000 金币起步\n\n💰 金币获取方式：\n• 出售物品获得金币（原价80%）\n• 会员每日登录奖励\n• 管理员活动奖励\n\n💸 金币消费：\n• 购买商品需要金币+税费（5%交易税）\n• 购买会员卡享受特权\n• 部分稀有物品限量购买\n\n📊 实时显示：\n• 界面顶部显示当前余额\n• 交易时显示金额变化\n• 支持大额数字格式化显示",
        buttonText = "了解更多"
    },
    {
        title = "🛍️ 商店操作指南",
        content = "⌨️ 键盘快捷键：\n• 按 **E** 键 - 打开/关闭商店界面\n• 按 **ESC** 键 - 快速关闭所有界面\n• 按 **H** 键 - 查看详细帮助文档\n• 按 **Tab** 键 - 切换界面标签页\n\n🖱️ 鼠标操作：\n• 左键点击 - 选择和确认\n• 右键点击 - 快速操作菜单\n• 滚轮滚动 - 浏览商品列表\n\n📱 界面布局：\n• 顶部：金币余额和用户信息\n• 左侧：商品分类导航\n• 中央：商品展示区域\n• 底部：操作按钮和状态栏",
        buttonText = "明白了"
    },
    {
        title = "🛒 商品购买详解",
        content = "🏪 购买流程：\n1️⃣ 浏览商品 - 在购买标签页查看所有商品\n2️⃣ 选择商品 - 点击心仪的物品查看详情\n3️⃣ 设定数量 - 使用数量选择器（注意限购）\n4️⃣ 确认购买 - 检查总价并确认交易\n\n🏷️ 商品信息：\n• 名称和图标 - 清晰的物品标识\n• 价格和税费 - 透明的费用计算\n• 库存状态 - 实时更新可用数量\n• 限购规则 - 每日/总量购买限制\n• 商品描述 - 详细的属性说明\n\n⚠️ 购买限制：\n• 检查金币余额是否充足\n• 注意每日限购数量\n• 某些特殊物品不可重复购买",
        buttonText = "继续"
    },
    {
        title = "💸 物品出售系统",
        content = "💰 出售规则：\n• 出售价格 = 原购买价格 × 80%\n• 支持批量选择出售\n• 即时到账，无延迟\n• 自动计算最优出售方案\n\n📦 库存管理：\n• 按分类显示所有拥有物品\n• 显示每个物品的数量和价值\n• 支持搜索和筛选功能\n• 一键批量出售同类物品\n\n🔒 出售限制：\n• 某些特殊物品不可出售\n• 会员卡等消耗品不可转售\n• 任务道具可能有出售限制\n\n💡 出售建议：\n• 价格波动时选择合适时机\n• 优先出售过量的普通物品\n• 保留稀有物品以备不时之需",
        buttonText = "下一步"
    },
    {
        title = "📊 交易记录中心",
        content = "📋 记录内容：\n• 完整的购买和出售历史\n• 精确的交易时间和金额\n• 详细的物品信息和数量\n• 交易前后的金币变化\n\n🔍 查询功能：\n• 按时间范围筛选记录\n• 按交易类型分类查看\n• 按物品名称搜索\n• 支持导出交易数据\n\n📈 数据统计：\n• 总交易次数和金额\n• 收入支出分析图表\n• 最常交易的物品排行\n• 交易趋势和习惯分析\n\n👑 管理员特权：\n• 管理员可查看全服交易数据\n• 监控异常交易行为\n• 生成系统运营报告",
        buttonText = "了解了"
    },
    {
        title = "👑 会员系统介绍",
        content = "💎 会员类型：\n• 周卡会员 - 7天特权，每日100金币\n• 月卡会员 - 30天特权，每日100金币\n• 季卡会员 - 90天特权，每日100金币\n• 高级月卡 - 30天特权，每日200金币\n• VIP年卡 - 365天特权，每日150金币\n\n🎁 会员特权：\n• 每日登录奖励自动发放\n• 支持最多7天的奖励补发\n• 会员专属商品和折扣\n• 优先客服支持\n\n⏰ 奖励机制：\n• 每日首次登录自动领取\n• 离线期间奖励会累积保存\n• 会员到期后停止奖励发放\n• 续费会员可延长有效期",
        buttonText = "很棒"
    },
    {
        title = "🎮 准备开始游戏！",
        content = "🎓 恭喜！你已经掌握了所有核心功能：\n\n✅ 基础操作：\n• E键打开商店，ESC关闭界面\n• H键查看帮助，Tab切换标签\n\n✅ 交易系统：\n• 购买商品的完整流程\n• 出售物品的最佳策略\n• 交易记录的查询方法\n\n✅ 进阶功能：\n• 会员系统和每日奖励\n• 库存管理和批量操作\n• 数据统计和趋势分析\n\n🚀 现在就开始你的商店之旅吧！\n记住：明智的投资和交易是成功的关键！",
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
    mainFrame.Size = UDim2.new(0, 500, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = overlay

    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame

    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -40, 0, 60)
    titleLabel.Position = UDim2.new(0, 20, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tutorialSteps[1].title
    titleLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame

    -- 内容
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "Content"
    contentLabel.Size = UDim2.new(1, -40, 0, 180)
    contentLabel.Position = UDim2.new(0, 20, 0, 90)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = tutorialSteps[1].content
    contentLabel.TextColor3 = Color3.new(0.3, 0.3, 0.3)
    contentLabel.TextScaled = true
    contentLabel.Font = Enum.Font.SourceSans
    contentLabel.TextWrapped = true
    contentLabel.Parent = mainFrame

    -- 步骤指示器
    local stepFrame = Instance.new("Frame")
    stepFrame.Name = "StepIndicator"
    stepFrame.Size = UDim2.new(1, -40, 0, 30)
    stepFrame.Position = UDim2.new(0, 20, 0, 280)
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
    nextButton.Size = UDim2.new(0, 120, 0, 40)
    nextButton.Position = UDim2.new(1, -140, 1, -60)
    nextButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
    nextButton.BorderSizePixel = 0
    nextButton.Text = tutorialSteps[1].buttonText
    nextButton.TextColor3 = Color3.new(1, 1, 1)
    nextButton.TextScaled = true
    nextButton.Font = Enum.Font.SourceSansBold
    nextButton.Parent = mainFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = nextButton

    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.9, 0.3, 0.3)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = mainFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton

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
    local titleLabel = mainFrame.Title
    local contentLabel = mainFrame.Content
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
            dot.BackgroundColor3 = i == currentStep and Color3.new(0.2, 0.6, 1) or Color3.new(0.8, 0.8, 0.8)
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
