# 🏪 Roblox 商店系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)
[![Roblox Studio](https://img.shields.io/badge/Roblox%20Studio-Latest-blue)](https://www.roblox.com/create)
[![API Version](https://img.shields.io/badge/API%20Version-v1.0.0-success)](./server/README.md)

一个功能完整的现代化 Roblox 商店系统，采用前后端分离架构，提供完整的电商功能和管理工具。

## 🌟 项目特色

### 🎯 核心优势

- 🏗️ **微服务架构** - 模块化设计，易于扩展和维护
- 🔐 **企业级安全** - JWT 认证、权限控制、数据加密
- ⚡ **高性能** - 缓存机制、连接池、异步处理
- 📱 **响应式 UI** - 现代化界面设计，支持多分辨率
- 🌐 **RESTful API** - 标准化接口，完整的 API 文档

### 💼 业务功能

- 🛒 **智能商店系统** - 多分类商品、库存管理、价格策略
- 💰 **金币经济体系** - 实时余额、交易税费、风控系统
- 👑 **会员特权服务** - 多层级会员、每日奖励、专享特权
- 📊 **数据分析中心** - 用户行为、交易统计、运营报表
- 🎮 **游戏化体验** - 成就系统、等级奖励、互动教程

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
│   │   │   └── TutorialUI.luau      # 新手教程系统
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
│   │   │   └── UserService.luau     # 用户服务管理
│   │   ├── 🚀 Main.server.luau      # 服务端主控制器
│   │   ├── 🔧 Bootstrap.server.luau # 系统初始化脚本
│   │   ├── 💾 DataManager.luau      # 数据存储管理
│   │   ├── 📦 SetupReplicatedStorage.luau # 共享存储配置
│   │   └── AdminService.luau        # 管理员服务（根级）
│   ├── 🌐 shared/                   # 共享模块
│   │   ├── ⚙️ Config.luau           # 系统配置中心
│   │   ├── 🔗 Events.luau           # 远程事件定义
│   │   ├── 📦 ShopData.luau         # 商店数据管理
│   │   └── 🌐 ShopDataClient.luau   # 客户端数据接口
│   ├── 📚 README.md                 # 游戏脚本文档
│   └── 📝 配置使用示例.luau         # 配置示例文件
├── 🚀 server/                       # 后端API服务 (Node.js)
│   ├── 🌐 api/                      # Express API服务器
│   │   ├── 📋 routes/               # API路由
│   │   │   ├── admin.js             # 管理员路由
│   │   │   ├── auth.js              # 认证路由
│   │   │   ├── items.js             # 商品路由
│   │   │   └── users.js             # 用户路由
│   │   ├── 🔒 middleware/           # 中间件
│   │   │   ├── auth.js              # 认证中间件
│   │   │   └── errorHandler.js      # 错误处理中间件
│   │   ├── 💾 services/             # 业务服务
│   │   │   ├── adminSQLOperations.js # 管理员数据操作
│   │   │   └── userSQLOperations.js # 用户数据操作
│   │   ├── ⚙️ config/               # 配置文件
│   │   │   └── database.js          # 数据库配置
│   │   ├── 🛠️ utils/                # 工具类
│   │   │   └── logger.js            # 日志工具
│   │   ├── 🚀 index.js              # API服务器主入口
│   │   ├── 🏥 healthcheck.js        # 健康检查脚本
│   │   ├── 🐳 Dockerfile            # 容器构建文件
│   │   └── 📦 package.json          # 依赖配置
│   ├── 🗄️ database/                 # 数据库相关
│   │   ├── 📄 init.sql              # 数据库初始化脚本
│   │   └── ⚙️ conf.d/               # MySQL配置
│   │       └── mysql.cnf            # MySQL配置文件
│   ├── 🌐 nginx/                    # 反向代理配置
│   │   └── nginx.conf               # Nginx配置文件
│   ├── 🐳 docker-compose.yml        # 容器编排配置
│   └── 📚 README.md                 # 后端服务文档
├── 📋 default.project.json          # Rojo项目配置
└── 📚 README.md                     # 项目主文档
```

## ✨ 功能特性

### 🙋‍♂️ 用户功能

| 功能模块        | 核心特性                           | 技术亮点                   |
| --------------- | ---------------------------------- | -------------------------- |
| 🛒 **智能购物** | 多分类商品浏览、智能推荐、批量购买 | 实时库存同步、价格计算引擎 |
| 💸 **便捷交易** | 一键出售、批量操作、最优价格       | 动态定价算法、交易防重复   |
| 📦 **库存管理** | 可视化库存、分类查看、价值统计     | 本地缓存、数据同步机制     |
| 📊 **数据分析** | 交易记录、趋势分析、个人报表       | 图表可视化、数据导出       |
| 👑 **会员特权** | 多层级会员、每日奖励、专享折扣     | 自动奖励发放、补签机制     |
| 🎓 **学习中心** | 交互式教程、操作指南、FAQ          | 分步式引导、智能提示       |

### 👨‍💼 管理员功能

| 管理模块        | 功能描述                     | 权限等级      |
| --------------- | ---------------------------- | ------------- |
| 👥 **用户中心** | 用户信息、状态管理、权限设置 | 🔒 高级管理员 |
| 💎 **金币银行** | 余额调整、交易监控、风险控制 | 🔐 超级管理员 |
| 📈 **数据大屏** | 实时统计、运营分析、趋势预测 | 📊 数据分析师 |
| ⚙️ **系统配置** | 参数设置、功能开关、主题定制 | 🛠️ 系统管理员 |
| 👑 **会员运营** | 会员管理、特权配置、活动策划 | 🎯 运营管理员 |
| 📋 **审计日志** | 操作记录、安全监控、合规报告 | 🛡️ 安全管理员 |

## 🛠️ 技术栈

### 🎮 前端技术 (Roblox)

| 技术                  | 版本   | 用途         | 特点                            |
| --------------------- | ------ | ------------ | ------------------------------- |
| **Luau**              | Latest | 游戏脚本语言 | 🚀 高性能、类型安全、现代语法   |
| **Roblox Studio**     | Latest | 开发环境     | 🎨 可视化编辑、实时预览、云同步 |
| **ReplicatedStorage** | -      | 数据同步     | 🔄 客户端-服务端实时通信        |
| **RemoteEvents**      | -      | 事件系统     | 📡 安全的远程调用机制           |

### 🚀 后端技术 (Node.js)

| 技术           | 版本   | 用途         | 特点                              |
| -------------- | ------ | ------------ | --------------------------------- |
| **Node.js**    | >=18.0 | 服务器运行时 | ⚡ 异步 I/O、高并发、生态丰富     |
| **Express.js** | ^4.18  | Web 框架     | 🌐 轻量级、中间件生态、RESTful    |
| **MySQL**      | ^8.0   | 关系型数据库 | 💾 ACID 事务、高性能、数据一致性  |
| **JWT**        | ^9.0   | 身份认证     | 🔐 无状态认证、安全可靠           |
| **Winston**    | ^3.11  | 日志系统     | 📝 多级日志、文件轮转、结构化输出 |

### 🐳 部署技术

| 技术               | 版本     | 用途     | 特点                              |
| ------------------ | -------- | -------- | --------------------------------- |
| **Docker**         | Latest   | 容器化   | 🐳 环境一致性、快速部署、资源隔离 |
| **Docker Compose** | v2       | 服务编排 | 🎼 多服务管理、网络配置、数据卷   |
| **Nginx**          | Alpine   | 反向代理 | 🌐 负载均衡、SSL 终端、静态资源   |
| **Redis**          | 7-Alpine | 缓存系统 | ⚡ 内存缓存、会话存储、消息队列   |

## 🚀 快速开始

### 📋 环境要求

| 软件              | 版本要求 | 用途         |
| ----------------- | -------- | ------------ |
| **Node.js**       | >=18.0.0 | 后端运行环境 |
| **Docker**        | Latest   | 容器化部署   |
| **Roblox Studio** | Latest   | 游戏开发     |
| **Git**           | Latest   | 版本控制     |

### 🐳 一键部署（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/your-username/roblox-shop-system.git
cd roblox-shop-system

# 2. 配置环境变量
cp server/.env.example server/.env
# 编辑 server/.env 文件，配置数据库密码等

# 3. 启动所有服务
cd server
docker-compose up -d

# 4. 查看服务状态
docker-compose ps

# 5. 查看日志
docker-compose logs -f api
```

### ⚙️ 环境变量配置

创建 `server/.env` 文件：

```env
# 🗄️ 数据库配置
MYSQL_HOST=shop-mysql
MYSQL_PORT=3306
MYSQL_USER=shop_user
MYSQL_PASSWORD=your_secure_password_here
MYSQL_DATABASE=shop_system
MYSQL_ROOT_PASSWORD=your_root_password_here

# 🔐 JWT配置
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production

# 🌐 API服务配置
API_SERVER_PORT=3001
NODE_ENV=production

# 👑 管理员配置（用逗号分隔多个用户名）
ADMIN_USERNAMES=YourRobloxUsername,AnotherAdmin

# 📊 日志配置
LOG_LEVEL=info

# 🔒 安全配置
DB_MAX_RETRIES=30
DB_RETRY_INTERVAL_MS=2000
```

### 🎮 Roblox 配置

#### 1. 导入脚本到 Roblox Studio

1. **准备工作**：

   - 在 Roblox Studio 中创建新的 Place
   - 启用 HttpService：`Game Settings → Security → Allow HTTP Requests ✅`

2. **脚本导入**：按照以下结构导入脚本：
   ```
   📁 ServerScriptService/     ← 导入 src/server/ 内容
   📁 StarterPlayerScripts/    ← 导入 src/client/ 内容
   📁 ReplicatedStorage/       ← 导入 src/shared/ 内容
   ```

#### 2. 配置 API 地址

编辑 `ReplicatedStorage/SharedModules/Config.luau`：

```lua
-- 🌐 API服务器配置
API_CONFIG = {
    -- 生产环境（替换为你的服务器地址）
    BASE_URL = "https://your-domain.com/api",

    -- 本地开发
    -- BASE_URL = "http://localhost:3001/api",

    TIMEOUT = 10,
    MAX_RETRIES = 3,
    DEBUG_MODE = false
}

-- 👑 管理员配置
ADMIN_CONFIG = {
    ADMIN_USER_IDS = {
        123456789,  -- 替换为你的 Roblox User ID
        -- 添加更多管理员 ID...
    }
}
```

#### 3. 发布并测试

1. **发布游戏**：`File → Publish to Roblox`
2. **测试功能**：
   - 进入游戏，按 `E` 键打开商店
   - 按 `H` 键查看教程
   - 测试购买、出售功能
3. **管理员测试**：使用管理员账号测试管理功能

### 🔍 服务验证

```bash
# 检查所有服务状态
curl http://localhost:3001/health

# 检查API接口
curl http://localhost:3001/api/config

# 查看数据库
docker-compose exec shop-mysql mysql -u shop_user -p shop_system
```

## API 接口

### 用户接口

- `POST /api/auth/login` - 用户登录
- `GET /api/users/profile` - 获取用户信息
- `POST /api/users/buy` - 购买商品
- `POST /api/users/sell` - 出售商品
- `GET /api/users/inventory` - 查看库存
- `GET /api/users/transactions` - 交易记录

### 管理员接口

- `GET /api/admin/users` - 用户列表
- `PUT /api/admin/users/:id/coins` - 修改用户金币
- `GET /api/admin/stats` - 系统统计
- `PUT /api/admin/config` - 系统配置
- `GET /api/admin/members-list` - 会员列表

## 配置说明

### 环境变量

```env
DB_HOST=localhost
DB_USER=shop_user
DB_PASSWORD=your_password
DB_NAME=shop_db
JWT_SECRET=your_jwt_secret
```

### Roblox 配置

在`src/shared/Config.luau`中配置：

- API 服务器地址
- 游戏设置参数
- UI 界面配置

## 部署指南

### Docker 部署（推荐）

```bash
cd server
docker-compose up -d
```

### 手动部署

1. 安装 MySQL 数据库
2. 导入`server/database/init.sql`
3. 安装 Node.js 依赖并启动服务
4. 配置 Nginx 反向代理

## 开发指南

### 添加新功能

1. 在`src/shared/ShopEvents.luau`中定义新的 RemoteEvent
2. 在客户端和服务端实现相应逻辑
3. 在后端 API 中添加对应接口
4. 更新数据库结构（如需要）

### 调试技巧

- 使用 Roblox Studio 的输出窗口查看日志
- 通过浏览器开发者工具监控 API 请求
- 检查 MySQL 日志排查数据库问题

## 许可证

MIT License - 详见 LICENSE 文件

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 支持

如有问题请在 GitHub Issues 中提出，或联系开发团队。
