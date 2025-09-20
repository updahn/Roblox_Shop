/**
 * 认证中间件模块
 *
 * 提供JWT token验证和管理员权限检查功能。
 * 支持多层级的权限管理：
 * 1. 数据库is_admin字段（最高优先级）
 * 2. 环境变量中的管理员列表
 */
const jwt = require('jsonwebtoken');
const { AppError } = require('./errorHandler');
const database = require('../config/database');
const AdminSQLOperations = require('../services/adminSQLOperations');
const UserSQLOperations = require('../services/userSQLOperations');

/**
 * JWT Token认证中间件
 *
 * 验证HTTP请求头中的JWT token，并将用户信息添加到请求对象中。
 * 要求请求头包含: Authorization: Bearer <token>
 *
 * @param {Object} req - Express请求对象
 * @param {Object} res - Express响应对象
 * @param {Function} next - Express下一个中间件
 */
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('未提供认证token', 401);
    }

    const token = authHeader.substring(7);

    // 验证JWT token，确保JWT_SECRET环境变量已配置
    if (!process.env.JWT_SECRET) {
      throw new AppError('JWT密钥未配置', 500);
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 验证 JWT payload 中的 userId 字段
    if (!decoded.userId || decoded.userId === undefined || decoded.userId === null) {
      throw new AppError('Token中缺少用户ID', 401);
    }

    // 检查用户是否存在
    const user = await UserSQLOperations.getUserDetails(decoded.userId);
    if (!user) {
      throw new AppError('用户不存在', 404);
    }

    // 将用户信息添加到请求对象
    req.user = {
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      coins: user.coins,
      totalEarned: user.total_earned,
      totalSpent: user.total_spent,
    };

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return next(new AppError('Token无效', 401));
    }
    if (error.name === 'TokenExpiredError') {
      return next(new AppError('Token已过期', 401));
    }
    next(error);
  }
};

/**
 * 检查用户管理员权限
 *
 * 按以下优先级检查管理员权限：
 * 1. 数据库users表中is_admin字段
 * 2. 环境变量ADMIN_USERNAMES中的用户名列表
 *
 * @param {number|string} userId - 用户ID
 * @param {string} username - 用户名
 * @returns {boolean} 是否为管理员
 */
const isUserAdmin = async (userId, username) => {
  try {
    const user = await AdminSQLOperations.checkUserExists(userId, true);
    // checkUserExists已经转换is_admin为布尔值，直接使用即可
    return user ? user.is_admin : false;
  } catch (error) {
    console.error('检查管理员权限时发生错误:', error);
    return false;
  }
};

/**
 * 管理员权限认证中间件
 *
 * 先执行普通用户认证，然后检查是否具有管理员权限。
 * 只有管理员才能通过此中间件。
 *
 * @param {Object} req - Express请求对象
 * @param {Object} res - Express响应对象
 * @param {Function} next - Express下一个中间件
 */
const authenticateAdmin = async (req, res, next) => {
  try {
    // 先进行普通用户认证
    await new Promise((resolve, reject) => {
      authenticateToken(req, res, (err) => {
        if (err) reject(err);
        else resolve();
      });
    });

    // 检查是否为管理员
    const isAdmin = await isUserAdmin(req.user.id, req.user.username);
    if (!isAdmin) {
      throw new AppError('需要管理员权限', 403);
    }

    // 标记为管理员
    req.user.isAdmin = true;
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * 可选认证中间件
 *
 * 如果请求包含有效的JWT token则解析用户信息，
 * 否则静默忽略继续处理。不会抛出认证错误。
 *
 * @param {Object} req - Express请求对象
 * @param {Object} res - Express响应对象
 * @param {Function} next - Express下一个中间件
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.substring(7);

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // 验证 JWT payload 中的 userId 字段
      if (!decoded.userId || decoded.userId === undefined || decoded.userId === null) {
        return next(); // 可选认证中，token无效时静默忽略
      }

      const user = await UserSQLOperations.getUserDetails(decoded.userId);

      if (user) {
        req.user = {
          id: user.id,
          username: user.username,
          displayName: user.display_name,
          coins: user.coins,
        };
      }
    } catch (tokenError) {
      // Token无效时忽略错误，继续处理请求
    }

    next();
  } catch (error) {
    next(error);
  }
};

module.exports = {
  authenticateToken,
  authenticateAdmin,
  optionalAuth,
  isUserAdmin,
};
