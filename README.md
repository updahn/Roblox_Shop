# Roblox 商店系统

一个功能完整的 Roblox 商店系统，包含用户界面、管理员功能和后端 API 服务。

## 项目结构

```
shop/
├── src/                    # Roblox游戏脚本
│   ├── client/            # 客户端脚本
│   ├── server/            # 服务端脚本
│   └── shared/            # 共享脚本
├── server/                # 后端API服务
│   ├── api/              # Express API服务器
│   └── database/         # 数据库配置
└── README.md             # 项目说明
```

## 主要功能

### 用户功能

- 🛒 **商品购买** - 支持多种商品类型购买
- 💰 **商品出售** - 将库存物品卖回给商店
- 📦 **库存管理** - 查看和管理个人库存
- 📊 **交易记录** - 完整的交易历史记录
- 👑 **会员系统** - 会员特权和每日奖励
- 🎯 **教程系统** - 新手引导和帮助

### 管理员功能

- 👥 **用户管理** - 用户信息查看和编辑
- 💎 **金币管理** - 调整用户金币余额
- 📈 **数据统计** - 系统运营数据分析
- 🛠️ **系统配置** - 商店参数配置
- 👑 **会员管理** - 会员权限和状态管理
- 📋 **管理日志** - 操作记录和审计

## 技术栈

### 前端 (Roblox)

- **Luau** - Roblox 脚本语言
- **Roblox Studio** - 开发环境
- **ReplicatedStorage** - 数据同步

### 后端

- **Node.js** - 服务器运行时
- **Express.js** - Web 框架
- **MySQL** - 数据库
- **JWT** - 身份认证
- **Docker** - 容器化部署

## 快速开始

### 1. 后端部署

```bash
cd server
docker-compose up -d
```

### 2. Roblox 配置

1. 在 Roblox Studio 中导入`src/`目录下的脚本
2. 配置`src/shared/Config.luau`中的 API 服务器地址
3. 发布游戏并测试功能

### 3. 管理员设置

- 访问 API 管理接口配置管理员权限
- 初始化商品数据和系统配置

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
