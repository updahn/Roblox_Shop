/**
 * 管理员专用SQL操作服务
 * 包含所有管理员权限相关的数据库操作
 */

const database = require('../config/database');
const { AppError } = require('../middleware/errorHandler');

class AdminSQLOperations {
  /**
   * 获取所有用户（带分页）
   */
  static async getUsersWithPagination(options = {}) {
    const { limit = 100, offset = 0, status = null, search = null, sortBy = 'created_at', sortOrder = 'DESC' } = options;

    // 确保参数是有效的整数
    const parsedLimit = Math.min(1000, Math.max(1, parseInt(limit) || 100));
    const parsedOffset = Math.max(0, parseInt(offset) || 0);

    let whereClause = '';
    const params = [];

    if (status) {
      whereClause += ' WHERE status = ?';
      params.push(status);
    }

    if (search) {
      const searchClause = status ? ' AND' : ' WHERE';
      whereClause += `${searchClause} (username LIKE ? OR display_name LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`);
    }

    const validSortColumns = ['id', 'username', 'display_name', 'coins', 'created_at', 'last_login'];
    const safeSort = validSortColumns.includes(sortBy) ? sortBy : 'created_at';
    const safeOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const query = `
      SELECT
        u.id,
        u.username,
        u.display_name,
        u.coins,
        u.status,
        u.is_admin,
        u.created_at,
        u.updated_at,
        u.last_login,
        mm.id as membership_id,
        mm.start_date as membership_start_date,
        mm.end_date as membership_end_date,
        mm.daily_reward_coins,
        mm.is_active as membership_active,
        CASE
          WHEN mm.is_active = TRUE AND mm.end_date >= CURDATE() THEN 'active'
          WHEN mm.id IS NOT NULL THEN 'expired'
          ELSE 'none'
        END as membership_status,
        CASE
          WHEN mm.is_active = TRUE AND mm.end_date >= CURDATE() THEN DATEDIFF(mm.end_date, CURDATE())
          ELSE 0
        END as days_remaining
      FROM users u
      LEFT JOIN monthly_memberships mm ON u.id = mm.user_id AND mm.is_active = TRUE
      ${whereClause}
      ORDER BY u.${safeSort} ${safeOrder}
      LIMIT ${parsedLimit} OFFSET ${parsedOffset}
    `
      .trim()
      .replace(/\s+/g, ' ');
    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取用户总数
   */
  static async getUserCount(status = null) {
    let query = 'SELECT COUNT(*) as count FROM users';
    const params = [];

    if (status) {
      query += ' WHERE status = ?';
      params.push(status);
    }

    const { rows } = await database.query(query, params);
    return rows[0].count;
  }

  /**
   * 获取用户统计数据（购买次数、卖出次数、消费、收入）
   */
  static async getUserStats(userId) {
    const query = `
      SELECT
        COUNT(CASE WHEN type = 'buy' THEN 1 END) as buy_count,
        COUNT(CASE WHEN type = 'sell' THEN 1 END) as sell_count,
        COALESCE(SUM(CASE WHEN type = 'buy' THEN total_amount ELSE 0 END), 0) as total_spent,
        COALESCE(SUM(CASE WHEN type = 'sell' THEN total_amount ELSE 0 END), 0) as total_earned
      FROM transactions
      WHERE user_id = ?
    `;

    const { rows } = await database.query(query, [userId]);
    return rows.length > 0
      ? rows[0]
      : {
          buy_count: 0,
          sell_count: 0,
          total_spent: 0,
          total_earned: 0,
        };
  }

  /**
   * 批量获取多个用户的统计数据
   */
  static async getBatchUserStats(userIds) {
    if (!userIds || userIds.length === 0) return {};

    const placeholders = userIds.map(() => '?').join(',');
    const query = `
      SELECT
        user_id,
        COUNT(CASE WHEN type = 'buy' THEN 1 END) as buy_count,
        COUNT(CASE WHEN type = 'sell' THEN 1 END) as sell_count,
        COALESCE(SUM(CASE WHEN type = 'buy' THEN total_amount ELSE 0 END), 0) as total_spent,
        COALESCE(SUM(CASE WHEN type = 'sell' THEN total_amount ELSE 0 END), 0) as total_earned
      FROM transactions
      WHERE user_id IN (${placeholders})
      GROUP BY user_id
    `;

    const { rows } = await database.query(query, userIds);

    // 转换为以用户ID为键的对象
    const statsMap = {};
    rows.forEach((row) => {
      statsMap[row.user_id] = {
        buy_count: row.buy_count,
        sell_count: row.sell_count,
        total_spent: row.total_spent,
        total_earned: row.total_earned,
      };
    });

    // 为没有统计数据的用户添加默认值
    userIds.forEach((userId) => {
      if (!statsMap[userId]) {
        statsMap[userId] = {
          buy_count: 0,
          sell_count: 0,
          total_spent: 0,
          total_earned: 0,
        };
      }
    });

    return statsMap;
  }

