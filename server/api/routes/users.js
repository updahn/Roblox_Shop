const express = require('express');
const { body, query, validationResult } = require('express-validator');

const SQLOperations = require('../services/sqlOperations');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 所有用户路由都需要认证
router.use(authenticateToken);

// 获取当前用户信息
router.get(
  '/me',
  catchAsync(async (req, res) => {
    const user = await SQLOperations.getUserDetails(req.user.id);

    if (!user) {
      throw new AppError('用户不存在', 404);
    }

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
      },
    });
  })
);

// 获取用户库存
router.get(
  '/inventory',
  catchAsync(async (req, res) => {
    const inventory = await SQLOperations.getUserInventory(req.user.id);

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
      const result = await SQLOperations.buyItem(userId, itemId, quantity);

      // 获取更新后的用户信息
      const updatedUser = await SQLOperations.getUserDetails(userId);

      res.json({
        success: true,
        message: '购买成功',
        data: {
          itemId,
          quantity,
          newCoins: updatedUser.coins,
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
      const result = await SQLOperations.sellItem(userId, itemId, quantity);

      // 获取更新后的用户信息
      const updatedUser = await SQLOperations.getUserDetails(userId);

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
  query('type').optional().isIn(['buy', 'sell', 'admin']).withMessage('交易类型只能是buy、sell或admin'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    const type = req.query.type;

    // 使用SQLOperations获取交易记录
    const transactions = await SQLOperations.getTransactions({
      userId: req.user.id,
      type: type || null,
      limit,
      offset,
    });

    // 获取统计信息
    const stats = await SQLOperations.getUserTransactionStats(req.user.id);

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
    // 使用SQLOperations获取30天交易统计
    const transactionStats = await SQLOperations.getTransactionStats(30);

    // 获取最常购买的商品
    const topItems = await SQLOperations.getUserTopItems(userId, 10);

    // 获取库存价值
    const inventoryValue = await SQLOperations.getUserInventoryValue(userId);

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

module.exports = router;
