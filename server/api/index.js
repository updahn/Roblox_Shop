/**
 * 商店系统 API 服务器主入口
 *
 * 提供完整的RESTful API服务，包括：
 * - 用户认证和授权管理
 * - 商品购买和销售功能
 * - 库存和交易记录管理
 * - 会员系统和每日奖励
 * - 管理员功能和数据统计
 * - 系统配置和监控接口
 *
 * 技术栈：
 * - Express.js - Web应用框架
 * - MySQL2 - 数据库连接和操作
 * - JWT - 身份认证和授权
 * - Winston - 日志管理
 * - Helmet - 安全防护
 *
 * 安全特性：
 * - CORS跨域支持
 * - 请求频率限制
 * - SQL注入防护
 * - 输入验证和清理
 * - 错误信息脱敏
 *
 * @author Shop System Team
 * @version 1.0.0
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// 核心服务和配置
const logger = require('./utils/logger');
const database = require('./config/database');
const { errorHandler } = require('./middleware/errorHandler');
const UserSQLOperations = require('./services/userSQLOperations');
const AdminSQLOperations = require('./services/adminSQLOperations');

// API路由模块
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const adminRoutes = require('./routes/admin');
const itemRoutes = require('./routes/items');

const app = express();
const PORT = process.env.API_SERVER_PORT || 3001;

// ==================== 基础配置 ====================

/**
 * 信任代理设置
 * 解决反向代理环境下的X-Forwarded-For警告
 * 确保获取真实客户端IP地址
 */
app.set('trust proxy', true);

// ==================== 安全中间件配置 ====================

/**
 * Helmet安全中间件
 * 设置各种HTTP头来保护应用程序免受常见攻击
 * - 防止点击劫持攻击
 * - 防止MIME类型嗅探
 * - XSS保护
 */
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);

/**
 * CORS跨域资源共享配置
 * 允许不同域名的前端应用访问API
 * 支持发送认证信息（cookies、authorization headers）
 */
app.use(
  cors({
    credentials: true,
  })
);

// ==================== 请求处理中间件 ====================

/**
 * 响应压缩中间件
 * 自动压缩响应内容，减少网络传输时间
 */
app.use(compression());

/**
 * JSON请求体解析
 * 支持最大10MB的JSON载荷，适合处理大型数据
 */
app.use(express.json({ limit: '10mb' }));

/**
 * URL编码请求体解析
 * 支持嵌套对象解析
 */
app.use(express.urlencoded({ extended: true }));

/**
 * HTTP请求日志记录
 * 使用Winston日志系统记录所有API请求
 * 包含请求方法、URL、状态码、响应时间等信息
 */
app.use(
  morgan('combined', {
    stream: {
      write: (message) => logger.info(`HTTP请求: ${message.trim()}`),
    },
  })
);

// ==================== 动态请求频率限制 ====================

/**
 * 创建动态请求频率限制器
 *
 * 从数据库读取配置参数，实现可动态调整的API请求频率控制。
 * 防止恶意请求和DDoS攻击，保护服务器资源。
 *
 * 配置参数：
 * - rate_limit_window_ms: 时间窗口（毫秒）
 * - rate_limit_max_requests: 窗口内最大请求数
 *
 * 默认配置：
 * - 时间窗口: 15分钟 (900000ms)
 * - 最大请求: 100次
 *
 * @returns {Function} Express中间件函数
 */
