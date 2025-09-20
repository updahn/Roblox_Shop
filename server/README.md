# 商店系统后端服务

基于 Node.js 和 Express.js 构建的 Roblox 商店系统后端 API 服务，提供完整的用户管理、商品管理和数据统计功能。

## 目录结构

```
server/
├── api/                    # Express API服务器
│   ├── config/            # 数据库配置
│   ├── middleware/        # 中间件
│   ├── routes/           # 路由定义
│   ├── services/         # 业务逻辑服务
│   ├── utils/            # 工具函数
│   ├── index.js          # 主入口文件
│   ├── package.json      # 依赖配置
│   └── Dockerfile        # Docker配置
├── database/             # 数据库相关
│   ├── init.sql          # 数据库初始化脚本
│   └── conf.d/           # MySQL配置
├── nginx/                # Nginx配置
└── docker-compose.yml    # Docker编排配置
```

## 技术栈

- **Node.js** - JavaScript 运行时环境
- **Express.js** - Web 应用框架
- **MySQL** - 关系型数据库
- **JWT** - JSON Web Token 身份认证
- **bcrypt** - 密码加密
- **express-validator** - 请求验证
- **cors** - 跨域资源共享
- **helmet** - 安全中间件
- **winston** - 日志管理
- **Docker** - 容器化部署

## API 接口文档

### 认证接口 (/api/auth)

#### 用户登录

```http
POST /api/auth/login
Content-Type: application/json

{
  "user_id": "123456789",
  "username": "PlayerName"
}
```

#### 刷新 Token

```http
POST /api/auth/refresh
Authorization: Bearer <refresh_token>
```

### 用户接口 (/api/users)

#### 获取用户信息

```http
GET /api/users/profile
Authorization: Bearer <access_token>
```

#### 购买商品

```http
POST /api/users/buy
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "item_id": "sword_001",
  "quantity": 1
}
```

#### 出售商品

```http
POST /api/users/sell
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "item_id": "sword_001",
  "quantity": 1
}
```

#### 查看库存

```http
GET /api/users/inventory
Authorization: Bearer <access_token>
```

#### 交易记录

```http
GET /api/users/transactions?limit=10&offset=0
Authorization: Bearer <access_token>
```

#### 会员相关

```http
# 购买会员
POST /api/users/buy-membership
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "days": 30
}

# 领取每日奖励
POST /api/users/claim-daily-reward
Authorization: Bearer <access_token>

# 获取会员状态
GET /api/users/membership-status
Authorization: Bearer <access_token>
```

### 管理员接口 (/api/admin)

#### 用户管理

```http
# 获取用户列表
GET /api/admin/users?limit=100&offset=0&status=active

# 获取用户详情
GET /api/admin/users/:userId

# 修改用户金币
PUT /api/admin/users/:userId/coins
Content-Type: application/json

{
  "coins": 10000,
  "reason": "活动奖励"
}

# 更新用户状态
PUT /api/admin/users/:userId/status
Content-Type: application/json

{
  "status": "banned",
  "reason": "违规操作"
}
```

#### 系统统计

```http
GET /api/admin/stats
```

#### 系统配置

```http
# 获取配置
GET /api/admin/config

# 更新单个配置
PUT /api/admin/config/:key
Content-Type: application/json

{
  "value": "0.8",
  "description": "商品卖出价格比例"
}

# 批量更新配置
PUT /api/admin/config
Content-Type: application/json

{
  "configs": [
    {
      "key": "sell_rate",
      "value": "0.8",
      "description": "卖出比例"
    }
  ]
}
```

#### 会员管理

```http
# 添加会员
POST /api/admin/add-membership
Content-Type: application/json

{
  "playerName": "PlayerName",
  "days": 30
}

# 取消会员
POST /api/admin/cancel-membership
Content-Type: application/json

{
  "playerName": "PlayerName"
}

# 延长会员
POST /api/admin/extend-membership
Content-Type: application/json

{
  "playerName": "PlayerName",
  "days": 15
}

# 获取会员列表
GET /api/admin/members-list?page=1&limit=20&status=active

# 批量操作会员
POST /api/admin/batch-membership
Content-Type: application/json

{
  "playerNames": ["Player1", "Player2"],
  "action": "add",
  "days": 30
}
```

#### 商品管理

```http
# 获取商品列表
GET /api/admin/items

# 获取商品详情
GET /api/admin/items/:itemId

# 更新商品库存
PUT /api/admin/items/:itemId/stock
Content-Type: application/json

{
  "stock": 100
}

# 启用/禁用商品
PUT /api/admin/items/:itemId/status
Content-Type: application/json

{
  "active": false
}
```

## 数据库设计

### 核心表结构

#### users - 用户表

```sql
CREATE TABLE users (
  id VARCHAR(50) PRIMARY KEY,
  username VARCHAR(100) NOT NULL,
  display_name VARCHAR(100),
  coins INT DEFAULT 0,
  status ENUM('active', 'inactive', 'banned') DEFAULT 'active',
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### items - 商品表

```sql
CREATE TABLE items (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  category VARCHAR(50),
  buy_price INT NOT NULL,
  sell_price INT NOT NULL,
  current_stock INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);
