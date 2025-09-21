# Roblox 商店系统 - 游戏脚本文档

这个目录包含了完整的 Roblox 商店系统游戏内脚本，使用现代化的 Luau 语言开发。

## 🎯 系统特性

### 核心功能

- 🛒 **完整商店系统** - 支持商品浏览、购买、出售
- 💰 **实时金币管理** - 动态余额更新和交易记录
- 👑 **会员系统** - 多层级会员特权和每日奖励
- 📊 **数据统计** - 详细的交易记录和用户行为分析
- 🎮 **教程系统** - 完整的新手引导和帮助文档

### 技术特色

- 📱 **模块化架构** - 清晰的代码结构和组件分离
- 🔒 **安全认证** - 权限验证和管理员权限控制
- ⚡ **高性能** - 缓存机制和异步操作优化
- 🌐 **数据存储** - 基于 Roblox DataStore 的数据管理
- 🛡️ **错误处理** - 完善的异常捕获和用户反馈

## 目录结构

```
src/
├── client/                 # 客户端脚本（LocalScript）
│   ├── admin/             # 管理员界面脚本
│   ├── user/              # 用户界面脚本
│   ├── init.client.luau   # 客户端主入口
│   └── ShopUtils.luau     # 客户端工具函数
├── server/                # 服务端脚本（Script）
│   ├── AdminService.luau  # 管理员服务
│   ├── Bootstrap.server.luau    # 服务器启动脚本
│   ├── DataManager.luau   # 数据管理服务
│   ├── init.server.luau   # 服务端主入口
│   └── SetupReplicatedStorage.luau  # 存储设置
├── shared/                # 共享脚本（ModuleScript）
│   ├── Config.luau        # 系统配置
│   ├── ShopData.luau      # 商店数据管理
│   └── ShopEvents.luau    # 远程事件定义
└── 配置使用示例.luau      # 配置示例文件
```

## 📁 脚本详细说明

### 🖥️ 客户端脚本 (client/)

客户端脚本运行在每个玩家的设备上，负责用户界面和交互逻辑。

#### 👤 用户界面模块 (user/)

| 文件名               | 功能描述       | 核心特性                            |
| -------------------- | -------------- | ----------------------------------- |
| **ShopUI.luau**      | 主商店界面系统 | 🏪 商品展示、标签页切换、响应式布局 |
| **ShopBuy.luau**     | 商品购买模块   | 💰 价格计算、库存检查、数量选择     |
| **ShopSell.luau**    | 物品出售模块   | 💸 批量出售、价值计算、库存管理     |
| **ShopRecords.luau** | 交易记录界面   | 📊 历史查询、数据分析、导出功能     |
| **TutorialUI.luau**  | 新手教程系统   | 🎓 分步引导、交互式教学、帮助文档   |

#### 👑 管理员界面模块 (admin/)

| 文件名                       | 功能描述       | 权限等级                  |
| ---------------------------- | -------------- | ------------------------- |
| **ShopAdminPanel.luau**      | 管理员控制面板 | 🔒 最高权限，系统配置     |
| **ShopAdminMembership.luau** | 会员管理系统   | 🎫 会员增删改查、特权管理 |
| **ShopAdminRecords.luau**    | 全服数据管理   | 📈 数据统计、用户监控     |

#### ⚙️ 核心系统文件

| 文件名               | 功能描述       | 重要程度                     |
| -------------------- | -------------- | ---------------------------- |
| **init.client.luau** | 客户端启动入口 | 🔥 初始化所有模块，键盘监听  |
| **ShopUtils.luau**   | 通用工具库     | 🛠️ UI 工具、格式化、动画效果 |

### 🖥️ 服务端脚本 (server/)

服务端脚本运行在 Roblox 服务器上，负责数据处理和业务逻辑。

| 文件名                          | 功能描述       | 核心职责                          |
| ------------------------------- | -------------- | --------------------------------- |
| **Main.server.luau**            | 服务端主控制器 | 🎯 启动所有服务，协调各模块       |
| **Bootstrap.server.luau**       | 系统初始化脚本 | 🚀 环境检查、配置加载、依赖注入   |
| **DataManager.luau**            | 数据存储管理   | 💾 数据持久化、缓存策略、备份恢复 |
| **SetupReplicatedStorage.luau** | 共享存储配置   | 📦 模块分发、版本控制、热更新     |

### 📁 服务模块 (server/modules/)

| 文件名                | 功能描述       | 技术特点                        |
| --------------------- | -------------- | ------------------------------- |
| **AdminService.luau** | 管理员服务逻辑 | 👮 权限验证、操作审计、安全控制 |
| **DataService.luau**  | 数据处理服务   | 📊 数据操作、数据验证、错误处理 |
| **UserService.luau**  | 用户服务管理   | 👤 用户认证、状态管理、行为分析 |