async function createDynamicRateLimiter() {
  try {
    // 从数据库获取动态配置
    const windowMs = (await AdminSQLOperations.getSystemConfig('rate_limit_window_ms')) || 15 * 60 * 1000;
    const maxRequests = (await AdminSQLOperations.getSystemConfig('rate_limit_max_requests')) || 100;

    logger.info('动态请求限制配置加载成功:', {
      windowMs: parseInt(windowMs),
      maxRequests: parseInt(maxRequests),
      windowMinutes: Math.ceil(parseInt(windowMs) / 60000),
    });

    return rateLimit({
      windowMs: parseInt(windowMs),
      max: parseInt(maxRequests),
      message: {
        error: '请求过于频繁，请稍后再试',
        retryAfter: Math.ceil(parseInt(windowMs) / 60000) + '分钟',
        code: 'RATE_LIMIT_EXCEEDED',
        timestamp: new Date().toISOString(),
      },
      standardHeaders: true, // 返回标准的限制头信息
      legacyHeaders: false, // 不返回旧版本头信息
      // 自定义键生成器（可根据需要修改）
      keyGenerator: (req) => req.ip,
      // 跳过某些请求的限制检查
      skip: (req) => {
        // 健康检查接口不受限制
        return req.path === '/health';
      },
    });
  } catch (error) {
    logger.warn('加载动态请求限制配置失败，使用默认配置:', error.message);
    return rateLimit({
      windowMs: 15 * 60 * 1000, // 15分钟
      max: 100, // 100次请求
      message: {
        error: '请求过于频繁，请稍后再试',
        retryAfter: '15分钟',
        code: 'RATE_LIMIT_EXCEEDED_DEFAULT',
        timestamp: new Date().toISOString(),
      },
      standardHeaders: true,
      legacyHeaders: false,
    });
  }
}

// 应用动态配置的请求限制
createDynamicRateLimiter().then((limiter) => {
  app.use('/api/', limiter);
  logger.info('动态rate limiting配置已加载');
});

// 健康检查
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: 'production',
  });
});

// API 路由
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/items', itemRoutes);

