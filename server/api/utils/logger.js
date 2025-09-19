/**
 * 统一日志系统
 *
 * 使用Winston库实现的统一日志管理系统。
 * 支持多种输出目标（控制台、文件）和不同日志级别。
 *
 * 特点：
 * - 默认使用生产环境配置
 * - 支持结构化日志输出
 * - 容器环境优化（依赖stdout输出）
 * - 错误堆栈跟踪
 */
const winston = require('winston');
const path = require('path');

/**
 * 日志格式化配置
 *
 * 统一的日志格式，包含时间戳、错误堆栈和自定义格式。
 */
const logFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss',
  }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ level, message, timestamp, stack }) => {
    return `${timestamp} [${level.toUpperCase()}]: ${stack || message}`;
  })
);

/**
 * 日志输出目标配置
 *
 * 构建所有可用的日志输出目标。
 * 优先保证控制台输出可用，文件输出不可用时不会崩溃。
 */
const transports = [];

/**
 * 控制台输出格式
 *
 * 默认使用生产环境日志格式。
 * 在容器环境中，依赖stdout进行日志收集。
 */
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ level, message, timestamp, stack }) => `${timestamp} [${level.toUpperCase()}]: ${stack || message}`)
);

transports.push(
  new winston.transports.Console({
    format: consoleFormat,
  })
);

/**
 * 尝试添加文件输出
 *
 * 如果可能，会添加文件日志输出。
 * 如果文件不可写，会忽略错误并继续使用控制台输出。
 */
try {
  const combinedFile = new winston.transports.File({
    filename: path.join(__dirname, '../logs/combined.log'),
    maxsize: 10485760, // 10MB
    maxFiles: 5,
  });
  combinedFile.on('error', (err) => {
    // eslint-disable-next-line no-console
    console.error('文件日志写入错误(combined):', err.message);
  });
  transports.push(combinedFile);

  const errorFile = new winston.transports.File({
    filename: path.join(__dirname, '../logs/error.log'),
    level: 'error',
    maxsize: 10485760, // 10MB
    maxFiles: 3,
  });
  errorFile.on('error', (err) => {
    // eslint-disable-next-line no-console
    console.error('文件日志写入错误(error):', err.message);
  });
  transports.push(errorFile);
} catch (e) {
  // eslint-disable-next-line no-console
  console.error('初始化文件日志失败，将仅输出到控制台:', e.message);
}

// 创建 winston logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  defaultMeta: { service: 'shop-api' },
  transports,
});

// 处理未捕获的异常和拒绝
process.on('uncaughtException', (error) => {
  logger.error('未捕获的异常:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('未处理的Promise拒绝:', reason);
});

module.exports = logger;
