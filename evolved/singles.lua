local registry = require 'evolved.registry'

---@class evolved.singles
local singles = {}

---@param component any
---@return evolved.entity
---@nodiscard
function singles.single(component)
    local single = registry.entity()
    registry.insert(single, single, component)
    return single
end

---@param single evolved.entity
---@return any
---@nodiscard
function singles.get(single)
    return registry.get(single, single)
end

---@param single evolved.entity
---@return boolean
---@nodiscard
function singles.has(single)
    return registry.has(single, single)
end

---@param single evolved.entity
---@param component any
function singles.assign(single, component)
    registry.assign(single, single, component)
end

return singles
