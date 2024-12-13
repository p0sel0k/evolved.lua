---@class evolved
local evolved = {}

---@alias evolved.id integer
---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.component any

---@class (exact) evolved.chunk
---@field __fragments table<evolved.fragment, boolean>
---@field __components table<evolved.fragment, evolved.component[]>

---
---
---
---
---

local __freelist_ids = {} ---@type evolved.id[]
local __available_idx = 0 ---@type integer

local __entity_chunks = {} ---@type table<integer, evolved.chunk>
local __entity_chunk_indices = {} ---@type table<integer, integer>

---
---
---
---
---

---@param index integer
---@param version integer
---@return evolved.id
---@nodiscard
local function __pack_id(index, version)
    assert(index >= 1 and index <= 0xFFFFF, 'id index out of range [1;0xFFFFF]')
    assert(version >= 1 and version <= 0x7FF, 'id version out of range [1;0x7FF]')
    return index + version * 0x100000
end

---@param id evolved.id
---@return integer index
---@return integer version
---@nodiscard
local function __unpack_id(id)
    local index = id % 0x100000
    local version = (id - index) / 0x100000
    return index, version
end

---@return evolved.id
---@nodiscard
local function __acquire_id()
    if __available_idx ~= 0 then
        local index = __available_idx
        local freelist_id = __freelist_ids[index]
        __available_idx = freelist_id % 0x100000
        local version = freelist_id - __available_idx

        local acquired_id = index + version
        __freelist_ids[index] = acquired_id
        return acquired_id
    else
        if #__freelist_ids == 0xFFFFF then
            error('id index overflow', 2)
        end

        local index = #__freelist_ids + 1
        local version = 0x100000

        local acquired_id = index + version
        __freelist_ids[index] = acquired_id
        return acquired_id
    end
end

---@param id evolved.id
---@return boolean
---@nodiscard
local function __alive_id(id)
    local index = id % 0x100000
    return __freelist_ids[index] == id
end

---@param id evolved.id
local function __release_id(id)
    local index = id % 0x100000
    local version = id - index

    if __freelist_ids[index] ~= id then
        error('id is not acquired or already released', 2)
    end

    version = version == 0x7FF00000
        and 0x100000
        or version + 0x100000

    __freelist_ids[index] = __available_idx + version
    __available_idx = index
end

---
---
---
---
---

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __chunk_has_fragment(chunk, fragment)
    return chunk.__fragments[fragment]
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
local function __chunk_has_all_fragments(chunk, ...)
    local fragments = chunk.__fragments

    for i = 1, select('#', ...) do
        if not fragments[select(i, ...)] then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@return boolean
---@nodiscard
local function __chunk_has_all_fragment_list(chunk, fragment_list)
    local fragments = chunk.__fragments

    for i = 1, #fragment_list do
        if not fragments[fragment_list[i]] then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
local function __chunk_has_any_fragments(chunk, ...)
    local fragments = chunk.__fragments

    for i = 1, select('#', ...) do
        if fragments[select(i, ...)] then
            return true
        end
    end

    return false
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@return boolean
---@nodiscard
local function __chunk_has_any_fragment_list(chunk, fragment_list)
    local fragments = chunk.__fragments

    for i = 1, #fragment_list do
        if fragments[fragment_list[i]] then
            return true
        end
    end

    return false
end

---@param chunk evolved.chunk
---@param chunk_index integer
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
local function __chunk_get_components(chunk, chunk_index, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return
    end

    local components = chunk.__components

    if fragment_count == 1 then
        local f1 = ...
        local cs1 = components[f1]
        return cs1 and cs1[chunk_index]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local cs1, cs2 = components[f1], components[f2]
        return cs1 and cs1[chunk_index], cs2 and cs2[chunk_index]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[chunk_index], cs2 and cs2[chunk_index], cs3 and cs3[chunk_index]
    end

    do
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[chunk_index], cs2 and cs2[chunk_index], cs3 and cs3[chunk_index],
            __chunk_get_components(chunk, chunk_index, select(4, ...))
    end
end

---
---
---
---
---

---@return evolved.id
---@nodiscard
function evolved.id()
    return __acquire_id()
end

---@param index integer
---@param version integer
---@return evolved.id
---@nodiscard
function evolved.pack(index, version)
    return __pack_id(index, version)
end

---@param id evolved.id
---@return integer index
---@return integer version
---@nodiscard
function evolved.unpack(id)
    return __unpack_id(id)
end

---@param id evolved.id
---@return boolean
---@nodiscard
function evolved.alive(id)
    return __alive_id(id)
end

---@param id evolved.id
function evolved.destroy(id)
    if __alive_id(id) then
        __release_id(id)
    end
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
function evolved.get(entity, ...)
    if not __alive_id(entity) then
        return
    end

    local entity_index = __unpack_id(entity)
    local entity_chunk = __entity_chunks[entity_index]

    if not entity_chunk then
        return
    end

    local entity_chunk_index = __entity_chunk_indices[entity_index]
    return __chunk_get_components(entity_chunk, entity_chunk_index, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function evolved.has(entity, fragment)
    if not __alive_id(entity) then
        return false
    end

    local entity_index = __unpack_id(entity)
    local entity_chunk = __entity_chunks[entity_index]

    if not entity_chunk then
        return false
    end

    return __chunk_has_fragment(entity_chunk, fragment)
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_all(entity, ...)
    if not __alive_id(entity) then
        return false
    end

    local entity_index = __unpack_id(entity)
    local entity_chunk = __entity_chunks[entity_index]

    if not entity_chunk then
        return select('#', ...) == 0
    end

    return __chunk_has_all_fragments(entity_chunk, ...)
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_any(entity, ...)
    if not __alive_id(entity) then
        return false
    end

    local entity_index = __unpack_id(entity)
    local entity_chunk = __entity_chunks[entity_index]

    if not entity_chunk then
        return false
    end

    return __chunk_has_any_fragments(entity_chunk, ...)
end

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
