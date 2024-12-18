---@class evolved
local evolved = {}

---@alias evolved.id integer
---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.component any

---@class (exact) evolved.chunk
---@field __parent? evolved.chunk
---@field __children evolved.chunk[]
---@field __fragment evolved.fragment
---@field __entities evolved.entity[]
---@field __fragments table<evolved.fragment, boolean>
---@field __components table<evolved.fragment, evolved.component[]>
---@field __with_fragment_cache table<evolved.fragment, evolved.chunk>
---@field __without_fragment_cache table<evolved.fragment, evolved.chunk>

---
---
---
---
---

local __freelist_ids = {} ---@type evolved.id[]
local __available_idx = 0 ---@type integer

local __root_chunks = {} ---@type table<evolved.fragment, evolved.chunk>
local __major_chunks = {} ---@type table<evolved.fragment, evolved.chunk>

local __entity_chunks = {} ---@type table<integer, evolved.chunk>
local __entity_places = {} ---@type table<integer, integer>

local __structural_changes = 0 ---@type integer

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

---@param fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __root_chunk(fragment)
    do
        local root_chunk = __root_chunks[fragment]
        if root_chunk then return root_chunk end
    end

    ---@type evolved.chunk
    local root_chunk = {
        __parent = nil,
        __children = {},
        __fragment = fragment,
        __entities = {},
        __fragments = { [fragment] = true },
        __components = { [fragment] = {} },
        __with_fragment_cache = {},
        __without_fragment_cache = {},
    }

    do
        __root_chunks[fragment] = root_chunk
    end

    do
        local major_chunks = __major_chunks[fragment] or {}
        major_chunks[#major_chunks + 1] = root_chunk
        __major_chunks[fragment] = major_chunks
    end

    __structural_changes = __structural_changes + 1
    return root_chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __chunk_with_fragment(chunk, fragment)
    if chunk == nil then
        return __root_chunk(fragment)
    end

    if chunk.__fragments[fragment] then
        return chunk
    end

    do
        local cached_chunk = chunk.__with_fragment_cache[fragment]
        if cached_chunk then return cached_chunk end
    end

    if fragment == chunk.__fragment then
        return chunk
    end

    if fragment < chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_with_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__with_fragment_cache[fragment] = sibling_chunk
        sibling_chunk.__without_fragment_cache[fragment] = chunk

        return sibling_chunk
    end

    ---@type evolved.chunk
    local child_chunk = {
        __parent = chunk,
        __children = {},
        __fragment = fragment,
        __entities = {},
        __fragments = { [fragment] = true },
        __components = { [fragment] = {} },
        __with_fragment_cache = {},
        __without_fragment_cache = {},
    }

    for f, _ in pairs(chunk.__components) do
        child_chunk.__fragments[f] = true
        child_chunk.__components[f] = {}
    end

    do
        local chunk_children = chunk.__children
        chunk_children[#chunk_children + 1] = child_chunk
    end

    do
        chunk.__with_fragment_cache[fragment] = child_chunk
        child_chunk.__without_fragment_cache[fragment] = chunk
    end

    do
        local fragment_chunks = __major_chunks[fragment] or {}
        fragment_chunks[#fragment_chunks + 1] = child_chunk
        __major_chunks[fragment] = fragment_chunks
    end

    __structural_changes = __structural_changes + 1
    return child_chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment(chunk, fragment)
    if chunk == nil then
        return nil
    end

    if not chunk.__fragments[fragment] then
        return chunk
    end

    do
        local cached_chunk = chunk.__without_fragment_cache[fragment]
        if cached_chunk then return cached_chunk end
    end

    if fragment == chunk.__fragment then
        return chunk.__parent
    end

    if fragment < chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_without_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__without_fragment_cache[fragment] = sibling_chunk
        sibling_chunk.__with_fragment_cache[fragment] = chunk

        return sibling_chunk
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param ... evolved.fragment fragments
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragments(chunk, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return chunk
    end

    for i = 1, fragment_count do
        chunk = __chunk_without_fragment(chunk, select(i, ...))
    end

    return chunk
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
---@param place integer
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
local function __chunk_get_components(chunk, place, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return
    end

    local components = chunk.__components

    if fragment_count == 1 then
        local f1 = ...
        local cs1 = components[f1]
        return cs1 and cs1[place]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local cs1, cs2 = components[f1], components[f2]
        return cs1 and cs1[place], cs2 and cs2[place]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[place], cs2 and cs2[place], cs3 and cs3[place]
    end

    do
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[place], cs2 and cs2[place], cs3 and cs3[place],
            __chunk_get_components(chunk, place, select(4, ...))
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

    local index = __unpack_id(entity)
    local chunk = __entity_chunks[index]

    if not chunk then
        return
    end

    local place = __entity_places[index]
    return __chunk_get_components(chunk, place, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function evolved.has(entity, fragment)
    if not __alive_id(entity) then
        return false
    end

    local index = __unpack_id(entity)
    local chunk = __entity_chunks[index]

    if not chunk then
        return false
    end

    return __chunk_has_fragment(chunk, fragment)
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_all(entity, ...)
    if not __alive_id(entity) then
        return false
    end

    local index = __unpack_id(entity)
    local chunk = __entity_chunks[index]

    if not chunk then
        return select('#', ...) == 0
    end

    return __chunk_has_all_fragments(chunk, ...)
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_any(entity, ...)
    if not __alive_id(entity) then
        return false
    end

    local index = __unpack_id(entity)
    local chunk = __entity_chunks[index]

    if not chunk then
        return false
    end

    return __chunk_has_any_fragments(chunk, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
function evolved.set(entity, fragment, component)
    if not __alive_id(entity) then
        return false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)
    local new_place = #new_chunk.__entities + 1

    if old_chunk == new_chunk then
        local old_chunk_fragment_components = old_chunk.__components[fragment]
        old_chunk_fragment_components[old_place] = component
        return true
    end

    local new_chunk_entities = new_chunk.__entities
    local new_chunk_components = new_chunk.__components

    new_chunk_entities[new_place] = entity
    new_chunk_components[fragment][new_place] = component

    if old_chunk then
        local old_chunk_size = #old_chunk.__entities
        local old_chunk_entities = old_chunk.__entities
        local old_chunk_components = old_chunk.__components

        for old_f, old_cs in pairs(old_chunk_components) do
            local new_cs = new_chunk_components[old_f]
            new_cs[new_place] = old_cs[old_place]
        end

        if old_place == old_chunk_size then
            old_chunk_entities[old_place] = nil

            for _, cs in pairs(old_chunk_components) do
                cs[old_place] = nil
            end
        else
            local last_chunk_entity = old_chunk_entities[old_chunk_size]
            __entity_places[__unpack_id(last_chunk_entity)] = old_place

            old_chunk_entities[old_place] = last_chunk_entity
            old_chunk_entities[old_chunk_size] = nil

            for _, cs in pairs(old_chunk_components) do
                local old_chunk_component = cs[old_chunk_size]
                cs[old_place] = old_chunk_component
                cs[old_chunk_size] = nil
            end
        end
    end

    __entity_chunks[index] = new_chunk
    __entity_places[index] = new_place

    __structural_changes = __structural_changes + 1

    return true
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@return boolean is_assigned
function evolved.assign(entity, fragment, component)
    if not __alive_id(entity) then
        return false
    end

    local index = __unpack_id(entity)

    local chunk = __entity_chunks[index]
    local place = __entity_places[index]

    if not chunk then
        return false
    end

    local chunk_fragment_components = chunk.__components[fragment]

    if not chunk_fragment_components then
        return false
    end

    chunk_fragment_components[place] = component

    return true
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@return boolean is_inserted
function evolved.insert(entity, fragment, component)
    if not __alive_id(entity) then
        return false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)
    local new_place = #new_chunk.__entities + 1

    if old_chunk == new_chunk then
        return false
    end

    local new_chunk_entities = new_chunk.__entities
    local new_chunk_components = new_chunk.__components

    new_chunk_entities[new_place] = entity
    new_chunk_components[fragment][new_place] = component

    if old_chunk then
        local old_chunk_size = #old_chunk.__entities
        local old_chunk_entities = old_chunk.__entities
        local old_chunk_components = old_chunk.__components

        for old_f, old_cs in pairs(old_chunk_components) do
            local new_cs = new_chunk_components[old_f]
            new_cs[new_place] = old_cs[old_place]
        end

        if old_place == old_chunk_size then
            old_chunk_entities[old_place] = nil

            for _, cs in pairs(old_chunk_components) do
                cs[old_place] = nil
            end
        else
            local last_chunk_entity = old_chunk_entities[old_chunk_size]
            __entity_places[__unpack_id(last_chunk_entity)] = old_place

            old_chunk_entities[old_place] = last_chunk_entity
            old_chunk_entities[old_chunk_size] = nil

            for _, cs in pairs(old_chunk_components) do
                local old_chunk_component = cs[old_chunk_size]
                cs[old_place] = old_chunk_component
                cs[old_chunk_size] = nil
            end
        end
    end

    __entity_chunks[index] = new_chunk
    __entity_places[index] = new_place

    __structural_changes = __structural_changes + 1

    return true
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
function evolved.remove(entity, ...)
    if not __alive_id(entity) then
        return
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_without_fragments(old_chunk, ...)
    local new_place = new_chunk and #new_chunk.__entities + 1

    if old_chunk == new_chunk then
        return
    end

    local old_chunk_size = #old_chunk.__entities
    local old_chunk_entities = old_chunk.__entities
    local old_chunk_components = old_chunk.__components

    if new_chunk and assert(new_place) then
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components

        new_chunk_entities[new_place] = entity

        for new_f, new_cs in pairs(new_chunk_components) do
            local old_cs = old_chunk_components[new_f]
            new_cs[new_place] = old_cs[old_place]
        end
    end

    if old_place == old_chunk_size then
        old_chunk_entities[old_place] = nil

        for _, cs in pairs(old_chunk_components) do
            cs[old_place] = nil
        end
    else
        local last_chunk_entity = old_chunk_entities[old_chunk_size]
        __entity_places[__unpack_id(last_chunk_entity)] = old_place

        old_chunk_entities[old_place] = last_chunk_entity
        old_chunk_entities[old_chunk_size] = nil

        for _, cs in pairs(old_chunk_components) do
            local old_chunk_component = cs[old_chunk_size]
            cs[old_place] = old_chunk_component
            cs[old_chunk_size] = nil
        end
    end

    __entity_chunks[index] = new_chunk
    __entity_places[index] = new_place

    __structural_changes = __structural_changes + 1
end

---@param entity evolved.entity
function evolved.clear(entity)
    if not __alive_id(entity) then
        return
    end

    local index = __unpack_id(entity)

    local chunk = __entity_chunks[index]
    local place = __entity_places[index]

    if not chunk then
        return
    end

    local chunk_size = #chunk.__entities
    local chunk_entities = chunk.__entities
    local chunk_components = chunk.__components

    if place == chunk_size then
        chunk_entities[place] = nil

        for _, cs in pairs(chunk_components) do
            cs[place] = nil
        end
    else
        local last_chunk_entity = chunk_entities[chunk_size]
        __entity_places[__unpack_id(last_chunk_entity)] = place

        chunk_entities[place] = last_chunk_entity
        chunk_entities[chunk_size] = nil

        for _, cs in pairs(chunk_components) do
            local last_chunk_component = cs[chunk_size]
            cs[place] = last_chunk_component
            cs[chunk_size] = nil
        end
    end

    __entity_chunks[index] = nil
    __entity_places[index] = nil

    __structural_changes = __structural_changes + 1
end

return evolved
