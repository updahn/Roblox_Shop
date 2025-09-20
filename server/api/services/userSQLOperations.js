/**
 * 普通用户SQL操作服务
 * 包含所有普通用户相关的数据库操作
 */

const database = require('../config/database');
const { AppError } = require('../middleware/errorHandler');

class UserSQLOperations {
  /**
   * 购买商品操作
   * @param {string} userId - 用户ID
   * @param {string} itemId - 商品ID
   * @param {number} quantity - 购买数量
   */
  static async buyItem(userId, itemId, quantity) {
    try {
      // 检查商品是否存在且启用
      const itemQuery = 'SELECT price, max_quantity, current_stock, daily_purchase_limit FROM items WHERE id = ? AND is_active = TRUE';
      const { rows: itemRows } = await database.query(itemQuery, [itemId]);

      if (itemRows.length === 0) {
        throw new AppError('商品不存在或已禁用', 400);
      }

      const item = itemRows[0];
      const itemPrice = item.price;
      const maxQuantity = item.max_quantity;
      const currentStock = item.current_stock;
      const dailyPurchaseLimit = item.daily_purchase_limit;

      // 检查库存（-1表示无限库存）
      if (currentStock !== -1 && currentStock < quantity) {
        throw new AppError(`库存不足，当前库存: ${currentStock}，尝试购买: ${quantity}`, 400);
      }

      // 检查数量限制
      if (maxQuantity !== null && quantity > maxQuantity) {
        throw new AppError(`购买数量超过限制，最大可购买: ${maxQuantity}`, 400);
      }

      // 检查每日限购（从transactions表中统计）
      if (dailyPurchaseLimit !== null) {
        const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD格式
        const dailyPurchaseQuery = `
          SELECT COALESCE(SUM(quantity), 0) as purchased_today
          FROM transactions
          WHERE user_id = ? AND item_id = ? AND transaction_date = ? AND type = 'buy'
        `;
        const { rows: dailyRows } = await database.query(dailyPurchaseQuery, [userId, itemId, today]);
        const purchasedToday = dailyRows.length > 0 ? dailyRows[0].purchased_today : 0;

        if (purchasedToday + quantity > dailyPurchaseLimit) {
          const remaining = dailyPurchaseLimit - purchasedToday;
          throw new AppError(`每日购买限额已达到，今日剩余可购买: ${remaining}，尝试购买: ${quantity}`, 400);
        }
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

        // 记录交易（包含交易日期）
        const today = new Date().toISOString().split('T')[0];
        const coinsAfter = userCoins - totalCost;
        const insertTransactionQuery = `
          INSERT INTO transactions (user_id, item_id, type, quantity, unit_price, total_amount, coins_before, coins_after, transaction_date, created_at)
          VALUES (?, ?, 'buy', ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        `;
        await connection.execute(insertTransactionQuery, [userId, itemId, quantity, itemPrice, totalCost, userCoins, coinsAfter, today]);

        return {
          success: true,
          totalCost,
          taxAmount,
          baseCost,
          itemPrice,
          quantity,
        };
      });
    } catch (error) {
      console.error('Purchase error:', error);
      throw error;
    }
  }

  /**
   * 出售商品操作
   * @param {string} userId - 用户ID
   * @param {string} itemId - 商品ID
   * @param {number} quantity - 出售数量
   */
  static async sellItem(userId, itemId, quantity) {
    try {
      // 检查用户是否拥有足够的商品
      const userItemQuery = 'SELECT quantity FROM user_items WHERE user_id = ? AND item_id = ?';
      const { rows: userItemRows } = await database.query(userItemQuery, [userId, itemId]);

      if (userItemRows.length === 0 || userItemRows[0].quantity < quantity) {
        const ownedQuantity = userItemRows.length > 0 ? userItemRows[0].quantity : 0;
        throw new AppError(`拥有的物品数量不足，拥有: ${ownedQuantity}，尝试出售: ${quantity}`, 400);
      }

      // 获取商品价格和卖出属性
      const itemQuery = 'SELECT price, can_sell FROM items WHERE id = ?';
      const { rows: itemRows } = await database.query(itemQuery, [itemId]);

      if (itemRows.length === 0) {
        throw new AppError('商品不存在', 404);
      }

      // 检查商品是否可以卖出
      if (!itemRows[0].can_sell) {
        throw new AppError('该商品无法卖出', 400);
      }

      const itemPrice = itemRows[0].price;
      const sellRate = parseFloat((await this.getSellRate()) || '0.8');
      const unitSellPrice = itemPrice * sellRate;
      const totalValue = unitSellPrice * quantity;

      // 获取用户当前金币
      const userCoinsQuery = 'SELECT coins FROM users WHERE id = ?';
      const { rows: userCoinsRows } = await database.query(userCoinsQuery, [userId]);
      const userCoinsBefore = userCoinsRows[0].coins;

      // 使用事务
      return await database.transaction(async (connection) => {
        // 增加金币
        const updateCoinsQuery = 'UPDATE users SET coins = coins + ? WHERE id = ?';
        await connection.execute(updateCoinsQuery, [totalValue, userId]);

        // 减少用户物品
        const updateItemQuery = 'UPDATE user_items SET quantity = quantity - ? WHERE user_id = ? AND item_id = ?';
        await connection.execute(updateItemQuery, [quantity, userId, itemId]);

        // 记录交易
        const today = new Date().toISOString().split('T')[0];
        const coinsAfter = userCoinsBefore + totalValue;
        const insertTransactionQuery = `
          INSERT INTO transactions (user_id, item_id, type, quantity, unit_price, total_amount, coins_before, coins_after, transaction_date, created_at)
          VALUES (?, ?, 'sell', ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        `;
        await connection.execute(insertTransactionQuery, [userId, itemId, quantity, unitSellPrice, totalValue, userCoinsBefore, coinsAfter, today]);

        return {
          success: true,
          totalValue,
          unitSellPrice,
          quantity,
        };
      });
    } catch (error) {
      console.error('Sell error:', error);
      throw error;
    }
  }

  /**
   * 获取用户详细信息
   */
  static async getUserDetails(userId) {
    // 验证 userId 参数
    if (userId === undefined || userId === null || userId === '') {
      throw new AppError('用户ID不能为空', 400);
    }

    // 确保 userId 是有效的（非空字符串或数字）
    const sanitizedUserId = String(userId).trim();
    if (!sanitizedUserId) {
      throw new AppError('用户ID无效', 400);
    }

    const query = `
      SELECT
        id,
        username,
        display_name,
        coins,
        is_admin,
        status,
        created_at,
        updated_at,
        last_login
      FROM users
      WHERE id = ?
    `;

    try {
      const { rows } = await database.query(query, [sanitizedUserId]);
      const result = rows.length > 0 ? rows[0] : null;

      // 确保is_admin字段被正确转换为布尔值（与AdminSQLOperations保持一致）
      if (result) {
        result.is_admin = Boolean(result.is_admin);
      }

      return result;
    } catch (error) {
      console.error('获取用户详情错误:', {
        userId: sanitizedUserId,
        error: error.message,
      });
      throw error;
    }
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
        (i.price * (SELECT COALESCE(config_value, '0.8') FROM system_config WHERE config_key = 'sell_rate')) as actual_sell_price
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
        t.item_id,
        i.name as item_name,
        t.type,
        t.quantity,
        t.unit_price,
        t.total_amount,
        t.transaction_date,
        t.created_at
      FROM transactions t
      LEFT JOIN items i ON t.item_id = i.id
      WHERE t.user_id = ?
      ORDER BY t.created_at DESC
      LIMIT ${parsedLimit}
    `;

    const { rows } = await database.query(query, [userId]);
    return rows;
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
   * 获取出售比率
   */
  static async getSellRate() {
    const sellRate = await this.getSystemConfig('sell_rate');
    return sellRate || '0.8';
  }

  /**
   * 创建或登录用户
   */
  static async createOrLoginUser(userId, username, displayName = null) {
    return await database.transaction(async (connection) => {
      // 检查用户是否存在
      const checkQuery = 'SELECT id, username, display_name, is_admin, last_login FROM users WHERE id = ?';
      const [existingRows] = await connection.execute(checkQuery, [userId]);

      if (existingRows.length > 0) {
        // 用户存在，更新最后登录时间
        const updateQuery = 'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?';
        await connection.execute(updateQuery, [userId]);

        // 确保is_admin字段被正确转换为布尔值
        const user = existingRows[0];
        user.is_admin = Boolean(user.is_admin);

        return {
          isNewUser: false,
          user: user,
        };
      } else {
        // 创建新用户，从系统配置获取默认金币
        const defaultCoins = parseInt((await this.getSystemConfig('default_coins_for_new_user')) || '1000');
        const insertQuery = `
          INSERT INTO users (id, username, display_name, coins, created_at, updated_at, last_login)
          VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        `;

        await connection.execute(insertQuery, [userId, username, displayName || username, defaultCoins]);

        // 获取新创建的用户信息
        const [newUserRows] = await connection.execute(checkQuery, [userId]);

        // 确保is_admin字段被正确转换为布尔值
        const newUser = newUserRows[0];
        newUser.is_admin = Boolean(newUser.is_admin);

        return {
          isNewUser: true,
          user: newUser,
        };
      }
    });
  }

  /**
   * 获取商品列表
   */
  static async getItems(activeOnly = true) {
    let query = `
      SELECT
        id, name, description, price, category, max_quantity,
        current_stock, daily_purchase_limit, is_active,
        created_at, updated_at
      FROM items
    `;

    const params = [];

    if (activeOnly) {
      query += ' WHERE is_active = TRUE';
    }

    // 让会员商品排在最前面，然后按分类和名称排序
    query += ' ORDER BY CASE WHEN category = "membership" THEN 0 ELSE 1 END, category, name';

    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取商品列表（带选项）
   */
  static async getItemsWithOptions(options = {}) {
    const { activeOnly = true, category = null, search = null, limit = 50, offset = 0 } = options;

    let query = `
      SELECT
        id, name, description, price, category, max_quantity,
        current_stock, daily_purchase_limit, is_active,
        created_at, updated_at
      FROM items
    `;

    const params = [];
    const conditions = [];

    if (activeOnly) {
      conditions.push('is_active = TRUE');
    }

    if (category && category !== 'undefined' && category !== 'null' && category.trim() !== '') {
      conditions.push('category = ?');
      params.push(category.trim());
    }

    if (search && search.trim() !== '') {
      conditions.push('(name LIKE ? OR description LIKE ?)');
      params.push(`%${search.trim()}%`, `%${search.trim()}%`);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    // 让会员商品排在最前面，然后按分类和名称排序
    query += ' ORDER BY CASE WHEN category = "membership" THEN 0 ELSE 1 END, category, name';

    if (limit && limit > 0) {
      query += ` LIMIT ${parseInt(limit)}`;
      if (offset && offset > 0) {
        query += ` OFFSET ${parseInt(offset)}`;
      }
    }

    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取单个商品信息
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
   * 获取交易记录（带筛选）
   */
  static async getTransactions(options = {}) {
    const { userId, type = null, limit = 50, offset = 0 } = options;

    // 验证和转换参数
    const sanitizedUserId = String(userId).trim();
    const parsedLimit = Math.min(1000, Math.max(1, parseInt(limit) || 50));
    const parsedOffset = Math.max(0, parseInt(offset) || 0);

    // 验证必要参数
    if (!sanitizedUserId || sanitizedUserId === '') {
      throw new Error('无效的用户ID');
    }

    let whereClause = 'WHERE t.user_id = ?';
    const params = [sanitizedUserId];

    if (type && typeof type === 'string' && type.trim() !== '') {
      whereClause += ' AND t.type = ?';
      params.push(type.trim());
    }

    const query = `
      SELECT
        t.id,
        t.item_id,
        i.name as item_name,
        t.type,
        t.quantity,
        t.unit_price,
        t.total_amount,
        t.transaction_date,
        t.created_at
      FROM transactions t
      LEFT JOIN items i ON t.item_id = i.id
      ${whereClause}
      ORDER BY t.created_at DESC
      LIMIT ${parsedLimit} OFFSET ${parsedOffset}
    `
      .trim()
      .replace(/\s+/g, ' ');
    const { rows } = await database.query(query, params);
    return rows;
  }

  /**
   * 获取用户交易统计
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
   * 获取用户最常购买的商品
   */
  static async getUserTopItems(userId, limit = 10) {
    // 确保 limit 是有效的整数
    const parsedLimit = Math.min(100, Math.max(1, parseInt(limit) || 10));

    const query = `
      SELECT
        t.item_id,
        i.name as item_name,
        SUM(t.quantity) as total_quantity,
        COUNT(*) as purchase_count,
        SUM(t.total_amount) as total_spent
      FROM transactions t
      JOIN items i ON t.item_id = i.id
      WHERE t.user_id = ? AND t.type = 'buy'
      GROUP BY t.item_id, i.name
      ORDER BY total_quantity DESC
      LIMIT ${parsedLimit}
    `;

    const { rows } = await database.query(query, [userId]);
    return rows;
  }

  /**
   * 获取用户库存价值
   */
  static async getUserInventoryValue(userId) {
    const query = `
      SELECT
        COUNT(*) as total_items,
        SUM(ui.quantity) as total_quantity,
        SUM(ui.quantity * i.price) as total_value,
        SUM(ui.quantity * i.price * (SELECT COALESCE(config_value, '0.8') FROM system_config WHERE config_key = 'sell_rate')) as sell_value
      FROM user_items ui
      JOIN items i ON ui.item_id = i.id
      WHERE ui.user_id = ? AND ui.quantity > 0
    `;

    const { rows } = await database.query(query, [userId]);
    return rows[0] || { total_items: 0, total_quantity: 0, total_value: 0, sell_value: 0 };
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
   * 处理登录奖励（包括补发未登录天数的奖励）
   */
  static async processLoginRewards(userId) {
    return await database.transaction(async (connection) => {
      // 检查用户是否有有效会员
      const membershipQuery = `
        SELECT id, daily_reward_coins, end_date, start_date
        FROM monthly_memberships
        WHERE user_id = ? AND is_active = TRUE AND end_date >= CURDATE()
        ORDER BY end_date DESC
        LIMIT 1
      `;

      const [membershipRows] = await connection.execute(membershipQuery, [userId]);

      if (membershipRows.length === 0) {
        return {
          success: false,
          message: '没有有效的会员资格',
          canClaim: false,
          totalRewards: 0,
        };
      }

      const membership = membershipRows[0];
      const today = new Date().toISOString().split('T')[0];
      const dailyReward = membership.daily_reward_coins;

      // 获取系统配置中的最大补发天数
      const maxMissedDaysQuery = `
        SELECT config_value FROM system_config WHERE config_key = 'membership_max_missed_rewards'
      `;
      const [configRows] = await connection.execute(maxMissedDaysQuery, []);
      const maxMissedDays = configRows.length > 0 ? parseInt(configRows[0].config_value) : 7;

      // 获取用户已领取奖励的最后日期
      const lastRewardQuery = `
        SELECT MAX(reward_date) as last_reward_date
        FROM daily_rewards
        WHERE user_id = ? AND membership_id = ?
      `;
      const [lastRewardRows] = await connection.execute(lastRewardQuery, [userId, membership.id]);

      // 确定开始计算的日期
      let startDate;
      if (lastRewardRows.length > 0 && lastRewardRows[0].last_reward_date) {
        // 从最后领取日期的第二天开始
        const lastDate = new Date(lastRewardRows[0].last_reward_date);
        lastDate.setDate(lastDate.getDate() + 1);
        startDate = lastDate.toISOString().split('T')[0];
      } else {
        // 如果没有领取记录，从会员开始日期开始
        startDate = membership.start_date;
      }

      // 计算需要补发的日期范围
      const startDateTime = new Date(startDate);
      const todayDateTime = new Date(today);
      const membershipStartDate = new Date(membership.start_date);

      // 确保开始日期不早于会员开始日期
      if (startDateTime < membershipStartDate) {
        startDate = membership.start_date;
      }

      // 计算需要补发的天数，限制在最大补发天数内
      const timeDiff = todayDateTime.getTime() - new Date(startDate).getTime();
      const totalDaysToReward = Math.min(Math.floor(timeDiff / (1000 * 3600 * 24)) + 1, maxMissedDays + 1);

      if (totalDaysToReward <= 0) {
        return {
          success: false,
          message: '今日奖励已领取',
          canClaim: false,
          alreadyClaimed: true,
          totalRewards: 0,
        };
      }

      // 检查哪些日期还没有领取奖励
      const datesToReward = [];
      const currentDate = new Date(startDate);

      for (let i = 0; i < totalDaysToReward; i++) {
        const dateStr = currentDate.toISOString().split('T')[0];

        // 检查这一天是否已经领取过奖励
        const checkRewardQuery = `
          SELECT id FROM daily_rewards
          WHERE user_id = ? AND membership_id = ? AND reward_date = ?
        `;
        const [existingRows] = await connection.execute(checkRewardQuery, [userId, membership.id, dateStr]);

        if (existingRows.length === 0) {
          datesToReward.push(dateStr);
        }

        currentDate.setDate(currentDate.getDate() + 1);

        // 不超过今天
        if (currentDate > todayDateTime) {
          break;
        }
      }

      if (datesToReward.length === 0) {
        return {
          success: false,
          message: '今日奖励已领取',
          canClaim: false,
          alreadyClaimed: true,
          totalRewards: 0,
        };
      }

      // 计算总奖励金额
      const totalRewardAmount = dailyReward * datesToReward.length;

      // 获取用户当前金币数量（用于记录交易）
      const userCoinsQuery = 'SELECT coins FROM users WHERE id = ?';
      const [userCoinsRows] = await connection.execute(userCoinsQuery, [userId]);
      const coinsBefore = userCoinsRows.length > 0 ? userCoinsRows[0].coins : 0;

      // 更新用户金币
      const updateCoinsQuery = 'UPDATE users SET coins = coins + ? WHERE id = ?';
      await connection.execute(updateCoinsQuery, [totalRewardAmount, userId]);

      // 记录每日奖励到daily_rewards表
      for (const rewardDate of datesToReward) {
        const insertRewardQuery = `
          INSERT INTO daily_rewards (user_id, reward_date, reward_coins, membership_id, claimed_at)
          VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
        `;
        await connection.execute(insertRewardQuery, [userId, rewardDate, dailyReward, membership.id]);
      }

      // 记录交易到transactions表
      const coinsAfter = coinsBefore + totalRewardAmount;
      const insertTransactionQuery = `
        INSERT INTO transactions (
          user_id, type, quantity, unit_price, total_amount,
          coins_before, coins_after, transaction_date,
          related_id, notes, created_at
        ) VALUES (?, 'daily_reward', ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `;

      const notes = datesToReward.length === 1 ? `每日登录奖励 (${datesToReward[0]})` : `补发每日登录奖励 (${datesToReward[0]} 至 ${datesToReward[datesToReward.length - 1]}, 共${datesToReward.length}天)`;

      await connection.execute(insertTransactionQuery, [userId, datesToReward.length, dailyReward, totalRewardAmount, coinsBefore, coinsAfter, today, membership.id, notes]);

      return {
        success: true,
        message: datesToReward.length === 1 ? '每日奖励领取成功' : `每日奖励领取成功，补发了${datesToReward.length}天的奖励`,
        canClaim: true,
        rewardAmount: dailyReward,
        totalRewards: totalRewardAmount,
        rewardedDays: datesToReward.length,
        membershipType: 'monthly',
        datesToReward: datesToReward,
      };
    });
  }

  /**
   * 购买会员商品
   */
  static async buyMembershipItem(userId, itemId, quantity) {
    // 支持的会员商品类型
    const validMembershipItems = ['monthly_membership', 'weekly_membership', 'quarterly_membership', 'premium_membership', 'vip_membership'];

    if (!validMembershipItems.includes(itemId)) {
      throw new AppError('无效的会员商品ID', 400);
    }

    // 获取会员商品的价格（从items表中获取）
    const itemQuery = 'SELECT price FROM items WHERE id = ? AND is_active = TRUE';
    const { rows: itemRows } = await database.query(itemQuery, [itemId]);

    if (itemRows.length === 0) {
      throw new AppError('会员商品不存在或已下架', 404);
    }

    const membershipPrice = itemRows[0].price;
    const totalCost = membershipPrice * quantity;

    // 根据会员类型获取持续天数配置
    let durationConfigKey, rewardConfigKey;
    switch (itemId) {
      case 'weekly_membership':
        durationConfigKey = 'weekly_membership_duration_days';
        rewardConfigKey = 'membership_daily_reward';
        break;
      case 'quarterly_membership':
        durationConfigKey = 'quarterly_membership_duration_days';
        rewardConfigKey = 'membership_daily_reward';
        break;
      case 'premium_membership':
        durationConfigKey = 'membership_duration_days';
        rewardConfigKey = 'premium_membership_daily_reward';
        break;
      case 'vip_membership':
        durationConfigKey = 'vip_membership_duration_days';
        rewardConfigKey = 'vip_membership_daily_reward';
        break;
      default: // monthly_membership
        durationConfigKey = 'membership_duration_days';
        rewardConfigKey = 'membership_daily_reward';
        break;
    }

    const membershipDurationDays = parseInt((await this.getSystemConfig(durationConfigKey)) || '30');
    const durationDays = membershipDurationDays * quantity;

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

    return await database.transaction(async (connection) => {
      // 扣除金币
      const updateCoinsQuery = 'UPDATE users SET coins = coins - ? WHERE id = ?';
      await connection.execute(updateCoinsQuery, [totalCost, userId]);

      // 获取每日奖励配置
      const dailyReward = parseInt((await this.getSystemConfig(rewardConfigKey)) || '100');

      // 检查用户是否已有活跃会员
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
        // 如果有现有活跃会员，从结束日期开始延期
        const existingEndDate = new Date(existingRows[0].end_date);
        startDate = existingEndDate > now ? existingEndDate : now;

        // 将现有会员设为不活跃
        const deactivateQuery = 'UPDATE monthly_memberships SET is_active = FALSE WHERE user_id = ?';
        await connection.execute(deactivateQuery, [userId]);
      } else {
        // 新会员从今天开始
        startDate = now;
      }

      endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + durationDays);

      // 插入新的会员记录
      const insertQuery = `
        INSERT INTO monthly_memberships (
          user_id, start_date, end_date, daily_reward_coins, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, ?, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      `;

      const [membershipResult] = await connection.execute(insertQuery, [userId, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0], dailyReward]);

      // 记录交易
      const today = new Date().toISOString().split('T')[0];
      const coinsAfter = userCoins - totalCost;
      const insertTransactionQuery = `
        INSERT INTO transactions (user_id, item_id, type, quantity, unit_price, total_amount, coins_before, coins_after, transaction_date, related_id, notes, created_at)
        VALUES (?, ?, 'membership_purchase', ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `;
      await connection.execute(insertTransactionQuery, [userId, itemId, quantity, membershipPrice, totalCost, userCoins, coinsAfter, today, membershipResult.insertId, `购买${quantity}个月会员，有效期${durationDays}天`]);

      // 购买会员后立即处理当日奖励
      // 先提交当前事务，然后处理奖励
      const membershipData = {
        success: true,
        totalCost,
        membershipDays: durationDays,
        dailyReward,
        startDate: startDate.toISOString().split('T')[0],
        endDate: endDate.toISOString().split('T')[0],
        membershipId: membershipResult.insertId,
      };

      return membershipData;
    });

    // 在事务提交后，立即触发当日奖励处理
    try {
      const rewardResult = await this.processLoginRewards(userId);
      if (rewardResult.success && rewardResult.totalRewards > 0) {
        console.log(`🎁 [会员购买奖励] 用户 ${userId} 购买会员后立即获得 ${rewardResult.totalRewards} 金币奖励`);
        result.immediateReward = {
          success: true,
          rewardAmount: rewardResult.totalRewards,
          message: rewardResult.message,
        };
      }
    } catch (rewardError) {
      console.warn(`⚠️  [会员购买奖励] 用户 ${userId} 购买会员后处理当日奖励时出错:`, rewardError.message);
      // 不影响主要的购买流程，只是记录警告
      result.immediateReward = {
        success: false,
        message: '购买成功，但当日奖励处理失败，请手动领取',
      };
    }

    return result;
  }

  /**
   * 获取交易统计
   */
  static async getTransactionStats(days = 30) {
    const query = `
      SELECT
        type,
        COUNT(*) as count,
        SUM(total_amount) as total_amount,
        AVG(total_amount) as avg_amount
      FROM transactions
      WHERE created_at >= DATE_SUB(CURRENT_DATE, INTERVAL ? DAY)
      GROUP BY type
    `;

    const { rows } = await database.query(query, [days]);
    return rows;
  }
}

module.exports = UserSQLOperations;
