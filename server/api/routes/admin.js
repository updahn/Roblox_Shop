const express = require('express');
const { body, query, validationResult } = require('express-validator');

const AdminSQLOperations = require('../services/adminSQLOperations');
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
  query('includeStats').optional().isBoolean().withMessage('includeStats必须是布尔值'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const limit = parseInt(req.query.limit) || 100;
    const offset = parseInt(req.query.offset) || 0;
    const status = req.query.status;
    const includeStats = req.query.includeStats === 'true';

    const users = await AdminSQLOperations.getUsersWithPagination({ limit, offset, status });

    // 如果需要包含统计数据，批量获取用户统计
    if (includeStats && users.length > 0) {
      const userIds = users.map((user) => user.id);
      const userStats = await AdminSQLOperations.getBatchUserStats(userIds);

      // 将统计数据合并到用户数据中
      users.forEach((user) => {
        const stats = userStats[user.id] || {
          buy_count: 0,
          sell_count: 0,
          total_spent: 0,
          total_earned: 0,
        };
        user.buy_count = stats.buy_count;
        user.sell_count = stats.sell_count;
        user.total_spent = stats.total_spent;
        user.total_earned = stats.total_earned;
        user.end_date = user.membership_end_date;
      });
    }

    // 获取总用户数
    const total = await AdminSQLOperations.getUserCount(status);

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

    const user = await AdminSQLOperations.getUserDetails(userId);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    // 获取用户库存
    const inventory = await AdminSQLOperations.getUserInventory(userId);

    // 获取最近交易
    const transactions = await AdminSQLOperations.getUserTransactions(userId, 10);

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

// 获取用户交易历史
router.get(
  '/users/:username/history',
  catchAsync(async (req, res) => {
    const { username } = req.params;
    const { page = 1, limit = 50 } = req.query;

    // 根据用户名获取用户信息
    const user = await AdminSQLOperations.checkUserExists(username, false);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    // 获取用户交易历史
    const transactions = await AdminSQLOperations.getUserTransactions(user.id, limit);

    res.json({
      success: true,
      message: '获取用户交易历史成功',
      data: {
        user: {
          id: user.id,
          username: user.username,
          displayName: user.display_name,
        },
        transactions: transactions,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: transactions.length,
        },
      },
    });
  })
);

