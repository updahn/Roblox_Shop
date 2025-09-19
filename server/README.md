# 商店系统服务器

这是商店系统的服务器端组件，包含 MySQL 数据库、API 中间件服务器和 Nginx 反向代理。

## 🏗️ 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                        Nginx (80)                           │
│                    反向代理 + 负载均衡                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   API 服务器 (3001)                         │
│              Node.js + Express + JWT                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
    ┌─────────────────▼──────────────────┐
    │            MySQL (3306)            │
    │        数据存储 + 事务处理           │
    └────────────────────────────────────┘
```

## 📋 系统要求

- **操作系统**: Linux (推荐 Ubuntu 20.04+)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **内存**: 最少 2GB RAM
- **存储**: 最少 10GB 可用空间
- **网络**: 开放端口 80, 3001, 3306

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd shop/server
```

### 2. 配置环境

```bash
# 复制环境配置文件
cp .env.example .env

# 编辑配置文件
nano .env
```

### 3. 启动服务

```bash
# 启动所有服务
docker compose up -d
```

### 4. 验证部署

```bash
# 检查服务状态
docker compose ps

# 测试API连接
curl http://localhost:3001/health

# 测试Nginx网关
curl http://localhost/health
```

## 🔧 配置说明

### 环境变量 (.env)

```env
# 服务器配置
SERVER_IP=47.243.109.39           # 服务器IP地址

# 数据库配置
MYSQL_HOST=47.243.109.39          # MySQL服务器地址
MYSQL_PORT=3306                   # MySQL端口
MYSQL_USER=shop_user              # 数据库用户名
MYSQL_PASSWORD=shop_password_2024! # 数据库密码
MYSQL_DATABASE=shop_system        # 数据库名称
MYSQL_ROOT_PASSWORD=root_password_2024! # 数据库root密码

# API服务器配置
API_SERVER_PORT=3001              # API服务器端口
JWT_SECRET=your-jwt-secret-key-here # JWT密钥

# 管理员配置
ADMIN_USERNAMES=YourUsername,AdminName  # 管理员用户名列表
```

## 📁 项目结构

```
server/
├── api/                          # API服务器
│   ├── config/
│   │   └── database.js           # 数据库连接配置
│   ├── middleware/
│   │   ├── auth.js               # 认证中间件
│   │   └── errorHandler.js       # 错误处理
│   ├── routes/
│   │   ├── auth.js               # 认证路由
│   │   ├── users.js              # 用户路由
│   │   ├── items.js              # 商品路由
│   │   ├── transactions.js       # 交易路由
│   │   └── admin.js              # 管理员路由
│   ├── utils/
│   │   └── logger.js             # 日志工具
│   ├── Dockerfile                # API服务器Docker配置
│   ├── package.json              # 依赖配置
│   └── index.js                  # 服务器入口
├── database/
│   ├── init.sql                  # 数据库初始化脚本
│   └── conf.d/
│       └── mysql.cnf             # MySQL配置
├── nginx/
│   ├── nginx.conf                # Nginx主配置
│   └── conf.d/                   # 额外配置目录
├── logs/                         # 日志目录
├── docker-compose.yml            # Docker编排配置
└── README.md                     # 说明文档
```

## 🗄️ 数据库设计

### 核心表结构

- **users** - 用户基本信息
- **user_coins** - 用户金币数据
- **items** - 商品信息
- **user_items** - 用户物品库存
- **transactions** - 交易记录
- **item_categories** - 商品分类

### 存储过程

- **BuyItem(userId, itemId, quantity)** - 购买物品
- **SellItem(userId, itemId, quantity)** - 出售物品

## 🔌 API 接口

### 认证接口

```
POST /api/auth/login      # 用户登录
POST /api/auth/verify     # Token验证
POST /api/auth/refresh    # Token刷新
GET  /api/auth/status     # 认证状态
```

### 用户接口

```
GET  /api/users/me           # 获取用户信息
GET  /api/users/inventory    # 获取用户库存
POST /api/users/buy          # 购买商品
POST /api/users/sell         # 出售商品
GET  /api/users/transactions # 获取交易记录
GET  /api/users/stats        # 获取用户统计
```

### 商品接口

```
GET /api/items                    # 获取所有商品
GET /api/items/category/:category # 获取分类商品
GET /api/items/:itemId            # 获取商品详情
GET /api/items/:itemId/stock      # 获取库存信息
GET /api/items/search             # 搜索商品
```

