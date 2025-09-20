const express = require('express');
const { body, query, validationResult } = require('express-validator');

const UserSQLOperations = require('../services/userSQLOperations');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 所有用户路由都需要认证
router.use(authenticateToken);

// 获取当前用户信息
router.get(
  '/me',
  catchAsync(async (req, res) => {
    const user = await UserSQLOperations.getUserDetails(req.user.id);

    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    // 获取用户会员状态
    const membershipStatus = await UserSQLOperations.getMembershipStatus(req.user.id);

    res.json({
      success: true,
      message: '获取用户信息成功',
      data: {
        id: user.id,
        username: user.username,
        displayName: user.display_name,
        coins: user.coins,
        totalEarned: user.total_earned,
        totalSpent: user.total_spent,
        createdAt: user.created_at,
        lastLogin: user.last_login,
        status: user.status,
        isAdmin: user.is_admin,
        membership: membershipStatus,
      },
    });
  })
);

// 获取用户库存
router.get(
  '/inventory',
  catchAsync(async (req, res) => {
    const inventory = await UserSQLOperations.getUserInventory(req.user.id);

    // 按分类组织库存
    const inventoryByCategory = {};
    inventory.forEach((item) => {
      if (!inventoryByCategory[item.category]) {
        inventoryByCategory[item.category] = [];
      }
      inventoryByCategory[item.category].push(item);
    });

    res.json({
      success: true,
      message: '获取用户库存成功',
      data: {
        inventory,
        inventoryByCategory,
        totalItems: inventory.length,
        totalValue: inventory.reduce((sum, item) => sum + item.actual_sell_price * item.quantity, 0),
      },
    });
  })
);

// 购买商品
router.post(
  '/buy',
  body('itemId').notEmpty().withMessage('商品ID不能为空'),
  body('quantity').isInt({ min: 1 }).withMessage('购买数量必须是正整数'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('输入验证失败', 400);
    }

    const { itemId, quantity } = req.body;
    const userId = req.user.id;

    try {
      let result;

      // 检查是否为会员卡商品
      const membershipItems = ['monthly_membership', 'weekly_membership', 'quarterly_membership', 'premium_membership', 'vip_membership'];
      if (membershipItems.includes(itemId)) {
        result = await UserSQLOperations.buyMembershipItem(userId, itemId, quantity);
      } else {
        result = await UserSQLOperations.buyItem(userId, itemId, quantity);
      }

      // 获取更新后的用户信息
      const updatedUser = await UserSQLOperations.getUserDetails(userId);

      // 如果购买的是会员卡，获取更新后的会员状态
      let membershipStatus = null;
      if (membershipItems.includes(itemId)) {
        membershipStatus = await UserSQLOperations.getMembershipStatus(userId);
      }

      res.json({
        success: true,
        message: '购买成功',
        data: {
          itemId,
          quantity,
          newCoins: updatedUser.coins,
          membership: membershipStatus,
          immediateReward: result.immediateReward || null,
        },
      });
    } catch (error) {
      if (error.message.includes('库存不足')) {
        throw new AppError('商品库存不足', 400, 'INSUFFICIENT_STOCK');
      }
      if (error.message.includes('金币不足')) {
        throw new AppError('金币不足', 400, 'INSUFFICIENT_COINS');
      }
      if (error.message.includes('物品不存在')) {
        throw new AppError('商品不存在或已下架', 404, 'ITEM_NOT_FOUND');
      }
      throw error;
    }
  })
);

// 出售商品
router.post(
  '/sell',
  body('itemId').notEmpty().withMessage('商品ID不能为空'),
  body('quantity').isInt({ min: 1 }).withMessage('出售数量必须是正整数'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('输入验证失败', 400);
    }

    const { itemId, quantity } = req.body;
    const userId = req.user.id;

    try {
      const result = await UserSQLOperations.sellItem(userId, itemId, quantity);

      // 获取更新后的用户信息
      const updatedUser = await UserSQLOperations.getUserDetails(userId);

      res.json({
        success: true,
        message: '出售成功',
        data: {
          itemId,
          quantity,
          newCoins: updatedUser.coins,
        },
      });
    } catch (error) {
      if (error.message.includes('拥有的物品数量不足')) {
        throw new AppError('拥有的物品数量不足', 400, 'INSUFFICIENT_ITEMS');
      }
      throw error;
    }
  })
);

