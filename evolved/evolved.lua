---@class evolved
local evolved = {}

---@class evolved.entity
local evolved_entity_mt = {}
evolved_entity_mt.__index = evolved_entity_mt

---@class evolved.query
local evolved_query_mt = {}
evolved_query_mt.__index = evolved_query_mt

---@class evolved.chunk
---@field entities evolved.entity[]
---@field components table<evolved.entity, any[]>
local evolved_chunk_mt = {}
evolved_chunk_mt.__index = evolved_chunk_mt

---@return evolved.entity
---@nodiscard
function evolved.create_entity() end

---@param entity evolved.entity
function evolved.destroy_entity(entity) end

---@param entity evolved.entity
---@param fragment evolved.entity
---@return any
---@nodiscard
function evolved.get_component(entity, fragment) end

---@param entity evolved.entity
---@param fragment evolved.entity
---@return boolean
---@nodiscard
function evolved.has_component(entity, fragment) end

---@param entity evolved.entity
---@param ... evolved.entity
---@return boolean
---@nodiscard
function evolved.has_all_components(entity, ...) end

---@param entity evolved.entity
---@param ... evolved.entity
---@return boolean
---@nodiscard
function evolved.has_any_components(entity, ...) end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
function evolved.assign_component(entity, fragment, component) end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
function evolved.insert_component(entity, fragment, component) end

---@param entity evolved.entity
---@param fragment evolved.entity
function evolved.remove_component(entity, fragment) end

---@param ... evolved.entity
---@return evolved.query
---@nodiscard
function evolved.create_query(...) end

---@param query evolved.query
---@return fun(): evolved.chunk?
---@nodiscard
function evolved.execute_query(query) end

return evolved
