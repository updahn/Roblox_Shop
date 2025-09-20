/**
 * 数据库连接配置模块
 *
 * 功能特性：
 * - 使用MySQL2库创建连接池，支持Promise和高并发
 * - 自动检测运行环境并选择合适的数据库主机地址
 * - 内置连接池管理和错误处理机制
 * - 支持事务处理和参数验证
 * - 提供连接健康检查和监控功能
 *
 * 环境变量配置：
 * - MYSQL_HOST: 数据库主机地址（默认：localhost）
 * - MYSQL_PORT: 数据库端口（默认：3306）
 * - MYSQL_USER: 数据库用户名（默认：shop_user）
 * - MYSQL_PASSWORD: 数据库密码（默认：shop_password_2024!）
 * - MYSQL_DATABASE: 数据库名（默认：shop_system）
 *
 * 使用示例：
 * ```javascript
 * const { query, transaction } = require('./config/database');
 *
 * // 简单查询
 * const { rows } = await query('SELECT * FROM users WHERE id = ?', [userId]);
 *
 * // 事务处理
 * await transaction(async (connection) => {
 *   await connection.execute('UPDATE users SET coins = coins - ?', [amount]);
 *   await connection.execute('INSERT INTO transactions ...', [...]);
 * });
 * ```
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

/**
 * 数据库操作封装类
 *
 * 提供完整的数据库操作接口，包括：
 * - 连接管理和健康检查
 * - 参数化查询和防SQL注入
 * - 事务支持和错误处理
 * - 自动重连和故障恢复
 */
class Database {
  constructor() {
    this.pool = pool;
  }

  /**
   * 测试数据库连接
   *
   * 通过ping命令检查数据库连接状态，确保服务可用性
   *
   * @returns {Promise<boolean>} 连接成功返回true
   * @throws {Error} 连接失败时抛出错误
   */
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

  /**
   * 执行SQL查询
   *
   * 执行参数化查询，提供自动参数验证和类型转换。
   * 所有查询都使用prepared statements防止SQL注入攻击。
   *
   * @param {string} sql - SQL查询语句，使用?作为参数占位符
   * @param {Array} params - 查询参数数组，可选，默认为空数组
   * @returns {Promise<{rows: Array, fields: Array}>} 查询结果对象，包含行数据和字段信息
   * @throws {Error} 查询失败时抛出错误，包含详细的错误信息
   *
   * @example
   * // 简单查询
   * const { rows } = await query('SELECT * FROM users WHERE id = ?', [123]);
   *
   * // 插入数据
   * const { rows } = await query(
   *   'INSERT INTO users (id, username) VALUES (?, ?)',
   *   [userId, username]
   * );
   *
   * // 复杂查询
   * const { rows } = await query(`
   *   SELECT u.*, COUNT(t.id) as transaction_count
   *   FROM users u
   *   LEFT JOIN transactions t ON u.id = t.user_id
   *   WHERE u.status = ? AND u.created_at > ?
   *   GROUP BY u.id
   * `, ['active', '2024-01-01']);
   */
  async query(sql, params = []) {
    let sanitizedParams = [];
    try {
      // 验证和转换参数，确保类型安全
      sanitizedParams = params.map((param, index) => {
        // 将 undefined 转换为 null（数据库兼容）
        if (param === undefined) {
          return null;
        }

        // 保持 null 值
        if (param === null) {
          return null;
        }

        // 检查和拒绝 NaN 值，防止数据损坏
        if (typeof param === 'number' && isNaN(param)) {
          throw new Error(`参数索引 ${index} 包含 NaN 值，这会导致数据库错误`);
        }

        // 将布尔值转换为数字（MySQL兼容）
        if (typeof param === 'boolean') {
          return param ? 1 : 0;
        }

        // 数字和字符串直接返回
        if (typeof param === 'number' || typeof param === 'string') {
          return param;
        }

        // 其他类型转换为字符串
        return String(param);
      });

      const [rows, fields] = await this.pool.execute(sql, sanitizedParams);
      return { rows, fields };
    } catch (error) {
      logger.error('数据库查询执行失败:', {
        sql: sql.substring(0, 200) + (sql.length > 200 ? '...' : ''), // 限制日志长度
        originalParams: params,
        sanitizedParams: sanitizedParams,
        error: error.message,
        errorCode: error.code,
        sqlState: error.sqlState,
        stack: error.stack?.substring(0, 500), // 限制堆栈信息长度
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

  /**
   * 执行数据库事务
   *
   * 提供事务支持，确保一组操作的原子性。
   * 自动处理事务的开始、提交和回滚，包括错误情况下的清理。
   *
   * @param {Function} callback - 事务回调函数，接收connection参数
   * @returns {Promise<*>} 回调函数的返回值
   * @throws {Error} 事务失败时抛出错误
   *
   * @example
   * // 转账操作示例
   * const result = await transaction(async (connection) => {
   *   // 扣除发送方金币
   *   await connection.execute(
   *     'UPDATE users SET coins = coins - ? WHERE id = ?',
   *     [amount, senderId]
   *   );
   *
   *   // 增加接收方金币
   *   await connection.execute(
   *     'UPDATE users SET coins = coins + ? WHERE id = ?',
   *     [amount, receiverId]
   *   );
   *
   *   // 记录交易
   *   const [result] = await connection.execute(
   *     'INSERT INTO transactions (...) VALUES (...)',
   *     [...]
   *   );
   *
   *   return result.insertId;
   * });
   */
  async transaction(callback) {
    const connection = await this.getConnection();
    try {
      await connection.beginTransaction();
      logger.debug('事务开始');

      const result = await callback(connection);

      await connection.commit();
      logger.debug('事务提交成功');

      return result;
    } catch (error) {
      await connection.rollback();
      logger.error('事务执行失败，已回滚:', {
        error: error.message,
        stack: error.stack?.substring(0, 300),
      });
      throw error;
    } finally {
      connection.release();
      logger.debug('数据库连接已释放');
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
