const express = require('express');
const { body, query, validationResult } = require('express-validator');

const SQLOperations = require('../services/sqlOperations');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { authenticateAdmin } = require('../middleware/auth');

const router = express.Router();

// 所有管理员路由都需要管理员认证
router.use(authenticateAdmin);

// 获取所有用户
router.get(
  '/users',
  query('limit').optional().isInt({ min: 1, max: 1000 }).withMessage('限制数量必须在1-1000之间'),
  query('offset').optional().isInt({ min: 0 }).withMessage('偏移量必须大于等于0'),
  query('status').optional().isIn(['active', 'inactive', 'banned']).withMessage('状态无效'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const limit = parseInt(req.query.limit) || 100;
    const offset = parseInt(req.query.offset) || 0;
    const status = req.query.status;

    const users = await SQLOperations.getUsersWithPagination({ limit, offset, status });

    // 获取总用户数
    const total = await SQLOperations.getUserCount(status);

    res.json({
      success: true,
      message: '获取用户列表成功',
      data: {
        users,
        pagination: {
          limit,
          offset,
          total,
          count: users.length,
        },
      },
    });
  })
);

// 获取用户详细信息
router.get(
  '/users/:userId',
  catchAsync(async (req, res) => {
    const { userId } = req.params;

    const user = await SQLOperations.getUserDetails(userId);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    // 获取用户库存
    const inventory = await SQLOperations.getUserInventory(userId);

    // 获取最近交易
    const transactions = await SQLOperations.getUserTransactions(userId, 10);

    res.json({
      success: true,
      message: '获取用户详细信息成功',
      data: {
        user,
        inventory,
        recentTransactions: transactions,
        inventoryValue: inventory.reduce((sum, item) => sum + item.actual_sell_price * item.quantity, 0),
      },
    });
  })
);

// 修改用户金币
router.put(
  '/users/:userId/coins',
  body('coins').isInt({ min: 0 }).withMessage('金币数量必须是非负整数'),
  body('reason').optional().isString().withMessage('原因必须是字符串'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('输入验证失败', 400);
    }

    const { userId } = req.params;
    const { coins, reason } = req.body;

    // 检查用户是否存在，如果不存在则尝试创建
    let user = await SQLOperations.getUserDetails(userId);
    if (!user) {
      // 尝试从用户ID获取用户名（Roblox用户ID）
      try {
        // 创建新用户记录
        await SQLOperations.createUser(userId, `User_${userId}`, `User_${userId}`);
        user = await SQLOperations.getUserDetails(userId);
        if (!user) {
          throw new AppError('无法创建用户记录', 500);
        }
      } catch (createError) {
        throw new AppError('用户不存在且无法创建用户记录', 404);
      }
    }

    await SQLOperations.updateUserCoins(userId, coins, reason || '管理员调整', req.user.id);

    // 获取更新后的用户信息
    const updatedUser = await SQLOperations.getUserDetails(userId);

    res.json({
      success: true,
      message: '修改用户金币成功',
      data: {
        userId,
        oldCoins: user.coins,
        newCoins: updatedUser.coins,
        reason: reason || '管理员调整',
        operator: req.user.username,
      },
    });
  })
);

// 更新用户状态
router.put(
  '/users/:userId/status',
  body('status').isIn(['active', 'inactive', 'banned']).withMessage('状态必须是active、inactive或banned'),
  body('reason').optional().isString().withMessage('原因必须是字符串'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('输入验证失败', 400);
    }

    const { userId } = req.params;
    const { status, reason } = req.body;

    // 检查用户是否存在
    const user = await SQLOperations.getUserDetails(userId);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    await SQLOperations.updateUserStatus(userId, status);

    res.json({
      success: true,
      message: '更新用户状态成功',
      data: {
        userId,
        oldStatus: user.status,
        newStatus: status,
        reason: reason || '管理员操作',
        operator: req.user.username,
      },
    });
  })
);

// 获取系统统计
router.get(
  '/stats',
  catchAsync(async (req, res) => {
    const stats = await SQLOperations.getCompleteSystemStats();

    res.json({
      success: true,
      message: '获取系统统计成功',
      data: {
        ...stats,
        timestamp: new Date().toISOString(),
      },
    });
  })
);

// 获取管理日志
router.get(
  '/logs',
  query('limit').optional().isInt({ min: 1, max: 1000 }).withMessage('限制数量必须在1-1000之间'),
  query('offset').optional().isInt({ min: 0 }).withMessage('偏移量必须大于等于0'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    // 获取管理员操作记录
    const logs = await SQLOperations.getAdminLogs({ limit, offset });

    res.json({
      success: true,
      message: '获取管理日志成功',
      data: {
        logs,
        pagination: {
          limit,
          offset,
          count: logs.length,
        },
      },
    });
  })
);

