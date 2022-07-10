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



Func = {}

--三次贝塞尔
--[[    
    可同时调用三个计算  

    local x = bezier3(this_x, mid1_x, mid2_x, stop_x, p_1)  --计算返回x
    local y = bezier3(this_y, mid1_y, mid2_y, stop_y, p_1)  --计算返回y
    local z = bezier3(this_z, mid1_z, mid2_z, stop_z, p_1)  --计算返回z
]]
---@param p_1 number 只能在0-1之间,表示时间/比例
function Func.bezier3 (start,  mid1,  mid2,  stop,  p_1 )
	local  m = p_1 * p_1
	return start + 3. * p_1 * (mid1 - start) + 3. * m * (mid2 - 2. * mid1 + start) + m * p_1 * (3. * (mid1 - mid2) + stop - start)
end

function Func.vec3_bezier3 ( this_x,  this_y,  this_z,  mid1_x,  mid1_y,  mid1_z,  mid2_x,  mid2_y,  mid2_z,  stop_x,  stop_y,  stop_z,  p_1)
	local x = Func.bezier3(this_x, mid1_x, mid2_x, stop_x, p_1)
	local y = Func.bezier3(this_y, mid1_y, mid2_y, stop_y, p_1)
	local z = Func.bezier3(this_z, mid1_z, mid2_z, stop_z, p_1)
	return x, y, z
end



--[[
    冲锋

    triggerUnit     --释放单位
    targetUnit    --目标单位
    targetX   --目标坐标
    targetY   --目标坐标
    track     --是否跟踪目标 

    frequency = 0.003 --频率,终止是大于等于 1 可以通过/1计算次数

    heightMax = 0, --飞跃高度（可选的，默认0)
    p1_dist, p1_heig = 0.2, 0.3 ;p2_dist, p2_heig = 1, 1    p1 p2 两个点的比,设定高度后可选


    sourceUnit, --[必须]伤害来源
]]
function Charge (options)
    
    local sourceUnit = options.triggerUnit   --释放单位
    local targetUnit = options.targetUnit    --目标单位


    local stop_x, stop_y, stop_z

    --判定目标是否是单位
    if targetUnit then      
        stop_x = hunit.x(targetUnit)   --目标坐标x
        stop_y = hunit.y(targetUnit)   --目标坐标y
        stop_z = hunit.z(sourceUnit)  or 0 --目标坐标z 默认0
    else
        stop_x = options.targetX   --目标坐标x
        stop_y = options.targetY   --目标坐标y
        stop_z = options.targetz or 0 --目标坐标z 默认0
    end


    local heightmax = options.heightMax or 0    --最大高度
    --起始位坐标
    local star_x = hunit.x(sourceUnit)
    local star_y = hunit.y(sourceUnit)
    local star_z = hunit.z(sourceUnit)
    local p1_dist, p1_heig = options.p1_dist or 0.3 , options.p1_heig or 1
    local p2_dist, p2_heig = options.p2_dist or 0.75 , options.p1_heig or 1


    local angle, distance = 0, 0
    angle = math.angle(star_x, star_y, stop_x, stop_y)  --角度
    distance = math.distance(star_x, star_y, stop_x, stop_y)    --距离

    hskill.addProperty()

    local mid1_x ,mid1_y = math.polarProjection(star_x, star_y, distance * p1_dist, angle)
    local mid1_z = heightmax * p1_heig + star_z

    local mid2_x ,mid2_y = math.polarProjection(star_x, star_y, distance *p2_dist,  angle)
    local mid2_z = heightmax * p2_heig + star_z

    local frequency = options.frequency or  math.min(0.2, math.max(0.003, options.frequency or 0.02))    --计时器频率

    
    local now_x, now_y, now_z = star_x, star_y, star_z


    local t_1 = 0

    local track = options.track or false        --是否跟踪目标


    htime.setInterval(frequency, function(curTimer)

      -- local tx ,ty = math.polarProjection(hunit.x(u), hunit.y(u), tdc, tfa )
        -- local tx ,ty = math.polarProjection(starx, stary, tdc, tfa )
        -- hunit.moveuntil(sourceUnit, tx, ty)
        -- if tdc >= distance and hrect.isBorder(sourceUnit, tx, ty) then
        --     curTimer.destroy()
        -- end

        if track == true then
            stop_x, stop_y = hunit.x(targetUnit) or stop_x, hunit.y(targetUnit)or stop_y
            now_x, now_y, now_z = Func.vec3_bezier3 (now_x, now_y, now_z, mid1_x, mid1_y, mid1_z, mid2_x, mid2_y, mid2_z, stop_x, stop_y, stop_z, t_1)
        else
            -- now_x, now_y, now_z = Func.vec3_bezier3 (star_x, star_y, star_z, mid1_x, mid1_y, mid1_z, mid2_x, mid2_y, mid2_z, stop_x, stop_y, stop_z, t_1)
            now_x, now_y, now_z = Func.vec3_bezier3 (star_x, star_y, star_z, mid1_x, mid1_y, mid1_z, mid2_x, mid2_y, mid2_z, stop_x, stop_y, stop_z, t_1)
            -- now_x, now_y, now_z = Func.vec3_bezier3 (0, 0, 0, 200, 0, 10, 400, 0, 10, 600, 0, 0, t_1)
        end
        print(now_x,  now_y,  now_z)
        hunit.setCanFly(sourceUnit)
        hunit.setFlyHeight(sourceUnit, now_z)
        hunit.moveuntil(sourceUnit, now_x, now_y)

        if t_1 >= 1 and hrect.isBorder(sourceUnit, stop_x, stop_y) then
            curTimer.destroy()
            hunit.setFlyHeight(sourceUnit, star_z)
        end

        t_1 = t_1 + frequency


    end)
end