# 🏪 Roblox 商店系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Roblox Studio](https://img.shields.io/badge/Roblox%20Studio-Latest-blue)](https://www.roblox.com/create)
[![DataStore](https://img.shields.io/badge/DataStore-Service-success)](https://developer.roblox.com/en-us/articles/datastore-service)

一个功能完整的现代化 Roblox 商店系统，采用纯 DataStore 架构，无需外部服务器，提供完整的电商功能、管理工具和无人机战斗系统。

## 🌟 项目特色

### 🎯 核心优势

- 🏗️ **纯 DataStore 架构** - 无需外部服务器，完全基于 Roblox 官方服务
- 🔐 **企业级安全** - 权限控制、数据加密、操作审计
- ⚡ **高性能** - 缓存机制、批量操作、异步处理
- 📱 **响应式 UI** - 现代化界面设计，支持多分辨率
- 🤖 **无人机系统** - 完整的 AI 战斗助手功能

### 💼 业务功能

- 🛒 **智能商店系统** - 28 种商品、多分类管理、实时库存
- 💰 **金币经济体系** - 实时余额、交易税费、风控系统
- 👑 **会员特权服务** - 多层级会员、每日奖励、专享特权
- 📊 **数据分析中心** - 用户行为、交易统计、运营报表
- 🎮 **游戏化体验** - 成就系统、等级奖励、互动教程
- 🤖 **无人机战斗** - 智能跟随、自动攻击、模式切换

## 📂 项目架构

```
shop/
├── 🎮 src/                          # Roblox游戏脚本 (Luau)
│   ├── 🖥️ client/                   # 客户端脚本
│   │   ├── 👤 user/                 # 用户界面模块
│   │   │   ├── ShopUI.luau          # 主商店界面
│   │   │   ├── ShopBuy.luau         # 商品购买模块
│   │   │   ├── ShopSell.luau        # 物品出售模块
│   │   │   ├── ShopRecords.luau     # 交易记录界面
│   │   │   ├── TutorialUI.luau      # 新手教程系统
│   │   │   └── DroneManager.luau    # 无人机管理器
│   │   ├── 👑 admin/                # 管理员界面模块
│   │   │   ├── ShopAdminPanel.luau  # 管理员控制面板
│   │   │   ├── ShopAdminMembership.luau # 会员管理系统
│   │   │   └── ShopAdminRecords.luau # 全服数据管理
│   │   ├── 🔧 init.client.luau      # 客户端入口
│   │   └── 🛠️ ShopUtils.luau        # 通用工具库
│   ├── 🖥️ server/                   # 服务端脚本
│   │   ├── 📡 modules/              # 业务逻辑模块
│   │   │   ├── AdminService.luau    # 管理员服务逻辑
│   │   │   ├── DataService.luau     # 数据处理服务
│   │   │   ├── UserService.luau     # 用户服务管理
│   │   │   ├── DataStoreManager.luau # 数据存储管理
│   │   │   ├── UserDataService.luau # 用户数据操作
│   │   │   ├── AdminDataService.luau # 管理员数据操作
│   │   │   ├── ItemsInitializer.luau # 商品初始化
│   │   │   ├── TargetService.luau   # 目标服务
│   │   │   ├── DroneService.luau    # 无人机服务
│   │   │   └── EnvironmentManager.luau # 环境管理
│   │   ├── 🚀 Main.server.luau      # 服务端主控制器
│   │   ├── 🔧 Bootstrap.server.luau # 系统初始化脚本
│   │   ├── 💾 DataManager.luau      # 数据存储管理
│   │   ├── 📦 SetupReplicatedStorage.luau # 共享存储配置
│   │   ├── DataStoreBootstrap.server.luau # DataStore初始化
│   │   └── AdminService.luau        # 管理员服务（根级）
│   ├── 🌐 shared/                   # 共享模块
│   │   ├── ⚙️ Config.luau           # 系统配置中心
│   │   ├── 🔗 Events.luau           # 远程事件定义
│   │   ├── 📦 ShopData.luau         # 商店数据管理
│   │   ├── 🌐 ShopDataClient.luau   # 客户端数据接口
│   │   └── 🤖 DroneConfig.luau      # 无人机系统配置
│   └── 📚 README.md                 # 游戏脚本详细文档
├── 📋 default.project.json          # Rojo项目配置
├── 📚 DataStore迁移说明.md          # 架构迁移文档
├── 📝 init.sql更新说明.md           # 数据迁移报告
├── 🤖 无人机系统说明.md            # 无人机功能文档
└── 📚 README.md                     # 项目主文档（本文件）
```

## ✨ 功能特性

### 🙋‍♂️ 用户功能

| 功能模块          | 核心特性                          | 技术亮点                   |
| ----------------- | --------------------------------- | -------------------------- |
| 🛒 **智能购物**   | 28 种商品浏览、智能推荐、批量购买 | 实时库存同步、价格计算引擎 |
| 💸 **便捷交易**   | 一键出售、批量操作、最优价格      | 动态定价算法、交易防重复   |
| 📦 **库存管理**   | 可视化库存、分类查看、价值统计    | 本地缓存、数据同步机制     |
| 📊 **数据分析**   | 交易记录、趋势分析、个人报表      | 图表可视化、数据导出       |
| 👑 **会员特权**   | 多层级会员、每日奖励、专享折扣    | 自动奖励发放、补签机制     |
| 🎓 **学习中心**   | 交互式教程、操作指南、FAQ         | 分步式引导、智能提示       |
| 🤖 **无人机系统** | AI 跟随、自动攻击、模式切换       | 智能目标识别、战斗辅助     |

### 👨‍💼 管理员功能

| 管理模块        | 功能描述                     | 权限等级      |
| --------------- | ---------------------------- | ------------- |
| 👥 **用户中心** | 用户信息、状态管理、权限设置 | 🔒 高级管理员 |
| 💎 **金币银行** | 余额调整、交易监控、风险控制 | 🔐 超级管理员 |
| 📈 **数据大屏** | 实时统计、运营分析、趋势预测 | 📊 数据分析师 |
| ⚙️ **系统配置** | 参数设置、功能开关、主题定制 | 🛠️ 系统管理员 |
| 👑 **会员运营** | 会员管理、特权配置、活动策划 | 🎯 运营管理员 |
| 📋 **审计日志** | 操作记录、安全监控、合规报告 | 🛡️ 安全管理员 |

### 🤖 无人机战斗系统

| 功能模块        | 功能描述                   | 控制方式       |
| --------------- | -------------------------- | -------------- |
| 🎯 **智能召唤** | 一键召唤 AI 助手，自动跟随 | B 键 / UI 按钮 |
| ⚔️ **自动攻击** | 智能识别敌人，自动战斗     | 被动触发       |
| 🔄 **模式切换** | 跟随模式 / 驻守模式        | M 键 / UI 按钮 |
| 📱 **收回管理** | 随时收回，10 秒自动销毁    | N 键 / UI 按钮 |

## 🛠️ 技术栈

### 🎮 前端技术 (Roblox)

| 技术                 | 版本   | 用途         | 特点                            |
| -------------------- | ------ | ------------ | ------------------------------- |
| **Luau**             | Latest | 游戏脚本语言 | 🚀 高性能、类型安全、现代语法   |
| **Roblox Studio**    | Latest | 开发环境     | 🎨 可视化编辑、实时预览、云同步 |
| **DataStoreService** | -      | 数据存储     | 💾 官方服务、高可用、免维护     |
| **RemoteEvents**     | -      | 事件系统     | 📡 安全的远程调用机制           |

### 🗄️ 数据存储架构

| DataStore               | 用途         | 数据类型                       |
| ----------------------- | ------------ | ------------------------------ |
| **ShopUserData_v3**     | 用户基础数据 | 用户信息、金币、库存、会员状态 |
| **ShopSystemConfig_v3** | 系统配置     | 出售比率、税率、每日奖励等配置 |
| **ShopItemData_v3**     | 商品数据     | 商品信息、价格、库存、分类等   |
| **ShopTransactions_v3** | 交易记录     | 购买、出售、管理员操作记录     |
| **ShopMemberships_v3**  | 会员数据     | 会员信息、有效期、奖励设置     |
| **ShopAdminData_v3**    | 管理员数据   | 操作日志、系统设置             |

## 🚀 快速开始

### 📋 环境要求

| 软件              | 版本要求 | 用途         |
| ----------------- | -------- | ------------ |
| **Roblox Studio** | Latest   | 游戏开发环境 |
| **DataStore**     | Enable   | 数据存储服务 |
| **HttpService**   | Enable   | 网络请求     |

### 🎮 一键部署

#### 1. 导入脚本到 Roblox Studio

```
📁 Roblox Studio 结构映射：
├── ServerScriptService/          ← server/ 目录内容
│   ├── Main.server.luau
│   ├── Bootstrap.server.luau
│   ├── DataManager.luau
│   ├── DataStoreBootstrap.server.luau
│   ├── AdminService.luau
│   ├── SetupReplicatedStorage.luau
│   └── modules/
│       ├── AdminService.luau
│       ├── AdminDataService.luau
│       ├── DataService.luau
│       ├── DataStoreManager.luau
│       ├── UserDataService.luau
│       ├── UserService.luau
│       ├── ItemsInitializer.luau
│       ├── TargetService.luau
│       ├── DroneService.luau
│       └── EnvironmentManager.luau
├── StarterPlayerScripts/         ← client/ 目录内容
│   ├── init.client.luau
│   ├── ShopUtils.luau
│   ├── user/
│   │   ├── ShopUI.luau
│   │   ├── ShopBuy.luau
│   │   ├── ShopSell.luau
│   │   ├── ShopRecords.luau
│   │   ├── TutorialUI.luau
│   │   └── DroneManager.luau
│   └── admin/
│       ├── ShopAdminPanel.luau
│       ├── ShopAdminMembership.luau
│       └── ShopAdminRecords.luau
└── ReplicatedStorage/            ← shared/ 目录内容
    └── SharedModules/
        ├── Config.luau
        ├── Events.luau
        ├── ShopData.luau
        ├── ShopDataClient.luau
        └── DroneConfig.luau
```

#### 2. 启用必要服务

在 **Game Settings → Security** 中启用：

- ✅ **Allow HTTP Requests** (用于无人机模型加载)
- ✅ **Enable Studio Access to API Services** (用于 DataStore 服务)

#### 3. 配置管理员权限

编辑 `ReplicatedStorage/SharedModules/Config.luau`：

```lua
-- 👑 管理员配置
ADMIN_CONFIG = {
    ADMIN_USER_IDS = {
        123456789,  -- 替换为你的 Roblox User ID
        987654321,  -- 添加更多管理员 ID...
    }
}
```

#### 4. 配置无人机系统

编辑 `ReplicatedStorage/SharedModules/DroneConfig.luau`：

```lua
-- 🤖 无人机模型配置
ASSET_ID = "rbxassetid://你的无人机模型ID",  -- 替换为实际模型ID
```

**获取无人机模型：**

1. 在 Roblox Studio Toolbox 搜索 "drone" 或 "quadcopter"
2. 选择免费模型并记下 Asset ID
3. 将 ID 填入上述配置

#### 5. 发布并测试

1. **发布游戏**：`File → Publish to Roblox`
2. **测试功能**：
   - 进入游戏，按 `E` 键打开商店
   - 按 `H` 键查看教程
   - 按 `B` 键召唤无人机
   - 测试购买、出售功能
3. **管理员测试**：使用管理员账号测试管理功能

### 🔍 部署验证

运行游戏后，检查输出窗口应显示：

```
✅ 商店系统已启动
🤖 无人机系统已激活
📊 系统初始化完成：
   - 商品数量: 28
   - 会员类型: 5
   - 配置项: 13
🚀 所有服务已启动，系统就绪！
```

## 🎮 操作指南

### 👤 用户操作

| 按键  | 功能           | 说明              |
| ----- | -------------- | ----------------- |
| **E** | 打开商店       | 查看和购买商品    |
| **H** | 显示教程       | 新手引导和帮助    |
| **R** | 交易记录       | 查看个人交易历史  |
| **B** | 召唤无人机     | 召唤 AI 战斗助手  |
| **M** | 切换无人机模式 | 跟随/驻守模式切换 |
| **N** | 收回无人机     | 立即收回无人机    |

### 👑 管理员操作

| 按键  | 功能       | 说明               |
| ----- | ---------- | ------------------ |
| **O** | 管理员面板 | 用户管理、系统配置 |
| **P** | 会员管理   | 会员状态、特权设置 |
| **L** | 查看日志   | 系统操作记录       |

## 📦 商品系统

### 🛒 商品分类 (28 种商品)

#### 武器类 (weapons) - 3 种

- **基础剑** - 100 金币，80 金币回收
- **钢剑** - 250 金币，200 金币回收
- **附魔剑** - 500 金币，每日限购 1 件，无法出售

#### 防具类 (armor) - 4 种

- **木制盾牌** - 80 金币，64 金币回收
- **铁制盾牌** - 180 金币，144 金币回收
- **皮甲** - 150 金币，120 金币回收
- **锁子甲** - 300 金币，240 金币回收

#### 消耗品类 (consumables) - 5 种

- **生命药水** - 50 金币，40 金币回收，每日限购 5 瓶
- **魔法药水** - 60 金币，48 金币回收，每日限购 5 瓶
- **力量药水** - 120 金币，96 金币回收，每日限购 3 瓶
- **传送卷轴** - 150 金币，每日限购 2 张，无法出售
- **面包** - 20 金币，16 金币回收

#### 材料类 (materials) - 6 种

- **红宝石** - 200 金币，160 金币回收，每日限购 2 颗
- **蓝宝石** - 220 金币，176 金币回收，每日限购 2 颗
- **绿宝石** - 250 金币，200 金币回收，每日限购 2 颗
- **铁矿石** - 30 金币，24 金币回收
- **金矿石** - 100 金币，80 金币回收，每日限购 10 个
- **橡木** - 25 金币，20 金币回收

#### 书籍类 (books) - 2 种

- **法术书** - 180 金币，每日限购 1 本，无法出售
- **历史书** - 80 金币，64 金币回收

#### 工具类 (tools) - 3 种

- **世界地图** - 120 金币，96 金币回收，每日限购 1 张
- **镐子** - 90 金币，72 金币回收
- **钓鱼竿** - 70 金币，56 金币回收

#### 会员类 (membership) - 5 种

- **月卡会员** - 1000 金币，每日奖励 100 金币，30 天有效期
- **周卡会员** - 300 金币，每日奖励 100 金币，7 天有效期
- **季卡会员** - 2700 金币，每日奖励 100 金币，90 天有效期
- **高级月卡** - 1800 金币，每日奖励 200 金币，30 天有效期
- **VIP 年卡** - 10000 金币，每日奖励 150 金币，365 天有效期

## 🤖 无人机系统详解

### 🎯 核心功能

1. **智能召唤** - 按 B 键或点击 UI 按钮召唤 AI 助手
2. **自动跟随** - 无人机智能跟随玩家移动
3. **驻守模式** - 切换为固定位置防守
4. **自动攻击** - 识别并攻击范围内敌对目标
5. **智能收回** - 按 N 键收回或 10 秒自动销毁

### ⚙️ 配置参数

```lua
-- 🤖 无人机参数配置
DRONE_CONFIG = {
    LIFETIME = 10,           -- 生存时间(秒)
    ATTACK_RANGE = 50,       -- 攻击范围
    ATTACK_INTERVAL = 1,     -- 攻击间隔
    ATTACK_DAMAGE = 30,      -- 攻击伤害
    FOLLOW_DISTANCE = 8,     -- 跟随距离
    FOLLOW_HEIGHT = 10,      -- 跟随高度
    MOVEMENT_SPEED = 16,     -- 移动速度
}
```

### 🎨 视觉效果

- **召唤特效** - 粒子效果和音效
- **攻击特效** - 激光束和爆炸效果
- **销毁特效** - 消失动画和音效
- **状态指示** - UI 实时显示状态和倒计时

## 💰 经济系统

### 📊 系统配置

| 配置项               | 默认值 | 说明                     |
| -------------------- | ------ | ------------------------ |
| **新用户初始金币**   | 1000   | 新注册用户获得的金币     |
| **商品出售比率**     | 0.8    | 出售价格为购买价格的 80% |
| **交易税率**         | 0.05   | 每笔交易收取 5%税费      |
| **月卡每日奖励**     | 100    | 普通月卡每日金币奖励     |
| **高级月卡每日奖励** | 200    | 高级月卡每日金币奖励     |
| **VIP 年卡每日奖励** | 150    | VIP 年卡每日金币奖励     |
| **月卡最多补发奖励** | 7 天   | 最多可补领 7 天奖励      |

### 💳 会员特权体系

| 会员类型     | 价格       | 有效期 | 每日奖励 | 特殊权益          |
| ------------ | ---------- | ------ | -------- | ----------------- |
| **周卡**     | 300 金币   | 7 天   | 100 金币 | 基础会员权益      |
| **月卡**     | 1000 金币  | 30 天  | 100 金币 | 标准会员权益      |
| **高级月卡** | 1800 金币  | 30 天  | 200 金币 | 高级会员专享      |
| **季卡**     | 2700 金币  | 90 天  | 100 金币 | 长期会员优惠      |
| **VIP 年卡** | 10000 金币 | 365 天 | 150 金币 | 最高级别 VIP 特权 |

## 📈 数据统计

### 📊 用户数据

- **交易统计** - 购买次数、出售次数、总消费、总收入
- **登录记录** - 注册时间、最后登录、活跃度分析
- **库存分析** - 物品分布、价值统计、持有时长
- **会员状态** - 会员类型、剩余天数、奖励记录

### 📈 系统统计

- **商品热度** - 购买排行、库存变化、价格趋势
- **用户活跃度** - 在线统计、新增用户、留存分析
- **收入分析** - 交易额、税收、会员收入
- **系统性能** - 响应时间、错误率、数据量

## 🔧 开发指南

### 添加新商品

1. 编辑 `ItemsInitializer.luau`：

```lua
-- 在 ITEMS 表中添加新商品
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

2. 重启系统自动生效

### 添加新的 RemoteEvent

1. 在 `shared/Events.luau` 中定义：

```lua
local NewEvent = Instance.new("RemoteEvent")
NewEvent.Name = "NewEvent"
NewEvent.Parent = ReplicatedStorage.ShopEvents
```

2. 在服务端处理：

```lua
ShopEvents.NewEvent.OnServerEvent:Connect(function(player, data)
    -- 服务端逻辑
end)
```

3. 在客户端调用：

```lua
ShopEvents.NewEvent:FireServer(data)
```

### 数据操作

使用 DataStore 服务进行数据操作：

```lua
-- 获取用户数据
local userData = UserDataService.getUserDetails(userId)

-- 更新用户金币
local success = AdminDataService.updateUserCoins(userId, newAmount, reason, adminId)

-- 购买商品
local success, message = UserDataService.buyItem(userId, itemId, quantity)
```

## 🛡️ 安全特性

### 🔐 权限控制

- **多级权限** - 普通用户、管理员、超级管理员
- **操作验证** - 所有关键操作都需要权限验证
- **会话管理** - 安全的用户会话系统

### 🛡️ 数据安全

- **原子操作** - 使用 UpdateAsync 确保数据一致性
- **错误恢复** - 完善的错误处理和数据恢复机制
- **操作日志** - 详细记录所有重要操作

### ⚡ 性能优化

- **缓存机制** - 多层缓存减少 DataStore 请求
- **批量操作** - 支持批量数据操作
- **请求限制** - 智能请求频率控制

## 📋 API 接口

### 用户接口

- `UserDataService.createOrLoginUser()` - 用户登录/注册
- `UserDataService.getUserDetails()` - 获取用户信息
- `UserDataService.buyItem()` - 购买商品
- `UserDataService.sellItem()` - 出售商品
- `UserDataService.getUserInventory()` - 查看库存
- `UserDataService.getUserTransactions()` - 交易记录

### 管理员接口

- `AdminDataService.getUsersWithPagination()` - 用户列表
- `AdminDataService.updateUserCoins()` - 修改用户金币
- `AdminDataService.getCompleteSystemStats()` - 系统统计
- `AdminDataService.updateUserStatus()` - 用户状态管理
- `AdminDataService.buyMembership()` - 会员管理

### 无人机接口

- `DroneService.spawnDrone()` - 召唤无人机
- `DroneService.recallDrone()` - 收回无人机
- `DroneService.switchMode()` - 切换模式
- `DroneService.getDroneStatus()` - 获取状态

## 📚 系统文档

### 📝 详细文档

- **[游戏脚本文档](src/README.md)** - 详细的脚本架构和开发指南
- **[DataStore 迁移说明](DataStore迁移说明.md)** - 从 MySQL 到 DataStore 的完整迁移指南
- **[数据更新报告](init.sql更新说明.md)** - 系统配置和商品数据迁移报告
- **[无人机系统说明](无人机系统说明.md)** - 无人机功能详细实现指南

### 🎓 教程系统

游戏内置完整的新手教程系统：

- **基础操作** - 界面介绍、基本操作
- **商店使用** - 购买、出售、库存管理
- **会员系统** - 会员特权、每日奖励
- **无人机系统** - 召唤、控制、战斗策略
- **高级功能** - 管理员功能、数据分析

## 🚨 故障排除

### 常见问题

#### 问题 1：数据加载失败

**症状**：进入游戏时显示"数据加载失败"
**解决方案**：

1. 确认游戏已发布到 Roblox 平台
2. 检查 DataStore 服务是否启用
3. 查看服务器日志了解具体错误

#### 问题 2：无人机不生成

**症状**：按 B 键无反应或无人机模型不显示
**解决方案**：

1. 检查 HttpService 是否启用
2. 确认无人机模型 Asset ID 正确
3. 系统会自动使用备用模型

#### 问题 3：管理员权限无效

**症状**：管理员无法访问管理功能
**解决方案**：

1. 确认 User ID 在 Config.luau 中配置正确
2. 检查 DataStore 中的 isAdmin 字段
3. 重新登录游戏刷新权限

#### 问题 4：交易失败

**症状**：购买或出售操作失败
**解决方案**：

1. 检查金币余额是否足够
2. 确认商品库存状态
3. 查看每日限购是否已达上限

### 调试工具

```lua
-- 启用调试模式
local Config = require(ReplicatedStorage.SharedModules.Config)
Config.DEBUG_MODE = true

-- 查看详细日志
print("调试信息:", data)
warn("警告信息:", error)
```

### 性能监控

- **内存使用** - 监控脚本内存占用
- **网络请求** - 跟踪 DataStore 请求频率
- **错误率** - 统计操作失败率
- **响应时间** - 测量系统响应性能

## 🔄 版本更新

### 更新历史

- **v3.0.0** - 完整 DataStore 架构，无人机系统
- **v2.1.0** - 添加会员系统和每日奖励
- **v2.0.0** - 从 MySQL 迁移到 DataStore
- **v1.3.0** - 添加教程系统
- **v1.2.0** - 优化管理员界面
- **v1.1.0** - 添加会员系统
- **v1.0.0** - 初始版本，基本商店功能

### 升级指南

从旧版本升级时：

1. **备份数据** - 导出重要的用户数据
2. **更新脚本** - 替换所有脚本文件
3. **配置迁移** - 更新配置文件
4. **测试验证** - 全面测试所有功能
5. **逐步部署** - 分阶段发布更新

## 🤝 贡献指南

### 开发规范

- **代码风格** - 遵循 Luau 官方代码规范
- **注释规范** - 所有函数必须有详细注释
- **错误处理** - 使用 pcall 确保安全性
- **性能考虑** - 避免不必要的 DataStore 请求

### 提交流程

1. **Fork 项目** - 创建个人分支
2. **功能开发** - 在独立分支开发新功能
3. **测试验证** - 确保所有功能正常
4. **提交 PR** - 详细描述修改内容
5. **代码审查** - 通过审查后合并

### 问题反馈

- **Bug 报告** - 在 GitHub Issues 中详细描述问题
- **功能建议** - 提出新功能需求和改进建议
- **文档改进** - 帮助完善项目文档

## 📞 技术支持

### 联系方式

- **GitHub Issues** - 报告问题和功能请求
- **开发文档** - 查看详细的技术文档
- **社区论坛** - 与其他开发者交流经验

### 常用资源

- **[Roblox 开发者中心](https://developer.roblox.com/)** - 官方开发文档
- **[DataStore 文档](https://developer.roblox.com/en-us/articles/datastore-service)** - DataStore 官方指南
- **[Luau 语言指南](https://luau-lang.org/)** - Luau 语言学习资源
- **[Roblox 社区](https://devforum.roblox.com/)** - 开发者社区

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

感谢所有为项目做出贡献的开发者和测试用户！

特别感谢：

- Roblox 官方提供的强大开发平台
- 社区贡献的优秀代码和建议
- 所有参与测试和反馈的用户

---

## 🚀 立即开始

准备好体验完整的 Roblox 商店系统了吗？

1. **⭐ Star** 这个项目
2. **📥 下载** 最新版本
3. **🎮 导入** 到 Roblox Studio
4. **🚀 发布** 你的第一个商店！

**让我们一起构建更好的 Roblox 游戏体验！** 🎮✨