// 获取交易记录
router.get(
  '/transactions',
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('限制数量必须在1-100之间'),
  query('offset').optional().isInt({ min: 0 }).withMessage('偏移量必须大于等于0'),
  query('type').optional().isIn(['buy', 'sell', 'admin', 'daily_reward', 'membership_purchase']).withMessage('交易类型只能是buy、sell、admin、daily_reward或membership_purchase'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    const type = req.query.type;

    // 使用UserSQLOperations获取交易记录
    const transactions = await UserSQLOperations.getTransactions({
      userId: req.user.id,
      type: type || null,
      limit,
      offset,
    });

    // 获取统计信息
    const stats = await UserSQLOperations.getUserTransactionStats(req.user.id);

    res.json({
      success: true,
      message: '获取交易记录成功',
      data: {
        transactions,
        pagination: {
          limit,
          offset,
          count: transactions.length,
        },
        stats: stats.reduce((acc, stat) => {
          acc[stat.type] = {
            count: stat.count,
            totalAmount: stat.total_amount,
          };
          return acc;
        }, {}),
      },
    });
  })
);

// 获取用户统计信息
router.get(
  '/stats',
  catchAsync(async (req, res) => {
    const userId = req.user.id;

    // 获取交易统计
    // 使用UserSQLOperations获取30天交易统计
    const transactionStats = await UserSQLOperations.getTransactionStats(30);

    // 获取最常购买的商品
    const topItems = await UserSQLOperations.getUserTopItems(userId, 10);

    // 获取库存价值
    const inventoryValue = await UserSQLOperations.getUserInventoryValue(userId);

    res.json({
      success: true,
      message: '获取用户统计成功',
      data: {
        transactionStats,
        topItems,
        inventory: inventoryValue,
      },
    });
  })
);

// 获取用户月卡状态
router.get(
  '/membership/status',
  catchAsync(async (req, res) => {
    const membershipStatus = await UserSQLOperations.getMembershipStatus(req.user.id);

    res.json({
      success: true,
      message: '获取月卡状态成功',
      data: membershipStatus,
    });
  })
);

// 处理每日登录奖励
router.post(
  '/membership/claim-rewards',
  catchAsync(async (req, res) => {
    const rewardResult = await UserSQLOperations.processLoginRewards(req.user.id);

    res.json({
      success: rewardResult.success,
      message: rewardResult.success ? '每日奖励领取成功' : rewardResult.message,
      data: rewardResult,
    });
  })
);

// 获取每日购买限制状态
router.get(
  '/daily-purchase/:itemId',
  catchAsync(async (req, res) => {
    const { itemId } = req.params;
    const userId = req.user.id;
    const today = new Date().toISOString().split('T')[0];

    // 获取商品的每日限购信息
    const itemQuery = 'SELECT daily_purchase_limit FROM items WHERE id = ? AND is_active = TRUE';
    const { rows: itemRows } = (await UserSQLOperations.query) || (await require('../config/database').query(itemQuery, [itemId]));

    if (itemRows.length === 0) {
      throw new AppError('商品不存在', 404);
    }

    const dailyLimit = itemRows[0].daily_purchase_limit;

    if (dailyLimit === null) {
      // 无限制
      res.json({
        success: true,
        data: {
          hasLimit: false,
          dailyLimit: null,
          purchasedToday: 0,
          remaining: null,
        },
      });
      return;
    }

    // 查询今日已购买数量（从transactions表统计）
    const dailyPurchaseQuery = `
      SELECT COALESCE(SUM(quantity), 0) as purchased_today
      FROM transactions
      WHERE user_id = ? AND item_id = ? AND transaction_date = ? AND type = 'buy'
    `;

    const database = require('../config/database');
    const { rows: dailyRows } = await database.query(dailyPurchaseQuery, [userId, itemId, today]);
    const purchasedToday = dailyRows.length > 0 ? dailyRows[0].purchased_today : 0;

    res.json({
      success: true,
      data: {
        hasLimit: true,
        dailyLimit,
        purchasedToday,
        remaining: Math.max(0, dailyLimit - purchasedToday),
      },
    });
  })
);

