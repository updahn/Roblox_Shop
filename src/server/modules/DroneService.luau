-- 无人机系统服务端模块
-- 处理无人机的生成、控制、攻击和销毁逻辑

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DroneService = {}

-- 等待模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local DroneConfig = require(SharedModules:WaitForChild("DroneConfig"))
local Events = require(SharedModules:WaitForChild("ShopEvents"))

-- 活跃无人机管理
local activeDrones = {} -- [player] = droneData

-- ==============================================
-- 内部工具函数
-- ==============================================

local function log(message, ...)
    DroneConfig.log("[服务端]", message, ...)
end

-- 创建攻击特效
local function createAttackEffect(startPos, endPos)
    if not DroneConfig.DRONE.EFFECTS.ATTACK_EFFECT then return end

    -- 创建激光束特效
    local beam = Instance.new("Beam")
    local attachment1 = Instance.new("Attachment")
    local attachment2 = Instance.new("Attachment")

    -- 创建临时部件来承载attachment
    local part1 = Instance.new("Part")
    part1.Anchored = true
    part1.CanCollide = false
    part1.Transparency = 1
    part1.Size = Vector3.new(0.1, 0.1, 0.1)
    part1.Position = startPos
    part1.Parent = workspace

    local part2 = Instance.new("Part")
    part2.Anchored = true
    part2.CanCollide = false
    part2.Transparency = 1
    part2.Size = Vector3.new(0.1, 0.1, 0.1)
    part2.Position = endPos
    part2.Parent = workspace

    attachment1.Parent = part1
    attachment2.Parent = part2

    beam.Attachment0 = attachment1
    beam.Attachment1 = attachment2
    beam.Color = ColorSequence.new(DroneConfig.EFFECTS.ATTACK_EFFECT.BEAM_COLOR)
    beam.Width0 = DroneConfig.EFFECTS.ATTACK_EFFECT.BEAM_WIDTH
    beam.Width1 = DroneConfig.EFFECTS.ATTACK_EFFECT.BEAM_WIDTH
    beam.Parent = part1

    -- 自动清理
    Debris:AddItem(part1, DroneConfig.EFFECTS.ATTACK_EFFECT.BEAM_DURATION)
    Debris:AddItem(part2, DroneConfig.EFFECTS.ATTACK_EFFECT.BEAM_DURATION)
end

-- 创建爆炸特效
local function createExplosionEffect(position)
    if not DroneConfig.DRONE.EFFECTS.EXPLOSION_EFFECT then return end

    -- 创建爆炸效果容器
    local effectPart = Instance.new("Part")
    effectPart.Name = "ExplosionEffect"
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
    effectPart.Position = position
    effectPart.Parent = workspace

    -- 创建爆炸光球
    local explosionBall = Instance.new("Part")
    explosionBall.Name = "ExplosionBall"
    explosionBall.Anchored = true
    explosionBall.CanCollide = false
    explosionBall.Material = Enum.Material.ForceField
    explosionBall.BrickColor = BrickColor.new("Bright orange")
    explosionBall.Shape = Enum.PartType.Ball
    explosionBall.Size = Vector3.new(0.1, 0.1, 0.1)
    explosionBall.Position = position
    explosionBall.Parent = effectPart

    -- 添加发光效果
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(255, 165, 0)
    pointLight.Brightness = 5
    pointLight.Range = 15
    pointLight.Parent = explosionBall

    -- 创建粒子效果
    local attachment = Instance.new("Attachment")
    attachment.Parent = explosionBall

    -- 火花粒子
    local sparkParticles = Instance.new("ParticleEmitter")
    sparkParticles.Parent = attachment
    sparkParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkParticles.Lifetime = NumberRange.new(0.3, 0.8)
    sparkParticles.Rate = 200
    sparkParticles.SpreadAngle = Vector2.new(360, 360)
    sparkParticles.Speed = NumberRange.new(10, 25)
    sparkParticles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    }
    sparkParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0)
    }

    -- 烟雾粒子
    local smokeParticles = Instance.new("ParticleEmitter")
    smokeParticles.Parent = attachment
    smokeParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
    smokeParticles.Lifetime = NumberRange.new(1, 2)
    smokeParticles.Rate = 50
    smokeParticles.SpreadAngle = Vector2.new(45, 45)
    smokeParticles.Speed = NumberRange.new(5, 15)
    smokeParticles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50))
    }
    smokeParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 2),
        NumberSequenceKeypoint.new(1, 3)
    }
    smokeParticles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }

    -- 爆炸球扩展动画
    local expandTween = TweenService:Create(
        explosionBall,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(8, 8, 8), Transparency = 1}
    )

    -- 光线衰减动画
    local lightTween = TweenService:Create(
        pointLight,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Brightness = 0, Range = 5}
    )

    -- 播放动画
    expandTween:Play()
    lightTween:Play()

    -- 使用spawn来异步停止粒子发射
    spawn(function()
        wait(0.1)
        sparkParticles.Enabled = false
        smokeParticles.Enabled = false
    end)

    -- 清理效果
    Debris:AddItem(effectPart, 3)

    log("创建爆炸特效于位置:", position)
