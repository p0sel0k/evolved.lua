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

---@class evolved.id

---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.query evolved.id
---@alias evolved.phase evolved.id
---@alias evolved.system evolved.id

---@alias evolved.component any
---@alias evolved.storage evolved.component[]

---@alias evolved.default evolved.component
---@alias evolved.construct fun(...: any): evolved.component

---@alias evolved.execute fun(c: evolved.chunk, es: evolved.entity[], ec: integer)
---@alias evolved.prologue fun()
---@alias evolved.epilogue fun()

---@alias evolved.set_hook fun(e: evolved.entity, f: evolved.fragment, nc: evolved.component, oc?: evolved.component)
---@alias evolved.assign_hook fun(e: evolved.entity, f: evolved.fragment, nc: evolved.component, oc: evolved.component)
---@alias evolved.insert_hook fun(e: evolved.entity, f: evolved.fragment, nc: evolved.component)
---@alias evolved.remove_hook fun(e: evolved.entity, f: evolved.fragment, c: evolved.component)

---@class (exact) evolved.chunk
---@field package __parent? evolved.chunk
---@field package __child_list evolved.chunk[]
---@field package __child_count integer
---@field package __entity_list evolved.entity[]
---@field package __entity_count integer
---@field package __fragment evolved.fragment
---@field package __fragment_set table<evolved.fragment, integer>
---@field package __fragment_list evolved.fragment[]
---@field package __fragment_count integer
---@field package __component_count integer
---@field package __component_indices table<evolved.fragment, integer>
---@field package __component_storages evolved.storage[]
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
---@field package [4] integer chunk_fragment_index

---@class (exact) evolved.execute_state
---@field package [1] integer structural_changes
---@field package [2] evolved.chunk[] chunk_stack
---@field package [3] integer chunk_stack_size
---@field package [4] table<evolved.fragment, integer>? exclude_set

---@alias evolved.each_iterator fun(state: evolved.each_state?): evolved.fragment?, evolved.component?
---@alias evolved.execute_iterator fun(state: evolved.execute_state?): evolved.chunk?, evolved.entity[]?, integer?

---
---
---
---
---

local __debug_mode = false ---@type boolean

local __freelist_ids = {} ---@type integer[]
local __acquired_count = 0 ---@type integer
local __available_index = 0 ---@type integer

local __defer_depth = 0 ---@type integer
local __defer_length = 0 ---@type integer
local __defer_bytecode = {} ---@type any[]

local __root_chunks = {} ---@type table<evolved.fragment, evolved.chunk>
local __major_chunks = {} ---@type table<evolved.fragment, evolved.assoc_list>
local __minor_chunks = {} ---@type table<evolved.fragment, evolved.assoc_list>

local __entity_chunks = {} ---@type table<integer, evolved.chunk>
local __entity_places = {} ---@type table<integer, integer>

local __structural_changes = 0 ---@type integer

local __phase_systems = {} ---@type table<evolved.phase, evolved.assoc_list>
local __system_dependencies = {} ---@type table<evolved.system, evolved.assoc_list>

local __query_sorted_includes = {} ---@type table<evolved.query, evolved.assoc_list>
local __query_sorted_excludes = {} ---@type table<evolved.query, evolved.assoc_list>

---
---
---
---
---

local __lua_assert = assert
local __lua_error = error
local __lua_ipairs = ipairs
local __lua_next = next
local __lua_pairs = pairs
local __lua_pcall = pcall
local __lua_print = print
local __lua_select = select
local __lua_setmetatable = setmetatable
local __lua_string_format = string.format
local __lua_table_concat = table.concat
local __lua_table_sort = table.sort
local __lua_table_unpack = table.unpack or unpack

