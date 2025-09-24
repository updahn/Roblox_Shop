# 🏪 Roblox 商店系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Roblox Studio](https://img.shields.io/badge/Roblox%20Studio-Latest-blue)](https://www.roblox.com/create)

一个功能完整的现代化 Roblox 商店系统，采用纯 DataStore 架构，无需外部服务器，提供完整的电商功能、管理工具和无人机战斗系统。

## 🌟 核心功能

- 🛒 **智能商店系统** - 28 种商品、多分类管理、实时库存
- 💰 **金币经济体系** - 实时余额、交易税费、会员特权
- 👑 **管理员系统** - 用户管理、数据统计、系统配置
- 🤖 **无人机战斗** - 智能跟随、自动攻击、模式切换
- 🎮 **游戏化体验** - 新手教程、互动界面

## 📂 项目架构 (新版本)

### 新架构设计原则

项目采用清晰的分层架构，严格分离服务端和客户端职责：

#### 服务端架构

- **DataStoreService** - 顶级数据服务，负责玩家数据加载和持久化
- **Services** - 功能服务层，提供业务逻辑和数据处理
- **Functions/Modules** - 功能模块，依赖 Service 的辅助功能

#### 客户端架构

- **Remote Services** - 封装服务端通信逻辑，只管与服务端的数据交换
- **Controllers** - 客户端本地服务，管理 UI 状态和本地行为
- **UI Scripts** - 纯 UI 展示逻辑，与业务逻辑解耦
- **Functions** - 客户端工具和辅助功能

#### 通用模块

- **Common** - 基础通用代码，可被服务端和客户端继承
- **Utils** - 工具模块，提供通用功能
- **Shared** - 第三方模块和跨端共享代码
- **Config** - 配置文件
- **Constant** - 常量定义

### 文件结构

```
src/
├── server/                        # 服务端代码
│   ├── datastoreservice/          # 顶级数据服务
│   │   ├── init.server.luau       # DataStore服务入口
│   │   ├── DataStoreManager.luau  # 数据存储管理器
│   │   ├── UserDataService.luau   # 用户数据服务
│   │   └── AdminDataService.luau  # 管理员数据服务
│   ├── services/                  # 业务服务层
│   │   ├── AdminService.luau      # 管理员服务
│   │   ├── CacheService.luau      # 缓存服务
│   │   ├── DataService.luau       # 数据服务接口
│   │   ├── DroneService.luau      # 无人机服务
│   │   └── UserService.luau       # 用户服务
│   ├── functions/                 # 功能模块
│   │   ├── Bootstrap.luau         # 系统启动管理器
│   │   ├── DataManager.luau       # 数据管理器
│   │   └── Main.luau              # 主逻辑
│   └── init.server.luau           # 服务端入口脚本
├── client/                        # 客户端代码
│   ├── remote/                    # 远程服务（与服务端通信）
│   │   ├── UserRemoteService.luau # 用户远程服务
│   │   ├── AdminRemoteService.luau# 管理员远程服务
│   │   └── ShopClient.luau        # 商店客户端接口
│   ├── controller/                # 本地控制器
│   │   ├── DataController.luau    # 数据状态管理
│   │   ├── UIController.luau      # UI状态管理
│   │   └── ClientServiceCoordinator.luau # 服务协调器
│   ├── ui/                        # UI脚本
│   │   ├── ShopUI.luau            # 主商店界面
│   │   ├── TutorialUI.luau        # 新手教程
│   │   ├── DroneManager.luau      # 无人机管理器
│   │   ├── ShopAdminPanel.luau    # 管理员面板
│   │   ├── ShopAdminMembership.luau # 会员管理
│   │   ├── ShopAdminRecords.luau  # 管理员记录
│   │   ├── ShopBuy.luau           # 购买界面
│   │   ├── ShopRecords.luau       # 记录界面
│   │   └── ShopSell.luau          # 出售界面
│   ├── functions/                 # 客户端功能模块
│   │   └── ShopUtils.luau         # 商店工具库
│   └── init.client.luau           # 客户端入口脚本
├── common/                        # 通用基础代码
│   ├── BaseService.luau           # 基础服务类
│   └── EventManager.luau          # 事件管理器
├── utils/                         # 工具模块
│   ├── CacheManager.luau          # 缓存管理器
│   ├── EnvironmentManager.luau    # 环境管理器
│   ├── ItemsInitializer.luau      # 物品初始化器
│   ├── SetupReplicatedStorage.luau # 共享存储设置
│   ├── TargetService.luau         # 目标服务
│   └── DataSerializer.luau        # 数据序列化工具
├── shared/                        # 第三方和跨端模块
│   └── Events.luau                # 事件定义
├── config/                        # 配置文件
│   └── Config.luau                # 主配置文件
├── constant/                      # 常量定义
│   └── Types.luau                 # 类型定义
└── assets/                        # 资源文件
```

