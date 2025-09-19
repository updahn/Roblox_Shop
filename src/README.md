# 🏪 Roblox 商店系统 - src 源码目录

## 📁 目录结构

```
src/
├── client/                    # 客户端脚本
│   ├── init.client.luau      # 客户端主入口
│   ├── ShopAdmin.luau        # 管理员界面
│   ├── ShopBuy.luau          # 购买界面
│   ├── ShopRecords.luau      # 交易记录界面
│   ├── ShopSell.luau         # 出售界面
│   ├── ShopUI.luau           # 主界面系统
│   ├── ShopUtils.luau        # UI工具类
│   └── TutorialUI.luau       # 教程界面
├── server/                    # 服务端脚本
│   ├── Bootstrap.server.luau  # 启动管理脚本
│   ├── DataManager.luau      # 数据管理器（弃用）
│   ├── init.server.luau      # 服务端主逻辑（API代理）
│   └── SetupReplicatedStorage.luau # 共享模块设置
└── shared/                    # 共享模块
    ├── Config.luau           # 🆕 统一配置文件
    ├── ShopData.luau         # 商店数据和API调用
    ├── ShopEvents.luau       # 远程事件定义
    ├── 配置使用示例.luau      # 配置使用示例代码
    └── README.md             # 本文档
```

## 🔄 系统架构更新

### v2.0 - API 代理模式

```
Roblox 客户端 → HTTP API → MySQL 数据库
        ↓
   统一配置管理
```

- ✅ **数据持久化**: MySQL 数据库存储
- ✅ **统一配置**: 集中式配置管理
- ✅ **API 代理**: 服务端作为 API 请求代理
- ✅ **模块化设计**: 清晰的职责分离

## 🆕 配置系统重构

### 📋 重构目标

将分散在各个文件中的配置项整合到一个统一的配置文件中，提高代码的可维护性和可配置性。

### 📁 变更文件列表

#### 新增文件

- `src/shared/Config.luau` - 统一配置文件

#### 修改文件

- `src/shared/ShopData.luau` - 移除 API 配置，引用 Config 模块
- `src/server/init.server.luau` - 移除管理员配置，引用 Config 模块
- `src/client/ShopUtils.luau` - 移除 UI 配置，引用 Config 模块
- `src/client/ShopUI.luau` - 使用 Config 中的动画和尺寸配置
- `src/server/SetupReplicatedStorage.luau` - 优先加载 Config 模块

### 统一配置文件 (`shared/Config.luau`)

**包含的配置类别:**

#### 1. API 服务器配置 (`Config.API`)

```lua
{
    BASE_URL = "http://47.243.109.39/api",
    TIMEOUT = 30,
    RETRY_ATTEMPTS = 3,
    RETRY_DELAY = 2,
    DEFAULT_HEADERS = {...},
    ENDPOINTS = {...}
}
```

#### 2. 管理员权限配置 (`Config.ADMIN`)

```lua
{
    USERNAMES = {...},
    PERMISSIONS = {...}
}
```

#### 3. UI 主题配置 (`Config.UI`)

```lua
{
    COLORS = {...},
    SOUNDS = {...},
    ANIMATIONS = {...},
    SIZES = {...}
}
```

#### 4. 游戏玩法配置 (`Config.GAME`)

```lua
{
    ECONOMY = {...},
    TRADING = {...},
    DATA_SYNC = {...}
}
```

#### 5. 调试配置 (`Config.DEBUG`)

```lua
{
    ENABLED = game:GetService("RunService"):IsStudio(),
    LOG_LEVEL = "INFO",
    VERBOSE_ERRORS = true,
    PERFORMANCE_MONITORING = true,
    TEST_DATA = {...}
}
```

#### 6. 本地化配置 (`Config.LOCALIZATION`)

```lua
{
    DEFAULT_LANGUAGE = "zh-CN",
    SUPPORTED_LANGUAGES = {...},
    CURRENCY_FORMAT = {...}
}
```

#### 7. 安全配置 (`Config.SECURITY`)

```lua
{
    ENABLE_REQUEST_VALIDATION = true,
    MAX_REQUEST_SIZE = 1048576,
    RATE_LIMITING = {...},
    INPUT_VALIDATION = {...}
}
```

### 🛠️ 工具函数

#### API 相关

- `Config.getApiUrl(endpoint)` - 获取完整的 API URL
- `Config.isDebugMode()` - 检查调试模式

#### 权限管理

- `Config.isValidAdmin(player)` - 验证管理员权限

#### UI 工具

- `Config.formatCurrency(amount)` - 格式化货币显示
- `Config.getText(key, language)` - 获取本地化文本

#### 日志系统

- `Config.log(level, message, data)` - 统一日志记录

## 📋 快速开始

### 1. 基本使用

```lua
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Config = require(SharedModules:WaitForChild("Config"))

-- 使用API配置
local apiUrl = Config.getApiUrl("/items")

-- 使用UI配置
button.BackgroundColor3 = Config.UI.COLORS.PRIMARY
```

### 2. 自定义配置

```lua
-- 修改API服务器地址
Config.API.BASE_URL = "http://your-server.com/api"

-- 添加管理员
table.insert(Config.ADMIN.USER_IDS, 123456789)

-- 调整UI主题
Config.UI.COLORS.ACCENT = Color3.fromRGB(255, 100, 100)
```

### 3. 管理员检查

```lua
if Config.isValidAdmin(player) then
    -- 执行管理员操作
    showAdminPanel(player)
end
```