// 获取用户会员状态
router.get(
  '/users/:username/membership',
  catchAsync(async (req, res) => {
    const { username } = req.params;

    // 根据用户名获取用户信息
    const user = await AdminSQLOperations.checkUserExists(username, false);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    // 获取用户会员状态
    const membership = await AdminSQLOperations.getMembershipStatus(user.id);

    res.json({
      success: true,
      message: '获取用户会员状态成功',
      data: {
        user: {
          id: user.id,
          username: user.username,
          displayName: user.display_name,
        },
        membership: membership,
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
    let user = await AdminSQLOperations.getUserDetails(userId);
    if (!user) {
      // 尝试从用户ID获取用户名（Roblox用户ID）
      try {
        // 创建新用户记录
        await AdminSQLOperations.createUser(userId, `User_${userId}`, `User_${userId}`);
        user = await AdminSQLOperations.getUserDetails(userId);
        if (!user) {
          throw new AppError('无法创建用户记录', 500);
        }
      } catch (createError) {
        throw new AppError('用户不存在且无法创建用户记录', 404);
      }
    }

    await AdminSQLOperations.updateUserCoins(userId, coins, reason || '管理员调整', req.user.id);

    // 获取更新后的用户信息
    const updatedUser = await AdminSQLOperations.getUserDetails(userId);

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
    const user = await AdminSQLOperations.getUserDetails(userId);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    await AdminSQLOperations.updateUserStatus(userId, status);

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
    const stats = await AdminSQLOperations.getCompleteSystemStats();

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
    const item = await AdminSQLOperations.getItem(itemId);

    if (!item) {
      throw new AppError('商品不存在', 404);
    }

    // 更新库存
    await AdminSQLOperations.updateItemStock(itemId, stock);

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
    const item = await AdminSQLOperations.getItem(itemId);

    if (!item) {
      throw new AppError('商品不存在', 404);
    }

    // 更新状态
    await AdminSQLOperations.updateItemStatus(itemId, active);

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
    const admins = await AdminSQLOperations.getAdminList();

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
    const existingUser = await AdminSQLOperations.checkUserExists(user_id || username, !!user_id);

    if (!existingUser) {
      // 如果用户不存在，创建新用户记录
      if (!user_id || !username) {
        throw new AppError('创建新用户时必须提供用户ID和用户名', 400);
      }

      await AdminSQLOperations.addAdmin({ user_id, username });
    } else {
      if (existingUser.is_admin) {
        throw new AppError('该用户已是管理员', 400);
      }

      // 更新现有用户为管理员
      await AdminSQLOperations.promoteToAdmin(existingUser.user_id);
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
    const existingAdmin = await AdminSQLOperations.checkUserExists(userId, true);

    if (!existingAdmin || !existingAdmin.is_admin) {
      throw new AppError('管理员不存在', 404);
    }

    // 取消管理员权限
    await AdminSQLOperations.removeAdmin(userId);

    res.json({
      success: true,
      message: '删除管理员成功',
    });
  })
);

// 获取系统配置
router.get(
  '/config',
  catchAsync(async (req, res) => {
    const configs = await AdminSQLOperations.getAllSystemConfig();
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
    const { key } = req.params;
    const { value, description } = req.body;

    if (!value) {
      throw new AppError('配置值不能为空', 400);
    }

    await AdminSQLOperations.setSystemConfig(key, value, description);

    res.json({
      success: true,
      message: '配置更新成功',
      data: { key, value, description },
    });
  })
);

// ==================== 管理员会员管理接口 ====================

// 管理员添加会员
router.post(
  '/add-membership',
  body('playerName').notEmpty().withMessage('玩家名不能为空'),
  body('days').isInt({ min: 1, max: 365 }).withMessage('天数必须在1-365之间'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { playerName, days } = req.body;

    const user = await AdminSQLOperations.getUserByUsername(playerName);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    const dailyReward = parseInt((await AdminSQLOperations.getSystemConfig('membership_daily_reward')) || '100');
    const result = await AdminSQLOperations.buyMembership(user.id, days, dailyReward);

    res.json({
      success: true,
      message: `成功为用户 ${playerName} 添加 ${days} 天会员`,
      data: result,
    });
  })
);

// 管理员取消会员
router.post(
  '/cancel-membership',
  body('playerName').notEmpty().withMessage('玩家名不能为空'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { playerName } = req.body;

    const user = await AdminSQLOperations.getUserByUsername(playerName);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    const result = await AdminSQLOperations.cancelMembership(user.id);

    res.json({
      success: true,
      message: `成功取消用户 ${playerName} 的会员`,
      data: result,
    });
  })
);

// 管理员延长会员
router.post(
  '/extend-membership',
  body('playerName').notEmpty().withMessage('玩家名不能为空'),
  body('days').isInt({ min: 1, max: 365 }).withMessage('天数必须在1-365之间'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { playerName, days } = req.body;

    const user = await AdminSQLOperations.getUserByUsername(playerName);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    const result = await AdminSQLOperations.extendMembership(user.id, days);

    res.json({
      success: true,
      message: `成功为用户 ${playerName} 延长 ${days} 天会员`,
      data: result,
    });
  })
);

// 管理员获取用户会员状态
router.get(
  '/membership-status/:playerName',
  catchAsync(async (req, res) => {
    const { playerName } = req.params;

    const user = await AdminSQLOperations.getUserByUsername(playerName);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    const membershipStatus = await AdminSQLOperations.getMembershipStatus(user.id);

    res.json({
      success: true,
      data: membershipStatus,
    });
  })
);

// 管理员获取所有会员列表
router.get(
  '/members-list',
  query('page').optional().isInt({ min: 1 }).withMessage('页码必须是正整数'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('限制数量必须在1-100之间'),
  query('status').optional().isIn(['all', 'active', 'expired']).withMessage('状态参数无效'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { page = 1, limit = 20, status = 'all' } = req.query;
    const membersList = await AdminSQLOperations.getMembersList(page, limit, status);

    res.json({
      success: true,
      data: membersList,
    });
  })
);

// 管理员获取所有用户及其会员状态（包括统计数据）
router.get(
  '/all-users-membership',
  query('page').optional().isInt({ min: 1 }).withMessage('页码必须是正整数'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('限制数量必须在1-100之间'),
  query('status').optional().isIn(['all', 'member', 'expired', 'non_member']).withMessage('状态参数无效'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { page = 1, limit = 50, status = 'all' } = req.query;
    const usersWithMembership = await AdminSQLOperations.getAllUsersWithMembershipStatus(page, limit, status);

    // 批量获取用户统计数据
    if (usersWithMembership?.users?.length > 0) {
      const userIds = usersWithMembership.users.map((user) => user.user_id);
      const userStats = await AdminSQLOperations.getBatchUserStats(userIds);

      usersWithMembership.users.forEach((user) => {
        const stats = userStats[user.user_id] || { buy_count: 0, sell_count: 0, total_spent: 0, total_earned: 0 };
        Object.assign(user, stats);
      });
    }

    res.json({
      success: true,
      data: usersWithMembership,
      message: '获取用户会员状态成功',
    });
  })
);

// 管理员批量操作会员
router.post(
  '/batch-membership',
  body('playerNames').isArray().withMessage('玩家名列表必须是数组'),
  body('action').isIn(['add', 'cancel', 'extend']).withMessage('无效的操作类型'),
  body('days').optional().isInt({ min: 1, max: 365 }).withMessage('天数必须在1-365之间'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { playerNames, action, days } = req.body;

    if (playerNames.length === 0) {
      throw new AppError('玩家名列表不能为空', 400);
    }

    if ((action === 'add' || action === 'extend') && !days) {
      throw new AppError('添加或延长会员时必须指定天数', 400);
    }

    const results = [];
    const dailyReward = parseInt((await AdminSQLOperations.getSystemConfig('membership_daily_reward')) || '100');

    for (const playerName of playerNames) {
      try {
        const user = await AdminSQLOperations.getUserByUsername(playerName);
        if (!user) {
          results.push({ playerName, success: false, message: '用户不存在' });
          continue;
        }

        let result;
        switch (action) {
          case 'add':
            result = await AdminSQLOperations.buyMembership(user.id, days, dailyReward);
            break;
          case 'cancel':
            result = await AdminSQLOperations.cancelMembership(user.id);
            break;
          case 'extend':
            result = await AdminSQLOperations.extendMembership(user.id, days);
            break;
        }

        results.push({ playerName, success: true, data: result });
      } catch (error) {
        results.push({ playerName, success: false, message: error.message });
      }
    }

    res.json({
      success: true,
      message: `批量操作完成`,
      data: results,
    });
  })
);

