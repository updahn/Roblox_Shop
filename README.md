# 🏪 Roblox 商店系统

一个功能完整的 Roblox 商店系统，支持购买和出售物品，具有现代化 UI 设计和完善的功能体验。系统采用 MySQL 数据库存储，支持 Docker 容器化部署，适用于生产和开发环境。

## 📋 目录

- [✨ 功能特性](#-功能特性)
- [🏗️ 系统架构](#️-系统架构)
- [🚀 快速开始](#-快速开始)
- [🎮 操作指南](#-操作指南)
- [🛍️ 商品清单](#️-商品清单)
- [📁 项目结构](#-项目结构)
- [🚀 部署指南](#-部署指南)
- [🐛 故障排除](#-故障排除)

## ✨ 功能特性

### 🛒 商店系统

- **8 种精美商品**: 剑、药水、盾牌、宝石、护甲、弓箭、卷轴、面包
- **商品图片展示**: 每个商品都有专属图片和详细描述
- **智能库存管理**: 支持有限/无限库存，实时库存显示
- **分类系统**: 武器、防具、消耗品、魔法等分类管理
- **价格体系**: 每个物品都有独立的买入/卖出价格

### 💰 经济系统

- **金币系统**: 完整的虚拟货币管理，实时显示余额
- **80%回收机制**: 物品卖出获得原价 80% 的金币
- **数量自定义**: 支持批量购买/卖出，弹窗选择数量
- **数据持久化**: MySQL 数据库存储，支持事务和数据一致性

### 🎨 现代化 UI 设计

- **毛玻璃效果**: 现代化的毛玻璃背景和模糊效果
- **圆角设计**: 所有 UI 元素都采用圆角设计，美观现代
- **分离式界面**: 购买和卖出界面完全分离
- **商品卡片**: 精美的商品展示卡片（图片+信息+价格+阴影）
- **数量选择器**: 专业的数量选择弹窗（+/-按钮、输入框）
- **动态库存**: 库存 UI 控件随物品数量动态增减
- **实时金币显示**: 顶部金币余额实时更新

### 📱 交互体验

- **三标签设计**: 购买、出售、记录三个独立标签页
- **快捷键操作**: E 键打开商店，H 键查看帮助，ESC 键关闭
- **智能界面切换**: 标签切换时自动清理界面，防止元素混合
- **统一按钮设计**: 所有功能按钮大小统一，视觉一致
- **帮助系统**: 按 H 键打开优化后的引导教程
- **系统通知**: 购买/卖出成功/失败的弹窗通知
- **管理员功能**: 记录页面包含管理员控制面板

## 🏗️ 系统架构

### v2.0 - API 代理模式

```
┌─────────────────────────────────────────────────────────────┐
│                    Roblox游戏客户端                          │
│              (src/client + src/shared)                     │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP API 调用
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   Nginx (80)                               │
│                反向代理 + 负载均衡                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 API服务器 (3001)                            │
│            Node.js + Express + JWT                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
    ┌─────────────────▼──────────────────┐
    │            MySQL (3306)            │
    │        数据库 + 存储过程             │
    └────────────────────────────────────┘
```

**架构特点:**

- ✅ **数据持久化**: MySQL 数据库存储
- ✅ **统一配置**: 集中式配置管理
- ✅ **API 代理**: 服务端作为 API 请求代理
- ✅ **模块化设计**: 清晰的职责分离
- ✅ **容器化部署**: Docker + Docker Compose
- ✅ **负载均衡**: Nginx 反向代理

## 🚀 快速开始

### 环境要求

**开发环境:**

- Roblox Studio
- Rojo 插件
- Git（可选）

**生产环境:**

- Linux 服务器 (推荐 Ubuntu 20.04+)
- Docker + Docker Compose
- 2GB+ RAM, 10GB+ 存储空间

### 本地开发部署

1. **克隆项目**

   ```bash
   git clone <repository-url>
   cd shop
   ```

2. **启动 Rojo 服务器**

   ```bash
   rojo serve
   ```

3. **连接 Roblox Studio**

   - 打开 Roblox Studio
   - 运行 Rojo 插件并连接到 `localhost:34872`
   - 启用 HttpService: `HttpService.HttpEnabled = true`

4. **配置 API 服务器**

   ```lua
   -- 在 src/shared/Config.luau 中配置
   Config.API.BASE_URL = "http://localhost:3001/api"  -- 开发环境
   -- Config.API.BASE_URL = "http://47.243.109.39/api"  -- 生产环境
   ```

5. **开始测试**
   - 按 F5 开始测试
   - 游戏会自动显示引导教程
   - 完成教程后按 **E** 键打开商店界面

## 🎮 操作指南

### 基本控制

- **E 键**: 打开/关闭商店界面
- **H 键**: 打开/关闭帮助界面
- **ESC 键**: 关闭当前界面（商店或帮助）
- **鼠标**: 点击按钮进行操作

### 购买流程

1. 打开商店（默认在购买模式）
2. 浏览商品卡片，查看价格和库存
3. 点击"🛒 购买"按钮
4. 在弹窗中选择购买数量（+/-按钮或直接输入）
5. 点击"确认"完成购买

### 出售流程

1. 点击"💰 出售"标签切换到出售界面
2. 查看你拥有的物品和数量
3. 点击商品的"💰 出售"按钮
4. 在弹窗中选择出售数量
5. 确认出售获得金币（原价 80%）

### 记录查看

1. 点击"📊 记录"标签切换到记录界面
2. 查看所有购买和出售历史记录
3. 管理员可点击"👑 管理"查看全服数据
4. 记录包含时间、物品、数量、金额信息

## 🛍️ 商品清单

| 商品        | 价格     | 卖出价   | 库存 | 分类   |
| ----------- | -------- | -------- | ---- | ------ |
| ⚔️ 铁剑     | 100 金币 | 80 金币  | 10   | 武器   |
| 🧪 生命药水 | 50 金币  | 40 金币  | ∞    | 消耗品 |
| 🛡️ 木盾     | 80 金币  | 64 金币  | 15   | 防具   |
| 💎 魔法宝石 | 200 金币 | 160 金币 | 5    | 魔法   |
| 🥼 皮革护甲 | 150 金币 | 120 金币 | 8    | 防具   |
| 🏹 长弓     | 120 金币 | 96 金币  | 12   | 武器   |
| 📜 魔法卷轴 | 75 金币  | 60 金币  | ∞    | 魔法   |
| 🍞 面包     | 25 金币  | 20 金币  | ∞    | 消耗品 |

## 📁 项目结构

```
shop/
├── src/                              # Roblox游戏源码
│   ├── client/                       # 客户端脚本
│   │   ├── init.client.luau          # 客户端入口
│   │   ├── ShopUI.luau               # 主商店界面（协调器）
│   │   ├── ShopBuy.luau              # 购买界面模块
│   │   ├── ShopSell.luau             # 出售界面模块
│   │   ├── ShopRecords.luau          # 记录界面模块
│   │   ├── ShopAdmin.luau            # 管理员界面模块
│   │   ├── ShopUtils.luau            # UI 工具函数
│   │   └── TutorialUI.luau           # 引导教程界面
│   ├── server/                       # 服务端脚本
│   │   ├── Bootstrap.server.luau     # 启动脚本
│   │   ├── SetupReplicatedStorage.luau # 模块设置
│   │   ├── init.server.luau          # 主服务端逻辑（API代理）
│   │   └── DataManager.luau          # 数据管理（弃用）
│   └── shared/                       # 共享模块
│       ├── Config.luau               # 🆕 统一配置文件
│       ├── ShopData.luau             # 商店数据和API调用
│       ├── ShopEvents.luau           # 远程事件定义
│       ├── 配置使用示例.luau          # 配置使用示例代码
│       └── README.md                 # 源码说明文档
├── server/                           # 服务器部署文件
│   ├── api/                          # Node.js API服务器
│   ├── database/                     # 数据库配置和初始化
│   ├── nginx/                        # Nginx配置
│   ├── docker-compose.yml            # Docker编排
│   └── README.md                     # 服务器部署说明
├── .env.example                      # 环境变量模板
├── default.project.json              # Rojo 项目配置
└── README.md                         # 本文档
```

### 模块化设计

#### 客户端模块

**ShopUtils.luau** - 公用工具类

- 🎨 颜色主题：统一的 UI 颜色方案
- 🔘 按钮创建：现代化按钮组件
- 🔧 圆角工具：UI 圆角效果
- 📢 通知系统：统一的消息提示
- 🔊 音效管理：音效资源管理

**ShopBuy.luau** - 购买界面模块

- 🛒 商品卡片：购买模式的商品展示
- 📦 库存显示：实时库存信息
- 💰 价格展示：商品价格显示
- 🔘 购买按钮：购买交互逻辑

**ShopSell.luau** - 出售界面模块

- 💰 卖出卡片：卖出模式的物品展示
- 📊 拥有数量：玩家物品数量显示
- 💵 卖出价格：80%回收价格计算
- 🔘 卖出按钮：卖出交互逻辑

**ShopUI.luau** - 主协调器

- 🎮 界面管理：主界面创建和管理
- 🔄 模块协调：各子模块的协调
- 📡 事件处理：服务器通信处理
- 🎨 动画控制：开关动画效果

## 🚀 部署指南

### 生产环境部署

#### 1. 服务器环境准备

**系统要求:**

- Linux 服务器 (推荐 Ubuntu 20.04+)
- 2GB+ RAM, 10GB+ 存储空间
- Docker + Docker Compose

**安装 Docker:**

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
newgrp docker
```

#### 2. 部署服务器组件

```bash
# 上传项目文件
cd /home/your-user/
git clone <your-repository-url> shop
cd shop/server

# 配置环境变量
cp ../.env.example .env
nano .env  # 根据实际情况修改配置
```

**配置 .env 文件:**

```env
# 数据库配置
MYSQL_HOST=47.243.109.39
MYSQL_PORT=3306
MYSQL_USER=shop_user
MYSQL_PASSWORD=shop_password_2024!
MYSQL_DATABASE=shop_system
MYSQL_ROOT_PASSWORD=root_password_2024!

# API服务器配置
API_SERVER_PORT=3001
JWT_SECRET=your-super-secret-jwt-key-here-change-this
SERVER_IP=47.243.109.39

# 管理员配置
ADMIN_USERNAMES=YourUsername,AdminName
```

**启动服务:**

```bash
# 启动所有服务
docker compose up -d

# 检查状态
docker compose ps

# 查看日志
docker compose logs -f
```

#### 3. 验证部署

```bash
# 测试 API 服务
curl http://47.243.109.39/health
curl http://47.243.109.39/api/items

# 测试用户注册
curl -X POST http://47.243.109.39/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"userId":"test123","username":"testuser"}'
```

#### 4. 配置 Roblox 游戏

在 Roblox Studio 中：

1. **启用 HTTP 服务:**

   ```lua
   game:GetService("HttpService").HttpEnabled = true
   ```

2. **配置生产环境:**

   ```lua
   -- 在 src/shared/Config.luau 中
   Config.API.BASE_URL = "http://47.243.109.39/api"
   Config.DEBUG.ENABLED = false
   Config.ADMIN.USER_IDS = {您的UserId}
   ```

3. **上传代码并测试:**
   - 使用 Rojo 同步代码到 Studio
   - 发布到 Roblox 平台
   - 测试 API 连接和功能

### 🔧 配置管理

#### 统一配置文件 (`src/shared/Config.luau`)

**包含的配置类别:**

1. **API 服务器配置** - 请求地址、超时、重试策略
2. **管理员权限配置** - 用户 ID、权限级别、自动授权
3. **UI 主题配置** - 颜色、音效、动画、尺寸
4. **游戏玩法配置** - 经济系统、交易规则、数据同步
5. **调试配置** - 日志级别、性能监控、测试数据
6. **本地化配置** - 语言、货币格式
7. **安全配置** - 请求验证、速率限制、输入验证

**工具函数:**

```lua
-- API工具
Config.getApiUrl(endpoint)       -- 获取完整API URL
Config.isDebugMode()             -- 检查调试模式

-- 权限管理
Config.isValidAdmin(player)      -- 验证管理员权限

-- UI工具
Config.formatCurrency(amount)    -- 格式化货币显示
Config.getText(key, language)    -- 本地化文本

-- 日志系统
Config.log(level, message, data) -- 统一日志记录
```

### 管理命令

**Docker Compose 服务管理:**

```bash
docker compose up -d           # 启动服务
docker compose down            # 停止服务
docker compose restart         # 重启服务
docker compose ps              # 查看状态
docker compose logs -f         # 查看日志
docker compose build --no-cache # 重新构建
```

**数据库管理:**

```bash
# 连接MySQL
docker compose exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

# 备份数据库
docker compose exec mysql mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > backup.sql

# 恢复数据库
docker compose exec -T mysql mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < backup.sql
```

## 🔧 系统配置

### HTTP 服务配置

**重要**: 系统需要在 Roblox Studio 中启用 HTTP 服务才能正常工作。

**启用方法**:

1. 打开 Roblox Studio
2. 进入 `文件 > 设置 > 安全性`
3. 勾选 `允许 HTTP 请求`
4. 重启 Studio

### 管理员配置

系统支持通过环境变量配置管理员用户：

```bash
# 在 .env 文件中设置
ADMIN_USERNAMES=YourUsername,AdminName
```

管理员用户将在 API 启动时自动更新到数据库。

### 数据库配置

系统使用动态配置机制，重要参数存储在 `system_config` 表中：

- `shop_tax_rate`: 商店税率 (默认 0.05)
- `default_coins`: 新用户初始金币 (默认 3000)
- `sell_rate`: 物品卖出比例 (默认 0.8)
- `rate_limit_window_ms`: API 请求限制时间窗口
- `rate_limit_max_requests`: API 请求限制最大次数

### 库存管理

系统支持灵活的库存配置：

- `current_stock = -1`: 无限库存
- `current_stock >= 0`: 有限库存，买入时扣减，卖出时增加
- `max_quantity`: 单次购买数量限制

## 🐛 故障排除

### 常见问题

#### Roblox 客户端问题

**商店界面不显示**

- 检查控制台是否有 Lua 错误
- 确认 Rojo 正确同步了所有文件
- 重启 Studio 并重新连接 Rojo
- 验证 Config 模块是否正确加载

**API 连接失败**

- **HTTP 服务未启用**: 错误提示 `HTTP 服务未启用，无法连接到 API 服务器`
  - 解决：在 Roblox Studio 中启用 HTTP 服务（参见系统配置部分）
- **请求头被限制**: 错误提示 `Header "User-Agent" is not allowed!`
  - 解决：已修复，移除了 Roblox 不允许的请求头
- 验证 API 服务器地址和端口
- 确认服务器防火墙设置
- 检查 CORS 配置

**购买/出售失败**

- 确认金币余额和物品数量
- 检查服务端控制台错误信息
- 验证数据库连接状态

#### 服务器部署问题

**API 服务无法启动**

```bash
# 检查端口占用
sudo netstat -tulpn | grep :3001

# 检查Docker日志
docker compose logs api

# 重新构建镜像
docker compose build --no-cache api
```

**数据库连接失败**

```bash
# 检查MySQL容器
docker compose ps mysql

# 测试连接
docker compose exec mysql mysql -uroot -p

# 重启数据库
docker compose restart mysql
```

**权限问题**

- 确认管理员 UserId 配置正确
- 检查 JWT 密钥设置
- 验证环境变量配置

### 调试信息

查看控制台输出获取详细的调试信息：

- `🏪` 商店系统相关
- `💰` 交易相关
- `📦` 库存相关
- `👤` 玩家相关
- `💾` 数据保存相关

### 性能优化

**服务器优化:**

- 调整 MySQL 缓冲区大小
- 启用 Redis 缓存（可选）
- 配置 Nginx gzip 压缩
- 优化数据库查询

**客户端优化:**

- 使用对象池复用 UI 元素
- 优化动画性能
- 合理管理内存使用

## 📚 相关文档

- [源码说明](./src/README.md) - 详细的源码结构和配置说明
- [服务器部署](./server/README.md) - 完整的服务器部署文档
- [配置使用示例](./src/配置使用示例.luau) - 实用代码示例

## 🔄 版本历史

- **v2.0.0** (当前) - API 代理模式 + 统一配置 + Docker 部署
- **v1.0.0** - 本地数据存储模式

## 📞 技术支持

**问题反馈:**

- 检查日志文件
- 提供错误信息
- 描述重现步骤

**重要提示:**

1. 部署前请务必修改 .env 文件中的密钥和密码
2. 定期备份数据库数据
3. 监控服务器资源使用情况
4. 及时更新系统和依赖包

---

**最后更新**: 2024 年
**维护者**: AI Assistant
**许可证**: MIT
