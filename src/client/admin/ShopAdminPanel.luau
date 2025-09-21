-- 统一的管理员控制面板
-- 整合了用户管理、记录查看、会员管理等功能

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))
local ShopEvents = require(SharedModules:WaitForChild("ShopEvents"))
local ShopUtils = require(script.Parent.Parent:WaitForChild("ShopUtils"))
local ShopRecords = require(script.Parent.Parent.user:WaitForChild("ShopRecords"))

local player = Players.LocalPlayer

local ShopAdminPanel = {}

-- UI 元素引用
local adminFrame = nil
local contentArea = nil
local tabButtons = {}
local currentTab = "users"
local currentScreenGui = nil  -- 存储传入的screenGui引用

-- 数据存储
local allPlayersData = {}
local membershipData = {}
local currentViewingPlayer = nil  -- 当前查看的玩家

-- 标签配置 - 默认只显示用户管理
local tabs = {
    {id = "users", name = "👤 用户管理", icon = "👤"}
}

-- 所有可用标签（用于动态添加）
local allTabs = {
    {id = "users", name = "👤 用户管理", icon = "👤"},
    {id = "records", name = "📊 交易记录", icon = "📊"},
    {id = "membership", name = "👥 会员管理", icon = "👥"}
}

-- 显示管理员面板主入口
function ShopAdminPanel.showAdminPanel(screenGui, showNotification)
    print("🔧 [统一管理面板] 显示管理员面板")

    -- 保存screenGui引用以供后续使用
    currentScreenGui = screenGui

    -- 检查管理员权限 - 增加容错机制
    local isAdmin = false
    print("🔍 [统一管理面板] 开始权限检查 - 玩家:", player.Name)
    local adminCheckSuccess, adminResult = pcall(function()
        return Config.isValidAdmin(player)
    end)

    if adminCheckSuccess then
        isAdmin = adminResult
        print("✅ [统一管理面板] Config权限检查成功:", player.Name, "->", isAdmin)
    end

    if not isAdmin then
        print("❌ [统一管理面板] 管理员权限检查失败")
        if showNotification then
            showNotification("❌ 您没有管理员权限", false)
        end
        return
    end

    print("✅ [统一管理面板] 管理员权限验证通过，开始创建管理员面板")

    -- 如果面板已存在，先销毁
    if adminFrame then
        adminFrame:Destroy()
        adminFrame = nil
    end

    -- 创建主管理面板
    adminFrame = Instance.new("Frame")
    adminFrame.Name = "AdminPanel"
    adminFrame.Size = UDim2.new(0, 900, 0, 650)
    adminFrame.Position = UDim2.new(0.5, -450, 0.5, -325)
    adminFrame.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    adminFrame.BorderSizePixel = 0
    adminFrame.ZIndex = 3000
    adminFrame.Parent = screenGui
    ShopUtils.createCorner(adminFrame, 12)

    print("✅ [统一管理面板] 主面板创建成功")

    -- 创建标题栏
    ShopAdminPanel._createTitleBar(adminFrame)
    print("✅ [统一管理面板] 标题栏创建成功")

    -- 创建标签栏
    ShopAdminPanel._createTabBar(adminFrame)
    print("✅ [统一管理面板] 标签栏创建成功")

    -- 创建内容区域
    ShopAdminPanel._createContentArea(adminFrame)
    print("✅ [统一管理面板] 内容区域创建成功")

    -- 等待一帧，确保UI元素完全创建
    wait()

    -- 显示默认标签
    print("🔄 [统一管理面板] 准备切换到用户管理标签")
    ShopAdminPanel.switchTab("users", showNotification)
end

-- 创建标题栏
function ShopAdminPanel._createTitleBar(parentFrame)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = ShopUtils.COLORS.ACCENT
    titleBar.BorderSizePixel = 0
    titleBar.Parent = parentFrame
    ShopUtils.createCorner(titleBar, 12)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "👑 管理员控制面板"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = titleBar

    -- 关闭按钮
    local closeBtn = ShopUtils.createButton("✗", ShopUtils.COLORS.ERROR, titleBar, function()
        adminFrame:Destroy()
        adminFrame = nil
    end)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.TextSize = 20
end

-- 创建标签栏
function ShopAdminPanel._createTabBar(parentFrame)
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -20, 0, 50)
    tabBar.Position = UDim2.new(0, 10, 0, 70)
    tabBar.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    tabBar.BorderSizePixel = 0
    tabBar.Parent = parentFrame
    ShopUtils.createCorner(tabBar, 8)

    ShopAdminPanel._updateTabBar()
end

