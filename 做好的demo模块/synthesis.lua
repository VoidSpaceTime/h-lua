

---构建物品合成表，支持以下合成类型
--[[
    formula = {
    "强化圣剑=物理学圣剑+强化器+魔剑碎片1+魔剑碎片2",
    "魔剑碎片1+魔剑碎片2=魔+剑"}
]]
SYNTHESIS_TABLE = {
    "强化圣剑=物理学圣剑+强化器+魔剑碎片1+魔剑碎片2",
    "魔剑碎片1+魔剑碎片2=魔+剑"

}
---根据输入物品，组合调用合成
---@param item itemuserdata
---@param until_ untilusedata
hslk_item_syn = function (item, until_)
    local formulas_lo = TEXT_SYNTHESIS(SYNTHESIS_TABLE)
    local tab = SYN_TABLE_INDEX(formulas_lo, item)
    local until1 = until_
    jud_obj_syn(tab, until1)

end

--- 合成文本构建处理
--[[
formula = {
    "双铁剑+煎饼=铁剑+铁盾“,
    "双铁剑=铁剑+铁盾"
]]
TEXT_SYNTHESIS = function(formula)
    local formulas = {}
    for i, v in ipairs(formula) do
        local formulas_lo = {profit = {},fragment = {}}
        local f1 = string.explode("=", v)
    
        if (string.strpos(f1[1], '+')) == false then
            formulas_lo.profit = f1[1]
        else
            formulas_lo.profit = string.explode("+",f1[1])
        end
    
        if (string.strpos(f1[2], '+')) == false then
            formulas_lo.fragment = f1[2]
        else
            formulas_lo.fragment = string.explode("+",f1[2])
        end
    
        table.insert(formulas, formulas_lo)    
    end
    return formulas
end


-- 判断此物品是否再合成表里，并返回含有合成表的表
---@param formulas table
---@param item_if userdata
---@return table
SYN_TABLE_INDEX = function (formulas, item_if)
    
    local table_index = {}  --记录此物品存在的合成表索引
    --判断物品是否再合成表里，并记录表的索引
    for index, value in ipairs(formulas) do
        if table.includes(value.fragment, hitem.getName(item_if)) then
            table.insert(table_index, value)
        end    
    end
    return table_index
end

--- 判断单位物品是否满足合成条件-满足情况下进行合成
---@param table_index table 含有触发物品的合成表索引
---@param until_ userdata   合成单位
jud_obj_syn = function (table_index, until_)
    local table_item = {}  --单位持有的物品 --第几个格子里，放着什么东西
    local table_itemname = {} --记录物品hand
    local u_item = {}   --储存要删除的物品usedata
    local back = {} --储存这个格子的
    local com_tab_syn = {}
    hitem.forEach(until_,function (enumitem, slotIndex)
        if enumitem ~= nil  then
            --第几个格子，放着什么东西
            table_item[slotIndex + 1] = hitem.getName(enumitem) --格子数+1 偏移
            table_itemname[slotIndex + 1] = enumitem
        end

    end)

    dump(table_item, "格子的东西")
    local flag_table_index = false

    --这个循环是匹配每个合成表的材料背包是否拥有，拥有的话进行标记
    for key, _ in pairs(table_index) do
        local temp = {}
        if flag_table_index then
            print('成功跳出循环')
            break
        end  
        --合成材料
        for i = 1, #table_index[key].fragment, 1 do    
        
            local flag = false
            --物品格子循环判定
            for index = 1, 6, 1 do
                if (table_index[key].fragment[i] == table_item[index] and table_item[index] and not flag and not back[index]) then
                    back[index] = true
                    flag = true
                    table.insert(temp, table_itemname[index])
                end
            end
            
            if not flag then
                print("材料不够退出")
                return
            end
        end
        table.insert(com_tab_syn, table_index[key].profit)
        u_item = temp
        flag_table_index = true

    end

    if not flag_table_index then
        print("材料不够退出 22")
        return
    end

    for i, v in ipairs(u_item) do
        if not until_ then
            return
        end
        hitem.destroy(v, 0)
    end


    dump(com_tab_syn, "com_tab_syn")
    print("长度是:" .. #com_tab_syn[1])

    local it

    if type(com_tab_syn[1]) == "string" then
        dump(com_tab_syn[1],"value")
        it = hitem.create({
            id = hslk.n2i(com_tab_syn[1]),
            whichUnit = until_
    })
    else
        for _, value in ipairs(com_tab_syn[1]) do
            dump(value,"value")
            it = hitem.create({
                id = hslk.n2i(value),
                whichUnit = until_
        })
        end
    end



    return it
end