// 更新商品库存
router.put(
  '/items/:itemId/stock',
  body('stock').isInt({ min: 0 }).withMessage('库存必须是非负整数'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('输入验证失败', 400);
    }

    const { itemId } = req.params;
    const { stock } = req.body;

    // 检查商品是否存在
    const item = await SQLOperations.getItem(itemId);

    if (!item) {
      throw new AppError('商品不存在', 404);
    }

    // 更新库存
    await SQLOperations.updateItemStock(itemId, stock);

    res.json({
      success: true,
      message: '更新商品库存成功',
      data: {
        itemId,
        itemName: item.name,
        oldStock: item.current_stock,
        newStock: stock,
        operator: req.user.username,
      },
    });
  })
);

// 启用/禁用商品
router.put(
  '/items/:itemId/status',
  body('active').isBoolean().withMessage('状态必须是布尔值'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('输入验证失败', 400);
    }

    const { itemId } = req.params;
    const { active } = req.body;

    // 检查商品是否存在
    const item = await SQLOperations.getItem(itemId);

    if (!item) {
      throw new AppError('商品不存在', 404);
    }

    // 更新状态
    await SQLOperations.updateItemStatus(itemId, active);

    res.json({
      success: true,
      message: '更新商品状态成功',
      data: {
        itemId,
        itemName: item.name,
        oldStatus: item.is_active,
        newStatus: active,
        operator: req.user.username,
      },
    });
  })
);

// 获取管理员列表
router.get(
  '/admins',
  catchAsync(async (req, res) => {
    const admins = await SQLOperations.getAdminList();

    res.json({
      success: true,
      message: '获取管理员列表成功',
      data: admins,
    });
  })
);

// 添加管理员
router.post(
  '/admins',
  body('user_id').optional().isLength({ min: 1 }).withMessage('用户ID不能为空'),
  body('username').optional().isLength({ min: 1 }).withMessage('用户名不能为空'),
  body('permission_level').isIn(['full', 'limited']).withMessage('权限级别无效'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { user_id, username, permission_level, permissions } = req.body;

    if (!user_id && !username) {
      throw new AppError('必须提供用户ID或用户名', 400);
    }

    // 检查用户是否存在
    const existingUser = await SQLOperations.checkUserExists(user_id || username, !!user_id);

    if (!existingUser) {
      // 如果用户不存在，创建新用户记录
      if (!user_id || !username) {
        throw new AppError('创建新用户时必须提供用户ID和用户名', 400);
      }

      await SQLOperations.addAdmin({ user_id, username });
    } else {
      if (existingUser.is_admin) {
        throw new AppError('该用户已是管理员', 400);
      }

      // 更新现有用户为管理员
      await SQLOperations.promoteToAdmin(existingUser.user_id);
    }

    res.json({
      success: true,
      message: '添加管理员成功',
    });
  })
);

// 删除管理员
router.delete(
  '/admins/:userId',
  catchAsync(async (req, res) => {
    const userId = req.params.userId;

    // 检查管理员是否存在
    const existingAdmin = await SQLOperations.checkUserExists(userId, true);

    if (!existingAdmin || !existingAdmin.is_admin) {
      throw new AppError('管理员不存在', 404);
    }

    // 取消管理员权限
    await SQLOperations.removeAdmin(userId);

    res.json({
      success: true,
      message: '删除管理员成功',
    });
  })
);

// 系统数据初始化
router.post(
  '/initialize',
  catchAsync(async (req, res) => {
    const SQLOperations = require('../services/sqlOperations');

    const result = await SQLOperations.initializeSystemData();

    res.json({
      success: true,
      message: '系统数据初始化完成',
      data: result,
    });
  })
);

// 获取系统配置
router.get(
  '/config',
  catchAsync(async (req, res) => {
    const SQLOperations = require('../services/sqlOperations');
    const configs = await SQLOperations.getAllSystemConfig();

    res.json({
      success: true,
      data: configs,
    });
  })
);

// 更新系统配置
router.put(
  '/config/:key',
  catchAsync(async (req, res) => {
    const SQLOperations = require('../services/sqlOperations');
    const { key } = req.params;
    const { value, description } = req.body;

    if (!value) {
      return res.status(400).json({
        success: false,
        message: '配置值不能为空',
      });
    }

    await SQLOperations.setSystemConfig(key, value, description);

    res.json({
      success: true,
      message: '配置更新成功',
      data: { key, value, description },
    });
  })
);

// 批量更新系统配置
router.put(
  '/config',
  catchAsync(async (req, res) => {
    const SQLOperations = require('../services/sqlOperations');
    const { configs } = req.body;

    if (!Array.isArray(configs)) {
      return res.status(400).json({
        success: false,
        message: '配置数据格式错误，应为数组',
      });
    }

    // 批量更新配置
    for (const config of configs) {
      const { key, value, description } = config;
      if (key && value !== undefined) {
        await SQLOperations.setSystemConfig(key, value, description);
      }
    }

    res.json({
      success: true,
      message: `成功更新${configs.length}项配置`,
    });
  })
);

module.exports = router;
