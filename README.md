# 🏪 Roblox 商店系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Roblox Studio](https://img.shields.io/badge/Roblox%20Studio-Latest-blue)](https://www.roblox.com/create)
[![Version](https://img.shields.io/badge/Version-v3.0-green.svg)](https://github.com/your-repo/releases)

一个功能完整的现代化 Roblox 商店系统，采用纯 DataStore 架构，无需外部服务器，提供完整的电商功能、管理工具、无人机战斗系统和靶子训练场。

## 🌟 核心功能

- 🛒 **智能商店系统** - 28 种商品、多分类管理、实时库存同步
- 💰 **金币经济体系** - 实时余额、交易税费、会员特权系统
- 👑 **管理员系统** - 用户管理、数据统计、权限控制
- 🤖 **无人机战斗系统** - 智能 AI、自动攻击、多模式切换
- 🎯 **靶子训练场** - 动态靶子、血量系统、自动重生
- 🎮 **游戏化体验** - 新手教程、实时特效、互动界面
- 🔄 **现代化架构** - MVC 模式、事件驱动、模块化设计

## 📂 项目架构 (v3.0 现代化架构)

### MVC 架构设计原则

项目采用现代化的 MVC(Model-View-Controller)架构，严格分离数据、视图和控制逻辑：

#### 🖥️ 服务端架构 (Model 层)

- **DataStoreService** - 数据持久化层，负责玩家数据的存储和加载
- **Services** - 业务逻辑层，提供核心功能服务
  - `UserService` - 用户认证和基础功能
  - `AdminService` - 管理员权限和功能
  - `DroneService` - 无人机系统逻辑
  - `TargetService` - 靶子系统管理
  - `CacheService` - 缓存和性能优化
- **Functions** - 系统启动和初始化模块

#### 📱 客户端架构 (View + Controller 层)

- **Controllers** - 控制器层，管理业务逻辑和状态
  - `UserController` - 用户数据和交易控制
  - `AdminController` - 管理员功能控制
  - `DroneController` - 无人机状态管理
  - `TargetController` - 靶子系统控制
- **UI Scripts** - 视图层，纯 UI 展示和交互
  - `ShopUI` - 主商店界面
  - `DroneUI` - 无人机控制面板
  - `TargetUI` - 靶子可视化界面
  - `TutorialUI` - 新手教程系统
- **Functions** - 客户端工具和辅助功能

#### 🔄 共享模块

- **Config** - 统一配置管理，支持热更新
- **Events** - 事件系统，支持客户端-服务端通信
- **Utils** - 通用工具库和辅助函数
- **Common** - 跨端共享的基础组件

### 📁 项目文件结构

```
src/
├── 🖥️ server/                     # 服务端代码 (Model层)
│   ├── datastoreservice/          # 数据持久化层
│   │   ├── init.server.luau       # DataStore服务入口
│   │   ├── DataStoreManager.luau  # 数据存储管理器
│   │   ├── UserDataService.luau   # 用户数据服务
│   │   └── AdminDataService.luau  # 管理员数据服务
│   ├── services/                  # 业务逻辑层
│   │   ├── UserService.luau       # 用户认证和基础功能
│   │   ├── AdminService.luau      # 管理员权限和功能
│   │   ├── DroneService.luau      # 🤖 无人机系统逻辑
│   │   ├── TargetService.luau     # 🎯 靶子系统管理
│   │   ├── CacheService.luau      # 缓存和性能优化
│   │   └── DataService.luau       # 数据服务接口
│   ├── functions/                 # 系统功能模块
│   │   ├── Main.luau              # 主逻辑入口
│   │   ├── Bootstrap.luau         # 系统启动管理器
│   │   └── DataManager.luau       # 数据管理器
│   └── init.server.luau           # 服务端入口脚本
├── 📱 client/                     # 客户端代码 (View + Controller层)
│   ├── controller/                # 🎮 控制器层 - 业务逻辑控制
│   │   ├── UserController.luau    # 用户数据和交易控制
│   │   ├── AdminController.luau   # 管理员功能控制
│   │   ├── DroneController.luau   # 🤖 无人机状态管理
│   │   └── TargetController.luau  # 🎯 靶子系统控制
│   ├── ui/                        # 🎨 视图层 - UI展示和交互
│   │   ├── ShopUI.luau            # 主商店界面
│   │   ├── DroneUI.luau           # 🤖 无人机控制面板
│   │   ├── TargetUI.luau          # 🎯 靶子可视化界面
│   │   ├── TutorialUI.luau        # 新手教程系统
│   │   ├── ShopAdminPanel.luau    # 👑 管理员面板
│   │   ├── ShopAdminMembership.luau # 会员管理界面
│   │   ├── ShopAdminRecords.luau  # 管理员记录界面
│   │   ├── ShopBuy.luau           # 购买界面
│   │   ├── ShopSell.luau          # 出售界面
│   │   └── ShopRecords.luau       # 交易记录界面
│   ├── functions/                 # 客户端工具模块
│   │   └── ShopUtils.luau         # 商店工具库
│   └── init.client.luau           # 客户端入口脚本
├── 🔄 shared/                     # 共享模块
│   ├── Events.luau                # 事件定义和通信
│   └── ShopData.luau              # 商店数据结构
├── ⚙️ config/                     # 配置管理
│   └── Config.luau                # 统一配置文件
├── 🛠️ utils/                      # 工具模块
│   ├── CacheManager.luau          # 缓存管理器
│   ├── ItemsInitializer.luau      # 物品初始化器
│   └── SetupReplicatedStorage.luau # 共享存储设置
├── 🏗️ common/                     # 通用基础组件
│   ├── BaseService.luau           # 基础服务类
│   └── EventManager.luau          # 事件管理器
└── 📦 assets/                     # 资源文件
```

### 🏗️ 架构特性

#### 🔄 MVC 数据流控制

- **Model 层(服务端)** - 数据持久化和业务逻辑处理
- **View 层(客户端 UI)** - 纯 UI 展示，无业务逻辑
- **Controller 层(客户端)** - 状态管理和用户交互处理
- **事件驱动通信** - 使用 RemoteEvent 和 BindableEvent 实现跨层通信

#### 🎯 新增系统特性

- **🤖 无人机战斗系统**

  - 智能 AI 寻敌算法，支持玩家、NPC、靶子三级目标优先级
  - 跟随/驻守双模式切换，适应不同战斗场景
  - 实时 3D 特效系统，包含激光攻击、爆炸效果
  - 自动高度控制，根据目标类型调整攻击位置

- **🎯 靶子训练系统**
  - 动态生成算法，自动分布在合理位置
  - 血量系统，支持伤害计算和可视化血条
  - 自动重生机制，保持训练场活跃度
  - 实时 UI 同步，客户端状态与服务端完全同步

#### 🛡️ 安全和稳定性

- **权限验证** - 多层权限检查，配置文件+数据库双重验证
- **数据安全** - 原子操作和事务处理，确保数据一致性
- **错误恢复** - 完善的异常处理和自动恢复机制
- **模块解耦** - 严格的依赖关系，避免循环引用

#### ⚡ 性能优化

- **智能缓存** - 多层缓存策略，显著减少 DataStore 调用
- **事件池化** - 统一的事件管理，避免内存泄漏
- **按需加载** - 模块化设计，支持延迟初始化
- **状态同步** - 高效的客户端-服务端状态同步机制

### 技术架构

- **纯 DataStore 架构** - 无需外部服务器，完全基于 Roblox 官方服务
- **事件驱动设计** - 使用 BindableEvent 实现松耦合的组件通信
- **分层架构** - 严格的分层设计，清晰的职责分离
- **模块化开发** - 高内聚低耦合，便于维护和扩展
- **数据安全** - 自动处理循环引用，防止数据传输错误
- **智能模块加载** - 绝对路径引用，避免 script.Parent 依赖问题
- **环境自适应** - Studio 和生产环境自动切换，兼容性保障

## 🚀 快速开始

### 环境要求

- **Roblox Studio** (最新版本)
- **DataStore Service** (已启用)
- **HttpService** (已启用，用于无人机模型)

### 部署步骤

#### 1. 导入代码到 Roblox Studio

```
Roblox Studio 目录映射：
├── ServerScriptService/      ← src/server/ 目录内容
├── StarterPlayerScripts/     ← src/client/ 目录内容
└── ReplicatedStorage/        ← src/shared/ 目录内容
    └── SharedModules/
```

#### 2. 启用必要服务

在 **Game Settings → Security** 中启用：

- ✅ **Allow HTTP Requests**
- ✅ **Enable Studio Access to API Services**

#### 3. 配置管理员权限

编辑 `ReplicatedStorage/SharedModules/core/Config.luau`：

```lua
-- 👑 管理员配置
ADMIN_CONFIG = {
    ADMIN_USER_IDS = {
        123456789,  -- 替换为你的 Roblox User ID
    }
}
```

#### 4. 配置系统参数

```lua
-- 🤖 无人机系统配置
DRONE_CONFIG = {
    LIFETIME = 10,           -- 无人机生存时间(秒)
    ATTACK_RANGE = 50,       -- 攻击范围
    ATTACK_DAMAGE = 30,      -- 攻击伤害
    FOLLOW_DISTANCE = 8,     -- 跟随距离
    MODES = {
        FOLLOW = "follow",   -- 跟随模式
        GUARD = "guard"      -- 驻守模式
    }
}

-- 🎯 靶子系统配置
TARGETS = {
    COUNT = 3,               -- 靶子数量
    MAX_HEALTH = 100,        -- 靶子血量
    RESPAWN_TIME = 5,        -- 重生时间(秒)
    SPAWN_AREA = {
        MIN_RADIUS = 30,     -- 最小生成半径
        MAX_RADIUS = 100,    -- 最大生成半径
        CENTER = Vector3.new(0, 0, 0)  -- 生成中心
    }
}
```

#### 5. 发布并测试

1. **发布游戏**：`File → Publish to Roblox`
2. **测试功能**：
   - 按 `E` 键打开商店
   - 按 `H` 键查看教程
   - 按 `B` 键召唤无人机
   - 按 `N` 键收回无人机
   - 按 `M` 键切换无人机模式

## 🎮 操作指南

### 🎯 基础操作

| 按键  | 功能     | 说明                 |
| ----- | -------- | -------------------- |
| **E** | 打开商店 | 查看商品、购买、出售 |
| **H** | 显示教程 | 新手引导和功能说明   |

### 🤖 无人机系统操作

| 按键  | 功能       | 说明              |
| ----- | ---------- | ----------------- |
| **B** | 召唤无人机 | 召唤 AI 战斗助手  |
| **N** | 收回无人机 | 立即收回无人机    |
| **M** | 切换模式   | 跟随/驻守模式切换 |

#### 无人机模式说明

- **🏃 跟随模式** - 无人机跟随玩家移动，自动攻击范围内敌人
- **🏠 驻守模式** - 无人机停留在召唤位置，守护该区域

#### 攻击优先级

1. **👤 其他玩家** (最高优先级)
2. **🤖 NPC 角色** (中等优先级)
3. **🎯 训练靶子** (最低优先级)

### 🎯 靶子训练系统

训练靶子会自动生成在地图周围，具有以下特性：

- **📊 血量系统** - 每个靶子 100 血量，带可视化血条
- **🔄 自动重生** - 被摧毁后 5 秒自动重生
- **📍 动态位置** - 随机分布在合理的训练位置
- **🎨 实时特效** - 攻击和摧毁时显示特效

### 👑 管理员功能

管理员可通过商店界面访问高级功能：

- **👤 用户管理** - 查看玩家信息、设置管理员权限
- **📊 数据统计** - 查看交易记录、系统使用情况
- **👥 会员管理** - 管理会员状态和特权设置
- **⚙️ 系统配置** - 调整系统参数和功能开关

## 📦 商品系统

系统包含 28 种商品，分为 7 个类别：

- **武器类** (3 种) - 基础剑、钢剑、附魔剑
- **防具类** (4 种) - 盾牌、盔甲等防护装备
- **消耗品类** (5 种) - 各类药水、传送卷轴、面包
- **材料类** (6 种) - 宝石、矿石、木材等原材料
- **书籍类** (2 种) - 法术书、历史书
- **工具类** (3 种) - 地图、镐子、钓鱼竿
- **会员类** (5 种) - 周卡、月卡、季卡、年卡等会员服务

## 💰 经济系统

### 基础设置

- **新用户初始金币**：1000
- **商品出售比率**：80% (出售价格为购买价格的 80%)
- **交易税率**：5%
- **会员每日奖励**：100-200 金币

### 会员体系

| 会员类型 | 价格  | 有效期 | 每日奖励 |
| -------- | ----- | ------ | -------- |
| 周卡     | 300   | 7 天   | 100      |
| 月卡     | 1000  | 30 天  | 100      |
| 高级月卡 | 1800  | 30 天  | 200      |
| 季卡     | 2700  | 90 天  | 100      |
| VIP 年卡 | 10000 | 365 天 | 150      |

## 🚀 缓存系统

### 统一缓存架构

项目采用分层缓存架构，提供高效的数据缓存和同步机制：

#### 核心组件

- **CacheManager** (`src/server/utils/CacheManager.luau`)

  - 底层缓存管理器，提供统一的缓存接口
  - 支持多种缓存类型：用户数据、库存、会员状态、管理员权限等
  - 基于 MessagingService 的跨服务器缓存同步
  - 自动过期清理和 LRU 缓存策略

- **CacheService** (`src/server/services/CacheService.luau`)
  - 高级缓存服务，是 CacheManager 的包装器
  - 提供简化的缓存操作接口
  - 客户端通知功能
  - 管理员缓存管理功能

#### 缓存类型

```luau
-- 支持的缓存类型
USER_DATA = "users"           -- 用户基础数据
USER_INVENTORY = "inventory"  -- 用户库存
MEMBERSHIP = "membership"     -- 会员状态
ADMIN_PERMISSIONS = "admin"   -- 管理员权限
SHOP_ITEMS = "shop_items"     -- 商品信息
SYSTEM_CONFIG = "system_config" -- 系统配置
TRANSACTIONS = "transactions"  -- 交易记录缓存
DAILY_REWARDS = "daily_rewards" -- 每日奖励记录
```

#### 使用示例

```luau
-- 获取缓存服务
local CacheService = require(script.Parent.Parent.services.CacheService)

-- 缓存用户数据
CacheService.cacheUserData(userId, userData, 600) -- TTL 10分钟

-- 获取用户数据
local userData = CacheService.getUserData(userId)

-- 刷新用户缓存
CacheService.refreshUserCache(userId)

-- 管理员功能：清除所有缓存
CacheService.globalRefresh()
```

### 集成状态

- ✅ **DataManager** - 完全集成统一缓存系统
- ✅ **AdminService** - 管理员权限缓存
- ✅ **UserDataService** - 会员状态缓存
- ✅ **Config** - 客户端权限验证缓存整合

## 🛡️ 安全特性

- **权限控制** - 多级权限验证，操作安全性保障
- **数据安全** - 原子操作，错误恢复，操作日志
- **缓存安全** - 跨服务器同步，自动失效处理
- **性能优化** - 智能缓存策略，减少 DataStore 调用

## 🔧 开发指南

### 添加新商品

编辑 `server/utils/ItemsInitializer.luau`，在 ITEMS 表中添加：

```lua
{
    id = "new_item_id",
    name = "新商品名称",
    price = 100,
    sellPrice = 80,
    category = "weapons",
    dailyLimit = 5,
    canSell = true,
    inStock = true,
    description = "商品描述"
}
```

### 模块引用系统 🔧

#### 新架构模块加载机制

本项目采用了绝对路径模块加载机制，避免了传统的 `script.Parent` 引用问题：

**服务端模块加载**

```lua
-- 获取 DataStore 服务模块
local function getDataStoreModule(moduleName)
    local ServerStorage = game:GetService("ServerStorage")
    local serverFolder = ServerStorage:FindFirstChild("Server")
    if serverFolder then
        local datastoreFolder = serverFolder:FindFirstChild("datastoreservice")
        if datastoreFolder and datastoreFolder:FindFirstChild(moduleName) then
            return require(datastoreFolder[moduleName])
        end
    end
    error("❌ 无法加载数据服务模块: " .. moduleName)
end
```

**客户端模块加载**

```lua
-- 获取客户端模块
local function getClientModule(path)
    local player = Players.LocalPlayer
    local playerScripts = player:WaitForChild("PlayerScripts")
    local clientFolder = playerScripts:FindFirstChild("Client")

    local parts = string.split(path, "/")
    local module = clientFolder
    for _, part in ipairs(parts) do
        module = module:FindFirstChild(part)
        if not module then
            error("❌ 找不到模块路径: " .. path)
        end
    end
    return module
end
```

#### 优势特性

- ✅ **环境兼容** - Studio 和生产环境完全兼容
- ✅ **路径安全** - 绝对路径避免相对路径错误
- ✅ **错误提示** - 清晰的错误信息，便于调试
- ✅ **多重查找** - 支持多个位置查找模块，增强容错性

### 常见问题与解决方案

#### 1. 模块加载错误

```
❌ 错误：utils is not a valid member of Script
```

**解决方案**：

- 确认文件结构与 README 描述一致
- 检查模块是否放置在正确位置
- 重新启动 Roblox Studio

#### 2. SharedModules 无法找到

```
❌ 错误：Infinite yield possible on 'ReplicatedStorage:WaitForChild("SharedModules")'
```

**解决方案**：

- 确认 `SetupReplicatedStorage.luau` 正确执行
- 检查 ReplicatedStorage 中是否有 SharedModules 文件夹
- 手动运行一次服务端脚本

#### 3. DataStore 服务启动失败

```
❌ 错误：Attempted to call require with invalid argument(s)
```

**解决方案**：

- 检查 DataStore 服务是否已启用
- 确认游戏已发布到 Roblox
- 验证文件夹结构完整性

#### 4. 模块加载时序问题

```
❌ 错误：客户端初始化失败: 无法获取服务端数据
```

**解决方案**：

- 确保服务端脚本先于客户端脚本执行
- 检查 ServerStorage 中的文件夹结构是否正确
- 增加客户端等待时间（修改 waitForServerData 函数中的超时值）

#### 5. 性能优化建议

- 避免频繁的模块重新加载
- 使用模块缓存减少重复 require 调用
- 定期清理未使用的事件连接

#### 6. 其他常见问题

1. **数据加载失败** - 确认游戏已发布，DataStore 已启用
2. **无人机不生成** - 检查 HttpService 启用，确认模型 Asset ID
3. **管理员权限无效** - 确认 User ID 配置正确
4. **交易失败** - 检查金币余额、库存状态、每日限购

## 📄 许可证

MIT License

---

## 🔄 版本更新历史

### v3.0.0 - 现代化架构重构 + 战斗系统 (2024-12-25)

#### 🚀 重大新功能

- ✨ **🤖 完整无人机战斗系统**

  - 智能 AI 寻敌算法，支持三级目标优先级
  - 跟随/驻守双模式，适应不同战术需求
  - 实时 3D 特效系统，激光攻击和爆炸效果
  - 自动高度控制，精确攻击定位

- ✨ **🎯 靶子训练系统**
  - 动态生成算法，智能分布训练靶子
  - 完整血量系统，可视化血条显示
  - 自动重生机制，持续训练体验
  - 实时 UI 同步，完美的客户端-服务端状态同步

#### 🏗️ 架构升级

- ✅ **MVC 架构重构** - 完整的 Model-View-Controller 分层设计
- ✅ **Controller 层引入** - 新增 4 个专业控制器管理不同系统
- ✅ **事件驱动通信** - 统一的事件系统，支持跨层通信
- ✅ **模块化设计** - 高内聚低耦合，便于维护和扩展

#### 🔧 技术改进

- 🎯 **TargetController** - 专业的靶子系统状态管理
- 🤖 **DroneController** - 无人机系统的完整控制逻辑
- 👤 **UserController** - 用户数据和交易的统一管理
- 👑 **AdminController** - 管理员功能的集中控制

#### 🐛 问题修复

- ✅ **修复靶子删除逻辑** - 解决靶子无法正确摧毁的问题
- ✅ **优化无人机路径查找** - 修复 TargetService 引用错误
- ✅ **增强 UI 同步机制** - 确保客户端 UI 与服务端状态完全同步
- ✅ **改进事件处理** - 更稳定的跨系统事件通信

### v2.1.0 - 模块引用重构 (2024-12-24)

#### 🛠️ 重大改进

- ✅ **完全移除 script.Parent 依赖** - 采用绝对路径模块加载
- ✅ **智能环境检测** - Studio 和生产环境自动适配
- ✅ **增强错误处理** - 详细的模块加载错误提示
- ✅ **改进 SharedModules 设置** - 更稳定的共享模块初始化

## 🚀 立即开始

1. **⭐ Star** 这个项目
2. **📥 下载** 最新版本
3. **🎮 导入** 到 Roblox Studio
4. **🚀 发布** 你的第一个商店！

**让我们一起构建更好的 Roblox 游戏体验！** 🎮✨

---

### 💡 贡献指南

欢迎提交 Issues 和 Pull Requests！

- 🐛 **Bug 报告** - 详细描述复现步骤
- 💡 **功能建议** - 说明使用场景和预期效果
- 📝 **代码贡献** - 遵循项目代码规范

### 📞 联系我们

如果您在使用过程中遇到问题，欢迎：

- 创建 GitHub Issue
- 查看常见问题解决方案
- 参考模块引用系统文档