local __lua_table_move = (function()
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

---@type fun(narray: integer, nhash: integer): table
local __lua_table_new = (function()
    local table_new_loader = package.preload['table.new']
    ---@return table
    return table_new_loader and table_new_loader() or function()
        return {}
    end
end)()

---@type fun(tab: table)
local __lua_table_clear = (function()
    local table_clear_loader = package.preload['table.clear']
    ---@param tab table
    return table_clear_loader and table_clear_loader() or function(tab)
        for i = 1, #tab do tab[i] = nil end
        for k in __lua_next, tab do tab[k] = nil end
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
    local freelist_ids = __freelist_ids
    local available_index = __available_index

    if available_index ~= 0 then
        local acquired_index = available_index
        local freelist_id = freelist_ids[acquired_index]

        local next_available_index = freelist_id % 0x100000
        local shifted_version = freelist_id - next_available_index

        __available_index = next_available_index

        local acquired_id = acquired_index + shifted_version
        freelist_ids[acquired_index] = acquired_id

        return acquired_id --[[@as evolved.id]]
    else
        local acquired_count = __acquired_count

        if acquired_count == 0xFFFFF then
            __lua_error('id index overflow')
        end

        acquired_count = acquired_count + 1
        __acquired_count = acquired_count

        local acquired_index = acquired_count
        local shifted_version = 0x100000

        local acquired_id = acquired_index + shifted_version
        freelist_ids[acquired_index] = acquired_id

        return acquired_id --[[@as evolved.id]]
    end
end

---@param id evolved.id
local function __release_id(id)
    local acquired_index = id % 0x100000
    local shifted_version = id - acquired_index

    local freelist_ids = __freelist_ids

    if freelist_ids[acquired_index] ~= id then
        __lua_error('id is not acquired or already released')
    end

    shifted_version = shifted_version == 0xFFF00000
        and 0x100000
        or shifted_version + 0x100000

    freelist_ids[acquired_index] = __available_index + shifted_version
    __available_index = acquired_index
end

---
---
---
---
---

---@enum evolved.table_pool_tag
local __table_pool_tag = {
    bytecode = 1,
    chunk_stack = 2,
    each_state = 3,
    execute_state = 4,
    fragment_set = 5,
    fragment_list = 6,
    component_list = 7,
    system_list = 8,
    sorting_stack = 9,
    sorting_marks = 10,
    __count = 10,
}

---@class (exact) evolved.table_pool
---@field package __size integer
---@field package [integer] table

---@type table<evolved.table_pool_tag, evolved.table_pool>
local __tagged_table_pools = (function()
    local table_pools = __lua_table_new(__table_pool_tag.__count, 0)
    local table_pool_reserve = 16

    for tag = 1, __table_pool_tag.__count do
        ---@type evolved.table_pool
        local table_pool = __lua_table_new(table_pool_reserve, 1)
        for i = 1, table_pool_reserve do table_pool[i] = {} end
        table_pool.__size = table_pool_reserve
        table_pools[tag] = table_pool
    end

    return table_pools
end)()

---@param tag evolved.table_pool_tag
---@return table
---@nodiscard
local function __acquire_table(tag)
    local table_pool = __tagged_table_pools[tag]
    local table_pool_size = table_pool.__size

    if table_pool_size == 0 then
        return {}
    end

    local table = table_pool[table_pool_size]

    table_pool[table_pool_size] = nil
    table_pool_size = table_pool_size - 1

    table_pool.__size = table_pool_size
    return table
end

---@param tag evolved.table_pool_tag
---@param table table
---@param no_clear? boolean
local function __release_table(tag, table, no_clear)
    local table_pool = __tagged_table_pools[tag]
    local table_pool_size = table_pool.__size

    if not no_clear then
        __lua_table_clear(table)
    end

    table_pool_size = table_pool_size + 1
    table_pool[table_pool_size] = table

    table_pool.__size = table_pool_size
end

---
---
---
---
---

---@class (exact) evolved.assoc_list
---@field package __item_set table<any, integer>
---@field package __item_list any[]
---@field package __item_count integer

---@param reserve? integer
---@return evolved.assoc_list
---@nodiscard
local function __assoc_list_new(reserve)
    ---@type evolved.assoc_list
    return {
        __item_set = __lua_table_new(0, reserve or 0),
        __item_list = __lua_table_new(reserve or 0, 0),
        __item_count = 0,
    }
end

---@param al evolved.assoc_list
---@param comp? fun(a: any, b: any): boolean
local function __assoc_list_sort(al, comp)
    local al_item_count = al.__item_count

    if al_item_count < 2 then
        return
    end

    local al_item_set, al_item_list = al.__item_set, al.__item_list

    __lua_table_sort(al_item_list, comp)

    for al_item_index = 1, al_item_count do
        local al_item = al_item_list[al_item_index]
        al_item_set[al_item] = al_item_index
    end
end

---@param al evolved.assoc_list
---@param item any
local function __assoc_list_insert(al, item)
    local al_item_set = al.__item_set

    local item_index = al_item_set[item]

    if item_index then
        return
    end

    local al_item_list, al_item_count = al.__item_list, al.__item_count

    al_item_count = al_item_count + 1
    al_item_set[item] = al_item_count
    al_item_list[al_item_count] = item

    al.__item_count = al_item_count
end

---@param al evolved.assoc_list
---@param item any
local function __assoc_list_remove_ordered(al, item)
    local al_item_set = al.__item_set

    local item_index = al_item_set[item]

    if not item_index then
        return
    end

    local al_item_list, al_item_count = al.__item_list, al.__item_count

    for al_item_index = item_index, al_item_count - 1 do
        local al_next_item = al_item_list[al_item_index + 1]
        al_item_set[al_next_item] = al_item_index
        al_item_list[al_item_index] = al_next_item
    end

    al_item_set[item] = nil
    al_item_list[al_item_count] = nil
    al_item_count = al_item_count - 1

    al.__item_count = al_item_count
end

---@param al evolved.assoc_list
---@param item any
---@diagnostic disable-next-line: unused-function, unused-local
local function __assoc_list_remove_unordered(al, item)
    local al_item_set = al.__item_set

    local item_index = al_item_set[item]

    if not item_index then
        return
    end

    local al_item_list, al_item_count = al.__item_list, al.__item_count

    if item_index ~= al_item_count then
        local al_last_item = al_item_list[al_item_count]
        al_item_set[al_last_item] = item_index
        al_item_list[item_index] = al_last_item
    end

    al_item_set[item] = nil
    al_item_list[al_item_count] = nil
    al_item_count = al_item_count - 1

    al.__item_count = al_item_count
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
    local chunk_fragment_index = each_state[4]

    if structural_changes ~= __structural_changes then
        __lua_error('structural changes are prohibited during iteration')
    end

    local chunk_fragment_list = entity_chunk.__fragment_list
    local chunk_fragment_count = entity_chunk.__fragment_count
    local chunk_component_indices = entity_chunk.__component_indices
    local chunk_component_storages = entity_chunk.__component_storages

    if chunk_fragment_index <= chunk_fragment_count then
        each_state[4] = chunk_fragment_index + 1
        local fragment = chunk_fragment_list[chunk_fragment_index]
        local component_index = chunk_component_indices[fragment]
        local component_storage = chunk_component_storages[component_index]
        return fragment, component_storage and component_storage[entity_place]
    end

    __release_table(__table_pool_tag.each_state, each_state, true)
end

---@type evolved.execute_iterator
local function __execute_iterator(execute_state)
    if not execute_state then return end

    local structural_changes = execute_state[1]
    local chunk_stack = execute_state[2]
    local chunk_stack_size = execute_state[3]
    local exclude_set = execute_state[4]

    if structural_changes ~= __structural_changes then
        __lua_error('structural changes are prohibited during iteration')
    end

    while chunk_stack_size > 0 do
        local chunk = chunk_stack[chunk_stack_size]

        chunk_stack[chunk_stack_size] = nil
        chunk_stack_size = chunk_stack_size - 1

        local chunk_child_list = chunk.__child_list
        local chunk_child_count = chunk.__child_count

        if exclude_set then
            for i = 1, chunk_child_count do
                local chunk_child = chunk_child_list[i]
                local chunk_child_fragment = chunk_child.__fragment

                if not exclude_set[chunk_child_fragment] then
                    chunk_stack_size = chunk_stack_size + 1
                    chunk_stack[chunk_stack_size] = chunk_child
                end
            end
        else
            __lua_table_move(
                chunk_child_list, 1, chunk_child_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + chunk_child_count
        end

        local chunk_entity_list = chunk.__entity_list
        local chunk_entity_count = chunk.__entity_count

        if chunk_entity_count > 0 then
            execute_state[3] = chunk_stack_size
            return chunk, chunk_entity_list, chunk_entity_count
        end
    end

    __release_table(__table_pool_tag.chunk_stack, chunk_stack, true)
    __release_table(__table_pool_tag.execute_state, execute_state, true)
end

---
---
---
---
---

local __TAG = __acquire_id()

local __NAME = __acquire_id()
local __DEFAULT = __acquire_id()
local __CONSTRUCT = __acquire_id()

local __INCLUDES = __acquire_id()
local __EXCLUDES = __acquire_id()

local __ON_SET = __acquire_id()
local __ON_ASSIGN = __acquire_id()
local __ON_INSERT = __acquire_id()
local __ON_REMOVE = __acquire_id()

local __PHASE = __acquire_id()
local __AFTER = __acquire_id()

local __QUERY = __acquire_id()
local __EXECUTE = __acquire_id()

local __PROLOGUE = __acquire_id()
local __EPILOGUE = __acquire_id()

local __DESTROY_POLICY = __acquire_id()
local __DESTROY_POLICY_DESTROY_ENTITY = __acquire_id()
local __DESTROY_POLICY_REMOVE_FRAGMENT = __acquire_id()

---
---
---
---
---

local __safe_tbls = {
    ---@type table<evolved.fragment, integer>
    __EMPTY_FRAGMENT_SET = __lua_setmetatable({}, {
        __newindex = function() __lua_error('attempt to modify empty fragment set') end
    }),

    ---@type evolved.fragment[]
    __EMPTY_FRAGMENT_LIST = __lua_setmetatable({}, {
        __newindex = function() __lua_error('attempt to modify empty fragment list') end
    }),

    ---@type evolved.component[]
    __EMPTY_COMPONENT_LIST = __lua_setmetatable({}, {
        __newindex = function() __lua_error('attempt to modify empty component list') end
    }),

    ---@type evolved.component[]
    __EMPTY_COMPONENT_STORAGE = __lua_setmetatable({}, {
        __newindex = function() __lua_error('attempt to modify empty component storage') end
    }),
}

---
---
---
---
---

local __evolved_id

local __evolved_pack
local __evolved_unpack

local __evolved_defer
local __evolved_commit

local __evolved_is_alive
local __evolved_is_empty

local __evolved_get
local __evolved_has
local __evolved_has_all
local __evolved_has_any

local __evolved_set
local __evolved_assign
local __evolved_insert
local __evolved_remove
local __evolved_clear
local __evolved_destroy

local __evolved_multi_set
local __evolved_multi_assign
local __evolved_multi_insert
local __evolved_multi_remove

local __evolved_batch_set
local __evolved_batch_assign
local __evolved_batch_insert
local __evolved_batch_remove
local __evolved_batch_clear
local __evolved_batch_destroy

local __evolved_batch_multi_set
local __evolved_batch_multi_assign
local __evolved_batch_multi_insert
local __evolved_batch_multi_remove

local __evolved_chunk
local __evolved_select
local __evolved_entities
local __evolved_fragments

local __evolved_each
local __evolved_execute

local __evolved_process

local __evolved_spawn_at
local __evolved_spawn_with

local __evolved_entity
local __evolved_fragment
local __evolved_query
local __evolved_phase
local __evolved_system

---
---
---
---
---

---@param id evolved.id
---@return string
---@nodiscard
local function __id_name(id)
    ---@type string?
    local id_name = __evolved_get(id, __NAME)

    if id_name then
        return id_name
    end

    local id_index, id_version = __evolved_unpack(id)
    return __lua_string_format('$%d#%d:%d', id, id_index, id_version)
end

---@param ... any component arguments
---@return evolved.component
---@nodiscard
local function __component_list(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return {}
    end

    local argument_list = __lua_table_new(argument_count, 0)

    for argument_index = 1, argument_count do
        argument_list[argument_index] = __lua_select(argument_index, ...)
    end

    return argument_list
end

---@param fragment evolved.fragment
---@return evolved.storage
---@nodiscard
---@diagnostic disable-next-line: unused-local
local function __component_storage(fragment)
    return {}
end

---@param ... any component arguments
---@return evolved.component
---@nodiscard
local function __component_construct(fragment, ...)
    ---@type evolved.default, evolved.construct
    local default, construct = __evolved_get(fragment, __DEFAULT, __CONSTRUCT)

    local component = ...

    if construct then
        component = construct(...)
    end

    if component == nil then
        component = default
    end

    return component == nil and true or component
end

---@param fragment evolved.fragment
---@param trace fun(chunk: evolved.chunk, ...: any): boolean
---@param ... any additional trace arguments
local function __trace_fragment_chunks(fragment, trace, ...)
    ---@type evolved.chunk[]
    local chunk_stack = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_stack_size = 0

    do
        local major_chunks = __major_chunks[fragment]
        local major_chunk_list = major_chunks and major_chunks.__item_list
        local major_chunk_count = major_chunks and major_chunks.__item_count or 0

        if major_chunk_count > 0 then
            __lua_table_move(
                major_chunk_list, 1, major_chunk_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + major_chunk_count
        end
    end

    while chunk_stack_size > 0 do
        local chunk = chunk_stack[chunk_stack_size]

        chunk_stack[chunk_stack_size] = nil
        chunk_stack_size = chunk_stack_size - 1

        if trace(chunk, ...) then
            local chunk_child_list = chunk.__child_list
            local chunk_child_count = chunk.__child_count

            __lua_table_move(
                chunk_child_list, 1, chunk_child_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + chunk_child_count
        end
    end

    __release_table(__table_pool_tag.chunk_stack, chunk_stack, true)
end

---
---
---
---
---

local __debug_mts = {
    chunk_mt = {}, ---@type metatable

    chunk_fragment_set_mt = {}, ---@type metatable
    chunk_fragment_list_mt = {}, ---@type metatable

    chunk_component_indices_mt = {}, ---@type metatable
    chunk_component_storages_mt = {}, ---@type metatable
    chunk_component_fragments_mt = {}, ---@type metatable
}

---@param self evolved.chunk
function __debug_mts.chunk_mt.__tostring(self)
    local items = {} ---@type string[]

    for fragment_index, fragment in __lua_ipairs(self.__fragment_list) do
        items[fragment_index] = __id_name(fragment)
    end

    return __lua_string_format('<%s>', __lua_table_concat(items, ', '))
end

---@param self table<evolved.fragment, integer>
function __debug_mts.chunk_fragment_set_mt.__tostring(self)
    local items = {} ---@type string[]

    for fragment, fragment_index in __lua_pairs(self) do
        items[fragment_index] = __lua_string_format('(%s -> %d)',
            __id_name(fragment), fragment_index)
    end

    return __lua_string_format('{%s}', __lua_table_concat(items, ', '))
end

---@param self evolved.fragment[]
function __debug_mts.chunk_fragment_list_mt.__tostring(self)
    local items = {} ---@type string[]

    for fragment_index, fragment in __lua_ipairs(self) do
        items[fragment_index] = __lua_string_format('(%d -> %s)',
            fragment_index, __id_name(fragment))
    end

    return __lua_string_format('[%s]', __lua_table_concat(items, ', '))
end

---@param self table<evolved.fragment, integer>
function __debug_mts.chunk_component_indices_mt.__tostring(self)
    local items = {} ---@type string[]

    for component_fragment, component_index in __lua_pairs(self) do
        items[component_index] = __lua_string_format('(%s -> %d)',
            __id_name(component_fragment), component_index)
    end

    return __lua_string_format('{%s}', __lua_table_concat(items, ', '))
end

---@param self evolved.storage[]
function __debug_mts.chunk_component_storages_mt.__tostring(self)
    local items = {} ---@type string[]

    for component_index, component_storage in __lua_ipairs(self) do
        items[component_index] = __lua_string_format('(%d -> #%d)',
            component_index, #component_storage)
    end

    return __lua_string_format('[%s]', __lua_table_concat(items, ', '))
end

---@param self evolved.fragment[]
function __debug_mts.chunk_component_fragments_mt.__tostring(self)
    local items = {} ---@type string[]

    for component_index, component_fragment in __lua_ipairs(self) do
        items[component_index] = __lua_string_format('(%d -> %s)',
            component_index, __id_name(component_fragment))
    end

    return __lua_string_format('[%s]', __lua_table_concat(items, ', '))
end

---
---
---
---
---

---@param chunk_parent? evolved.chunk
---@param chunk_fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __new_chunk(chunk_parent, chunk_fragment)
    ---@type table<evolved.fragment, integer>
    local chunk_fragment_set = __lua_setmetatable({}, __debug_mts.chunk_fragment_set_mt)

    ---@type evolved.fragment[]
    local chunk_fragment_list = __lua_setmetatable({}, __debug_mts.chunk_fragment_list_mt)

    ---@type integer
    local chunk_fragment_count = 0

    ---@type integer
    local chunk_component_count = 0

    ---@type table<evolved.fragment, integer>
    local chunk_component_indices = __lua_setmetatable({}, __debug_mts.chunk_component_indices_mt)

    ---@type evolved.storage[]
    local chunk_component_storages = __lua_setmetatable({}, __debug_mts.chunk_component_storages_mt)

    ---@type evolved.fragment[]
    local chunk_component_fragments = __lua_setmetatable({}, __debug_mts.chunk_component_fragments_mt)

    local has_defaults_or_constructs = (chunk_parent and chunk_parent.__has_defaults_or_constructs)
        or __evolved_has_any(chunk_fragment, __DEFAULT, __CONSTRUCT)

    local has_set_or_assign_hooks = (chunk_parent and chunk_parent.__has_set_or_assign_hooks)
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_ASSIGN)

    local has_set_or_insert_hooks = (chunk_parent and chunk_parent.__has_set_or_insert_hooks)
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_INSERT)

    local has_remove_hooks = (chunk_parent and chunk_parent.__has_remove_hooks)
        or __evolved_has(chunk_fragment, __ON_REMOVE)

    ---@type evolved.chunk
    local chunk = __lua_setmetatable({
        __parent = chunk_parent,
        __child_list = {},
        __child_count = 0,
        __entity_list = {},
        __entity_count = 0,
        __fragment = chunk_fragment,
        __fragment_set = chunk_fragment_set,
        __fragment_list = chunk_fragment_list,
        __fragment_count = chunk_fragment_count,
        __component_count = chunk_component_count,
        __component_indices = chunk_component_indices,
        __component_storages = chunk_component_storages,
        __component_fragments = chunk_component_fragments,
        __with_fragment_edges = {},
        __without_fragment_edges = {},
        __has_defaults_or_constructs = has_defaults_or_constructs,
        __has_set_or_assign_hooks = has_set_or_assign_hooks,
        __has_set_or_insert_hooks = has_set_or_insert_hooks,
        __has_remove_hooks = has_remove_hooks,
    }, __debug_mts.chunk_mt)

    if chunk_parent then
        local parent_fragment_list = chunk_parent.__fragment_list
        local parent_fragment_count = chunk_parent.__fragment_count

        for parent_fragment_index = 1, parent_fragment_count do
            local parent_fragment = parent_fragment_list[parent_fragment_index]

            chunk_fragment_count = chunk_fragment_count + 1
            chunk_fragment_set[parent_fragment] = chunk_fragment_count
            chunk_fragment_list[chunk_fragment_count] = parent_fragment

            if not __evolved_has(parent_fragment, __TAG) then
                chunk_component_count = chunk_component_count + 1
                local component_storage = __component_storage(parent_fragment)
                local component_storage_index = chunk_component_count
                chunk_component_indices[parent_fragment] = component_storage_index
                chunk_component_storages[component_storage_index] = component_storage
                chunk_component_fragments[component_storage_index] = parent_fragment
            end
        end

        local child_chunk_index = chunk_parent.__child_count + 1
        chunk_parent.__child_list[child_chunk_index] = chunk
        chunk_parent.__child_count = child_chunk_index

        chunk_parent.__with_fragment_edges[chunk_fragment] = chunk
        chunk.__without_fragment_edges[chunk_fragment] = chunk_parent
    end

    do
        chunk_fragment_count = chunk_fragment_count + 1
        chunk_fragment_set[chunk_fragment] = chunk_fragment_count
        chunk_fragment_list[chunk_fragment_count] = chunk_fragment

        if not __evolved_has(chunk_fragment, __TAG) then
            chunk_component_count = chunk_component_count + 1
            local component_storage = __component_storage(chunk_fragment)
            local component_storage_index = chunk_component_count
            chunk_component_indices[chunk_fragment] = component_storage_index
            chunk_component_storages[component_storage_index] = component_storage
            chunk_component_fragments[component_storage_index] = chunk_fragment
        end
    end

    do
        chunk.__fragment_count = chunk_fragment_count
        chunk.__component_count = chunk_component_count
    end

    if not chunk_parent then
        local root_fragment = chunk_fragment
        __root_chunks[root_fragment] = chunk
    end

    do
        local major_fragment = chunk_fragment
        local major_chunks = __major_chunks[major_fragment]

        if not major_chunks then
            major_chunks = __assoc_list_new(4)
            __major_chunks[major_fragment] = major_chunks
        end

        __assoc_list_insert(major_chunks, chunk)
    end

    for i = 1, chunk_fragment_count do
        local minor_fragment = chunk_fragment_list[i]
        local minor_chunks = __minor_chunks[minor_fragment]

        if not minor_chunks then
            minor_chunks = __assoc_list_new(4)
            __minor_chunks[minor_fragment] = minor_chunks
        end

        __assoc_list_insert(minor_chunks, chunk)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __chunk_with_fragment(chunk, fragment)
    if not chunk then
        local root_chunk = __root_chunks[fragment]
        return root_chunk or __new_chunk(nil, fragment)
    end

    if chunk.__fragment_set[fragment] then
        return chunk
    end

    do
        local with_fragment_edge = chunk.__with_fragment_edges[fragment]
        if with_fragment_edge then return with_fragment_edge end
    end

    if fragment < chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_with_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__with_fragment_edges[fragment] = sibling_chunk
        sibling_chunk.__without_fragment_edges[fragment] = chunk

        return sibling_chunk
    end

    return __new_chunk(chunk, fragment)
end

---@param chunk? evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return evolved.chunk?
---@nodiscard
local function __chunk_with_fragment_list(chunk, fragment_list, fragment_count)
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
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return chunk
    end

    for i = 1, fragment_count do
        local fragment = __lua_select(i, ...)
        chunk = __chunk_without_fragment(chunk, fragment)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment_list(chunk, fragment_list, fragment_count)
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

---@param ... evolved.fragment fragments
---@return evolved.chunk?
---@nodiscard
local function __chunk_fragments(...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local root_fragment = ...
    local chunk = __root_chunks[root_fragment]
        or __chunk_with_fragment(nil, root_fragment)

    for i = 2, fragment_count do
        local child_fragment = __lua_select(i, ...)
        chunk = chunk.__with_fragment_edges[child_fragment]
            or __chunk_with_fragment(chunk, child_fragment)
    end

    return chunk
end

---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return evolved.chunk?
---@nodiscard
local function __chunk_fragment_list(fragment_list, fragment_count)
    if fragment_count == 0 then
        return
    end

    local root_fragment = fragment_list[1]
    local chunk = __root_chunks[root_fragment]
        or __chunk_with_fragment(nil, root_fragment)

    for i = 2, fragment_count do
        local child_fragment = fragment_list[i]
        chunk = chunk.__with_fragment_edges[child_fragment]
            or __chunk_with_fragment(chunk, child_fragment)
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
    return chunk.__fragment_set[fragment] ~= nil
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
local function __chunk_has_all_fragments(chunk, ...)
    local fragment_set = chunk.__fragment_set

    for i = 1, __lua_select('#', ...) do
        local fragment = __lua_select(i, ...)
        if not fragment_set[fragment] then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return boolean
---@nodiscard
local function __chunk_has_all_fragment_list(chunk, fragment_list, fragment_count)
    local fragment_set = chunk.__fragment_set

    for i = 1, fragment_count do
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

    for i = 1, __lua_select('#', ...) do
        local fragment = __lua_select(i, ...)
        if fragment_set[fragment] then
            return true
        end
    end

    return false
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return boolean
---@nodiscard
local function __chunk_has_any_fragment_list(chunk, fragment_list, fragment_count)
    local fragment_set = chunk.__fragment_set

    for i = 1, fragment_count do
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
    local fragment_count = __lua_select('#', ...)

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

    if fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        local i1, i2, i3, i4 = indices[f1], indices[f2], indices[f3], indices[f4]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place],
            i3 and storages[i3][place],
            i4 and storages[i4][place]
    end

    do
        local f1, f2, f3, f4 = ...
        local i1, i2, i3, i4 = indices[f1], indices[f2], indices[f3], indices[f4]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place],
            i3 and storages[i3][place],
            i4 and storages[i4][place],
            __chunk_get_components(chunk, place, __lua_select(5, ...))
    end
end

---
---
---
---
---

local __defer
local __commit

local __defer_set
local __defer_assign
local __defer_insert
local __defer_remove
local __defer_clear
local __defer_destroy

local __defer_multi_set
local __defer_multi_assign
local __defer_multi_insert
local __defer_multi_remove

local __defer_batch_set
local __defer_batch_assign
local __defer_batch_insert
local __defer_batch_remove
local __defer_batch_clear
local __defer_batch_destroy

local __defer_batch_multi_set
local __defer_batch_multi_assign
local __defer_batch_multi_insert
local __defer_batch_multi_remove

local __defer_spawn_entity_at
local __defer_spawn_entity_with

local __defer_call_hook

---
---
---
---
---

---@param chunk evolved.chunk
---@param place integer
local function __detach_entity(chunk, place)
    local entity_list = chunk.__entity_list
    local entity_count = chunk.__entity_count

    local component_count = chunk.__component_count
    local component_storages = chunk.__component_storages

    if place == entity_count then
        entity_list[place] = nil

        for component_index = 1, component_count do
            local component_storage = component_storages[component_index]
            component_storage[place] = nil
        end
    else
        local last_entity = entity_list[entity_count]
        local last_entity_index = last_entity % 0x100000
        __entity_places[last_entity_index] = place

        entity_list[place] = last_entity
        entity_list[entity_count] = nil

        for component_index = 1, component_count do
            local component_storage = component_storages[component_index]
            local last_component = component_storage[entity_count]
            component_storage[place] = last_component
            component_storage[entity_count] = nil
        end
    end

    chunk.__entity_count = entity_count - 1
end

---@param chunk evolved.chunk
local function __detach_all_entities(chunk)
    local entity_list = chunk.__entity_list

    local component_count = chunk.__component_count
    local component_storages = chunk.__component_storages

    __lua_table_clear(entity_list)

    for component_index = 1, component_count do
        __lua_table_clear(component_storages[component_index])
    end

    chunk.__entity_count = 0
end

---@param entity evolved.entity
---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@param component_list evolved.component[]
local function __spawn_entity_at(entity, chunk, fragment_list, fragment_count, component_list)
    if __defer_depth <= 0 then
        __lua_error('spawn entity operations should be deferred')
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    local chunk_component_count = chunk.__component_count
    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages
    local chunk_component_fragments = chunk.__component_fragments

    local chunk_has_defaults_or_constructs = chunk.__has_defaults_or_constructs
    local chunk_has_set_or_insert_hooks = chunk.__has_set_or_insert_hooks

    local place = chunk_entity_count + 1
    chunk.__entity_count = place

    chunk_entity_list[place] = entity

    do
        local entity_index = entity % 0x100000

        __entity_chunks[entity_index] = chunk
        __entity_places[entity_index] = place

        __structural_changes = __structural_changes + 1
    end

    if chunk_has_defaults_or_constructs then
        for component_index = 1, chunk_component_count do
            local fragment = chunk_component_fragments[component_index]
            local component_storage = chunk_component_storages[component_index]

            local new_component = __evolved_get(fragment, __DEFAULT)

            if new_component == nil then
                new_component = true
            end

            component_storage[place] = new_component
        end
    else
        for component_index = 1, chunk_component_count do
            local component_storage = chunk_component_storages[component_index]

            local new_component = true

            component_storage[place] = new_component
        end
    end

    if chunk_has_defaults_or_constructs then
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            local component_index = chunk_component_indices[fragment]

            if component_index then
                local component_storage = chunk_component_storages[component_index]

                local new_component = component_list[i]

                if new_component == nil then
                    new_component = __evolved_get(fragment, __DEFAULT)
                end

                if new_component == nil then
                    new_component = true
                end

                component_storage[place] = new_component
            end
        end
    else
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            local component_index = chunk_component_indices[fragment]

            if component_index then
                local component_storage = chunk_component_storages[component_index]

                local new_component = component_list[i]

                if new_component == nil then
                    new_component = true
                end

                component_storage[place] = new_component
            end
        end
    end

    if chunk_has_set_or_insert_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert = __evolved_get(fragment, __ON_SET, __ON_INSERT)

            local component_index = chunk_component_indices[fragment]

            if component_index then
                local component_storage = chunk_component_storages[component_index]

                local new_component = component_storage[place]

                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment)
                end
            end
        end
    end
end

---@param entity evolved.entity
---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@param component_list evolved.component[]
local function __spawn_entity_with(entity, chunk, fragment_list, fragment_count, component_list)
    if __defer_depth <= 0 then
        __lua_error('spawn entity operations should be deferred')
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    local chunk_has_defaults_or_constructs = chunk.__has_defaults_or_constructs
    local chunk_has_set_or_insert_hooks = chunk.__has_set_or_insert_hooks

    local place = chunk_entity_count + 1
    chunk.__entity_count = place

    chunk_entity_list[place] = entity

    do
        local entity_index = entity % 0x100000

        __entity_chunks[entity_index] = chunk
        __entity_places[entity_index] = place

        __structural_changes = __structural_changes + 1
    end

    if chunk_has_defaults_or_constructs then
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            local component_index = chunk_component_indices[fragment]

            if component_index then
                local component_storage = chunk_component_storages[component_index]

                local new_component = component_list[i]

                if new_component == nil then
                    new_component = __evolved_get(fragment, __DEFAULT)
                end

                if new_component == nil then
                    new_component = true
                end

                component_storage[place] = new_component
            end
        end
    else
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            local component_index = chunk_component_indices[fragment]

            if component_index then
                local component_storage = chunk_component_storages[component_index]

                local new_component = component_list[i]

                if new_component == nil then
                    new_component = true
                end

                component_storage[place] = new_component
            end
        end
    end

    if chunk_has_set_or_insert_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert = __evolved_get(fragment, __ON_SET, __ON_INSERT)

            local component_index = chunk_component_indices[fragment]

            if component_index then
                local component_storage = chunk_component_storages[component_index]

                local new_component = component_storage[place]

                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment)
                end
            end
        end
    end
end

---
---
---
---
---

local __chunk_assign
local __chunk_insert
local __chunk_remove
local __chunk_clear
local __chunk_destroy

local __chunk_multi_set
local __chunk_multi_assign
local __chunk_multi_insert
local __chunk_multi_remove

---
---
---
---
---

---@param fragment evolved.fragment
---@param policy evolved.id
---@return integer purged_count
local function __purge_fragment(fragment, policy)
    if __defer_depth <= 0 then
        __lua_error('purge operations should be deferred')
    end

    local purged_count = 0

    local minor_chunks = __minor_chunks[fragment]
    local minor_chunk_list = minor_chunks and minor_chunks.__item_list
    local minor_chunk_count = minor_chunks and minor_chunks.__item_count or 0

    if policy == __DESTROY_POLICY_DESTROY_ENTITY then
        for minor_chunk_index = minor_chunk_count, 1, -1 do
            local minor_chunk = minor_chunk_list[minor_chunk_index]
            purged_count = purged_count + __chunk_destroy(minor_chunk)
        end
    elseif policy == __DESTROY_POLICY_REMOVE_FRAGMENT then
        for minor_chunk_index = minor_chunk_count, 1, -1 do
            local minor_chunk = minor_chunk_list[minor_chunk_index]
            purged_count = purged_count + __chunk_remove(minor_chunk, fragment)
        end
    else
        __lua_print(__lua_string_format('| evolved.lua | unknown DESTROY_POLICY policy (%s) on (%s)',
            __id_name(policy), __id_name(fragment)))
    end

    return purged_count
end

---@param fragments evolved.fragment[]
---@param policies evolved.id[]
---@param count integer
---@return integer purged_count
local function __purge_fragments(fragments, policies, count)
    if __defer_depth <= 0 then
        __lua_error('purge operations should be deferred')
    end

    local purged_count = 0

    for index = 1, count do
        local fragment, policy = fragments[index], policies[index]

        if policy == __DESTROY_POLICY_DESTROY_ENTITY then
            purged_count = purged_count + __purge_fragment(fragment, __DESTROY_POLICY_DESTROY_ENTITY)
        elseif policy == __DESTROY_POLICY_REMOVE_FRAGMENT then
            purged_count = purged_count + __purge_fragment(fragment, __DESTROY_POLICY_REMOVE_FRAGMENT)
        else
            __lua_print(__lua_string_format('| evolved.lua | unknown DESTROY_POLICY policy (%s) on (%s)',
                __id_name(policy), __id_name(fragment)))
        end
    end

    return purged_count
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
__chunk_assign = function(chunk, fragment, ...)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    if not chunk.__fragment_set[fragment] then
        return 0
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    if chunk_entity_count == 0 then
        return 0
    end

    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    ---@type evolved.default?, evolved.construct?
    local fragment_default, fragment_construct

    ---@type evolved.set_hook?, evolved.assign_hook?
    local fragment_on_set, fragment_on_assign

    do
        if chunk.__has_defaults_or_constructs then
            fragment_default, fragment_construct = __evolved_get(fragment, __DEFAULT, __CONSTRUCT)
        end

        if chunk.__has_set_or_assign_hooks then
            fragment_on_set, fragment_on_assign = __evolved_get(fragment, __ON_SET, __ON_ASSIGN)
        end
    end

    if fragment_on_set or fragment_on_assign then
        local component_index = chunk_component_indices[fragment]

        if component_index then
            local component_storage = chunk_component_storages[component_index]

            if fragment_default ~= nil or fragment_construct then
                for place = 1, chunk_entity_count do
                    local entity = chunk_entity_list[place]
                    local old_component = component_storage[place]

                    local new_component = ...
                    if fragment_construct then new_component = fragment_construct(...) end
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    component_storage[place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                    end
                end
            else
                local new_component = ...
                if new_component == nil then new_component = true end

                for place = 1, chunk_entity_count do
                    local entity = chunk_entity_list[place]
                    local old_component = component_storage[place]

                    component_storage[place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                    end
                end
            end
        else
            for place = 1, chunk_entity_count do
                local entity = chunk_entity_list[place]

                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_assign then
                    __defer_call_hook(fragment_on_assign, entity, fragment)
                end
            end
        end
    else
        local component_index = chunk_component_indices[fragment]

        if component_index then
            local component_storage = chunk_component_storages[component_index]

            if fragment_default ~= nil or fragment_construct then
                for place = 1, chunk_entity_count do
                    local new_component = ...
                    if fragment_construct then new_component = fragment_construct(...) end
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end
                    component_storage[place] = new_component
                end
            else
                local new_component = ...
                if new_component == nil then new_component = true end

                for place = 1, chunk_entity_count do
                    component_storage[place] = new_component
                end
            end
        else
            -- nothing
        end
    end

    return chunk_entity_count
end

---@param old_chunk evolved.chunk
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer inserted_count
---@nodiscard
__chunk_insert = function(old_chunk, fragment, ...)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if not new_chunk or old_chunk == new_chunk then
        return 0
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return 0
    end

    local old_component_count = old_chunk.__component_count
    local old_component_storages = old_chunk.__component_storages
    local old_component_fragments = old_chunk.__component_fragments

    local new_entity_list = new_chunk.__entity_list
    local new_entity_count = new_chunk.__entity_count

    local new_component_indices = new_chunk.__component_indices
    local new_component_storages = new_chunk.__component_storages

    ---@type evolved.default?, evolved.construct?
    local fragment_default, fragment_construct

    ---@type evolved.set_hook?, evolved.insert_hook?
    local fragment_on_set, fragment_on_insert

    do
        if new_chunk.__has_defaults_or_constructs then
            fragment_default, fragment_construct = __evolved_get(fragment, __DEFAULT, __CONSTRUCT)
        end

        if new_chunk.__has_set_or_insert_hooks then
            fragment_on_set, fragment_on_insert = __evolved_get(fragment, __ON_SET, __ON_INSERT)
        end
    end

    if new_entity_count == 0 then
        old_chunk.__entity_list, new_chunk.__entity_list =
            new_entity_list, old_entity_list

        old_entity_list, new_entity_list =
            new_entity_list, old_entity_list

        for old_ci = 1, old_component_count do
            local old_f = old_component_fragments[old_ci]
            local new_ci = new_component_indices[old_f]
            old_component_storages[old_ci], new_component_storages[new_ci] =
                new_component_storages[new_ci], old_component_storages[old_ci]
        end

        new_chunk.__entity_count = old_entity_count
    else
        __lua_table_move(
            old_entity_list, 1, old_entity_count,
            new_entity_count + 1, new_entity_list)

        for old_ci = 1, old_component_count do
            local old_f = old_component_fragments[old_ci]
            local old_cs = old_component_storages[old_ci]
            local new_ci = new_component_indices[old_f]
            local new_cs = new_component_storages[new_ci]
            __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
        end

        new_chunk.__entity_count = new_entity_count + old_entity_count
    end

    do
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
            local entity = new_entity_list[new_place]
            local entity_index = entity % 0x100000
            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_place
        end

        __detach_all_entities(old_chunk)
    end

    if fragment_on_set or fragment_on_insert then
        local new_component_index = new_component_indices[fragment]

        if new_component_index then
            local new_component_storage = new_component_storages[new_component_index]

            if fragment_default ~= nil or fragment_construct then
                for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                    local entity = new_entity_list[new_place]

                    local new_component = ...
                    if fragment_construct then new_component = fragment_construct(...) end
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                end
            else
                local new_component = ...
                if new_component == nil then new_component = true end

                for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                    local entity = new_entity_list[new_place]

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                end
            end
        else
            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                local entity = new_entity_list[new_place]

                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment)
                end
            end
        end
    else
        local new_component_index = new_component_indices[fragment]

        if new_component_index then
            local new_component_storage = new_component_storages[new_component_index]

            if fragment_default ~= nil or fragment_construct then
                for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                    local new_component = ...
                    if fragment_construct then new_component = fragment_construct(...) end
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end
                    new_component_storage[new_place] = new_component
                end
            else
                local new_component = ...
                if new_component == nil then new_component = true end

                for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                    new_component_storage[new_place] = new_component
                end
            end
        else
            -- nothing
        end
    end

    __structural_changes = __structural_changes + 1
    return old_entity_count
end

---@param old_chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return integer removed_count
---@nodiscard
__chunk_remove = function(old_chunk, ...)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return 0
    end

    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return 0
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return 0
    end

    local old_fragment_set = old_chunk.__fragment_set
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages

    if old_chunk.__has_remove_hooks then
        ---@type table<evolved.fragment, boolean>
        local removed_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            local fragment = __lua_select(i, ...)

            if not removed_set[fragment] and old_fragment_set[fragment] then
                removed_set[fragment] = true

                ---@type evolved.remove_hook?
                local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                if fragment_on_remove then
                    local old_component_index = old_component_indices[fragment]

                    if old_component_index then
                        local old_component_storage = old_component_storages[old_component_index]

                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            local old_component = old_component_storage[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                        end
                    else
                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment)
                        end
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, removed_set)
    end

    if new_chunk then
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_count = new_chunk.__component_count
        local new_component_storages = new_chunk.__component_storages
        local new_component_fragments = new_chunk.__component_fragments

        if new_entity_count == 0 then
            old_chunk.__entity_list, new_chunk.__entity_list =
                new_entity_list, old_entity_list

            old_entity_list, new_entity_list =
                new_entity_list, old_entity_list

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local old_ci = old_component_indices[new_f]
                old_component_storages[old_ci], new_component_storages[new_ci] =
                    new_component_storages[new_ci], old_component_storages[old_ci]
            end

            new_chunk.__entity_count = old_entity_count
        else
            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]
                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]
                __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
            end

            new_chunk.__entity_count = new_entity_count + old_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                local entity = new_entity_list[new_place]
                local entity_index = entity % 0x100000
                entity_chunks[entity_index] = new_chunk
                entity_places[entity_index] = new_place
            end

            __detach_all_entities(old_chunk)
        end
    else
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for old_place = 1, old_entity_count do
            local entity = old_entity_list[old_place]
            local entity_index = entity % 0x100000
            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil
        end

        __detach_all_entities(old_chunk)
    end

    __structural_changes = __structural_changes + 1
    return old_entity_count
