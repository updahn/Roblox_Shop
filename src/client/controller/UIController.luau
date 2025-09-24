-- UI控制器
-- 管理UI状态和逻辑，分离数据处理

local UIController = {}

-- UI状态管理
local uiState = {
    shopVisible = false,
    tutorialVisible = false,
    adminPanelVisible = false,
    droneUIVisible = false
}

-- 内部事件系统
local uiEvents = {
    ShopVisibilityChanged = Instance.new("BindableEvent"),
    TutorialVisibilityChanged = Instance.new("BindableEvent"),
    AdminPanelVisibilityChanged = Instance.new("BindableEvent"),
    DroneUIVisibilityChanged = Instance.new("BindableEvent"),
    UIInteraction = Instance.new("BindableEvent")
}

-- 导出事件
UIController.Events = {
    ShopVisibilityChanged = uiEvents.ShopVisibilityChanged.Event,
    TutorialVisibilityChanged = uiEvents.TutorialVisibilityChanged.Event,
    AdminPanelVisibilityChanged = uiEvents.AdminPanelVisibilityChanged.Event,
    DroneUIVisibilityChanged = uiEvents.DroneUIVisibilityChanged.Event,
    UIInteraction = uiEvents.UIInteraction.Event
}

-- 商店UI控制
function UIController.setShopVisible(visible)
    if uiState.shopVisible ~= visible then
        uiState.shopVisible = visible
        uiEvents.ShopVisibilityChanged:Fire(visible)
        print("🏪 [UIController] 商店UI:", visible and "显示" or "隐藏")
    end
end

function UIController.toggleShop()
    UIController.setShopVisible(not uiState.shopVisible)
end

function UIController.isShopVisible()
    return uiState.shopVisible
end

-- 教程UI控制
function UIController.setTutorialVisible(visible)
    if uiState.tutorialVisible ~= visible then
        uiState.tutorialVisible = visible
        uiEvents.TutorialVisibilityChanged:Fire(visible)
        print("📖 [UIController] 教程UI:", visible and "显示" or "隐藏")
    end
end

function UIController.toggleTutorial()
    UIController.setTutorialVisible(not uiState.tutorialVisible)
end

function UIController.isTutorialVisible()
    return uiState.tutorialVisible
end

-- 管理员面板控制
function UIController.setAdminPanelVisible(visible)
    if uiState.adminPanelVisible ~= visible then
        uiState.adminPanelVisible = visible
        uiEvents.AdminPanelVisibilityChanged:Fire(visible)
        print("👑 [UIController] 管理员面板:", visible and "显示" or "隐藏")
    end
end

function UIController.toggleAdminPanel()
    UIController.setAdminPanelVisible(not uiState.adminPanelVisible)
end

function UIController.isAdminPanelVisible()
    return uiState.adminPanelVisible
end

-- 无人机UI控制
function UIController.setDroneUIVisible(visible)
    if uiState.droneUIVisible ~= visible then
        uiState.droneUIVisible = visible
        uiEvents.DroneUIVisibilityChanged:Fire(visible)
        print("🤖 [UIController] 无人机UI:", visible and "显示" or "隐藏")
    end
end

function UIController.toggleDroneUI()
    UIController.setDroneUIVisible(not uiState.droneUIVisible)
end

function UIController.isDroneUIVisible()
    return uiState.droneUIVisible
end

-- 关闭所有UI
function UIController.closeAllUI()
    UIController.setShopVisible(false)
    UIController.setTutorialVisible(false)
    UIController.setAdminPanelVisible(false)
    UIController.setDroneUIVisible(false)
    print("❌ [UIController] 所有UI已关闭")
end

-- UI交互事件触发
function UIController.fireInteractionEvent(eventType, data)
    uiEvents.UIInteraction:Fire({
        type = eventType,
        data = data,
        timestamp = tick()
    })
end

-- 预定义的UI交互类型
UIController.InteractionTypes = {
    BUY_ITEM = "buy_item",
    SELL_ITEM = "sell_item",
    SPAWN_DRONE = "spawn_drone",
    RECALL_DRONE = "recall_drone",
    SWITCH_DRONE_MODE = "switch_drone_mode",
    ADMIN_ACTION = "admin_action",
    REFRESH_DATA = "refresh_data"
}

-- 触发购买物品事件
function UIController.triggerBuyItem(itemId, quantity)
    UIController.fireInteractionEvent(UIController.InteractionTypes.BUY_ITEM, {
        itemId = itemId,
        quantity = quantity
    })
end

-- 触发出售物品事件
function UIController.triggerSellItem(itemId, quantity)
    UIController.fireInteractionEvent(UIController.InteractionTypes.SELL_ITEM, {
        itemId = itemId,
        quantity = quantity
    })
end

-- 触发无人机相关事件
function UIController.triggerDroneAction(action, data)
    local actionType = nil
    if action == "spawn" then
        actionType = UIController.InteractionTypes.SPAWN_DRONE
    elseif action == "recall" then
        actionType = UIController.InteractionTypes.RECALL_DRONE
    elseif action == "switch_mode" then
        actionType = UIController.InteractionTypes.SWITCH_DRONE_MODE
    end

    if actionType then
        UIController.fireInteractionEvent(actionType, data or {})
    end
end

-- 触发管理员操作事件
function UIController.triggerAdminAction(action, data)
    UIController.fireInteractionEvent(UIController.InteractionTypes.ADMIN_ACTION, {
        action = action,
        data = data
    })
end

-- 触发数据刷新事件
function UIController.triggerRefreshData()
    UIController.fireInteractionEvent(UIController.InteractionTypes.REFRESH_DATA, {})
end

-- 获取当前UI状态
function UIController.getUIState()
    return {
        shopVisible = uiState.shopVisible,
        tutorialVisible = uiState.tutorialVisible,
        adminPanelVisible = uiState.adminPanelVisible,
        droneUIVisible = uiState.droneUIVisible
    }
end

-- 检查是否有任何UI显示
function UIController.hasVisibleUI()
    return uiState.shopVisible or uiState.tutorialVisible or
           uiState.adminPanelVisible or uiState.droneUIVisible
end

return UIController