// 配置信息API (供Roblox Studio获取系统配置)
app.get('/api/config', async (req, res) => {
  try {
    const config = await AdminSQLOperations.getAllSystemConfig();
    const adminUsernames = await AdminSQLOperations.getAdminList();

    const adminConfig = {
      usernames: adminUsernames,
    };

    res.json({
      success: true,
      data: {
        system: config,
        admin: adminConfig,
        api_version: '1.0.0',
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    logger.error('获取配置失败:', error);
    res.status(500).json({
      success: false,
      message: '获取配置失败',
    });
  }
});

// 根路径
app.get('/', (req, res) => {
  res.json({
    message: 'Shop System API Server',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      users: '/api/users',
      admin: '/api/admin',
    },
  });
});

/**
 * 404错误处理
 *
 * 处理所有未匹配的路由请求。
 */
app.use('*', (req, res) => {
  res.status(404).json({
    error: '接口不存在',
    path: req.originalUrl,
    method: req.method,
  });
});

/**
 * 全局错误处理中间件
 *
 * 捕获和处理所有未被捕获的错误，确保稳定的错误响应。
 */
app.use(errorHandler);

/**
 * 初始化管理员用户
 * 根据环境变量ADMIN_USERNAMES配置的用户名列表，将对应用户设置为管理员
 */
async function initializeAdminUsers() {
  try {
    const adminUsernames =
      process.env.ADMIN_USERNAMES?.split(',')
        .map((name) => name.trim())
        .filter(Boolean) || [];

    if (adminUsernames.length === 0) {
      logger.info('未配置ADMIN_USERNAMES环境变量，跳过管理员初始化');
      return;
    }

    logger.info(`开始初始化管理员用户: ${adminUsernames.join(', ')}`);

    for (const username of adminUsernames) {
      try {
        // 检查用户是否存在
        const user = await AdminSQLOperations.getUserByUsername(username);

        if (!user) {
          logger.warn(`管理员用户 ${username} 不存在，将在用户首次登录时自动设置为管理员`);
          continue;
        }

        if (!user.is_admin) {
          // 将用户设置为管理员
          await AdminSQLOperations.promoteToAdmin(user.id);
          logger.info(`用户 ${username} 已设置为管理员`);
        } else {
          logger.info(`用户 ${username} 已经是管理员`);
        }
      } catch (error) {
        logger.error(`初始化管理员用户 ${username} 失败:`, error);
      }
    }

    logger.info('管理员用户初始化完成');
  } catch (error) {
    logger.error('初始化管理员用户失败:', error);
  }
}

/**
 * 服务器启动函数 - 弹性启动策略
 *
 * 实现高可用的服务启动机制，确保服务在各种环境下都能稳定启动：
 *
 * 启动流程：
 * 1. 🌐 立即启动HTTP服务器，确保基础服务可用性
 * 2. 🔄 后台异步重试数据库连接，避免启动失败
 * 3. 👑 数据库连接成功后，初始化管理员用户
 * 4. ⚡ 即使数据库暂时不可用，健康检查和静态路由仍可访问
 *
 * 容错特性：
 * - 数据库连接失败不会阻塞服务启动
 * - 支持自定义重试次数和间隔
 * - 提供详细的启动状态日志
 * - 优雅降级，确保核心功能可用
 *
 * 环境变量：
 * - DB_MAX_RETRIES: 数据库连接最大重试次数 (默认: 30)
 * - DB_RETRY_INTERVAL_MS: 重试间隔毫秒数 (默认: 2000)
 *
 * @returns {Promise<void>} 无返回值，但会启动HTTP服务器
 */
async function startServer() {
  // ==================== HTTP服务器启动 ====================

  const server = app.listen(PORT, '0.0.0.0', () => {
    logger.info(`🚀 Shop System API服务器启动成功`);
    logger.info(`📍 监听地址: 0.0.0.0:${PORT}`);
    logger.info(`🌐 运行环境: ${process.env.NODE_ENV || 'production'}`);
    logger.info(`📊 健康检查: http://localhost:${PORT}/health`);
    logger.info(`📚 API文档: http://localhost:${PORT}/api`);
    logger.info(`⚡ 服务就绪，等待请求...`);
  });

  // 处理服务器错误
  server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
      logger.error(`❌ 端口 ${PORT} 已被占用，请检查其他服务或更改端口`);
      process.exit(1);
    } else {
      logger.error('HTTP服务器启动错误:', error);
      process.exit(1);
    }
  });

  // ==================== 数据库连接重试机制 ====================

  const maxRetries = parseInt(process.env.DB_MAX_RETRIES || '30');
  const retryIntervalMs = parseInt(process.env.DB_RETRY_INTERVAL_MS || '2000');
  let attempt = 0;

  logger.info(`📦 开始初始化数据库连接 (最大重试: ${maxRetries}次, 间隔: ${retryIntervalMs}ms)`);

  const tryConnect = async () => {
    attempt += 1;
    try {
      await database.testConnection();
      logger.info(`✅ 数据库连接建立成功 (尝试 ${attempt}/${maxRetries})`);

      // 数据库连接成功后，初始化管理员用户
      logger.info('👑 开始初始化管理员用户配置...');
      await initializeAdminUsers();

      logger.info('🎉 系统完全就绪，所有组件正常运行！');
      return true;
    } catch (err) {
      const remainingRetries = maxRetries - attempt;

      if (attempt < maxRetries) {
        logger.warn(`⚠️  数据库连接失败 (${attempt}/${maxRetries}): ${err.message}`);
        logger.info(`🔄 将在 ${retryIntervalMs / 1000}秒后重试 (剩余 ${remainingRetries} 次)`);
        setTimeout(tryConnect, retryIntervalMs);
      } else {
        logger.error(`❌ 数据库连接失败，已达最大重试次数 (${maxRetries}次)`);
        logger.warn('🚨 服务将继续运行，但数据库相关功能不可用');
        logger.info('💡 请检查数据库配置和网络连接，或重启服务重试');
      }
      return false;
    }
  };

  // 立即开始第一次连接尝试
  tryConnect();
}

// 优雅关闭
process.on('SIGTERM', () => {
  logger.info('收到 SIGTERM 信号，正在关闭服务器...');
  database.close();
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('收到 SIGINT 信号，正在关闭服务器...');
  database.close();
  process.exit(0);
});

startServer();

module.exports = app;