end

---@param chunk evolved.chunk
---@return integer cleared_count
---@nodiscard
__chunk_clear = function(chunk)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    if chunk_entity_count == 0 then
        return 0
    end

    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    if chunk.__has_remove_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.remove_hook?
            local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

            if fragment_on_remove then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        local old_component = component_storage[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                    end
                else
                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment)
                    end
                end
            end
        end
    end

    do
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for place = 1, chunk_entity_count do
            local entity = chunk_entity_list[place]
            local entity_index = entity % 0x100000
            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil
        end

        __detach_all_entities(chunk)
    end

    __structural_changes = __structural_changes + 1
    return chunk_entity_count
end

---@param chunk evolved.chunk
---@return integer destroyed_count
---@nodiscard
__chunk_destroy = function(chunk)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    if chunk_entity_count == 0 then
        return 0
    end

    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    if chunk.__has_remove_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.remove_hook?
            local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

            if fragment_on_remove then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        local old_component = component_storage[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                    end
                else
                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment)
                    end
                end
            end
        end
    end

    do
        ---@type integer
        local purging_count = 0

        ---@type evolved.fragment[]
        local purging_fragments = __acquire_table(__table_pool_tag.fragment_list)

        ---@type evolved.fragment[]
        local purging_policies = __acquire_table(__table_pool_tag.fragment_list)

        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for place = 1, chunk_entity_count do
            local entity = chunk_entity_list[place]
            local entity_index = entity % 0x100000

            if __minor_chunks[entity] then
                purging_count = purging_count + 1
                purging_fragments[purging_count] = entity
                purging_policies[purging_count] = __chunk_get_components(chunk, place, __DESTROY_POLICY)
                    or __DESTROY_POLICY_REMOVE_FRAGMENT
            end

            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil

            __release_id(entity)
        end

        __detach_all_entities(chunk)

        if purging_count > 0 then
            __purge_fragments(purging_fragments, purging_policies, purging_count)
        end

        __release_table(__table_pool_tag.fragment_list, purging_fragments)
        __release_table(__table_pool_tag.fragment_list, purging_policies)
    end

    __structural_changes = __structural_changes + 1
    return chunk_entity_count
end

---@param old_chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@return integer set_count
__chunk_multi_set = function(old_chunk, fragments, fragment_count, components)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    if fragment_count == 0 then
        return 0
    end

    local new_chunk = __chunk_with_fragment_list(old_chunk, fragments, fragment_count)

    if not new_chunk then
        return 0
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return 0
    end

    local old_fragment_set = old_chunk.__fragment_set
    local old_component_count = old_chunk.__component_count
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages
    local old_component_fragments = old_chunk.__component_fragments

    local old_chunk_has_defaults_or_constructs = old_chunk.__has_defaults_or_constructs
    local old_chunk_has_set_or_assign_hooks = old_chunk.__has_set_or_assign_hooks

    if old_chunk == new_chunk then
        for i = 1, fragment_count do
            local fragment = fragments[i]

            ---@type evolved.default?
            local fragment_default

            ---@type evolved.set_hook?, evolved.assign_hook?
            local fragment_on_set, fragment_on_assign

            do
                if old_chunk_has_defaults_or_constructs then
                    fragment_default = __evolved_get(fragment, __DEFAULT)
                end

                if old_chunk_has_set_or_assign_hooks then
                    fragment_on_set, fragment_on_assign = __evolved_get(fragment, __ON_SET, __ON_ASSIGN)
                end
            end

            if fragment_on_set or fragment_on_assign then
                local old_component_index = old_component_indices[fragment]

                if old_component_index then
                    local old_component_storage = old_component_storages[old_component_index]

                    local new_component = components[i]
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    for place = 1, old_entity_count do
                        local entity = old_entity_list[place]
                        local old_component = old_component_storage[place]

                        old_component_storage[place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                        end
                    end
                else
                    for place = 1, old_entity_count do
                        local entity = old_entity_list[place]

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment)
                        end
                    end
                end
            else
                local old_component_index = old_component_indices[fragment]

                if old_component_index then
                    local old_component_storage = old_component_storages[old_component_index]

                    local new_component = components[i]
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    for place = 1, old_entity_count do
                        old_component_storage[place] = new_component
                    end
                else
                    -- nothing
                end
            end
        end
    else
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_chunk_has_defaults_or_constructs = new_chunk.__has_defaults_or_constructs
        local new_chunk_has_set_or_assign_hooks = new_chunk.__has_set_or_assign_hooks
        local new_chunk_has_set_or_insert_hooks = new_chunk.__has_set_or_insert_hooks

        if new_entity_count == 0 then
            old_chunk.__entity_list, new_chunk.__entity_list =
                new_entity_list, old_entity_list

            old_entity_list, new_entity_list =
                new_entity_list, old_entity_list

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local new_ci = new_component_indices[old_f]
                old_component_storages[old_ci], new_component_storages[new_ci] =
                    new_component_storages[new_ci], old_component_storages[old_ci]
            end

            new_chunk.__entity_count = old_entity_count
        else
            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
            end

            new_chunk.__entity_count = new_entity_count + old_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                local entity = new_entity_list[new_place]
                local entity_index = entity % 0x100000
                entity_chunks[entity_index] = new_chunk
                entity_places[entity_index] = new_place
            end

            __detach_all_entities(old_chunk)
        end

        ---@type table<evolved.fragment, boolean>
        local inserted_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            local fragment = fragments[i]

            if inserted_set[fragment] or old_fragment_set[fragment] then
                ---@type evolved.default?
                local fragment_default

                ---@type evolved.set_hook?, evolved.assign_hook?
                local fragment_on_set, fragment_on_assign

                do
                    if new_chunk_has_defaults_or_constructs then
                        fragment_default = __evolved_get(fragment, __DEFAULT)
                    end

                    if new_chunk_has_set_or_assign_hooks then
                        fragment_on_set, fragment_on_assign = __evolved_get(fragment, __ON_SET, __ON_ASSIGN)
                    end
                end

                if fragment_on_set or fragment_on_assign then
                    local new_component_index = new_component_indices[fragment]
                    if new_component_index then
                        local new_component_storage = new_component_storages[new_component_index]

                        local new_component = components[i]
                        if new_component == nil then new_component = fragment_default end
                        if new_component == nil then new_component = true end

                        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                            local entity = new_entity_list[new_place]
                            local old_component = new_component_storage[new_place]

                            new_component_storage[new_place] = new_component

                            if fragment_on_set then
                                __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                            end

                            if fragment_on_assign then
                                __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                            end
                        end
                    else
                        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                            local entity = new_entity_list[new_place]

                            if fragment_on_set then
                                __defer_call_hook(fragment_on_set, entity, fragment)
                            end

                            if fragment_on_assign then
                                __defer_call_hook(fragment_on_assign, entity, fragment)
                            end
                        end
                    end
                else
                    local new_component_index = new_component_indices[fragment]

                    if new_component_index then
                        local new_component_storage = new_component_storages[new_component_index]

                        local new_component = components[i]
                        if new_component == nil then new_component = fragment_default end
                        if new_component == nil then new_component = true end

                        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                            new_component_storage[new_place] = new_component
                        end
                    else
                        -- nothing
                    end
                end
            else
                inserted_set[fragment] = true

                ---@type evolved.default?
                local fragment_default

                ---@type evolved.set_hook?, evolved.insert_hook?
                local fragment_on_set, fragment_on_insert

                do
                    if new_chunk_has_defaults_or_constructs then
                        fragment_default = __evolved_get(fragment, __DEFAULT)
                    end

                    if new_chunk_has_set_or_insert_hooks then
                        fragment_on_set, fragment_on_insert = __evolved_get(fragment, __ON_SET, __ON_INSERT)
                    end
                end

                if fragment_on_set or fragment_on_insert then
                    local new_component_index = new_component_indices[fragment]

                    if new_component_index then
                        local new_component_storage = new_component_storages[new_component_index]

                        local new_component = components[i]
                        if new_component == nil then new_component = fragment_default end
                        if new_component == nil then new_component = true end

                        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                            local entity = new_entity_list[new_place]

                            new_component_storage[new_place] = new_component

                            if fragment_on_set then
                                __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                            end

                            if fragment_on_insert then
                                __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                            end
                        end
                    else
                        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                            local entity = new_entity_list[new_place]

                            if fragment_on_set then
                                __defer_call_hook(fragment_on_set, entity, fragment)
                            end

                            if fragment_on_insert then
                                __defer_call_hook(fragment_on_insert, entity, fragment)
                            end
                        end
                    end
                else
                    local new_component_index = new_component_indices[fragment]

                    if new_component_index then
                        local new_component_storage = new_component_storages[new_component_index]

                        local new_component = components[i]
                        if new_component == nil then new_component = fragment_default end
                        if new_component == nil then new_component = true end

                        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                            new_component_storage[new_place] = new_component
                        end
                    else
                        -- nothing
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, inserted_set)

        __structural_changes = __structural_changes + 1
    end

    return old_entity_count
