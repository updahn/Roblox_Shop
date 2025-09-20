# Roblox 游戏脚本

这个目录包含了Roblox商店系统的所有游戏内脚本，使用Luau语言开发。

## 目录结构

```
src/
├── client/                 # 客户端脚本（LocalScript）
│   ├── admin/             # 管理员界面脚本
│   ├── user/              # 用户界面脚本
│   ├── init.client.luau   # 客户端主入口
│   └── ShopUtils.luau     # 客户端工具函数
├── server/                # 服务端脚本（Script）
│   ├── AdminService.luau  # 管理员服务
│   ├── Bootstrap.server.luau    # 服务器启动脚本
│   ├── DataManager.luau   # 数据管理服务
│   ├── init.server.luau   # 服务端主入口
│   └── SetupReplicatedStorage.luau  # 存储设置
├── shared/                # 共享脚本（ModuleScript）
│   ├── Config.luau        # 系统配置
│   ├── ShopData.luau      # 商店数据管理
│   └── ShopEvents.luau    # 远程事件定义
└── 配置使用示例.luau      # 配置示例文件
```

## 脚本说明

### 客户端脚本 (client/)

#### 用户界面 (user/)
- **ShopUI.luau** - 主商店界面，包含商品展示和购买功能
- **ShopBuy.luau** - 购买功能实现
- **ShopSell.luau** - 出售功能实现
- **TutorialUI.luau** - 新手教程界面

#### 管理员界面 (admin/)
- **ShopAdminMembership.luau** - 会员管理界面
- **ShopAdminRecords.luau** - 管理员记录查看
- **ShopRecords.luau** - 交易记录界面

#### 核心文件
- **init.client.luau** - 客户端主入口，初始化所有客户端功能
- **ShopUtils.luau** - 客户端工具函数和辅助方法

### 服务端脚本 (server/)

- **init.server.luau** - 服务端主入口，启动所有服务
- **Bootstrap.server.luau** - 服务器启动和初始化脚本
- **AdminService.luau** - 管理员功能服务
- **DataManager.luau** - 数据存储和管理
- **SetupReplicatedStorage.luau** - 设置共享存储

### 共享脚本 (shared/)

- **Config.luau** - 系统配置文件，包含API地址、界面设置等
- **ShopData.luau** - 商店数据管理模块，处理API请求和数据缓存
- **ShopEvents.luau** - 定义所有RemoteEvent和RemoteFunction

## 安装和配置

### 1. 导入脚本到Roblox Studio

1. 在Roblox Studio中创建新的Place
2. 将`src/`目录下的所有脚本导入到对应位置：
   - `client/` → ServerStorage/ClientScripts/
   - `server/` → ServerScriptService/
   - `shared/` → ReplicatedStorage/

### 2. 配置API服务器

编辑`shared/Config.luau`：

```lua
-- API服务器配置
API_BASE_URL = "https://your-api-server.com/api"

-- 或者本地开发
API_BASE_URL = "http://localhost:3000/api"
```

### 3. 设置权限

在`shared/Config.luau`中配置管理员：

```lua
ADMIN_CONFIG = {
    ADMIN_USER_IDS = {
        123456789,  -- 替换为实际的用户ID
        987654321,
    }
}
```

## 开发指南

### 添加新的RemoteEvent

1. 在`shared/ShopEvents.luau`中定义：
```lua
-- 创建新的RemoteEvent
local NewFeatureEvent = Instance.new("RemoteEvent")
NewFeatureEvent.Name = "NewFeatureEvent"
NewFeatureEvent.Parent = ReplicatedStorage.ShopEvents

ShopEvents.NewFeatureEvent = NewFeatureEvent
```

2. 在服务端处理：
```lua
-- server/init.server.luau
ShopEvents.NewFeatureEvent.OnServerEvent:Connect(function(player, data)
    -- 处理逻辑
end)
```

3. 在客户端调用：
```lua
-- client/init.client.luau
ShopEvents.NewFeatureEvent:FireServer(data)
```

### 添加新的UI界面

1. 在`client/user/`或`client/admin/`中创建新的脚本
2. 使用Roblox GUI创建界面
3. 在`client/init.client.luau`中引用和初始化

### 数据管理

使用`shared/ShopData.luau`进行API调用：

```lua
local ShopData = require(ReplicatedStorage.ShopData)

-- 获取用户信息
local success, userData = ShopData.getUserProfile(userId)

-- 购买商品
local success, result = ShopData.buyItem(itemId, quantity)
```

## 调试技巧

### 1. 输出调试信息
```lua
print("调试信息:", data)
warn("警告信息:", error)
```

### 2. 检查网络请求
在`shared/ShopData.luau`中启用调试模式：
```lua
local DEBUG_MODE = true
```

### 3. 错误处理
```lua
local success, result = pcall(function()
    -- 可能出错的代码
    return ShopData.someFunction()
end)

if not success then
    warn("操作失败:", result)
end
```

## 性能优化

### 1. 缓存数据
- 使用本地缓存减少API调用
- 实现数据预加载

### 2. UI优化
- 使用对象池管理UI元素
- 延迟加载非关键界面

### 3. 网络优化
- 批量处理API请求
- 实现请求去重

## 常见问题

### Q: API请求失败怎么办？
A: 检查`Config.luau`中的API地址是否正确，确保后端服务正常运行。

### Q: 如何添加新的管理员？
A: 在`Config.luau`中的`ADMIN_USER_IDS`列表中添加用户ID。

### Q: 界面显示异常怎么解决？
A: 检查GUI元素的层级关系，确保ScreenGui正确设置。

## 更新日志

- v1.0.0 - 初始版本，包含基本商店功能
- v1.1.0 - 添加会员系统
- v1.2.0 - 优化管理员界面
- v1.3.0 - 添加教程系统

## 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 发起Pull Request

欢迎贡献代码和提出改进建议！