```

#### user_inventory - 用户库存表

```sql
CREATE TABLE user_inventory (
  user_id VARCHAR(50),
  item_id VARCHAR(50),
  quantity INT DEFAULT 0,
  actual_sell_price INT,
  PRIMARY KEY (user_id, item_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (item_id) REFERENCES items(id)
);
```

#### transactions - 交易记录表

```sql
CREATE TABLE transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(50),
  item_id VARCHAR(50),
  transaction_type ENUM('buy', 'sell'),
  quantity INT,
  unit_price INT,
  total_amount INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (item_id) REFERENCES items(id)
);
```

#### memberships - 会员表

```sql
CREATE TABLE memberships (
  user_id VARCHAR(50) PRIMARY KEY,
  membership_type ENUM('basic', 'premium') DEFAULT 'basic',
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT FALSE,
  daily_reward_amount INT DEFAULT 100,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## 部署指南

### Docker 部署（推荐）

1. **克隆项目**

```bash
git clone <repository-url>
cd shop/server
```

2. **环境配置**

```bash
cp .env.example .env
# 编辑.env文件，配置数据库密码等
```

3. **启动服务**

```bash
docker-compose up -d
```

4. **检查服务状态**

```bash
docker-compose ps
docker-compose logs api
```

### 手动部署

1. **安装依赖**

```bash
cd api
npm install
```

2. **配置数据库**

```bash
# 安装MySQL
sudo apt-get install mysql-server

# 创建数据库和用户
mysql -u root -p < ../database/init.sql
```

3. **环境变量**

```bash
export DB_HOST=localhost
export DB_USER=shop_user
export DB_PASSWORD=your_password
export DB_NAME=shop_db
export JWT_SECRET=your_jwt_secret
export JWT_REFRESH_SECRET=your_refresh_secret
```

4. **启动服务**

```bash
npm start
# 或开发模式
npm run dev
```

## 配置说明

### 环境变量

```env
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=shop_user
DB_PASSWORD=your_secure_password
DB_NAME=shop_db

# JWT配置
JWT_SECRET=your_jwt_secret_key
JWT_REFRESH_SECRET=your_jwt_refresh_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# 服务配置
PORT=3000
NODE_ENV=production

# 安全配置
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 系统配置

通过 API 接口可以动态配置的系统参数：

```javascript
{
  "sell_rate": "0.8",              // 卖出价格比例
  "membership_daily_reward": "100", // 会员每日奖励
  "membership_price_per_day": "50", // 会员每日价格
  "max_inventory_slots": "100",     // 最大库存槽位
  "transaction_fee_rate": "0.05"    // 交易手续费率
}
```

## 开发指南

### 添加新的 API 接口

1. **创建路由**

```javascript
// routes/newFeature.js
const express = require('express');
const router = express.Router();

router.get('/endpoint', async (req, res) => {
  // 实现逻辑
});

module.exports = router;
```

2. **注册路由**

```javascript
// index.js
const newFeatureRoutes = require('./routes/newFeature');
app.use('/api/new-feature', newFeatureRoutes);
```

3. **添加数据库操作**

```javascript
// services/newFeatureSQLOperations.js
class NewFeatureSQLOperations {
  static async someOperation() {
    // SQL操作
  }
}
```

### 错误处理

使用统一的错误处理中间件：

```javascript
const { AppError, catchAsync } = require('./middleware/errorHandler');

router.get(
  '/endpoint',
  catchAsync(async (req, res) => {
    if (someCondition) {
      throw new AppError('错误信息', 400);
    }

    res.json({ success: true, data: result });
  })
);
```

### 日志记录

```javascript
const logger = require('./utils/logger');

logger.info('信息日志', { userId, action });
logger.warn('警告日志', { error });
logger.error('错误日志', { error: error.stack });
```

## 监控和维护

### 健康检查

```http
GET /api/health
```

### 日志查看

```bash
# Docker环境
docker-compose logs -f api

# 手动部署
tail -f logs/app.log
```

### 数据库维护

```sql
-- 清理过期数据
DELETE FROM transactions WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);

-- 优化表
OPTIMIZE TABLE users, items, transactions;

-- 查看性能
SHOW PROCESSLIST;
```

### 性能优化

1. **数据库索引**

```sql
CREATE INDEX idx_transactions_user_created ON transactions(user_id, created_at);
CREATE INDEX idx_user_inventory_user ON user_inventory(user_id);
```

2. **查询优化**

- 使用分页查询
- 添加适当的 WHERE 条件
- 避免 SELECT \*

3. **缓存策略**

- Redis 缓存热点数据
- 应用层缓存配置信息

## 安全注意事项

1. **输入验证** - 使用 express-validator 验证所有输入
2. **SQL 注入防护** - 使用参数化查询
3. **认证授权** - JWT token 验证和权限检查
4. **HTTPS** - 生产环境必须使用 HTTPS
5. **敏感信息** - 不在日志中记录敏感数据

## 故障排除

### 常见问题

1. **数据库连接失败**

   - 检查数据库服务是否启动
   - 验证连接配置和权限

2. **JWT 验证失败**

   - 检查 token 是否过期
   - 验证 JWT_SECRET 配置

3. **API 请求失败**

   - 检查请求格式和参数
   - 查看服务器日志

4. **性能问题**
   - 监控数据库查询性能
   - 检查内存使用情况

### 调试技巧

```javascript
// 启用详细日志
process.env.LOG_LEVEL = 'debug';

// 数据库查询日志
process.env.DB_LOG = 'true';

// API请求日志
process.env.API_LOG = 'true';
```

## 版本更新

### 数据库迁移

```sql
-- 添加新字段
ALTER TABLE users ADD COLUMN new_field VARCHAR(100);

-- 更新数据
UPDATE users SET new_field = 'default_value';

-- 创建新表
CREATE TABLE new_table (...);
```

### API 版本控制

```javascript
// v1 API
app.use('/api/v1', v1Routes);

// v2 API
app.use('/api/v2', v2Routes);

// 默认最新版本
app.use('/api', latestRoutes);
```

## 支持和贡献

- 提交 Issue 报告问题
- 发起 Pull Request 贡献代码
- 查看 Wiki 获取更多文档

---

更多详细信息请参考项目 Wiki 或联系开发团队。