  /**
   * 获取用户详细信息
   */
  static async getUserDetails(userId) {
    const query = `
      SELECT
        id,
        username,
        display_name,
        coins,
        status,
        is_admin,
        created_at,
        updated_at,
        last_login
      FROM users
      WHERE id = ?
    `;
    const { rows } = await database.query(query, [userId]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * 更新用户金币
   */
  static async updateUserCoins(userId, coins, reason, adminUserId) {
    return await database.transaction(async (connection) => {
      // 先获取用户当前金币数量
      const getUserQuery = 'SELECT coins FROM users WHERE id = ?';
      const [userRows] = await connection.execute(getUserQuery, [userId]);

      if (userRows.length === 0) {
        throw new AppError('用户不存在', 404);
      }

      const coinsBefore = userRows[0].coins;
      const coinsAfter = coins;
      const coinsDifference = coinsAfter - coinsBefore;

      // 更新用户金币
      const updateQuery = 'UPDATE users SET coins = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
      const [result] = await connection.execute(updateQuery, [coins, userId]);

      if (result.affectedRows === 0) {
        throw new AppError('用户不存在', 404);
      }

      // 插入交易记录
      const insertTransactionQuery = `
        INSERT INTO transactions (
          user_id, type, quantity, unit_price, total_amount,
          coins_before, coins_after, transaction_date,
          admin_user_id, notes, created_at
        ) VALUES (?, 'admin', 1, ?, ?, ?, ?, CURDATE(), ?, ?, CURRENT_TIMESTAMP)
      `;

      await connection.execute(insertTransactionQuery, [
        userId,
        coinsDifference, // unit_price表示金币变化量
        coinsDifference, // total_amount也是金币变化量
        coinsBefore,
        coinsAfter,
        adminUserId,
        reason || '管理员调整金币',
      ]);

      return result;
    });
  }

  /**
   * 更新用户状态
   */
  static async updateUserStatus(userId, status) {
    const query = 'UPDATE users SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    const { rows } = await database.query(query, [status, userId]);
    return rows;
  }

  /**
   * 获取完整系统统计
   */
  static async getCompleteSystemStats() {
    const stats = {};

    // 用户统计
    const userStatsQuery = `
      SELECT
        COUNT(*) as total_users,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users,
        COUNT(CASE WHEN status = 'banned' THEN 1 END) as banned_users,
        COUNT(CASE WHEN is_admin = TRUE THEN 1 END) as admin_users,
        COUNT(CASE WHEN last_login >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY) THEN 1 END) as active_last_week,
        COUNT(CASE WHEN created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) THEN 1 END) as new_users_30_days
      FROM users
    `;
    const { rows: userStats } = await database.query(userStatsQuery);
    stats.users = userStats[0];

    // 交易统计
    const transactionStatsQuery = `
      SELECT
        COUNT(*) as total_transactions,
        COUNT(CASE WHEN type = 'buy' THEN 1 END) as total_buys,
        COUNT(CASE WHEN type = 'sell' THEN 1 END) as total_sells,
        SUM(CASE WHEN type = 'buy' THEN total_amount ELSE 0 END) as total_spent,
        SUM(CASE WHEN type = 'sell' THEN total_amount ELSE 0 END) as total_earned,
        COUNT(CASE WHEN created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 24 HOUR) THEN 1 END) as transactions_24h,
        COUNT(CASE WHEN created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY) THEN 1 END) as transactions_7d
      FROM transactions
    `;
    const { rows: transactionStats } = await database.query(transactionStatsQuery);
    stats.transactions = transactionStats[0];

    // 商品统计
    const itemStatsQuery = `
      SELECT
        COUNT(*) as total_items,
        COUNT(CASE WHEN is_active = TRUE THEN 1 END) as active_items,
        COUNT(CASE WHEN current_stock = 0 THEN 1 END) as out_of_stock_items,
        AVG(price) as average_price
      FROM items
    `;
    const { rows: itemStats } = await database.query(itemStatsQuery);
    stats.items = itemStats[0];

    // 会员统计
    const membershipStatsQuery = `
      SELECT
        COUNT(*) as total_members,
        COUNT(CASE WHEN is_active = TRUE AND end_date >= CURDATE() THEN 1 END) as active_members,
        COUNT(CASE WHEN is_active = FALSE OR end_date < CURDATE() THEN 1 END) as expired_members
      FROM monthly_memberships
    `;
    const { rows: membershipStats } = await database.query(membershipStatsQuery);
    stats.membership = membershipStats[0];

    return stats;
  }

  /**
   * 更新商品库存
   */
  static async updateItemStock(itemId, stock) {
    const query = 'UPDATE items SET current_stock = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    const { rows } = await database.query(query, [stock, itemId]);
    return rows;
  }

  /**
   * 更新商品状态
   */
  static async updateItemStatus(itemId, active) {
    const query = 'UPDATE items SET is_active = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    const { rows } = await database.query(query, [active, itemId]);
    return rows;
  }

  /**
   * 获取管理员列表
   */
  static async getAdminList() {
    const query = `
      SELECT
        id,
        username,
        display_name,
        created_at,
        last_login
      FROM users
      WHERE is_admin = TRUE
      ORDER BY created_at DESC
    `;
    const { rows } = await database.query(query);
    return rows;
  }

  /**
   * 检查用户是否存在
   */
  static async checkUserExists(userIdOrUsername, isUserId = true) {
    try {
      const query = isUserId ? 'SELECT id, username, display_name, is_admin, status, coins, created_at FROM users WHERE id = ?' : 'SELECT id, username, display_name, is_admin, status, coins, created_at FROM users WHERE username = ?';

      const { rows } = await database.query(query, [userIdOrUsername]);

      const result = rows.length > 0 ? rows[0] : null;

      // 确保is_admin字段被正确转换为布尔值
      if (result) {
        result.is_admin = Boolean(result.is_admin);
      }

      return result;
    } catch (error) {
      throw error;
    }
  }

  /**
   * 添加管理员
   */
  static async addAdmin(userData) {
    return await database.transaction(async (connection) => {
      const { user_id, username } = userData;

      // 创建用户记录
      const createUserQuery = `
        INSERT INTO users (id, username, display_name, is_admin, created_at, updated_at)
        VALUES (?, ?, ?, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON DUPLICATE KEY UPDATE is_admin = TRUE, updated_at = CURRENT_TIMESTAMP
      `;

      await connection.execute(createUserQuery, [user_id, username, username]);

      return { success: true, message: '管理员添加成功' };
    });
  }

  /**
   * 提升用户为管理员
   */
  static async promoteToAdmin(userId) {
    const query = 'UPDATE users SET is_admin = TRUE, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    const { rows } = await database.query(query, [userId]);

    if (rows.affectedRows === 0) {
      throw new AppError('用户不存在', 404);
    }

    return { success: true, message: '用户已提升为管理员' };
  }

  /**
   * 移除管理员权限
   */
  static async removeAdmin(userId) {
    const query = 'UPDATE users SET is_admin = FALSE, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    const { rows } = await database.query(query, [userId]);

    if (rows.affectedRows === 0) {
      throw new AppError('管理员不存在', 404);
    }

    return { success: true, message: '管理员权限已移除' };
  }

  /**
   * 获取系统配置
   */
  static async getSystemConfig(configKey) {
    const query = 'SELECT config_value FROM system_config WHERE config_key = ?';
    const { rows } = await database.query(query, [configKey]);
    return rows.length > 0 ? rows[0].config_value : null;
  }

  /**
   * 设置系统配置
   */
  static async setSystemConfig(configKey, configValue, description = null) {
    const query = `
      INSERT INTO system_config (config_key, config_value, description, updated_at)
      VALUES (?, ?, ?, CURRENT_TIMESTAMP)
      ON DUPLICATE KEY UPDATE
      config_value = VALUES(config_value),
      description = COALESCE(VALUES(description), description),
      updated_at = CURRENT_TIMESTAMP
    `;

    await database.query(query, [configKey, configValue, description]);
    return { success: true };
  }

  /**
   * 获取所有系统配置
   */
  static async getAllSystemConfig() {
    const query = 'SELECT config_key, config_value, description, updated_at FROM system_config ORDER BY config_key';
    const { rows } = await database.query(query);
    return rows;
  }

  /**
   * 通过用户名查找用户
   */
  static async getUserByUsername(username) {
    const query = `
      SELECT
        id,
        username,
        display_name,
        coins,
        status,
        is_admin,
        created_at,
        updated_at,
        last_login
      FROM users
      WHERE username = ?
    `;
    const { rows } = await database.query(query, [username]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * 获取会员列表
   */
  static async getMembersList(page = 1, limit = 20, status = 'all') {
    // 确保参数是有效的整数
    const parsedPage = Math.max(1, parseInt(page) || 1);
    const parsedLimit = Math.min(1000, Math.max(1, parseInt(limit) || 20));
    const offset = (parsedPage - 1) * parsedLimit;

    let whereClause = '';
    let params = [];

    switch (status) {
      case 'active':
        whereClause = 'WHERE mm.is_active = TRUE AND mm.end_date >= CURDATE()';
        break;
      case 'expired':
        whereClause = 'WHERE mm.is_active = FALSE OR mm.end_date < CURDATE()';
        break;
      case 'all':
      default:
        whereClause = '';
        break;
    }

    const query = `
      SELECT
        u.id as user_id,
        u.username,
        u.display_name,
        mm.id as membership_id,
        mm.start_date,
        mm.end_date,
        mm.daily_reward_coins,
        mm.is_active,
        mm.created_at,
        mm.updated_at,
        CASE
          WHEN mm.is_active = TRUE AND mm.end_date >= CURDATE() THEN 'active'
          ELSE 'expired'
        END as status
      FROM users u
      JOIN monthly_memberships mm ON u.id = mm.user_id
      ${whereClause}
      ORDER BY mm.created_at DESC
      LIMIT ${parsedLimit} OFFSET ${offset}
    `
      .trim()
      .replace(/\s+/g, ' ');

    const { rows } = await database.query(query, params);

    // 获取总数
    const countQuery = `
      SELECT COUNT(*) as total
      FROM users u
      JOIN monthly_memberships mm ON u.id = mm.user_id
      ${whereClause}
    `
      .trim()
      .replace(/\s+/g, ' ');

    const { rows: countRows } = await database.query(countQuery, []);
    const total = countRows[0].total;

    return {
      members: rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * 获取所有用户及其会员状态（包括没有会员的用户）
   */
  static async getAllUsersWithMembershipStatus(page = 1, limit = 20, status = 'all') {
    // 确保参数是有效的整数
    const parsedPage = Math.max(1, parseInt(page) || 1);
    const parsedLimit = Math.min(1000, Math.max(1, parseInt(limit) || 20));
    const offset = (parsedPage - 1) * parsedLimit;

    let whereClause = '';
    let params = [];

    // 根据会员状态过滤
    switch (status) {
      case 'member':
        whereClause = 'WHERE mm.is_active = TRUE AND mm.end_date >= CURDATE()';
        break;
      case 'expired':
        whereClause = 'WHERE mm.is_active = FALSE OR mm.end_date < CURDATE()';
        break;
      case 'non_member':
        whereClause = 'WHERE mm.id IS NULL';
        break;
      case 'all':
      default:
        whereClause = '';
        break;
    }

    const query = `
      SELECT
        u.id as user_id,
        u.username,
        u.display_name,
        u.coins,
        u.status as user_status,
        u.is_admin,
        u.created_at as user_created_at,
        mm.id as membership_id,
        mm.start_date,
        mm.end_date,
        mm.daily_reward_coins,
        mm.is_active as membership_active,
        mm.created_at as membership_created_at,
        CASE
          WHEN mm.is_active = TRUE AND mm.end_date >= CURDATE() THEN 'active'
          WHEN mm.id IS NOT NULL THEN 'expired'
          ELSE 'none'
        END as membership_status,
        CASE
          WHEN mm.is_active = TRUE AND mm.end_date >= CURDATE() THEN DATEDIFF(mm.end_date, CURDATE())
          ELSE 0
        END as days_remaining
      FROM users u
      LEFT JOIN monthly_memberships mm ON u.id = mm.user_id AND mm.is_active = TRUE
      ${whereClause}
      ORDER BY u.created_at DESC
      LIMIT ${parsedLimit} OFFSET ${offset}
    `
      .trim()
      .replace(/\s+/g, ' ');

    const { rows } = await database.query(query, params);

    // 获取总数
    const countQuery = `
      SELECT COUNT(*) as total
      FROM users u
      LEFT JOIN monthly_memberships mm ON u.id = mm.user_id AND mm.is_active = TRUE
      ${whereClause}
    `
      .trim()
      .replace(/\s+/g, ' ');

    const { rows: countRows } = await database.query(countQuery, []);
    const total = countRows[0].total;

    return {
      users: rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * 购买会员
   */
  static async buyMembership(userId, durationDays = 30, dailyReward = 100) {
    return await database.transaction(async (connection) => {
      // 检查用户是否已有会员
      const checkQuery = `
        SELECT id, end_date, is_active
        FROM monthly_memberships
        WHERE user_id = ? AND is_active = TRUE
        ORDER BY end_date DESC
        LIMIT 1
      `;
      const [existingRows] = await connection.execute(checkQuery, [userId]);

      let startDate, endDate;
      const now = new Date();

      if (existingRows.length > 0) {
        // 如果有现有会员，从结束日期开始延期
        const existingEndDate = new Date(existingRows[0].end_date);
        startDate = existingEndDate > now ? existingEndDate : now;
      } else {
        // 新会员从今天开始
        startDate = now;
      }

      endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + durationDays);

      // 如果有现有会员，先将其设为不活跃
      if (existingRows.length > 0) {
        const deactivateQuery = 'UPDATE monthly_memberships SET is_active = FALSE WHERE user_id = ?';
        await connection.execute(deactivateQuery, [userId]);
      }

      // 插入新的会员记录
      const insertQuery = `
        INSERT INTO monthly_memberships (
          user_id, start_date, end_date, daily_reward_coins, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, ?, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      `;

      const [result] = await connection.execute(insertQuery, [userId, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0], dailyReward]);

      return {
        membershipId: result.insertId,
        startDate: startDate.toISOString().split('T')[0],
        endDate: endDate.toISOString().split('T')[0],
        durationDays,
        dailyReward,
      };
    });
  }

  /**
   * 取消会员
   */
  static async cancelMembership(userId) {
    return await database.transaction(async (connection) => {
      const today = new Date().toISOString().split('T')[0];

      const updateQuery = `
        UPDATE monthly_memberships
        SET end_date = ?, is_active = FALSE, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = ? AND is_active = TRUE
      `;

      const [result] = await connection.execute(updateQuery, [today, userId]);

      if (result.affectedRows === 0) {
        throw new AppError('用户没有活跃的会员记录', 404);
      }

      return {
        success: true,
        message: '会员已取消',
        endDate: today,
      };
    });
  }

  /**
   * 延长会员
   */
  static async extendMembership(userId, days) {
    return await database.transaction(async (connection) => {
      // 查找当前活跃的会员记录
      const checkQuery = `
        SELECT id, end_date
        FROM monthly_memberships
        WHERE user_id = ? AND is_active = TRUE
        ORDER BY end_date DESC
        LIMIT 1
      `;
      const [checkRows] = await connection.execute(checkQuery, [userId]);

      if (checkRows.length === 0) {
        throw new AppError('用户没有活跃的会员记录', 404);
      }

      const currentEndDate = new Date(checkRows[0].end_date);
      const newEndDate = new Date(currentEndDate);
      newEndDate.setDate(newEndDate.getDate() + days);

      const updateQuery = `
        UPDATE monthly_memberships
        SET end_date = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `;

      await connection.execute(updateQuery, [newEndDate.toISOString().split('T')[0], checkRows[0].id]);

      return {
        success: true,
        oldEndDate: currentEndDate.toISOString().split('T')[0],
        newEndDate: newEndDate.toISOString().split('T')[0],
        extendedDays: days,
      };
    });
  }

  /**
   * 更新会员信息
   */
  static async updateMembershipInfo(userId, updateData) {
    return await database.transaction(async (connection) => {
      const { membershipType, status, endDate, end_date, is_active, daily_reward_coins } = updateData;

      // 检查用户是否有会员记录
      const checkQuery = `
        SELECT id FROM monthly_memberships
        WHERE user_id = ? AND is_active = TRUE
        ORDER BY end_date DESC LIMIT 1
      `;
      const [checkRows] = await connection.execute(checkQuery, [userId]);

      if (checkRows.length === 0) {
        throw new AppError('用户没有激活的会员记录', 404);
      }

      const membershipId = checkRows[0].id;

      // 构建更新语句
      const updateFields = [];
      const updateValues = [];

      // 支持多种格式的结束日期字段
      const finalEndDate = endDate || end_date;
      if (finalEndDate) {
        updateFields.push('end_date = ?');
        updateValues.push(finalEndDate instanceof Date ? finalEndDate.toISOString().split('T')[0] : finalEndDate);
      }

      // 支持多种格式的状态字段
      const finalStatus = status !== undefined ? status : is_active;
      if (finalStatus !== undefined) {
        updateFields.push('is_active = ?');
        updateValues.push(finalStatus === 'active' || finalStatus === true);
      }

      // 每日奖励字段
      if (daily_reward_coins !== undefined) {
        updateFields.push('daily_reward_coins = ?');
        updateValues.push(daily_reward_coins);
      }

      updateFields.push('updated_at = CURRENT_TIMESTAMP');
      updateValues.push(membershipId);

      if (updateFields.length > 1) {
        const updateQuery = `
          UPDATE monthly_memberships
          SET ${updateFields.join(', ')}
          WHERE id = ?
        `
          .trim()
          .replace(/\s+/g, ' ');

        const [result] = await connection.execute(updateQuery, updateValues);

        return {
          success: true,
          affectedRows: result.affectedRows,
          membershipId,
        };
      }

      return { success: true, message: '没有需要更新的字段' };
    });
  }

  /**
   * 获取会员统计
   */
  static async getMembershipStats() {
    const query = `
      SELECT
        COUNT(*) as total_members,
        COUNT(CASE WHEN is_active = TRUE AND end_date >= CURDATE() THEN 1 END) as active_members,
        COUNT(CASE WHEN is_active = FALSE OR end_date < CURDATE() THEN 1 END) as expired_members
      FROM monthly_memberships
    `;

    const { rows } = await database.query(query);
    return rows[0];
  }

  /**
   * 获取会员奖励记录
   */
  static async getMembershipRewards(userId, days = 30) {
    const query = `
      SELECT
        date,
        coins_rewarded,
        membership_id,
        created_at
      FROM membership_rewards
      WHERE user_id = ?
      ORDER BY date DESC
    `;

    const { rows } = await database.query(query, [userId, days]);
    return rows;
  }

  /**
   * 获取商品信息
   */
  static async getItem(itemId) {
    const query = `
      SELECT
        id, name, description, price, category, max_quantity,
        current_stock, daily_purchase_limit, is_active,
        created_at, updated_at
      FROM items
      WHERE id = ?
    `;
    const { rows } = await database.query(query, [itemId]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * 获取用户库存
   */
  static async getUserInventory(userId) {
    const query = `
      SELECT
        ui.item_id,
        i.name as item_name,
        i.description,
        i.category,
        ui.quantity,
        i.price as current_price,
        (i.price * 0.8) as actual_sell_price
      FROM user_items ui
      JOIN items i ON ui.item_id = i.id
      WHERE ui.user_id = ? AND ui.quantity > 0
      ORDER BY i.category, i.name
    `;

    const { rows } = await database.query(query, [userId]);
    return rows;
  }

  /**
   * 获取用户交易记录
   */
  static async getUserTransactions(userId, limit = 50) {
    // 确保 limit 是有效的整数
    const parsedLimit = Math.min(1000, Math.max(1, parseInt(limit) || 50));

    const query = `
      SELECT
        t.id,
        t.user_id,
        t.item_id,
        i.name as item_name,
        t.type,
        t.quantity,
        t.unit_price,
        t.total_amount,
        t.coins_before,
        t.coins_after,
        t.transaction_date,
        t.admin_user_id,
        admin.username as admin_username,
        t.related_id,
        t.notes,
        t.created_at
      FROM transactions t
      LEFT JOIN items i ON t.item_id = i.id
      LEFT JOIN users admin ON t.admin_user_id = admin.id
      WHERE t.user_id = ?
      ORDER BY t.created_at DESC
      LIMIT ${parsedLimit}
    `;

    const { rows } = await database.query(query, [userId]);
    return rows;
  }

  /**
   * 获取会员状态
   */
  static async getMembershipStatus(userId) {
    const query = `
      SELECT
        mm.id as membership_id,
        'monthly' as membership_type,
        mm.start_date,
        mm.end_date,
        mm.daily_reward_coins as daily_reward,
        mm.is_active,
        mm.created_at,
        CASE
          WHEN mm.is_active = TRUE AND mm.end_date >= CURDATE() THEN TRUE
          ELSE FALSE
        END as is_valid,
        CASE
          WHEN mm.is_active = TRUE AND mm.end_date >= CURDATE() THEN DATEDIFF(mm.end_date, CURDATE())
          ELSE 0
        END as days_remaining
      FROM monthly_memberships mm
      WHERE mm.user_id = ?
      ORDER BY mm.end_date DESC, mm.created_at DESC
      LIMIT 1
    `;

    const { rows } = await database.query(query, [userId]);

    if (rows.length === 0) {
      return {
        hasMembership: false,
        isValid: false,
        daysRemaining: 0,
        membershipType: null,
        startDate: null,
        endDate: null,
        dailyReward: 0,
      };
    }

    const membership = rows[0];
    return {
      hasMembership: true,
      isValid: membership.is_valid,
      membershipId: membership.membership_id,
      membershipType: membership.membership_type,
      startDate: membership.start_date,
      endDate: membership.end_date,
      dailyReward: membership.daily_reward,
      daysRemaining: membership.days_remaining,
      isActive: membership.is_active,
      createdAt: membership.created_at,
    };
  }
  /**
   * 获取商品列表
   */
  static async getItemsList(page = 1, limit = 20, category = null, is_active = true) {
    // 验证和转换参数
    const parsedPage = Math.max(1, parseInt(page) || 1);
    const parsedLimit = Math.min(100, Math.max(1, parseInt(limit) || 20));

    // 计算偏移量
    const offset = (parsedPage - 1) * parsedLimit;

    // 处理 is_active 参数 - 转换为数值
    const activeValue = is_active === false ? 0 : 1;

    let whereClause = 'WHERE is_active = ?';
    let params = [activeValue];
    let countParams = [activeValue]; // 分别管理 count 查询的参数

    if (category && typeof category === 'string' && category !== 'undefined' && category !== 'null' && category.trim() !== '') {
      whereClause += ' AND category = ?';
      params.push(category.trim());
      countParams.push(category.trim());
    }

    const query = `
      SELECT
        id,
        name,
        description,
        price,
        sell_price,
        max_quantity,
        current_stock,
        daily_purchase_limit,
        can_sell,
        category,
        image_url,
        is_active,
        sort_order,
        created_at,
        updated_at
      FROM items
      ${whereClause}
      ORDER BY CASE WHEN category = 'membership' THEN 0 ELSE 1 END, sort_order DESC, created_at DESC
      LIMIT ${parsedLimit} OFFSET ${offset}
    `
      .trim()
      .replace(/\s+/g, ' ');

    const { rows } = await database.query(query, params);

    // 获取总数 - 使用独立的参数数组
    const countQuery = `
      SELECT COUNT(*) as total
      FROM items
      ${whereClause}
    `
      .trim()
      .replace(/\s+/g, ' ');
    const { rows: countRows } = await database.query(countQuery, countParams);

    return {
      items: rows,
      total: countRows[0].total,
      page: parsedPage,
      limit: parsedLimit,
      totalPages: Math.ceil(countRows[0].total / parsedLimit),
    };
  }

  /**
   * 根据ID获取商品详情
   */
  static async getItemById(itemId) {
    const query = `
      SELECT
        id,
        name,
        description,
        price,
        sell_price,
        max_quantity,
        current_stock,
        daily_purchase_limit,
        can_sell,
        category,
        image_url,
        is_active,
        sort_order,
        created_at,
        updated_at
      FROM items
      WHERE id = ?
    `;
    const { rows } = await database.query(query, [itemId]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * 获取所有商品分类
   */
  static async getItemCategories() {
    const query = `
      SELECT DISTINCT category
      FROM items
      WHERE is_active = true
      ORDER BY category
    `;
    const { rows } = await database.query(query);
    return rows.map((row) => row.category);
  }
}

module.exports = AdminSQLOperations;
