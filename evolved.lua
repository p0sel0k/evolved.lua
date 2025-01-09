local evolved = {
    __HOMEPAGE = 'https://github.com/BlackMATov/evolved.lua',
    __DESCRIPTION = 'Evolved ECS (Entity-Component-System) for Lua',
    __VERSION = '0.0.1',
    __LICENSE = [[
        MIT License

        Copyright (C) 2024-2025, by Matvey Cherevko (blackmatov@gmail.com)

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

---@alias evolved.id integer

---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.query evolved.id

---@alias evolved.component any
---@alias evolved.component_storage evolved.component[]

---@class (exact) evolved.chunk
---@field package __parent? evolved.chunk
---@field package __children evolved.chunk[]
---@field package __entities evolved.entity[]
---@field package __fragment evolved.fragment
---@field package __fragment_set table<evolved.fragment, boolean>
---@field package __fragment_list evolved.fragment[]
---@field package __component_indices table<evolved.fragment, integer>
---@field package __component_storages evolved.component_storage[]
---@field package __component_fragments evolved.fragment[]
---@field package __with_fragment_edges table<evolved.fragment, evolved.chunk>
---@field package __without_fragment_edges table<evolved.fragment, evolved.chunk>
---@field package __has_defaults_or_constructs boolean
---@field package __has_set_or_assign_hooks boolean
---@field package __has_set_or_insert_hooks boolean
---@field package __has_remove_hooks boolean

---@class (exact) evolved.each_state
---@field package [1] integer structural_changes
---@field package [2] evolved.chunk entity_chunk
---@field package [3] integer entity_place
---@field package [4] integer fragment_index

---@class (exact) evolved.execute_state
---@field package [1] integer structural_changes
---@field package [2] evolved.chunk[] chunk_stack
---@field package [3] table<evolved.fragment, boolean> exclude_set

---@alias evolved.each_iterator fun(state: evolved.each_state?): evolved.fragment?, evolved.component?
---@alias evolved.execute_iterator fun(state: evolved.execute_state?): evolved.chunk?, evolved.entity[]?

---
---
---
---
---

local __freelist_ids = {} ---@type evolved.id[]
local __available_idx = 0 ---@type integer

local __defer_depth = 0 ---@type integer
local __defer_length = 0 ---@type integer
local __defer_bytecode = {} ---@type any[]

local __root_chunks = {} ---@type table<evolved.fragment, evolved.chunk>
local __major_chunks = {} ---@type table<evolved.fragment, evolved.chunk[]>

local __entity_chunks = {} ---@type table<integer, evolved.chunk>
local __entity_places = {} ---@type table<integer, integer>

local __structural_changes = 0 ---@type integer

---
---
---
---
---

local __table_move = (function()
    ---@param a1 table
    ---@param f integer
    ---@param e integer
    ---@param t integer
    ---@param a2? table
    ---@return table a2
    return table.move or function(a1, f, e, t, a2)
        -- REFERENCE:
        -- https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lib_table.c#L132

        if a2 == nil then
            a2 = a1
        end

        if e < f then
            return a2
        end

        local d = t - f

        if t > e or t <= f or a2 ~= a1 then
            for i = f, e do
                a2[i + d] = a1[i]
            end
        else
            for i = e, f, -1 do
                a2[i + d] = a1[i]
            end
        end

        return a2
    end
end)()

local __table_unpack = (function()
    return table.unpack or unpack
end)()

---@type fun(narray: integer, nhash: integer): table
local __table_new = (function()
    local table_new_loader = package.preload['table.new']
    ---@return table
    return table_new_loader and table_new_loader() or function()
        return {}
    end
end)()

---@type fun(tab: table)
local __table_clear = (function()
    local table_clear_loader = package.preload['table.clear']
    ---@param tab table
    return table_clear_loader and table_clear_loader() or function(tab)
        for i = 1, #tab do tab[i] = nil end
        for k in pairs(tab) do tab[k] = nil end
    end
end)()

---
---
---
---
---

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

---@alias evolved.table_pool_tag
---| `__TABLE_POOL_TAG__BYTECODE`
---| `__TABLE_POOL_TAG__CHUNK_LIST`
---| `__TABLE_POOL_TAG__EACH_STATE`
---| `__TABLE_POOL_TAG__EXECUTE_STATE`
---| `__TABLE_POOL_TAG__FRAGMENT_SET`
---| `__TABLE_POOL_TAG__FRAGMENT_LIST`
---| `__TABLE_POOL_TAG__COMPONENT_LIST`

local __TABLE_POOL_TAG__BYTECODE = 1
local __TABLE_POOL_TAG__CHUNK_LIST = 2
local __TABLE_POOL_TAG__EACH_STATE = 3
local __TABLE_POOL_TAG__EXECUTE_STATE = 4
local __TABLE_POOL_TAG__FRAGMENT_SET = 5
local __TABLE_POOL_TAG__FRAGMENT_LIST = 7
local __TABLE_POOL_TAG__COMPONENT_LIST = 8

---@type table<evolved.table_pool_tag, table[]>
local __tagged_table_pools = __table_new(6, 0)

---@param tag evolved.table_pool_tag
---@param narray integer
---@param nhash integer
---@return table
---@nodiscard
local function __acquire_table(tag, narray, nhash)
    local table_pool = __tagged_table_pools[tag]

    if not table_pool then
        table_pool = __table_new(16, 0)
        __tagged_table_pools[tag] = table_pool
    end

    local table_pool_size = #table_pool

    if table_pool_size == 0 then
        return __table_new(narray, nhash)
    end

    local table = table_pool[table_pool_size]
    table_pool[table_pool_size] = nil

    return table
end

---@param tag evolved.table_pool_tag
---@param tab table
local function __release_table(tag, tab)
    local table_pool = __tagged_table_pools[tag]

    if not table_pool then
        table_pool = __table_new(16, 0)
        __tagged_table_pools[tag] = table_pool
    end

    setmetatable(tab, nil)
    __table_clear(tab)

    table_pool[#table_pool + 1] = tab
end

---
---
---
---
---

---@type evolved.each_iterator
local function __each_iterator(each_state)
    if not each_state then return end

    local structural_changes = each_state[1]
    local entity_chunk = each_state[2]
    local entity_place = each_state[3]
    local fragment_index = each_state[4]

    if structural_changes ~= __structural_changes then
        error('structural changes are prohibited during iteration', 2)
    end

    local entity_chunk_fragment_list = entity_chunk.__fragment_list
    local entity_chunk_component_indices = entity_chunk.__component_indices
    local entity_chunk_component_storages = entity_chunk.__component_storages

    if fragment_index <= #entity_chunk_fragment_list then
        each_state[4] = fragment_index + 1
        local fragment = entity_chunk_fragment_list[fragment_index]
        local component_index = entity_chunk_component_indices[fragment]
        local component_storage = entity_chunk_component_storages[component_index]
        return fragment, component_storage and component_storage[entity_place]
    end

    __release_table(__TABLE_POOL_TAG__EACH_STATE, each_state)
end

---@type evolved.execute_iterator
local function __execute_iterator(execute_state)
    if not execute_state then return end

    local structural_changes = execute_state[1]
    local chunk_stack = execute_state[2]
    local exclude_set = execute_state[3]

    if structural_changes ~= __structural_changes then
        error('structural changes are prohibited during iteration', 2)
    end

    while #chunk_stack > 0 do
        local chunk = chunk_stack[#chunk_stack]
        chunk_stack[#chunk_stack] = nil

        for _, chunk_child in ipairs(chunk.__children) do
            if not exclude_set[chunk_child.__fragment] then
                chunk_stack[#chunk_stack + 1] = chunk_child
            end
        end

        if #chunk.__entities > 0 then
            return chunk, chunk.__entities
        end
    end

    __release_table(__TABLE_POOL_TAG__CHUNK_LIST, chunk_stack)
    __release_table(__TABLE_POOL_TAG__EXECUTE_STATE, execute_state)
end

---
---
---
---
---

evolved.TAG = __acquire_id()
evolved.DEFAULT = __acquire_id()
evolved.CONSTRUCT = __acquire_id()

evolved.INCLUDES = __acquire_id()
evolved.EXCLUDES = __acquire_id()

evolved.ON_SET = __acquire_id()
evolved.ON_ASSIGN = __acquire_id()
evolved.ON_INSERT = __acquire_id()
evolved.ON_REMOVE = __acquire_id()

---
---
---
---
---

local __INCLUDE_SET = __acquire_id()
local __EXCLUDE_SET = __acquire_id()
local __SORTED_INCLUDE_LIST = __acquire_id()
local __SORTED_EXCLUDE_LIST = __acquire_id()

---@type table<evolved.fragment, boolean>
local __EMPTY_FRAGMENT_SET = setmetatable({}, {
    __newindex = function() error('attempt to modify empty fragment set') end
})

---@type evolved.fragment[]
local __EMPTY_FRAGMENT_LIST = setmetatable({}, {
    __newindex = function() error('attempt to modify empty fragment list') end
})

---@type evolved.component[]
local __EMPTY_COMPONENT_LIST = setmetatable({}, {
    __newindex = function() error('attempt to modify empty component list') end
})

---@type evolved.component[]
local __EMPTY_COMPONENT_STORAGE = setmetatable({}, {
    __newindex = function() error('attempt to modify empty component storage') end
})

---
---
---
---
---

---@param ... any component arguments
---@return evolved.component
local function __component_construct(fragment, ...)
    local default, construct = evolved.get(fragment, evolved.DEFAULT, evolved.CONSTRUCT)

    local component = ...

    if construct ~= nil then
        component = construct(...)
    end

    if component == nil then
        component = default
    end

    return component == nil and true or component
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param new_component evolved.component
---@param old_component evolved.component
local function __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
    local on_set, on_assign = evolved.get(fragment, evolved.ON_SET, evolved.ON_ASSIGN)
    if on_set then on_set(entity, fragment, new_component, old_component) end
    if on_assign then on_assign(entity, fragment, new_component, old_component) end
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param new_component evolved.component
local function __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
    local on_set, on_insert = evolved.get(fragment, evolved.ON_SET, evolved.ON_INSERT)
    if on_set then on_set(entity, fragment, new_component) end
    if on_insert then on_insert(entity, fragment, new_component) end
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param old_component evolved.component
local function __fragment_call_remove_hook(entity, fragment, old_component)
    local on_remove = evolved.get(fragment, evolved.ON_REMOVE)
    if on_remove then on_remove(entity, fragment, old_component) end
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __fragment_has_default_or_construct(fragment)
    return evolved.has_any(fragment, evolved.DEFAULT, evolved.CONSTRUCT)
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __fragment_has_set_or_assign_hooks(fragment)
    return evolved.has_any(fragment, evolved.ON_SET, evolved.ON_ASSIGN)
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __fragment_has_set_or_insert_hooks(fragment)
    return evolved.has_any(fragment, evolved.ON_SET, evolved.ON_INSERT)
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __fragment_has_remove_hook(fragment)
    return evolved.has(fragment, evolved.ON_REMOVE)
end

---
---
---
---
---

---@param root_fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __root_chunk(root_fragment)
    do
        local root_chunk = __root_chunks[root_fragment]
        if root_chunk then return root_chunk end
    end

    local has_defaults_or_constructs = __fragment_has_default_or_construct(root_fragment)
    local has_set_or_assign_hooks = __fragment_has_set_or_assign_hooks(root_fragment)
    local has_set_or_insert_hooks = __fragment_has_set_or_insert_hooks(root_fragment)
    local has_remove_hooks = __fragment_has_remove_hook(root_fragment)

    local root_fragment_set = {} ---@type table<evolved.fragment, boolean>
    local root_fragment_list = {} ---@type evolved.fragment[]

    local root_component_indices = {} ---@type table<evolved.fragment, integer>
    local root_component_storages = {} ---@type evolved.component_storage[]
    local root_component_fragments = {} ---@type evolved.fragment[]

    ---@type evolved.chunk
    local root_chunk = {
        __parent = nil,
        __children = {},
        __entities = {},
        __fragment = root_fragment,
        __fragment_set = root_fragment_set,
        __fragment_list = root_fragment_list,
        __component_indices = root_component_indices,
        __component_storages = root_component_storages,
        __component_fragments = root_component_fragments,
        __with_fragment_edges = {},
        __without_fragment_edges = {},
        __has_defaults_or_constructs = has_defaults_or_constructs,
        __has_set_or_assign_hooks = has_set_or_assign_hooks,
        __has_set_or_insert_hooks = has_set_or_insert_hooks,
        __has_remove_hooks = has_remove_hooks,
    }

    do
        root_fragment_set[root_fragment] = true
        root_fragment_list[#root_fragment_list + 1] = root_fragment

        if not evolved.has(root_fragment, evolved.TAG) then
            local storage = {}
            local storage_index = #root_component_storages + 1
            root_component_indices[root_fragment] = storage_index
            root_component_storages[storage_index] = storage
            root_component_fragments[storage_index] = root_fragment
        end
    end

    do
        __root_chunks[root_fragment] = root_chunk
    end

    do
        local fragment_chunks = __major_chunks[root_fragment]

        if not fragment_chunks then
            fragment_chunks = {}
            __major_chunks[root_fragment] = fragment_chunks
        end

        fragment_chunks[#fragment_chunks + 1] = root_chunk
    end

    return root_chunk
end

---@param parent_chunk? evolved.chunk
---@param child_fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __chunk_with_fragment(parent_chunk, child_fragment)
    if not parent_chunk then
        return __root_chunk(child_fragment)
    end

    if parent_chunk.__fragment_set[child_fragment] then
        return parent_chunk
    end

    do
        local with_fragment_chunk = parent_chunk.__with_fragment_edges[child_fragment]
        if with_fragment_chunk then return with_fragment_chunk end
    end

    if child_fragment < parent_chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_with_fragment(parent_chunk.__parent, child_fragment),
            parent_chunk.__fragment)

        parent_chunk.__with_fragment_edges[child_fragment] = sibling_chunk
        sibling_chunk.__without_fragment_edges[child_fragment] = parent_chunk

        return sibling_chunk
    end

    local has_defaults_or_constructs = parent_chunk.__has_defaults_or_constructs
        or __fragment_has_default_or_construct(child_fragment)
    local has_set_or_assign_hooks = parent_chunk.__has_set_or_assign_hooks
        or __fragment_has_set_or_assign_hooks(child_fragment)
    local has_set_or_insert_hooks = parent_chunk.__has_set_or_insert_hooks
        or __fragment_has_set_or_insert_hooks(child_fragment)
    local has_remove_hooks = parent_chunk.__has_remove_hooks
        or __fragment_has_remove_hook(child_fragment)

    local child_fragment_set = {} ---@type table<evolved.fragment, boolean>
    local child_fragment_list = {} ---@type evolved.fragment[]

    local child_component_indices = {} ---@type table<evolved.fragment, integer>
    local child_component_storages = {} ---@type evolved.component_storage[]
    local child_component_fragments = {} ---@type evolved.fragment[]

    ---@type evolved.chunk
    local child_chunk = {
        __parent = parent_chunk,
        __children = {},
        __entities = {},
        __fragment = child_fragment,
        __fragment_set = child_fragment_set,
        __fragment_list = child_fragment_list,
        __component_indices = child_component_indices,
        __component_storages = child_component_storages,
        __component_fragments = child_component_fragments,
        __with_fragment_edges = {},
        __without_fragment_edges = {},
        __has_defaults_or_constructs = has_defaults_or_constructs,
        __has_set_or_assign_hooks = has_set_or_assign_hooks,
        __has_set_or_insert_hooks = has_set_or_insert_hooks,
        __has_remove_hooks = has_remove_hooks,
    }

    for _, parent_fragment in ipairs(parent_chunk.__fragment_list) do
        child_fragment_set[parent_fragment] = true
        child_fragment_list[#child_fragment_list + 1] = parent_fragment

        if not evolved.has(parent_fragment, evolved.TAG) then
            local storage = {}
            local storage_index = #child_component_storages + 1
            child_component_indices[parent_fragment] = storage_index
            child_component_storages[storage_index] = storage
            child_component_fragments[storage_index] = parent_fragment
        end
    end

    do
        child_fragment_set[child_fragment] = true
        child_fragment_list[#child_fragment_list + 1] = child_fragment

        if not evolved.has(child_fragment, evolved.TAG) then
            local storage = {}
            local storage_index = #child_component_storages + 1
            child_component_indices[child_fragment] = storage_index
            child_component_storages[storage_index] = storage
            child_component_fragments[storage_index] = child_fragment
        end
    end

    do
        local chunk_children = parent_chunk.__children
        chunk_children[#chunk_children + 1] = child_chunk
    end

    do
        parent_chunk.__with_fragment_edges[child_fragment] = child_chunk
        child_chunk.__without_fragment_edges[child_fragment] = parent_chunk
    end

    do
        local fragment_chunks = __major_chunks[child_fragment]

        if not fragment_chunks then
            fragment_chunks = {}
            __major_chunks[child_fragment] = fragment_chunks
        end

        fragment_chunks[#fragment_chunks + 1] = child_chunk
    end

    return child_chunk
end

---@param chunk? evolved.chunk
---@param fragment_list evolved.fragment[]
---@return evolved.chunk?
---@nodiscard
local function __chunk_with_fragment_list(chunk, fragment_list)
    local fragment_count = #fragment_list

    if fragment_count == 0 then
        return chunk
    end

    for i = 1, fragment_count do
        local fragment = fragment_list[i]
        chunk = __chunk_with_fragment(chunk, fragment)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment(chunk, fragment)
    if not chunk then
        return nil
    end

    if not chunk.__fragment_set[fragment] then
        return chunk
    end

    if fragment == chunk.__fragment then
        return chunk.__parent
    end

    do
        local without_fragment_edge = chunk.__without_fragment_edges[fragment]
        if without_fragment_edge then return without_fragment_edge end
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
        local fragment = select(i, ...)
        chunk = __chunk_without_fragment(chunk, fragment)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param fragment_list evolved.fragment[]
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment_list(chunk, fragment_list)
    local fragment_count = #fragment_list

    if fragment_count == 0 then
        return chunk
    end

    for i = 1, fragment_count do
        local fragment = fragment_list[i]
        chunk = __chunk_without_fragment(chunk, fragment)
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
    return chunk.__fragment_set[fragment]
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
local function __chunk_has_all_fragments(chunk, ...)
    local fragment_set = chunk.__fragment_set

    for i = 1, select('#', ...) do
        local fragment = select(i, ...)
        if not fragment_set[fragment] then
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
    local fragment_set = chunk.__fragment_set

    for i = 1, #fragment_list do
        local fragment = fragment_list[i]
        if not fragment_set[fragment] then
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
    local fragment_set = chunk.__fragment_set

    for i = 1, select('#', ...) do
        local fragment = select(i, ...)
        if fragment_set[fragment] then
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
    local fragment_set = chunk.__fragment_set

    for i = 1, #fragment_list do
        local fragment = fragment_list[i]
        if fragment_set[fragment] then
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

    local indices = chunk.__component_indices
    local storages = chunk.__component_storages

    if fragment_count == 1 then
        local f1 = ...
        local i1 = indices[f1]
        return
            i1 and storages[i1][place]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local i1, i2 = indices[f1], indices[f2]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local i1, i2, i3 = indices[f1], indices[f2], indices[f3]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place],
            i3 and storages[i3][place]
    end

    do
        local f1, f2, f3 = ...
        local i1, i2, i3 = indices[f1], indices[f2], indices[f3]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place],
            i3 and storages[i3][place],
            __chunk_get_components(chunk, place, select(4, ...))
    end
end

---
---
---
---
---

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer assigned_count
---@nodiscard
local function __chunk_assign(chunk, fragment, ...)
    if __defer_depth <= 0 then
        error('batched chunk operations should be deferred', 2)
    end

    if not chunk.__fragment_set[fragment] then
        return 0
    end

    local chunk_entities = chunk.__entities
    local chunk_size = #chunk_entities

    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    if chunk.__has_set_or_assign_hooks and __fragment_has_set_or_assign_hooks(fragment) then
        local component_index = chunk_component_indices[fragment]
        if component_index then
            local component_storage = chunk_component_storages[component_index]
            if chunk.__has_defaults_or_constructs and __fragment_has_default_or_construct(fragment) then
                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    local old_component = component_storage[place]
                    local new_component = __component_construct(fragment, ...)
                    component_storage[place] = new_component
                    __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                end
            else
                local new_component = ...

                if new_component == nil then
                    new_component = true
                end

                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    local old_component = component_storage[place]
                    component_storage[place] = new_component
                    __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                end
            end
        else
            for place = 1, chunk_size do
                local entity = chunk_entities[place]
                __fragment_call_set_and_assign_hooks(entity, fragment)
            end
        end
    else
        local component_index = chunk_component_indices[fragment]
        if component_index then
            local component_storage = chunk_component_storages[component_index]
            if chunk.__has_defaults_or_constructs and __fragment_has_default_or_construct(fragment) then
                for place = 1, chunk_size do
                    local new_component = __component_construct(fragment, ...)
                    component_storage[place] = new_component
                end
            else
                local new_component = ...

                if new_component == nil then
                    new_component = true
                end

                for place = 1, chunk_size do
                    component_storage[place] = new_component
                end
            end
        else
            -- nothing
        end
    end

    return chunk_size
end

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer inserted_count
---@nodiscard
local function __chunk_insert(chunk, fragment, ...)
    if __defer_depth <= 0 then
        error('batched chunk operations should be deferred', 2)
    end

    local old_chunk = chunk
    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if old_chunk == new_chunk then
        return 0
    end

    local old_entities = old_chunk.__entities
    local old_size = #old_entities

    local old_component_storages = old_chunk.__component_storages
    local old_component_fragments = old_chunk.__component_fragments

    local new_entities = new_chunk.__entities
    local new_size = #new_entities

    local new_component_indices = new_chunk.__component_indices
    local new_component_storages = new_chunk.__component_storages

    do
        __table_move(
            old_entities, 1, old_size,
            new_size + 1, new_entities)

        for i = 1, #old_component_fragments do
            local old_f = old_component_fragments[i]
            local old_cs = old_component_storages[i]
            local new_ci = new_component_indices[old_f]
            if new_ci then
                local new_cs = new_component_storages[new_ci]
                __table_move(old_cs, 1, old_size, new_size + 1, new_cs)
            end
        end
    end

    do
        if new_chunk.__has_set_or_insert_hooks and __fragment_has_set_or_insert_hooks(fragment) then
            local new_component_index = new_component_indices[fragment]
            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]
                if chunk.__has_defaults_or_constructs and __fragment_has_default_or_construct(fragment) then
                    for new_place = new_size + 1, new_size + old_size do
                        local entity = new_entities[new_place]
                        local new_component = __component_construct(fragment, ...)
                        new_component_storage[new_place] = new_component
                        __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                    end
                else
                    local new_component = ...

                    if new_component == nil then
                        new_component = true
                    end

                    for new_place = new_size + 1, new_size + old_size do
                        local entity = new_entities[new_place]
                        new_component_storage[new_place] = new_component
                        __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                    end
                end
            else
                for new_place = new_size + 1, new_size + old_size do
                    local entity = new_entities[new_place]
                    __fragment_call_set_and_insert_hooks(entity, fragment)
                end
            end
        else
            local new_component_index = new_component_indices[fragment]
            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]
                if chunk.__has_defaults_or_constructs and __fragment_has_default_or_construct(fragment) then
                    for new_place = new_size + 1, new_size + old_size do
                        local new_component = __component_construct(fragment, ...)
                        new_component_storage[new_place] = new_component
                    end
                else
                    local new_component = ...

                    if new_component == nil then
                        new_component = true
                    end

                    for new_place = new_size + 1, new_size + old_size do
                        new_component_storage[new_place] = new_component
                    end
                end
            else
                -- nothing
            end
        end
    end

    for new_place = new_size + 1, new_size + old_size do
        local entity = new_entities[new_place]
        local entity_index = entity % 0x100000
        __entity_chunks[entity_index] = new_chunk
        __entity_places[entity_index] = new_place
    end

    do
        old_chunk.__entities = {}

        for i = 1, #old_component_storages do
            old_component_storages[i] = {}
        end
    end

    __structural_changes = __structural_changes + old_size
    return old_size
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return integer removed_count
---@nodiscard
local function __chunk_remove(chunk, ...)
    if __defer_depth <= 0 then
        error('batched chunk operations should be deferred', 2)
    end

    local old_chunk = chunk
    local new_chunk = __chunk_without_fragments(chunk, ...)

    if old_chunk == new_chunk then
        return 0
    end

    local old_entities = old_chunk.__entities
    local old_size = #old_entities

    local old_component_indices = chunk.__component_indices
    local old_component_storages = chunk.__component_storages

    if old_chunk.__has_remove_hooks then
        local old_fragment_set = old_chunk.__fragment_set
        for i = 1, select('#', ...) do
            local fragment = select(i, ...)
            if old_fragment_set[fragment] and __fragment_has_remove_hook(fragment) then
                local old_component_index = old_component_indices[fragment]
                if old_component_index then
                    local old_component_storage = old_component_storages[old_component_index]
                    for old_place = 1, old_size do
                        local entity = old_entities[old_place]
                        local old_component = old_component_storage[old_place]
                        __fragment_call_remove_hook(entity, fragment, old_component)
                    end
                else
                    for old_place = 1, old_size do
                        local entity = old_entities[old_place]
                        __fragment_call_remove_hook(entity, fragment)
                    end
                end
            end
        end
    end

    if new_chunk then
        local new_entities = new_chunk.__entities
        local new_size = #new_entities

        local new_component_storages = new_chunk.__component_storages
        local new_component_fragments = new_chunk.__component_fragments

        __table_move(
            old_entities, 1, old_size,
            new_size + 1, new_entities)

        for i = 1, #new_component_fragments do
            local new_f = new_component_fragments[i]
            local new_cs = new_component_storages[i]
            local old_ci = old_component_indices[new_f]
            if old_ci then
                local old_cs = old_component_storages[old_ci]
                __table_move(old_cs, 1, old_size, new_size + 1, new_cs)
            end
        end

        for new_place = new_size + 1, new_size + old_size do
            local entity = new_entities[new_place]
            local entity_index = entity % 0x100000
            __entity_chunks[entity_index] = new_chunk
            __entity_places[entity_index] = new_place
        end
    else
        for old_place = 1, old_size do
            local entity = old_entities[old_place]
            local entity_index = entity % 0x100000
            __entity_chunks[entity_index] = nil
            __entity_places[entity_index] = nil
        end
    end

    do
        old_chunk.__entities = {}

        for i = 1, #old_component_storages do
            old_component_storages[i] = {}
        end
    end

    __structural_changes = __structural_changes + old_size
    return old_size
end

---@param chunk evolved.chunk
---@return integer cleared_count
---@nodiscard
local function __chunk_clear(chunk)
    if __defer_depth <= 0 then
        error('batched chunk operations should be deferred', 2)
    end

    local chunk_entities = chunk.__entities
    local chunk_size = #chunk_entities

    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    if chunk.__has_remove_hooks then
        for _, fragment in ipairs(chunk.__fragment_list) do
            if __fragment_has_remove_hook(fragment) then
                local component_index = chunk_component_indices[fragment]
                if component_index then
                    local component_storage = chunk_component_storages[component_index]
                    for place = 1, chunk_size do
                        local entity = chunk_entities[place]
                        local old_component = component_storage[place]
                        __fragment_call_remove_hook(entity, fragment, old_component)
                    end
                else
                    for place = 1, chunk_size do
                        local entity = chunk_entities[place]
                        __fragment_call_remove_hook(entity, fragment)
                    end
                end
            end
        end
    end

    for place = 1, chunk_size do
        local entity = chunk_entities[place]
        local entity_index = entity % 0x100000
        __entity_chunks[entity_index] = nil
        __entity_places[entity_index] = nil
    end

    do
        chunk.__entities = {}

        for i = 1, #chunk_component_storages do
            chunk_component_storages[i] = {}
        end
    end

    __structural_changes = __structural_changes + chunk_size
    return chunk_size
end

---@param chunk evolved.chunk
---@return integer destroyed_count
---@nodiscard
local function __chunk_destroy(chunk)
    if __defer_depth <= 0 then
        error('batched chunk operations should be deferred', 2)
    end

    local chunk_entities = chunk.__entities
    local chunk_size = #chunk_entities

    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    if chunk.__has_remove_hooks then
        for _, fragment in ipairs(chunk.__fragment_list) do
            if __fragment_has_remove_hook(fragment) then
                local component_index = chunk_component_indices[fragment]
                if component_index then
                    local component_storage = chunk_component_storages[component_index]
                    for place = 1, chunk_size do
                        local entity = chunk_entities[place]
                        local old_component = component_storage[place]
                        __fragment_call_remove_hook(entity, fragment, old_component)
                    end
                else
                    for place = 1, chunk_size do
                        local entity = chunk_entities[place]
                        __fragment_call_remove_hook(entity, fragment)
                    end
                end
            end
        end
    end

    for place = 1, chunk_size do
        local entity = chunk_entities[place]
        local entity_index = entity % 0x100000
        __entity_chunks[entity_index] = nil
        __entity_places[entity_index] = nil
        __release_id(entity)
    end

    do
        chunk.__entities = {}

        for i = 1, #chunk_component_storages do
            chunk_component_storages[i] = {}
        end
    end

    __structural_changes = __structural_changes + chunk_size
    return chunk_size
end

---
---
---
---
---

---@param entity evolved.entity
local function __detach_entity(entity)
    local entity_index = entity % 0x100000

    local old_chunk = __entity_chunks[entity_index]

    if not old_chunk then
        return
    end

    local old_entities = old_chunk.__entities
    local old_component_storages = old_chunk.__component_storages

    local old_place = __entity_places[entity_index]
    local old_size = #old_entities

    if old_place == old_size then
        old_entities[old_place] = nil

        for i = 1, #old_component_storages do
            local old_cs = old_component_storages[i]
            old_cs[old_place] = nil
        end
    else
        local last_entity = old_entities[old_size]
        local last_entity_index = last_entity % 0x100000
        __entity_places[last_entity_index] = old_place

        old_entities[old_place] = last_entity
        old_entities[old_size] = nil

        for i = 1, #old_component_storages do
            local old_cs = old_component_storages[i]
            local last_component = old_cs[old_size]
            old_cs[old_place] = last_component
            old_cs[old_size] = nil
        end
    end

    __entity_chunks[entity_index] = nil
    __entity_places[entity_index] = nil

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

    multi_set = 7,
    multi_assign = 8,
    multi_insert = 9,
    multi_remove = 10,

    batch_set = 11,
    batch_assign = 12,
    batch_insert = 13,
    batch_remove = 14,
    batch_clear = 15,
    batch_destroy = 16,
}

---@type table<evolved.defer_op, fun(bytes: any[], index: integer): integer>
local __defer_ops = {
    [__defer_op.set] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.set(entity, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.assign] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.assign(entity, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.insert] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.insert(entity, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.remove] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment_count = bytes[index + 1]
        evolved.remove(entity, __table_unpack(bytes, index + 2, index + 1 + fragment_count))
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
    [__defer_op.multi_set] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragments = bytes[index + 1]
        local components = bytes[index + 2]
        evolved.multi_set(entity, fragments, components)
        __release_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragments)
        __release_table(__TABLE_POOL_TAG__COMPONENT_LIST, components)
        return 3
    end,
    [__defer_op.multi_assign] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragments = bytes[index + 1]
        local components = bytes[index + 2]
        evolved.multi_assign(entity, fragments, components)
        __release_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragments)
        __release_table(__TABLE_POOL_TAG__COMPONENT_LIST, components)
        return 3
    end,
    [__defer_op.multi_insert] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragments = bytes[index + 1]
        local components = bytes[index + 2]
        evolved.multi_insert(entity, fragments, components)
        __release_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragments)
        __release_table(__TABLE_POOL_TAG__COMPONENT_LIST, components)
        return 3
    end,
    [__defer_op.multi_remove] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragments = bytes[index + 1]
        evolved.multi_remove(entity, fragments)
        __release_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragments)
        return 2
    end,
    [__defer_op.batch_set] = function(bytes, index)
        local query = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.batch_set(query, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.batch_assign] = function(bytes, index)
        local query = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.batch_assign(query, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.batch_insert] = function(bytes, index)
        local query = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.batch_insert(query, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.batch_remove] = function(bytes, index)
        local query = bytes[index + 0]
        local fragment_count = bytes[index + 1]
        evolved.batch_remove(query, __table_unpack(bytes, index + 2, index + 1 + fragment_count))
        return 2 + fragment_count
    end,
    [__defer_op.batch_clear] = function(bytes, index)
        local query = bytes[index + 0]
        evolved.batch_clear(query)
        return 1
    end,
    [__defer_op.batch_destroy] = function(bytes, index)
        local query = bytes[index + 0]
        evolved.batch_destroy(query)
        return 1
    end,
}

---@return boolean started
local function __defer()
    __defer_depth = __defer_depth + 1
    return __defer_depth == 1
end

---@return boolean committed
local function __defer_commit()
    if __defer_depth <= 0 then
        error('unbalanced defer/commit', 2)
    end

    __defer_depth = __defer_depth - 1

    if __defer_depth > 0 then
        return false
    end

    if __defer_length == 0 then
        return true
    end

    local length = __defer_length
    local bytecode = __defer_bytecode

    __defer_length = 0
    __defer_bytecode = __acquire_table(__TABLE_POOL_TAG__BYTECODE, length, 0)

    local bytecode_index = 1
    while bytecode_index <= length do
        local op = __defer_ops[bytecode[bytecode_index]]
        bytecode_index = bytecode_index + op(bytecode, bytecode_index + 1) + 1
    end

    __release_table(__TABLE_POOL_TAG__BYTECODE, bytecode)
    return true
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_set(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.set
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_assign(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.assign
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_insert(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.insert
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
local function __defer_remove(entity, ...)
    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.remove
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_count

    for i = 1, fragment_count do
        bytecode[length + 3 + i] = select(i, ...)
    end

    __defer_length = length + 3 + fragment_count
end

---@param entity evolved.entity
local function __defer_clear(entity)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.clear
    bytecode[length + 2] = entity

    __defer_length = length + 2
end

---@param entity evolved.entity
local function __defer_destroy(entity)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.destroy
    bytecode[length + 2] = entity

    __defer_length = length + 2
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components any[]
local function __defer_multi_set(entity, fragments, components)
    local fragment_count = #fragments
    local fragment_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragment_count, 0)
    __table_move(fragments, 1, fragment_count, 1, fragment_list)

    local component_count = #components
    local component_list = __acquire_table(__TABLE_POOL_TAG__COMPONENT_LIST, component_count, 0)
    __table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_set
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components any[]
local function __defer_multi_assign(entity, fragments, components)
    local fragment_count = #fragments
    local fragment_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragment_count, 0)
    __table_move(fragments, 1, fragment_count, 1, fragment_list)

    local component_count = #components
    local component_list = __acquire_table(__TABLE_POOL_TAG__COMPONENT_LIST, component_count, 0)
    __table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_assign
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components any[]
local function __defer_multi_insert(entity, fragments, components)
    local fragment_count = #fragments
    local fragment_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragment_count, 0)
    __table_move(fragments, 1, fragment_count, 1, fragment_list)

    local component_count = #components
    local component_list = __acquire_table(__TABLE_POOL_TAG__COMPONENT_LIST, component_count, 0)
    __table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_insert
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
local function __defer_multi_remove(entity, fragments)
    local fragment_count = #fragments
    local fragment_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragment_count, 0)
    __table_move(fragments, 1, fragment_count, 1, fragment_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_remove
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list

    __defer_length = length + 3
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_batch_set(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.batch_set
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_batch_assign(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.batch_assign
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_batch_insert(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.batch_insert
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param query evolved.query
---@param ... evolved.fragment fragments
local function __defer_batch_remove(query, ...)
    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_remove
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_count

    for i = 1, fragment_count do
        bytecode[length + 3 + i] = select(i, ...)
    end

    __defer_length = length + 3 + fragment_count
end

---@param query evolved.query
local function __defer_batch_clear(query)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_clear
    bytecode[length + 2] = query

    __defer_length = length + 2
end

---@param query evolved.query
local function __defer_batch_destroy(query)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_destroy
    bytecode[length + 2] = query

    __defer_length = length + 2
end

---
---
---
---
---

---@param count? integer
---@return evolved.id ... ids
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
---@return evolved.id id
---@nodiscard
function evolved.pack(index, version)
    if index < 1 or index > 0xFFFFF then
        error('id index out of range [1;0xFFFFF]', 2)
    end

    if version < 1 or version > 0x7FF then
        error('id version out of range [1;0x7FF]', 2)
    end

    return index + version * 0x100000
end

---@param id evolved.id
---@return integer index
---@return integer version
---@nodiscard
function evolved.unpack(id)
    local index = id % 0x100000
    local version = (id - index) / 0x100000
    return index, version
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
---@return boolean
---@nodiscard
function evolved.is_alive(entity)
    local entity_index = entity % 0x100000

    return __freelist_ids[entity_index] == entity
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
function evolved.is_empty(entity)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return true
    end

    return not __entity_chunks[entity_index]
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
function evolved.get(entity, ...)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return
    end

    local chunk = __entity_chunks[entity_index]

    if not chunk then
        return
    end

    local place = __entity_places[entity_index]
    return __chunk_get_components(chunk, place, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function evolved.has(entity, fragment)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false
    end

    local chunk = __entity_chunks[entity_index]

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
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false
    end

    local chunk = __entity_chunks[entity_index]

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
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false
    end

    local chunk = __entity_chunks[entity_index]

    if not chunk then
        return false
    end

    return __chunk_has_any_fragments(chunk, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return boolean is_set
---@return boolean is_deferred
function evolved.set(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_set(entity, fragment, ...)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local old_chunk = __entity_chunks[entity_index]
    local old_place = __entity_places[entity_index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if not new_chunk then
        return false, false
    end

    __defer()

    if old_chunk == new_chunk then
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        local old_component_index = old_component_indices[fragment]

        if old_component_index then
            local old_component_storage = old_component_storages[old_component_index]
            local old_component = old_component_storage[old_place]

            if old_chunk.__has_defaults_or_constructs then
                local new_component = __component_construct(fragment, ...)

                old_component_storage[old_place] = new_component

                if old_chunk.__has_set_or_assign_hooks then
                    __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                end
            else
                local new_component = ...
                if new_component == nil then new_component = true end

                old_component_storage[old_place] = new_component

                if old_chunk.__has_set_or_assign_hooks then
                    __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                end
            end
        else
            if old_chunk.__has_set_or_assign_hooks then
                __fragment_call_set_and_assign_hooks(entity, fragment)
            end
        end
    else
        local new_entities = new_chunk.__entities
        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_place = #new_entities + 1
        new_entities[new_place] = entity

        if old_chunk then
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for i = 1, #old_component_fragments do
                local old_f = old_component_fragments[i]
                local old_cs = old_component_storages[i]
                local new_ci = new_component_indices[old_f]
                if new_ci then
                    local new_cs = new_component_storages[new_ci]
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)
        end

        do
            local new_component_index = new_component_indices[fragment]

            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]

                if new_chunk.__has_defaults_or_constructs then
                    local new_component = __component_construct(fragment, ...)

                    new_component_storage[new_place] = new_component

                    if new_chunk.__has_set_or_insert_hooks then
                        __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                    end
                else
                    local new_component = ...
                    if new_component == nil then new_component = true end

                    new_component_storage[new_place] = new_component

                    if new_chunk.__has_set_or_insert_hooks then
                        __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                    end
                end
            else
                if new_chunk.__has_set_or_insert_hooks then
                    __fragment_call_set_and_insert_hooks(entity, fragment)
                end
            end
        end

        __entity_chunks[entity_index] = new_chunk
        __entity_places[entity_index] = new_place

        __structural_changes = __structural_changes + 1
    end

    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return boolean is_assigned
---@return boolean is_deferred
function evolved.assign(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_assign(entity, fragment, ...)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local chunk = __entity_chunks[entity_index]
    local place = __entity_places[entity_index]

    if not chunk or not chunk.__fragment_set[fragment] then
        return false, false
    end

    __defer()

    do
        local component_indices = chunk.__component_indices
        local component_storages = chunk.__component_storages

        local component_index = component_indices[fragment]

        if component_index then
            local component_storage = component_storages[component_index]
            local old_component = component_storage[place]

            if chunk.__has_defaults_or_constructs then
                local new_component = __component_construct(fragment, ...)

                component_storage[place] = new_component

                if chunk.__has_set_or_assign_hooks then
                    __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                end
            else
                local new_component = ...
                if new_component == nil then new_component = true end

                component_storage[place] = new_component

                if chunk.__has_set_or_assign_hooks then
                    __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                end
            end
        else
            if chunk.__has_set_or_assign_hooks then
                __fragment_call_set_and_assign_hooks(entity, fragment)
            end
        end
    end

    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return boolean is_inserted
---@return boolean is_deferred
function evolved.insert(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_insert(entity, fragment, ...)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local old_chunk = __entity_chunks[entity_index]
    local old_place = __entity_places[entity_index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if not new_chunk or old_chunk == new_chunk then
        return false, false
    end

    __defer()

    do
        local new_entities = new_chunk.__entities
        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_place = #new_entities + 1
        new_entities[new_place] = entity

        if old_chunk then
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for i = 1, #old_component_fragments do
                local old_f = old_component_fragments[i]
                local old_cs = old_component_storages[i]
                local new_ci = new_component_indices[old_f]
                if new_ci then
                    local new_cs = new_component_storages[new_ci]
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)
        end

        do
            local new_component_index = new_component_indices[fragment]

            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]

                if new_chunk.__has_defaults_or_constructs then
                    local new_component = __component_construct(fragment, ...)

                    new_component_storage[new_place] = new_component

                    if new_chunk.__has_set_or_insert_hooks then
                        __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                    end
                else
                    local new_component = ...
                    if new_component == nil then new_component = true end

                    new_component_storage[new_place] = new_component

                    if new_chunk.__has_set_or_insert_hooks then
                        __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                    end
                end
            else
                if new_chunk.__has_set_or_insert_hooks then
                    __fragment_call_set_and_insert_hooks(entity, fragment)
                end
            end
        end

        __entity_chunks[entity_index] = new_chunk
        __entity_places[entity_index] = new_place

        __structural_changes = __structural_changes + 1
    end

    __defer_commit()
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

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local old_chunk = __entity_chunks[entity_index]
    local old_place = __entity_places[entity_index]

    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return true, false
    end

    __defer()

    do
        local old_fragment_set = old_chunk.__fragment_set
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        if old_chunk.__has_remove_hooks then
            for i = 1, select('#', ...) do
                local fragment = select(i, ...)
                if old_fragment_set[fragment] then
                    local old_component_index = old_component_indices[fragment]
                    if old_component_index then
                        local old_component_storage = old_component_storages[old_component_index]
                        local old_component = old_component_storage[old_place]
                        __fragment_call_remove_hook(entity, fragment, old_component)
                    else
                        __fragment_call_remove_hook(entity, fragment)
                    end
                end
            end
        end

        if new_chunk then
            local new_entities = new_chunk.__entities
            local new_component_storages = new_chunk.__component_storages
            local new_component_fragments = new_chunk.__component_fragments

            local new_place = #new_entities + 1
            new_entities[new_place] = entity

            for i = 1, #new_component_fragments do
                local new_f = new_component_fragments[i]
                local new_cs = new_component_storages[i]
                local old_ci = old_component_indices[new_f]
                if old_ci then
                    local old_cs = old_component_storages[old_ci]
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)

            __entity_chunks[entity_index] = new_chunk
            __entity_places[entity_index] = new_place
        else
            __detach_entity(entity)
        end

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

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local chunk = __entity_chunks[entity_index]
    local place = __entity_places[entity_index]

    if not chunk then
        return true, false
    end

    __defer()

    do
        local fragment_list = chunk.__fragment_list
        local component_indices = chunk.__component_indices
        local component_storages = chunk.__component_storages

        if chunk.__has_remove_hooks then
            for i = 1, #fragment_list do
                local fragment = fragment_list[i]
                local component_index = component_indices[fragment]
                if component_index then
                    local component_storage = component_storages[component_index]
                    local old_component = component_storage[place]
                    __fragment_call_remove_hook(entity, fragment, old_component)
                else
                    __fragment_call_remove_hook(entity, fragment)
                end
            end
        end

        __detach_entity(entity)

        __structural_changes = __structural_changes + 1
    end

    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@return boolean is_destroyed
---@return boolean is_deferred
function evolved.destroy(entity)
    if __defer_depth > 0 then
        __defer_destroy(entity)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return true, false
    end

    local chunk = __entity_chunks[entity_index]
    local place = __entity_places[entity_index]

    if not chunk then
        __release_id(entity)
        return true, false
    end

    __defer()

    do
        local fragment_list = chunk.__fragment_list
        local component_indices = chunk.__component_indices
        local component_storages = chunk.__component_storages

        if chunk.__has_remove_hooks then
            for i = 1, #fragment_list do
                local fragment = fragment_list[i]
                local component_index = component_indices[fragment]
                if component_index then
                    local component_storage = component_storages[component_index]
                    local old_component = component_storage[place]
                    __fragment_call_remove_hook(entity, fragment, old_component)
                else
                    __fragment_call_remove_hook(entity, fragment)
                end
            end
        end

        __detach_entity(entity)
        __release_id(entity)

        __structural_changes = __structural_changes + 1
    end

    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components? any[]
---@return boolean is_any_set
---@return boolean is_deferred
function evolved.multi_set(entity, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return false, false
    end

    if not components then
        components = __EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_multi_set(entity, fragments, components)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local old_chunk = __entity_chunks[entity_index]
    local old_place = __entity_places[entity_index]

    local new_chunk = __chunk_with_fragment_list(old_chunk, fragments)

    if not new_chunk then
        return false, false
    end

    __defer()

    if old_chunk == new_chunk then
        local old_fragment_set = old_chunk.__fragment_set
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        for i = 1, fragment_count do
            local fragment = fragments[i]
            if old_fragment_set[fragment] then
                local old_component_index = old_component_indices[fragment]

                if old_component_index then
                    local old_component_storage = old_component_storages[old_component_index]
                    local old_component = old_component_storage[old_place]

                    if old_chunk.__has_defaults_or_constructs then
                        local new_component = components[i]

                        if new_component == nil then new_component = evolved.get(fragment, evolved.DEFAULT) end
                        if new_component == nil then new_component = true end

                        old_component_storage[old_place] = new_component

                        if old_chunk.__has_set_or_assign_hooks then
                            __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                        end
                    else
                        local new_component = components[i]
                        if new_component == nil then new_component = true end

                        old_component_storage[old_place] = new_component

                        if old_chunk.__has_set_or_assign_hooks then
                            __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                        end
                    end
                else
                    if old_chunk.__has_set_or_assign_hooks then
                        __fragment_call_set_and_assign_hooks(entity, fragment)
                    end
                end
            end
        end
    else
        local new_entities = new_chunk.__entities
        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local old_fragment_set = old_chunk and old_chunk.__fragment_set or __EMPTY_FRAGMENT_SET

        local new_place = #new_entities + 1
        new_entities[new_place] = entity

        if old_chunk then
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for i = 1, #old_component_fragments do
                local old_f = old_component_fragments[i]
                local old_cs = old_component_storages[i]
                local new_ci = new_component_indices[old_f]
                if new_ci then
                    local new_cs = new_component_storages[new_ci]
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)
        end

        local inserted_set = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_SET, 0, fragment_count)

        for i = 1, fragment_count do
            local fragment = fragments[i]
            if inserted_set[fragment] or old_fragment_set[fragment] then
                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]
                    local old_component = new_component_storage[new_place]

                    if new_chunk.__has_defaults_or_constructs then
                        local new_component = components[i]

                        if new_component == nil then new_component = evolved.get(fragment, evolved.DEFAULT) end
                        if new_component == nil then new_component = true end

                        new_component_storage[new_place] = new_component

                        if new_chunk.__has_set_or_assign_hooks then
                            __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                        end
                    else
                        local new_component = components[i]
                        if new_component == nil then new_component = true end

                        new_component_storage[new_place] = new_component

                        if new_chunk.__has_set_or_assign_hooks then
                            __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                        end
                    end
                else
                    if new_chunk.__has_set_or_assign_hooks then
                        __fragment_call_set_and_assign_hooks(entity, fragment)
                    end
                end
            else
                inserted_set[fragment] = true

                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    if new_chunk.__has_defaults_or_constructs then
                        local new_component = components[i]

                        if new_component == nil then new_component = evolved.get(fragment, evolved.DEFAULT) end
                        if new_component == nil then new_component = true end

                        new_component_storage[new_place] = new_component

                        if new_chunk.__has_set_or_insert_hooks then
                            __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                        end
                    else
                        local new_component = components[i]
                        if new_component == nil then new_component = true end

                        new_component_storage[new_place] = new_component

                        if new_chunk.__has_set_or_insert_hooks then
                            __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                        end
                    end
                else
                    if new_chunk.__has_set_or_insert_hooks then
                        __fragment_call_set_and_insert_hooks(entity, fragment)
                    end
                end
            end
        end

        __release_table(__TABLE_POOL_TAG__FRAGMENT_SET, inserted_set)

        __entity_chunks[entity_index] = new_chunk
        __entity_places[entity_index] = new_place

        __structural_changes = __structural_changes + 1
    end

    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components? any[]
---@return boolean is_any_assigned
---@return boolean is_deferred
function evolved.multi_assign(entity, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return false, false
    end

    if not components then
        components = __EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_multi_assign(entity, fragments, components)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local chunk = __entity_chunks[entity_index]
    local place = __entity_places[entity_index]

    if not chunk or not __chunk_has_any_fragment_list(chunk, fragments) then
        return false, false
    end

    __defer()

    do
        local fragment_set = chunk.__fragment_set
        local component_indices = chunk.__component_indices
        local component_storages = chunk.__component_storages

        for i = 1, fragment_count do
            local fragment = fragments[i]
            if fragment_set[fragment] then
                local component_index = component_indices[fragment]

                if component_index then
                    local component_storage = component_storages[component_index]
                    local old_component = component_storage[place]

                    if chunk.__has_defaults_or_constructs then
                        local new_component = components[i]

                        if new_component == nil then new_component = evolved.get(fragment, evolved.DEFAULT) end
                        if new_component == nil then new_component = true end

                        component_storage[place] = new_component

                        if chunk.__has_set_or_assign_hooks then
                            __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                        end
                    else
                        local new_component = components[i]
                        if new_component == nil then new_component = true end

                        component_storage[place] = new_component

                        if chunk.__has_set_or_assign_hooks then
                            __fragment_call_set_and_assign_hooks(entity, fragment, new_component, old_component)
                        end
                    end
                else
                    if chunk.__has_set_or_assign_hooks then
                        __fragment_call_set_and_assign_hooks(entity, fragment)
                    end
                end
            end
        end
    end

    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components? any[]
---@return boolean is_any_inserted
---@return boolean is_deferred
function evolved.multi_insert(entity, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return false, false
    end

    if not components then
        components = __EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_multi_insert(entity, fragments, components)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local old_chunk = __entity_chunks[entity_index]
    local old_place = __entity_places[entity_index]

    local new_chunk = __chunk_with_fragment_list(old_chunk, fragments)

    if not new_chunk or old_chunk == new_chunk then
        return false, false
    end

    __defer()

    do
        local new_entities = new_chunk.__entities
        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local old_fragment_set = old_chunk and old_chunk.__fragment_set or __EMPTY_FRAGMENT_SET

        local new_place = #new_entities + 1
        new_entities[new_place] = entity

        if old_chunk then
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for i = 1, #old_component_fragments do
                local old_f = old_component_fragments[i]
                local old_cs = old_component_storages[i]
                local new_ci = new_component_indices[old_f]
                if new_ci then
                    local new_cs = new_component_storages[new_ci]
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)
        end

        local inserted_set = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_SET, 0, fragment_count)

        for i = 1, fragment_count do
            local fragment = fragments[i]
            if not inserted_set[fragment] and not old_fragment_set[fragment] then
                inserted_set[fragment] = true

                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    if new_chunk.__has_defaults_or_constructs then
                        local new_component = components[i]

                        if new_component == nil then new_component = evolved.get(fragment, evolved.DEFAULT) end
                        if new_component == nil then new_component = true end

                        new_component_storage[new_place] = new_component

                        if new_chunk.__has_set_or_insert_hooks then
                            __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                        end
                    else
                        local new_component = components[i]
                        if new_component == nil then new_component = true end

                        new_component_storage[new_place] = new_component

                        if new_chunk.__has_set_or_insert_hooks then
                            __fragment_call_set_and_insert_hooks(entity, fragment, new_component)
                        end
                    end
                else
                    if new_chunk.__has_set_or_insert_hooks then
                        __fragment_call_set_and_insert_hooks(entity, fragment)
                    end
                end
            end
        end

        __entity_chunks[entity_index] = new_chunk
        __entity_places[entity_index] = new_place

        __structural_changes = __structural_changes + 1
    end

    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@return boolean is_all_removed
---@return boolean is_deferred
function evolved.multi_remove(entity, fragments)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return true, false
    end

    if __defer_depth > 0 then
        __defer_multi_remove(entity, fragments)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local old_chunk = __entity_chunks[entity_index]
    local old_place = __entity_places[entity_index]

    local new_chunk = __chunk_without_fragment_list(old_chunk, fragments)

    if old_chunk == new_chunk then
        return true, false
    end

    __defer()

    do
        local old_fragment_set = old_chunk.__fragment_set
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        if old_chunk.__has_remove_hooks then
            local removed_set = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_SET, 0, fragment_count)

            for i = 1, fragment_count do
                local fragment = fragments[i]
                if not removed_set[fragment] and old_fragment_set[fragment] then
                    removed_set[fragment] = true
                    local old_component_index = old_component_indices[fragment]
                    if old_component_index then
                        local old_component_storage = old_component_storages[old_component_index]
                        local old_component = old_component_storage[old_place]
                        __fragment_call_remove_hook(entity, fragment, old_component)
                    else
                        __fragment_call_remove_hook(entity, fragment)
                    end
                end
            end

            __release_table(__TABLE_POOL_TAG__FRAGMENT_SET, removed_set)
        end

        if new_chunk then
            local new_entities = new_chunk.__entities
            local new_component_storages = new_chunk.__component_storages
            local new_component_fragments = new_chunk.__component_fragments

            local new_place = #new_entities + 1
            new_entities[new_place] = entity

            for i = 1, #new_component_fragments do
                local new_f = new_component_fragments[i]
                local new_cs = new_component_storages[i]
                local old_ci = old_component_indices[new_f]
                if old_ci then
                    local old_cs = old_component_storages[old_ci]
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)

            __entity_chunks[entity_index] = new_chunk
            __entity_places[entity_index] = new_place
        else
            __detach_entity(entity)
        end

        __structural_changes = __structural_changes + 1
    end

    __defer_commit()
    return true, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer set_count
---@return boolean is_deferred
function evolved.batch_set(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_set(query, fragment, ...)
        return 0, true
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__TABLE_POOL_TAG__CHUNK_LIST, 16, 0)

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local set_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            if __chunk_has_fragment(chunk, fragment) then
                set_count = set_count + __chunk_assign(chunk, fragment, ...)
            else
                set_count = set_count + __chunk_insert(chunk, fragment, ...)
            end
        end
    end
    __defer_commit()

    __release_table(__TABLE_POOL_TAG__CHUNK_LIST, chunk_list)
    return set_count, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer assigned_count
---@return boolean is_deferred
function evolved.batch_assign(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_assign(query, fragment, ...)
        return 0, true
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__TABLE_POOL_TAG__CHUNK_LIST, 16, 0)

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local assigned_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            assigned_count = assigned_count + __chunk_assign(chunk, fragment, ...)
        end
    end
    __defer_commit()

    __release_table(__TABLE_POOL_TAG__CHUNK_LIST, chunk_list)
    return assigned_count, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer inserted_count
---@return boolean is_deferred
function evolved.batch_insert(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_insert(query, fragment, ...)
        return 0, true
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__TABLE_POOL_TAG__CHUNK_LIST, 16, 0)

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local inserted_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            inserted_count = inserted_count + __chunk_insert(chunk, fragment, ...)
        end
    end
    __defer_commit()

    __release_table(__TABLE_POOL_TAG__CHUNK_LIST, chunk_list)
    return inserted_count, false
end

---@param query evolved.query
---@param ... evolved.fragment fragments
---@return integer removed_count
---@return boolean is_deferred
function evolved.batch_remove(query, ...)
    if __defer_depth > 0 then
        __defer_batch_remove(query, ...)
        return 0, true
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__TABLE_POOL_TAG__CHUNK_LIST, 16, 0)

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local removed_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            removed_count = removed_count + __chunk_remove(chunk, ...)
        end
    end
    __defer_commit()

    __release_table(__TABLE_POOL_TAG__CHUNK_LIST, chunk_list)
    return removed_count, false
end

---@param query evolved.query
---@return integer cleared_count
---@return boolean is_deferred
function evolved.batch_clear(query)
    if __defer_depth > 0 then
        __defer_batch_clear(query)
        return 0, true
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__TABLE_POOL_TAG__CHUNK_LIST, 16, 0)

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local cleared_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            cleared_count = cleared_count + __chunk_clear(chunk)
        end
    end
    __defer_commit()

    __release_table(__TABLE_POOL_TAG__CHUNK_LIST, chunk_list)
    return cleared_count, false
end

---@param query evolved.query
---@return integer destroyed_count
---@return boolean is_deferred
function evolved.batch_destroy(query)
    if __defer_depth > 0 then
        __defer_batch_destroy(query)
        return 0, true
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__TABLE_POOL_TAG__CHUNK_LIST, 16, 0)

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local destroyed_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            destroyed_count = destroyed_count + __chunk_destroy(chunk)
        end
    end
    __defer_commit()

    __release_table(__TABLE_POOL_TAG__CHUNK_LIST, chunk_list)
    return destroyed_count, false
end

---
---
---
---
---

evolved.set(evolved.TAG, evolved.TAG)

---@param ... evolved.fragment
evolved.set(evolved.INCLUDES, evolved.CONSTRUCT, function(...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return __table_new(0, 0)
    end

    ---@type evolved.fragment[]
    local include_list = __table_new(fragment_count, 0)

    for i = 1, fragment_count do
        include_list[i] = select(i, ...)
    end

    return include_list
end)

---@param query evolved.query
---@param include_list evolved.fragment[]
evolved.set(evolved.INCLUDES, evolved.ON_SET, function(query, _, include_list)
    local include_list_size = #include_list

    ---@type table<evolved.fragment, boolean>
    local include_set = __table_new(0, include_list_size)

    for i = 1, include_list_size do
        include_set[include_list[i]] = true
    end

    ---@type evolved.fragment[]
    local sorted_include_list = __table_new(include_list_size, 0)
    local sorted_include_list_size = 0

    for f, _ in pairs(include_set) do
        sorted_include_list[sorted_include_list_size + 1] = f
        sorted_include_list_size = sorted_include_list_size + 1
    end

    table.sort(sorted_include_list)

    evolved.set(query, __INCLUDE_SET, include_set)
    evolved.set(query, __SORTED_INCLUDE_LIST, sorted_include_list)
end)

evolved.set(evolved.INCLUDES, evolved.ON_REMOVE, function(query)
    evolved.remove(query, __INCLUDE_SET, __SORTED_INCLUDE_LIST)
end)

---@param ... evolved.fragment
evolved.set(evolved.EXCLUDES, evolved.CONSTRUCT, function(...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return __table_new(0, 0)
    end

    ---@type evolved.fragment[]
    local exclude_list = __table_new(fragment_count, 0)

    for i = 1, fragment_count do
        exclude_list[i] = select(i, ...)
    end

    return exclude_list
end)

---@param query evolved.query
---@param exclude_list evolved.fragment[]
evolved.set(evolved.EXCLUDES, evolved.ON_SET, function(query, _, exclude_list)
    local exclude_list_size = #exclude_list

    ---@type table<evolved.fragment, boolean>
    local exclude_set = __table_new(0, exclude_list_size)

    for i = 1, exclude_list_size do
        exclude_set[exclude_list[i]] = true
    end

    ---@type evolved.fragment[]
    local sorted_exclude_list = __table_new(exclude_list_size, 0)
    local sorted_exclude_list_size = 0

    for f, _ in pairs(exclude_set) do
        sorted_exclude_list[sorted_exclude_list_size + 1] = f
        sorted_exclude_list_size = sorted_exclude_list_size + 1
    end

    table.sort(sorted_exclude_list)

    evolved.set(query, __EXCLUDE_SET, exclude_set)
    evolved.set(query, __SORTED_EXCLUDE_LIST, sorted_exclude_list)
end)

evolved.set(evolved.EXCLUDES, evolved.ON_REMOVE, function(query)
    evolved.remove(query, __EXCLUDE_SET, __SORTED_EXCLUDE_LIST)
end)

---
---
---
---
---

---@param ... evolved.fragment fragments
---@return evolved.chunk? chunk
---@return evolved.entity[]? chunk_entities
function evolved.chunk(...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return
    end

    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragment_count, 0)

    for i = 1, fragment_count do
        local fragment = select(i, ...)
        fragment_list[#fragment_list + 1] = fragment
    end

    table.sort(fragment_list)

    local root_fragment = fragment_list[1]
    local chunk = __root_chunks[root_fragment]
        or __root_chunk(root_fragment)

    for i = 2, fragment_count do
        local child_fragment = fragment_list[i]
        chunk = chunk.__with_fragment_edges[child_fragment]
            or __chunk_with_fragment(chunk, child_fragment)
    end

    __release_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragment_list)
    return chunk, chunk.__entities
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return evolved.component_storage ... component_storages
---@nodiscard
function evolved.select(chunk, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return
    end

    local indices = chunk.__component_indices
    local storages = chunk.__component_storages

    local empty_component_storage = __EMPTY_COMPONENT_STORAGE

    if fragment_count == 1 then
        local f1 = ...
        local i1 = indices[f1]
        return
            i1 and storages[i1] or empty_component_storage
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local i1, i2 = indices[f1], indices[f2]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local i1, i2, i3 = indices[f1], indices[f2], indices[f3]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage,
            i3 and storages[i3] or empty_component_storage
    end

    do
        local f1, f2, f3 = ...
        local i1, i2, i3 = indices[f1], indices[f2], indices[f3]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage,
            i3 and storages[i3] or empty_component_storage,
            evolved.select(chunk, select(4, ...))
    end
end

---@param entity evolved.entity
---@return evolved.each_iterator iterator
---@return evolved.each_state? iterator_state
---@nodiscard
function evolved.each(entity)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return __each_iterator
    end

    local chunk = __entity_chunks[entity_index]
    local place = __entity_places[entity_index]

    if not chunk then
        return __each_iterator
    end

    ---@type evolved.each_state
    local each_state = __acquire_table(__TABLE_POOL_TAG__EACH_STATE, 4, 0)

    each_state[1] = __structural_changes
    each_state[2] = chunk
    each_state[3] = place
    each_state[4] = 1

    return __each_iterator, each_state
end

---@param query evolved.query
---@return evolved.execute_iterator iterator
---@return evolved.execute_state? iterator_state
---@nodiscard
function evolved.execute(query)
    local query_index = query % 0x100000

    if __freelist_ids[query_index] ~= query then
        return __execute_iterator
    end

    ---@type table<evolved.fragment, boolean>?, evolved.fragment[]?, evolved.fragment[]?
    local exclude_set, include_list, exclude_list = evolved.get(query,
        __EXCLUDE_SET, __SORTED_INCLUDE_LIST, __SORTED_EXCLUDE_LIST)

    if not exclude_set then exclude_set = __EMPTY_FRAGMENT_SET end
    if not include_list then include_list = __EMPTY_FRAGMENT_LIST end
    if not exclude_list then exclude_list = __EMPTY_FRAGMENT_LIST end

    if #include_list == 0 then
        return __execute_iterator
    end

    local major_fragment = include_list[#include_list]
    local major_fragment_chunks = __major_chunks[major_fragment]

    if not major_fragment_chunks then
        return __execute_iterator
    end

    ---@type evolved.chunk[]
    local chunk_stack = __acquire_table(__TABLE_POOL_TAG__CHUNK_LIST, 16, 0)

    ---@type evolved.execute_state
    local execute_state = __acquire_table(__TABLE_POOL_TAG__EXECUTE_STATE, 3, 0)

    execute_state[1] = __structural_changes
    execute_state[2] = chunk_stack
    execute_state[3] = exclude_set

    for _, major_fragment_chunk in ipairs(major_fragment_chunks) do
        if __chunk_has_all_fragment_list(major_fragment_chunk, include_list) then
            if not __chunk_has_any_fragment_list(major_fragment_chunk, exclude_list) then
                chunk_stack[#chunk_stack + 1] = major_fragment_chunk
            end
        end
    end

    return __execute_iterator, execute_state
end

---
---
---
---
---

---@class (exact) evolved.__entity_builder
---@field package __fragment_list? evolved.fragment[]
---@field package __component_list? evolved.component[]

---@class evolved.entity_builder : evolved.__entity_builder
local evolved_entity_builder = {}
evolved_entity_builder.__index = evolved_entity_builder

---@return evolved.entity_builder builder
---@nodiscard
function evolved.entity()
    ---@type evolved.__entity_builder
    local builder = {
        __fragment_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, 8, 0),
        __component_list = __acquire_table(__TABLE_POOL_TAG__COMPONENT_LIST, 8, 0),
    }
    ---@cast builder evolved.entity_builder
    return setmetatable(builder, evolved_entity_builder)
end

---@param fragment evolved.fragment
---@param ... any component arguments
---@return evolved.entity_builder builder
function evolved_entity_builder:set(fragment, ...)
    local component = __component_construct(fragment, ...)

    local fragment_list = self.__fragment_list
    local component_list = self.__component_list

    fragment_list[#fragment_list + 1] = fragment
    component_list[#component_list + 1] = component

    return self
end

---@return evolved.entity entity
function evolved_entity_builder:build()
    local fragment_list = self.__fragment_list
    local component_list = self.__component_list

    self.__fragment_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, 8, 0)
    self.__component_list = __acquire_table(__TABLE_POOL_TAG__COMPONENT_LIST, 8, 0)

    local entity = evolved.id()

    for i = 1, #fragment_list do
        local fragment = fragment_list[i]
        local component = component_list[i]
        evolved.set(entity, fragment, component)
    end

    __release_table(__TABLE_POOL_TAG__FRAGMENT_LIST, fragment_list)
    __release_table(__TABLE_POOL_TAG__COMPONENT_LIST, component_list)

    return entity
end

---
---
---
---
---

---@class (evact) evolved.__fragment_builder
---@field package __tag boolean
---@field package __default? evolved.component
---@field package __construct? fun(...): evolved.component

---@class evolved.fragment_builder : evolved.__fragment_builder
local evolved_fragment_builder = {}
evolved_fragment_builder.__index = evolved_fragment_builder

---@return evolved.fragment_builder builder
---@nodiscard
function evolved.fragment()
    ---@type evolved.__fragment_builder
    local builder = {
        __tag = false,
        __default = nil,
        __construct = nil,
    }
    ---@cast builder evolved.fragment_builder
    return setmetatable(builder, evolved_fragment_builder)
end

---@return evolved.fragment_builder builder
function evolved_fragment_builder:tag()
    self.__tag = true
    return self
end

---@param default evolved.component
---@return evolved.fragment_builder builder
function evolved_fragment_builder:default(default)
    self.__default = default
    return self
end

---@param construct fun(...): evolved.component
---@return evolved.fragment_builder builder
function evolved_fragment_builder:construct(construct)
    self.__construct = construct
    return self
end

---@return evolved.fragment fragment
function evolved_fragment_builder:build()
    local tag = self.__tag
    local default = self.__default
    local construct = self.__construct

    self.__tag = false
    self.__default = nil
    self.__construct = nil

    local fragment = evolved.id()

    if tag then
        evolved.set(fragment, evolved.TAG, tag)
    end

    if default ~= nil then
        evolved.set(fragment, evolved.DEFAULT, default)
    end

    if construct ~= nil then
        evolved.set(fragment, evolved.CONSTRUCT, construct)
    end

    return fragment
end

---
---
---
---
---

---@class (exact) evolved.__query_builder
---@field package __include_list? evolved.fragment[]
---@field package __exclude_list? evolved.fragment[]

---@class evolved.query_builder : evolved.__query_builder
local evolved_query_builder = {}
evolved_query_builder.__index = evolved_query_builder

---@return evolved.query_builder builder
---@nodiscard
function evolved.query()
    ---@type evolved.__query_builder
    local builder = {
        __include_list = nil,
        __exclude_list = nil,
    }
    ---@cast builder evolved.query_builder
    return setmetatable(builder, evolved_query_builder)
end

---@param ... evolved.fragment fragments
---@return evolved.query_builder builder
function evolved_query_builder:include(...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return self
    end

    local include_list = self.__include_list

    if not include_list then
        include_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, 8, 0)
        self.__include_list = include_list
    end

    local include_list_size = #include_list

    for i = 1, fragment_count do
        local fragment = select(i, ...)
        include_list[include_list_size + 1] = fragment
        include_list_size = include_list_size + 1
    end

    return self
end

---@param ... evolved.fragment fragments
---@return evolved.query_builder builder
function evolved_query_builder:exclude(...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return self
    end

    local exclude_list = self.__exclude_list

    if not exclude_list then
        exclude_list = __acquire_table(__TABLE_POOL_TAG__FRAGMENT_LIST, 8, 0)
        self.__exclude_list = exclude_list
    end

    local exclude_list_size = #exclude_list

    for i = 1, fragment_count do
        local fragment = select(i, ...)
        exclude_list[exclude_list_size + 1] = fragment
        exclude_list_size = exclude_list_size + 1
    end

    return self
end

---@return evolved.query query
function evolved_query_builder:build()
    local include_list = self.__include_list
    local exclude_list = self.__exclude_list

    self.__include_list = nil
    self.__exclude_list = nil

    local query = evolved.id()

    if include_list then
        evolved.insert(query, evolved.INCLUDES, __table_unpack(include_list))
        __release_table(__TABLE_POOL_TAG__FRAGMENT_LIST, include_list)
    end

    if exclude_list then
        evolved.insert(query, evolved.EXCLUDES, __table_unpack(exclude_list))
        __release_table(__TABLE_POOL_TAG__FRAGMENT_LIST, exclude_list)
    end

    return query
end

---
---
---
---
---

return evolved