end

-- 创建生成特效
local function createSpawnEffect(position)
    if not DroneConfig.DRONE.EFFECTS.SPAWN_EFFECT then return end

    -- 创建粒子发射器
    local effectPart = Instance.new("Part")
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Size = Vector3.new(1, 1, 1)
    effectPart.Position = position
    effectPart.Parent = workspace

    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart

    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Enabled = true
    particles.Lifetime = NumberRange.new(DroneConfig.EFFECTS.SPAWN_EFFECT.LIFETIME)
    particles.Rate = DroneConfig.EFFECTS.SPAWN_EFFECT.PARTICLE_COUNT
    particles.Color = ColorSequence.new(DroneConfig.EFFECTS.SPAWN_EFFECT.COLOR)
    particles.VelocityInheritance = 0.5
    particles.Speed = NumberRange.new(5, 15)

    -- 停止发射并清理
    spawn(function()
        wait(0.5)
        particles.Enabled = false
        Debris:AddItem(effectPart, DroneConfig.EFFECTS.SPAWN_EFFECT.LIFETIME + 1)
    end)
end

-- 创建销毁特效（已禁用爆炸效果）
local function createDestroyEffect(position)
    -- 爆炸效果已被禁用，无人机消失时不再显示爆炸
    return

    --[[
    if not DroneConfig.DRONE.EFFECTS.DESTROY_EFFECT then return end

    -- 创建爆炸特效
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = 5
    explosion.BlastPressure = 0 -- 不产生物理效果
    explosion.Parent = workspace
    --]]
end