end

---@param chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@return integer assigned_count
__chunk_multi_assign = function(chunk, fragments, fragment_count, components)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    if fragment_count == 0 then
        return 0
    end

    if not __chunk_has_any_fragment_list(chunk, fragments, fragment_count) then
        return 0
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    if chunk_entity_count == 0 then
        return 0
    end

    local chunk_fragment_set = chunk.__fragment_set
    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    local chunk_has_defaults_or_constructs = chunk.__has_defaults_or_constructs
    local chunk_has_set_or_assign_hooks = chunk.__has_set_or_assign_hooks

    for i = 1, fragment_count do
        local fragment = fragments[i]

        if chunk_fragment_set[fragment] then
            ---@type evolved.default?
            local fragment_default

            ---@type evolved.set_hook?, evolved.assign_hook?
            local fragment_on_set, fragment_on_assign

            do
                if chunk_has_defaults_or_constructs then
                    fragment_default = __evolved_get(fragment, __DEFAULT)
                end

                if chunk_has_set_or_assign_hooks then
                    fragment_on_set, fragment_on_assign = __evolved_get(fragment, __ON_SET, __ON_ASSIGN)
                end
            end

            if fragment_on_set or fragment_on_assign then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    local new_component = components[i]
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        local old_component = component_storage[place]

                        component_storage[place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                        end
                    end
                else
                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment)
                        end
                    end
                end
            else
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    local new_component = components[i]
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    for place = 1, chunk_entity_count do
                        component_storage[place] = new_component
                    end
                else
                    -- nothing
                end
            end
        end
    end

    return chunk_entity_count
end

---@param old_chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@return integer inserted_count
__chunk_multi_insert = function(old_chunk, fragments, fragment_count, components)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    if fragment_count == 0 then
        return 0
    end

    local new_chunk = __chunk_with_fragment_list(old_chunk, fragments, fragment_count)

    if not new_chunk or old_chunk == new_chunk then
        return 0
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return 0
    end

    local old_fragment_set = old_chunk.__fragment_set
    local old_component_count = old_chunk.__component_count
    local old_component_storages = old_chunk.__component_storages
    local old_component_fragments = old_chunk.__component_fragments

    local new_entity_list = new_chunk.__entity_list
    local new_entity_count = new_chunk.__entity_count

    local new_component_indices = new_chunk.__component_indices
    local new_component_storages = new_chunk.__component_storages

    local new_chunk_has_defaults_or_constructs = new_chunk.__has_defaults_or_constructs
    local new_chunk_has_set_or_insert_hooks = new_chunk.__has_set_or_insert_hooks

    if new_entity_count == 0 then
        old_chunk.__entity_list, new_chunk.__entity_list =
            new_entity_list, old_entity_list

        old_entity_list, new_entity_list =
            new_entity_list, old_entity_list

        for old_ci = 1, old_component_count do
            local old_f = old_component_fragments[old_ci]
            local new_ci = new_component_indices[old_f]
            old_component_storages[old_ci], new_component_storages[new_ci] =
                new_component_storages[new_ci], old_component_storages[old_ci]
        end

        new_chunk.__entity_count = old_entity_count
    else
        __lua_table_move(
            old_entity_list, 1, old_entity_count,
            new_entity_count + 1, new_entity_list)

        for old_ci = 1, old_component_count do
            local old_f = old_component_fragments[old_ci]
            local old_cs = old_component_storages[old_ci]
            local new_ci = new_component_indices[old_f]
            local new_cs = new_component_storages[new_ci]
            __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
        end

        new_chunk.__entity_count = new_entity_count + old_entity_count
    end

    do
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
            local entity = new_entity_list[new_place]
            local entity_index = entity % 0x100000
            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_place
        end

        __detach_all_entities(old_chunk)
    end

    ---@type table<evolved.fragment, boolean>
    local inserted_set = __acquire_table(__table_pool_tag.fragment_set)

    for i = 1, fragment_count do
        local fragment = fragments[i]

        if not inserted_set[fragment] and not old_fragment_set[fragment] then
            inserted_set[fragment] = true

            ---@type evolved.default?
            local fragment_default

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert

            do
                if new_chunk_has_defaults_or_constructs then
                    fragment_default = __evolved_get(fragment, __DEFAULT)
                end

                if new_chunk_has_set_or_insert_hooks then
                    fragment_on_set, fragment_on_insert = __evolved_get(fragment, __ON_SET, __ON_INSERT)
                end
            end

            if fragment_on_set or fragment_on_insert then
                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    local new_component = components[i]
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                        local entity = new_entity_list[new_place]

                        new_component_storage[new_place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                        end

                        if fragment_on_insert then
                            __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                        end
                    end
                else
                    for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                        local entity = new_entity_list[new_place]

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment)
                        end

                        if fragment_on_insert then
                            __defer_call_hook(fragment_on_insert, entity, fragment)
                        end
                    end
                end
            else
                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    local new_component = components[i]
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                        new_component_storage[new_place] = new_component
                    end
                else
                    -- nothing
                end
            end
        end
    end

    __release_table(__table_pool_tag.fragment_set, inserted_set)

    __structural_changes = __structural_changes + 1
    return old_entity_count
end

---@param old_chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@return integer removed_count
__chunk_multi_remove = function(old_chunk, fragments, fragment_count)
    if __defer_depth <= 0 then
        __lua_error('batched chunk operations should be deferred')
    end

    if fragment_count == 0 then
        return 0
    end

    local new_chunk = __chunk_without_fragment_list(old_chunk, fragments, fragment_count)

    if old_chunk == new_chunk then
        return 0
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return 0
    end

    local old_fragment_set = old_chunk.__fragment_set
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages

    if old_chunk.__has_remove_hooks then
        ---@type table<evolved.fragment, boolean>
        local removed_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            local fragment = fragments[i]

            if not removed_set[fragment] and old_fragment_set[fragment] then
                removed_set[fragment] = true

                ---@type evolved.remove_hook?
                local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                if fragment_on_remove then
                    local old_component_index = old_component_indices[fragment]

                    if old_component_index then
                        local old_component_storage = old_component_storages[old_component_index]

                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            local old_component = old_component_storage[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                        end
                    else
                        for place = 1, old_entity_count do
                            local entity = old_entity_list[place]
                            __defer_call_hook(fragment_on_remove, entity, fragment)
                        end
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, removed_set)
    end

    if new_chunk then
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_count = new_chunk.__component_count
        local new_component_storages = new_chunk.__component_storages
        local new_component_fragments = new_chunk.__component_fragments

        if new_entity_count == 0 then
            old_chunk.__entity_list, new_chunk.__entity_list =
                new_entity_list, old_entity_list

            old_entity_list, new_entity_list =
                new_entity_list, old_entity_list

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local old_ci = old_component_indices[new_f]
                old_component_storages[old_ci], new_component_storages[new_ci] =
                    new_component_storages[new_ci], old_component_storages[old_ci]
            end

            new_chunk.__entity_count = old_entity_count
        else
            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]
                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]
                __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
            end

            new_chunk.__entity_count = new_entity_count + old_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                local entity = new_entity_list[new_place]
                local entity_index = entity % 0x100000
                entity_chunks[entity_index] = new_chunk
                entity_places[entity_index] = new_place
            end

            __detach_all_entities(old_chunk)
        end
    else
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for old_place = 1, old_entity_count do
            local entity = old_entity_list[old_place]
            local entity_index = entity % 0x100000
            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil
        end

        __detach_all_entities(old_chunk)
    end

    __structural_changes = __structural_changes + 1
    return old_entity_count
end

---
---
---
---
---

---@param system evolved.system
local function __system_process(system)
    local query, execute, prologue, epilogue = __evolved_get(system,
        __QUERY, __EXECUTE, __PROLOGUE, __EPILOGUE)

    if prologue then
        local success, result = __lua_pcall(prologue)

        if not success then
            __lua_error(__lua_string_format('system prologue failed: %s', result))
        end
    end

    if query and execute then
        __defer()
        do
            for chunk, entity_list, entity_count in __evolved_execute(query) do
                local success, result = __lua_pcall(execute, chunk, entity_list, entity_count)

                if not success then
                    __commit()
                    __lua_error(__lua_string_format('system execution failed: %s', result))
                end
            end
        end
        __commit()
    end

    if epilogue then
        local success, result = __lua_pcall(epilogue)

        if not success then
            __lua_error(__lua_string_format('system epilogue failed: %s', result))
        end
    end
end

---@param phase evolved.phase
local function __phase_process(phase)
    local phase_systems = __phase_systems[phase]
    local phase_system_set = phase_systems and phase_systems.__item_set
    local phase_system_list = phase_systems and phase_systems.__item_list
    local phase_system_count = phase_systems and phase_systems.__item_count or 0

    ---@type evolved.system[]
    local sorted_system_list = __acquire_table(__table_pool_tag.system_list)
    local sorted_system_count = 0

    ---@type integer[]
    local sorting_marks = __acquire_table(__table_pool_tag.sorting_marks)

    ---@type evolved.system[]
    local sorting_stack = __acquire_table(__table_pool_tag.sorting_stack)
    local sorting_stack_size = phase_system_count

    for phase_system_index = 1, phase_system_count do
        sorting_marks[phase_system_index] = 0
        local phase_system_rev_index = phase_system_count - phase_system_index + 1
        sorting_stack[phase_system_index] = phase_system_list[phase_system_rev_index]
    end

    while sorting_stack_size > 0 do
        local system = sorting_stack[sorting_stack_size]

        local system_mark_index = phase_system_set[system]
        local system_mark = sorting_marks[system_mark_index]

        if not system_mark then
            -- the system has already been added to the sorted list
            sorting_stack[sorting_stack_size] = nil
            sorting_stack_size = sorting_stack_size - 1
        elseif system_mark == 0 then
            sorting_marks[system_mark_index] = 1

            local dependencies = __system_dependencies[system]
            local dependency_list = dependencies and dependencies.__item_list
            local dependency_count = dependencies and dependencies.__item_count or 0

            for dependency_index = dependency_count, 1, -1 do
                local dependency = dependency_list[dependency_index]
                local dependency_mark_index = phase_system_set[dependency]

                if not dependency_mark_index then
                    -- the dependency is not from this phase
                else
                    local dependency_mark = sorting_marks[dependency_mark_index]

                    if not dependency_mark then
                        -- the dependency has already been added to the sorted list
                    elseif dependency_mark == 0 then
                        sorting_stack_size = sorting_stack_size + 1
                        sorting_stack[sorting_stack_size] = dependency
                    elseif dependency_mark == 1 then
                        local sorting_cycle_path = '' .. dependency

                        for cycled_system_index = sorting_stack_size, 1, -1 do
                            local cycled_system = sorting_stack[cycled_system_index]

                            local cycled_system_mark_index = phase_system_set[cycled_system]
                            local cycled_system_mark = sorting_marks[cycled_system_mark_index]

                            if cycled_system_mark == 1 then
                                sorting_cycle_path = __lua_string_format('%s -> %s',
                                    sorting_cycle_path, cycled_system)

                                if cycled_system == dependency then
                                    break
                                end
                            end
                        end

                        __lua_error(__lua_string_format('system sorting failed: cyclic dependency detected (%s)',
                            sorting_cycle_path))
                    end
                end
            end
        elseif system_mark == 1 then
            sorting_marks[system_mark_index] = nil

            sorted_system_count = sorted_system_count + 1
            sorted_system_list[sorted_system_count] = system

            sorting_stack[sorting_stack_size] = nil
            sorting_stack_size = sorting_stack_size - 1
        end
    end

    for sorted_system_index = 1, sorted_system_count do
        local system = sorted_system_list[sorted_system_index]
        __system_process(system)
    end

    __release_table(__table_pool_tag.system_list, sorted_system_list)
    __release_table(__table_pool_tag.sorting_marks, sorting_marks, true)
    __release_table(__table_pool_tag.sorting_stack, sorting_stack, true)
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

    batch_multi_set = 17,
    batch_multi_assign = 18,
    batch_multi_insert = 19,
    batch_multi_remove = 20,

    spawn_entity_at = 21,
    spawn_entity_with = 22,

    call_hook = 23,

    __count = 23,
}

---@type table<evolved.defer_op, fun(bytes: any[], index: integer): integer>
local __defer_ops = __lua_table_new(__defer_op.__count, 0)

---@return boolean started
__defer = function()
    __defer_depth = __defer_depth + 1
    return __defer_depth == 1
end