### 交易接口

```
GET /api/transactions/stats           # 交易统计
GET /api/transactions/popular-items   # 热门商品
GET /api/transactions/price-trends/:itemId # 价格趋势
GET /api/transactions/:transactionId  # 交易详情
GET /api/transactions/market/summary  # 市场摘要
```

### 管理员接口

```
GET /api/admin/users              # 获取所有用户
GET /api/admin/users/:userId      # 获取用户详情
PUT /api/admin/users/:userId/coins # 修改用户金币
PUT /api/admin/users/:userId/status # 更新用户状态
GET /api/admin/stats              # 系统统计
GET /api/admin/logs               # 管理日志
PUT /api/admin/items/:itemId/stock # 更新商品库存
PUT /api/admin/items/:itemId/status # 启用/禁用商品
```

## 🛠️ 管理命令

### Docker Compose 服务管理

```bash
# 启动所有服务
docker compose up -d

# 停止所有服务
docker compose down

# 重启所有服务
docker compose restart

# 查看服务状态
docker compose ps

# 重新构建镜像
docker compose build --no-cache

# 查看日志
docker compose logs -f [服务名]
```

### Docker 命令

```bash
# 查看容器状态
docker compose ps

# 查看特定服务日志
docker compose logs -f api
docker compose logs -f mysql
docker compose logs -f nginx

# 进入容器
docker compose exec api bash
docker compose exec mysql mysql -uroot -p

# 重启单个服务
docker compose restart api

# 查看资源使用情况
docker stats
```

### 数据库管理

```bash
# 连接MySQL
docker compose exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

# 备份数据库
docker compose exec mysql mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > backup.sql

# 恢复数据库
docker compose exec -T mysql mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < backup.sql
```

## 📊 监控和日志

### 日志位置

- **应用日志**: `./logs/combined.log`
- **错误日志**: `./logs/error.log`
- **Nginx 访问日志**: `./logs/nginx/access.log`
- **Nginx 错误日志**: `./logs/nginx/error.log`

### 健康检查

```bash
# API服务健康检查
curl http://localhost:3001/health

# 通过Nginx的健康检查
curl http://localhost/health

# 数据库连接测试
curl -X POST http://localhost:3001/api/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"token":"test"}'
```

## 🔒 安全配置

### 防火墙设置

```bash
# Ubuntu/Debian
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3306/tcp  # 仅限内网访问
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
```

### SSL 配置

1. 获取 SSL 证书：

```bash
# 使用Let's Encrypt
sudo certbot certonly --webroot -w /var/www/html -d yourdomain.com

# 复制证书到ssl目录
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ./ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ./ssl/
```

2. 更新 Nginx 配置以启用 HTTPS

## 🚨 故障排除

### 常见问题

**1. 服务无法启动**

```bash
# 检查端口占用
sudo netstat -tulpn | grep :3001
sudo netstat -tulpn | grep :3306

# 检查Docker状态
docker version
docker compose version

# 查看详细错误
docker compose logs api
```

**2. 数据库连接失败**

```bash
# 检查MySQL容器状态
docker compose ps mysql

# 测试数据库连接
docker compose exec mysql mysql -uroot -p

# 重启数据库服务
docker compose restart mysql
```

**3. API 服务错误**

```bash
# 查看API日志
docker compose logs -f api

# 检查环境变量
docker compose exec api env | grep MYSQL

# 重新构建API镜像
docker compose build --no-cache api
```

**4. Nginx 配置问题**

```bash
# 测试Nginx配置
docker compose exec nginx nginx -t

# 重新加载配置
docker compose exec nginx nginx -s reload

# 查看Nginx日志
docker compose logs nginx
```

### 性能优化

1. **MySQL 优化**：

   - 调整`my.cnf`中的缓冲区大小
   - 启用查询缓存
   - 定期优化表

2. **API 服务优化**：

   - 启用 Redis 缓存
   - 配置连接池
   - 优化查询语句

3. **Nginx 优化**：
   - 启用 gzip 压缩
   - 配置缓存策略
   - 调整 worker 进程数

## 📞 技术支持

如果遇到问题，请：

1. 查看日志文件
2. 检查服务状态
3. 验证配置文件
4. 查阅本文档的故障排除部分

## 📝 更新日志

- **v1.0.0** - 初始版本发布
  - 完整的 API 服务器
  - MySQL 数据库支持
  - Nginx 反向代理
  - Docker 容器化部署
