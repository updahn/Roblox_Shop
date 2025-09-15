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

-- 教程步骤数据
local tutorialSteps = {
    {
        title = "🎉 欢迎来到商店系统！",
        content = "这是一个功能完整的商店系统，包含8种精美商品。\n\n• 支持买卖物品\n• 实时金币系统\n• 交易记录查看\n\n让我们开始教程吧！",
        buttonText = "开始教程"
    },
    {
        title = "💰 金币系统",
        content = "你开始时有 3000 金币。\n\n• 购买物品需要消耗金币\n• 出售物品可获得金币\n• 金币余额实时显示在界面顶部",
        buttonText = "了解更多"
    },
    {
        title = "🛍️ 打开商店",
        content = "按 **E** 键可以打开商店界面。\n\n• 商店有三个标签页：购买、出售、记录\n• 按 **ESC** 键可以关闭界面\n• 按 **H** 键可以查看帮助",
        buttonText = "明白了"
    },
    {
        title = "🛒 购买物品",
        content = "在「购买」标签页中：\n\n• 浏览8种精美商品\n• 查看价格和库存信息\n• 点击「购买」选择数量\n• 确认购买完成交易",
        buttonText = "继续"
    },
    {
        title = "💸 出售物品",
        content = "在「出售」标签页中：\n\n• 查看你拥有的所有物品\n• 出售价格是原价的80%\n• 选择出售数量获得金币\n• 支持批量出售操作",
        buttonText = "下一步"
    },
    {
        title = "📊 交易记录",
        content = "在「记录」标签页中：\n\n• 查看所有购买和出售历史\n• 显示交易时间和金额\n• 管理员可查看全服数据\n• 记录永久保存",
        buttonText = "了解了"
    },
    {
        title = "🎮 开始游戏",
        content = "教程完成！现在你已经掌握了：\n\n✅ 如何打开商店 (E键)\n✅ 如何购买和出售物品\n✅ 如何查看交易记录\n✅ 如何获取帮助 (H键)\n\n祝你游戏愉快！",
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
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
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
