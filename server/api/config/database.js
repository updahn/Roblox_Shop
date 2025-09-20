/**
 * 数据库连接配置模块
 *
 * 使用MySQL2库创建连接池，支持Promise和连接池管理。
 * 自动检测运行环境并选择合适的数据库主机地址。
 *
 * 环境变量：
 * - MYSQL_HOST: 数据库主机地址
 * - MYSQL_PORT: 数据库端口
 * - MYSQL_USER: 数据库用户名
 * - MYSQL_PASSWORD: 数据库密码
 * - MYSQL_DATABASE: 数据库名
 */
const mysql = require('mysql2/promise');
const logger = require('../utils/logger');

/**
 * 智能推断数据库主机地址
 *
 * 根据环境变量和运行环境自动选择最适合的数据库主机：
 * 使用显式配置的MYSQL_HOST
 */
const inferredDefaultHost = (() => {
  // 显式提供则使用显式值
  if (process.env.MYSQL_HOST && process.env.MYSQL_HOST.trim().length > 0) return process.env.MYSQL_HOST;
})();

/**
 * MySQL2 3.x 兼容的数据库连接池配置
 *
 * 优化的连接池参数，支持高并发和稳定性。
 * 包含超时、字符集、时区等重要设置。
 */
const poolConfig = {
  host: inferredDefaultHost,
  port: parseInt(process.env.MYSQL_PORT) || 3306,
  user: process.env.MYSQL_USER || 'shop_user',
  password: process.env.MYSQL_PASSWORD || 'shop_password_2024!',
  database: process.env.MYSQL_DATABASE || 'shop_system',

  // 连接池专用选项
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,

  // 基础连接选项 (MySQL2 3.x 兼容)
  charset: 'utf8mb4',
  timezone: '+08:00',

  // 数据处理选项
  supportBigNumbers: true,
  bigNumberStrings: true,
  dateStrings: false,

  // SSL配置
  ssl: false,

  // 连接超时 (仅保留兼容的选项)
  connectTimeout: 60000,
};

/**
 * 创建数据库连接池
 *
 * 使用上述配置参数创建连接池实例。
 * 连接池会自动管理连接的创建、重用和销毁。
 */
const pool = mysql.createPool(poolConfig);

// 添加连接池事件监听
pool.on('connection', function (connection) {
  logger.info(`数据库连接已建立: ${connection.threadId}`);
});

pool.on('error', function (err) {
  logger.error('数据库连接池错误:', err);
  if (err.code === 'PROTOCOL_CONNECTION_LOST') {
    logger.warn('数据库连接丢失，尝试重新连接...');
  }
});

// 数据库操作封装类
class Database {
  constructor() {
    this.pool = pool;
  }

  // 测试连接
  async testConnection() {
    try {
      const connection = await this.pool.getConnection();
      await connection.ping();
      connection.release();
      logger.info('数据库连接测试成功');
      return true;
    } catch (error) {
      logger.error('数据库连接测试失败:', error.message);
      throw error;
    }
  }

  // 初始化数据库连接（启动时调用）
  async initialize() {
    try {
      logger.info('初始化数据库连接池...');
      logger.info('使用配置:', {
        host: poolConfig.host,
        port: poolConfig.port,
        database: poolConfig.database,
        connectionLimit: poolConfig.connectionLimit,
        connectTimeout: poolConfig.connectTimeout,
        charset: poolConfig.charset,
        timezone: poolConfig.timezone,
      });

      await this.testConnection();
      logger.info('数据库连接池初始化完成');
      return true;
    } catch (error) {
      logger.error('数据库初始化失败:', error.message);
      throw error;
    }
  }

  // 执行查询
  async query(sql, params = []) {
    let sanitizedParams = [];
    try {
      // 验证和转换参数
      sanitizedParams = params.map((param, index) => {
        // 将 undefined 转换为 null
        if (param === undefined) {
          return null;
        }

        // 将 null 保持为 null
        if (param === null) {
          return null;
        }

        // 检查 NaN 值
        if (typeof param === 'number' && isNaN(param)) {
          throw new Error(`参数 ${index} 是 NaN，无法执行 SQL 查询`);
        }

        // 处理布尔值
        if (typeof param === 'boolean') {
          return param ? 1 : 0;
        }

        // 确保数字类型参数是有效的
        if (typeof param === 'number') {
          return param;
        }

        // 字符串参数直接返回，不做自动转换
        return param;
      });

      const [rows, fields] = await this.pool.execute(sql, sanitizedParams);
      return { rows, fields };
    } catch (error) {
      logger.error('数据库查询错误:', {
        sql,
        originalParams: params,
        sanitizedParams: sanitizedParams,
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  // 获取连接（用于事务）
  async getConnection() {
    try {
      return await this.pool.getConnection();
    } catch (error) {
      logger.error('获取数据库连接失败:', error.message);
      throw error;
    }
  }

  // 执行事务
  async transaction(callback) {
    const connection = await this.getConnection();
    try {
      await connection.beginTransaction();
      const result = await callback(connection);
      await connection.commit();
      return result;
    } catch (error) {
      await connection.rollback();
      logger.error('事务执行失败:', error.message);
      throw error;
    } finally {
      connection.release();
    }
  }

  // 开始事务
  async beginTransaction() {
    const connection = await this.pool.getConnection();
    await connection.beginTransaction();
    return connection;
  }

  // 提交事务
  async commitTransaction(connection) {
    await connection.commit();
    connection.release();
  }

  // 回滚事务
  async rollbackTransaction(connection) {
    await connection.rollback();
    connection.release();
  }

  // 关闭连接池
  async close() {
    await this.pool.end();
    logger.info('数据库连接池已关闭');
  }
}

// 创建数据库实例
const database = new Database();

// 确保方法正确绑定
const query = database.query.bind(database);
const transaction = database.transaction.bind(database);
const testConnection = database.testConnection.bind(database);
const initialize = database.initialize.bind(database);
const getConnection = database.getConnection.bind(database);
const beginTransaction = database.beginTransaction.bind(database);
const commitTransaction = database.commitTransaction.bind(database);
const rollbackTransaction = database.rollbackTransaction.bind(database);
const close = database.close.bind(database);

// 导出绑定好方法的对象
module.exports = {
  query,
  transaction,
  testConnection,
  initialize,
  getConnection,
  beginTransaction,
  commitTransaction,
  rollbackTransaction,
  close,
  pool: database.pool,
};