-- 更新标签栏显示
function ShopAdminPanel._updateTabBar()
    local tabBar = adminFrame and adminFrame:FindFirstChild("TabBar")
    if not tabBar then
        print("⚠️ [统一管理面板] 未找到TabBar元素")
        return
    end

    print("🔄 [统一管理面板] 更新标签栏，标签数量:", #tabs)

    -- 清除现有按钮
    for _, child in pairs(tabBar:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local buttonWidth = 1 / #tabs
    tabButtons = {}

    for i, tab in ipairs(tabs) do
        print("🏷️ [统一管理面板] 创建标签按钮:", tab.name, "ID:", tab.id)

        local tabButton = Instance.new("TextButton")
        tabButton.Name = "Tab_" .. tab.id
        tabButton.Size = UDim2.new(buttonWidth, -5, 1, -10)
        tabButton.Position = UDim2.new(buttonWidth * (i-1), 5, 0, 5)
        tabButton.BackgroundColor3 = tab.id == currentTab and ShopUtils.COLORS.ACCENT or ShopUtils.COLORS.PRIMARY
        tabButton.Text = tab.name
        tabButton.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.SourceSansBold
        tabButton.BorderSizePixel = 0
        tabButton.Parent = tabBar
        ShopUtils.createCorner(tabButton, 6)

        tabButton.MouseButton1Click:Connect(function()
            print("🖱️ [统一管理面板] 点击标签:", tab.id)
            ShopAdminPanel.switchTab(tab.id)
        end)

        tabButtons[tab.id] = tabButton
    end

    print("✅ [统一管理面板] 标签栏更新完成，创建了", #tabs, "个按钮")
end

-- 添加标签
function ShopAdminPanel._addTab(tabId)
    -- 检查标签是否已存在
    for _, tab in ipairs(tabs) do
        if tab.id == tabId then
            return
        end
    end

    -- 从allTabs中找到对应标签
    for _, tab in ipairs(allTabs) do
        if tab.id == tabId then
            table.insert(tabs, tab)
            break
        end
    end

    ShopAdminPanel._updateTabBar()
end

-- 移除标签（除了用户管理）
function ShopAdminPanel._removeTab(tabId)
    if tabId == "users" then return end

    for i, tab in ipairs(tabs) do
        if tab.id == tabId then
            table.remove(tabs, i)
            break
        end
    end

    ShopAdminPanel._updateTabBar()
end

-- 重置为默认标签（只显示用户管理）
function ShopAdminPanel._resetToDefaultTabs()
    tabs = {{id = "users", name = "👤 用户管理", icon = "👤"}}
    currentTab = "users"
    currentViewingPlayer = nil
    ShopAdminPanel._updateTabBar()
end

-- 创建内容区域
function ShopAdminPanel._createContentArea(parentFrame)
    contentArea = Instance.new("ScrollingFrame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -140)
    contentArea.Position = UDim2.new(0, 10, 0, 130)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.ScrollBarThickness = 8
    contentArea.ScrollBarImageColor3 = ShopUtils.COLORS.ACCENT
    contentArea.Parent = parentFrame
end

-- 切换标签
function ShopAdminPanel.switchTab(tabId, showNotification)
    -- 允许重复切换到同一标签，以支持刷新功能
    print("🔄 [统一管理面板] 切换到标签:", tabId)

    local wasFirstTime = (currentTab ~= tabId)
    currentTab = tabId

    -- 更新标签按钮样式
    for id, button in pairs(tabButtons) do
        if id == tabId then
            button.BackgroundColor3 = ShopUtils.COLORS.ACCENT
        else
            button.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
        end
    end

    -- 清空内容区域
    for _, child in pairs(contentArea:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    -- 根据标签显示对应内容
    if tabId == "users" then
        -- 首次切换到用户管理时，重置为默认标签
        if wasFirstTime then
            ShopAdminPanel._resetToDefaultTabs()
        end
        ShopAdminPanel._showUsersPanel(showNotification)
    elseif tabId == "records" then
        ShopAdminPanel._showRecordsPanel(showNotification)
    elseif tabId == "membership" then
        ShopAdminPanel._showMembershipPanel(showNotification)
    end
end

-- 显示用户管理面板
function ShopAdminPanel._showUsersPanel(showNotification)
    print("👤 [用户管理] 加载用户管理面板")

    -- 显示加载提示
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Text = "📡 正在加载玩家数据...\n请稍候，正在连接服务器"
    loadingLabel.Font = Enum.Font.SourceSans
    loadingLabel.TextSize = 16
    loadingLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
    loadingLabel.Size = UDim2.new(1, 0, 0, 100)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
    loadingLabel.TextYAlignment = Enum.TextYAlignment.Center
    loadingLabel.TextWrapped = true
    loadingLabel.Parent = contentArea

    -- 添加调试按钮
    local debugBtn = ShopUtils.createButton("🔧 显示测试数据", ShopUtils.COLORS.WARNING, contentArea, function()
        print("🔧 [调试] 手动显示测试数据")
        if loadingLabel and loadingLabel.Parent then
            loadingLabel:Destroy()
        end

        local testData = {
            [player.Name] = {
                userId = player.UserId,
                name = player.Name,
                coins = 1000,
                totalPurchases = 5,
                totalSpent = 500,
                totalSales = 3,
                totalEarned = 300,
                inventoryCount = 10,
                membership_status = "active",
                end_date = "2024-12-31",
                days_remaining = 30,
                daily_reward_coins = 100
            },
            ["测试用户1"] = {
                userId = 12345,
                name = "测试用户1",
                coins = 500,
                totalPurchases = 2,
                totalSpent = 200,
                totalSales = 1,
                totalEarned = 100,
                inventoryCount = 5,
                membership_status = "none",
                end_date = nil,
                days_remaining = 0,
                daily_reward_coins = 100
            },
            ["测试用户2"] = {
                userId = 67890,
                name = "测试用户2",
                coins = 2000,
                totalPurchases = 10,
                totalSpent = 1000,
                totalSales = 8,
                totalEarned = 800,
                inventoryCount = 15,
                membership_status = "active",
                end_date = "2024-10-15",
                days_remaining = 15,
                daily_reward_coins = 150
            }
        }

        ShopAdminPanel._displayAllPlayersData(testData, showNotification)
        if showNotification then
            showNotification("🔧 手动显示测试数据", true)
        end
    end)
    debugBtn.Position = UDim2.new(0.5, -80, 0, 120)
    debugBtn.Size = UDim2.new(0, 160, 0, 30)
    debugBtn.TextSize = 12

    -- 请求所有玩家数据
    print("📡 [用户管理] 发送请求到服务器获取用户数据")
    print("📡 [调试] 检查ShopEvents.Admin.GetAllUsers是否存在:", ShopEvents.Admin.GetAllUsers ~= nil)

    if ShopEvents.Admin.GetAllUsers then
        ShopEvents.Admin.GetAllUsers:FireServer()
        print("📡 [调试] 已发送GetAllUsers请求到服务器")
    else
        print("❌ [错误] ShopEvents.Admin.GetAllUsers 不存在")
        if showNotification then
            showNotification("❌ 事件系统错误", false)
        end
        return
    end

    -- 设置较短的超时机制，便于调试
    local timeoutTime = 8  -- 减少到8秒
    spawn(function()
        for i = 1, timeoutTime do
            wait(1)
            if not loadingLabel or not loadingLabel.Parent then
                return  -- 已经收到响应
            end
            loadingLabel.Text = string.format("📡 正在加载玩家数据...\n等待服务器响应 (%d/%d秒)", i, timeoutTime)
        end

        if loadingLabel and loadingLabel.Parent then
            print("⚠️ [用户管理] 请求超时，显示错误提示")
            loadingLabel.Text = "⚠️ 服务器响应超时\n可能原因：数据服务离线或网络问题"
            loadingLabel.TextColor3 = ShopUtils.COLORS.WARNING

            -- 5秒后自动显示测试数据
            spawn(function()
                wait(5)
                if loadingLabel and loadingLabel.Parent then
                    loadingLabel:Destroy()
                    debugBtn:Destroy()

                    local testData = {
                        [player.Name] = {
                            userId = player.UserId,
                            name = player.Name,
                            coins = 1000,
                            totalPurchases = 5,
                            totalSpent = 500,
                            totalSales = 3,
                            totalEarned = 300,
                            inventoryCount = 10,
                            membership_status = "active",
                            end_date = "2024-12-31",
                            days_remaining = 30,
                            daily_reward_coins = 100
                        },
                        ["测试用户1"] = {
                            userId = 12345,
                            name = "测试用户1",
                            coins = 500,
                            totalPurchases = 2,
                            totalSpent = 200,
                            totalSales = 1,
                            totalEarned = 100,
                            inventoryCount = 5,
                            membership_status = "none",
                            end_date = nil,
                            days_remaining = 0,
                            daily_reward_coins = 100
                        }
                    }

                    print("🧪 [测试] 自动显示测试数据")
                    ShopAdminPanel._displayAllPlayersData(testData, showNotification)
                    if showNotification then
                        showNotification("🧪 自动显示测试数据（服务器超时）", true)
                    end
                end
            end)
        end
    end)

    -- 监听服务器响应
    local connection
    local hasReceivedData = false
    local eventReceived = false

    print("👤 [调试] 开始监听服务器响应事件")

    if not ShopEvents.Admin.GetAllUsers.OnClientEvent then
        print("❌ [错误] ShopEvents.Admin.GetAllUsers.OnClientEvent 不存在")
        if showNotification then
            showNotification("❌ 事件监听器错误", false)
        end
        return
    end

    connection = ShopEvents.Admin.GetAllUsers.OnClientEvent:Connect(function(allPlayersData, errorMsg)
        eventReceived = true
        print("👤 [调试] 收到服务器响应事件！")
        print("👤 [调试] 参数1 (allPlayersData) 类型:", type(allPlayersData))
        print("👤 [调试] 参数2 (errorMsg):", errorMsg)

        -- 清理UI元素
        if loadingLabel and loadingLabel.Parent then
            loadingLabel:Destroy()
        end
        if debugBtn and debugBtn.Parent then
            debugBtn:Destroy()
        end

        -- 处理错误情况
        if errorMsg then
            print("❌ [错误] 获取用户数据失败:", errorMsg)
            hasReceivedData = false

            -- 创建错误显示
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Text = "❌ 服务器错误:\n" .. errorMsg .. "\n\n请稍候，将自动显示测试数据..."
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.TextColor3 = ShopUtils.COLORS.ERROR
            errorLabel.Size = UDim2.new(1, -20, 0, 150)
            errorLabel.Position = UDim2.new(0, 10, 0, 10)
            errorLabel.BackgroundTransparency = 1
            errorLabel.TextXAlignment = Enum.TextXAlignment.Center
            errorLabel.TextYAlignment = Enum.TextYAlignment.Top
            errorLabel.TextWrapped = true
            errorLabel.Parent = contentArea

            -- 添加重试按钮
            local retryBtn = ShopUtils.createButton("🔄 重试连接服务器", ShopUtils.COLORS.ACCENT, contentArea, function()
                for _, child in pairs(contentArea:GetChildren()) do
                    if child:IsA("GuiObject") then
                        child:Destroy()
                    end
                end
                ShopAdminPanel._showUsersPanel(showNotification)
            end)
            retryBtn.Position = UDim2.new(0.5, -80, 0, 170)
            retryBtn.Size = UDim2.new(0, 160, 0, 30)
            retryBtn.TextSize = 12

            if showNotification then
                showNotification("❌ 服务器连接失败", false)
            end

            -- 如果是模拟数据通知，不断开连接
            if string.find(errorMsg, "模拟数据") or string.find(errorMsg, "注意") then
                print("📝 [通知] 等待模拟数据...")
                if showNotification then
                    showNotification("📝 正在准备模拟数据...", true)
                end
                return -- 不断开连接，等待模拟数据
            end

        elseif allPlayersData and type(allPlayersData) == "table" then
            print("✅ [成功] 获取到用户数据，准备显示")
            hasReceivedData = true

            -- 检查数据内容
            if allPlayersData then
                print("👤 [调试] allPlayersData内容:", allPlayersData)
                if type(allPlayersData) == "table" then
                    local count = 0
                    for k, v in pairs(allPlayersData) do
                        count = count + 1
                        print("👤 [调试] 数据项", count, ":", k, "->", v)
                    end
                    print("👤 [调试] 总共有", count, "项数据")
                end
            end

            -- 检查是否是模拟数据
            local isSimulatedData = false
            for playerName, data in pairs(allPlayersData) do
                if string.find(playerName, "模拟") then
                    isSimulatedData = true
                    break
                end
            end

            if isSimulatedData and showNotification then
                showNotification("⚠️ 显示模拟数据（数据服务离线）", true)
            else
                if showNotification then
                    showNotification("✅ 用户数据加载成功", true)
                end
            end

            ShopAdminPanel._displayAllPlayersData(allPlayersData, showNotification)
            if connection then
                connection:Disconnect()
            end
        else
            print("❌ [错误] 未收到有效的用户数据")
            if not hasReceivedData then
                local noDataLabel = Instance.new("TextLabel")
                noDataLabel.Text = "❌ 无法加载玩家数据\n\n可能的原因：\n• 数据服务未响应\n• 数据库连接问题\n• 网络连接异常\n\n将自动显示测试数据供参考"
                noDataLabel.Font = Enum.Font.SourceSans
                noDataLabel.TextSize = 14
                noDataLabel.TextColor3 = ShopUtils.COLORS.ERROR
                noDataLabel.Size = UDim2.new(1, -20, 0, 200)
                noDataLabel.Position = UDim2.new(0, 10, 0, 10)
                noDataLabel.BackgroundTransparency = 1
                noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
                noDataLabel.TextYAlignment = Enum.TextYAlignment.Top
                noDataLabel.TextWrapped = true
                noDataLabel.Parent = contentArea

                if showNotification then
                    showNotification("❌ 无法加载真实数据", false)
                end

                -- 3秒后显示测试数据
                spawn(function()
                    wait(3)
                    if noDataLabel and noDataLabel.Parent then
                        noDataLabel:Destroy()

                        local testData = {
                            [player.Name] = {
                                userId = player.UserId,
                                name = player.Name,
                                coins = 1000,
                                totalPurchases = 5,
                                totalSpent = 500,
                                totalSales = 3,
                                totalEarned = 300,
                                inventoryCount = 10,
                                membership_status = "active",
                                end_date = "2024-12-31",
                                days_remaining = 30,
                                daily_reward_coins = 100
                            }
                        }

                        ShopAdminPanel._displayAllPlayersData(testData, showNotification)
                        if showNotification then
                            showNotification("🔧 显示基础测试数据", true)
                        end
                    end
                end)

                if connection then
                    connection:Disconnect()
                end
            end
        end
    end)

    print("👤 [调试] 事件监听器已设置")
end

-- 显示所有玩家数据
function ShopAdminPanel._displayAllPlayersData(allPlayersData, showNotification)
    print("👤 [用户管理] 开始显示所有玩家数据")
    print("👤 [调试] 接收到的数据类型:", type(allPlayersData))

    -- 详细的数据检查和日志
    if not allPlayersData then
        print("❌ [错误] allPlayersData 为 nil")
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Text = "❌ 数据为空\n未收到任何玩家数据"
        errorLabel.Font = Enum.Font.SourceSans
        errorLabel.TextSize = 16
        errorLabel.TextColor3 = ShopUtils.COLORS.ERROR
        errorLabel.Size = UDim2.new(1, 0, 0, 100)
        errorLabel.BackgroundTransparency = 1
        errorLabel.TextXAlignment = Enum.TextXAlignment.Center
        errorLabel.Parent = contentArea
        return
    end

    if type(allPlayersData) ~= "table" then
        print("❌ [错误] allPlayersData 不是表格类型:", type(allPlayersData))
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Text = "❌ 数据格式错误\n期望表格类型，收到:" .. type(allPlayersData)
        errorLabel.Font = Enum.Font.SourceSans
        errorLabel.TextSize = 16
        errorLabel.TextColor3 = ShopUtils.COLORS.ERROR
        errorLabel.Size = UDim2.new(1, 0, 0, 100)
        errorLabel.BackgroundTransparency = 1
        errorLabel.TextXAlignment = Enum.TextXAlignment.Center
        errorLabel.Parent = contentArea
        return
    end

    -- 统计和调试信息
    local count = 0
    for k, v in pairs(allPlayersData) do
        count = count + 1
        print("👤 [调试] 玩家", count, "- 名称:", k)
        if type(v) == "table" then
            print("  └─ 用户ID:", v.userId or "未知")
            print("  └─ 金币:", v.coins or "未知")
            print("  └─ 会员状态:", v.membership_status or "未知")
        else
            print("  └─ 数据类型错误:", type(v))
        end
    end
    print("👤 [调试] 总共找到", count, "个玩家")

    local yPos = 10

    -- 检查是否有数据
    if count == 0 then
        print("👤 [调试] 没有用户数据，显示提示")
        local noDataLabel = Instance.new("TextLabel")
        noDataLabel.Text = "😔 暂无用户数据\n\n可能的原因:\n• 数据服务未启动\n• 数据库中没有用户数据\n• 网络连接问题\n\n建议：点击\"🔧 显示测试数据\"按钮查看示例"
        noDataLabel.Font = Enum.Font.SourceSans
        noDataLabel.TextSize = 16
        noDataLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
        noDataLabel.Size = UDim2.new(1, -20, 0, 250)
        noDataLabel.Position = UDim2.new(0, 10, 0, yPos)
        noDataLabel.BackgroundTransparency = 1
        noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
        noDataLabel.TextYAlignment = Enum.TextYAlignment.Top
        noDataLabel.TextWrapped = true
        noDataLabel.Parent = contentArea

        -- 添加显示测试数据按钮
        local showTestBtn = ShopUtils.createButton("🔧 显示测试数据", ShopUtils.COLORS.ACCENT, contentArea, function()
            noDataLabel:Destroy()
            local testData = {
                [player.Name] = {
                    userId = player.UserId,
                    name = player.Name,
                    coins = 1000,
                    totalPurchases = 5,
                    totalSpent = 500,
                    totalSales = 3,
                    totalEarned = 300,
                    inventoryCount = 10,
                    membership_status = "active",
                    end_date = "2024-12-31",
                    days_remaining = 30,
                    daily_reward_coins = 100
                }
            }
            ShopAdminPanel._displayAllPlayersData(testData, showNotification)
        end)
        showTestBtn.Position = UDim2.new(0.5, -80, 0, yPos + 200)
        showTestBtn.Size = UDim2.new(0, 160, 0, 30)
        showTestBtn.TextSize = 12
        return
    end

    -- 显示加载成功的信息
    print("✅ [用户管理] 开始创建用户界面，共", count, "个用户")

    -- 在顶部显示统计信息
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Text = "📊 用户统计: 共 " .. count .. " 个用户"
    statsLabel.Font = Enum.Font.SourceSansBold
    statsLabel.TextSize = 14
    statsLabel.TextColor3 = ShopUtils.COLORS.SUCCESS
    statsLabel.Size = UDim2.new(1, -20, 0, 25)
    statsLabel.Position = UDim2.new(0, 10, 0, yPos)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = contentArea

    yPos = yPos + 35

    for playerName, data in pairs(allPlayersData) do
        print("👤 [调试] 创建玩家卡片:", playerName)

        -- 验证数据完整性
        if not data or type(data) ~= "table" then
            print("⚠️ [警告] 玩家", playerName, "的数据无效:", type(data))
            continue
        end

        -- 玩家卡片
        local playerCard = Instance.new("Frame")
        playerCard.Name = "PlayerCard_" .. playerName
        playerCard.Size = UDim2.new(1, -20, 0, 120)
        playerCard.Position = UDim2.new(0, 10, 0, yPos)
        playerCard.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
        playerCard.BorderSizePixel = 0
        playerCard.Parent = contentArea
        ShopUtils.createCorner(playerCard, 8)

        -- 玩家信息
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = "👤 " .. playerName .. " (ID: " .. data.userId .. ")"
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 16
        nameLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        nameLabel.Size = UDim2.new(0.4, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = playerCard

        -- 金币显示和修改
        local coinsLabel = Instance.new("TextLabel")
        coinsLabel.Text = "💰 " .. data.coins .. " 金币"
        coinsLabel.Font = Enum.Font.SourceSans
        coinsLabel.TextSize = 14
        coinsLabel.TextColor3 = ShopUtils.COLORS.WARNING
        coinsLabel.Size = UDim2.new(0.2, 0, 0, 20)
        coinsLabel.Position = UDim2.new(0, 10, 0, 30)
        coinsLabel.BackgroundTransparency = 1
        coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
        coinsLabel.Parent = playerCard

        -- 会员状态显示
        local membershipStatus = data.membership_status or "none"
        local isMember = membershipStatus == "active"
        local membershipLabel = Instance.new("TextLabel")
        membershipLabel.Text = isMember and "👑 会员" or "👤 普通用户"
        membershipLabel.Font = Enum.Font.SourceSansBold
        membershipLabel.TextSize = 12
        membershipLabel.TextColor3 = isMember and ShopUtils.COLORS.SUCCESS or ShopUtils.COLORS.TEXT_MUTED
        membershipLabel.Size = UDim2.new(0.15, 0, 0, 20)
        membershipLabel.Position = UDim2.new(0.25, 10, 0, 30)
        membershipLabel.BackgroundTransparency = 1
        membershipLabel.TextXAlignment = Enum.TextXAlignment.Left
        membershipLabel.Parent = playerCard

        -- 会员到期时间显示
        local expiryLabel = Instance.new("TextLabel")
        local expiryText = ""
        if isMember and data.end_date then
            expiryText = "⏰ " .. data.end_date:sub(1, 10)
        elseif isMember then
            expiryText = "⏰ 未知"
        else
            expiryText = ""
        end
        expiryLabel.Text = expiryText
        expiryLabel.Font = Enum.Font.SourceSans
        expiryLabel.TextSize = 11
        expiryLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
        expiryLabel.Size = UDim2.new(0.2, 0, 0, 20)
        expiryLabel.Position = UDim2.new(0.45, 10, 0, 30)
        expiryLabel.BackgroundTransparency = 1
        expiryLabel.TextXAlignment = Enum.TextXAlignment.Left
        expiryLabel.Parent = playerCard

        -- 金币修改输入框
        local coinsInput = Instance.new("TextBox")
        coinsInput.Text = tostring(data.coins)
        coinsInput.Font = Enum.Font.SourceSans
        coinsInput.TextSize = 12
        coinsInput.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        coinsInput.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
        coinsInput.Size = UDim2.new(0, 80, 0, 25)
        coinsInput.Position = UDim2.new(0, 10, 0, 55)
        coinsInput.PlaceholderText = "新金币数"
        coinsInput.Parent = playerCard
        ShopUtils.createCorner(coinsInput, 4)

        -- 设置金币按钮
        local setCoinsBtn = ShopUtils.createButton("设置", ShopUtils.COLORS.SUCCESS, playerCard, function()
            local newCoins = tonumber(coinsInput.Text)
            if newCoins and newCoins >= 0 and newCoins <= 999999 then
                -- 发送修改金币请求
                if ShopEvents.Admin.SetUserCoins then
                    ShopEvents.Admin.SetUserCoins:FireServer(playerName, newCoins)

                    -- 监听修改结果
                    local connection
                    connection = ShopEvents.Admin.SetUserCoins.OnClientEvent:Connect(function(success, message)
                        connection:Disconnect()

                        if success then
                            print("✅ 金币修改成功:", playerName, newCoins)
                            -- 立即更新显示
                            coinsLabel.Text = "💰 " .. newCoins .. " 金币"
                            if showNotification then
                                showNotification("✅ " .. message, true)
                            end

                            -- 刷新用户列表以确保数据同步
                            task.wait(0.5)
                            ShopAdminPanel._refreshPlayerData()

                            -- 再次刷新以确保数据完全同步
                            task.wait(1.0)
                            ShopAdminPanel._refreshPlayerData()
                        else
                            print("❌ 金币修改失败:", message)
                            if showNotification then
                                showNotification("❌ " .. message, false)
                            end
                        end
                    end)
                else
                    print("❌ SetUserCoins 事件不存在")
                end
            else
                if showNotification then
                    showNotification("❌ 金币数量必须在 0-999999 之间", false)
                end
            end
        end)
        setCoinsBtn.Position = UDim2.new(0, 100, 0, 55)
        setCoinsBtn.Size = UDim2.new(0, 60, 0, 25)
        setCoinsBtn.TextSize = 12

        -- 查看记录按钮
        local viewRecordsBtn = ShopUtils.createButton("查看记录", ShopUtils.COLORS.ACCENT, playerCard, function()
            print("🔧 [统一管理面板] 查看用户记录:", playerName)
            currentViewingPlayer = playerName
            ShopAdminPanel._addTab("records")
            ShopAdminPanel.switchTab("records")
        end)
        viewRecordsBtn.Position = UDim2.new(0, 170, 0, 55)
        viewRecordsBtn.Size = UDim2.new(0, 80, 0, 25)
        viewRecordsBtn.TextSize = 12

        -- 管理会员按钮
        local manageMembershipBtn = ShopUtils.createButton("管理会员", ShopUtils.COLORS.WARNING, playerCard, function()
            print("🔧 [统一管理面板] 管理用户会员:", playerName)
            currentViewingPlayer = playerName
            ShopAdminPanel._addTab("membership")
            ShopAdminPanel.switchTab("membership")
        end)
        manageMembershipBtn.Position = UDim2.new(0, 260, 0, 55)
        manageMembershipBtn.Size = UDim2.new(0, 80, 0, 25)
        manageMembershipBtn.TextSize = 12

        -- 统计信息
        local statsText = string.format(
            "📊 购买: %d次 | 卖出: %d次 | 消费: %d金币 | 收入: %d金币 | 库存: %d件",
            data.totalPurchases or 0, data.totalSales or 0, data.totalSpent or 0, data.totalEarned or 0, data.inventoryCount or 0
        )
        local statsLabel = Instance.new("TextLabel")
        statsLabel.Text = statsText
        statsLabel.Font = Enum.Font.SourceSans
        statsLabel.TextSize = 12
        statsLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
        statsLabel.Size = UDim2.new(1, -20, 0, 30)
        statsLabel.Position = UDim2.new(0, 10, 0, 85)
        statsLabel.BackgroundTransparency = 1
        statsLabel.TextXAlignment = Enum.TextXAlignment.Left
        statsLabel.TextWrapped = true
        statsLabel.Parent = playerCard

        yPos = yPos + 130
    end

    contentArea.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

-- 显示交易记录面板
function ShopAdminPanel._showRecordsPanel(showNotification)
    print("📊 [交易记录] 加载交易记录面板，查看用户:", currentViewingPlayer)

    if not currentViewingPlayer then
        local noPlayerLabel = Instance.new("TextLabel")
        noPlayerLabel.Text = "❌ 请先选择要查看的用户"
        noPlayerLabel.Font = Enum.Font.SourceSans
        noPlayerLabel.TextSize = 16
        noPlayerLabel.TextColor3 = ShopUtils.COLORS.ERROR
        noPlayerLabel.Size = UDim2.new(1, 0, 0, 100)
        noPlayerLabel.BackgroundTransparency = 1
        noPlayerLabel.TextXAlignment = Enum.TextXAlignment.Center
        noPlayerLabel.Parent = contentArea
        return
    end

    -- 显示当前查看的用户信息
    local userInfoLabel = Instance.new("TextLabel")
    userInfoLabel.Text = "📊 正在查看 " .. currentViewingPlayer .. " 的交易记录"
    userInfoLabel.Font = Enum.Font.SourceSansBold
    userInfoLabel.TextSize = 16
    userInfoLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    userInfoLabel.Size = UDim2.new(1, 0, 0, 30)
    userInfoLabel.BackgroundTransparency = 1
    userInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
    userInfoLabel.Parent = contentArea

    -- 返回用户管理按钮
    local backBtn = ShopUtils.createButton("← 返回用户管理", ShopUtils.COLORS.ACCENT, contentArea, function()
        ShopAdminPanel._resetToDefaultTabs()
        ShopAdminPanel.switchTab("users")
    end)
    backBtn.Position = UDim2.new(0, 10, 0, 40)
    backBtn.Size = UDim2.new(0, 120, 0, 30)
    backBtn.TextSize = 12

    -- 显示加载提示
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Text = "📡 正在加载 " .. currentViewingPlayer .. " 的交易记录..."
    loadingLabel.Font = Enum.Font.SourceSans
    loadingLabel.TextSize = 14
    loadingLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
    loadingLabel.Size = UDim2.new(1, 0, 0, 50)
    loadingLabel.Position = UDim2.new(0, 0, 0, 80)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
    loadingLabel.Parent = contentArea

    -- 请求特定用户的历史记录
    if ShopEvents.Admin.GetUserHistory then
        ShopEvents.Admin.GetUserHistory:FireServer(currentViewingPlayer)

        -- 监听服务器响应
        local connection
        connection = ShopEvents.Admin.GetUserHistory.OnClientEvent:Connect(function(success, message, data)
            connection:Disconnect()
            loadingLabel:Destroy()

            if not success then
                local errorLabel = Instance.new("TextLabel")
                errorLabel.Text = "❌ " .. (message or "获取用户交易记录失败")
                errorLabel.Font = Enum.Font.SourceSans
                errorLabel.TextSize = 14
                errorLabel.TextColor3 = ShopUtils.COLORS.ERROR
                errorLabel.Size = UDim2.new(1, 0, 0, 50)
                errorLabel.Position = UDim2.new(0, 0, 0, 80)
                errorLabel.BackgroundTransparency = 1
                errorLabel.TextXAlignment = Enum.TextXAlignment.Center
                errorLabel.Parent = contentArea
            elseif data and data.transactions and #data.transactions > 0 then
                print("✅ [交易记录] 成功获取到", #data.transactions, "条交易记录")
                ShopAdminPanel._displayUserRecords(data.transactions)
            else
                local noRecordsLabel = Instance.new("TextLabel")
                noRecordsLabel.Text = "📝 " .. currentViewingPlayer .. " 暂无交易记录"
                noRecordsLabel.Font = Enum.Font.SourceSans
                noRecordsLabel.TextSize = 14
                noRecordsLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
                noRecordsLabel.Size = UDim2.new(1, 0, 0, 50)
                noRecordsLabel.Position = UDim2.new(0, 0, 0, 80)
                noRecordsLabel.BackgroundTransparency = 1
                noRecordsLabel.TextXAlignment = Enum.TextXAlignment.Center
                noRecordsLabel.Parent = contentArea
            end
        end)
    else
        loadingLabel:Destroy()
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Text = "❌ 获取用户记录功能不可用"
        errorLabel.Font = Enum.Font.SourceSans
        errorLabel.TextSize = 14
        errorLabel.TextColor3 = ShopUtils.COLORS.ERROR
        errorLabel.Size = UDim2.new(1, 0, 0, 50)
        errorLabel.Position = UDim2.new(0, 0, 0, 80)
        errorLabel.BackgroundTransparency = 1
        errorLabel.TextXAlignment = Enum.TextXAlignment.Center
        errorLabel.Parent = contentArea
    end
end

-- 显示用户交易记录
function ShopAdminPanel._displayUserRecords(records)
    print("📊 [交易记录] 显示用户记录，共", #records, "条")

    local yPos = 140  -- 从返回按钮下方开始

    for i, record in ipairs(records) do
        local recordCard = Instance.new("Frame")
        recordCard.Name = "Record" .. i
        recordCard.Size = UDim2.new(1, -20, 0, 80)
        recordCard.Position = UDim2.new(0, 10, 0, yPos)
        recordCard.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
        recordCard.BorderSizePixel = 0
        recordCard.Parent = contentArea
        ShopUtils.createCorner(recordCard, 8)

        -- 时间戳
        local timeLabel = Instance.new("TextLabel")

        -- 调试时间戳问题
        local timestamp = record.timestamp or record.createdAt or record.transactionDate
        print("📊 [调试] 交易记录时间戳:",
            "timestamp=", record.timestamp,
            "createdAt=", record.createdAt,
            "transactionDate=", record.transactionDate,
            "使用=", timestamp)

        timeLabel.Text = ShopUtils.formatTimestamp(timestamp)
        timeLabel.Font = Enum.Font.SourceSans
        timeLabel.TextSize = 12
        timeLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
        timeLabel.Size = UDim2.new(0, 150, 0, 20)
        timeLabel.Position = UDim2.new(0, 10, 0, 5)
        timeLabel.BackgroundTransparency = 1
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.Parent = recordCard

        -- 交易类型和物品
        local actionLabel = Instance.new("TextLabel")
        local actionText = ""
        if record.type == "buy" or record.action == "buy" then
            actionText = "🛒 购买 " .. (record.itemName or record.item_name or "未知物品") .. " x" .. (record.quantity or 1)
        elseif record.type == "sell" or record.action == "sell" then
            actionText = "💰 卖出 " .. (record.itemName or record.item_name or "未知物品") .. " x" .. (record.quantity or 1)
        elseif record.type == "admin" or record.action == "admin_edit" then
            actionText = "⚙️ 管理员操作 x" .. (record.quantity or 1)
        elseif record.type == "daily_reward" then
            actionText = "🎁 每日奖励 x" .. (record.quantity or 1)
        elseif record.type == "membership_purchase" then
            actionText = "💎 购买会员 " .. (record.itemName or record.item_name or "未知会员") .. " x" .. (record.quantity or 1)
        end
        actionLabel.Text = actionText
        actionLabel.Font = Enum.Font.SourceSansBold
        actionLabel.TextSize = 16
        actionLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        actionLabel.Size = UDim2.new(1, -20, 0, 25)
        actionLabel.Position = UDim2.new(0, 10, 0, 25)
        actionLabel.BackgroundTransparency = 1
        actionLabel.TextXAlignment = Enum.TextXAlignment.Left
        actionLabel.Parent = recordCard

        -- 金额
        local amountLabel = Instance.new("TextLabel")
        local amountText = ""
        local amountColor = ShopUtils.COLORS.TEXT_SECONDARY
        if record.type == "buy" or record.action == "buy" then
            amountText = "-" .. (record.totalAmount or record.totalCost or record.total_amount or 0) .. " 金币"
            amountColor = ShopUtils.COLORS.ERROR
        elseif record.type == "sell" or record.action == "sell" then
            amountText = "+" .. (record.totalAmount or record.totalEarned or record.total_amount or 0) .. " 金币"
            amountColor = ShopUtils.COLORS.SUCCESS
        elseif record.type == "admin" or record.action == "admin_edit" then
            amountText = (record.totalAmount or record.total_amount or 0) .. " 金币"
            amountColor = ShopUtils.COLORS.TEXT_PRIMARY
        elseif record.type == "daily_reward" then
            amountText = "+" .. (record.totalAmount or record.total_amount or 0) .. " 金币"
            amountColor = ShopUtils.COLORS.SUCCESS
        elseif record.type == "membership_purchase" then
            amountText = "-" .. (record.totalAmount or record.totalCost or record.total_amount or 0) .. " 金币"
            amountColor = ShopUtils.COLORS.ERROR
        end
        amountLabel.Text = amountText
        amountLabel.Font = Enum.Font.SourceSansBold
        amountLabel.TextSize = 14
        amountLabel.TextColor3 = amountColor
        amountLabel.Size = UDim2.new(0, 120, 0, 20)
        amountLabel.Position = UDim2.new(1, -130, 0, 30)
        amountLabel.BackgroundTransparency = 1
        amountLabel.TextXAlignment = Enum.TextXAlignment.Right
        amountLabel.Parent = recordCard

        yPos = yPos + 90
    end

    contentArea.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

-- 显示会员管理面板
function ShopAdminPanel._showMembershipPanel(showNotification)
    print("👥 [会员管理] 加载会员管理面板，查看用户:", currentViewingPlayer)

    if not currentViewingPlayer then
        local noPlayerLabel = Instance.new("TextLabel")
        noPlayerLabel.Text = "❌ 请先选择要管理的用户"
        noPlayerLabel.Font = Enum.Font.SourceSans
        noPlayerLabel.TextSize = 16
        noPlayerLabel.TextColor3 = ShopUtils.COLORS.ERROR
        noPlayerLabel.Size = UDim2.new(1, 0, 0, 100)
        noPlayerLabel.BackgroundTransparency = 1
        noPlayerLabel.TextXAlignment = Enum.TextXAlignment.Center
        noPlayerLabel.Parent = contentArea
        return
    end

    -- 显示当前管理的用户信息
    local userInfoLabel = Instance.new("TextLabel")
    userInfoLabel.Text = "👥 正在管理 " .. currentViewingPlayer .. " 的会员状态"
    userInfoLabel.Font = Enum.Font.SourceSansBold
    userInfoLabel.TextSize = 16
    userInfoLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    userInfoLabel.Size = UDim2.new(1, 0, 0, 30)
    userInfoLabel.BackgroundTransparency = 1
    userInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
    userInfoLabel.Parent = contentArea

    -- 返回用户管理按钮
    local backBtn = ShopUtils.createButton("← 返回用户管理", ShopUtils.COLORS.ACCENT, contentArea, function()
        ShopAdminPanel._resetToDefaultTabs()
        ShopAdminPanel.switchTab("users")
    end)
    backBtn.Position = UDim2.new(0, 10, 0, 40)
    backBtn.Size = UDim2.new(0, 120, 0, 30)
    backBtn.TextSize = 12

    -- 显示加载提示
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Text = "📡 正在加载 " .. currentViewingPlayer .. " 的会员信息..."
    loadingLabel.Font = Enum.Font.SourceSans
    loadingLabel.TextSize = 14
    loadingLabel.TextColor3 = ShopUtils.COLORS.TEXT_MUTED
    loadingLabel.Size = UDim2.new(1, 0, 0, 50)
    loadingLabel.Position = UDim2.new(0, 0, 0, 80)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
    loadingLabel.Parent = contentArea

    -- 从服务器获取特定用户的会员状态
    local connection
    connection = ShopEvents.Admin.GetAllUsersWithMembership.OnClientEvent:Connect(function(success, response)
        connection:Disconnect()
        loadingLabel:Destroy()

        if success and response and response.success then
            local users = response.data.users or {}
            local targetUser = nil

            -- 查找目标用户
            for _, user in pairs(users) do
                if user.username == currentViewingPlayer then
                    targetUser = user
                    break
                end
            end

            if targetUser then
                ShopAdminPanel._displayUserMembership(targetUser)
            else
                local errorLabel = Instance.new("TextLabel")
                errorLabel.Text = "❌ 未找到用户 " .. currentViewingPlayer .. " 的会员信息"
                errorLabel.Font = Enum.Font.SourceSans
                errorLabel.TextSize = 14
                errorLabel.TextColor3 = ShopUtils.COLORS.ERROR
                errorLabel.Size = UDim2.new(1, 0, 0, 50)
                errorLabel.Position = UDim2.new(0, 0, 0, 80)
                errorLabel.BackgroundTransparency = 1
                errorLabel.TextXAlignment = Enum.TextXAlignment.Center
                errorLabel.Parent = contentArea
            end
        else
            local errorMsg = response and response.message or "获取会员数据失败"
            print("❌ 用户会员数据加载失败:", errorMsg)
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Text = "❌ " .. errorMsg
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.TextColor3 = ShopUtils.COLORS.ERROR
            errorLabel.Size = UDim2.new(1, 0, 0, 50)
            errorLabel.Position = UDim2.new(0, 0, 0, 80)
            errorLabel.BackgroundTransparency = 1
            errorLabel.TextXAlignment = Enum.TextXAlignment.Center
            errorLabel.Parent = contentArea
        end
    end)

    -- 发送请求到服务器
    if ShopEvents.Admin.GetAllUsersWithMembership then
        ShopEvents.Admin.GetAllUsersWithMembership:FireServer(1, 50, "all")
    else
        loadingLabel:Destroy()
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Text = "❌ 会员管理功能不可用"
        errorLabel.Font = Enum.Font.SourceSans
        errorLabel.TextSize = 14
        errorLabel.TextColor3 = ShopUtils.COLORS.ERROR
        errorLabel.Size = UDim2.new(1, 0, 0, 50)
        errorLabel.Position = UDim2.new(0, 0, 0, 80)
        errorLabel.BackgroundTransparency = 1
        errorLabel.TextXAlignment = Enum.TextXAlignment.Center
        errorLabel.Parent = contentArea
    end
end

-- 显示单个用户的会员管理信息
function ShopAdminPanel._displayUserMembership(user)
    print("👥 [会员管理] 显示用户会员信息:", user.username)

    local membershipStatus = user.membership_status or "none"
    local isMember = membershipStatus == "active"
    local yPos = 140  -- 从返回按钮下方开始

    -- 用户信息卡片
    local userCard = Instance.new("Frame")
    userCard.Name = "UserMembershipCard"
    userCard.Size = UDim2.new(1, -20, 0, 200)
    userCard.Position = UDim2.new(0, 10, 0, yPos)
    userCard.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    userCard.BorderSizePixel = 0
    userCard.Parent = contentArea
    ShopUtils.createCorner(userCard, 8)

    -- 用户名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = "👤 " .. user.username .. " (ID: " .. user.user_id .. ")"
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    nameLabel.Size = UDim2.new(1, -20, 0, 25)
    nameLabel.Position = UDim2.new(0, 10, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = userCard

    -- 金币数量
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Text = "💰 " .. (user.coins or 0) .. " 金币"
    coinsLabel.Font = Enum.Font.SourceSans
    coinsLabel.TextSize = 14
    coinsLabel.TextColor3 = ShopUtils.COLORS.WARNING
    coinsLabel.Size = UDim2.new(0.3, 0, 0, 20)
    coinsLabel.Position = UDim2.new(0, 10, 0, 40)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinsLabel.Parent = userCard

    -- 会员状态
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text = isMember and "👑 活跃会员" or "👤 普通用户"
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.TextSize = 14
    statusLabel.TextColor3 = isMember and ShopUtils.COLORS.SUCCESS or ShopUtils.COLORS.TEXT_MUTED
    statusLabel.Size = UDim2.new(0.3, 0, 0, 20)
    statusLabel.Position = UDim2.new(0.35, 10, 0, 40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = userCard

    -- 剩余天数
    local daysRemaining = tonumber(user.days_remaining) or 0
    local daysLabel = Instance.new("TextLabel")
    daysLabel.Text = "⏰ 剩余 " .. daysRemaining .. " 天"
    daysLabel.Font = Enum.Font.SourceSans
    daysLabel.TextSize = 12
    daysLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
    daysLabel.Size = UDim2.new(0.3, 0, 0, 20)
    daysLabel.Position = UDim2.new(0.7, 10, 0, 40)
    daysLabel.BackgroundTransparency = 1
    daysLabel.TextXAlignment = Enum.TextXAlignment.Left
    daysLabel.Parent = userCard

    -- 会员开始时间
    if user.start_date then
        local startLabel = Instance.new("TextLabel")
        startLabel.Text = "📅 开始时间: " .. user.start_date:sub(1, 10)
        startLabel.Font = Enum.Font.SourceSans
        startLabel.TextSize = 12
        startLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
        startLabel.Size = UDim2.new(0.4, 0, 0, 20)
        startLabel.Position = UDim2.new(0, 10, 0, 70)
        startLabel.BackgroundTransparency = 1
        startLabel.TextXAlignment = Enum.TextXAlignment.Left
        startLabel.Parent = userCard
    end

    -- 会员结束时间
    if user.end_date then
        local endLabel = Instance.new("TextLabel")
        endLabel.Text = "📅 结束时间: " .. user.end_date:sub(1, 10)
        endLabel.Font = Enum.Font.SourceSans
        endLabel.TextSize = 12
        endLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
        endLabel.Size = UDim2.new(0.4, 0, 0, 20)
        endLabel.Position = UDim2.new(0.5, 10, 0, 70)
        endLabel.BackgroundTransparency = 1
        endLabel.TextXAlignment = Enum.TextXAlignment.Left
        endLabel.Parent = userCard
    end

    -- 每日奖励
    local dailyReward = tonumber(user.daily_reward_coins) or 100
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Text = "🎁 每日奖励: " .. dailyReward .. " 金币"
    rewardLabel.Font = Enum.Font.SourceSans
    rewardLabel.TextSize = 12
    rewardLabel.TextColor3 = ShopUtils.COLORS.SUCCESS
    rewardLabel.Size = UDim2.new(0.4, 0, 0, 20)
    rewardLabel.Position = UDim2.new(0, 10, 0, 100)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
    rewardLabel.Parent = userCard

    yPos = yPos + 220

    -- 控制面板
    local controlCard = Instance.new("Frame")
    controlCard.Name = "ControlCard"
    controlCard.Size = UDim2.new(1, -20, 0, 150)
    controlCard.Position = UDim2.new(0, 10, 0, yPos)
    controlCard.BackgroundColor3 = ShopUtils.COLORS.PRIMARY
    controlCard.BorderSizePixel = 0
    controlCard.Parent = contentArea
    ShopUtils.createCorner(controlCard, 8)

    -- 控制标题
    local controlTitle = Instance.new("TextLabel")
    controlTitle.Text = "⚙️ 会员控制"
    controlTitle.Font = Enum.Font.SourceSansBold
    controlTitle.TextSize = 16
    controlTitle.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    controlTitle.Size = UDim2.new(1, -20, 0, 25)
    controlTitle.Position = UDim2.new(0, 10, 0, 10)
    controlTitle.BackgroundTransparency = 1
    controlTitle.TextXAlignment = Enum.TextXAlignment.Left
    controlTitle.Parent = controlCard

    -- 切换会员状态按钮
    local toggleBtn = ShopUtils.createButton(
        isMember and "🔴 停用会员" or "🟢 激活会员",
        isMember and ShopUtils.COLORS.ERROR or ShopUtils.COLORS.SUCCESS,
        controlCard,
        function()
            ShopAdminPanel._toggleUserMembership(user)
        end
    )
    toggleBtn.Position = UDim2.new(0, 10, 0, 40)
    toggleBtn.Size = UDim2.new(0, 120, 0, 30)
    toggleBtn.TextSize = 12

    -- 设置到期时间
    local daysInput = Instance.new("TextBox")
    daysInput.Text = tostring(daysRemaining)
    daysInput.Font = Enum.Font.SourceSans
    daysInput.TextSize = 12
    daysInput.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
    daysInput.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
    daysInput.Size = UDim2.new(0, 80, 0, 25)
    daysInput.Position = UDim2.new(0, 150, 0, 40)
    daysInput.PlaceholderText = "天数"
    daysInput.Parent = controlCard
    ShopUtils.createCorner(daysInput, 4)

    local setDaysBtn = ShopUtils.createButton("设置天数", ShopUtils.COLORS.ACCENT, controlCard, function()
        local newDays = tonumber(daysInput.Text)
        if newDays and newDays >= 0 and newDays <= 365 then
            ShopAdminPanel._setMembershipDays(user, newDays)
        else
            print("❌ 天数必须在 0-365 之间")
        end
    end)
    setDaysBtn.Position = UDim2.new(0, 240, 0, 40)
    setDaysBtn.Size = UDim2.new(0, 80, 0, 25)
    setDaysBtn.TextSize = 12

    contentArea.CanvasSize = UDim2.new(0, 0, 0, yPos + 170)
end

-- 显示会员管理数据
function ShopAdminPanel._displayMembershipData()
    print("👥 [会员管理] 显示会员数据")

    local yPos = 10

    for playerName, membershipInfo in pairs(membershipData) do
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = playerName .. "_Entry"
        entryFrame.Size = UDim2.new(1, -20, 0, 100)
        entryFrame.Position = UDim2.new(0, 10, 0, yPos)
        entryFrame.BackgroundColor3 = ShopUtils.COLORS.SECONDARY
        entryFrame.BorderSizePixel = 0
        entryFrame.Parent = contentArea
        ShopUtils.createCorner(entryFrame, 8)

        -- 玩家名称
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = "👤 " .. playerName
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 16
        nameLabel.TextColor3 = ShopUtils.COLORS.TEXT_PRIMARY
        nameLabel.Size = UDim2.new(0.2, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = entryFrame

        -- 金币数量
        local coinsLabel = Instance.new("TextLabel")
        coinsLabel.Text = "💰 " .. membershipInfo.coins .. " 金币"
        coinsLabel.Font = Enum.Font.SourceSans
        coinsLabel.TextSize = 12
        coinsLabel.TextColor3 = ShopUtils.COLORS.WARNING
        coinsLabel.Size = UDim2.new(0.15, 0, 0, 20)
        coinsLabel.Position = UDim2.new(0, 10, 0, 30)
        coinsLabel.BackgroundTransparency = 1
        coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
        coinsLabel.Parent = entryFrame

        -- 会员状态
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Text = membershipInfo.isMember and "✓ 会员" or "普通用户"
        statusLabel.Font = Enum.Font.SourceSansBold
        statusLabel.TextSize = 12
        statusLabel.TextColor3 = membershipInfo.isMember and ShopUtils.COLORS.SUCCESS or ShopUtils.COLORS.TEXT_MUTED
        statusLabel.Size = UDim2.new(0.12, 0, 0, 20)
        statusLabel.Position = UDim2.new(0.2, 10, 0, 10)
        statusLabel.BackgroundTransparency = 1
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.Parent = entryFrame

        -- 剩余天数
        local daysLabel = Instance.new("TextLabel")
        local daysText = "剩余" .. membershipInfo.daysRemaining .. "天"
        daysLabel.Text = daysText
        daysLabel.Font = Enum.Font.SourceSans
        daysLabel.TextSize = 12
        daysLabel.TextColor3 = ShopUtils.COLORS.TEXT_SECONDARY
        daysLabel.Size = UDim2.new(0.12, 0, 0, 20)
        daysLabel.Position = UDim2.new(0.2, 10, 0, 30)
        daysLabel.BackgroundTransparency = 1
        daysLabel.TextXAlignment = Enum.TextXAlignment.Left
        daysLabel.Parent = entryFrame

        -- 操作按钮
        local quickButton = ShopUtils.createButton(
            membershipInfo.isMember and "🔴 停用" or "🟢 激活",
            membershipInfo.isMember and ShopUtils.COLORS.ERROR or ShopUtils.COLORS.SUCCESS,
            entryFrame,
            function()
                ShopAdminPanel._toggleUserMembershipByName(playerName, membershipInfo)
            end
        )
        quickButton.Position = UDim2.new(0.8, 0, 0, 10)
        quickButton.Size = UDim2.new(0, 80, 0, 25)
        quickButton.TextSize = 12

        local manageButton = ShopUtils.createButton("⚙️ 管理", ShopUtils.COLORS.ACCENT, entryFrame, function()
            ShopAdminPanel._showPlayerMembership(playerName, membershipInfo)
        end)
        manageButton.Position = UDim2.new(0.8, 0, 0, 40)
        manageButton.Size = UDim2.new(0, 80, 0, 25)
        manageButton.TextSize = 12

        yPos = yPos + 110
    end

    contentArea.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

-- 通过用户名切换会员状态
function ShopAdminPanel._toggleUserMembershipByName(playerName, membershipInfo)
    print("🔄 [会员管理] 通过用户名切换会员状态:", playerName)

    local isMember = membershipInfo.isMember
    local action = isMember and "deactivate" or "activate"

    local requestData = {
        playerName = playerName,
        action = action,
        days = action == "activate" and 30 or nil,
        dailyReward = membershipInfo.dailyReward or 100
    }

    if ShopEvents.Admin.ManageUserMembership then
        ShopEvents.Admin.ManageUserMembership:FireServer(requestData)

        local connection
        connection = ShopEvents.Admin.ManageUserMembership.OnClientEvent:Connect(function(success, response)
            connection:Disconnect()

            if success and response and response.success then
                print("✅", playerName, "会员状态切换成功")
                -- 重新获取用户数据并刷新界面
                if ShopEvents.Admin.GetUserInfo then
                    ShopEvents.Admin.GetUserInfo:FireServer(playerName)
                end
                -- 刷新用户列表以更新所有相关数据
                ShopAdminPanel._refreshPlayerData()
            else
                local errorMsg = response and (response.message or response.error) or "操作失败"
                print("❌ 会员状态切换失败:", errorMsg)
                ShopUtils.showNotification("❌ " .. errorMsg, false, currentScreenGui)
            end
        end)
    else
        print("❌ ManageUserMembership 事件不存在")
    end
end

-- 切换用户会员状态
function ShopAdminPanel._toggleUserMembership(user)
    print("🔄 [会员管理] 切换用户会员状态:", user.username)

    local membershipStatus = user.membership_status or "none"
    local isMember = membershipStatus == "active"
    local action = isMember and "deactivate" or "activate"

    local requestData = {
        userId = tostring(user.user_id),
        action = action,
        days = action == "activate" and 30 or nil,
        dailyReward = tonumber(user.daily_reward_coins) or 100
    }

    if ShopEvents.Admin.ManageUserMembership then
        ShopEvents.Admin.ManageUserMembership:FireServer(requestData)

        local connection
        connection = ShopEvents.Admin.ManageUserMembership.OnClientEvent:Connect(function(success, response)
            connection:Disconnect()

            if success and response and response.success then
                print("✅", user.username, "会员状态切换成功")
                ShopUtils.showNotification("✅ " .. user.username .. " 会员状态切换成功", true, currentScreenGui)

                -- 异步刷新面板数据，避免阻塞界面
                spawn(function()
                    -- 重新获取用户数据并刷新面板
                    if currentViewingPlayer then
                        if ShopEvents.Admin.GetUserInfo then
                            ShopEvents.Admin.GetUserInfo:FireServer(currentViewingPlayer)
                        end
                        -- 等待数据更新然后刷新面板
                        task.wait(0.3)
                        ShopAdminPanel._showMembershipPanel()
                    end
                end)
            else
                local errorMsg = response and response.message or "操作失败"
                print("❌ 会员状态切换失败:", errorMsg)
                ShopUtils.showNotification("❌ " .. errorMsg, false, currentScreenGui)
            end
        end)
    else
        print("❌ ManageUserMembership 事件不存在")
    end
end

-- 设置会员天数
function ShopAdminPanel._setMembershipDays(user, days)
    print("📅 [会员管理] 设置用户会员天数:", user.username, days)

    local requestData = {
        userId = tostring(user.user_id),
        action = "set_days",
        days = days,
        dailyReward = tonumber(user.daily_reward_coins) or 100
    }

    if ShopEvents.Admin.ManageUserMembership then
        ShopEvents.Admin.ManageUserMembership:FireServer(requestData)

        local connection
        connection = ShopEvents.Admin.ManageUserMembership.OnClientEvent:Connect(function(success, response)
            connection:Disconnect()

            if success and response and response.success then
                local successMsg = response.message or "会员天数设置成功"
                print("✅", user.username, successMsg)
                ShopUtils.showNotification("✅ " .. user.username .. " " .. successMsg, true, currentScreenGui)

                -- 异步刷新面板数据，避免阻塞界面
                spawn(function()
                    -- 重新获取用户数据并刷新面板
                    if currentViewingPlayer then
                        if ShopEvents.Admin.GetUserInfo then
                            ShopEvents.Admin.GetUserInfo:FireServer(currentViewingPlayer)
                        end
                        -- 等待数据更新然后刷新面板
                        task.wait(0.3)
                        ShopAdminPanel._showMembershipPanel()
                    end
                end)
            else
                local errorMsg = response and response.message or "操作失败"
                print("❌ 会员天数设置失败:", errorMsg)
                ShopUtils.showNotification("❌ " .. errorMsg, false, currentScreenGui)
            end
        end)
    else
        print("❌ ManageUserMembership 事件不存在")
    end
end

-- 设置每日奖励
function ShopAdminPanel._setDailyReward(user, reward)
    print("🎁 [会员管理] 设置用户每日奖励:", user.username, reward)

    local requestData = {
        userId = tostring(user.user_id),
        action = "set_reward",
        days = tonumber(user.days_remaining) or 0,
        dailyReward = reward
    }

    if ShopEvents.Admin.ManageUserMembership then
        ShopEvents.Admin.ManageUserMembership:FireServer(requestData)

        local connection
        connection = ShopEvents.Admin.ManageUserMembership.OnClientEvent:Connect(function(success, response)
            connection:Disconnect()

            if success and response and response.success then
                print("✅", user.username, "每日奖励设置成功")
                -- 重新获取用户数据并刷新面板
                if currentViewingPlayer then
                    if ShopEvents.Admin.GetUserInfo then
                        ShopEvents.Admin.GetUserInfo:FireServer(currentViewingPlayer)
                    end
                    -- 稍等片刻让数据更新，然后刷新面板
                    task.wait(0.5)
                    ShopAdminPanel._showMembershipPanel()
                end
            else
                local errorMsg = response and response.message or "操作失败"
                print("❌ 每日奖励设置失败:", errorMsg)
            end
        end)
    else
        print("❌ ManageUserMembership 事件不存在")
    end
end

-- 刷新玩家数据
function ShopAdminPanel._refreshPlayerData()
    print("🔄 [管理面板] 刷新玩家数据")

    if currentTab == "players" then
        -- 重新获取用户列表
        if ShopEvents.Admin.GetAllUsers then
            ShopEvents.Admin.GetAllUsers:FireServer()
        end
    elseif currentTab == "membership" then
        -- 重新获取会员数据
        ShopAdminPanel._showMembershipPanel()
    end
end

return ShopAdminPanel
