---@class evolved
local evolved = {}

---@alias evolved.id integer
---@alias evolved.query evolved.id
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
---@field __with_fragment_edges table<evolved.fragment, evolved.chunk>
---@field __without_fragment_edges table<evolved.fragment, evolved.chunk>

---@alias evolved.execution_stack evolved.chunk[]
---@alias evolved.execution_state [integer, table<evolved.entity, boolean>, evolved.execution_stack]
---@alias evolved.execution_iterator fun(state: evolved.execution_state?): evolved.chunk?

---
---
---
---
---

local __freelist_ids = {} ---@type evolved.id[]
local __available_idx = 0 ---@type integer

local __defer_depth = 0 ---@type integer
local __defer_bytecode = {} ---@type any[]
local __defer_bytecode_length = 0 ---@type integer

local __root_chunks = {} ---@type table<evolved.fragment, evolved.chunk>
local __major_chunks = {} ---@type table<evolved.fragment, evolved.chunk[]>

local __entity_chunks = {} ---@type table<integer, evolved.chunk>
local __entity_places = {} ---@type table<integer, integer>

local __execution_stacks = {} ---@type evolved.execution_stack[]
local __execution_states = {} ---@type evolved.execution_state[]

local __structural_changes = 0 ---@type integer

---
---
---
---
---

local __lua_pack = table.pack or function(...)
    return { n = select('#', ...), ... }
end

local __lua_unpack = table.unpack or function(list, i, j)
    return unpack(list, i, j)
end

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

evolved.DEFAULT = __acquire_id()
evolved.CONSTRUCT = __acquire_id()

evolved.ON_SET = __acquire_id()
evolved.ON_ASSIGN = __acquire_id()
evolved.ON_INSERT = __acquire_id()
evolved.ON_REMOVE = __acquire_id()

evolved.INCLUDE_LIST = __acquire_id()
evolved.EXCLUDE_LIST = __acquire_id()

