local iterators = {}

---@generic K
---@param t table<K, any>
---@return fun(): K
function iterators.keys(t)
    if #t > 0 then
        local i = 0
        return function()
            i = i + 1
            if i <= #t then
                return i
            end
        end
    else
        local k = nil
        return function()
            local v
            k, v = next(t, k)
            if k ~= nil then
                return k
            end
        end
    end
end

---@generic V
---@param t table<any, V>
---@return fun(): V?
function iterators.values(t)
    if #t > 0 then
        local i = 0
        return function()
            i = i + 1
            if i <= #t then
                return t[i]
            end
        end
    else
        local k = nil
        return function()
            local v
            k, v = next(t, k)
            if k ~= nil then
                return v
            end
        end
    end
end

---@generic V
---@param iter fun(): V?
---@return integer
function iterators.count(iter)
    local count = 0
    for _ in iter do count = count + 1 end
    return count
end

---@generic V
---@param iter fun(): V?
---@param func fun(v: V): boolean
---@return fun(): V?
function iterators.filter(iter, func)
    return function()
        while true do
            local v = iter()
            if v == nil then
                return
            end
            if func(v) then
                return v
            end
        end
    end
end

return iterators