---@return boolean committed
__commit = function()
    if __defer_depth <= 0 then
        __lua_error('unbalanced defer/commit')
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
    __defer_bytecode = __acquire_table(__table_pool_tag.bytecode)

    local bytecode_index = 1
    while bytecode_index <= length do
        local op = __defer_ops[bytecode[bytecode_index]]
        bytecode_index = bytecode_index + op(bytecode, bytecode_index + 1) + 1
    end

    __release_table(__table_pool_tag.bytecode, bytecode, true)
    return true
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
__defer_set = function(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.set
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 5] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
        for i = 5, argument_count do
            bytecode[length + 4 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 4 + argument_count
end

__defer_ops[__defer_op.set] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragment = bytes[index + 1]
    local argument_count = bytes[index + 2]

    if argument_count == 0 then
        __evolved_set(entity, fragment)
    elseif argument_count == 1 then
        local a1 = bytes[index + 3]
        __evolved_set(entity, fragment, a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 3], bytes[index + 4]
        __evolved_set(entity, fragment, a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_set(entity, fragment, a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_set(entity, fragment, a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_set(entity, fragment, a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 7, index + 2 + argument_count))
    end

    return 3 + argument_count
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
__defer_assign = function(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.assign
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 5] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
        for i = 5, argument_count do
            bytecode[length + 4 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 4 + argument_count
end

__defer_ops[__defer_op.assign] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragment = bytes[index + 1]
    local argument_count = bytes[index + 2]

    if argument_count == 0 then
        __evolved_assign(entity, fragment)
    elseif argument_count == 1 then
        local a1 = bytes[index + 3]
        __evolved_assign(entity, fragment, a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 3], bytes[index + 4]
        __evolved_assign(entity, fragment, a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_assign(entity, fragment, a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_assign(entity, fragment, a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_assign(entity, fragment, a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 7, index + 2 + argument_count))
    end

    return 3 + argument_count
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
__defer_insert = function(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.insert
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 5] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
        for i = 5, argument_count do
            bytecode[length + 4 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 4 + argument_count
end

__defer_ops[__defer_op.insert] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragment = bytes[index + 1]
    local argument_count = bytes[index + 2]

    if argument_count == 0 then
        __evolved_insert(entity, fragment)
    elseif argument_count == 1 then
        local a1 = bytes[index + 3]
        __evolved_insert(entity, fragment, a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 3], bytes[index + 4]
        __evolved_insert(entity, fragment, a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_insert(entity, fragment, a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_insert(entity, fragment, a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_insert(entity, fragment, a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 7, index + 2 + argument_count))
    end

    return 3 + argument_count
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
__defer_remove = function(entity, ...)
    local fragment_count = __lua_select('#', ...)
    if fragment_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.remove
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_count

    if fragment_count == 0 then
        -- nothing
    elseif fragment_count == 1 then
        local f1 = ...
        bytecode[length + 4] = f1
    elseif fragment_count == 2 then
        local f1, f2 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
    elseif fragment_count == 3 then
        local f1, f2, f3 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
    elseif fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
        bytecode[length + 7] = f4
    else
        local f1, f2, f3, f4 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
        bytecode[length + 7] = f4
        for i = 5, fragment_count do
            bytecode[length + 3 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 3 + fragment_count
end

__defer_ops[__defer_op.remove] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragment_count = bytes[index + 1]

    if fragment_count == 0 then
        -- nothing
    elseif fragment_count == 1 then
        local f1 = bytes[index + 2]
        __evolved_remove(entity, f1)
    elseif fragment_count == 2 then
        local f1, f2 = bytes[index + 2], bytes[index + 3]
        __evolved_remove(entity, f1, f2)
    elseif fragment_count == 3 then
        local f1, f2, f3 = bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_remove(entity, f1, f2, f3)
    elseif fragment_count == 4 then
        local f1, f2, f3, f4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_remove(entity, f1, f2, f3, f4)
    else
        local f1, f2, f3, f4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_remove(entity, f1, f2, f3, f4,
            __lua_table_unpack(bytes, index + 6, index + 1 + fragment_count))
    end

    return 2 + fragment_count
end

---@param entity evolved.entity
__defer_clear = function(entity)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.clear
    bytecode[length + 2] = entity

    __defer_length = length + 2
end

__defer_ops[__defer_op.clear] = function(bytes, index)
    local entity = bytes[index + 0]
    __evolved_clear(entity)
    return 1
end

---@param entity evolved.entity
__defer_destroy = function(entity)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.destroy
    bytecode[length + 2] = entity

    __defer_length = length + 2
end

__defer_ops[__defer_op.destroy] = function(bytes, index)
    local entity = bytes[index + 0]
    __evolved_destroy(entity)
    return 1
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_multi_set = function(entity, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_set
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

__defer_ops[__defer_op.multi_set] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragments = bytes[index + 1]
    local components = bytes[index + 2]
    __evolved_multi_set(entity, fragments, components)
    __release_table(__table_pool_tag.fragment_list, fragments)
    __release_table(__table_pool_tag.component_list, components)
    return 3
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_multi_assign = function(entity, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_assign
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

__defer_ops[__defer_op.multi_assign] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragments = bytes[index + 1]
    local components = bytes[index + 2]
    __evolved_multi_assign(entity, fragments, components)
    __release_table(__table_pool_tag.fragment_list, fragments)
    __release_table(__table_pool_tag.component_list, components)
    return 3
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_multi_insert = function(entity, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_insert
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

__defer_ops[__defer_op.multi_insert] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragments = bytes[index + 1]
    local components = bytes[index + 2]
    __evolved_multi_insert(entity, fragments, components)
    __release_table(__table_pool_tag.fragment_list, fragments)
    __release_table(__table_pool_tag.component_list, components)
    return 3
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param fragment_count integer
__defer_multi_remove = function(entity, fragments, fragment_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_remove
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list

    __defer_length = length + 3
end

__defer_ops[__defer_op.multi_remove] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragments = bytes[index + 1]
    __evolved_multi_remove(entity, fragments)
    __release_table(__table_pool_tag.fragment_list, fragments)
    return 2
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
__defer_batch_set = function(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.batch_set
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 5] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
        for i = 5, argument_count do
            bytecode[length + 4 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 4 + argument_count
end

__defer_ops[__defer_op.batch_set] = function(bytes, index)
    local query = bytes[index + 0]
    local fragment = bytes[index + 1]
    local argument_count = bytes[index + 2]

    if argument_count == 0 then
        __evolved_batch_set(query, fragment)
    elseif argument_count == 1 then
        local a1 = bytes[index + 3]
        __evolved_batch_set(query, fragment, a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 3], bytes[index + 4]
        __evolved_batch_set(query, fragment, a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_batch_set(query, fragment, a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_batch_set(query, fragment, a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_batch_set(query, fragment, a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 7, index + 2 + argument_count))
    end

    return 3 + argument_count
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
__defer_batch_assign = function(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.batch_assign
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 5] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
        for i = 5, argument_count do
            bytecode[length + 4 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 4 + argument_count
end

__defer_ops[__defer_op.batch_assign] = function(bytes, index)
    local query = bytes[index + 0]
    local fragment = bytes[index + 1]
    local argument_count = bytes[index + 2]

    if argument_count == 0 then
        __evolved_batch_assign(query, fragment)
    elseif argument_count == 1 then
        local a1 = bytes[index + 3]
        __evolved_batch_assign(query, fragment, a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 3], bytes[index + 4]
        __evolved_batch_assign(query, fragment, a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_batch_assign(query, fragment, a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_batch_assign(query, fragment, a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_batch_assign(query, fragment, a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 7, index + 2 + argument_count))
    end

    return 3 + argument_count
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
__defer_batch_insert = function(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.batch_insert
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 5] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 5] = a1
        bytecode[length + 6] = a2
        bytecode[length + 7] = a3
        bytecode[length + 8] = a4
        for i = 5, argument_count do
            bytecode[length + 4 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 4 + argument_count
end

__defer_ops[__defer_op.batch_insert] = function(bytes, index)
    local query = bytes[index + 0]
    local fragment = bytes[index + 1]
    local argument_count = bytes[index + 2]

    if argument_count == 0 then
        __evolved_batch_insert(query, fragment)
    elseif argument_count == 1 then
        local a1 = bytes[index + 3]
        __evolved_batch_insert(query, fragment, a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 3], bytes[index + 4]
        __evolved_batch_insert(query, fragment, a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_batch_insert(query, fragment, a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_batch_insert(query, fragment, a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6]
        __evolved_batch_insert(query, fragment, a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 7, index + 2 + argument_count))
    end

    return 3 + argument_count
end

---@param query evolved.query
---@param ... evolved.fragment fragments
__defer_batch_remove = function(query, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local fragment_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.batch_remove
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_count

    if fragment_count == 0 then
        -- nothing
    elseif fragment_count == 1 then
        local f1 = ...
        bytecode[length + 4] = f1
    elseif fragment_count == 2 then
        local f1, f2 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
    elseif fragment_count == 3 then
        local f1, f2, f3 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
    elseif fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
        bytecode[length + 7] = f4
    else
        local f1, f2, f3, f4 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
        bytecode[length + 7] = f4
        for i = 5, fragment_count do
            bytecode[length + 3 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 3 + fragment_count
end

__defer_ops[__defer_op.batch_remove] = function(bytes, index)
    local query = bytes[index + 0]
    local fragment_count = bytes[index + 1]

    if fragment_count == 0 then
        -- nothing
    elseif fragment_count == 1 then
        local f1 = bytes[index + 2]
        __evolved_batch_remove(query, f1)
    elseif fragment_count == 2 then
        local f1, f2 = bytes[index + 2], bytes[index + 3]
        __evolved_batch_remove(query, f1, f2)
    elseif fragment_count == 3 then
        local f1, f2, f3 = bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_batch_remove(query, f1, f2, f3)
    elseif fragment_count == 4 then
        local f1, f2, f3, f4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_batch_remove(query, f1, f2, f3, f4)
    else
        local f1, f2, f3, f4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_batch_remove(query, f1, f2, f3, f4,
            __lua_table_unpack(bytes, index + 6, index + 1 + fragment_count))
    end

    return 2 + fragment_count
end

---@param query evolved.query
__defer_batch_clear = function(query)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_clear
    bytecode[length + 2] = query

    __defer_length = length + 2
end

__defer_ops[__defer_op.batch_clear] = function(bytes, index)
    local query = bytes[index + 0]
    __evolved_batch_clear(query)
    return 1
end

---@param query evolved.query
__defer_batch_destroy = function(query)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_destroy
    bytecode[length + 2] = query

    __defer_length = length + 2
end

__defer_ops[__defer_op.batch_destroy] = function(bytes, index)
    local query = bytes[index + 0]
    __evolved_batch_destroy(query)
    return 1
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_batch_multi_set = function(query, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_multi_set
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

__defer_ops[__defer_op.batch_multi_set] = function(bytes, index)
    local query = bytes[index + 0]
    local fragments = bytes[index + 1]
    local components = bytes[index + 2]
    __evolved_batch_multi_set(query, fragments, components)
    __release_table(__table_pool_tag.fragment_list, fragments)
    __release_table(__table_pool_tag.component_list, components)
    return 3
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_batch_multi_assign = function(query, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_multi_assign
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

__defer_ops[__defer_op.batch_multi_assign] = function(bytes, index)
    local query = bytes[index + 0]
    local fragments = bytes[index + 1]
    local components = bytes[index + 2]
    __evolved_batch_multi_assign(query, fragments, components)
    __release_table(__table_pool_tag.fragment_list, fragments)
    __release_table(__table_pool_tag.component_list, components)
    return 3
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_batch_multi_insert = function(query, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_multi_insert
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

__defer_ops[__defer_op.batch_multi_insert] = function(bytes, index)
    local query = bytes[index + 0]
    local fragments = bytes[index + 1]
    local components = bytes[index + 2]
    __evolved_batch_multi_insert(query, fragments, components)
    __release_table(__table_pool_tag.fragment_list, fragments)
    __release_table(__table_pool_tag.component_list, components)
    return 3
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param fragment_count integer
__defer_batch_multi_remove = function(query, fragments, fragment_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_multi_remove
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_list

    __defer_length = length + 3
end

__defer_ops[__defer_op.batch_multi_remove] = function(bytes, index)
    local query = bytes[index + 0]
    local fragments = bytes[index + 1]
    __evolved_batch_multi_remove(query, fragments)
    __release_table(__table_pool_tag.fragment_list, fragments)
    return 2
end

---@param entity evolved.entity
---@param chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_spawn_entity_at = function(entity, chunk, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.spawn_entity_at
    bytecode[length + 2] = entity
    bytecode[length + 3] = chunk
    bytecode[length + 4] = fragment_list
    bytecode[length + 5] = fragment_count
    bytecode[length + 6] = component_list

    __defer_length = length + 6
end

__defer_ops[__defer_op.spawn_entity_at] = function(bytes, index)
    local entity = bytes[index + 0]
    local chunk = bytes[index + 1]
    local fragment_list = bytes[index + 2]
    local fragment_count = bytes[index + 3]
    local component_list = bytes[index + 4]
    __defer()
    do
        __spawn_entity_at(entity, chunk, fragment_list, fragment_count, component_list)
        __release_table(__table_pool_tag.fragment_list, fragment_list)
        __release_table(__table_pool_tag.component_list, component_list)
    end
    __commit()
    return 5
end

---@param entity evolved.entity
---@param chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_spawn_entity_with = function(entity, chunk, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.spawn_entity_with
    bytecode[length + 2] = entity
    bytecode[length + 3] = chunk
    bytecode[length + 4] = fragment_list
    bytecode[length + 5] = fragment_count
    bytecode[length + 6] = component_list

    __defer_length = length + 6
end

__defer_ops[__defer_op.spawn_entity_with] = function(bytes, index)
    local entity = bytes[index + 0]
    local chunk = bytes[index + 1]
    local fragment_list = bytes[index + 2]
    local fragment_count = bytes[index + 3]
    local component_list = bytes[index + 4]
    __defer()
    do
        __spawn_entity_with(entity, chunk, fragment_list, fragment_count, component_list)
        __release_table(__table_pool_tag.fragment_list, fragment_list)
        __release_table(__table_pool_tag.component_list, component_list)
    end
    __commit()
    return 5
end

---@param hook fun(...)
---@param ... any hook arguments
__defer_call_hook = function(hook, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.call_hook
    bytecode[length + 2] = hook
    bytecode[length + 3] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 4] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 4] = a1
        bytecode[length + 5] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 4] = a1
        bytecode[length + 5] = a2
        bytecode[length + 6] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 4] = a1
        bytecode[length + 5] = a2
        bytecode[length + 6] = a3
        bytecode[length + 7] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 4] = a1
        bytecode[length + 5] = a2
        bytecode[length + 6] = a3
        bytecode[length + 7] = a4
        for i = 5, argument_count do
            bytecode[length + 3 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 3 + argument_count
end

__defer_ops[__defer_op.call_hook] = function(bytes, index)
    local hook = bytes[index + 0]
    local argument_count = bytes[index + 1]

    if argument_count == 0 then
        hook()
    elseif argument_count == 1 then
        local a1 = bytes[index + 2]
        hook(a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 2], bytes[index + 3]
        hook(a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 2], bytes[index + 3], bytes[index + 4]
        hook(a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        hook(a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        hook(a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 6, index + 1 + argument_count))
    end

    return 2 + argument_count
end

---
---
---
---
---

---@param fragment evolved.fragment
local function __validate_fragment(fragment)
    local fragment_index = fragment % 0x100000

    if __freelist_ids[fragment_index] ~= fragment then
        __lua_error(__lua_string_format(
            'the fragment (%s) is not alive and cannot be used',
            __id_name(fragment)))
    end
end

---@param ... evolved.fragment fragments
local function __validate_fragments(...)
    for i = 1, __lua_select('#', ...) do
        __validate_fragment(__lua_select(i, ...))
    end
end

---@param fragment_list evolved.fragment[]
---@param fragment_count integer
local function __validate_fragment_list(fragment_list, fragment_count)
    for i = 1, fragment_count do
        __validate_fragment(fragment_list[i])
    end
end

---@param query evolved.query
local function __validate_query(query)
    local query_index = query % 0x100000

    if __freelist_ids[query_index] ~= query then
        __lua_error(__lua_string_format(
            'the query (%s) is not alive and cannot be used',
            __id_name(query)))
    end
end

---@param phase evolved.phase
local function __validate_phase(phase)
    local phase_index = phase % 0x100000

    if __freelist_ids[phase_index] ~= phase then
        __lua_error(__lua_string_format(
            'the phase (%s) is not alive and cannot be used',
            __id_name(phase)))
    end
end

---@param ... evolved.phase phases
local function __validate_phases(...)
    for i = 1, __lua_select('#', ...) do
        __validate_phase(__lua_select(i, ...))
    end
end

---
---
---
---
---

---@param count? integer
---@return evolved.id ... ids
---@nodiscard
__evolved_id = function(count)
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

    if count == 4 then
        return __acquire_id(), __acquire_id(), __acquire_id(), __acquire_id()
    end

    do
        return __acquire_id(), __acquire_id(), __acquire_id(), __acquire_id(),
            __evolved_id(count - 4)
    end
end

---@param index integer
---@param version integer
---@return evolved.id id
---@nodiscard
__evolved_pack = function(index, version)
    if index < 1 or index > 0xFFFFF then
        __lua_error('id index out of range [1;0xFFFFF]')
    end

    if version < 1 or version > 0xFFF then
        __lua_error('id version out of range [1;0xFFF]')
    end

    local shifted_version = version * 0x100000
    return index + shifted_version --[[@as evolved.id]]
end

---@param id evolved.id
---@return integer index
---@return integer version
---@nodiscard
__evolved_unpack = function(id)
    local index = id % 0x100000
    local version = (id - index) / 0x100000
    return index, version
end

---@return boolean started
__evolved_defer = function()
    return __defer()
end

---@return boolean committed
__evolved_commit = function()
    return __commit()
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
__evolved_is_alive = function(entity)
    local entity_index = entity % 0x100000

    return __freelist_ids[entity_index] == entity
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
__evolved_is_empty = function(entity)
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
__evolved_get = function(entity, ...)
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
__evolved_has = function(entity, fragment)
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
__evolved_has_all = function(entity, ...)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false
    end

    local chunk = __entity_chunks[entity_index]

    if not chunk then
        return __lua_select('#', ...) == 0
    end

    return __chunk_has_all_fragments(chunk, ...)
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
__evolved_has_any = function(entity, ...)
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
__evolved_set = function(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_set(entity, fragment, ...)
        return false, true
    end

    if __debug_mode then
        __validate_fragment(fragment)
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    ---@type evolved.set_hook?, evolved.assign_hook?, evolved.insert_hook?
    local fragment_on_set, fragment_on_assign, fragment_on_insert

    if new_chunk.__has_set_or_assign_hooks or new_chunk.__has_set_or_insert_hooks then
        fragment_on_set, fragment_on_assign, fragment_on_insert = __evolved_get(fragment,
            __ON_SET, __ON_ASSIGN, __ON_INSERT)
    end

    __defer()

    if old_chunk == new_chunk then
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        local old_component_index = old_component_indices[fragment]

        if old_component_index then
            local old_component_storage = old_component_storages[old_component_index]

            if old_chunk.__has_defaults_or_constructs then
                local new_component = __component_construct(fragment, ...)

                if fragment_on_set or fragment_on_assign then
                    local old_component = old_component_storage[old_place]

                    old_component_storage[old_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                    end
                else
                    old_component_storage[old_place] = new_component
                end
            else
                local new_component = ...

                if new_component == nil then
                    new_component = true
                end

                if fragment_on_set or fragment_on_assign then
                    local old_component = old_component_storage[old_place]

                    old_component_storage[old_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                    end
                else
                    old_component_storage[old_place] = new_component
                end
            end
        else
            if fragment_on_set then
                __defer_call_hook(fragment_on_set, entity, fragment)
            end

            if fragment_on_assign then
                __defer_call_hook(fragment_on_assign, entity, fragment)
            end
        end
    else
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_place = new_entity_count + 1
        new_chunk.__entity_count = new_place

        new_entity_list[new_place] = entity

        if old_chunk then
            local old_component_count = old_chunk.__component_count
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                new_cs[new_place] = old_cs[old_place]
            end

            __detach_entity(old_chunk, old_place)
        end

        do
            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_place

            __structural_changes = __structural_changes + 1
        end

        do
            local new_component_index = new_component_indices[fragment]

            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]

                if new_chunk.__has_defaults_or_constructs then
                    local new_component = __component_construct(fragment, ...)

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                else
                    local new_component = ...

                    if new_component == nil then
                        new_component = true
                    end

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment)
                end
            end
        end
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return boolean is_assigned
---@return boolean is_deferred
__evolved_assign = function(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_assign(entity, fragment, ...)
        return false, true
    end

    if __debug_mode then
        __validate_fragment(fragment)
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local chunk = entity_chunks[entity_index]
    local place = entity_places[entity_index]

    if not chunk or not chunk.__fragment_set[fragment] then
        return false, false
    end

    ---@type evolved.set_hook?, evolved.assign_hook?
    local fragment_on_set, fragment_on_assign

    if chunk.__has_set_or_assign_hooks then
        fragment_on_set, fragment_on_assign = __evolved_get(fragment,
            __ON_SET, __ON_ASSIGN)
    end

    __defer()

    do
        local component_indices = chunk.__component_indices
        local component_storages = chunk.__component_storages

        local component_index = component_indices[fragment]

        if component_index then
            local component_storage = component_storages[component_index]

            if chunk.__has_defaults_or_constructs then
                local new_component = __component_construct(fragment, ...)

                if fragment_on_set or fragment_on_assign then
                    local old_component = component_storage[place]

                    component_storage[place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                    end
                else
                    component_storage[place] = new_component
                end
            else
                local new_component = ...

                if new_component == nil then
                    new_component = true
                end

                if fragment_on_set or fragment_on_assign then
                    local old_component = component_storage[place]

                    component_storage[place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                    end
                else
                    component_storage[place] = new_component
                end
            end
        else
            if fragment_on_set then
                __defer_call_hook(fragment_on_set, entity, fragment)
            end

            if fragment_on_assign then
                __defer_call_hook(fragment_on_assign, entity, fragment)
            end
        end
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return boolean is_inserted
---@return boolean is_deferred
__evolved_insert = function(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_insert(entity, fragment, ...)
        return false, true
    end

    if __debug_mode then
        __validate_fragment(fragment)
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if not new_chunk or old_chunk == new_chunk then
        return false, false
    end

    ---@type evolved.set_hook?, evolved.insert_hook?
    local fragment_on_set, fragment_on_insert

    if new_chunk.__has_set_or_insert_hooks then
        fragment_on_set, fragment_on_insert = __evolved_get(fragment,
            __ON_SET, __ON_INSERT)
    end

    __defer()

    do
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_place = new_entity_count + 1
        new_chunk.__entity_count = new_place

        new_entity_list[new_place] = entity

        if old_chunk then
            local old_component_count = old_chunk.__component_count
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                new_cs[new_place] = old_cs[old_place]
            end

            __detach_entity(old_chunk, old_place)
        end

        do
            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_place

            __structural_changes = __structural_changes + 1
        end

        do
            local new_component_index = new_component_indices[fragment]

            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]

                if new_chunk.__has_defaults_or_constructs then
                    local new_component = __component_construct(fragment, ...)

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                else
                    local new_component = ...

                    if new_component == nil then
                        new_component = true
                    end

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment)
                end
            end
        end
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean is_removed
---@return boolean is_deferred
__evolved_remove = function(entity, ...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return true, false
    end

    if __defer_depth > 0 then
        __defer_remove(entity, ...)
        return false, true
    end

    if __debug_mode then
        __validate_fragments(...)
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return true, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

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
            ---@type table<evolved.fragment, boolean>
            local removed_set = __acquire_table(__table_pool_tag.fragment_set)

            for i = 1, fragment_count do
                local fragment = __lua_select(i, ...)

                if not removed_set[fragment] and old_fragment_set[fragment] then
                    removed_set[fragment] = true

                    ---@type evolved.remove_hook?
                    local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                    if fragment_on_remove then
                        local old_component_index = old_component_indices[fragment]

                        if old_component_index then
                            local old_component_storage = old_component_storages[old_component_index]
                            local old_component = old_component_storage[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                        else
                            __defer_call_hook(fragment_on_remove, entity, fragment)
                        end
                    end
                end
            end

            __release_table(__table_pool_tag.fragment_set, removed_set)
        end

        if new_chunk then
            local new_entity_list = new_chunk.__entity_list
            local new_entity_count = new_chunk.__entity_count

            local new_component_count = new_chunk.__component_count
            local new_component_storages = new_chunk.__component_storages
            local new_component_fragments = new_chunk.__component_fragments

            local new_place = new_entity_count + 1
            new_chunk.__entity_count = new_place

            new_entity_list[new_place] = entity

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]
                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]
                new_cs[new_place] = old_cs[old_place]
            end
        end

        do
            __detach_entity(old_chunk, old_place)

            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_chunk and new_chunk.__entity_count

            __structural_changes = __structural_changes + 1
        end
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@return boolean is_cleared
---@return boolean is_deferred
__evolved_clear = function(entity)
    if __defer_depth > 0 then
        __defer_clear(entity)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return true, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local chunk = entity_chunks[entity_index]
    local place = entity_places[entity_index]

    __defer()

    do
        if chunk and chunk.__has_remove_hooks then
            local chunk_fragment_list = chunk.__fragment_list
            local chunk_fragment_count = chunk.__fragment_count
            local chunk_component_indices = chunk.__component_indices
            local chunk_component_storages = chunk.__component_storages

            for chunk_fragment_index = 1, chunk_fragment_count do
                local fragment = chunk_fragment_list[chunk_fragment_index]

                ---@type evolved.remove_hook?
                local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                if fragment_on_remove then
                    local component_index = chunk_component_indices[fragment]

                    if component_index then
                        local component_storage = chunk_component_storages[component_index]
                        local old_component = component_storage[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                    else
                        __defer_call_hook(fragment_on_remove, entity, fragment)
                    end
                end
            end
        end

        if chunk then
            __detach_entity(chunk, place)

            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil

            __structural_changes = __structural_changes + 1
        end
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@return boolean is_destroyed
---@return boolean is_deferred
__evolved_destroy = function(entity)
    if __defer_depth > 0 then
        __defer_destroy(entity)
        return false, true
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return true, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local chunk = entity_chunks[entity_index]
    local place = entity_places[entity_index]

    __defer()

    do
        if chunk and chunk.__has_remove_hooks then
            local chunk_fragment_list = chunk.__fragment_list
            local chunk_fragment_count = chunk.__fragment_count
            local chunk_component_indices = chunk.__component_indices
            local chunk_component_storages = chunk.__component_storages

            for chunk_fragment_index = 1, chunk_fragment_count do
                local fragment = chunk_fragment_list[chunk_fragment_index]

                ---@type evolved.remove_hook?
                local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                if fragment_on_remove then
                    local component_index = chunk_component_indices[fragment]

                    if component_index then
                        local component_storage = chunk_component_storages[component_index]
                        local old_component = component_storage[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                    else
                        __defer_call_hook(fragment_on_remove, entity, fragment)
                    end
                end
            end
        end

        do
            local purging_fragment ---@type evolved.fragment?
            local purging_policy ---@type evolved.id?

            if __minor_chunks[entity] then
                purging_fragment = entity
                purging_policy = chunk and __chunk_get_components(chunk, place, __DESTROY_POLICY)
                    or __DESTROY_POLICY_REMOVE_FRAGMENT
            end

            if chunk then
                __detach_entity(chunk, place)

                entity_chunks[entity_index] = nil
                entity_places[entity_index] = nil

                __structural_changes = __structural_changes + 1
            end

            __release_id(entity)

            if purging_fragment then
                __purge_fragment(purging_fragment, purging_policy)
            end
        end
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components? evolved.component[]
---@return boolean is_any_set
---@return boolean is_deferred
__evolved_multi_set = function(entity, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return false, false
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_multi_set(entity, fragments, fragment_count, components, #components)
        return false, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_with_fragment_list(old_chunk, fragments, fragment_count)

    if not new_chunk then
        return false, false
    end

    __defer()

    if old_chunk == new_chunk then
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        local old_chunk_has_defaults_or_constructs = old_chunk.__has_defaults_or_constructs
        local old_chunk_has_set_or_assign_hooks = old_chunk.__has_set_or_assign_hooks

        for i = 1, fragment_count do
            local fragment = fragments[i]

            ---@type evolved.set_hook?, evolved.assign_hook?
            local fragment_on_set, fragment_on_assign

            if old_chunk_has_set_or_assign_hooks then
                fragment_on_set, fragment_on_assign = __evolved_get(fragment, __ON_SET, __ON_ASSIGN)
            end

            local old_component_index = old_component_indices[fragment]

            if old_component_index then
                local old_component_storage = old_component_storages[old_component_index]

                local new_component = components[i]

                if old_chunk_has_defaults_or_constructs and new_component == nil then
                    new_component = __evolved_get(fragment, __DEFAULT)
                end

                if new_component == nil then
                    new_component = true
                end

                if fragment_on_set or fragment_on_assign then
                    local old_component = old_component_storage[old_place]

                    old_component_storage[old_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                    end
                else
                    old_component_storage[old_place] = new_component
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_assign then
                    __defer_call_hook(fragment_on_assign, entity, fragment)
                end
            end
        end
    else
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_chunk_has_defaults_or_constructs = new_chunk.__has_defaults_or_constructs
        local new_chunk_has_set_or_assign_hooks = new_chunk.__has_set_or_assign_hooks
        local new_chunk_has_set_or_insert_hooks = new_chunk.__has_set_or_insert_hooks

        local old_fragment_set = old_chunk and old_chunk.__fragment_set or __safe_tbls.__EMPTY_FRAGMENT_SET

        local new_place = new_entity_count + 1
        new_chunk.__entity_count = new_place

        new_entity_list[new_place] = entity

        if old_chunk then
            local old_component_count = old_chunk.__component_count
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                new_cs[new_place] = old_cs[old_place]
            end

            __detach_entity(old_chunk, old_place)
        end

        do
            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_place

            __structural_changes = __structural_changes + 1
        end

        ---@type table<evolved.fragment, boolean>
        local inserted_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            local fragment = fragments[i]

            if inserted_set[fragment] or old_fragment_set[fragment] then
                ---@type evolved.set_hook?, evolved.assign_hook?
                local fragment_on_set, fragment_on_assign

                if new_chunk_has_set_or_assign_hooks then
                    fragment_on_set, fragment_on_assign = __evolved_get(fragment, __ON_SET, __ON_ASSIGN)
                end

                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    local new_component = components[i]

                    if new_chunk_has_defaults_or_constructs and new_component == nil then
                        new_component = __evolved_get(fragment, __DEFAULT)
                    end

                    if new_component == nil then
                        new_component = true
                    end

                    if fragment_on_set or fragment_on_assign then
                        local old_component = new_component_storage[new_place]

                        new_component_storage[new_place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                        end
                    else
                        new_component_storage[new_place] = new_component
                    end
                else
                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment)
                    end
                end
            else
                inserted_set[fragment] = true

                ---@type evolved.set_hook?, evolved.insert_hook?
                local fragment_on_set, fragment_on_insert

                if new_chunk_has_set_or_insert_hooks then
                    fragment_on_set, fragment_on_insert = __evolved_get(fragment, __ON_SET, __ON_INSERT)
                end

                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    local new_component = components[i]

                    if new_chunk_has_defaults_or_constructs and new_component == nil then
                        new_component = __evolved_get(fragment, __DEFAULT)
                    end

                    if new_component == nil then
                        new_component = true
                    end

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                else
                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment)
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, inserted_set)
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components? evolved.component[]
---@return boolean is_any_assigned
---@return boolean is_deferred
__evolved_multi_assign = function(entity, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return false, false
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_multi_assign(entity, fragments, fragment_count, components, #components)
        return false, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local chunk = entity_chunks[entity_index]
    local place = entity_places[entity_index]

    if not chunk or not __chunk_has_any_fragment_list(chunk, fragments, fragment_count) then
        return false, false
    end

    __defer()

    do
        local chunk_fragment_set = chunk.__fragment_set
        local chunk_component_indices = chunk.__component_indices
        local chunk_component_storages = chunk.__component_storages

        local chunk_has_defaults_or_constructs = chunk.__has_defaults_or_constructs
        local chunk_has_set_or_assign_hooks = chunk.__has_set_or_assign_hooks

        for i = 1, fragment_count do
            local fragment = fragments[i]

            if chunk_fragment_set[fragment] then
                ---@type evolved.set_hook?, evolved.assign_hook?
                local fragment_on_set, fragment_on_assign

                if chunk_has_set_or_assign_hooks then
                    fragment_on_set, fragment_on_assign = __evolved_get(fragment, __ON_SET, __ON_ASSIGN)
                end

                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    local new_component = components[i]

                    if chunk_has_defaults_or_constructs and new_component == nil then
                        new_component = __evolved_get(fragment, __DEFAULT)
                    end

                    if new_component == nil then
                        new_component = true
                    end

                    if fragment_on_set or fragment_on_assign then
                        local old_component = component_storage[place]

                        component_storage[place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                        end
                    else
                        component_storage[place] = new_component
                    end
                else
                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment)
                    end
                end
            end
        end
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components? evolved.component[]
---@return boolean is_any_inserted
---@return boolean is_deferred
__evolved_multi_insert = function(entity, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return false, false
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_multi_insert(entity, fragments, fragment_count, components, #components)
        return false, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return false, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_with_fragment_list(old_chunk, fragments, fragment_count)

    if not new_chunk or old_chunk == new_chunk then
        return false, false
    end

    __defer()

    do
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_chunk_has_defaults_or_constructs = new_chunk.__has_defaults_or_constructs
        local new_chunk_has_set_or_insert_hooks = new_chunk.__has_set_or_insert_hooks

        local old_fragment_set = old_chunk and old_chunk.__fragment_set or __safe_tbls.__EMPTY_FRAGMENT_SET

        local new_place = new_entity_count + 1
        new_chunk.__entity_count = new_place

        new_entity_list[new_place] = entity

        if old_chunk then
            local old_component_count = old_chunk.__component_count
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                new_cs[new_place] = old_cs[old_place]
            end

            __detach_entity(old_chunk, old_place)
        end

        do
            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_place

            __structural_changes = __structural_changes + 1
        end

        ---@type table<evolved.fragment, boolean>
        local inserted_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            local fragment = fragments[i]

            if not inserted_set[fragment] and not old_fragment_set[fragment] then
                inserted_set[fragment] = true

                ---@type evolved.set_hook?, evolved.insert_hook?
                local fragment_on_set, fragment_on_insert

                if new_chunk_has_set_or_insert_hooks then
                    fragment_on_set, fragment_on_insert = __evolved_get(fragment, __ON_SET, __ON_INSERT)
                end

                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    local new_component = components[i]

                    if new_chunk_has_defaults_or_constructs and new_component == nil then
                        new_component = __evolved_get(fragment, __DEFAULT)
                    end

                    if new_component == nil then
                        new_component = true
                    end

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                else
                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment)
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, inserted_set)
    end

    __commit()
    return true, false
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@return boolean is_all_removed
---@return boolean is_deferred
__evolved_multi_remove = function(entity, fragments)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return true, false
    end

    if __defer_depth > 0 then
        __defer_multi_remove(entity, fragments, fragment_count)
        return false, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return true, false
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_without_fragment_list(old_chunk, fragments, fragment_count)

    if old_chunk == new_chunk then
        return true, false
    end

    __defer()

    do
        local old_fragment_set = old_chunk.__fragment_set
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        if old_chunk.__has_remove_hooks then
            ---@type table<evolved.fragment, boolean>
            local removed_set = __acquire_table(__table_pool_tag.fragment_set)

            for i = 1, fragment_count do
                local fragment = fragments[i]

                if not removed_set[fragment] and old_fragment_set[fragment] then
                    removed_set[fragment] = true

                    ---@type evolved.remove_hook?
                    local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                    if fragment_on_remove then
                        local old_component_index = old_component_indices[fragment]

                        if old_component_index then
                            local old_component_storage = old_component_storages[old_component_index]
                            local old_component = old_component_storage[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                        else
                            __defer_call_hook(fragment_on_remove, entity, fragment)
                        end
                    end
                end
            end

            __release_table(__table_pool_tag.fragment_set, removed_set)
        end

        if new_chunk then
            local new_entity_list = new_chunk.__entity_list
            local new_entity_count = new_chunk.__entity_count

            local new_component_count = new_chunk.__component_count
            local new_component_storages = new_chunk.__component_storages
            local new_component_fragments = new_chunk.__component_fragments

            local new_place = new_entity_count + 1
            new_chunk.__entity_count = new_place

            new_entity_list[new_place] = entity

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]
                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]
                new_cs[new_place] = old_cs[old_place]
            end
        end

        do
            __detach_entity(old_chunk, old_place)

            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_chunk and new_chunk.__entity_count

            __structural_changes = __structural_changes + 1
        end
    end

    __commit()
    return true, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer set_count
---@return boolean is_deferred
__evolved_batch_set = function(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_set(query, fragment, ...)
        return 0, true
    end

    if __debug_mode then
        __validate_fragment(fragment)
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local set_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            if __chunk_has_fragment(chunk, fragment) then
                set_count = set_count + __chunk_assign(chunk, fragment, ...)
            else
                set_count = set_count + __chunk_insert(chunk, fragment, ...)
            end
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return set_count, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer assigned_count
---@return boolean is_deferred
__evolved_batch_assign = function(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_assign(query, fragment, ...)
        return 0, true
    end

    if __debug_mode then
        __validate_fragment(fragment)
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local assigned_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            assigned_count = assigned_count + __chunk_assign(chunk, fragment, ...)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return assigned_count, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer inserted_count
---@return boolean is_deferred
__evolved_batch_insert = function(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_insert(query, fragment, ...)
        return 0, true
    end

    if __debug_mode then
        __validate_fragment(fragment)
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local inserted_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            inserted_count = inserted_count + __chunk_insert(chunk, fragment, ...)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return inserted_count, false
end

---@param query evolved.query
---@param ... evolved.fragment fragments
---@return integer removed_count
---@return boolean is_deferred
__evolved_batch_remove = function(query, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return 0, false
    end

    if __defer_depth > 0 then
        __defer_batch_remove(query, ...)
        return 0, true
    end

    if __debug_mode then
        __validate_fragments(...)
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local removed_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            removed_count = removed_count + __chunk_remove(chunk, ...)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return removed_count, false
end

---@param query evolved.query
---@return integer cleared_count
---@return boolean is_deferred
__evolved_batch_clear = function(query)
    if __defer_depth > 0 then
        __defer_batch_clear(query)
        return 0, true
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local cleared_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            cleared_count = cleared_count + __chunk_clear(chunk)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return cleared_count, false
end

---@param query evolved.query
---@return integer destroyed_count
---@return boolean is_deferred
__evolved_batch_destroy = function(query)
    if __defer_depth > 0 then
        __defer_batch_destroy(query)
        return 0, true
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local destroyed_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            destroyed_count = destroyed_count + __chunk_destroy(chunk)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return destroyed_count, false
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param components? evolved.component[]
---@return integer set_count
---@return boolean is_deferred
__evolved_batch_multi_set = function(query, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return 0, false
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_batch_multi_set(query, fragments, fragment_count, components, #components)
        return 0, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local set_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            set_count = set_count + __chunk_multi_set(chunk, fragments, fragment_count, components)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return set_count, false
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param components? evolved.component[]
---@return integer assigned_count
---@return boolean is_deferred
__evolved_batch_multi_assign = function(query, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return 0, false
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_batch_multi_assign(query, fragments, fragment_count, components, #components)
        return 0, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local assigned_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            assigned_count = assigned_count + __chunk_multi_assign(chunk, fragments, fragment_count, components)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return assigned_count, false
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param components? evolved.component[]
---@return integer inserted_count
---@return boolean is_deferred
__evolved_batch_multi_insert = function(query, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return 0, false
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    if __defer_depth > 0 then
        __defer_batch_multi_insert(query, fragments, fragment_count, components, #components)
        return 0, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local inserted_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            inserted_count = inserted_count + __chunk_multi_insert(chunk, fragments, fragment_count, components)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return inserted_count, false
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@return integer removed_count
---@return boolean is_deferred
__evolved_batch_multi_remove = function(query, fragments)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return 0, false
    end

    if __defer_depth > 0 then
        __defer_batch_multi_remove(query, fragments, fragment_count)
        return 0, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    ---@type evolved.chunk[]
    local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_count = 0

    for chunk in __evolved_execute(query) do
        chunk_count = chunk_count + 1
        chunk_list[chunk_count] = chunk
    end

    local removed_count = 0

    __defer()
    do
        for i = 1, chunk_count do
            local chunk = chunk_list[i]
            removed_count = removed_count + __chunk_multi_remove(chunk, fragments, fragment_count)
        end
    end
    __commit()

    __release_table(__table_pool_tag.chunk_stack, chunk_list)
    return removed_count, false
end

---
---
---
---
---

---@param ... evolved.fragment fragments
---@return evolved.chunk? chunk
---@return evolved.entity[]? entity_list
---@return integer? entity_count
---@nodiscard
__evolved_chunk = function(...)
    if __debug_mode then
        __validate_fragments(...)
    end

    local chunk = __chunk_fragments(...)

    if not chunk then
        return
    end

    return chunk, chunk.__entity_list, chunk.__entity_count
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return evolved.storage ... storages
---@nodiscard
__evolved_select = function(chunk, ...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    if __debug_mode then
        __validate_fragments(...)
    end

    local indices = chunk.__component_indices
    local storages = chunk.__component_storages

    local empty_component_storage = __safe_tbls.__EMPTY_COMPONENT_STORAGE

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

    if fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        local i1, i2, i3, i4 = indices[f1], indices[f2], indices[f3], indices[f4]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage,
            i3 and storages[i3] or empty_component_storage,
            i4 and storages[i4] or empty_component_storage
    end

    do
        local f1, f2, f3, f4 = ...
        local i1, i2, i3, i4 = indices[f1], indices[f2], indices[f3], indices[f4]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage,
            i3 and storages[i3] or empty_component_storage,
            i4 and storages[i4] or empty_component_storage,
            __evolved_select(chunk, __lua_select(5, ...))
    end
end

---@param chunk evolved.chunk
---@return evolved.entity[] entity_list
---@return integer entity_count
---@nodiscard
__evolved_entities = function(chunk)
    return chunk.__entity_list, chunk.__entity_count
end

---@param chunk evolved.chunk
---@return evolved.fragment[] fragments
---@return integer fragment_count
---@nodiscard
__evolved_fragments = function(chunk)
    return chunk.__fragment_list, chunk.__fragment_count
end

---@param entity evolved.entity
---@return evolved.each_iterator iterator
---@return evolved.each_state? iterator_state
---@nodiscard
__evolved_each = function(entity)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return __each_iterator
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local chunk = entity_chunks[entity_index]
    local place = entity_places[entity_index]

    if not chunk then
        return __each_iterator
    end

    ---@type evolved.each_state
    local each_state = __acquire_table(__table_pool_tag.each_state)

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
__evolved_execute = function(query)
    if __debug_mode then
        __validate_query(query)
    end

    ---@type evolved.chunk[]
    local chunk_stack = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_stack_size = 0

    local query_includes = __query_sorted_includes[query]
    local query_include_list = query_includes and query_includes.__item_list
    local query_include_count = query_includes and query_includes.__item_count or 0

    local query_excludes = __query_sorted_excludes[query]
    local query_exclude_set = query_excludes and query_excludes.__item_set
    local query_exclude_list = query_excludes and query_excludes.__item_list
    local query_exclude_count = query_excludes and query_excludes.__item_count or 0

    if query_include_count > 0 then
        local major_fragment = query_include_list[query_include_count]

        local major_fragment_chunks = __major_chunks[major_fragment]
        local major_fragment_chunk_list = major_fragment_chunks and major_fragment_chunks.__item_list
        local major_fragment_chunk_count = major_fragment_chunks and major_fragment_chunks.__item_count or 0

        for major_fragment_chunk_index = 1, major_fragment_chunk_count do
            local major_fragment_chunk = major_fragment_chunk_list[major_fragment_chunk_index]

            local is_major_chunk_matched = true

            if is_major_chunk_matched and query_include_count > 1 then
                is_major_chunk_matched = __chunk_has_all_fragment_list(
                    major_fragment_chunk, query_include_list, query_include_count - 1)
            end

            if is_major_chunk_matched and query_exclude_count > 0 then
                is_major_chunk_matched = not __chunk_has_any_fragment_list(
                    major_fragment_chunk, query_exclude_list, query_exclude_count)
            end

            if is_major_chunk_matched then
                chunk_stack_size = chunk_stack_size + 1
                chunk_stack[chunk_stack_size] = major_fragment_chunk
            end
        end
    elseif query_exclude_count > 0 then
        for root_fragment, root_fragment_chunk in __lua_next, __root_chunks do
            if not query_exclude_set[root_fragment] then
                chunk_stack_size = chunk_stack_size + 1
                chunk_stack[chunk_stack_size] = root_fragment_chunk
            end
        end
    else
        for _, root_fragment_chunk in __lua_next, __root_chunks do
            chunk_stack_size = chunk_stack_size + 1
            chunk_stack[chunk_stack_size] = root_fragment_chunk
        end
    end

    ---@type evolved.execute_state
    local execute_state = __acquire_table(__table_pool_tag.execute_state)

    execute_state[1] = __structural_changes
    execute_state[2] = chunk_stack
    execute_state[3] = chunk_stack_size
    execute_state[4] = query_exclude_set

    return __execute_iterator, execute_state
end

---@param ... evolved.phase phases
__evolved_process = function(...)
    local phase_count = __lua_select('#', ...)

    if phase_count == 0 then
        return
    end

    if __debug_mode then
        __validate_phases(...)
    end

    for i = 1, phase_count do
        local phase = __lua_select(i, ...)
        __phase_process(phase)
    end
end

---
---
---
---
---

---@param chunk? evolved.chunk
---@param fragments? evolved.fragment[]
---@param components? evolved.component[]
---@return evolved.entity entity
---@return boolean is_deferred
__evolved_spawn_at = function(chunk, fragments, components)
    if not fragments then
        fragments = __safe_tbls.__EMPTY_FRAGMENT_LIST
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    local fragment_count = #fragments
    local component_count = #components

    local entity = __acquire_id()

    if not chunk then
        return entity, false
    end

    if __defer_depth > 0 then
        __defer_spawn_entity_at(entity, chunk,
            fragments, fragment_count,
            components, component_count)
        return entity, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    __defer()
    do
        __spawn_entity_at(entity, chunk, fragments, fragment_count, components)
    end
    __commit()

    return entity, false
end

---@param fragments? evolved.fragment[]
---@param components? evolved.component[]
---@return evolved.entity entity
---@return boolean is_deferred
__evolved_spawn_with = function(fragments, components)
    if not fragments then
        fragments = __safe_tbls.__EMPTY_FRAGMENT_LIST
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    local fragment_count = #fragments
    local component_count = #components

    local entity, chunk = __acquire_id(), __chunk_fragment_list(fragments, fragment_count)

    if not chunk then
        return entity, false
    end

    if __defer_depth > 0 then
        __defer_spawn_entity_with(entity, chunk,
            fragments, fragment_count,
            components, component_count)
        return entity, true
    end

    if __debug_mode then
        __validate_fragment_list(fragments, fragment_count)
    end

    __defer()
    do
        __spawn_entity_with(entity, chunk, fragments, fragment_count, components)
    end
    __commit()

    return entity, false
end

---
---
---
---
---

---@param yesno boolean
local function __evolved_debug_mode(yesno)
    __debug_mode = yesno
end

local function __evolved_collect_garbage()
end

---
---
---
---
---

---@class (exact) evolved.__entity_builder
---@field package __fragment_list? evolved.fragment[]
---@field package __component_list? evolved.component[]
---@field package __component_count integer

---@class evolved.entity_builder : evolved.__entity_builder
local evolved_entity_builder = {}
evolved_entity_builder.__index = evolved_entity_builder

---@return evolved.entity_builder builder
---@nodiscard
__evolved_entity = function()
    ---@type evolved.__entity_builder
    local builder = {
        __fragment_list = nil,
        __component_list = nil,
        __component_count = 0,
    }
    ---@cast builder evolved.entity_builder
    return __lua_setmetatable(builder, evolved_entity_builder)
end

---@param fragment evolved.fragment
---@param ... any component arguments
---@return evolved.entity_builder builder
function evolved_entity_builder:set(fragment, ...)
    local component = __component_construct(fragment, ...)

    local fragment_list = self.__fragment_list
    local component_list = self.__component_list
    local component_count = self.__component_count

    if component_count == 0 then
        fragment_list = __acquire_table(__table_pool_tag.fragment_list)
        component_list = __acquire_table(__table_pool_tag.component_list)
        self.__fragment_list = fragment_list
        self.__component_list = component_list
    end

    component_count = component_count + 1
    self.__component_count = component_count

    fragment_list[component_count] = fragment
    component_list[component_count] = component

    return self
end

---@return evolved.entity entity
---@return boolean is_deferred
function evolved_entity_builder:build()
    local fragment_list = self.__fragment_list
    local component_list = self.__component_list
    local component_count = self.__component_count

    self.__fragment_list = nil
    self.__component_list = nil
    self.__component_count = 0

    if component_count == 0 then
        return __evolved_id(), false
    end

    local entity, is_deferred = __evolved_spawn_with(fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return entity, is_deferred
end

---
---
---
---
---

---@class (exact) evolved.__fragment_builder
---@field package __tag boolean
---@field package __name? string
---@field package __single? evolved.component
---@field package __default? evolved.component
---@field package __construct? fun(...): evolved.component
---@field package __on_set? evolved.set_hook
---@field package __on_assign? evolved.set_hook
---@field package __on_insert? evolved.set_hook
---@field package __on_remove? evolved.remove_hook
---@field package __destroy_policy? evolved.id

---@class evolved.fragment_builder : evolved.__fragment_builder
local evolved_fragment_builder = {}
evolved_fragment_builder.__index = evolved_fragment_builder

---@return evolved.fragment_builder builder
---@nodiscard
__evolved_fragment = function()
    ---@type evolved.__fragment_builder
    local builder = {
        __tag = false,
        __name = nil,
        __single = nil,
        __default = nil,
        __construct = nil,
        __on_set = nil,
        __on_assign = nil,
        __on_insert = nil,
        __on_remove = nil,
        __destroy_policy = nil,
    }
    ---@cast builder evolved.fragment_builder
    return __lua_setmetatable(builder, evolved_fragment_builder)
end

---@return evolved.fragment_builder builder
function evolved_fragment_builder:tag()
    self.__tag = true
    return self
end

---@param name string
---@return evolved.fragment_builder builder
function evolved_fragment_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.fragment_builder builder
function evolved_fragment_builder:single(single)
    self.__single = single
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

---@param on_set evolved.set_hook
---@return evolved.fragment_builder builder
function evolved_fragment_builder:on_set(on_set)
    self.__on_set = on_set
    return self
end

---@param on_assign evolved.assign_hook
---@return evolved.fragment_builder builder
function evolved_fragment_builder:on_assign(on_assign)
    self.__on_assign = on_assign
    return self
end

---@param on_insert evolved.insert_hook
---@return evolved.fragment_builder builder
function evolved_fragment_builder:on_insert(on_insert)
    self.__on_insert = on_insert
    return self
end

---@param on_remove evolved.remove_hook
---@return evolved.fragment_builder builder
function evolved_fragment_builder:on_remove(on_remove)
    self.__on_remove = on_remove
    return self
end

---@param destroy_policy evolved.id
---@return evolved.fragment_builder builder
function evolved_fragment_builder:destroy_policy(destroy_policy)
    self.__destroy_policy = destroy_policy
    return self
end

---@return evolved.fragment fragment
---@return boolean is_deferred
function evolved_fragment_builder:build()
    local tag = self.__tag
    local name = self.__name
    local single = self.__single
    local default = self.__default
    local construct = self.__construct

    local on_set = self.__on_set
    local on_assign = self.__on_assign
    local on_insert = self.__on_insert
    local on_remove = self.__on_remove
    local destroy_policy = self.__destroy_policy

    self.__tag = false
    self.__name = nil
    self.__single = nil
    self.__default = nil
    self.__construct = nil

    self.__on_set = nil
    self.__on_assign = nil
    self.__on_insert = nil
    self.__on_remove = nil
    self.__destroy_policy = nil

    local fragment = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if tag then
        component_count = component_count + 1
        fragment_list[component_count] = __TAG
        component_list[component_count] = true
    end

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = fragment
        component_list[component_count] = single
    end

    if default ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = __DEFAULT
        component_list[component_count] = default
    end

    if construct then
        component_count = component_count + 1
        fragment_list[component_count] = __CONSTRUCT
        component_list[component_count] = construct
    end

    if on_set then
        component_count = component_count + 1
        fragment_list[component_count] = __ON_SET
        component_list[component_count] = on_set
    end

    if on_assign then
        component_count = component_count + 1
        fragment_list[component_count] = __ON_ASSIGN
        component_list[component_count] = on_assign
    end

    if on_insert then
        component_count = component_count + 1
        fragment_list[component_count] = __ON_INSERT
        component_list[component_count] = on_insert
    end

    if on_remove then
        component_count = component_count + 1
        fragment_list[component_count] = __ON_REMOVE
        component_list[component_count] = on_remove
    end

    if destroy_policy then
        component_count = component_count + 1
        fragment_list[component_count] = __DESTROY_POLICY
        component_list[component_count] = destroy_policy
    end

    local _, is_deferred = __evolved_multi_set(fragment, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return fragment, is_deferred
end

---
---
---
---
---

---@class (exact) evolved.__query_builder
---@field package __name? string
---@field package __single? evolved.component
---@field package __include_list? evolved.fragment[]
---@field package __exclude_list? evolved.fragment[]

---@class evolved.query_builder : evolved.__query_builder
local evolved_query_builder = {}
evolved_query_builder.__index = evolved_query_builder

---@return evolved.query_builder builder
---@nodiscard
__evolved_query = function()
    ---@type evolved.__query_builder
    local builder = {
        __name = nil,
        __single = nil,
        __include_list = nil,
        __exclude_list = nil,
    }
    ---@cast builder evolved.query_builder
    return __lua_setmetatable(builder, evolved_query_builder)
end

---@param name string
---@return evolved.query_builder builder
function evolved_query_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.query_builder builder
function evolved_query_builder:single(single)
    self.__single = single
    return self
end

---@param ... evolved.fragment fragments
---@return evolved.query_builder builder
function evolved_query_builder:include(...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return self
    end

    local include_list = self.__include_list

    if not include_list then
        include_list = __lua_table_new(math.max(4, fragment_count), 0)
        self.__include_list = include_list
    end

    local include_count = #include_list

    for i = 1, fragment_count do
        local fragment = __lua_select(i, ...)
        include_list[include_count + i] = fragment
    end

    return self
end

---@param ... evolved.fragment fragments
---@return evolved.query_builder builder
function evolved_query_builder:exclude(...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return self
    end

    local exclude_list = self.__exclude_list

    if not exclude_list then
        exclude_list = __lua_table_new(math.max(4, fragment_count), 0)
        self.__exclude_list = exclude_list
    end

    local exclude_count = #exclude_list

    for i = 1, fragment_count do
        local fragment = __lua_select(i, ...)
        exclude_list[exclude_count + i] = fragment
    end

    return self
end

---@return evolved.query query
---@return boolean is_deferred
function evolved_query_builder:build()
    local name = self.__name
    local single = self.__single
    local include_list = self.__include_list
    local exclude_list = self.__exclude_list

    self.__name = nil
    self.__single = nil
    self.__include_list = nil
    self.__exclude_list = nil

    local query = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = query
        component_list[component_count] = single
    end

    if include_list then
        component_count = component_count + 1
        fragment_list[component_count] = __INCLUDES
        component_list[component_count] = include_list
    end

    if exclude_list then
        component_count = component_count + 1
        fragment_list[component_count] = __EXCLUDES
        component_list[component_count] = exclude_list
    end

    local _, is_deferred = __evolved_multi_set(query, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return query, is_deferred
end

---
---
---
---
---

---@class (exact) evolved.__phase_builder
---@field package __name? string
---@field package __single? evolved.component

---@class evolved.phase_builder : evolved.__phase_builder
local evolved_phase_builder = {}
evolved_phase_builder.__index = evolved_phase_builder

---@return evolved.phase_builder builder
---@nodiscard
__evolved_phase = function()
    ---@type evolved.__phase_builder
    local builder = {
        __name = nil,
        __single = nil,
    }
    ---@cast builder evolved.phase_builder
    return __lua_setmetatable(builder, evolved_phase_builder)
end

---@param name string
---@return evolved.phase_builder builder
function evolved_phase_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.phase_builder builder
function evolved_phase_builder:single(single)
    self.__single = single
    return self
end

---@return evolved.phase phase
---@return boolean is_deferred
function evolved_phase_builder:build()
    local name = self.__name
    local single = self.__single

    self.__name = nil
    self.__single = nil

    local phase = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = phase
        component_list[component_count] = single
    end

    local _, is_deferred = __evolved_multi_set(phase, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return phase, is_deferred
end

---
---
---
---
---

---@class (exact) evolved.__system_builder
---@field package __name? string
---@field package __single? evolved.component
---@field package __phase? evolved.phase
---@field package __after? evolved.system[]
---@field package __query? evolved.query
---@field package __execute? evolved.execute
---@field package __prologue? evolved.prologue
---@field package __epilogue? evolved.epilogue

---@class evolved.system_builder : evolved.__system_builder
local evolved_system_builder = {}
evolved_system_builder.__index = evolved_system_builder

---@return evolved.system_builder builder
---@nodiscard
__evolved_system = function()
    ---@type evolved.__system_builder
    local builder = {
        __name = nil,
        __single = nil,
        __phase = nil,
        __after = nil,
        __query = nil,
        __execute = nil,
        __prologue = nil,
        __epilogue = nil,
    }
    ---@cast builder evolved.system_builder
    return __lua_setmetatable(builder, evolved_system_builder)
end

---@param name string
---@return evolved.system_builder builder
function evolved_system_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.system_builder builder
function evolved_system_builder:single(single)
    self.__single = single
    return self
end

---@param phase evolved.phase
function evolved_system_builder:phase(phase)
    self.__phase = phase
    return self
end

---@param ... evolved.system systems
---@return evolved.system_builder builder
function evolved_system_builder:after(...)
    local system_count = __lua_select('#', ...)

    if system_count == 0 then
        return self
    end

    local after = self.__after

    if not after then
        after = __lua_table_new(math.max(4, system_count), 0)
        self.__after = after
    end

    local after_count = #after

    for i = 1, system_count do
        after_count = after_count + 1
        after[after_count] = __lua_select(i, ...)
    end

    return self
end

---@param query evolved.query
function evolved_system_builder:query(query)
    self.__query = query
    return self
end

---@param execute evolved.execute
function evolved_system_builder:execute(execute)
    self.__execute = execute
    return self
end

---@param prologue evolved.prologue
function evolved_system_builder:prologue(prologue)
    self.__prologue = prologue
    return self
end

---@param epilogue evolved.epilogue
function evolved_system_builder:epilogue(epilogue)
    self.__epilogue = epilogue
    return self
end

---@return evolved.system system
---@return boolean is_deferred
function evolved_system_builder:build()
    local name = self.__name
    local single = self.__single
    local phase = self.__phase
    local after = self.__after
    local query = self.__query
    local execute = self.__execute
    local prologue = self.__prologue
    local epilogue = self.__epilogue

    self.__name = nil
    self.__single = nil
    self.__phase = nil
    self.__after = nil
    self.__query = nil
    self.__execute = nil
    self.__prologue = nil
    self.__epilogue = nil

    local system = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = system
        component_list[component_count] = single
    end

    if phase then
        component_count = component_count + 1
        fragment_list[component_count] = __PHASE
        component_list[component_count] = phase
    end

    if after then
        component_count = component_count + 1
        fragment_list[component_count] = __AFTER
        component_list[component_count] = after
    end

    if query then
        component_count = component_count + 1
        fragment_list[component_count] = __QUERY
        component_list[component_count] = query
    end

    if execute then
        component_count = component_count + 1
        fragment_list[component_count] = __EXECUTE
        component_list[component_count] = execute
    end

    if prologue then
        component_count = component_count + 1
        fragment_list[component_count] = __PROLOGUE
        component_list[component_count] = prologue
    end

    if epilogue then
        component_count = component_count + 1
        fragment_list[component_count] = __EPILOGUE
        component_list[component_count] = epilogue
    end

    local _, is_deferred = __evolved_multi_set(system, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return system, is_deferred
end

---
---
---
---
---

---@param chunk evolved.chunk
---@return boolean
local function __update_chunk_caches_trace(chunk)
    local chunk_parent, chunk_fragment = chunk.__parent, chunk.__fragment

    local has_defaults_or_constructs = (chunk_parent and chunk_parent.__has_defaults_or_constructs)
        or __evolved_has_any(chunk_fragment, __DEFAULT, __CONSTRUCT)

    local has_set_or_assign_hooks = (chunk_parent and chunk_parent.__has_set_or_assign_hooks)
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_ASSIGN)

    local has_set_or_insert_hooks = (chunk_parent and chunk_parent.__has_set_or_insert_hooks)
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_INSERT)

    local has_remove_hooks = (chunk_parent and chunk_parent.__has_remove_hooks)
        or __evolved_has(chunk_fragment, __ON_REMOVE)

    chunk.__has_defaults_or_constructs = has_defaults_or_constructs
    chunk.__has_set_or_assign_hooks = has_set_or_assign_hooks
    chunk.__has_set_or_insert_hooks = has_set_or_insert_hooks
    chunk.__has_remove_hooks = has_remove_hooks

    return true
end

---@param fragment evolved.fragment
local function __update_fragment_hooks(fragment)
    __trace_fragment_chunks(fragment, __update_chunk_caches_trace, fragment)
end

__lua_assert(__evolved_insert(__ON_SET, __ON_INSERT, __update_fragment_hooks))
__lua_assert(__evolved_insert(__ON_ASSIGN, __ON_INSERT, __update_fragment_hooks))
__lua_assert(__evolved_insert(__ON_INSERT, __ON_INSERT, __update_fragment_hooks))
__lua_assert(__evolved_insert(__ON_REMOVE, __ON_INSERT, __update_fragment_hooks))

__lua_assert(__evolved_insert(__ON_SET, __ON_REMOVE, __update_fragment_hooks))
__lua_assert(__evolved_insert(__ON_ASSIGN, __ON_REMOVE, __update_fragment_hooks))
__lua_assert(__evolved_insert(__ON_INSERT, __ON_REMOVE, __update_fragment_hooks))
__lua_assert(__evolved_insert(__ON_REMOVE, __ON_REMOVE, __update_fragment_hooks))

---
---
---
---
---

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@return boolean
local function __update_chunk_tags_trace(chunk, fragment)
    local component_count = chunk.__component_count
    local component_indices = chunk.__component_indices
    local component_storages = chunk.__component_storages
    local component_fragments = chunk.__component_fragments

    local component_index = component_indices[fragment]

    if component_index and __evolved_has(fragment, __TAG) then
        if component_index ~= component_count then
            local last_component_storage = component_storages[component_count]
            local last_component_fragment = component_fragments[component_count]
            component_indices[last_component_fragment] = component_index
            component_storages[component_index] = last_component_storage
            component_fragments[component_index] = last_component_fragment
        end

        component_indices[fragment] = nil
        component_storages[component_count] = nil
        component_fragments[component_count] = nil

        component_count = component_count - 1
        chunk.__component_count = component_count
    end

    if not component_index and not __evolved_has(fragment, __TAG) then
        component_count = component_count + 1
        chunk.__component_count = component_count

        local storage = {}
        local storage_index = component_count

        component_indices[fragment] = storage_index
        component_storages[storage_index] = storage
        component_fragments[storage_index] = fragment

        local new_component = __evolved_get(fragment, __DEFAULT)

        if new_component == nil then
            new_component = true
        end

        for i = 1, chunk.__entity_count do
            storage[i] = new_component
        end
    end

    return true
end

local function __update_fragment_tags(fragment)
    __trace_fragment_chunks(fragment, __update_chunk_tags_trace, fragment)
end

---@param fragment evolved.fragment
local function __update_fragment_defaults(fragment)
    __trace_fragment_chunks(fragment, __update_chunk_caches_trace, fragment)
end

---@param fragment evolved.fragment
local function __update_fragment_constructs(fragment)
    __trace_fragment_chunks(fragment, __update_chunk_caches_trace, fragment)
end

__lua_assert(__evolved_insert(__TAG, __ON_INSERT, __update_fragment_tags))
__lua_assert(__evolved_insert(__TAG, __ON_REMOVE, __update_fragment_tags))

__lua_assert(__evolved_insert(__DEFAULT, __ON_INSERT, __update_fragment_defaults))
__lua_assert(__evolved_insert(__DEFAULT, __ON_REMOVE, __update_fragment_defaults))

__lua_assert(__evolved_insert(__CONSTRUCT, __ON_INSERT, __update_fragment_constructs))
__lua_assert(__evolved_insert(__CONSTRUCT, __ON_REMOVE, __update_fragment_constructs))

---
---
---
---
---

__lua_assert(__evolved_insert(__TAG, __NAME, 'TAG'))

__lua_assert(__evolved_insert(__NAME, __NAME, 'NAME'))
__lua_assert(__evolved_insert(__DEFAULT, __NAME, 'DEFAULT'))
__lua_assert(__evolved_insert(__CONSTRUCT, __NAME, 'CONSTRUCT'))

__lua_assert(__evolved_insert(__INCLUDES, __NAME, 'INCLUDES'))
__lua_assert(__evolved_insert(__EXCLUDES, __NAME, 'EXCLUDES'))

__lua_assert(__evolved_insert(__ON_SET, __NAME, 'ON_SET'))
__lua_assert(__evolved_insert(__ON_ASSIGN, __NAME, 'ON_ASSIGN'))
__lua_assert(__evolved_insert(__ON_INSERT, __NAME, 'ON_INSERT'))
__lua_assert(__evolved_insert(__ON_REMOVE, __NAME, 'ON_REMOVE'))

__lua_assert(__evolved_insert(__PHASE, __NAME, 'PHASE'))
__lua_assert(__evolved_insert(__AFTER, __NAME, 'AFTER'))

__lua_assert(__evolved_insert(__QUERY, __NAME, 'QUERY'))
__lua_assert(__evolved_insert(__EXECUTE, __NAME, 'EXECUTE'))

__lua_assert(__evolved_insert(__PROLOGUE, __NAME, 'PROLOGUE'))
__lua_assert(__evolved_insert(__EPILOGUE, __NAME, 'EPILOGUE'))

__lua_assert(__evolved_insert(__DESTROY_POLICY, __NAME, 'DESTROY_POLICY'))
__lua_assert(__evolved_insert(__DESTROY_POLICY_DESTROY_ENTITY, __NAME, 'DESTROY_POLICY_DESTROY_ENTITY'))
__lua_assert(__evolved_insert(__DESTROY_POLICY_REMOVE_FRAGMENT, __NAME, 'DESTROY_POLICY_REMOVE_FRAGMENT'))

---
---
---
---
---

__lua_assert(__evolved_insert(__TAG, __TAG))

__lua_assert(__evolved_insert(__INCLUDES, __CONSTRUCT, __component_list))
__lua_assert(__evolved_insert(__EXCLUDES, __CONSTRUCT, __component_list))

__lua_assert(__evolved_insert(__AFTER, __CONSTRUCT, __component_list))

---
---
---
---
---

---@param query evolved.query
---@param include_list evolved.fragment[]
__lua_assert(__evolved_insert(__INCLUDES, __ON_SET, function(query, _, include_list)
    local include_count = #include_list

    if include_count == 0 then
        __query_sorted_includes[query] = nil
        return
    end

    local sorted_includes = __assoc_list_new(include_count)

    for include_index = 1, include_count do
        local include = include_list[include_index]
        __assoc_list_insert(sorted_includes, include)
    end

    __assoc_list_sort(sorted_includes)
    __query_sorted_includes[query] = sorted_includes
end))

__lua_assert(__evolved_insert(__INCLUDES, __ON_REMOVE, function(query)
    __query_sorted_includes[query] = nil
end))

---
---
---
---
---

---@param query evolved.query
---@param exclude_list evolved.fragment[]
__lua_assert(__evolved_insert(__EXCLUDES, __ON_SET, function(query, _, exclude_list)
    local exclude_count = #exclude_list

    if exclude_count == 0 then
        __query_sorted_excludes[query] = nil
        return
    end

    local sorted_excludes = __assoc_list_new(exclude_count)

    for exclude_index = 1, exclude_count do
        local exclude = exclude_list[exclude_index]
        __assoc_list_insert(sorted_excludes, exclude)
    end

    __assoc_list_sort(sorted_excludes)
    __query_sorted_excludes[query] = sorted_excludes
end))

__lua_assert(__evolved_insert(__EXCLUDES, __ON_REMOVE, function(query)
    __query_sorted_excludes[query] = nil
end))

---
---
---
---
---

---@param system evolved.system
---@param new_phase evolved.phase
---@param old_phase? evolved.phase
__lua_assert(__evolved_insert(__PHASE, __ON_SET, function(system, _, new_phase, old_phase)
    if new_phase == old_phase then
        return
    end

    if old_phase then
        local old_phase_systems = __phase_systems[old_phase]

        if old_phase_systems then
            __assoc_list_remove_ordered(old_phase_systems, system)

            if old_phase_systems.__item_count == 0 then
                __phase_systems[old_phase] = nil
            end
        end
    end

    local new_phase_systems = __phase_systems[new_phase]

    if not new_phase_systems then
        new_phase_systems = __assoc_list_new(4)
        __phase_systems[new_phase] = new_phase_systems
    end

    __assoc_list_insert(new_phase_systems, system)
end))

---@param system evolved.system
---@param old_phase evolved.phase
__lua_assert(__evolved_insert(__PHASE, __ON_REMOVE, function(system, _, old_phase)
    local old_phase_systems = __phase_systems[old_phase]

    if old_phase_systems then
        __assoc_list_remove_ordered(old_phase_systems, system)

        if old_phase_systems.__item_count == 0 then
            __phase_systems[old_phase] = nil
        end
    end
end))

---
---
---
---
---

---@param system evolved.system
---@param new_after_list evolved.system[]
__lua_assert(__evolved_insert(__AFTER, __ON_SET, function(system, _, new_after_list)
    local new_after_count = #new_after_list

    if new_after_count == 0 then
        __system_dependencies[system] = nil
        return
    end

    local new_dependencies = __assoc_list_new(new_after_count)

    for new_after_index = 1, new_after_count do
        local new_after = new_after_list[new_after_index]
        __assoc_list_insert(new_dependencies, new_after)
    end

    __system_dependencies[system] = new_dependencies
end))

---@param system evolved.system
__lua_assert(__evolved_insert(__AFTER, __ON_REMOVE, function(system)
    __system_dependencies[system] = nil
end))

---
---
---
---
---

evolved.TAG = __TAG

evolved.NAME = __NAME
evolved.DEFAULT = __DEFAULT
evolved.CONSTRUCT = __CONSTRUCT

evolved.INCLUDES = __INCLUDES
evolved.EXCLUDES = __EXCLUDES

evolved.ON_SET = __ON_SET
evolved.ON_ASSIGN = __ON_ASSIGN
evolved.ON_INSERT = __ON_INSERT
evolved.ON_REMOVE = __ON_REMOVE

evolved.PHASE = __PHASE
evolved.AFTER = __AFTER

evolved.QUERY = __QUERY
evolved.EXECUTE = __EXECUTE

evolved.PROLOGUE = __PROLOGUE
evolved.EPILOGUE = __EPILOGUE

evolved.DESTROY_POLICY = __DESTROY_POLICY
evolved.DESTROY_POLICY_DESTROY_ENTITY = __DESTROY_POLICY_DESTROY_ENTITY
evolved.DESTROY_POLICY_REMOVE_FRAGMENT = __DESTROY_POLICY_REMOVE_FRAGMENT

evolved.id = __evolved_id

evolved.pack = __evolved_pack
evolved.unpack = __evolved_unpack

evolved.defer = __evolved_defer
evolved.commit = __evolved_commit

evolved.is_alive = __evolved_is_alive
evolved.is_empty = __evolved_is_empty

evolved.get = __evolved_get
evolved.has = __evolved_has
evolved.has_all = __evolved_has_all
evolved.has_any = __evolved_has_any

evolved.set = __evolved_set
evolved.assign = __evolved_assign
evolved.insert = __evolved_insert
evolved.remove = __evolved_remove
evolved.clear = __evolved_clear
evolved.destroy = __evolved_destroy

evolved.multi_set = __evolved_multi_set
evolved.multi_assign = __evolved_multi_assign
evolved.multi_insert = __evolved_multi_insert
evolved.multi_remove = __evolved_multi_remove

evolved.batch_set = __evolved_batch_set
evolved.batch_assign = __evolved_batch_assign
evolved.batch_insert = __evolved_batch_insert
evolved.batch_remove = __evolved_batch_remove
evolved.batch_clear = __evolved_batch_clear
evolved.batch_destroy = __evolved_batch_destroy

evolved.batch_multi_set = __evolved_batch_multi_set
evolved.batch_multi_assign = __evolved_batch_multi_assign
evolved.batch_multi_insert = __evolved_batch_multi_insert
evolved.batch_multi_remove = __evolved_batch_multi_remove

evolved.chunk = __evolved_chunk
evolved.select = __evolved_select

evolved.entities = __evolved_entities
evolved.fragments = __evolved_fragments

evolved.each = __evolved_each
evolved.execute = __evolved_execute

evolved.process = __evolved_process

evolved.spawn_at = __evolved_spawn_at
evolved.spawn_with = __evolved_spawn_with

evolved.debug_mode = __evolved_debug_mode
evolved.collect_garbage = __evolved_collect_garbage

evolved.entity = __evolved_entity
evolved.fragment = __evolved_fragment
evolved.query = __evolved_query
evolved.phase = __evolved_phase
evolved.system = __evolved_system

return evolved
