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

## 📂 项目架构

### 文件结构

```
src/
├── server/                    # 服务端代码
│   ├── core/                  # 核心系统模块
│   │   ├── Main.luau          # 主入口点
│   │   ├── Bootstrap.luau     # 系统启动管理器
│   │   └── DataManager.luau   # 数据持久化管理器
│   ├── init.server.luau       # 服务端入口脚本
│   ├── services/              # 业务服务层
│   │   ├── UserService.luau   # 普通用户服务
│   │   ├── AdminService.luau  # 管理员服务
│   │   ├── CacheService.luau  # 缓存服务
│   │   ├── DroneService.luau  # 无人机服务
│   │   └── DataService.luau   # 数据服务统一接口
│   ├── data/                  # 数据层模块
│   │   ├── DataStoreManager.luau
│   │   ├── UserDataService.luau
│   │   └── AdminDataService.luau
│   └── utils/                 # 工具和辅助模块
│       ├── EnvironmentManager.luau
│       ├── CacheManager.luau      # 统一缓存管理器
│       ├── ItemsInitializer.luau
│       ├── TargetService.luau
│       └── SetupReplicatedStorage.luau
├── client/                    # 客户端代码
│   ├── user/                  # 用户界面模块
│   │   ├── ShopUI.luau        # 主商店界面
│   │   ├── TutorialUI.luau    # 新手教程系统
│   │   └── DroneManager.luau  # 无人机管理器
│   ├── admin/                 # 管理员界面模块
│   │   ├── ShopAdminPanel.luau
│   │   └── ShopAdminMembership.luau
│   ├── init.client.luau       # 客户端入口
│   └── ShopUtils.luau         # 通用工具库
└── shared/                    # 共享代码
    ├── core/                  # 核心配置和类型
    │   ├── Config.luau        # 统一配置文件
    │   ├── Events.luau        # 事件定义
    │   └── Types.luau         # 类型定义
    └── client/
        └── ShopClient.luau    # 客户端数据接口
```

### 技术架构

- **纯 DataStore 架构** - 无需外部服务器，完全基于 Roblox 官方服务
- **分层设计** - 核心层、服务层、数据层、工具层各司其职
- **模块化开发** - 功能独立，便于维护和扩展

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

### 常见问题

1. **数据加载失败** - 确认游戏已发布，DataStore 已启用
2. **无人机不生成** - 检查 HttpService 启用，确认模型 Asset ID
3. **管理员权限无效** - 确认 User ID 配置正确
4. **交易失败** - 检查金币余额、库存状态、每日限购

## 📄 许可证

MIT License

---

## 🚀 立即开始

1. **⭐ Star** 这个项目
2. **📥 下载** 最新版本
3. **🎮 导入** 到 Roblox Studio
4. **🚀 发布** 你的第一个商店！

**让我们一起构建更好的 Roblox 游戏体验！** 🎮✨