### 架构特性

#### 🔄 数据流控制

- **单向数据流** - 客户端通过 Remote Service 请求数据
- **状态管理** - Controller 层管理本地状态，UI 层只负责展示
- **事件驱动** - 使用 BindableEvent 实现组件间通信

#### 🛡️ 循环引用防护

- **数据序列化** - 自动检测和处理循环引用
- **模块解耦** - 严格的依赖方向，避免循环依赖
- **接口抽象** - 通过事件和接口解耦模块

#### ⚡ 性能优化

- **缓存策略** - 多层缓存减少网络请求
- **按需加载** - 模块化设计支持按需初始化
- **事件池化** - 统一的事件管理避免内存泄漏

#### 🧪 可测试性

- **依赖注入** - 服务间通过接口通信
- **模块隔离** - 每个模块职责单一，便于单元测试
- **环境分离** - Studio 和生产环境自动切换

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

#### 4. 配置无人机系统

```lua
-- 🤖 无人机模型配置
DRONE_CONFIG = {
    ASSET_ID = "rbxassetid://你的无人机模型ID",
    LIFETIME = 10,           -- 生存时间(秒)
    ATTACK_RANGE = 50,       -- 攻击范围
    ATTACK_DAMAGE = 30,      -- 攻击伤害
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

### 用户操作

| 按键  | 功能           | 说明              |
| ----- | -------------- | ----------------- |
| **E** | 打开商店       | 查看和购买商品    |
| **H** | 显示教程       | 新手引导和帮助    |
| **B** | 召唤无人机     | 召唤 AI 战斗助手  |
| **N** | 收回无人机     | 立即收回无人机    |
| **M** | 切换无人机模式 | 跟随/驻守模式切换 |

### 管理员操作

管理员功能通过商店界面内的管理按钮访问，包括：

- 用户管理和系统配置
- 会员状态和特权设置
- 交易记录和数据统计

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

## 🔄 最新更新

### v2.1.0 - 模块引用重构 (2024-12-24)

#### 🛠️ 重大改进

- ✅ **完全移除 script.Parent 依赖** - 采用绝对路径模块加载
- ✅ **智能环境检测** - Studio 和生产环境自动适配
- ✅ **增强错误处理** - 详细的模块加载错误提示
- ✅ **改进 SharedModules 设置** - 更稳定的共享模块初始化

#### 🔧 技术升级

- 新增模块加载回退机制，支持多位置查找
- 优化 DataStore 初始化流程，提升启动可靠性
- 改进缓存系统集成，减少模块依赖问题
- 增强客户端服务协调器的模块管理

#### 🐛 修复问题

- ✅ **修复 `utils is not a valid member of Script` 错误** - 完全重写模块引用系统
- ✅ **解决 `SharedModules` 无限等待问题** - 添加超时处理和错误回退
- ✅ **修复 `Attempted to call require with invalid argument(s)` 错误** - 服务端模块加载优化
- ✅ **解决按钮无响应问题** - 增强客户端事件处理和错误容错
- ✅ **修复服务端模块引用循环依赖** - 采用绝对路径引用系统
- ✅ **优化客户端 UI 模块加载逻辑** - 支持部分模块加载失败的降级处理

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