-- 尝试从单个模型ID加载无人机
local function tryLoadModelFromId(assetId)
    -- 提取纯数字ID（去掉rbxassetid://前缀）
    local numericId = assetId
    if string.find(assetId, "rbxassetid://") then
        numericId = string.gsub(assetId, "rbxassetid://", "")
    end

    -- 转换为数字
    local assetNumber = tonumber(numericId)
    if not assetNumber then
        log("无效的资产ID格式：" .. assetId)
        return nil
    end

    local success, result = pcall(function()
        local insertService = game:GetService("InsertService")
        return insertService:LoadAsset(assetNumber)
    end)

    if success and result then
        log("✅ 成功从网络加载模型：" .. assetId .. " (数字ID: " .. assetNumber .. ")")
        log("📦 模型类型：" .. result.ClassName)
        log("📂 模型子对象数量：" .. #result:GetChildren())

        -- 打印所有子对象信息用于调试
        for i, child in pairs(result:GetChildren()) do
            log("  └─ 子对象" .. i .. "：" .. child.Name .. " (" .. child.ClassName .. ")")
        end

        -- 查找模型中的无人机
        for _, child in pairs(result:GetChildren()) do
            if child:IsA("Model") and child.Name ~= "Model" then
                log("找到模型子对象：" .. child.Name)
                -- 找到无人机模型，进行设置
                local drone = child:Clone()
                result:Destroy()

                -- 确保无人机有PrimaryPart
                if not drone.PrimaryPart then
                    log("模型没有PrimaryPart，尝试查找主要部件...")
                    -- 寻找主要部件
                    local mainPart = drone:FindFirstChild("Body") or drone:FindFirstChild("Main") or drone:FindFirstChildOfClass("Part")
                    if mainPart then
                        drone.PrimaryPart = mainPart
                        log("设置PrimaryPart为：" .. mainPart.Name)
                    else
                        log("未找到合适的主要部件")
                    end
                end

                -- 如果有PrimaryPart，添加移动控制
                if drone.PrimaryPart then
                    local body = drone.PrimaryPart

                    -- 确保部件设置正确
                    body.Anchored = false
                    body.CanCollide = false

                    -- 添加或更新BodyPosition
                    local bodyPosition = body:FindFirstChild("BodyPosition")
                    if not bodyPosition then
                        bodyPosition = Instance.new("BodyPosition")
                        bodyPosition.Parent = body
                    end
                    bodyPosition.MaxForce = Vector3.new(8000, 8000, 8000)
                    bodyPosition.D = 3000
                    bodyPosition.P = 12000

                    log("成功配置无人机模型：" .. assetId .. "，PrimaryPart：" .. body.Name)
                    return drone
                else
                    log("模型没有有效的PrimaryPart，跳过")
                end
            end
        end

        -- 如果没有找到子模型，尝试直接使用加载的模型
        if result:IsA("Model") then
            log("尝试直接使用加载的模型作为无人机")
            local drone = result:Clone()
            result:Destroy()

            -- 确保无人机有PrimaryPart
            if not drone.PrimaryPart then
                log("直接模型没有PrimaryPart，尝试查找主要部件...")
                local mainPart = drone:FindFirstChild("Body") or drone:FindFirstChild("Main") or drone:FindFirstChildOfClass("Part")
                if mainPart then
                    drone.PrimaryPart = mainPart
                    log("设置PrimaryPart为：" .. mainPart.Name)
                end
            end

            if drone.PrimaryPart then
                local body = drone.PrimaryPart
                body.Anchored = false
                body.CanCollide = false

                local bodyPosition = body:FindFirstChild("BodyPosition")
                if not bodyPosition then
                    bodyPosition = Instance.new("BodyPosition")
                    bodyPosition.Parent = body
                end
                bodyPosition.MaxForce = Vector3.new(8000, 8000, 8000)
                bodyPosition.D = 3000
                bodyPosition.P = 12000

                log("成功配置直接模型：" .. assetId)
                return drone
            end
        end

        result:Destroy()
        log("模型" .. assetId .. "结构不符合要求，无法使用")
    else
        local errorMsg = result or "未知错误"
        log("❌ 无法从网络加载模型ID：" .. assetId .. " (数字ID: " .. (assetNumber or "无效") .. ")，错误：" .. tostring(errorMsg))
    end

    return nil
end

-- 加载无人机模型
local function loadDroneModel()
    -- 首先尝试加载主要模型
    local drone = tryLoadModelFromId(DroneConfig.MODEL.ASSET_ID)
    if drone then
        return drone
    end

    -- 如果主要模型失败，尝试备用模型
    if DroneConfig.MODEL.FALLBACK_ASSET_IDS then
        for _, fallbackId in ipairs(DroneConfig.MODEL.FALLBACK_ASSET_IDS) do
            if fallbackId ~= DroneConfig.MODEL.ASSET_ID then -- 避免重复尝试主要模型
                drone = tryLoadModelFromId(fallbackId)
                if drone then
                    return drone
                end
            end
        end
    end

    -- 所有外部模型都失败，使用内置备用模型
    log("所有外部模型都无法加载，使用内置备用模型")
    local drone = Instance.new("Model")
    drone.Name = "Drone"

    -- 主体
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Material = Enum.Material.ForceField
    body.BrickColor = BrickColor.new("Bright blue")
    body.Shape = Enum.PartType.Ball
    body.Size = Vector3.new(3, 3, 3)
    body.Anchored = false
    body.CanCollide = false
    body.TopSurface = Enum.SurfaceType.Smooth
    body.BottomSurface = Enum.SurfaceType.Smooth
    body.Parent = drone

    -- 添加发光效果
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(0, 162, 255)
    pointLight.Brightness = 2
    pointLight.Range = 10
    pointLight.Parent = body

    -- 添加BodyPosition用于位置控制（更适合无人机的悬停移动）
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(8000, 8000, 8000)
    bodyPosition.Position = Vector3.new(0, 0, 0)
    bodyPosition.D = 3000 -- 增加阻尼以减少震荡
    bodyPosition.P = 12000 -- 增加功率以提高响应速度
    bodyPosition.Parent = body

    -- 添加BodyAngularVelocity用于稳定旋转
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(4000, 4000, 4000)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    bodyAngularVelocity.Parent = body

    -- PrimaryPart设置
    drone.PrimaryPart = body

    return drone
end

-- 查找攻击目标
local function findNearestTarget(dronePosition, attackRange, ownerPlayer)
    local nearestTarget = nil
    local nearestDistance = attackRange
    local targetType = "none"  -- "target", "player", "npc", "none"

    -- 优先查找靶子（在Workspace.Targets文件夹中）
    local targetsFolder = workspace:FindFirstChild("Targets")
    if targetsFolder then
        for _, targetModel in pairs(targetsFolder:GetChildren()) do
            -- 检查靶子是否是有效的Model并且有活跃的Base部件
            if targetModel:IsA("Model") then
                local basePart = targetModel:FindFirstChild("Base")
                if basePart and basePart:IsA("Part") and basePart.Transparency == 0 then
                    local distance = (basePart.Position - dronePosition).Magnitude
                    if distance < nearestDistance then
                        nearestTarget = basePart  -- 返回Base部件作为攻击目标
                        nearestDistance = distance
                        targetType = "target"
                    end
                end
            end
        end
    end

    -- 如果没有找到靶子，再查找范围内的玩家（除了拥有者）
    if not nearestTarget then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= ownerPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - dronePosition).Magnitude
                if distance < nearestDistance then
                    nearestTarget = player.Character
                    nearestDistance = distance
                    targetType = "player"
                end
            end
        end
    end

    -- 最后查找范围内的NPC（查找Humanoid但不是玩家的角色）
    if not nearestTarget then
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                -- 检查是否是玩家角色
                local isPlayerCharacter = false
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character == obj then
                        isPlayerCharacter = true
                        break
                    end
                end

                if not isPlayerCharacter then
                    local distance = (obj.HumanoidRootPart.Position - dronePosition).Magnitude
                    if distance < nearestDistance then
                        nearestTarget = obj
                        nearestDistance = distance
                        targetType = "npc"
                    end
                end
            end
        end
    end

    return nearestTarget, targetType
