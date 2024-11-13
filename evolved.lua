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
---@field children evolved.chunk[]
---@field entities evolved.entity[]
---@field components table<evolved.entity, any[]>
---@field with_cache table<evolved.entity, evolved.chunk>
---@field without_cache table<evolved.entity, evolved.chunk>
local evolved_chunk_mt = {}
evolved_chunk_mt.__index = evolved_chunk_mt

---@class evolved.query
---@field owner evolved.registry
---@field id integer
---@field roots evolved.chunk[]
---@field fragments evolved.entity[]
local evolved_query_mt = {}
evolved_query_mt.__index = evolved_query_mt

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
---@field queries evolved.query[]
---@field entities evolved.entity[]
---@field chunks_by_fragment table<evolved.entity, evolved.chunk[]>
---@field queries_by_fragment table<evolved.entity, evolved.query[]>
local evolved_registry_mt = {}
evolved_registry_mt.__index = evolved_registry_mt

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

    if self.fragment and self.fragment.id > fragment.id then
        local sibling_chunk = self.parent
            :with(fragment)
            :with(self.fragment)

        self.with_cache[fragment] = sibling_chunk

        return sibling_chunk
    end

    ---@type evolved.chunk
    local new_chunk = {
        owner = self.owner,
        parent = self,
        fragment = fragment,
        children = {},
        entities = {},
        components = {},
        with_cache = {},
        without_cache = {},
    }
    setmetatable(new_chunk, evolved_chunk_mt)
    self.owner.chunks[#self.owner.chunks + 1] = new_chunk

    do
        local iter = new_chunk
        while iter and iter.fragment do
            new_chunk.components[iter.fragment] = {}
            iter = iter.parent
        end
    end

    do
        self.children[#self.children + 1] = new_chunk
    end

    do
        local chunks = self.owner.chunks_by_fragment[fragment] or {}
        chunks[#chunks + 1] = new_chunk
        self.owner.chunks_by_fragment[fragment] = chunks
    end

    do
        local queries = self.owner.queries_by_fragment[fragment] or {}
        for _, query in ipairs(queries) do
            if new_chunk:has_all_fragments(unpack(query.fragments)) then
                query.roots[#query.roots + 1] = new_chunk
            end
        end
    end

    self.with_cache[fragment] = new_chunk
    new_chunk.without_cache[fragment] = self

    return new_chunk
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

    local sibling_chunk = self.parent
        :without(fragment)
        :with(self.fragment)

    self.without_cache[fragment] = sibling_chunk

    return sibling_chunk
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
--- QUERY API
---
---

function evolved_query_mt:__tostring()
    return string.format('evolved.query(%d)', self.id)
end

---@return fun(): evolved.chunk?
function evolved_query_mt:chunks()
    return coroutine.wrap(function()
        local queue = {}

        for i = #self.roots, 1, -1 do
            queue[#queue + 1] = self.roots[i]
        end

        while #queue > 0 do
            local chunk = table.remove(queue)

            coroutine.yield(chunk)

            for i = #chunk.children, 1, -1 do
                queue[#queue + 1] = chunk.children[i]
            end
        end
    end)
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

---@param ... evolved.entity
---@return evolved.chunk
function evolved_registry_mt:chunk(...)
    local chunk = self.chunks[1]

    for i = 1, select('#', ...) do
        chunk = chunk:with(select(i, ...))
    end

    return chunk
end

---@param ... evolved.entity
---@return evolved.query
function evolved_registry_mt:query(...)
    local id = self.nextid
    self.nextid = self.nextid + 1

    ---@type evolved.query
    local query = {
        owner = self,
        id = id,
        roots = {},
        fragments = {},
    }
    setmetatable(query, evolved_query_mt)
    self.queries[#self.queries + 1] = query

    do
        local fragments = { ... }
        table.sort(fragments, function(a, b) return a.id < b.id end)
        query.fragments = fragments
    end

    if #query.fragments > 0 then
        local fragment = query.fragments[#query.fragments]
        local chunks = self.chunks_by_fragment[fragment] or {}
        for _, chunk in ipairs(chunks) do
            if chunk:has_all_fragments(...) then
                query.roots[#query.roots + 1] = chunk
            end
        end
    end

    if #query.fragments > 0 then
        local fragment = query.fragments[#query.fragments]
        local queries = self.queries_by_fragment[fragment] or {}
        queries[#queries + 1] = query
        self.queries_by_fragment[fragment] = queries
    end

    return query
end

---@param ... evolved.entity
---@return evolved.entity
function evolved_registry_mt:entity(...)
    local id = self.nextid
    self.nextid = self.nextid + 1

    ---@type evolved.entity
    local entity = {
        owner = self,
        id = id,
        chunk = nil,
        index_in_chunk = nil,
    }
    setmetatable(entity, evolved_entity_mt)
    self.entities[#self.entities + 1] = entity

    self:chunk(...):insert(entity)

    return entity
end

---
---
--- MODULE API
---
---

---@return evolved.registry
function evolved.registry()
    ---@type evolved.registry
    local registry = {
        nextid = 1,
        chunks = {},
        queries = {},
        entities = {},
        chunks_by_fragment = {},
        queries_by_fragment = {},
    }
    setmetatable(registry, evolved_registry_mt)

    ---@type evolved.chunk
    local root_chunk = {
        owner = registry,
        parent = nil,
        fragment = nil,
        children = {},
        entities = {},
        components = {},
        with_cache = {},
        without_cache = {},
    }
    setmetatable(root_chunk, evolved_chunk_mt)

    registry.chunks[1] = root_chunk

    return registry
end

---
---
---
---
---

return evolved
