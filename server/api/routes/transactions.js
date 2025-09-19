const express = require('express');
const { query, validationResult } = require('express-validator');

const SQLOperations = require('../services/sqlOperations');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { authenticateToken, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// 获取交易统计（公开接口）
router.get(
  '/stats',
  query('days').optional().isInt({ min: 1, max: 365 }).withMessage('天数必须在1-365之间'),
  optionalAuth,
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const days = parseInt(req.query.days) || 7;

    const stats = await SQLOperations.getTransactionStats(days);

    // 计算汇总数据
    const summary = {
      buy: { count: 0, totalAmount: 0 },
      sell: { count: 0, totalAmount: 0 },
    };

    stats.forEach((stat) => {
      summary[stat.type].count += stat.count;
      summary[stat.type].totalAmount += stat.total_amount;
    });

    res.json({
      success: true,
      message: '获取交易统计成功',
      data: {
        period: `${days}天`,
        stats,
        summary,
        netFlow: summary.sell.totalAmount - summary.buy.totalAmount,
      },
    });
  })
);

// 获取热门商品（基于交易量）
router.get(
  '/popular-items',
  query('type').optional().isIn(['buy', 'sell']).withMessage('交易类型只能是buy或sell'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('限制数量必须在1-50之间'),
  query('days').optional().isInt({ min: 1, max: 365 }).withMessage('天数必须在1-365之间'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const type = req.query.type;
    const limit = parseInt(req.query.limit) || 10;
    const days = parseInt(req.query.days) || 7;

    const rows = await SQLOperations.getPopularItems({ type, limit, days });

    res.json({
      success: true,
      message: '获取热门商品成功',
      data: {
        period: `${days}天`,
        type: type || 'all',
        items: rows,
        count: rows.length,
      },
    });
  })
);

// 获取价格趋势
router.get(
  '/price-trends/:itemId',
  query('days').optional().isInt({ min: 1, max: 365 }).withMessage('天数必须在1-365之间'),
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400);
    }

    const { itemId } = req.params;
    const days = parseInt(req.query.days) || 30;

    // 获取商品信息
    const item = await SQLOperations.getItem(itemId);

    if (!item) {
      throw new AppError('商品不存在', 404);
    }

    // 获取价格趋势数据
    const trends = await SQLOperations.getItemPriceTrends(itemId, days);

    res.json({
      success: true,
      message: '获取价格趋势成功',
      data: {
        item,
        period: `${days}天`,
        trends,
        currentPrices: {
          buy: item.price,
          sell: item.sell_price || Math.floor(item.price * (await SQLOperations.getSellRate())),
        },
      },
    });
  })
);

// 获取交易详情（需要认证）
router.get(
  '/:transactionId',
  authenticateToken,
  catchAsync(async (req, res) => {
    const { transactionId } = req.params;

    const transaction = await SQLOperations.getTransactionDetails(transactionId, req.user.id);

    if (!transaction) {
      throw new AppError('交易记录不存在或无权访问', 404);
    }

    res.json({
      success: true,
      message: '获取交易详情成功',
      data: transaction,
    });
  })
);

// 获取市场活动摘要
router.get(
  '/market/summary',
  catchAsync(async (req, res) => {
    // 获取今日交易统计
    const todayStats = await SQLOperations.getTodayMarketStats();

    // 获取活跃商品数量
    const activeItemsCount = await SQLOperations.getActiveItemsCount();

    // 获取最新交易
    const recentTransactions = await SQLOperations.getRecentTransactions(10);

    const summary = {
      buy: { count: 0, totalAmount: 0, totalQuantity: 0 },
      sell: { count: 0, totalAmount: 0, totalQuantity: 0 },
    };

    todayStats.forEach((stat) => {
      summary[stat.type] = {
        count: stat.count,
        totalAmount: stat.total_amount,
        totalQuantity: stat.total_quantity,
      };
    });

    res.json({
      success: true,
      message: '获取市场活动摘要成功',
      data: {
        today: summary,
        activeItems: activeItemsCount,
        recentTransactions,
        timestamp: new Date().toISOString(),
      },
    });
  })
);

module.exports = router;
