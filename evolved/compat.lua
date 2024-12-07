---@class evolved.compat
local compat = {}

compat.pack = table.pack or function(...)
    return { n = select('#', ...), ... }
end

compat.unpack = table.unpack or function(list, i, j)
    return unpack(list, i, j)
end

compat.move = table.move or function(a1, f, e, t, a2)
    if a2 == nil then
        a2 = a1
    end

    if e < f then
        return a2
    end

    local d = t - f

    if t > e or t <= f or a2 ~= a1 then
        for i = f, e do a2[i + d] = a1[i] end
    else
        for i = e, f, -1 do a2[i + d] = a1[i] end
    end

    return a2
end

return compat