end

-- 无人机攻击目标
local function attackTarget(drone, target, targetType)
    local body = drone.PrimaryPart
    if not body or not target then
        return false
    end

    -- 验证目标是否仍然存在
    if targetType == "target" then
        -- 检查靶子是否还在Targets文件夹中并且可见（透明度为0表示可见，透明度为1表示隐藏）
        local targetsFolder = workspace:FindFirstChild("Targets")
        local targetModel = target.Parent
        if not targetsFolder or not targetModel or targetModel.Parent ~= targetsFolder or target.Transparency == 1 then
            log("目标靶子已消失或被隐藏，取消攻击")
            return false
        end
    else
        -- 检查玩家或NPC是否仍然有效
        if not target.Parent or not target:FindFirstChild("HumanoidRootPart") then
            log("目标角色已消失，取消攻击")
            return false
        end
    end

    local targetPos
    local dronePos = body.Position

    -- 根据目标类型获取位置
    if targetType == "target" then
        -- 靶子是Part对象
        targetPos = target.Position
    else
        -- 玩家或NPC有HumanoidRootPart
        if not target:FindFirstChild("HumanoidRootPart") then
            return false
        end
        targetPos = target.HumanoidRootPart.Position
    end

    -- 创建攻击特效
    createAttackEffect(dronePos, targetPos)

    -- 根据目标类型处理伤害
    if targetType == "target" then
        -- 攻击靶子 - 通过TargetService处理
        local targetModel = target.Parent  -- target是Base部件，其父级是Model
        local targetId = targetModel.Name
        local ownerName = drone.Owner.Value.Name

        -- 直接在服务端处理靶子伤害 - 获取TargetService
        local success, TargetService = pcall(function()
            return require(script.Parent:WaitForChild("TargetService"))
        end)

        if success and TargetService then
            local destroyed = TargetService.damageTarget(targetId, DroneConfig.DRONE.ATTACK_DAMAGE, ownerName)
            log("🔥 无人机攻击靶子:", targetId, "造成伤害:", DroneConfig.DRONE.ATTACK_DAMAGE, destroyed and "(被摧毁)" or "")

            -- 如果靶子被摧毁，创建爆炸效果
            if destroyed then
                createExplosionEffect(targetPos)
            end
        else
            log("❌ 无法获取TargetService来处理靶子伤害")
        end
    else
        -- 攻击玩家或NPC
        local humanoid = target:FindFirstChild("Humanoid")
        if humanoid then
            local oldHealth = humanoid.Health
            humanoid.Health = humanoid.Health - DroneConfig.DRONE.ATTACK_DAMAGE
            log("攻击目标:", target.Name, "造成伤害:", DroneConfig.DRONE.ATTACK_DAMAGE)

            -- 如果目标被击败，创建爆炸效果
            if humanoid.Health <= 0 and oldHealth > 0 then
                createExplosionEffect(targetPos)
            end
        end
    end

    -- 播放攻击音效
    local sound = Instance.new("Sound")
    sound.SoundId = DroneConfig.SOUNDS.ATTACK
    sound.Volume = DroneConfig.SOUNDS.VOLUME.ATTACK
    sound.Parent = body
    sound:Play()

    -- 清理音效
    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    return true
