local evolved = require 'evolved.evolved'

---@class evolved.singles
local singles = {}

---@param registry evolved.registry
---@param component any
---@return evolved.entity
---@nodiscard
function singles.create(registry, component)
    local single = evolved.create_entity(registry)
    evolved.insert_component(single, single, component)
    return single
end

---@param single evolved.entity
---@return any
---@nodiscard
function singles.get(single)
    return evolved.get_component(single, single)
end

---@param single evolved.entity
---@return boolean
---@nodiscard
function singles.has(single)
    return evolved.has_component(single, single)
end

---@param single evolved.entity
---@param component any
function singles.assign(single, component)
    evolved.assign_component(single, single, component)
end

return singles
