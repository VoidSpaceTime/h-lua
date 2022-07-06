--- 自定义公式

---将秒换算为时:分:秒
---@param temp number 秒
HH_MM_SS = function (temp)
    local hour, min, sec=  0, 0, 0
    hour = temp//3600
    min = (temp%3600)//60
    sec = temp%60
    return hour, min, sec
end




---移动单位到目标坐标,判断目标坐标是否超出地图边界
---@param u userdata
---@param x number
---@param y number
hunit.moveuntil = function (u, x, y)
    if x == nil or y == nil or u == nil and hrect.isBorder(u, x, y) == false then
        return
    end
    cj.SetUnitX(u, x)
    cj.SetUnitY(u, y)
end



--[[
    冲锋

    triggerUnit     --释放单位
    targetUnit    --目标单位
    targetX   --目标坐标
    targetY   --目标坐标
    height = 0, --飞跃高度（可选的，默认0)
    frequency = 0.003 --频率
    speed = 500, --每秒冲击的距离


    sourceUnit, --[必须]伤害来源
]]
function charge (options)
    
    local sourceUnit = options.triggerUnit   --释放单位
    local targetUnit = options.targetUnit    --目标单位
    local x = options.targetX   --目标坐标
    local y = options.targetY   --目标坐标
    local frequency = options.frequency or  math.min(0.2, math.max(0.003, options.frequency or 0.01))    --计时器频率
    local speed = options.speed or  math.min(10000, math.max(10, options.speed or 500)) --每频次速度

    local angle, distance = 0, 0

    local starx = hunit.x(sourceUnit)
    local stary = hunit.y(sourceUnit)

    angle = math.angle(hunit.x(sourceUnit), hunit.y(sourceUnit), x, y)
    distance = math.distance(hunit.x(sourceUnit), hunit.y(sourceUnit), x, y)

    local tfa = angle
    local tdc = 0

    htime.setInterval(frequency, function(curTimer)

        tdc = tdc + speed
        -- local tx ,ty = math.polarProjection(hunit.x(u), hunit.y(u), tdc, tfa )
        local tx ,ty = math.polarProjection(starx, stary, tdc, tfa )
        hunit.moveuntil(sourceUnit, tx, ty)

        if tdc >= distance and hrect.isBorder(sourceUnit, tx, ty) then
            curTimer.destroy()
        end
    end)
end