end

-- 无人机移动逻辑
local function updateDroneMovement(droneData)
    local drone = droneData.model
    local player = droneData.owner
    local mode = droneData.mode

    if not drone or not drone.PrimaryPart or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local body = drone.PrimaryPart
    local bodyPosition = body:FindFirstChild("BodyPosition")
    if not bodyPosition then
        log("警告: 无人机缺少BodyPosition组件")
        return
    end

    local playerPos = player.Character.HumanoidRootPart.Position
    local currentPos = body.Position
    local targetPos

    if mode == DroneConfig.MODES.FOLLOW then
        -- 跟随模式：根据玩家朝向智能跟随
        local humanoidRootPart = player.Character.HumanoidRootPart
        local lookDirection = humanoidRootPart.CFrame.LookVector

        -- 计算跟随位置（在玩家身后上方）
        local behindOffset = -lookDirection * DroneConfig.DRONE.FOLLOW_DISTANCE
        local heightOffset = Vector3.new(0, DroneConfig.DRONE.FOLLOW_HEIGHT, 0)
        targetPos = playerPos + behindOffset + heightOffset

        -- 添加一些随机偏移以避免过于僵硬的跟随
        local randomOffset = Vector3.new(
            (math.random() - 0.5) * 2,
            (math.random() - 0.5) * 1,
            (math.random() - 0.5) * 2
        )
        targetPos = targetPos + randomOffset
    else
        -- 驻守模式：保持在设定的位置
        if not droneData.guardPosition then
            -- 如果没有设定驻守位置，使用当前位置
            droneData.guardPosition = currentPos
        end
        targetPos = droneData.guardPosition
    end

    -- 更新目标位置
    bodyPosition.Position = targetPos

    -- 调试信息
    if DroneConfig.DEBUG.VERBOSE_LOGGING then
        local distance = (currentPos - targetPos).Magnitude
        if distance > 1 then
            log("无人机移动:", player.Name, "模式:", mode, "距离目标:", math.floor(distance), "studs")
        end
    end