// ==================== 用户商品接口 ====================

// 获取所有商品（用户视图，只显示可用商品）
router.get(
  '/items',
  catchAsync(async (req, res) => {
    const items = await UserSQLOperations.getItems();

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

// 获取系统配置（用户可见的部分）
router.get(
  '/config',
  catchAsync(async (req, res) => {
    const sellRate = await UserSQLOperations.getSellRate();

    res.json({
      success: true,
      message: '获取系统配置成功',
      data: {
        sell_rate: sellRate,
      },
    });
  })
);

// 获取特定分类的商品
router.get(
  '/items/category/:category',
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('限制数量必须在1-100之间'),
  query('offset').optional().isInt({ min: 0 }).withMessage('偏移量必须大于等于0'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { category } = req.params;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    const rows = await UserSQLOperations.getItemsWithOptions({
      category,
      limit,
      offset,
      activeOnly: true,
    });

    res.json({
      success: true,
      message: '获取分类商品成功',
      data: {
        category,
        items: rows,
        count: rows.length,
        limit,
        offset,
      },
    });
  })
);

// 获取单个商品详情
router.get(
  '/items/:itemId',
  catchAsync(async (req, res) => {
    const { itemId } = req.params;

    const item = await UserSQLOperations.getItem(itemId);

    if (!item || !item.is_active) {
      throw new AppError('商品不存在或已下架', 404);
    }

    // 获取该商品的最近交易统计
    const stats = await UserSQLOperations.getItemStats(itemId);

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

// 获取商品库存信息
router.get(
  '/items/:itemId/stock',
  catchAsync(async (req, res) => {
    const { itemId } = req.params;

    const stockInfo = await UserSQLOperations.checkItemStock(itemId);

    if (!stockInfo) {
      throw new AppError('商品不存在或已下架', 404);
    }

    res.json({
      success: true,
      message: '获取库存信息成功',
      data: stockInfo,
    });
  })
);

// 搜索商品
router.get(
  '/items/search',
  query('q').notEmpty().withMessage('搜索关键词不能为空'),
  query('category').optional().isString().withMessage('分类必须是字符串'),
  query('minPrice').optional().isInt({ min: 0 }).withMessage('最小价格必须大于等于0'),
  query('maxPrice').optional().isInt({ min: 0 }).withMessage('最大价格必须大于等于0'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('限制数量必须在1-100之间'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { q, category, minPrice, maxPrice } = req.query;
    const limit = parseInt(req.query.limit) || 20;

    // 使用UserSQLOperations搜索商品，目前暂不支持价格过滤
    const rows = await UserSQLOperations.getItemsWithOptions({
      search: q,
      category,
      limit,
      activeOnly: true,
    });

    // 如果有价格过滤，需要在内存中进行过滤
    let filteredRows = rows;
    if (minPrice !== undefined || maxPrice !== undefined) {
      filteredRows = rows.filter((item) => {
        if (minPrice !== undefined && item.price < parseInt(minPrice)) return false;
        if (maxPrice !== undefined && item.price > parseInt(maxPrice)) return false;
        return true;
      });
    }

    res.json({
      success: true,
      message: '搜索完成',
      data: {
        query: q,
        filters: {
          category,
          minPrice: minPrice ? parseInt(minPrice) : null,
          maxPrice: maxPrice ? parseInt(maxPrice) : null,
        },
        items: filteredRows,
        count: filteredRows.length,
      },
    });
  })
);

module.exports = router;
