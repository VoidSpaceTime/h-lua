---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hunzs.
--- DateTime: 2020/5/8 22:18
--- Updated: 2021/1/22 00:19
---

-- hslk 初始化
hslk_init()

-- 全局秒钟
cj.TimerStart(cj.CreateTimer(), 0.01, true, htime.clock)

-- 预读 preReadUnit
local preReadUnit = cj.CreateUnit(hplayer.player_passive, HL_ID.unit_token, 0, 0, 0)
hattributeSetter.relyRegister(preReadUnit)
hunit.del(preReadUnit)

-- 同步
hsync.init()

hcache.alloc("global")
hcache.protect("global")

for i = 1, bj_MAX_PLAYERS, 1 do
    -- init
    hplayer.players[i] = cj.Player(i - 1)
    -- 英雄模块初始化
    hhero.player_allow_qty[i] = 1
    hhero.player_heroes[i] = {}

    cj.SetPlayerHandicapXP(hplayer.players[i], 0) -- 经验置0

    hcache.alloc(hplayer.players[i])
    hcache.protect(hplayer.players[i])
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_GOLD_PREV, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_GOLD_TOTAL, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_GOLD_COST, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_GOLD_RATIO, 100)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_LUMBER_PREV, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_LUMBER_TOTAL, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_LUMBER_COST, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_LUMBER_RATIO, 100)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_EXP_RATIO, 100)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_SELL_RATIO, 50)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_APM, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_DAMAGE, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_BE_DAMAGE, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_KILL, 0)
    if ((cj.GetPlayerController(hplayer.players[i]) == MAP_CONTROL_USER)
        and (cj.GetPlayerSlotState(hplayer.players[i]) == PLAYER_SLOT_STATE_PLAYING)) then
        --
        hplayer.qty_current = hplayer.qty_current + 1

        -- 默认开启自动换木
        hplayer.setIsAutoConvert(hplayer.players[i], true)
        hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_STATUS, hplayer.player_status.gaming)

        -- 玩家离开游戏
        hevent.pool(hplayer.players[i], hevent_default_actions.player.leave, function(tgr)
            cj.TriggerRegisterPlayerEvent(tgr, hplayer.players[i], EVENT_PLAYER_LEAVE)
        end)
        -- 玩家选中单位
        hevent.pool(hplayer.players[i], hevent_default_actions.player.selection, function(tgr)
            cj.TriggerRegisterPlayerUnitEvent(tgr, hplayer.players[i], EVENT_PLAYER_UNIT_SELECTED, nil)
        end)
        hevent.onSelection(hplayer.players[i], 1, function(evtData)
            hcache.set(evtData.triggerPlayer, CONST_CACHE.PLAYER_SELECTION, evtData.triggerUnit)
        end)
        -- 玩家取消选择单位
        hevent.onDeSelection(hplayer.players[i], function(evtData)
            hcache.set(evtData.triggerPlayer, CONST_CACHE.PLAYER_SELECTION, nil)
        end)
        -- 玩家聊天接管
        hevent.pool(hplayer.players[i], hevent_default_actions.player.chat, function(tgr)
            cj.TriggerRegisterPlayerChatEvent(tgr, hplayer.players[i], "", false)
        end)
    else
        hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_STATUS, hplayer.player_status.none)
    end
end