end

-- ==============================================
-- 无人机管理函数
-- ==============================================

function DroneService.spawnDrone(player: Player)
    -- 检查玩家是否已有无人机
    if activeDrones[player] then
        return false, "您已经有一个活跃的无人机了"
    end

    -- 检查玩家角色是否存在
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false, "无法获取玩家位置"
    end

    -- 加载无人机模型
    local droneModel = loadDroneModel()
    if not droneModel then
        return false, "无法加载无人机模型"
    end

    -- 设置无人机位置
    local playerPos = player.Character.HumanoidRootPart.Position
    local spawnPos = playerPos + Vector3.new(0, DroneConfig.DRONE.FOLLOW_HEIGHT, -DroneConfig.DRONE.FOLLOW_DISTANCE)

    droneModel:SetPrimaryPartCFrame(CFrame.new(spawnPos))
    droneModel.Parent = workspace

    -- 创建生成特效
    createSpawnEffect(spawnPos)

    -- 播放生成音效
    local sound = Instance.new("Sound")
    sound.SoundId = DroneConfig.SOUNDS.SPAWN
    sound.Volume = DroneConfig.SOUNDS.VOLUME.SPAWN
    sound.Parent = droneModel.PrimaryPart
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    -- 添加Owner属性到无人机模型
    local ownerValue = Instance.new("ObjectValue")
    ownerValue.Name = "Owner"
    ownerValue.Value = player
    ownerValue.Parent = droneModel

    -- 创建无人机数据
    local droneData = {
        model = droneModel,
        owner = player,
        mode = DroneConfig.MODES.FOLLOW,
        spawnTime = tick(),
        lastAttackTime = 0,
        guardPosition = nil
    }

    activeDrones[player] = droneData

    -- 通知客户端
    Events.Drone.DroneSpawned:FireClient(player, true)

    log("玩家", player.Name, "召唤了无人机")

    return true, "无人机已召唤"
end

function DroneService.recallDrone(player: Player)
    local droneData = activeDrones[player]
    if not droneData then
        return false, "您没有活跃的无人机"
    end

    -- 创建销毁特效
    if droneData.model and droneData.model.PrimaryPart then
        createDestroyEffect(droneData.model.PrimaryPart.Position)
    end

    -- 销毁无人机模型
    if droneData.model then
        droneData.model:Destroy()
    end

    -- 清除数据
    activeDrones[player] = nil

    -- 通知客户端
    Events.Drone.DroneRecalled:FireClient(player, true)

    log("玩家", player.Name, "收回了无人机")

    return true, "无人机已收回"
end

