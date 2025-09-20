const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const logger = require('./utils/logger');
const database = require('./config/database');
const { errorHandler } = require('./middleware/errorHandler');
const UserSQLOperations = require('./services/userSQLOperations');
const AdminSQLOperations = require('./services/adminSQLOperations');

// 路由模块
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const adminRoutes = require('./routes/admin');
const itemRoutes = require('./routes/items');

const app = express();
const PORT = process.env.API_SERVER_PORT || 3001;

// 信任代理设置 (解决 X-Forwarded-For 警告)
app.set('trust proxy', true);

// 中间件配置
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);

app.use(
  cors({
    credentials: true,
  })
);

app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 日志中间件
app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));

// 动态请求限制配置
async function createDynamicRateLimiter() {
  try {
    const windowMs = (await AdminSQLOperations.getSystemConfig('rate_limit_window_ms')) || 15 * 60 * 1000;
    const maxRequests = (await AdminSQLOperations.getSystemConfig('rate_limit_max_requests')) || 100;

    return rateLimit({
      windowMs: parseInt(windowMs),
      max: parseInt(maxRequests),
      message: {
        error: '请求过于频繁，请稍后再试',
        retryAfter: Math.ceil(parseInt(windowMs) / 60000) + '分钟',
      },
      standardHeaders: true,
      legacyHeaders: false,
    });
  } catch (error) {
    logger.warn('加载动态rate limiting配置失败，使用默认值:', error);
    return rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 100,
      message: {
        error: '请求过于频繁，请稍后再试',
        retryAfter: '15分钟',
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
 * 服务器启动函数
 *
 * 采用弹性启动策略：
 * 1. 先启动HTTP服务器，确保基本服务可用
 * 2. 后台异步重试数据库连接
 * 3. 即使数据库暂时不可用也不会崩溃
 *
 * 这种设计提高了系统的可用性和容错性。
 */
async function startServer() {
  // 先启动 HTTP 服务器
  app.listen(PORT, '0.0.0.0', () => {
    logger.info(`🚀 API服务器启动成功，端口: ${PORT}`);
    logger.info(`🌐 环境: production`);
    logger.info(`📊 健康检查: http://localhost:${PORT}/health`);
  });

  // 后台重试数据库连接，避免容器因数据库未就绪而退出
  const maxRetries = parseInt(process.env.DB_MAX_RETRIES || '30');
  const retryIntervalMs = parseInt(process.env.DB_RETRY_INTERVAL_MS || '2000');
  let attempt = 0;

  const tryConnect = async () => {
    attempt += 1;
    try {
      await database.testConnection();
      logger.info('数据库连接成功');

      // 初始化管理员用户
      await initializeAdminUsers();

      return true;
    } catch (err) {
      logger.warn(`数据库未就绪，稍后重试 (#${attempt}/${maxRetries}): ${err.message}`);
      if (attempt >= maxRetries) {
        logger.error('数据库重试连接失败，达到最大重试次数，继续运行以供健康检查/静态路由使用');
        return false;
      }
      setTimeout(tryConnect, retryIntervalMs);
      return false;
    }
  };

  // 立即尝试一次
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