## 🔧 开发环境设置

### Roblox Studio 配置

1. **启用 HTTP 服务**

   ```lua
   game:GetService("HttpService").HttpEnabled = true
   ```

2. **使用 Rojo 同步代码**

   ```bash
   rojo serve default.project.json
   ```

3. **配置 API 服务器地址**
   - 开发环境: `http://localhost:3001/api`
   - 生产环境: `http://47.243.109.39/api`

### 调试模式

调试模式在 Studio 中自动启用，包含：

- 详细日志输出
- 性能监控
- 错误详细信息
- 测试数据支持

## 📊 性能优化

### 模块加载优化

- Config 模块优先加载
- 避免循环依赖
- 延迟加载非关键模块

### 网络请求优化

- 连接池管理
- 请求重试机制
- 缓存策略

### UI 性能优化

- 对象池复用
- 动画性能优化
- 内存管理

## 🔒 安全考虑

### 客户端安全

- 输入验证
- 请求频率限制
- 数据加密传输

### 服务端安全

- JWT 身份验证
- 权限检查
- SQL 注入防护

## 🎨 配置自定义指南

### 修改 API 服务器地址

```lua
-- 在 Config.luau 中
Config.API.BASE_URL = "http://your-server.com/api"
```

### 添加管理员

```lua
Config.ADMIN.USER_IDS = {
    123456789,  -- 你的UserId
    987654321   -- 其他管理员的UserId
}
```

### 自定义 UI 主题

```lua
Config.UI.COLORS.PRIMARY = Color3.fromRGB(50, 50, 60)  -- 更改主背景色
Config.UI.COLORS.ACCENT = Color3.fromRGB(255, 100, 100)  -- 更改强调色
```

### 调整经济参数

```lua
Config.GAME.ECONOMY.STARTING_COINS = 5000  -- 新玩家初始金币
Config.GAME.ECONOMY.SELL_RATE = 0.9        -- 提高卖出价格比例
```

## ⚠️ 注意事项

### 1. 模块加载顺序

- Config 模块必须在其他模块之前加载
- SetupReplicatedStorage.luau 已经调整为优先复制 Config 模块

### 2. 循环引用避免

- Config 模块不应引用其他共享模块
- 其他模块可以安全地引用 Config 模块

### 3. 配置修改后的重启

- 修改配置后需要重启游戏服务器
- 客户端配置修改需要玩家重新加入游戏

### 4. 生产环境配置

- 确保在生产环境中关闭调试模式
- 修改默认的管理员配置
- 设置正确的 API 服务器地址

## 🔄 迁移指南

### 原有配置位置 → 新配置位置

1. **API 配置**

   - 原位置: `ShopData.luau` 中的 `API_BASE_URL`
   - 新位置: `Config.API.BASE_URL`

2. **管理员配置**

   - 原位置: `init.server.luau` 中的 `ADMIN_USER_IDS`、`ADMIN_USERNAMES`
   - 新位置: `Config.ADMIN.USER_IDS`、`Config.ADMIN.USERNAMES`

3. **UI 配置**

   - 原位置: `ShopUtils.luau` 中的 `COLORS`、`SOUNDS`
   - 新位置: `Config.UI.COLORS`、`Config.UI.SOUNDS`

4. **动画配置**
   - 原位置: 硬编码在各个 UI 文件中
   - 新位置: `Config.UI.ANIMATIONS`

## 🚀 部署指南

### 生产环境配置

1. **修改 API 配置**

   ```lua
   Config.API.BASE_URL = "http://47.243.109.39/api"
   Config.DEBUG.ENABLED = false
   ```

2. **设置管理员**

   ```lua
   Config.ADMIN.USER_IDS = {您的UserId}
   ```

3. **优化性能设置**
   ```lua
   Config.DEBUG.PERFORMANCE_MONITORING = false
   Config.SECURITY.RATE_LIMITING.ENABLED = true
   ```

## 🆘 故障排除

### 常见问题

1. **模块找不到错误**

   - 确保 Rojo 正确同步了所有文件
   - 检查 SetupReplicatedStorage 是否正确执行

2. **API 连接失败**

   - 检查 HttpService 是否启用
   - 验证 API 服务器地址和端口

3. **权限问题**
   - 确认管理员 UserId 配置正确
   - 检查 Config 模块是否正确加载

### 调试工具

```lua
-- 检查配置加载状态
print("Config模块状态:", Config and "✅ 已加载" or "❌ 未加载")

-- 查看当前配置
print("API地址:", Config.API.BASE_URL)
print("调试模式:", Config.isDebugMode())

-- 测试API连接
local url = Config.getApiUrl("/health")
print("健康检查地址:", url)
```

## 🚀 后续扩展

### 可添加的配置类型

- 网络重试策略
- 缓存配置
- 性能监控配置
- A/B 测试配置
- 多服务器配置

### 高级功能

- 配置热重载
- 远程配置管理
- 配置版本控制
- 配置验证机制

## 📚 配置使用示例

详细的配置使用示例请参考 [`配置使用示例.luau`](./配置使用示例.luau) 文件，包含：

- API 配置使用
- 管理员权限检查
- UI 组件创建
- 经济系统配置
- 日志系统使用
- 环境配置切换
- 配置验证机制

## 🔄 版本历史

- **v2.0.0** (当前) - API 代理模式 + 统一配置
- **v1.0.0** - 本地数据存储模式

---

**最后更新**: 2024 年
**维护者**: AI Assistant
**许可证**: MIT