function DroneService.switchDroneMode(player: Player, newMode: string)
    local droneData = activeDrones[player]
    if not droneData then
        return false, "您没有活跃的无人机"
    end

    if newMode ~= DroneConfig.MODES.FOLLOW and newMode ~= DroneConfig.MODES.GUARD then
        return false, "无效的模式"
    end

    local oldMode = droneData.mode
    droneData.mode = newMode

    -- 如果切换到驻守模式，记录当前位置
    if newMode == DroneConfig.MODES.GUARD and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local playerPos = player.Character.HumanoidRootPart.Position
        droneData.guardPosition = playerPos + Vector3.new(0, DroneConfig.DRONE.HOVER_HEIGHT, 0)
    end

    -- 通知客户端
    Events.Drone.DroneModeChanged:FireClient(player, newMode, oldMode)

    log("玩家", player.Name, "将无人机模式从", oldMode, "切换到", newMode)

    return true, "模式已切换到" .. (newMode == DroneConfig.MODES.FOLLOW and "跟随模式" or "驻守模式")
end

function DroneService.getDroneInfo(player: Player)
    local droneData = activeDrones[player]
    if not droneData then
        return nil
    end

    local currentTime = tick()
    local timeRemaining = math.max(0, DroneConfig.DRONE.LIFETIME - (currentTime - droneData.spawnTime))

    return {
        mode = droneData.mode,
        timeRemaining = timeRemaining,
        isActive = timeRemaining > 0
    }
end

-- ==============================================
-- 主循环和事件处理
-- ==============================================

local function mainLoop()
    local currentTime = tick()

    for player, droneData in pairs(activeDrones) do
        -- 检查无人机是否超时
        local timeElapsed = currentTime - droneData.spawnTime
        if timeElapsed >= DroneConfig.DRONE.LIFETIME then
            -- 自动销毁无人机
            createDestroyEffect(droneData.model.PrimaryPart.Position)
            droneData.model:Destroy()
            activeDrones[player] = nil

            -- 通知客户端
            Events.Drone.DroneDestroyed:FireClient(player, "时间到期")
            log("玩家", player.Name, "的无人机因时间到期而销毁")
            continue
        end

        -- 更新无人机移动
        updateDroneMovement(droneData)

        -- 攻击逻辑
        if (currentTime - droneData.lastAttackTime) >= DroneConfig.DRONE.ATTACK_INTERVAL then
            local dronePos = droneData.model.PrimaryPart.Position
            local target, targetType = findNearestTarget(dronePos, DroneConfig.DRONE.ATTACK_RANGE, player)

            if target then
                local attackSuccess = attackTarget(droneData.model, target, targetType)
                if attackSuccess then
                    droneData.lastAttackTime = currentTime

                    -- 通知客户端攻击事件
                    local targetName = targetType == "target" and (target.Parent and target.Parent.Name or target.Name) or target.Name
                    Events.Drone.DroneAttack:FireClient(player, targetName)
                    log("✅ 无人机攻击成功：类型=" .. targetType .. ", 目标=" .. targetName)
                else
                    -- 攻击失败，可能是目标已消失，重置攻击时间以便立即寻找新目标
                    droneData.lastAttackTime = currentTime - DroneConfig.DRONE.ATTACK_INTERVAL + 0.1
                end
            end
        end
    end
end

-- 启动主循环
local connection = RunService.Heartbeat:Connect(mainLoop)

-- 玩家离开时清理
Players.PlayerRemoving:Connect(function(player)
    if activeDrones[player] then
        if activeDrones[player].model then
            activeDrones[player].model:Destroy()
        end
        activeDrones[player] = nil
    end
end)

-- ==============================================
-- 事件连接
-- ==============================================

Events.Drone.SpawnDrone.OnServerEvent:Connect(function(player)
    local success, message = DroneService.spawnDrone(player)
    -- 可以在这里添加额外的客户端反馈
end)

Events.Drone.RecallDrone.OnServerEvent:Connect(function(player)
    local success, message = DroneService.recallDrone(player)
    -- 可以在这里添加额外的客户端反馈
end)

Events.Drone.SwitchDroneMode.OnServerEvent:Connect(function(player, newMode)
    local success, message = DroneService.switchDroneMode(player, newMode)
    -- 可以在这里添加额外的客户端反馈
end)

log("无人机服务已启动")

return DroneService
