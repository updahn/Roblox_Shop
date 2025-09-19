/**
 * 统一的SQL操作服务
 * 将所有数据库操作集中管理，包括原存储过程和初始化操作
 */

const database = require('../config/database');
const { AppError } = require('../middleware/errorHandler');

class SQLOperations {
  /**
   * 购买商品操作 (原BuyItem存储过程)
   * @param {string} userId - 用户ID
   * @param {string} itemId - 商品ID
   * @param {number} quantity - 购买数量
   */
  static async buyItem(userId, itemId, quantity) {
    try {
      // 检查商品是否存在且启用
      const itemQuery = 'SELECT price, max_quantity, current_stock FROM items WHERE id = ? AND is_active = TRUE';
      const { rows: itemRows } = await database.query(itemQuery, [itemId]);

      if (itemRows.length === 0) {
        throw new AppError('商品不存在或已禁用', 400);
      }

      const item = itemRows[0];
      const itemPrice = item.price;
      const maxQuantity = item.max_quantity;
      const currentStock = item.current_stock;

      // 检查库存（-1表示无限库存）
      if (currentStock !== -1 && currentStock < quantity) {
        throw new AppError(`库存不足，当前库存: ${currentStock}，尝试购买: ${quantity}`, 400);
      }

      // 检查数量限制
      if (maxQuantity !== null && quantity > maxQuantity) {
        throw new AppError(`购买数量超过限制，最大可购买: ${maxQuantity}`, 400);
      }

      // 获取税率配置并计算总价
      const taxRate = parseFloat((await this.getSystemConfig('shop_tax_rate')) || '0.05');
      const baseCost = itemPrice * quantity;
      const taxAmount = baseCost * taxRate;
      const totalCost = baseCost + taxAmount;

      // 检查用户金币
      const userQuery = 'SELECT coins FROM users WHERE id = ?';
      const { rows: userRows } = await database.query(userQuery, [userId]);

      if (userRows.length === 0) {
        throw new AppError('用户不存在', 404);
      }

      const userCoins = userRows[0].coins;
      if (userCoins < totalCost) {
        throw new AppError(`金币不足，需要: ${totalCost}，当前: ${userCoins}`, 400);
      }

      // 使用事务
      return await database.transaction(async (connection) => {
        // 扣除金币
        const updateCoinsQuery = 'UPDATE users SET coins = coins - ? WHERE id = ?';
        await connection.execute(updateCoinsQuery, [totalCost, userId]);

        // 更新商品库存（只有当库存不是无限时才更新）
        if (currentStock !== -1) {
          const updateStockQuery = 'UPDATE items SET current_stock = current_stock - ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
          await connection.execute(updateStockQuery, [quantity, itemId]);
        }

        // 更新用户物品
        const upsertItemQuery = `
          INSERT INTO user_items (user_id, item_id, quantity)
          VALUES (?, ?, ?)
          ON DUPLICATE KEY UPDATE quantity = quantity + ?
        `;
        await connection.execute(upsertItemQuery, [userId, itemId, quantity, quantity]);

        // 记录交易
        const insertTransactionQuery = `
          INSERT INTO transactions (
            user_id, type, item_id, quantity, unit_price,
            total_amount, coins_before, coins_after
          ) VALUES (?, 'buy', ?, ?, ?, ?, ?, ?)
        `;
        await connection.execute(insertTransactionQuery, [userId, itemId, quantity, itemPrice, totalCost, userCoins, userCoins - totalCost]);

        return {
          success: true,
          totalCost,
          newCoins: userCoins - totalCost,
        };
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * 出售商品操作 (原SellItem存储过程)
   * @param {string} userId - 用户ID
   * @param {string} itemId - 商品ID
   * @param {number} quantity - 出售数量
   */
  static async sellItem(userId, itemId, quantity) {
    try {
      // 检查用户拥有的物品数量
      const userItemQuery = `
        SELECT COALESCE(quantity, 0) as quantity
        FROM user_items
        WHERE user_id = ? AND item_id = ?
      `;
      const { rows: userItemRows } = await database.query(userItemQuery, [userId, itemId]);

      const userQuantity = userItemRows.length > 0 ? userItemRows[0].quantity : 0;

      if (userQuantity < quantity) {
        throw new AppError(`物品数量不足，拥有: ${userQuantity}，尝试出售: ${quantity}`, 400);
      }

      // 获取物品价格信息
      const itemQuery = 'SELECT price, sell_price, current_stock FROM items WHERE id = ? AND is_active = TRUE';
      const { rows: itemRows } = await database.query(itemQuery, [itemId]);

      if (itemRows.length === 0) {
        throw new AppError('商品不存在或已禁用', 400);
      }

      const item = itemRows[0];
      const itemPrice = item.price;
      const sellPrice = item.sell_price;
      const currentStock = item.current_stock;

      // 获取系统配置的出售比例并计算实际出售价格
      const sellRate = await this.getSellRate();
      const actualSellPrice = sellPrice !== null ? sellPrice : Math.floor(itemPrice * sellRate);
      const totalEarn = actualSellPrice * quantity;

      // 获取用户当前金币
      const userQuery = 'SELECT coins FROM users WHERE id = ?';
      const { rows: userRows } = await database.query(userQuery, [userId]);
      const userCoins = userRows[0].coins;

      // 使用事务
      return await database.transaction(async (connection) => {
        // 减少用户物品数量
        const updateItemQuery = `
          UPDATE user_items
          SET quantity = quantity - ?
          WHERE user_id = ? AND item_id = ?
        `;
        await connection.execute(updateItemQuery, [quantity, userId, itemId]);

        // 增加商品库存（只有当库存不是无限时才增加）
        if (currentStock !== -1) {
          const updateStockQuery = 'UPDATE items SET current_stock = current_stock + ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
          await connection.execute(updateStockQuery, [quantity, itemId]);
        }

        // 增加用户金币
        const updateCoinsQuery = 'UPDATE users SET coins = coins + ? WHERE id = ?';
        await connection.execute(updateCoinsQuery, [totalEarn, userId]);

        // 记录交易
        const insertTransactionQuery = `
          INSERT INTO transactions (
            user_id, type, item_id, quantity, unit_price,
            total_amount, coins_before, coins_after
          ) VALUES (?, 'sell', ?, ?, ?, ?, ?, ?)
        `;
        await connection.execute(insertTransactionQuery, [userId, itemId, quantity, actualSellPrice, totalEarn, userCoins, userCoins + totalEarn]);

        return {
          success: true,
          totalEarn,
          newCoins: userCoins + totalEarn,
        };
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * 获取用户详细信息
   * @param {string} userId - 用户ID
   */
  static async getUserDetails(userId) {
    const query = `
      SELECT
        u.*,
        COALESCE(buy_stats.total_spent, 0) as total_spent,
        COALESCE(buy_stats.total_purchases, 0) as total_purchases,
        COALESCE(sell_stats.total_earned, 0) as total_earned,
        COALESCE(sell_stats.total_sales, 0) as total_sales,
        COALESCE(inventory_stats.total_items, 0) as total_items,
        COALESCE(inventory_stats.unique_items, 0) as unique_items
      FROM users u
      LEFT JOIN (
        SELECT
          user_id,
          SUM(total_amount) as total_spent,
          COUNT(*) as total_purchases
        FROM transactions
        WHERE type = 'buy'
        GROUP BY user_id
      ) buy_stats ON u.id = buy_stats.user_id
      LEFT JOIN (
        SELECT
          user_id,
          SUM(total_amount) as total_earned,
          COUNT(*) as total_sales
        FROM transactions
        WHERE type = 'sell'
        GROUP BY user_id
      ) sell_stats ON u.id = sell_stats.user_id
      LEFT JOIN (
        SELECT user_id, SUM(quantity) as total_items, COUNT(*) as unique_items
        FROM user_items
        WHERE quantity > 0
        GROUP BY user_id
      ) inventory_stats ON u.id = inventory_stats.user_id
      WHERE u.id = ?
    `;

    const { rows } = await database.query(query, [userId]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * 获取用户库存
   * @param {string} userId - 用户ID
   */
  static async getUserInventory(userId) {
    const sellRate = await this.getSellRate();
    const query = `
      SELECT
        ui.quantity,
        i.id as item_id, i.name, i.description, i.price, i.sell_price, i.category, i.image_url,
        COALESCE(i.sell_price, FLOOR(i.price * ?)) as actual_sell_price
      FROM user_items ui
      JOIN items i ON ui.item_id = i.id
      WHERE ui.user_id = ? AND ui.quantity > 0
      ORDER BY i.category, i.name
    `;

    const { rows } = await database.query(query, [sellRate, userId]);
    return rows;
  }

  /**
   * 获取用户交易记录
   * @param {string} userId - 用户ID
   * @param {number} limit - 限制数量
   */
  static async getUserTransactions(userId, limit = 50) {
    const query = `
      SELECT
        t.*,
        i.name as item_name, i.image_url as item_image
      FROM transactions t
      JOIN items i ON t.item_id = i.id
      WHERE t.user_id = ?
      ORDER BY t.created_at DESC
      LIMIT ${parseInt(limit)}
    `;

    const { rows } = await database.query(query, [userId]);
    return rows;
  }

  /**
   * 更新用户金币 (管理员操作)
   * @param {string} userId - 用户ID
   * @param {number} coins - 新的金币数量
   * @param {string} reason - 操作原因
   * @param {string} adminUserId - 管理员用户ID
   */
  static async updateUserCoins(userId, coins, reason, adminUserId) {
    try {
      // 获取用户当前金币
      const userQuery = 'SELECT coins FROM users WHERE id = ?';
      const { rows: userRows } = await database.query(userQuery, [userId]);

      if (userRows.length === 0) {
        throw new AppError('用户不存在', 404);
      }

      const oldCoins = userRows[0].coins;
      const coinsDiff = coins - oldCoins;

      // 使用事务
      return await database.transaction(async (connection) => {
        // 更新用户金币
        const updateQuery = 'UPDATE users SET coins = ? WHERE id = ?';
        await connection.execute(updateQuery, [coins, userId]);

        // 记录管理员操作
        if (coinsDiff !== 0) {
          // 首先确保有管理员操作的虚拟商品记录
          const checkItemQuery = 'SELECT id FROM items WHERE id = ?';
          const { rows: itemRows } = await database.query(checkItemQuery, ['admin_coins_adjustment']);

          if (itemRows.length === 0) {
            // 创建管理员操作的虚拟商品
            const createItemQuery = `
            INSERT INTO items (id, name, description, price, sell_price, category, max_quantity, current_stock)
            VALUES ('admin_coins_adjustment', '管理员金币调整', '管理员调整玩家金币的虚拟操作记录', 0, 0, 'system', NULL, NULL)
          `;
            await connection.execute(createItemQuery);
          }

          // 记录管理员操作
          const transactionQuery = `
            INSERT INTO transactions (
              user_id, type, item_id, quantity, unit_price,
              total_amount, coins_before, coins_after, admin_user_id, notes
            ) VALUES (?, 'admin', 'admin_coins_adjustment', 1, ?, ?, ?, ?, ?, ?)
          `;
          await connection.execute(transactionQuery, [userId, coinsDiff, coinsDiff, oldCoins, coins, adminUserId, reason]);
        }

        return {
          oldCoins,
          newCoins: coins,
          difference: coinsDiff,
        };
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * 初始化系统数据 (替代原SQL初始化脚本)
   */
  static async initializeSystemData() {
    try {
      // 插入默认系统配置
      const systemConfigs = [
        ['shop_enabled', 'true', '商店是否启用'],
        ['max_coins_per_user', '1000000', '用户最大金币数'],
        ['default_user_coins', '3000', '新用户默认金币'],
        ['transaction_log_retention_days', '90', '交易日志保留天数'],
        ['sell_rate', '0.8', '物品出售价格比例'],
        ['max_coins', '999999999', '用户最大金币数量'],
        ['api_version', '1.0.0', 'API版本号'],
      ];

      for (const [key, value, description] of systemConfigs) {
        const insertConfigQuery = `
          INSERT IGNORE INTO system_config (config_key, config_value, description)
          VALUES (?, ?, ?)
        `;
        await database.query(insertConfigQuery, [key, value, description]);
      }

      // 插入示例商品数据
      const sampleItems = [
        {
          id: 'sword_basic',
          name: '基础剑',
          description: '一把普通的铁剑，适合新手使用',
          price: 100,
          category: 'weapons',
          sort_order: 1,
        },
        {
          id: 'shield_wooden',
          name: '木制盾牌',
          description: '简单的木制盾牌，提供基础防护',
          price: 80,
          category: 'armor',
          sort_order: 2,
        },
        {
          id: 'potion_health',
          name: '生命药水',
          description: '恢复一定生命值的药水',
          price: 50,
          category: 'consumables',
          sort_order: 3,
        },
        {
          id: 'gem_ruby',
          name: '红宝石',
          description: '珍贵的红色宝石，可用于装备强化',
          price: 200,
          category: 'materials',
          sort_order: 4,
        },
        {
          id: 'scroll_teleport',
          name: '传送卷轴',
          description: '瞬间传送到指定地点的魔法卷轴',
          price: 150,
          category: 'consumables',
          sort_order: 5,
        },
      ];

      for (const item of sampleItems) {
        const insertItemQuery = `
          INSERT IGNORE INTO items (id, name, description, price, category, sort_order)
          VALUES (?, ?, ?, ?, ?, ?)
        `;
        await database.query(insertItemQuery, [item.id, item.name, item.description, item.price, item.category, item.sort_order]);
      }

      return { success: true, message: '系统数据初始化完成' };
    } catch (error) {
      console.error('系统数据初始化失败:', error);
      throw new AppError('系统数据初始化失败', 500);
    }
  }

  /**
   * 获取系统配置
   * @param {string} configKey - 配置键
   */
  static async getSystemConfig(configKey) {
    const query = 'SELECT config_value FROM system_config WHERE config_key = ? AND is_active = TRUE';
    const { rows } = await database.query(query, [configKey]);
    return rows.length > 0 ? rows[0].config_value : null;
  }

  /**
   * 获取当前sell_rate配置
   * @returns {Promise<number>} sell_rate值，默认0.8
   */
  static async getSellRate() {
    const sellRate = await this.getSystemConfig('sell_rate');
    return parseFloat(sellRate || '0.8');
  }

  /**
   * 设置系统配置
   * @param {string} configKey - 配置键
   * @param {string} configValue - 配置值
   * @param {string} description - 配置描述
   */
  static async setSystemConfig(configKey, configValue, description = null) {
    const query = `
      INSERT INTO system_config (config_key, config_value, description)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE
        config_value = VALUES(config_value),
        description = COALESCE(VALUES(description), description),
        updated_at = CURRENT_TIMESTAMP
    `;
    await database.query(query, [configKey, configValue, description]);
    return { success: true };
  }

  /**
   * 获取商品列表
   * @param {boolean} activeOnly - 只获取启用的商品
   */
  static async getItems(activeOnly = true) {
    let query = 'SELECT * FROM items';
    const params = [];

    if (activeOnly) {
      query += ' WHERE is_active = TRUE';
    }

    query += ' ORDER BY sort_order, name';

    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取单个商品信息
   * @param {string} itemId - 商品ID
   */
  static async getItem(itemId) {
    const query = 'SELECT * FROM items WHERE id = ?';
    const { rows } = await database.query(query, [itemId]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * 清理过期交易记录
   * @param {number} retentionDays - 保留天数
   */
  static async cleanupOldTransactions(retentionDays = 90) {
    const query = `
      DELETE FROM transactions
      WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
      AND type != 'admin'
    `;
    const { affectedRows } = await database.query(query, [retentionDays]);
    return { deletedCount: affectedRows };
  }

  /**
   * 获取系统统计信息
   */
  static async getSystemStats() {
    const queries = {
      users: `
        SELECT
          COUNT(*) as total_users,
          COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users,
          COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as new_users_today
        FROM users
      `,
      transactions: `
        SELECT
          COUNT(*) as total_transactions,
          COUNT(CASE WHEN type = 'buy' THEN 1 END) as buy_transactions,
          COUNT(CASE WHEN type = 'sell' THEN 1 END) as sell_transactions,
          SUM(CASE WHEN type = 'buy' THEN total_amount ELSE 0 END) as total_buy_amount,
          SUM(CASE WHEN type = 'sell' THEN total_amount ELSE 0 END) as total_sell_amount,
          COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as transactions_today
        FROM transactions
      `,
      items: `
        SELECT
          COUNT(*) as total_items,
          COUNT(CASE WHEN is_active = TRUE THEN 1 END) as active_items
        FROM items
      `,
      coins: `
        SELECT
          SUM(coins) as total_coins_in_circulation,
          AVG(coins) as avg_coins_per_user,
          MAX(coins) as max_coins,
          MIN(coins) as min_coins
        FROM users
      `,
    };

    const results = {};
    for (const [key, query] of Object.entries(queries)) {
      const { rows } = await database.query(query);
      results[key] = rows[0];
    }

    return results;
  }

  // ==================== 认证相关操作 ====================

  /**
   * 创建或登录用户
   * @param {string} userId - 用户ID
   * @param {string} username - 用户名
   * @param {string} displayName - 显示名称
   */
  static async createOrLoginUser(userId, username, displayName = null) {
    // 获取系统配置的默认金币数量
    const defaultCoins = parseInt((await this.getSystemConfig('default_user_coins')) || '3000');

    // 检查是否为管理员用户
    const isAdmin = await this.isUserAdmin(userId, username);

    const query = `
      INSERT INTO users (id, username, display_name, coins, is_admin, last_login)
      VALUES (?, ?, ?, ?, ?, NOW())
      ON DUPLICATE KEY UPDATE
        last_login = NOW(),
        display_name = COALESCE(VALUES(display_name), display_name),
        coins = CASE WHEN coins IS NULL OR coins = 0 THEN VALUES(coins) ELSE coins END,
        is_admin = CASE WHEN is_admin = FALSE AND VALUES(is_admin) = TRUE THEN TRUE ELSE is_admin END
    `;

    await database.query(query, [userId, username, displayName, defaultCoins, isAdmin]);

    // 如果用户是管理员但数据库中is_admin为false，则更新
    if (isAdmin) {
      const updateAdminQuery = 'UPDATE users SET is_admin = TRUE WHERE id = ? AND is_admin = FALSE';
      await database.query(updateAdminQuery, [userId]);
    }

    return await this.getUserDetails(userId);
  }

  /**
   * 检查用户管理员权限（原auth.js中的isUserAdmin函数）
   * @param {string} userId - 用户ID
   * @param {string} username - 用户名
   * @returns {boolean} 是否为管理员
   */
  static async isUserAdmin(userId, username) {
    try {
      // 1. 检查数据库中的is_admin字段（优先级最高）
      const query = 'SELECT is_admin FROM users WHERE id = ? OR username = ?';
      const { rows } = await database.query(query, [userId, username]);

      if (rows.length > 0 && rows[0].is_admin) {
        return true;
      }

      // 2. 检查环境变量配置的管理员用户名列表
      const adminUsernames =
        process.env.ADMIN_USERNAMES?.split(',')
          .map((name) => name.trim())
          .filter(Boolean) || [];

      if (adminUsernames.includes(username)) {
        return true;
      }

      // 3. 检查硬编码的管理员用户名列表（用于初始化）
      const hardcodedAdmins = ['updahn', 'updahn2'];
      if (hardcodedAdmins.includes(username)) {
        return true;
      }

      return false;
    } catch (error) {
      console.error('检查管理员权限时发生错误:', error);
      return false;
    }
  }

  /**
   * 验证用户权限
   * @param {string} userId - 用户ID
   * @param {string} permission - 权限名称
   */
  static async checkUserPermission(userId, permission) {
    const query = `
      SELECT is_admin
      FROM users
      WHERE id = ? AND status = 'active'
    `;

    const { rows } = await database.query(query, [userId]);
    if (rows.length === 0) return false;

    const user = rows[0];
    // 管理员拥有所有权限
    return user.is_admin;
  }

  // ==================== 商品相关操作 ====================

  /**
   * 获取商品（带分页和搜索）
   * @param {Object} options - 查询选项
   */
  static async getItemsWithOptions(options = {}) {
    const { category = null, search = null, limit = 50, offset = 0, activeOnly = true } = options;
    const sellRate = await this.getSellRate();

    let query = `
      SELECT id, name, price, description,
             image_url as item_image, category,
             COALESCE(sell_price, FLOOR(price * ?)) as sell_price,
             is_active
      FROM items
    `;

    const conditions = [];
    const params = [sellRate];

    if (activeOnly) {
      conditions.push('is_active = TRUE');
    }

    if (category) {
      conditions.push('category = ?');
      params.push(category);
    }

    if (search) {
      conditions.push('(name LIKE ? OR description LIKE ?)');
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ` ORDER BY sort_order, name LIMIT ${parseInt(limit)} OFFSET ${parseInt(offset)}`;

    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取商品统计信息
   * @param {string} itemId - 商品ID
   */
  static async getItemStats(itemId) {
    const query = `
      SELECT
        type,
        COUNT(*) as transaction_count,
        SUM(quantity) as total_quantity,
        AVG(unit_price) as avg_price
      FROM transactions
      WHERE item_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
      GROUP BY type
    `;

    const { rows } = await database.query(query, [itemId]);
    return rows;
  }

  /**
   * 检查商品库存状态
   * @param {string} itemId - 商品ID
   */
  static async checkItemStock(itemId) {
    const query = `
      SELECT id, name, max_quantity, current_stock,
             CASE
               WHEN max_quantity IS NULL THEN 'unlimited'
               WHEN current_stock <= 0 THEN 'out_of_stock'
               WHEN current_stock < 10 THEN 'low_stock'
               ELSE 'in_stock'
             END as stock_status
      FROM items
      WHERE id = ? AND is_active = TRUE
    `;

    const { rows } = await database.query(query, [itemId]);
    return rows.length > 0 ? rows[0] : null;
  }

  // ==================== 交易相关操作 ====================

  /**
   * 获取交易记录（带过滤）
   * @param {Object} options - 查询选项
   */
  static async getTransactions(options = {}) {
    const { userId = null, type = null, startDate = null, endDate = null, limit = 50, offset = 0 } = options;

    let query = `
      SELECT t.*, i.name as item_name, i.image_url as item_image
      FROM transactions t
      LEFT JOIN items i ON t.item_id = i.id
    `;

    const conditions = [];
    const params = [];

    if (userId) {
      conditions.push('t.user_id = ?');
      params.push(userId);
    }

    if (type) {
      conditions.push('t.type = ?');
      params.push(type);
    }

    if (startDate) {
      conditions.push('t.created_at >= ?');
      params.push(startDate);
    }

    if (endDate) {
      conditions.push('t.created_at <= ?');
      params.push(endDate);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ` ORDER BY t.created_at DESC LIMIT ${parseInt(limit)} OFFSET ${parseInt(offset)}`;

    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取交易统计
   * @param {number} days - 统计天数
   */
  static async getTransactionStats(days = 30) {
    const query = `
      SELECT
        DATE(created_at) as date,
        type,
        COUNT(*) as count,
        SUM(total_amount) as total_amount
      FROM transactions
      WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
      GROUP BY DATE(created_at), type
      ORDER BY date DESC, type
    `;

    const { rows } = await database.query(query, [days]);
    return rows;
  }

  /**
   * 获取最近交易
   * @param {number} limit - 限制数量
   */
  static async getRecentTransactions(limit = 10) {
    const query = `
      SELECT t.*, i.name as item_name, i.image_url as item_image, u.username
      FROM transactions t
      LEFT JOIN items i ON t.item_id = i.id
      LEFT JOIN users u ON t.user_id = u.id
      ORDER BY t.created_at DESC
      LIMIT ${parseInt(limit)}
    `;

    const { rows } = await database.query(query);
    return rows;
  }

  // ==================== 管理员相关操作 ====================

  /**
   * 获取所有用户（管理员用）
   * @param {Object} options - 查询选项
   */
  static async getAllUsers(options = {}) {
    const { limit = 50, offset = 0, status = null, search = null } = options;

    let query = `
      SELECT u.*,
             COALESCE(total_spent.amount, 0) as total_spent,
             COALESCE(total_earned.amount, 0) as total_earned
      FROM users u
      LEFT JOIN (
        SELECT user_id, SUM(total_amount) as amount
        FROM transactions
        WHERE type = 'buy'
        GROUP BY user_id
      ) total_spent ON u.id = total_spent.user_id
      LEFT JOIN (
        SELECT user_id, SUM(total_amount) as amount
        FROM transactions
        WHERE type = 'sell'
        GROUP BY user_id
      ) total_earned ON u.id = total_earned.user_id
    `;

    const conditions = [];
    const params = [];

    if (status) {
      conditions.push('u.status = ?');
      params.push(status);
    }

    if (search) {
      conditions.push('(u.username LIKE ? OR u.display_name LIKE ?)');
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ` ORDER BY u.created_at DESC LIMIT ${parseInt(limit)} OFFSET ${parseInt(offset)}`;

    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取管理员操作日志
   * @param {Object} options - 查询选项
   */
  static async getAdminLogs(options = {}) {
    const { limit = 50, offset = 0 } = options;

    const query = `
      SELECT t.*, i.name as item_name
      FROM transactions t
      LEFT JOIN items i ON t.item_id = i.id
      WHERE t.type = 'admin'
      ORDER BY t.created_at DESC
      LIMIT ${parseInt(limit)} OFFSET ${parseInt(offset)}
    `;

    const { rows } = await database.query(query);
    return rows;
  }

  // ==================== 用户统计相关操作 ====================

  /**
   * 获取用户购买最多的商品
   * @param {string} userId - 用户ID
   * @param {number} limit - 限制数量
   */
  static async getUserTopItems(userId, limit = 5) {
    const query = `
      SELECT
        i.id, i.name, i.image_url as item_image,
        SUM(t.quantity) as total_bought,
        SUM(t.total_amount) as total_spent
      FROM transactions t
      JOIN items i ON t.item_id = i.id
      WHERE t.user_id = ? AND t.type = 'buy'
      GROUP BY i.id, i.name, i.image_url
      ORDER BY total_bought DESC
      LIMIT ${parseInt(limit)}
    `;

    const { rows } = await database.query(query, [userId]);
    return rows;
  }

  /**
   * 获取用户30天统计
   * @param {string} userId - 用户ID
   */
  static async getUserStats30Days(userId) {
    const query = `
       SELECT
         COUNT(CASE WHEN type = 'buy' THEN 1 END) as transactions_buy,
         COUNT(CASE WHEN type = 'sell' THEN 1 END) as transactions_sell,
         SUM(CASE WHEN type = 'buy' THEN total_amount ELSE 0 END) as total_spent,
         SUM(CASE WHEN type = 'sell' THEN total_amount ELSE 0 END) as total_earned
       FROM transactions
       WHERE user_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
     `;

    const { rows } = await database.query(query, [userId]);
    return (
      rows[0] || {
        transactions_buy: 0,
        transactions_sell: 0,
        total_spent: 0,
        total_earned: 0,
      }
    );
  }

  // ==================== 用户交易统计相关操作 ====================

  /**
   * 获取用户交易统计（针对特定用户）
   * @param {string} userId - 用户ID
   */
  static async getUserTransactionStats(userId) {
    const query = `
       SELECT
         type,
         COUNT(*) as count,
         SUM(total_amount) as total_amount
       FROM transactions
       WHERE user_id = ?
       GROUP BY type
     `;

    const { rows } = await database.query(query, [userId]);
    return rows;
  }

  /**
   * 获取用户库存价值统计
   * @param {string} userId - 用户ID
   */
  static async getUserInventoryValue(userId) {
    const sellRate = await this.getSellRate();
    const query = `
       SELECT
         COUNT(*) as unique_items,
         SUM(ui.quantity) as total_items,
         SUM(ui.quantity * COALESCE(i.sell_price, FLOOR(i.price * ?))) as total_value
       FROM user_items ui
       JOIN items i ON ui.item_id = i.id
       WHERE ui.user_id = ? AND ui.quantity > 0
     `;

    const { rows } = await database.query(query, [sellRate, userId]);
    return (
      rows[0] || {
        unique_items: 0,
        total_items: 0,
        total_value: 0,
      }
    );
  }

  // ==================== 热门商品和价格趋势 ====================

  /**
   * 获取热门商品（基于交易量）
   * @param {Object} options - 查询选项
   */
  static async getPopularItems(options = {}) {
    const { type = null, limit = 10, days = 7 } = options;

    let query = `
       SELECT
         i.id, i.name, i.image_url as item_image, i.category,
         COUNT(*) as transaction_count,
         SUM(t.quantity) as total_quantity,
         SUM(t.total_amount) as total_amount,
         AVG(t.unit_price) as avg_price
       FROM transactions t
       JOIN items i ON t.item_id = i.id
       WHERE t.created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
     `;
    const params = [days];

    if (type) {
      query += ' AND t.type = ?';
      params.push(type);
    }

    query += `
       GROUP BY i.id, i.name, i.image_url, i.category
       ORDER BY total_quantity DESC
       LIMIT ${parseInt(limit)}
     `;

    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取商品价格趋势
   * @param {string} itemId - 商品ID
   * @param {number} days - 统计天数
   */
  static async getItemPriceTrends(itemId, days = 30) {
    const query = `
       SELECT
         DATE(created_at) as date,
         type,
         AVG(unit_price) as avg_price,
         MIN(unit_price) as min_price,
         MAX(unit_price) as max_price,
         COUNT(*) as transaction_count,
         SUM(quantity) as total_quantity
       FROM transactions
       WHERE item_id = ? AND created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
       GROUP BY DATE(created_at), type
       ORDER BY date DESC, type
     `;

    const { rows } = await database.query(query, [itemId, days]);
    return rows;
  }

  // ==================== 交易详情和市场统计 ====================

  /**
   * 获取单个交易详情
   * @param {string} transactionId - 交易ID
   * @param {string} userId - 用户ID
   */
  static async getTransactionDetails(transactionId, userId) {
    const query = `
       SELECT t.*, i.name as item_name, i.image_url as item_image, i.category
       FROM transactions t
       JOIN items i ON t.item_id = i.id
       WHERE t.id = ? AND t.user_id = ?
     `;

    const { rows } = await database.query(query, [transactionId, userId]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * 获取今日市场统计
   */
  static async getTodayMarketStats() {
    const query = `
       SELECT
         type,
         COUNT(*) as count,
         SUM(total_amount) as total_amount,
         SUM(quantity) as total_quantity
       FROM transactions
       WHERE DATE(created_at) = CURDATE()
       GROUP BY type
     `;

    const { rows } = await database.query(query);
    return rows;
  }

  /**
   * 获取活跃商品数量
   */
  static async getActiveItemsCount() {
    const query = `
       SELECT COUNT(DISTINCT item_id) as active_items
       FROM transactions
       WHERE created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
     `;

    const { rows } = await database.query(query);
    return rows[0]?.active_items || 0;
  }

  // ==================== 管理员系统统计 ====================

  /**
   * 获取系统完整统计信息
   */
  static async getCompleteSystemStats() {
    // 用户统计
    const userStatsQuery = `
       SELECT
         COUNT(*) as total_users,
         COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users,
         COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as new_users_today
       FROM users
     `;

    // 交易统计
    const transactionStatsQuery = `
       SELECT
         COUNT(*) as total_transactions,
         COUNT(CASE WHEN type = 'buy' THEN 1 END) as buy_transactions,
         COUNT(CASE WHEN type = 'sell' THEN 1 END) as sell_transactions,
         SUM(CASE WHEN type = 'buy' THEN total_amount ELSE 0 END) as total_buy_amount,
         SUM(CASE WHEN type = 'sell' THEN total_amount ELSE 0 END) as total_sell_amount,
         COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as transactions_today
       FROM transactions
     `;

    // 商品统计
    const itemStatsQuery = `
       SELECT
         COUNT(*) as total_items,
         COUNT(CASE WHEN is_active = TRUE THEN 1 END) as active_items,
         COUNT(CASE WHEN max_quantity IS NOT NULL AND current_stock = 0 THEN 1 END) as out_of_stock_items
       FROM items
     `;

    // 金币统计
    const coinStatsQuery = `
       SELECT
         SUM(coins) as total_coins_in_circulation,
         AVG(coins) as avg_coins_per_user,
         MAX(coins) as max_coins,
         MIN(coins) as min_coins
       FROM users
       WHERE status = 'active'
     `;

    const [userStats, transactionStats, itemStats, coinStats] = await Promise.all([database.query(userStatsQuery), database.query(transactionStatsQuery), database.query(itemStatsQuery), database.query(coinStatsQuery)]);

    return {
      users: userStats.rows[0],
      transactions: transactionStats.rows[0],
      items: itemStats.rows[0],
      coins: coinStats.rows[0],
    };
  }

  // ==================== 数据库连接操作 ====================

  /**
   * 创建用户记录（原database.js中的createUser方法）
   * @param {string} userId - 用户ID
   * @param {string} username - 用户名
   * @param {string} displayName - 显示名称
   */
  static async createUser(userId, username, displayName = null) {
    const sql = `
      INSERT INTO users (id, username, display_name)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE
        username = VALUES(username),
        display_name = VALUES(display_name),
        last_login = CURRENT_TIMESTAMP
    `;

    await database.query(sql, [userId, username, displayName]);
    return { success: true };
  }

  /**
   * 获取所有商品（原database.js中的getAllItems方法）
   * @param {boolean} activeOnly - 只获取启用的商品
   */
  static async getAllItems(activeOnly = true) {
    const sellRate = await this.getSellRate();
    const sql = `
      SELECT id, name, price, max_quantity, description,
             image_url as item_image, category,
             COALESCE(sell_price, FLOOR(price * ?)) as sell_price,
             is_active
      FROM items
      ${activeOnly ? 'WHERE is_active = TRUE' : ''}
      ORDER BY category, name
    `;

    const { rows } = await database.query(sql, [sellRate]);
    return rows;
  }

  /**
   * 获取交易统计（原database.js中的getTransactionStats方法）
   * @param {number} days - 统计天数
   */
  static async getTransactionStatsForDays(days = 7) {
    const sql = `
      SELECT
        DATE(created_at) as date,
        type,
        COUNT(*) as count,
        SUM(total_amount) as total_amount
      FROM transactions
      WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
      GROUP BY DATE(created_at), type
      ORDER BY date DESC, type
    `;

    const { rows } = await database.query(sql, [days]);
    return rows;
  }

  /**
   * 管理员更新用户金币（原database.js中的updateUserCoins方法）
   * @param {string} userId - 用户ID
   * @param {number} newAmount - 新金币数量
   * @param {string} reason - 操作原因
   */
  static async adminUpdateUserCoins(userId, newAmount, reason = '管理员调整') {
    const connection = await database.beginTransaction();

    try {
      // 获取当前金币
      const currentSql = 'SELECT coins FROM users WHERE id = ?';
      const [currentRows] = await connection.execute(currentSql, [userId]);
      const currentCoins = currentRows[0]?.coins || 0;

      // 更新金币
      const updateSql = `
        UPDATE users
        SET coins = ?
        WHERE id = ?
      `;
      await connection.execute(updateSql, [newAmount, userId]);

      // 记录管理员操作
      const change = newAmount - currentCoins;
      if (change !== 0) {
        // 首先确保有管理员操作的虚拟商品记录
        const checkItemQuery = 'SELECT id FROM items WHERE id = ?';
        const [checkItemRows] = await connection.execute(checkItemQuery, ['admin_coins_adjustment']);

        if (checkItemRows.length === 0) {
          // 创建管理员操作的虚拟商品
          const createItemQuery = `
            INSERT INTO items (id, name, description, price, sell_price, category, max_quantity, current_stock)
            VALUES ('admin_coins_adjustment', '管理员金币调整', '管理员调整玩家金币的虚拟操作记录', 0, 0, 'system', NULL, NULL)
          `;
          await connection.execute(createItemQuery);
        }

        // 记录管理员操作
        const logSql = `
          INSERT INTO transactions (user_id, type, item_id, quantity, unit_price, total_amount, coins_before, coins_after, notes)
          VALUES (?, 'admin', 'admin_coins_adjustment', 1, ?, ?, ?, ?, ?)
        `;
        await connection.execute(logSql, [userId, change, change, currentCoins, newAmount, `${reason} (变化: ${change > 0 ? '+' : ''}${change})`]);
      }

      await database.commitTransaction(connection);

      return {
        oldCoins: currentCoins,
        newCoins: newAmount,
        difference: change,
      };
    } catch (error) {
      await database.rollbackTransaction(connection);
      throw error;
    }
  }

  // ==================== 管理员操作 ====================

  /**
   * 更新用户状态
   * @param {string} userId - 用户ID
   * @param {string} status - 新状态
   */
  static async updateUserStatus(userId, status) {
    const query = 'UPDATE users SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    await database.query(query, [status, userId]);
    return true;
  }

  /**
   * 更新商品库存
   * @param {string} itemId - 商品ID
   * @param {number} stock - 新库存
   */
  static async updateItemStock(itemId, stock) {
    const query = 'UPDATE items SET current_stock = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    await database.query(query, [stock, itemId]);
    return true;
  }

  /**
   * 更新商品状态
   * @param {string} itemId - 商品ID
   * @param {boolean} active - 是否启用
   */
  static async updateItemStatus(itemId, active) {
    const query = 'UPDATE items SET is_active = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    await database.query(query, [active, itemId]);
    return true;
  }

  /**
   * 获取系统配置列表（原admin.js中的获取配置操作）
   */
  static async getAllSystemConfig() {
    const query = 'SELECT * FROM system_config ORDER BY config_key';
    const { rows } = await database.query(query);
    return rows;
  }

  /**
   * 获取管理员列表
   */
  static async getAdminList() {
    const query = `
       SELECT user_id, username, display_name, created_at, updated_at
       FROM users
       WHERE is_admin = TRUE
       ORDER BY updated_at DESC
     `;

    const { rows } = await database.query(query);
    return rows;
  }

  /**
   * 检查用户是否存在（通过user_id或username）
   * @param {string} userIdOrUsername - 用户ID或用户名
   * @param {boolean} isUserId - 是否为用户ID
   */
  static async checkUserExists(userIdOrUsername, isUserId = true) {
    const field = isUserId ? 'user_id' : 'username';
    const query = `SELECT user_id, username, is_admin FROM users WHERE ${field} = ?`;

    const { rows } = await database.query(query, [userIdOrUsername]);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * 添加管理员
   * @param {Object} userData - 用户数据
   */
  static async addAdmin(userData) {
    const { user_id, username } = userData;

    const query = `
       INSERT INTO users (user_id, username, is_admin, created_at, updated_at)
       VALUES (?, ?, TRUE, NOW(), NOW())
     `;

    await database.query(query, [user_id, username]);
    return true;
  }

  /**
   * 更新用户为管理员
   * @param {string} userId - 用户ID
   */
  static async promoteToAdmin(userId) {
    const query = `
       UPDATE users
       SET is_admin = TRUE, updated_at = NOW()
       WHERE user_id = ?
     `;

    await database.query(query, [userId]);
    return true;
  }

  /**
   * 移除管理员权限
   * @param {string} userId - 用户ID
   */
  static async removeAdmin(userId) {
    const query = `
       UPDATE users
       SET is_admin = FALSE, updated_at = NOW()
       WHERE user_id = ?
     `;

    await database.query(query, [userId]);
    return true;
  }

  /**
   * 获取用户数量统计（带筛选）
   * @param {string} status - 用户状态过滤
   */
  static async getUserCount(status = null) {
    let query = 'SELECT COUNT(*) as total FROM users';
    const params = [];

    if (status) {
      query += ' WHERE status = ?';
      params.push(status);
    }

    const { rows } = await database.query(query, params);
    return rows[0].total;
  }

  /**
   * 获取用户列表（带分页和筛选）
   * @param {Object} options - 查询选项
   */
  static async getUsersWithPagination(options = {}) {
    const { limit = 100, offset = 0, status = null } = options;

    let query = `
      SELECT
        u.*,
        COALESCE(buy_stats.total_spent, 0) as total_spent,
        COALESCE(buy_stats.total_purchases, 0) as total_purchases,
        COALESCE(sell_stats.total_earned, 0) as total_earned,
        COALESCE(sell_stats.total_sales, 0) as total_sales,
        COALESCE(inventory_stats.total_items, 0) as total_items,
        COALESCE(inventory_stats.unique_items, 0) as unique_items
      FROM users u
      LEFT JOIN (
        SELECT
          user_id,
          SUM(total_amount) as total_spent,
          COUNT(*) as total_purchases
        FROM transactions
        WHERE type = 'buy'
        GROUP BY user_id
      ) buy_stats ON u.id = buy_stats.user_id
      LEFT JOIN (
        SELECT
          user_id,
          SUM(total_amount) as total_earned,
          COUNT(*) as total_sales
        FROM transactions
        WHERE type = 'sell'
        GROUP BY user_id
      ) sell_stats ON u.id = sell_stats.user_id
      LEFT JOIN (
        SELECT user_id, SUM(quantity) as total_items, COUNT(*) as unique_items
        FROM user_items
        WHERE quantity > 0
        GROUP BY user_id
      ) inventory_stats ON u.id = inventory_stats.user_id
    `;
    const params = [];

    if (status) {
      query += ' WHERE u.status = ?';
      params.push(status);
    }

    query += ` ORDER BY u.created_at DESC LIMIT ${limit} OFFSET ${offset}`;

    const { rows } = await database.query(query, params);
    return rows;
  }

  // ==================== 系统配置相关操作 ====================

  /**
   * 获取系统配置
   * @returns {Object} 系统配置对象
   */
  static async getSystemConfigAll() {
    const { rows: configRows } = await database.query('SELECT config_key, config_value FROM system_config WHERE is_active = TRUE');

    const config = {};
    configRows.forEach((row) => {
      config[row.config_key] = row.config_value;
    });

    return config;
  }

  /**
   * 获取管理员用户名列表
   * @returns {Array} 管理员用户名数组
   */
  static async getAdminUsernames() {
    const { rows: adminRows } = await database.query('SELECT username FROM users WHERE is_admin = TRUE');
    return adminRows.filter((row) => row.username).map((row) => row.username);
  }

  /**
   * 检查用户是否存在并获取管理员状态
   * @param {string} username - 用户名
   * @returns {Object|null} 用户信息或null
   */
  static async getUserByUsername(username) {
    const { rows: userRows } = await database.query('SELECT id, is_admin FROM users WHERE username = ?', [username]);
    return userRows.length > 0 ? userRows[0] : null;
  }

  /**
   * 通过用户名设置用户为管理员
   * @param {string} username - 用户名
   * @returns {boolean} 操作是否成功
   */
  static async setAdminByUsername(username) {
    await database.query('UPDATE users SET is_admin = TRUE, updated_at = CURRENT_TIMESTAMP WHERE username = ?', [username]);
    return true;
  }
}

module.exports = SQLOperations;
