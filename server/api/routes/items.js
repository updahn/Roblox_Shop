const express = require('express');
const { query, validationResult } = require('express-validator');

const AdminSQLOperations = require('../services/adminSQLOperations');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 获取商品列表 (公开接口，不需要认证)
router.get(
  '/',
  [query('page').optional().isInt({ min: 1 }).withMessage('页码必须是正整数'), query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('每页数量必须在1-100之间'), query('category').optional().isString().withMessage('分类必须是字符串'), query('is_active').optional().isBoolean().withMessage('is_active必须是布尔值')],
  catchAsync(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('参数验证失败', 400, errors.array());
    }

    const { page = 1, limit = 20, category, is_active = true } = req.query;

    // 确保 is_active 参数被正确处理
    const activeFilter = is_active === 'false' ? false : true;

    try {
      const items = await AdminSQLOperations.getItemsList(parseInt(page), parseInt(limit), category, activeFilter);

      res.json({
        success: true,
        message: '获取商品列表成功',
        data: items,
      });
    } catch (error) {
      console.error('获取商品列表错误:', {
        page,
        limit,
        category,
        activeFilter,
        error: error.message,
        stack: error.stack,
      });

      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError(`获取商品列表失败: ${error.message}`, 500);
    }
  })
);

// 获取商品详情
router.get(
  '/:id',
  catchAsync(async (req, res) => {
    const { id } = req.params;

    try {
      const item = await AdminSQLOperations.getItemById(id);

      if (!item) {
        throw new AppError('商品不存在', 404);
      }

      res.json({
        success: true,
        message: '获取商品详情成功',
        data: item,
      });
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('获取商品详情失败', 500);
    }
  })
);

// 获取商品分类列表
router.get(
  '/categories/list',
  catchAsync(async (req, res) => {
    try {
      const categories = await AdminSQLOperations.getItemCategories();

      res.json({
        success: true,
        message: '获取商品分类成功',
        data: categories,
      });
    } catch (error) {
      throw new AppError('获取商品分类失败', 500);
    }
  })
);

module.exports = router;
