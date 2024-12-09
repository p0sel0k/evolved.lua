local registry = require 'evolved.registry'

---@class evolved.singles
local singles = {}

---@param component evolved.component
---@return evolved.entity
---@nodiscard
function singles.single(component)
    local single = registry.entity()
    return single:set(single, component)
end

---@param single evolved.entity
---@return evolved.component
---@nodiscard
function singles.get(single)
    return single:get(single)
end

---@param single evolved.entity
---@return boolean
---@nodiscard
function singles.has(single)
    return single:has(single)
end

---@param single evolved.entity
---@param component evolved.component
---@return evolved.entity
function singles.set(single, component)
    return single:set(single, component)
end

return singles