---
---
---
---
---

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@param ... any construct additional parameters
---@return evolved.component
local function __construct(entity, fragment, component, ...)
    local default, construct = evolved.get(fragment, evolved.DEFAULT, evolved.CONSTRUCT)
    if construct ~= nil then component = construct(entity, component, ...) end
    if component == nil then component = default end
    return component == nil and true or component
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param new_component evolved.component
---@param old_component evolved.component
local function __on_assign(entity, fragment, new_component, old_component)
    local on_set, on_assign = evolved.get(fragment, evolved.ON_SET, evolved.ON_ASSIGN)
    if on_set then on_set(entity, fragment, new_component, old_component) end
    if on_assign then on_assign(entity, fragment, new_component, old_component) end
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param new_component evolved.component
local function __on_insert(entity, fragment, new_component)
    local on_set, on_insert = evolved.get(fragment, evolved.ON_SET, evolved.ON_INSERT)
    if on_set then on_set(entity, fragment, new_component) end
    if on_insert then on_insert(entity, fragment, new_component) end
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param old_component evolved.component
local function __on_remove(entity, fragment, old_component)
    local on_remove = evolved.get(fragment, evolved.ON_REMOVE)
    if on_remove then on_remove(entity, fragment, old_component) end
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
        __with_fragment_edges = {},
        __without_fragment_edges = {},
    }

    do
        __root_chunks[fragment] = root_chunk
    end

    do
        local fragment_chunks = __major_chunks[fragment]

        if not fragment_chunks then
            fragment_chunks = {}
            __major_chunks[fragment] = fragment_chunks
        end

        fragment_chunks[#fragment_chunks + 1] = root_chunk
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
        local with_fragment_chunk = chunk.__with_fragment_edges[fragment]
        if with_fragment_chunk then return with_fragment_chunk end
    end

    if fragment == chunk.__fragment then
        return chunk
    end

    if fragment < chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_with_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__with_fragment_edges[fragment] = sibling_chunk
        sibling_chunk.__without_fragment_edges[fragment] = chunk

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
        __with_fragment_edges = {},
        __without_fragment_edges = {},
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
        chunk.__with_fragment_edges[fragment] = child_chunk
        child_chunk.__without_fragment_edges[fragment] = chunk
    end

    do
        local fragment_chunks = __major_chunks[fragment]

        if not fragment_chunks then
            fragment_chunks = {}
            __major_chunks[fragment] = fragment_chunks
        end

        fragment_chunks[#fragment_chunks + 1] = child_chunk
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
        local without_fragment_edge = chunk.__without_fragment_edges[fragment]
        if without_fragment_edge then return without_fragment_edge end
    end

    if fragment == chunk.__fragment then
        return chunk.__parent
    end

    if fragment < chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_without_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__without_fragment_edges[fragment] = sibling_chunk
        sibling_chunk.__with_fragment_edges[fragment] = chunk

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

---@param entity evolved.entity
local function __detach_entity(entity)
    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]

    if not old_chunk then
        return
    end

    local old_chunk_entities = old_chunk.__entities
    local old_chunk_components = old_chunk.__components

    local old_place = __entity_places[index]
    local old_chunk_size = #old_chunk_entities

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
            local last_chunk_component = cs[old_chunk_size]
            cs[old_place] = last_chunk_component
            cs[old_chunk_size] = nil
        end
    end

    __entity_chunks[index] = nil
    __entity_places[index] = nil

    __structural_changes = __structural_changes + 1
end

---
---
---
---
---

---@enum evolved.defer_op
local __defer_op = {
    set = 1,
    assign = 2,
    insert = 3,
    remove = 4,
    clear = 5,
    destroy = 6,
}

---@type table<evolved.defer_op, fun(bytes: any[], index: integer): integer>
local __defer_ops = {
    [__defer_op.set] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local component = bytes[index + 2]
        evolved.set(entity, fragment, component)
        return 3
    end,
    [__defer_op.assign] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local component = bytes[index + 2]
        evolved.assign(entity, fragment, component)
        return 3
    end,
    [__defer_op.insert] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local component = bytes[index + 2]
        evolved.insert(entity, fragment, component)
        return 3
    end,
    [__defer_op.remove] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment_count = bytes[index + 1]
        evolved.remove(entity, __lua_unpack(bytes, index + 2, index + 1 + fragment_count))
        return 2 + fragment_count
    end,
    [__defer_op.clear] = function(bytes, index)
        local entity = bytes[index + 0]
        evolved.clear(entity)
        return 1
    end,
    [__defer_op.destroy] = function(bytes, index)
        local entity = bytes[index + 0]
        evolved.destroy(entity)
        return 1
    end,
}

---@return boolean started
local function __defer()
    assert(__defer_depth >= 0, 'unbalanced defer/commit')
    __defer_depth = __defer_depth + 1
    return __defer_depth == 1
end

---@return boolean committed
local function __defer_commit()
    assert(__defer_depth > 0, 'unbalanced defer/commit')
    __defer_depth = __defer_depth - 1

    if __defer_depth > 0 then
        return false
    end

    local bytecode = __defer_bytecode
    local bytecode_length = __defer_bytecode_length

    __defer_bytecode = {}
    __defer_bytecode_length = 0

    local bytecode_index = 1
    while bytecode_index <= bytecode_length do
        local op = __defer_ops[bytecode[bytecode_index]]
        bytecode_index = bytecode_index + op(bytecode, bytecode_index + 1) + 1
    end

    return true
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@param ... any construct additional parameters
local function __defer_set(entity, fragment, component, ...)
    component = __construct(entity, fragment, component, ...)

    local bytes = __defer_bytecode
    local length = __defer_bytecode_length

    bytes[length + 1] = __defer_op.set
    bytes[length + 2] = entity
    bytes[length + 3] = fragment
    bytes[length + 4] = component

    __defer_bytecode_length = length + 4
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@param ... any construct additional parameters
local function __defer_assign(entity, fragment, component, ...)
    component = __construct(entity, fragment, component, ...)

    local bytes = __defer_bytecode
    local length = __defer_bytecode_length

    bytes[length + 1] = __defer_op.assign
    bytes[length + 2] = entity
    bytes[length + 3] = fragment
    bytes[length + 4] = component

    __defer_bytecode_length = length + 4
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@param ... any construct additional parameters
local function __defer_insert(entity, fragment, component, ...)
    component = __construct(entity, fragment, component, ...)

    local bytes = __defer_bytecode
    local length = __defer_bytecode_length

    bytes[length + 1] = __defer_op.insert
    bytes[length + 2] = entity
    bytes[length + 3] = fragment
    bytes[length + 4] = component

    __defer_bytecode_length = length + 4
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
local function __defer_remove(entity, ...)
    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    local bytes = __defer_bytecode
    local length = __defer_bytecode_length

    bytes[length + 1] = __defer_op.remove
    bytes[length + 2] = entity
    bytes[length + 3] = fragment_count

    for i = 1, fragment_count do
        bytes[length + 3 + i] = select(i, ...)
    end

    __defer_bytecode_length = length + 3 + fragment_count
end

---@param entity evolved.entity
local function __defer_clear(entity)
    local bytes = __defer_bytecode
    local length = __defer_bytecode_length

    bytes[length + 1] = __defer_op.clear
    bytes[length + 2] = entity

    __defer_bytecode_length = length + 2
end

---@param entity evolved.entity
local function __defer_destroy(entity)
    local bytes = __defer_bytecode
    local length = __defer_bytecode_length

    bytes[length + 1] = __defer_op.destroy
    bytes[length + 2] = entity

    __defer_bytecode_length = length + 2
end

---
---
---
---
---

---@param count? integer
---@return evolved.id ...
---@nodiscard
function evolved.id(count)
    count = count or 1

    if count == 0 then
        return
    end

    if count == 1 then
        return __acquire_id()
    end

    if count == 2 then
        return __acquire_id(), __acquire_id()
    end

    if count == 3 then
        return __acquire_id(), __acquire_id(), __acquire_id()
    end

    do
        return __acquire_id(), __acquire_id(), __acquire_id(),
            evolved.id(count - 3)
    end
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

---@return boolean started
function evolved.defer()
    return __defer()
end

---@return boolean committed
function evolved.commit()
    return __defer_commit()
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
---@param ... any construct additional parameters
---@return boolean is_set
---@return boolean is_deferred
function evolved.set(entity, fragment, component, ...)
    component = __construct(entity, fragment, component, ...)

    if __defer_depth > 0 then
        __defer_set(entity, fragment, component)
        return false, true
    end

    if not __alive_id(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)
    local new_place = #new_chunk.__entities + 1

    if old_chunk == new_chunk then
        local old_chunk_fragment_components = old_chunk.__components[fragment]
        local old_component = old_chunk_fragment_components[old_place]
        old_chunk_fragment_components[old_place] = component
        __on_assign(entity, fragment, component, old_component)
        return true, false
    end

    local new_chunk_entities = new_chunk.__entities
    local new_chunk_components = new_chunk.__components

    new_chunk_entities[new_place] = entity
    new_chunk_components[fragment][new_place] = component

    if old_chunk then
        local old_chunk_components = old_chunk.__components

        for old_f, old_cs in pairs(old_chunk_components) do
            local new_cs = new_chunk_components[old_f]
            new_cs[new_place] = old_cs[old_place]
        end

        __detach_entity(entity)
    end

    __entity_chunks[index] = new_chunk
    __entity_places[index] = new_place

    __structural_changes = __structural_changes + 1

    __on_insert(entity, fragment, component)
    return true, false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@param ... any construct additional parameters
---@return boolean is_assigned
---@return boolean is_deferred
function evolved.assign(entity, fragment, component, ...)
    component = __construct(entity, fragment, component, ...)

    if __defer_depth > 0 then
        __defer_assign(entity, fragment, component)
        return false, true
    end

    if not __alive_id(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    if not old_chunk or not old_chunk.__fragments[fragment] then
        return false, false
    end

    local old_chunk_fragment_components = old_chunk.__components[fragment]
    local old_component = old_chunk_fragment_components[old_place]
    old_chunk_fragment_components[old_place] = component
    __on_assign(entity, fragment, component, old_component)
    return true, false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
---@param ... any construct additional parameters
---@return boolean is_inserted
---@return boolean is_deferred
function evolved.insert(entity, fragment, component, ...)
    component = __construct(entity, fragment, component, ...)

    if __defer_depth > 0 then
        __defer_insert(entity, fragment, component)
        return false, true
    end

    if not __alive_id(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)
    local new_place = #new_chunk.__entities + 1

    if old_chunk == new_chunk then
        return false, false
    end

    local new_chunk_entities = new_chunk.__entities
    local new_chunk_components = new_chunk.__components

    new_chunk_entities[new_place] = entity
    new_chunk_components[fragment][new_place] = component

    if old_chunk then
        local old_chunk_components = old_chunk.__components

        for old_f, old_cs in pairs(old_chunk_components) do
            local new_cs = new_chunk_components[old_f]
            new_cs[new_place] = old_cs[old_place]
        end

        __detach_entity(entity)
    end

    __entity_chunks[index] = new_chunk
    __entity_places[index] = new_place

    __structural_changes = __structural_changes + 1

    __on_insert(entity, fragment, component)
    return true, false
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean is_removed
---@return boolean is_deferred
function evolved.remove(entity, ...)
    if __defer_depth > 0 then
        __defer_remove(entity, ...)
        return false, true
    end

    if not __alive_id(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_without_fragments(old_chunk, ...)
    local new_place = new_chunk and #new_chunk.__entities + 1

    if old_chunk == new_chunk then
        return true, false
    end

    __defer()
    do
        local old_chunk_fragments = old_chunk.__fragments
        local old_chunk_components = old_chunk.__components

        for i = 1, select('#', ...) do
            local old_f = select(i, ...)
            if old_chunk_fragments[old_f] then
                local old_cs = old_chunk_components[old_f]
                __on_remove(entity, old_f, old_cs[old_place])
            end
        end

        if new_chunk and assert(new_place) then
            local new_chunk_entities = new_chunk.__entities
            local new_chunk_components = new_chunk.__components

            new_chunk_entities[new_place] = entity

            for new_f, new_cs in pairs(new_chunk_components) do
                local old_cs = old_chunk_components[new_f]
                new_cs[new_place] = old_cs[old_place]
            end
        end

        __detach_entity(entity)

        __entity_chunks[index] = new_chunk
        __entity_places[index] = new_place

        __structural_changes = __structural_changes + 1
    end
    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@return boolean is_cleared
---@return boolean is_deferred
function evolved.clear(entity)
    if __defer_depth > 0 then
        __defer_clear(entity)
        return false, true
    end

    if not __alive_id(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    if not old_chunk then
        return true, false
    end

    __defer()
    do
        local old_chunk_fragments = old_chunk.__fragments
        local old_chunk_components = old_chunk.__components

        for old_f, _ in pairs(old_chunk_fragments) do
            local old_cs = old_chunk_components[old_f]
            __on_remove(entity, old_f, old_cs[old_place])
        end

        __detach_entity(entity)
    end
    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
function evolved.alive(entity)
    return __alive_id(entity)
end

---@param entity evolved.entity
---@return boolean is_destroyed
---@return boolean is_deferred
function evolved.destroy(entity)
    if __defer_depth > 0 then
        __defer_destroy(entity)
        return false, true
    end

    if not __alive_id(entity) then
        return true, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    if not old_chunk then
        __release_id(entity)
        return true, false
    end

    __defer()
    do
        local old_chunk_fragments = old_chunk.__fragments
        local old_chunk_components = old_chunk.__components

        for old_f, _ in pairs(old_chunk_fragments) do
            local old_cs = old_chunk_components[old_f]
            __on_remove(entity, old_f, old_cs[old_place])
        end

        __detach_entity(entity)
        __release_id(entity)
    end
    __defer_commit()
    return true, false
end

---
---
---
---
---

local __INCLUDE_SET = __acquire_id()
local __EXCLUDE_SET = __acquire_id()

---@param in_list? evolved.fragment[]
assert(evolved.insert(evolved.INCLUDE_LIST, evolved.CONSTRUCT, function(_, in_list)
    if not in_list then
        return {}
    end

    local out_list = {}

    for i = 1, #in_list do
        out_list[i] = in_list[i]
    end

    table.sort(out_list)
    return out_list
end))

---@param query evolved.query
---@param include_list evolved.entity[]
assert(evolved.insert(evolved.INCLUDE_LIST, evolved.ON_SET, function(query, _, include_list)
    ---@type table<evolved.entity, boolean>
    local include_set = {}

    for i = 1, #include_list do
        include_set[include_list[i]] = true
    end

    evolved.set(query, __INCLUDE_SET, include_set)
    evolved.insert(query, evolved.EXCLUDE_LIST)
end))

---@param in_list? evolved.fragment[]
assert(evolved.insert(evolved.EXCLUDE_LIST, evolved.CONSTRUCT, function(_, in_list)
    if not in_list then
        return {}
    end

    local out_list = {}

    for i = 1, #in_list do
        out_list[i] = in_list[i]
    end

    table.sort(out_list)
    return out_list
end))

---@param query evolved.query
---@param exclude_list evolved.entity[]
assert(evolved.insert(evolved.EXCLUDE_LIST, evolved.ON_SET, function(query, _, exclude_list)
    ---@type table<evolved.entity, boolean>
    local exclude_set = {}

    for i = 1, #exclude_list do
        exclude_set[exclude_list[i]] = true
    end

    evolved.set(query, __EXCLUDE_SET, exclude_set)
    evolved.insert(query, evolved.INCLUDE_LIST)
end))

---@return evolved.execution_stack
---@nodiscard
local function __acquire_execution_stack()
    local execution_stacks = __execution_stacks

    if #execution_stacks == 0 then
        return {}
    end

    local stack = execution_stacks[#execution_stacks]
    execution_stacks[#execution_stacks] = nil

    return stack
end

---@param stack evolved.execution_stack
local function __release_execution_stack(stack)
    for i = #stack, 1, -1 do stack[i] = nil end
    __execution_stacks[#__execution_stacks + 1] = stack
end

---@param exclude_set table<evolved.fragment, boolean>
---@return evolved.execution_state
---@return evolved.execution_stack
---@nodiscard
local function __acquire_execution_state(exclude_set)
    local execution_states = __execution_states

    if #execution_states == 0 then
        local stack = __acquire_execution_stack()
        return { __structural_changes, exclude_set, stack }, stack
    end

    local state = execution_states[#execution_states]
    execution_states[#execution_states] = nil

    local stack = __acquire_execution_stack()
    state[1], state[2], state[3] = __structural_changes, exclude_set, stack
    return state, stack
end

---@param state evolved.execution_state
local function __release_execution_state(state)
    __release_execution_stack(state[3]); state[3] = nil
    __execution_states[#__execution_states + 1] = state
end

---@type evolved.execution_iterator
local function __execution_iterator(execution_state)
    if not execution_state then return end

    local structural_changes, exclude_set, execution_stack =
        execution_state[1], execution_state[2], execution_state[3]

    if structural_changes ~= __structural_changes then
        error('structural changes are prohibited during execution', 2)
    end

    while #execution_stack > 0 do
        local matched_chunk = execution_stack[#execution_stack]
        execution_stack[#execution_stack] = nil

        for _, matched_chunk_child in ipairs(matched_chunk.__children) do
            if not exclude_set[matched_chunk_child.__fragment] then
                execution_stack[#execution_stack + 1] = matched_chunk_child
            end
        end

        if #matched_chunk.__entities > 0 then
            return matched_chunk
        end
    end

    __release_execution_state(execution_state)
end

---
---
---
---
---

---@param query evolved.query
---@return evolved.execution_iterator
---@return evolved.execution_state?
---@nodiscard
function evolved.execute(query)
    local include_list =
        evolved.get(query, evolved.INCLUDE_LIST)

    if not include_list or #include_list == 0 then
        return __execution_iterator, nil
    end

    local exclude_set, exclude_list =
        evolved.get(query, __EXCLUDE_SET, evolved.EXCLUDE_LIST)

    local major_fragment = include_list[#include_list]
    local major_fragment_chunks = __major_chunks[major_fragment]

    if not major_fragment_chunks then
        return __execution_iterator, nil
    end

    local execution_state, execution_stack =
        __acquire_execution_state(exclude_set)

    for _, major_fragment_chunk in ipairs(major_fragment_chunks) do
        if __chunk_has_all_fragment_list(major_fragment_chunk, include_list) then
            if not __chunk_has_any_fragment_list(major_fragment_chunk, exclude_list) then
                execution_stack[#execution_stack + 1] = major_fragment_chunk
            end
        end
    end

    return __execution_iterator, execution_state
end

---
---
---
---
---

return evolved