### 🌐 共享脚本模块 (shared/)

共享脚本在客户端和服务端都可使用，提供通用功能和配置。

| 文件名                  | 功能描述       | 使用场景                        |
| ----------------------- | -------------- | ------------------------------- |
| **Config.luau**         | 系统配置中心   | ⚙️ 系统设置、界面主题、业务参数 |
| **Events.luau**         | 远程事件定义   | 🌉 客户端-服务端通信桥梁        |
| **ShopData.luau**       | 商店数据管理   | 📦 商品信息、价格策略、库存同步 |
| **ShopDataClient.luau** | 客户端数据接口 | 🔗 数据请求、本地缓存、状态同步 |

## 🚀 快速开始指南

### 📥 第一步：导入脚本到 Roblox Studio

#### 1.1 准备工作环境

```bash
# 1. 在Roblox Studio中创建新的Place
# 2. 确保Studio版本为最新
# 3. 确保 DataStore 服务可用
```

#### 1.2 脚本目录映射

将`src/`目录下的脚本按以下结构导入：

```
Roblox Studio 结构映射：
├── ServerScriptService/          ← server/ 目录内容
│   ├── Main.server.luau
│   ├── Bootstrap.server.luau
│   ├── DataManager.luau
│   └── modules/
│       ├── AdminService.luau
│       ├── DataService.luau
│       └── UserService.luau
├── StarterPlayerScripts/         ← client/ 目录内容
│   ├── init.client.luau
│   ├── ShopUtils.luau
│   ├── user/
│   │   ├── ShopUI.luau
│   │   ├── TutorialUI.luau
│   │   └── ...
│   └── admin/
│       ├── ShopAdminPanel.luau
│       └── ...
└── ReplicatedStorage/            ← shared/ 目录内容
    └── SharedModules/
        ├── Config.luau
        ├── Events.luau
        ├── ShopData.luau
        └── ShopDataClient.luau
```

#### 1.3 脚本属性设置

确保以下设置正确：

- ✅ 所有服务端脚本类型为 `Script`
- ✅ 所有客户端脚本类型为 `LocalScript`
- ✅ 所有共享模块类型为 `ModuleScript`
- ✅ 启用 `RunContext` 为适当模式

### ⚙️ 第二步：配置系统参数

#### 2.1 DataStore 配置

编辑 `ReplicatedStorage/SharedModules/Config.luau`：

```lua
-- 🌐 数据存储配置
DATASTORE_CONFIG = {
    -- DataStore 名称
    MAIN_STORE = "ShopData_v1",

    -- 玩家数据 DataStore
    PLAYER_STORE = "PlayerData_v1",

    -- 超时设置（秒）
    TIMEOUT = 10,

    -- 重试次数
    MAX_RETRIES = 3,

    -- 调试模式
    DEBUG_MODE = false
}
```

#### 2.2 管理员权限配置

```lua
-- 👑 管理员配置
ADMIN_CONFIG = {
    -- 管理员用户ID列表（替换为实际ID）
    ADMIN_USER_IDS = {
        123456789,  -- 主管理员
        987654321,  -- 副管理员
        -- 添加更多管理员ID...
    },

    -- 管理员等级配置
    ADMIN_LEVELS = {
        [123456789] = "super",  -- 超级管理员
        [987654321] = "normal", -- 普通管理员
    }
}
```

#### 2.3 界面主题配置

```lua
-- 🎨 界面主题设置
UI_CONFIG = {
    -- 主题色彩
    THEME = {
        PRIMARY_COLOR = Color3.new(0.2, 0.6, 1),
        SECONDARY_COLOR = Color3.new(0.8, 0.8, 0.8),
        SUCCESS_COLOR = Color3.new(0.2, 0.8, 0.2),
        ERROR_COLOR = Color3.new(0.8, 0.2, 0.2),
        WARNING_COLOR = Color3.new(1, 0.6, 0.2)
    },

    -- 动画设置
    ANIMATIONS = {
        FADE_TIME = 0.3,
        SLIDE_TIME = 0.5,
        BOUNCE_TIME = 0.2
    }
}
```

### 🔧 第三步：环境验证与测试

#### 3.1 基础功能测试

```lua
-- 在ServerScriptService中运行测试脚本
local function testBasicFunctions()
    print("🧪 开始基础功能测试...")

    -- 测试共享模块加载
    local success1, config = pcall(require,
        game.ReplicatedStorage.SharedModules.Config)
    print("📦 Config模块:", success1 and "✅ 成功" or "❌ 失败")

    -- 测试数据连接
    local success2, shopData = pcall(require,
        game.ReplicatedStorage.SharedModules.ShopData)
    print("🌐 ShopData模块:", success2 and "✅ 成功" or "❌ 失败")

    -- 测试事件系统
    local success3, events = pcall(require,
        game.ReplicatedStorage.SharedModules.Events)
    print("📡 Events模块:", success3 and "✅ 成功" or "❌ 失败")
end

testBasicFunctions()
```

