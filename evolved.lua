---@class evolved
local evolved = {}

---@alias evolved.id integer
---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.component any

---@return evolved.id
---@nodiscard
function evolved.id() end

---@param index integer
---@param version integer
---@return evolved.id
---@nodiscard
function evolved.pack(index, version) end

---@param id evolved.id
---@return integer index
---@return integer version
---@nodiscard
function evolved.unpack(id) end

---@param id evolved.id
---@return boolean
---@nodiscard
function evolved.alive(id) end

---@param id evolved.id
function evolved.destroy(id) end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
function evolved.get(entity, ...) end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function evolved.has(entity, fragment) end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_all(entity, ...) end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_any(entity, ...) end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
function evolved.set(entity, fragment, component) end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@return boolean is_assigned
function evolved.assign(entity, fragment, component) end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@return boolean is_inserted
function evolved.insert(entity, fragment, component) end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
function evolved.remove(entity, ...) end

---@param entity evolved.entity
function evolved.clear(entity) end

return evolved
