---@class evolved.compat
local compat = {}

compat.pack = table.pack or function(...)
    return { n = select('#', ...), ... }
end

compat.unpack = table.unpack or function(list, i, j)
    return unpack(list, i, j)
end

return compat
