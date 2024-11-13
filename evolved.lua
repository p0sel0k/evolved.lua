---@class evolved
local evolved = {}

---
---
---
---
---

---@class evolved.chunk
---@field owner evolved.registry
---@field parent? evolved.chunk
---@field fragment? evolved.entity
---@field entities evolved.entity[]
---@field with_cache table<evolved.entity, evolved.chunk>
---@field without_cache table<evolved.entity, evolved.chunk>
local evolved_chunk_mt = {}
evolved_chunk_mt.__index = evolved_chunk_mt

---@class evolved.entity
---@field owner evolved.registry
---@field id integer
---@field chunk? evolved.chunk
---@field index_in_chunk? integer
local evolved_entity_mt = {}
evolved_entity_mt.__index = evolved_entity_mt

---@class evolved.registry
---@field nextid integer
---@field chunks evolved.chunk[]
local evolved_registry_mt = {}
evolved_registry_mt.__index = evolved_registry_mt

---
---
---
---
---

---@param owner evolved.registry
---@param parent? evolved.chunk
---@param fragment? evolved.entity
---@return evolved.chunk
local function create_chunk(owner, parent, fragment)
    ---@type evolved.chunk
    local chunk = {
        owner = owner,
        parent = parent,
        fragment = fragment,
        entities = {},
        with_cache = {},
        without_cache = {},
    }
    return setmetatable(chunk, evolved_chunk_mt)
end

---@param owner evolved.registry
---@param id integer
---@return evolved.entity
local function create_entity(owner, id)
    ---@type evolved.entity
    local entity = {
        owner = owner,
        id = id,
    }
    return setmetatable(entity, evolved_entity_mt)
end

---@return evolved.registry
local function create_registry()
    ---@type evolved.registry
    local registry = {
        nextid = 1,
        chunks = {},
    }

    registry.chunks[1] = create_chunk(registry)

    return setmetatable(registry, evolved_registry_mt)
end

---
---
--- CHUNK API
---
---

function evolved_chunk_mt:__tostring()
    local id, iter = '', self
    while iter and iter.parent and iter.fragment do
        id, iter = iter.fragment.id .. (id == '' and '' or ',') .. id, iter.parent
    end
    return string.format('evolved.chunk(%s)', id)
end

---@param fragment evolved.entity
---@return evolved.chunk
function evolved_chunk_mt:with(fragment)
    do
        local with_chunk = self.with_cache[fragment]
        if with_chunk then return with_chunk end
    end

    if self.fragment and self.fragment.id == fragment.id then
        return self
    end

    if not self.fragment or self.fragment.id < fragment.id then
        local new_chunk = create_chunk(self.owner, self, fragment)
        self.owner.chunks[#self.owner.chunks + 1] = new_chunk

        self.with_cache[fragment] = new_chunk
        new_chunk.without_cache[fragment] = self

        return new_chunk
    end

    do
        local sibling_chunk = self.parent
            :with(fragment)
            :with(self.fragment)

        self.with_cache[fragment] = sibling_chunk

        return sibling_chunk
    end
end

---@param fragment evolved.entity
---@return evolved.chunk
function evolved_chunk_mt:without(fragment)
    do
        local without_chunk = self.without_cache[fragment]
        if without_chunk then return without_chunk end
    end

    if not self.fragment or self.fragment.id < fragment.id then
        return self
    end

    do
        local sibling_chunk = self.parent
            :without(fragment)
            :with(self.fragment)

        self.without_cache[fragment] = sibling_chunk

        return sibling_chunk
    end
end

---@param entity evolved.entity
function evolved_chunk_mt:insert(entity)
    self.entities[#self.entities + 1] = entity
    entity.chunk, entity.index_in_chunk = self, #self.entities
end

---@param entity evolved.entity
function evolved_chunk_mt:remove(entity)
    local last_entity = self.entities[#self.entities]

    if entity ~= last_entity then
        self.entities[entity.index_in_chunk] = last_entity
        last_entity.index_in_chunk = entity.index_in_chunk
    end

    self.entities[#self.entities] = nil
    entity.chunk, entity.index_in_chunk = nil, 0
end

---@param fragment evolved.entity
---@return boolean
---@nodiscard
function evolved_chunk_mt:has_fragment(fragment)
    return self.components[fragment] ~= nil
end

---@param ... evolved.entity
---@return boolean
---@nodiscard
function evolved_chunk_mt:has_all_fragments(...)
    local fragment_count = select('#', ...)

    for i = 1, fragment_count do
        local fragment = select(i, ...)
        if self.components[fragment] == nil then
            return false
        end
    end

    return true
end

---@param ... evolved.entity
---@return boolean
---@nodiscard
function evolved_chunk_mt:has_any_fragment(...)
    local fragment_count = select('#', ...)

    for i = 1, fragment_count do
        local fragment = select(i, ...)
        if self.components[fragment] ~= nil then
            return true
        end
    end

    return false
end

---
---
--- ENTITY API
---
---

function evolved_entity_mt:__tostring()
    return string.format('evolved.entity(%d)', self.id)
end

function evolved_entity_mt:destroy()
    self.chunk:remove(self)
end

---@param fragment evolved.entity
function evolved_entity_mt:insert(fragment)
    local old_chunk = assert(self.chunk)
    local new_chunk = old_chunk:with(fragment)

    old_chunk:remove(self)
    new_chunk:insert(self)
end

---@param fragment evolved.entity
function evolved_entity_mt:remove(fragment)
    local old_chunk = assert(self.chunk)
    local new_chunk = old_chunk:without(fragment)

    old_chunk:remove(self)
    new_chunk:insert(self)
end

---
---
--- REGISTRY API
---
---

---@return evolved.chunk
function evolved_registry_mt:root()
    return self.chunks[1]
end

---@return evolved.entity
function evolved_registry_mt:entity()
    local id = self.nextid
    self.nextid = self.nextid + 1
    local entity = create_entity(self, id)
    self.chunks[1]:insert(entity)
    return entity
end

---
---
--- MODULE API
---
---

---@return evolved.registry
function evolved.registry()
    return create_registry()
end

---
---
---
---
---

return evolved
