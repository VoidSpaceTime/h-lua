---@class hevent
hevent = {}

--- 动态事件池
hevent_pool = {}

hevent_pool_dyn_max = 1000
hevent_pool_dyn = {}

---@type Array[]
hevent_chat_pattern = {}

--- 事件反应
---@protected
hevent_reaction = {}

---@protected
function hevent.free(handle)
    local poolRegister = hcache.get(handle, CONST_CACHE.EVENT_POOL)
    if (poolRegister ~= nil) then
        poolRegister:forEach(function(key, poolIndex)
            hevent_pool_dyn[key][poolIndex].stock = hevent_pool_dyn[key][poolIndex].stock - 1
            -- 起码利用红线1/4允许归零
            if (hevent_pool_dyn[key][poolIndex].stock == 0 and hevent_pool_dyn[key][poolIndex].count > 0.25 * hevent_pool_dyn_max) then
                cj.DisableTrigger(hevent_pool_dyn[key][poolIndex].trigger)
                cj.DestroyTrigger(hevent_pool_dyn[key][poolIndex].trigger)
                hevent_pool_dyn[key][poolIndex] = -1
            end
            local e = 0
            for _, v in ipairs(hevent_pool_dyn[key]) do
                if (v == -1) then
                    e = e + 1
                end
            end
            if (e == #hevent_pool_dyn[key]) then
                hevent_pool_dyn[key] = nil
            end
        end)
    end
end

--- 触发池
--- 使用一个handle，以不同的conditionAction累计计数
--- 分配触发到回调注册
--- 触发池的action是不会被同一个handle注册两次的，与on事件并不相同
---@protected
---@param conditionFunc number
---@param regEvent function
---@return void
function hevent.pool(conditionFunc, regEvent)
    if (type(regEvent) ~= "function") then
        return
    end
    local id = cj.GetHandleId(conditionFunc)
    -- 如果这个handle已经注册过此动作，则不重复注册
    local tgr = hevent_pool[id]
    if (tgr == nil) then
        tgr = cj.CreateTrigger()
        cj.TriggerAddCondition(tgr, conditionFunc)
        hevent_pool[id] = tgr
    end
    regEvent(hevent_pool[id])
end

--- 触发池
--- 使用一个handle，以不同的conditionAction累计计数
--- 分配触发到回调注册
--- 触发池的action是不会被同一个handle注册两次的，与on事件并不相同
---@protected
function hevent.poolRed(handle, conditionAction, regEvent)
    if (type(regEvent) ~= 'function') then
        return
    end
    local key = cj.GetHandleId(conditionAction)
    -- 如果这个handle已经注册过此动作，则不重复注册
    local poolRegister = hcache.get(handle, CONST_CACHE.EVENT_POOL)
    if (poolRegister == nil) then
        poolRegister = Array()
        hcache.set(handle, CONST_CACHE.EVENT_POOL, poolRegister)
    end
    if (poolRegister.get(key) ~= nil) then
        return
    end
    if (hevent_pool_dyn[key] == nil) then
        hevent_pool_dyn[key] = {}
    end
    local poolIndex = #hevent_pool_dyn[key]
    if (poolIndex <= 0 or hevent_pool_dyn[key][poolIndex] == -1 or hevent_pool_dyn[key][poolIndex].count >= hevent_pool_dyn_max) then
        local tgr = cj.CreateTrigger()
        table.insert(hevent_pool_dyn[key], { stock = 0, count = 0, trigger = tgr })
        cj.TriggerAddCondition(tgr, conditionAction)
        poolIndex = #hevent_pool_dyn[key]
    end
    poolRegister.set(key, poolIndex)
    hevent_pool_dyn[key][poolIndex].count = hevent_pool_dyn[key][poolIndex].count + 1
    hevent_pool_dyn[key][poolIndex].stock = hevent_pool_dyn[key][poolIndex].stock + 1
    regEvent(hevent_pool_dyn[key][poolIndex].trigger)
end

--- 捕捉反应
---@param evt string 事件类型
---@vararg any
---@return void
function hevent.reaction(evt, ...)
    local opt = { ... }
    ---@type string 关联反应标识符
    local key
    ---@type fun(callData:table) 回调
    local callFunc
    if (type(opt[1]) == "function") then
        key = "default"
        callFunc = opt[1]
    elseif (type(opt[1]) == "string") then
        key = opt[1]
        if (type(opt[2]) == "function") then
            callFunc = opt[2]
        end
    end
    if (evt == nil) then
        stack()
    end
    if (hevent_reaction[evt] == nil) then
        hevent_reaction[evt] = Array()
    end
    hevent_reaction[evt].set(key, callFunc)
end

--- set最后一位伤害的单位关系
---@protected
function hevent.setLastDamage(sourceUnit, targetUnit)
    if (sourceUnit ~= nil) then
        hcache.set(sourceUnit, CONST_CACHE.EVENT_LAST_DMG_TARGET, targetUnit)
        hcache.set(hunit.getOwner(sourceUnit), CONST_CACHE.EVENT_LAST_DMG_TARGET_PLAYER, targetUnit)
        if (targetUnit ~= nil) then
            hcache.set(targetUnit, CONST_CACHE.EVENT_LAST_DMG_SRC, sourceUnit)
        end
    end
end

--- 最后一位伤害的单位
---@protected
function hevent.getUnitLastDamageSource(whichUnit)
    return hcache.get(whichUnit, CONST_CACHE.EVENT_LAST_DMG_SRC)
end

--- 获取单位最后一次伤害的目标单位
---@protected
function hevent.getUnitLastDamageTarget(whichUnit)
    return hcache.get(whichUnit, CONST_CACHE.EVENT_LAST_DMG_TARGET)
end

--- 获取玩家最后一次伤害的目标单位
---@protected
function hevent.getPlayerLastDamageTarget(whichPlayer)
    return hcache.get(whichPlayer, CONST_CACHE.EVENT_LAST_DMG_TARGET_PLAYER)
end

---@param handle any
---@param evt string 事件类型
---@param init boolean
---@return nil|table<string,Array>|Array
function hevent.data(handle, evt, init)
    if (handle == nil) then
        return
    end
    local data = hcache.get(handle, CONST_CACHE.EVENT_DATA)
    if (init == true) then
        if (data == nil) then
            data = {}
            hcache.set(handle, CONST_CACHE.EVENT_DATA, data)
        end
        if (evt ~= nil and data[evt] == nil) then
            data[evt] = Array()
        end
    end
    if (evt == nil) then
        return data
    else
        if (type(data) == "table") then
            return data[evt]
        end
    end
end

--- 注销事件|事件集
---@param handle any
---@param evt string 事件类型
---@param key string|nil
---@return void
function hevent.unregister(handle, evt, key)
    if (handle == nil or evt == nil) then
        return
    end
    local data = hevent.data(handle)
    if (data == nil) then
        return
    end
    if (key == nil) then
        data[evt] = nil
    else
        data[evt].set(key, nil)
    end
end

--- 注册事件
--- 每种类型的事件默认只会被注册一次，重复会覆盖
--- 这是根据 key 值决定的，key 默认就是default，需要的时候可以自定义
---@param handle any
---@param evt string 事件类型字符
---@vararg string|function
---@return void
function hevent.register(handle, evt, ...)
    if (handle == nil) then
        return
    end
    local opt = { ... }
    ---@type string 关联事件标识符
    local key
    ---@type fun(callData:table) 回调
    local callFunc
    if (type(opt[1]) == "function") then
        key = "default"
        callFunc = opt[1]
    elseif (type(opt[1]) == "string") then
        key = opt[1]
        if (type(opt[2]) == "function") then
            callFunc = opt[2]
        end
    end
    if (key ~= nil) then
        if (callFunc == nil) then
            hevent.unregister(handle, evt, key)
        elseif (type(callFunc) == "function") then
            hevent.data(handle, evt, true).set(key, callFunc)
        end
    end
end

--- 触发事件
---@param handle any
---@param key string 事件类型
---@param triggerData table
function hevent.trigger(handle, key, triggerData)
    if (handle == nil or key == nil) then
        return
    end
    -- 数据
    triggerData = triggerData or {}
    if (triggerData.triggerSkill ~= nil and type(triggerData.triggerSkill) == "number") then
        triggerData.triggerSkill = i2c(triggerData.triggerSkill)
    end
    if (triggerData.learnedSkill ~= nil and type(triggerData.learnedSkill) == "number") then
        triggerData.learnedSkill = i2c(triggerData.learnedSkill)
    end
    if (triggerData.targetLoc ~= nil) then
        triggerData.targetX = cj.GetLocationX(triggerData.targetLoc)
        triggerData.targetY = cj.GetLocationY(triggerData.targetLoc)
        triggerData.targetZ = cj.GetLocationZ(triggerData.targetLoc)
        cj.RemoveLocation(triggerData.targetLoc)
        triggerData.targetLoc = nil
    end
    -- 反应
    if (hevent_reaction[key] ~= nil) then
        hevent_reaction[key].forEach(function(_, val)
            if (type(val) == "function") then
                val(triggerData)
            end
        end)
    end
    -- 判断事件注册执行与否
    local reg = hevent.data(handle, key)
    if (reg ~= nil) then
        if (reg.count() > 0) then
            reg.forEach(function(_, callFunc)
                callFunc(triggerData)
            end)
        end
    end
end


-----------------------------------------------------------------------------------------


--- 准备被攻击
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onBeAttackReadyData {triggerUnit:"被攻击单位",attackUnit:"攻击单位"}
---@alias onBeAttackReady fun(evtData: onBeAttackReadyData):void
---@param whichUnit userdata
---@param callFunc onBeAttackReady | "function(evtData) end"
---@return void
function hevent.onBeAttackReady(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.beAttackReady, callFunc)
end

--- 造成攻击
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onAttackData {triggerUnit:"攻击单位",targetUnit:"被攻击单位",damage:"伤害"}
---@alias onAttack fun(evtData: onAttackData):void
---@param whichUnit userdata
---@param callFunc onAttack | "function(evtData) end"
---@return void
function hevent.onAttack(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.attack, callFunc)
end

--- 承受攻击
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onBeAttackData {triggerUnit:"被攻击单位",attackUnit:"攻击单位",damage:"伤害"}
---@alias onBeAttack fun(evtData: onBeAttackData):void
---@param whichUnit userdata
---@param callFunc onBeAttack | "function(evtData) end"
---@return void
function hevent.onBeAttack(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.beAttack, callFunc)
end

--- 学习技能
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onSkillStudyData {triggerUnit:"学习单位",learnedSkill:"学习技能ID字符串"}
---@alias onSkillStudy fun(evtData: onSkillStudyData):void
---@param whichUnit userdata
---@param callFunc onSkillStudy | "function(evtData) end"
---@return void
function hevent.onSkillStudy(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.skillStudy, callFunc)
end

--- 准备施放技能
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onSkillReadyData {triggerUnit:"施放单位",triggerSkill:"施放技能ID字符串",targetUnit:"获取目标单位",targetX:"获取施放目标点X",targetY:"获取施放目标点Y",targetZ:"获取施放目标点Z"}
---@alias onSkillReady fun(evtData: onSkillReadyData):void
---@param whichUnit userdata
---@param callFunc onSkillReady | "function(evtData) end"
---@return void
function hevent.onSkillReady(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.skillReady, callFunc)
end

--- 开始施放技能
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onSkillCastData {triggerUnit:"施放单位",triggerSkill:"施放技能ID字符串",targetUnit:"获取目标单位",targetX:"获取施放目标点X",targetY:"获取施放目标点Y",targetZ:"获取施放目标点Z"}
---@alias onSkillCast fun(evtData: onSkillCastData):void
---@param whichUnit userdata
---@param callFunc onSkillCast | "function(evtData) end"
---@return void
function hevent.onSkillCast(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.skillCast, callFunc)
end

--- 停止施放技能
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onSkillStopData {triggerUnit:"施放单位",triggerSkill:"施放技能ID字符串"}
---@alias onSkillStop fun(evtData: onSkillStopData):void
---@param whichUnit userdata
---@param callFunc onSkillStop | "function(evtData) end"
---@return void
function hevent.onSkillStop(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.skillStop, callFunc)
end

--- 发动技能效果
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onSkillEffectData {triggerUnit:"施放单位",triggerSkill:"施放技能ID字符串",targetUnit:"获取目标单位",targetItem:"获取目标物品",targetDestructable:"获取目标可破坏物",targetX:"获取施放目标点X",targetY:"获取施放目标点Y",targetZ:"获取施放目标点Z"}
---@alias onSkillEffect fun(evtData: onSkillEffectData):void
---@param whichUnit userdata
---@param callFunc onSkillEffect | "function(evtData) end"
---@return void
function hevent.onSkillEffect(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.skillEffect, callFunc)
end

--- 施放技能结束
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onSkillFinishData {triggerUnit:"施放单位",triggerSkill:"施放技能ID字符串"}
---@alias onSkillFinish fun(evtData: onSkillFinishData):void
---@param whichUnit userdata
---@param callFunc onSkillFinish | "function(evtData) end"
---@return void
function hevent.onSkillFinish(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.skillFinish, callFunc)
end

--- 单位使用物品
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onItemUsedData {triggerUnit:"触发单位",triggerItem:"触发物品",triggerSkill:"施放技能ID字符串",targetUnit:"获取目标单位",targetX:"获取施放目标点X",targetY:"获取施放目标点Y",targetZ:"获取施放目标点Z"}
---@alias onItemUsed fun(evtData: onItemUsedData):void
---@param whichUnit userdata
---@param callFunc onItemUsed | "function(evtData) end"
---@return void
function hevent.onItemUsed(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.itemUsed, callFunc)
end

--- 丢弃(传递)物品
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onItemDropData {triggerUnit:"丢弃单位",targetUnit:"获得单位（如果有）",triggerItem:"触发物品"}
---@alias onItemDrop fun(evtData: onItemDropData):void
---@param whichUnit userdata
---@param callFunc onItemDrop | "function(evtData) end"
---@return void
function hevent.onItemDrop(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.itemDrop, callFunc)
end

--- 获得物品
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onItemGetData {triggerUnit:"触发单位",triggerItem:"触发物品"}
---@alias onItemGet fun(evtData: onItemGetData):void
---@param whichUnit userdata
---@param callFunc onItemGet | "function(evtData) end"
---@return void
function hevent.onItemGet(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.itemGet, callFunc)
end

--- 抵押物品（玩家把物品扔给商店）
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onItemPawnData {triggerUnit:"触发单位",soldItem:"抵押物品",buyingUnit:"抵押商店",soldGold:"抵押获得黄金",soldLumber:"抵押获得木头"}
---@alias onItemPawn fun(evtData: onItemPawnData):void
---@param whichUnit userdata
---@param callFunc onItemPawn | "function(evtData) end"
---@return void
function hevent.onItemPawn(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.itemPawn, callFunc)
end

--- 出售物品(商店卖给玩家)
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onItemSellData {triggerUnit:"售卖单位",soldItem:"售卖物品",buyingUnit:"购买单位"}
---@alias onItemSell fun(evtData: onItemSellData):void
---@param whichUnit userdata
---@param callFunc onItemSell | "function(evtData) end"
---@return void
function hevent.onItemSell(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.itemSell, callFunc)
end

--- 出售单位(商店卖给玩家)
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onUnitSellData {triggerUnit:"商店单位",soldUnit:"被售卖单位",buyingUnit:"购买单位"}
---@alias onUnitSell fun(evtData: onUnitSellData):void
---@param whichUnit userdata
---@param callFunc onUnitSell | "function(evtData) end"
---@return void
function hevent.onUnitSell(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.unitSell, callFunc)
end

--- 物品被破坏
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onItemDestroyData {triggerUnit:"触发单位",triggerItem:"触发物品"}
---@alias onItemDestroy fun(evtData: onItemDestroyData):void
---@param whichItem userdata
---@param callFunc onItemDestroy | "function(evtData) end"
---@return void
function hevent.onItemDestroy(whichItem, callFunc)
    hevent.poolRed(whichItem, hevent_binder.item.destroy, function(tgr)
        cj.TriggerRegisterDeathEvent(tgr, whichItem)
    end)
    hevent.register(whichItem, CONST_EVENT.itemDestroy, callFunc)
end

--- 造成伤害
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onDamageData {triggerUnit:"伤害来自单位",targetUnit:"被伤害单位",damage:"伤害",damageSrc:"伤害来源"}
---@alias onDamage fun(evtData: onDamageData):void
---@param whichUnit userdata
---@param callFunc onDamage | "function(evtData) end"
---@return void
function hevent.onDamage(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.damage, callFunc)
end

--- 承受伤害
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onBeDamageData {triggerUnit:"被伤害单位",sourceUnit:"伤害来自单位",damage:"伤害",damageSrc:"伤害来源"}
---@alias onBeDamage fun(evtData: onBeDamageData):void
---@param whichUnit userdata
---@param callFunc onBeDamage | "function(evtData) end"
---@return void
function hevent.onBeDamage(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.beDamage, callFunc)
end

--- 死亡时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onDeadData {triggerUnit:"死亡单位",killUnit:"凶手单位"}
---@alias onDead fun(evtData: onDeadData):void
---@param whichUnit userdata
---@param callFunc onDead | "function(evtData) end"
---@return void
function hevent.onDead(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.dead, callFunc)
end

--- 杀敌时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onKillData {triggerUnit:"凶手单位",targetUnit:"死亡单位"}
---@alias onKill fun(evtData: onKillData):void
---@param whichUnit userdata
---@param callFunc onKill | "function(evtData) end"
---@return void
function hevent.onKill(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.kill, callFunc)
end

--- 复活时(必须使用 hunit.reborn 方法才能嵌入到事件系统)
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onRebornData {triggerUnit:"触发单位"}
---@alias onReborn fun(evtData: onRebornData):void
---@param whichUnit userdata
---@param callFunc onReborn | "function(evtData) end"
---@return void
function hevent.onReborn(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.reborn, callFunc)
end

--- 获得经验时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onExpData {triggerUnit:"触发单位",value:"获取了多少经验值"}
---@alias onExp fun(evtData: onExpData):void
---@param whichUnit userdata
---@param callFunc onLevelUp | "function(evtData) end"
---@return void
function hevent.onExp(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.exp, callFunc)
end

--- 提升等级时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onLevelUpData {triggerUnit:"触发单位",value:"获取提升了多少级"}
---@alias onLevelUp fun(evtData: onLevelUpData):void
---@param whichUnit userdata
---@param callFunc onLevelUp | "function(evtData) end"
---@return void
function hevent.onLevelUp(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.levelUp, callFunc)
end

--- 建筑升级开始时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onUpgradeStartData {triggerUnit:"触发单位"}
---@alias onUpgradeStart fun(evtData: onUpgradeStartData):void
---@param whichUnit userdata
---@param callFunc onUpgradeStart | "function(evtData) end"
---@return void
function hevent.onUpgradeStart(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.upgradeStart, callFunc)
end

--- 建筑升级取消时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onUpgradeCancelData {triggerUnit:"触发单位"}
---@alias onUpgradeCancel fun(evtData: onUpgradeCancelData):void
---@param whichUnit userdata
---@param callFunc onUpgradeCancel | "function(evtData) end"
---@return void
function hevent.onUpgradeCancel(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.upgradeCancel, callFunc)
end

--- 建筑升级完成时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onUpgradeFinishData {triggerUnit:"触发单位"}
---@alias onUpgradeFinish fun(evtData: onUpgradeFinishData):void
---@param whichUnit userdata
---@param callFunc onUpgradeFinish | "function(evtData) end"
---@return void
function hevent.onUpgradeFinish(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.upgradeFinish, callFunc)
end

--- 进入某单位（whichUnit）半径范围内
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onEnterUnitRangeData {centerUnit:"被进入范围的中心单位",triggerUnit:"进入范围的单位",radius:"设定的半径范围"}
---@alias onEnterUnitRange fun(evtData: onEnterUnitRangeData):void
---@param whichUnit userdata
---@param radius number
---@param callFunc onEnterUnitRange | "function(evtData) end"
---@return void
function hevent.onEnterUnitRange(whichUnit, radius, callFunc)
    local key = CONST_EVENT.enterUnitRange
    local func = hcache.get(whichUnit, CONST_CACHE.EVENT_ON_ENTER_RANGE .. radius, nil)
    if (func == nil) then
        function func()
            hevent.trigger(whichUnit, key, {
                centerUnit = whichUnit,
                triggerUnit = cj.GetTriggerUnit(),
                radius = radius
            })
        end
        hcache.set(whichUnit, CONST_CACHE.EVENT_ON_ENTER_RANGE .. radius, func)
    end
    hevent.poolRed(whichUnit, cj.Condition(func), function(tgr)
        cj.TriggerRegisterUnitInRange(tgr, whichUnit, radius, nil)
    end)
    hevent.register(whichUnit, key, callFunc)
end

--- 进入某区域
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onEnterRectData {triggerRect:"被进入的矩形区域",triggerUnit:"进入矩形区域的单位"}
---@alias onEnterRect fun(evtData: onEnterRectData):void
---@param whichRect userdata
---@param callFunc onEnterRect | "function(evtData) end"
---@return void
function hevent.onEnterRect(whichRect, callFunc)
    if (false == hcache.exist(whichRect)) then
        hcache.alloc(whichRect)
    end
    local key = CONST_EVENT.enterRect
    local onEnterRectAction = hcache.get(whichRect, CONST_CACHE.EVENT_ON_ENTER_RECT)
    if (onEnterRectAction == nil) then
        function onEnterRectAction()
            hevent.trigger(whichRect, key, {
                triggerRect = whichRect,
                triggerUnit = cj.GetTriggerUnit()
            })
        end
        hcache.set(whichRect, CONST_CACHE.EVENT_ON_ENTER_RECT, onEnterRectAction)
    end
    hevent.poolRed(whichRect, cj.Condition(onEnterRectAction), function(tgr)
        local rectRegion = cj.CreateRegion()
        cj.RegionAddRect(rectRegion, whichRect)
        cj.TriggerRegisterEnterRegion(tgr, rectRegion, nil)
    end)
    hevent.register(whichRect, key, callFunc)
end

--- 离开某区域
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onLeaveRectData {triggerRect:"被离开的矩形区域",triggerUnit:"离开矩形区域的单位"}
---@alias onLeaveRect fun(evtData: onLeaveRectData):void
---@param whichRect userdata
---@param callFunc onLeaveRect | "function(evtData) end"
---@return void
function hevent.onLeaveRect(whichRect, callFunc)
    if (false == hcache.exist(whichRect)) then
        hcache.alloc(whichRect)
    end
    local key = CONST_EVENT.leaveRect
    local onLeaveRectAction = hcache.get(whichRect, CONST_CACHE.EVENT_ON_LEAVE_RECT)
    if (onLeaveRectAction == nil) then
        function onLeaveRectAction()
            hevent.trigger(whichRect, key, {
                triggerRect = whichRect,
                triggerUnit = cj.GetTriggerUnit()
            })
        end
        hcache.set(whichRect, CONST_CACHE.EVENT_ON_LEAVE_RECT, onLeaveRectAction)
    end
    hevent.poolRed(whichRect, cj.Condition(onLeaveRectAction), function(tgr)
        local rectRegion = cj.CreateRegion()
        cj.RegionAddRect(rectRegion, whichRect)
        cj.TriggerRegisterLeaveRegion(tgr, rectRegion, nil)
    end)
    hevent.register(whichRect, key, callFunc)
end

--- 任意建筑建造开始时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onConstructStartData {triggerUnit:"触发单位"}
---@alias onConstructStart fun(evtData: onConstructStartData):void
---@param whichPlayer userdata
---@param callFunc onConstructStart | "function(evtData) end"
---@return void
function hevent.onConstructStart(whichPlayer, callFunc)
    hevent.register(whichPlayer, CONST_EVENT.constructStart, callFunc)
end

--- 任意建筑建造取消时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onConstructCancelData {triggerUnit:"触发单位"}
---@alias onConstructCancel fun(evtData: onConstructCancelData):void
---@param whichPlayer userdata
---@param callFunc onConstructCancel | "function(evtData) end"
---@return void
function hevent.onConstructCancel(whichPlayer, callFunc)
    hevent.register(whichPlayer, CONST_EVENT.constructCancel, callFunc)
end

--- 任意建筑建造完成时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onConstructFinishData {triggerUnit:"触发单位"}
---@alias onConstructFinish fun(evtData: onConstructFinishData):void
---@param whichPlayer userdata
---@param callFunc onConstructFinish | "function(evtData) end"
---@return void
function hevent.onConstructFinish(whichPlayer, callFunc)
    hevent.register(whichPlayer, CONST_EVENT.constructFinish, callFunc)
end

--- 当聊天时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onChatData {triggerPlayer:"聊天的玩家",chatString:"聊天的内容",matchedString:"匹配命中的内容"}
---@alias onChat fun(evtData: onChatData):void
---@param whichPlayer userdata
---@param pattern string 支持正则
---@param callFunc onChat | "function(evtData) end"
---@return void
function hevent.onChat(whichPlayer, pattern, callFunc)
    local i = hplayer.index(whichPlayer)
    if (hevent_chat_pattern[i] ~= nil) then
        if (type(callFunc) == "function") then
            hevent_chat_pattern[i].set(pattern, callFunc)
        else
            hevent_chat_pattern[i].splice(pattern)
        end
    end
end

--- 按ESC
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onEscData {triggerPlayer:"触发玩家"}
---@alias onEsc fun(evtData: onEscData):void
---@param whichPlayer userdata
---@param callFunc onEsc | "function(evtData) end"
---@return void
function hevent.onEsc(whichPlayer, callFunc)
    hevent.register(whichPlayer, CONST_EVENT.esc, callFunc)
end

--- 玩家选择单位(点击了qty次)
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onSelectionData {triggerPlayer:"触发玩家",triggerUnit:"触发单位"}
---@alias onSelection fun(evtData: onSelectionData):void
---@param whichPlayer userdata
---@param qty number
---@param callFunc onSelection | "function(evtData) end"
---@return void
function hevent.onSelection(whichPlayer, qty, callFunc)
    hevent.register(whichPlayer, CONST_EVENT.selection .. "#" .. qty, callFunc)
end

--- 玩家取消选择单位
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onDeSelectionData {triggerPlayer:"触发玩家",triggerUnit:"触发单位"}
---@alias onDeSelection fun(evtData: onDeSelectionData):void
---@param whichPlayer userdata
---@param callFunc onDeSelection | "function(evtData) end"
---@return void
function hevent.onDeSelection(whichPlayer, callFunc)
    hevent.register(whichPlayer, CONST_EVENT.deSelection, callFunc)
end

--- 玩家离开游戏事件(注意这是全局事件)
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onPlayerLeaveData {triggerPlayer:"触发玩家"}
---@alias onPlayerLeave fun(evtData: onPlayerLeaveData):void
---@param callFunc onPlayerLeave | "function(evtData) end"
---@return void
function hevent.onPlayerLeave(callFunc)
    hevent.register("global", CONST_EVENT.playerLeave, callFunc)
end

--- 玩家资源变动
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onPlayerResourceChangeData {triggerPlayer:"触发玩家",triggerUnit:"触发单位",type:"资源类型",value:"变化值"}
---@alias onPlayerResourceChange fun(evtData: onPlayerResourceChangeData):void
---@param callFunc onPlayerResourceChange | "function(evtData) end"
---@return void
function hevent.onPlayerResourceChange(callFunc)
    hevent.register("global", CONST_EVENT.playerResourceChange, callFunc)
end

--- 任意单位经过hero方法被玩家所挑选为英雄时(注意这是全局事件)
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onPickHeroData {triggerPlayer:"触发玩家",triggerUnit:"触发单位"}
---@alias onPickHero fun(evtData: onPickHeroData):void
---@param callFunc onPickHero | "function(evtData) end"
---@return void
function hevent.onPickHero(callFunc)
    hevent.register("global", CONST_EVENT.pickHero, callFunc)
end

--- 可破坏物死亡
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onDestructableDestroyData {triggerDestructable:"被破坏的可破坏物"}
---@alias onDestructableDestroy fun(evtData: onDestructableDestroyData):void
---@param whichDestructable userdata
---@param callFunc onDestructableDestroy | "function(evtData) end"
---@return void
function hevent.onDestructableDestroy(whichDestructable, callFunc)
    hevent.poolRed(whichDestructable, hevent_binder.destructable.destroy, function(tgr)
        cj.TriggerRegisterDeathEvent(tgr, whichDestructable)
    end)
    hevent.register(whichDestructable, CONST_EVENT.destructableDestroy, callFunc)
end

--- 全图当前可破坏物死亡
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onMapDestructableDestroyData {triggerDestructable:"被破坏的可破坏物"}
---@alias onMapDestructableDestroy fun(evtData: onMapDestructableDestroyData):void
---@param callFunc onMapDestructableDestroy | "function(evtData) end"
---@return void
function hevent.onMapDestructableDestroy(callFunc)
    local tgr = cj.CreateTrigger()
    cj.TriggerAddCondition(tgr, cj.Condition(function()
        callFunc({ triggerDestructable = cj.GetTriggerDestructable() })
    end))
    cj.EnumDestructablesInRect(hrect.playable(), nil, function()
        cj.TriggerRegisterDeathEvent(tgr, cj.GetEnumDestructable())
    end)
end

--- 当单位发布驻扎(H)命令
--- 只有真人玩家的单位有此事件
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onHoldOnData {triggerUnit:"触发单位"}
---@alias onHoldOn fun(evtData: onHoldOnData):void
---@param whichUnit userdata
---@param callFunc onHoldOn | "function(evtData) end"
---@return void
function hevent.onHoldOn(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.holdOn, callFunc)
end

--- 当单位发布停止(S)命令
--- 只有真人玩家的单位有此事件
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onStopData {triggerUnit:"触发单位"}
---@alias onStop fun(evtData: onStopData):void
---@param whichUnit userdata
---@param callFunc onStop | "function(evtData) end"
---@return void
function hevent.onStop(whichUnit, callFunc)
    hevent.register(whichUnit, CONST_EVENT.stop, callFunc)
end

--- 任意单位改变所有者时
--- * 使用默认key[default]覆盖式定义，如有需要请自行直接使用register方法注册
---@alias onUnitChangeOwnerData {triggerUnit:"被改变所有者的单位",prevOwner:"原所有者"}
---@alias onUnitChangeOwner fun(evtData: onUnitChangeOwnerData):void
---@param whichPlayer userdata
---@param callFunc onUnitChangeOwner | "function(evtData) end"
---@return void
function hevent.onUnitChangeOwner(whichPlayer, callFunc)
    hevent.register(whichPlayer, CONST_EVENT.changeOwner, callFunc)
end
