---@class evolved.compat
local compat = {}

compat.pack = table.pack or function(...)
    return { n = select('#', ...), ... }
end

compat.unpack = table.unpack or function(list, i, j)
    return unpack(list, i, j)
end

compat.move = table.move or function(a1, f, e, t, a2)
    error('compat.move is not implemented yet', 2)
end

return compat
