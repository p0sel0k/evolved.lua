---@class evolved.registry
local registry = {}

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
function registry.entity() end

---@param entity evolved.entity
function registry.destroy(entity) end

---@param entity evolved.entity
---@param fragment evolved.entity
---@return any
---@nodiscard
function registry.get(entity, fragment) end

---@param entity evolved.entity
---@param fragment evolved.entity
---@return boolean
---@nodiscard
function registry.has(entity, fragment) end

---@param entity evolved.entity
---@param ... evolved.entity
---@return boolean
---@nodiscard
function registry.has_all(entity, ...) end

---@param entity evolved.entity
---@param ... evolved.entity
---@return boolean
---@nodiscard
function registry.has_any(entity, ...) end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
function registry.assign(entity, fragment, component) end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
function registry.insert(entity, fragment, component) end

---@param entity evolved.entity
---@param fragment evolved.entity
function registry.remove(entity, fragment) end

---@param ... evolved.entity
---@return evolved.query
---@nodiscard
function registry.query(...) end

---@param query evolved.query
---@return fun(): evolved.chunk?
---@nodiscard
function registry.execute(query) end

return registry
