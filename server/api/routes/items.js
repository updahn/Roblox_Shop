const express = require('express');
const { query, validationResult } = require('express-validator');

const SQLOperations = require('../services/sqlOperations');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 获取所有商品
router.get(
  '/',
  catchAsync(async (req, res) => {
    const items = await SQLOperations.getItems();

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

// 获取系统配置
router.get(
  '/config',
  catchAsync(async (req, res) => {
    const sellRate = await SQLOperations.getSellRate();

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
  '/category/:category',
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

    const rows = await SQLOperations.getItemsWithOptions({
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
  '/:itemId',
  catchAsync(async (req, res) => {
    const { itemId } = req.params;

    const item = await SQLOperations.getItem(itemId);

    if (!item || !item.is_active) {
      throw new AppError('商品不存在或已下架', 404);
    }

    // 获取该商品的最近交易统计
    const stats = await SQLOperations.getItemStats(itemId);

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

// 获取商品库存信息（需要认证）
router.get(
  '/:itemId/stock',
  authenticateToken,
  catchAsync(async (req, res) => {
    const { itemId } = req.params;

    const stockInfo = await SQLOperations.checkItemStock(itemId);

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
  '/search',
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

    // 使用SQLOperations搜索商品，目前暂不支持价格过滤
    const rows = await SQLOperations.getItemsWithOptions({
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