#### 3.2 数据服务测试

```lua
-- 测试数据服务连接
local ShopDataClient = require(game.ReplicatedStorage.SharedModules.ShopDataClient)

spawn(function()
    wait(2) -- 等待系统初始化
    ShopDataClient.getPlayerData(function(data)
        if data then
            print("🌐 数据服务测试: ✅ 成功")
            print("📊 玩家数据:", data)
        else
            warn("🌐 数据服务测试: ❌ 失败")
            warn("🔍 请检查数据存储服务是否正常")
        end
    end)
end)
```

### 🛠️ 第四步：高级配置选项

#### 4.1 性能优化配置

```lua
-- 📈 性能优化设置
PERFORMANCE_CONFIG = {
    -- 缓存设置
    CACHE_SIZE = 100,           -- 最大缓存项目数
    CACHE_TTL = 300,           -- 缓存过期时间（秒）

    -- UI优化
    MAX_VISIBLE_ITEMS = 20,    -- 最大同时显示商品数
    LAZY_LOAD_THRESHOLD = 10,  -- 懒加载触发阈值

    -- 网络优化
    BATCH_SIZE = 10,           -- 批量请求大小
    REQUEST_INTERVAL = 1,      -- 请求间隔（秒）
}
```

#### 4.2 安全配置

```lua
-- 🔒 安全配置
SECURITY_CONFIG = {
    -- 请求频率限制
    RATE_LIMIT = {
        MAX_REQUESTS_PER_MINUTE = 60,
        COOLDOWN_TIME = 1,
    },

    -- 数据验证
    VALIDATION = {
        MAX_QUANTITY = 999,
        MAX_COINS = 999999999,
        MIN_USERNAME_LENGTH = 3,
    },

    -- 防作弊设置
    ANTI_CHEAT = {
        ENABLE_CLIENT_VALIDATION = true,
        LOG_SUSPICIOUS_ACTIVITY = true,
    }
}
```

## 开发指南

### 添加新的 RemoteEvent

1. 在`shared/ShopEvents.luau`中定义：

```lua
-- 创建新的RemoteEvent
local NewFeatureEvent = Instance.new("RemoteEvent")
NewFeatureEvent.Name = "NewFeatureEvent"
NewFeatureEvent.Parent = ReplicatedStorage.ShopEvents

ShopEvents.NewFeatureEvent = NewFeatureEvent
```

2. 在服务端处理：

```lua
-- server/init.server.luau
ShopEvents.NewFeatureEvent.OnServerEvent:Connect(function(player, data)
    -- 处理逻辑
end)
```

3. 在客户端调用：

```lua
-- client/init.client.luau
ShopEvents.NewFeatureEvent:FireServer(data)
```

### 添加新的 UI 界面

1. 在`client/user/`或`client/admin/`中创建新的脚本
2. 使用 Roblox GUI 创建界面
3. 在`client/init.client.luau`中引用和初始化

### 数据管理

使用`shared/ShopData.luau`进行数据操作：

```lua
local ShopData = require(ReplicatedStorage.ShopData)

-- 获取用户信息
local success, userData = ShopData.getUserProfile(userId)

-- 购买商品
local success, result = ShopData.buyItem(itemId, quantity)
```

## 调试技巧

### 1. 输出调试信息

```lua
print("调试信息:", data)
warn("警告信息:", error)
```

### 2. 检查网络请求

在`shared/ShopData.luau`中启用调试模式：

```lua
local DEBUG_MODE = true
```

### 3. 错误处理

```lua
local success, result = pcall(function()
    -- 可能出错的代码
    return ShopData.someFunction()
end)

if not success then
    warn("操作失败:", result)
end
```

## 性能优化

### 1. 缓存数据

- 使用本地缓存减少数据操作
- 实现数据预加载

### 2. UI 优化

- 使用对象池管理 UI 元素
- 延迟加载非关键界面

### 3. 网络优化

- 批量处理数据请求
- 实现请求去重

## 常见问题

### Q: 数据操作失败怎么办？

A: 检查 DataStore 服务是否可用，确保游戏已发布且 DataStore 配置正确。

### Q: 如何添加新的管理员？

A: 在`Config.luau`中的`ADMIN_USER_IDS`列表中添加用户 ID。

### Q: 界面显示异常怎么解决？

A: 检查 GUI 元素的层级关系，确保 ScreenGui 正确设置。

## 更新日志

- v1.0.0 - 初始版本，包含基本商店功能
- v1.1.0 - 添加会员系统
- v1.2.0 - 优化管理员界面
- v1.3.0 - 添加教程系统

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

欢迎贡献代码和提出改进建议！
