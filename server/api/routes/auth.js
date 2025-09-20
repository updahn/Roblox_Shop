const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const UserSQLOperations = require('../services/userSQLOperations');
const AdminSQLOperations = require('../services/adminSQLOperations');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { isUserAdmin } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// 验证中间件
const validateAuth = [body('userId').notEmpty().withMessage('用户ID不能为空'), body('username').notEmpty().withMessage('用户名不能为空'), body('displayName').optional().isString().withMessage('显示名称必须是字符串')];

// 用户登录/注册
router.post(
  '/login',
  validateAuth,
  catchAsync(async (req, res) => {
    // 检查验证结果
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('输入验证失败', 400, 'VALIDATION_ERROR');
    }

    const { userId, username, displayName } = req.body;

    try {
      // 创建或更新用户并获取详细信息
      const result = await UserSQLOperations.createOrLoginUser(userId, username, displayName);

      if (!result || !result.user) {
        throw new AppError('用户创建失败', 500);
      }

      const user = result.user;

      // 生成JWT token
      const token = jwt.sign(
        {
          userId: user.id,
          username: user.username,
        },
        process.env.JWT_SECRET || 'default-secret',
        {
          expiresIn: '7d',
          issuer: 'shop-system',
        }
      );

      logger.info(`用户登录成功: ${userId} (${username})`);

      res.json({
        success: true,
        message: '登录成功',
        data: {
          token,
          user: {
            id: user.id,
            username: user.username,
            displayName: user.display_name,
            coins: user.coins,
            totalEarned: user.total_earned,
            totalSpent: user.total_spent,
            createdAt: user.created_at,
            lastLogin: user.last_login,
            isAdmin: user.is_admin,
          },
        },
      });
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      logger.error('登录过程中发生错误:', error);
      throw new AppError('登录失败，请稍后重试', 500);
    }
  })
);

// 验证token
router.post(
  '/verify',
  catchAsync(async (req, res) => {
    const { token } = req.body;

    if (!token) {
      throw new AppError('Token不能为空', 400);
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default-secret');

      // 获取最新用户信息
      const user = await UserSQLOperations.getUserDetails(decoded.userId);

      if (!user) {
        throw new AppError('用户不存在', 404);
      }

      res.json({
        success: true,
        message: 'Token验证成功',
        data: {
          valid: true,
          user: {
            id: user.id,
            username: user.username,
            displayName: user.display_name,
            coins: user.coins,
            totalEarned: user.total_earned,
            totalSpent: user.total_spent,
            isAdmin: user.is_admin,
          },
        },
      });
    } catch (error) {
      if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
        throw new AppError('Token无效或已过期', 401);
      }
      throw error;
    }
  })
);

// Token刷新
router.post(
  '/refresh',
  catchAsync(async (req, res) => {
    const { token } = req.body;

    if (!token) {
      throw new AppError('Token不能为空', 400);
    }

    try {
      // 验证token（即使过期也要能解析）
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default-secret', { ignoreExpiration: true });

      // 检查用户是否存在
      const user = await UserSQLOperations.getUserDetails(decoded.userId);
      if (!user) {
        throw new AppError('用户不存在', 404);
      }

      // 生成新token
      const newToken = jwt.sign(
        {
          userId: user.id,
          username: user.username,
        },
        process.env.JWT_SECRET || 'default-secret',
        {
          expiresIn: '7d',
          issuer: 'shop-system',
        }
      );

      res.json({
        success: true,
        message: 'Token刷新成功',
        data: {
          token: newToken,
          user: {
            id: user.id,
            username: user.username,
            displayName: user.display_name,
            coins: user.coins,
          },
        },
      });
    } catch (error) {
      if (error.name === 'JsonWebTokenError') {
        throw new AppError('Token格式无效', 401);
      }
      throw error;
    }
  })
);

// 获取用户状态
router.get(
  '/status',
  catchAsync(async (req, res) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.json({
        success: true,
        data: {
          authenticated: false,
        },
      });
    }

    const token = authHeader.substring(7);

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default-secret');
      const user = await UserSQLOperations.getUserDetails(decoded.userId);

      if (!user) {
        return res.json({
          success: true,
          data: {
            authenticated: false,
          },
        });
      }

      res.json({
        success: true,
        data: {
          authenticated: true,
          user: {
            id: user.id,
            username: user.username,
            displayName: user.display_name,
            coins: user.coins,
            isAdmin: user.is_admin,
          },
        },
      });
    } catch (error) {
      res.json({
        success: true,
        data: {
          authenticated: false,
        },
      });
    }
  })
);

// 检查用户管理员权限（专为Roblox客户端设计）
router.post(
  '/check-admin',
  [body('userId').notEmpty().withMessage('用户ID不能为空')],
  catchAsync(async (req, res) => {
    // 检查验证结果
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('输入验证失败', 400, 'VALIDATION_ERROR');
    }

    const { userId } = req.body;

    try {
      // 检查用户是否存在并获取管理员权限
      const user = await AdminSQLOperations.checkUserExists(userId, true);

      if (!user) {
        logger.info(`管理员权限检查: 用户${userId} - 用户不存在`);
        return res.json({
          success: true,
          data: {
            userId: userId,
            isAdmin: false,
            user: null,
            message: '用户不存在',
          },
        });
      }

      res.json({
        success: true,
        data: {
          userId: userId,
          isAdmin: user.is_admin,
          user: {
            id: user.id,
            username: user.username,
            displayName: user.display_name,
          },
        },
      });
    } catch (error) {
      logger.error('检查管理员权限时发生错误:', error);

      // 出错时返回false，确保安全
      res.json({
        success: true,
        data: {
          userId: userId,
          isAdmin: false,
          error: '权限检查失败',
        },
      });
    }
  })
);

module.exports = router;