--- debug
if (DEBUGGING) then
    local debugUI = hjapi.DzCreateFrameByTagName("TEXT", "StandardSmallTextTemplate", hdzui.origin.game(), "DEBUG-UI", 0)
    hjapi.DzFrameSetPoint(debugUI, FRAME_ALIGN_LEFT, hdzui.origin.game(), FRAME_ALIGN_LEFT, 0.001, 0.06)
    hjapi.DzFrameSetTextAlignment(debugUI, TEXT_ALIGN_LEFT)
    hjapi.DzFrameSetFont(debugUI, 'fonts.ttf', 8 * 0.001, 0)
    hjapi.DzFrameSetAlpha(debugUI, 210)
    local types = { "all", "max" }
    local typesLabel = {
        all = "总共",
        max = "最大值",
        ["+tmr"] = "计时器",
        ["+ply"] = "玩家",
        ["+frc"] = "玩家势力",
        ["+flt"] = "过滤器",
        ["+w3u"] = "单位",
        ["+w3d"] = "可破坏物",
        ["+grp"] = "单位组",
        ["+rct"] = "区域",
        ["+snd"] = "声音",
        ["+que"] = "任务",
        ["+trg"] = "触发器",
        ["+tac"] = "触发器动作",
        ["+EIP"] = "对点特效",
        ["+EIm"] = "附着特效",
        ["+loc"] = "点",
        ["pcvt"] = "玩家聊天事件",
        ["pevt"] = "玩家事件",
        ["uevt"] = "单位事件",
        ["tcnd"] = "触发器条件",
        ["wdvt"] = "可破坏物事件",
        ["item"] = "物品",
    }
    collectgarbage("collect")
    local rem0 = collectgarbage("count")
    local debugData = function()
        local count = { all = 0, max = JassDebug.handlemax() }
        for c = 1, count.max do
            local h = 0x100000 + c
            local info = JassDebug.handledef(h)
            if (info and info.type) then
                if (not table.includes(types, info.type)) then
                    table.insert(types, info.type)
                end
                if (count[info.type] == nil) then
                    count[info.type] = 0
                end
                count.all = count.all + 1
                count[info.type] = count[info.type] + 1
            end
        end
        local txts = {
            " ————————————————"
        }
        for _, t in ipairs(types) do
            table.insert(txts, "  " .. (typesLabel[t] or t) .. " : " .. (count[t] or 0))
        end
        table.insert(txts, " ————————————————")
        local i = 0
        for _, _ in pairs(htime.kernel) do
            i = i + 1
        end
        table.insert(txts, hcolor.sky("  计时内核 : " .. i))
        table.insert(txts, " ————————————————")
        table.insert(txts, hcolor.gold("  内存消耗 : " .. math.round((collectgarbage("count") - rem0) / 1024, 2) .. ' MB'))
        table.insert(txts, " ————————————————")
        return txts
    end
    htime.setInterval(2, function(_)
        hjapi.DzFrameSetText(debugUI, string.implode('|n', debugData()))
    end)
end

-- register APM
hevent.pool("global", hevent_default_actions.player.apm, function(tgr)
    hplayer.forEach(function(enumPlayer)
        cj.TriggerRegisterPlayerUnitEvent(tgr, enumPlayer, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, nil)
        cj.TriggerRegisterPlayerUnitEvent(tgr, enumPlayer, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, nil)
        cj.TriggerRegisterPlayerUnitEvent(tgr, enumPlayer, EVENT_PLAYER_UNIT_ISSUED_ORDER, nil)
    end)
end)

-- 恢复生命监听器
hmonitor.create(CONST_MONITOR.LIFE_BACK, 0.5,
    function(object)
        local val = hattribute.get(object, "life_back")
        hunit.addCurLife(object, val * 0.5)
    end,
    function(object)
        if (his.deleted(object) or his.dead(object)) then
            return true
        end
        local val = hattribute.get(object, "life_back")
        if (hunit.getMaxLife(object) <= 0 or val == 0) then
            return true
        end
        return false
    end
)

-- 恢复魔法监听器
hmonitor.create(CONST_MONITOR.MANA_BACK, 0.7,
    function(object)
        local val = hattribute.get(object, "mana_back")
        hunit.addCurMana(object, val * 0.7)
    end,
    function(object)
        if (his.deleted(object) or his.dead(object)) then
            return true
        end
        local val = hattribute.get(object, "mana_back")
        if (hunit.getMaxMana(object) <= 0 or val == 0) then
            return true
        end
        return false
    end
)

-- 沉默
local silentTrigger = cj.CreateTrigger()
cj.TriggerAddAction(silentTrigger, function()
    local triggerUnit = cj.GetTriggerUnit()
    if (his.silent(triggerUnit)) then
        cj.IssueImmediateOrder(triggerUnit, "stop")
    end
end)

-- 缴械
local unArmTrigger = cj.CreateTrigger()
cj.TriggerAddAction(unArmTrigger, function()
    local attacker = cj.GetAttacker()
    if (his.unarm(attacker)) then
        cj.IssueImmediateOrder(attacker, "stop")
    end
end)
for i = 1, bj_MAX_PLAYERS, 1 do
    cj.TriggerRegisterPlayerUnitEvent(silentTrigger, hplayer.players[i], EVENT_PLAYER_UNIT_SPELL_CHANNEL, nil)
    cj.TriggerRegisterPlayerUnitEvent(unArmTrigger, hplayer.players[i], EVENT_PLAYER_UNIT_ATTACKED, nil)
end
