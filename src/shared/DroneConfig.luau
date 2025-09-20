--[[
无人机系统配置文件

本文件包含无人机系统的所有配置参数。

功能要求：
1. 玩家可召唤一个无人机, 无人机具有跟随和驻守模式, 初始为跟随模式
2. 无人机存在时会定时攻击范围内的非玩家目标
3. 无人机可切换模式
4. 无人机可收回
5. 无人机单次可存在10秒, 切换模式不重新计时

用法：
  local DroneConfig = require(路径到该文件)
  DroneConfig.DRONE.LIFETIME -- 获取无人机生存时间
--]]

local DroneConfig = {}

-- ==============================================
-- 无人机基础配置
-- ==============================================

DroneConfig.DRONE = {
    -- 生存时间配置
    LIFETIME = 10,  -- 无人机生存时间（秒）

    -- 移动配置
    FOLLOW_DISTANCE = 8,  -- 跟随模式下的距离
    FOLLOW_HEIGHT = 10,   -- 跟随高度
    HOVER_HEIGHT = 12,    -- 驻守模式下的悬停高度
    MOVEMENT_SPEED = 16,  -- 移动速度

    -- 攻击配置
    ATTACK_RANGE = 50,    -- 攻击范围
    ATTACK_INTERVAL = 1,  -- 攻击间隔（秒）
    ATTACK_DAMAGE = 30,   -- 攻击伤害

    -- 视觉效果配置
    SIZE_SCALE = 1,       -- 无人机大小缩放
    EFFECTS = {
        SPAWN_EFFECT = true,    -- 生成特效
        ATTACK_EFFECT = true,   -- 攻击特效
        EXPLOSION_EFFECT = true,-- 爆炸特效
        DESTROY_EFFECT = true,  -- 销毁特效
    }
}

-- ==============================================
-- 无人机模式配置
-- ==============================================

DroneConfig.MODES = {
    FOLLOW = "follow",    -- 跟随模式
    GUARD = "guard"       -- 驻守模式
}

-- ==============================================
-- 无人机模型配置
-- ==============================================

DroneConfig.MODEL = {
    -- 使用Roblox免费模型库的无人机模型
    -- 如果此模型ID无法加载，系统会自动使用备用模型
    ASSET_ID = "rbxassetid://5129458730",

    -- 备用模型ID列表（如果主要模型无法加载时尝试）
    FALLBACK_ASSET_IDS = {
        "rbxassetid://5129458730",  -- 原始模型
        "rbxassetid://1390779",     -- Roblox官方汽车模型
        "rbxassetid://1374148",     -- 经典Roblox载具
        "rbxassetid://16159032",    -- 简单飞行器
        "rbxassetid://16384448",    -- 球形载具
    },

    -- 模型部件名称
    PARTS = {
        MAIN_BODY = "Body",
        PROPELLERS = {"Propeller1", "Propeller2", "Propeller3", "Propeller4"},
        LASER = "Laser"  -- 激光发射器部件
    }
}

-- ==============================================
-- 音效配置
-- ==============================================

DroneConfig.SOUNDS = {
    SPAWN = "rbxasset://sounds/electronicpingshort.wav",
    ATTACK = "rbxasset://sounds/impact_punch.mp3", -- 使用punch音效替代generic
    DESTROY = "rbxasset://sounds/snap.wav",
    HOVER = "rbxasset://sounds/ambient.ogg",
    VOLUME = {
        SPAWN = 0.5,
        ATTACK = 0.3,
        DESTROY = 0.4,
        HOVER = 0.2
    }
}

-- ==============================================
-- 粒子效果配置
-- ==============================================

DroneConfig.EFFECTS = {
    SPAWN_EFFECT = {
        PARTICLE_COUNT = 50,
        LIFETIME = 2,
        COLOR = Color3.fromRGB(0, 162, 255)
    },
    ATTACK_EFFECT = {
        BEAM_COLOR = Color3.fromRGB(255, 0, 0),
        BEAM_WIDTH = 0.2,
        BEAM_DURATION = 0.1
    },
    EXPLOSION_EFFECT = {
        ENABLED = true,
        SPARK_PARTICLES = 200,
        SMOKE_PARTICLES = 50,
        LIGHT_BRIGHTNESS = 5,
        LIGHT_RANGE = 15,
        BALL_SIZE = Vector3.new(8, 8, 8),
        DURATION = 3
    },
    DESTROY_EFFECT = {
        PARTICLE_COUNT = 30,
        LIFETIME = 1.5,
        COLOR = Color3.fromRGB(255, 255, 255)
    }
}

-- ==============================================
-- UI配置
-- ==============================================

DroneConfig.UI = {
    BUTTON_SIZE = UDim2.new(0, 120, 0, 40),
    BUTTON_POSITION = UDim2.new(1, -140, 1, -60),

    COLORS = {
        SPAWN_BUTTON = Color3.fromRGB(52, 211, 153),    -- 绿色
        RECALL_BUTTON = Color3.fromRGB(248, 113, 113),  -- 红色
        MODE_BUTTON = Color3.fromRGB(88, 166, 255),     -- 蓝色
        DISABLED = Color3.fromRGB(100, 100, 100)        -- 灰色
    },

    TEXT = {
        SPAWN = "召唤无人机",
        RECALL = "收回无人机",
        MODE_FOLLOW = "跟随模式",
        MODE_GUARD = "驻守模式",
        SWITCH_TO_FOLLOW = "切换到跟随",
        SWITCH_TO_GUARD = "切换到驻守"
    }
}

-- ==============================================
-- 靶子系统配置
-- ==============================================

DroneConfig.TARGETS = {
    COUNT = 3,  -- 靶子数量
    SPAWN_RADIUS = 100,  -- 靶子生成半径
    HEIGHT = 5,  -- 靶子高度
    MAX_HEALTH = 100,  -- 靶子最大血量
    RESPAWN_TIME = 10,  -- 靶子重生时间（秒）

    -- 靶子外观
    APPEARANCE = {
        COLOR = Color3.fromRGB(255, 100, 100),  -- 红色
        SIZE = Vector3.new(4, 6, 1),  -- 宽x高x厚
        MATERIAL = Enum.Material.Neon,
    },

    -- 靶子标识
    MARKER = {
        ENABLED = true,
        TEXT = "靶子",
        TEXT_SIZE = 24,
        TEXT_COLOR = Color3.fromRGB(255, 255, 255)
    }
}

-- ==============================================
-- 调试配置
-- ==============================================

DroneConfig.DEBUG = {
    ENABLED = game:GetService("RunService"):IsStudio(),
    SHOW_ATTACK_RANGE = false,  -- 显示攻击范围球体
    VERBOSE_LOGGING = true      -- 详细日志输出
}

-- ==============================================
-- 工具函数
-- ==============================================

function DroneConfig.log(message, ...)
    if DroneConfig.DEBUG.ENABLED and DroneConfig.DEBUG.VERBOSE_LOGGING then
        print("[无人机系统]", message, ...)
    end
end

return DroneConfig