// 管理员更新会员信息
router.put(
  '/update-membership',
  body('playerName').notEmpty().withMessage('玩家名不能为空'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { playerName, membershipType, status, endDate } = req.body;

    const user = await AdminSQLOperations.getUserByUsername(playerName);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    const result = await AdminSQLOperations.updateMembershipInfo(user.id, {
      membershipType,
      status,
      endDate,
    });

    res.json({
      success: true,
      message: `成功更新用户 ${playerName} 的会员信息`,
      data: result,
    });
  })
);

// 删除了复杂的manage-user-membership函数 - 使用专用的add/cancel/extend函数代替

// 管理员获取用户会员奖励记录
router.get(
  '/membership-rewards/:playerName',
  catchAsync(async (req, res) => {
    const { playerName } = req.params;

    const user = await AdminSQLOperations.getUserByUsername(playerName);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    const rewards = await AdminSQLOperations.getMembershipRewards(user.id);

    res.json({
      success: true,
      data: rewards,
    });
  })
);

// 管理员获取会员统计
router.get(
  '/membership-stats',
  catchAsync(async (req, res) => {
    const stats = await AdminSQLOperations.getMembershipStats();

    res.json({
      success: true,
      data: stats,
    });
  })
);

// ==================== 管理员商品管理接口 ====================

// 获取所有商品（管理员视图，包含详细信息）
router.get(
  '/items',
  catchAsync(async (req, res) => {
    const items = await AdminSQLOperations.getItems();

    // 按分类组织商品
    const itemsByCategory = {};
    const categories = new Set();

    items.forEach((item) => {
      if (!itemsByCategory[item.category]) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category].push(item);
      categories.add(item.category);
    });

    res.json({
      success: true,
      message: '获取商品列表成功',
      data: {
        items,
        itemsByCategory,
        categories: Array.from(categories),
        totalItems: items.length,
      },
    });
  })
);

// 获取单个商品详情（管理员视图）
router.get(
  '/items/:itemId',
  catchAsync(async (req, res) => {
    const { itemId } = req.params;

    const item = await AdminSQLOperations.getItem(itemId);

    if (!item) {
      throw new AppError('商品不存在', 404);
    }

    // 获取该商品的交易统计
    const stats = await AdminSQLOperations.getItemStats(itemId);

    res.json({
      success: true,
      message: '获取商品详情成功',
      data: {
        item,
        stats: stats.reduce((acc, stat) => {
          acc[stat.type] = {
            transactionCount: stat.transaction_count,
            totalQuantity: stat.total_quantity,
            avgPrice: stat.avg_price,
          };
          return acc;
        }, {}),
      },
    });
  })
);

module.exports = router;
