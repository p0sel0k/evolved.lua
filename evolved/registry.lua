local compat = require 'evolved.compat'
local idpools = require 'evolved.idpools'

---@class evolved.registry
local registry = {}

---
---
---
---
---

---@alias evolved.execution_stack evolved.chunk[]
---@alias evolved.execution_state [table<evolved.entity, boolean>, integer, evolved.execution_stack]
---@alias evolved.execution_iterator fun(execute_state: evolved.execution_state?): evolved.chunk?

local __guids = idpools.idpool()

local __roots = {} ---@type table<evolved.entity, evolved.chunk>
local __chunks = {} ---@type table<evolved.entity, evolved.chunk[]>

local __structural_changes = 0 ---@type integer
local __execution_stack_cache = {} ---@type evolved.execution_stack[]
local __execution_state_cache = {} ---@type evolved.execution_state[]

---
---
---
---
---

---@class evolved.entity
---@field package __guid evolved.id
---@field package __chunk? evolved.chunk
---@field package __index_in_chunk integer
local evolved_entity_mt = {}
evolved_entity_mt.__index = evolved_entity_mt

---@class evolved.query
---@field package __include_list evolved.entity[]
---@field package __exclude_list evolved.entity[]
---@field package __include_set table<evolved.entity, boolean>
---@field package __exclude_set table<evolved.entity, boolean>
local evolved_query_mt = {}
evolved_query_mt.__index = evolved_query_mt

---@class evolved.chunk
---@field package __parent? evolved.chunk
---@field package __fragment evolved.entity
---@field package __children evolved.chunk[]
---@field package __entities evolved.entity[]
---@field package __components table<evolved.entity, any[]>
---@field package __with_fragment_cache table<evolved.entity, evolved.chunk>
---@field package __without_fragment_cache table<evolved.entity, evolved.chunk>
local evolved_chunk_mt = {}
evolved_chunk_mt.__index = evolved_chunk_mt

---
---
---
---
---

---@param entity evolved.entity
local function __detach_entity(entity)
    local chunk = entity.__chunk
    if chunk == nil then return end

    local chunk_size = #chunk.__entities
    local chunk_entities = chunk.__entities
    local chunk_components = chunk.__components

    local index_in_chunk = entity.__index_in_chunk

    if index_in_chunk == chunk_size then
        chunk_entities[index_in_chunk] = nil

        for _, cs in pairs(chunk_components) do
            cs[index_in_chunk] = nil
        end
    else
        chunk_entities[index_in_chunk] = chunk_entities[chunk_size]
        chunk_entities[index_in_chunk].__index_in_chunk = index_in_chunk
        chunk_entities[chunk_size] = nil

        for _, cs in pairs(chunk_components) do
            cs[index_in_chunk] = cs[chunk_size]
            cs[chunk_size] = nil
        end
    end

    entity.__chunk = nil
    entity.__index_in_chunk = 0

    __structural_changes = __structural_changes + 1
end

---@param chunk evolved.chunk
---@param fragment evolved.entity
---@return boolean
---@nodiscard
local function __chunk_has_fragment(chunk, fragment)
    return chunk.__components[fragment] ~= nil
end

---@param chunk evolved.chunk
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
local function __chunk_has_all_fragments(chunk, ...)
    local components = chunk.__components

    for i = 1, select('#', ...) do
        if components[select(i, ...)] == nil then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param fragment_list evolved.entity[]
---@return boolean
---@nodiscard
local function __chunk_has_all_fragment_list(chunk, fragment_list)
    local components = chunk.__components

    for i = 1, #fragment_list do
        if components[fragment_list[i]] == nil then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
local function __chunk_has_any_fragments(chunk, ...)
    local components = chunk.__components

    for i = 1, select('#', ...) do
        if components[select(i, ...)] ~= nil then
            return true
        end
    end

    return false
end

---@param chunk evolved.chunk
---@param fragment_list evolved.entity[]
---@return boolean
---@nodiscard
local function __chunk_has_any_fragment_list(chunk, fragment_list)
    local components = chunk.__components

    for i = 1, #fragment_list do
        if components[fragment_list[i]] ~= nil then
            return true
        end
    end

    return false
end

---@param fragment evolved.entity
---@return evolved.chunk
---@nodiscard
local function __root_chunk(fragment)
    do
        local root_chunk = __roots[fragment]
        if root_chunk then return root_chunk end
    end

    ---@type evolved.chunk
    local root_chunk = {
        __parent = nil,
        __fragment = fragment,
        __children = {},
        __entities = {},
        __components = { [fragment] = {} },
        __with_fragment_cache = {},
        __without_fragment_cache = {},
    }

    setmetatable(root_chunk, evolved_chunk_mt)

    do
        __roots[fragment] = root_chunk
    end

    do
        local fragment_chunks = __chunks[fragment] or {}
        fragment_chunks[#fragment_chunks + 1] = root_chunk
        __chunks[fragment] = fragment_chunks
    end

    __structural_changes = __structural_changes + 1
    return root_chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.entity
---@return evolved.chunk
---@nodiscard
local function __chunk_with_fragment(chunk, fragment)
    if chunk == nil then
        return __root_chunk(fragment)
    end

    if chunk.__components[fragment] ~= nil then
        return chunk
    end

    do
        local cached_chunk = chunk.__with_fragment_cache[fragment]
        if cached_chunk then return cached_chunk end
    end

    if fragment.__guid == chunk.__fragment.__guid then
        return chunk
    end

    if fragment.__guid < chunk.__fragment.__guid then
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
        __fragment = fragment,
        __children = {},
        __entities = {},
        __components = { [fragment] = {} },
        __with_fragment_cache = {},
        __without_fragment_cache = {},
    }

    for f, _ in pairs(chunk.__components) do
        child_chunk.__components[f] = {}
    end

    setmetatable(child_chunk, evolved_chunk_mt)

    do
        local chunk_children = chunk.__children
        chunk_children[#chunk_children + 1] = child_chunk
    end

    do
        chunk.__with_fragment_cache[fragment] = child_chunk
        child_chunk.__without_fragment_cache[fragment] = chunk
    end

    do
        local fragment_chunks = __chunks[fragment] or {}
        fragment_chunks[#fragment_chunks + 1] = child_chunk
        __chunks[fragment] = fragment_chunks
    end

    __structural_changes = __structural_changes + 1
    return child_chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.entity
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment(chunk, fragment)
    if chunk == nil then
        return nil
    end

    if chunk.__components[fragment] == nil then
        return chunk
    end

    do
        local cached_chunk = chunk.__without_fragment_cache[fragment]
        if cached_chunk then return cached_chunk end
    end

    if fragment.__guid == chunk.__fragment.__guid then
        return chunk.__parent
    end

    if fragment.__guid < chunk.__fragment.__guid then
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
---@param ... evolved.entity fragments
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

---@return evolved.execution_stack
---@nodiscard
local function __execution_stack_acquire()
    local stack_cache = __execution_stack_cache

    if #stack_cache == 0 then
        return {}
    end

    local stack = stack_cache[#stack_cache]
    stack_cache[#stack_cache] = nil

    return stack
end

---@param stack evolved.execution_stack
local function __execution_stack_release(stack)
    for i = #stack, 1, -1 do stack[i] = nil end
    __execution_stack_cache[#__execution_stack_cache + 1] = stack
end

---@param query evolved.query
---@return evolved.execution_state
---@return evolved.execution_stack
---@nodiscard
local function __execution_state_acquire(query)
    local state_cache = __execution_state_cache

    if #state_cache == 0 then
        local stack = __execution_stack_acquire()
        local state = { query.__exclude_set, __structural_changes, stack, }
        return state, stack
    end

    local state = state_cache[#state_cache]
    state_cache[#state_cache] = nil

    local stack = __execution_stack_acquire()
    state[1], state[2], state[3] = query.__exclude_set, __structural_changes, stack
    return state, stack
end

---@param state evolved.execution_state
local function __execution_state_release(state)
    __execution_stack_release(state[3]); state[3] = nil
    __execution_state_cache[#__execution_state_cache + 1] = state
end

---@type evolved.execution_iterator
local function __execute_iterator(execution_state)
    if execution_state == nil then return nil end

    local exclude_set, structural_changes, execution_stack =
        execution_state[1], execution_state[2], execution_state[3]

    if structural_changes ~= __structural_changes then
        error('chunks have been modified during query execution', 2)
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

    __execution_state_release(execution_state)
end

---
---
---
---
---

---@return evolved.entity
---@nodiscard
function registry.entity()
    local guid = idpools.acquire(__guids)

    ---@type evolved.entity
    local entity = {
        __guid = guid,
        __chunk = nil,
        __index_in_chunk = 0,
    }

    return setmetatable(entity, evolved_entity_mt)
end

---@param entity evolved.entity
---@return evolved.id
---@nodiscard
function registry.guid(entity)
    return entity.__guid
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
function registry.alive(entity)
    return idpools.alive(__guids, entity.__guid)
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return any ... components
---@nodiscard
function registry.get(entity, ...)
    local chunk = entity.__chunk
    if chunk == nil then return end

    local components = chunk.__components
    if components == nil then return end

    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    local index_in_chunk = entity.__index_in_chunk

    if fragment_count == 1 then
        local f1 = ...
        local cs1 = components[f1]
        return cs1 and cs1[index_in_chunk]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local cs1, cs2 = components[f1], components[f2]
        return cs1 and cs1[index_in_chunk], cs2 and cs2[index_in_chunk]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[index_in_chunk], cs2 and cs2[index_in_chunk], cs3 and cs3[index_in_chunk]
    end

    do
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[index_in_chunk], cs2 and cs2[index_in_chunk], cs3 and cs3[index_in_chunk],
            registry.get(entity, select(4, ...))
    end
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@return boolean
---@nodiscard
function registry.has(entity, fragment)
    local chunk = entity.__chunk
    if chunk == nil then return false end
    return __chunk_has_fragment(chunk, fragment)
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
function registry.has_all(entity, ...)
    local chunk = entity.__chunk
    if chunk == nil then return select('#', ...) == 0 end
    return __chunk_has_all_fragments(chunk, ...)
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
function registry.has_any(entity, ...)
    local chunk = entity.__chunk
    if chunk == nil then return false end
    return __chunk_has_any_fragments(chunk, ...)
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
---@return evolved.entity
function registry.set(entity, fragment, component)
    component = component == nil and true or component

    if not idpools.alive(__guids, entity.__guid) then
        return entity
    end

    local old_chunk = entity.__chunk
    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if old_chunk == new_chunk then
        local components = new_chunk.__components[fragment]
        components[entity.__index_in_chunk] = component
        return entity
    end

    if new_chunk ~= nil then
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components

        local old_index_in_chunk = entity.__index_in_chunk
        local new_index_in_chunk = #new_chunk_entities + 1

        new_chunk_entities[new_index_in_chunk] = entity
        new_chunk_components[fragment][new_index_in_chunk] = component

        if old_chunk ~= nil then
            local old_chunk_components = old_chunk.__components
            for old_f, old_cs in pairs(old_chunk_components) do
                local new_cs = new_chunk_components[old_f]
                new_cs[new_index_in_chunk] = old_cs[old_index_in_chunk]
            end
            __detach_entity(entity)
        end

        entity.__chunk = new_chunk
        entity.__index_in_chunk = new_index_in_chunk

        __structural_changes = __structural_changes + 1
    else
        __detach_entity(entity)
    end

    return entity
end

---@param chunk evolved.chunk
---@param fragment evolved.entity
---@param component any
---@return integer assigned_count
---@return integer inserted_count
function registry.chunk_set(chunk, fragment, component)
    if __chunk_has_fragment(chunk, fragment) then
        local assigned = registry.chunk_assign(chunk, fragment, component)
        return assigned, 0
    else
        local inserted = registry.chunk_insert(chunk, fragment, component)
        return 0, inserted
    end
end

---@param query evolved.query
---@param fragment evolved.entity
---@param component any
---@return integer assigned_count
---@return integer inserted_count
function registry.query_set(query, fragment, component)
    local assign_chunks = __execution_stack_acquire()
    local insert_chunks = __execution_stack_acquire()

    for chunk in registry.query_execute(query) do
        if __chunk_has_fragment(chunk, fragment) then
            assign_chunks[#assign_chunks + 1] = chunk
        else
            insert_chunks[#insert_chunks + 1] = chunk
        end
    end

    local assigned_count = 0
    local inserted_count = 0

    for i = 1, #assign_chunks do
        local assigned, inserted = registry.chunk_set(assign_chunks[i], fragment, component)
        assigned_count = assigned_count + assigned
        inserted_count = inserted_count + inserted
    end

    for i = 1, #insert_chunks do
        local assigned, inserted = registry.chunk_set(insert_chunks[i], fragment, component)
        assigned_count = assigned_count + assigned
        inserted_count = inserted_count + inserted
    end

    __execution_stack_release(assign_chunks)
    __execution_stack_release(insert_chunks)
    return assigned_count, inserted_count
end

---@param entity evolved.entity
---@param apply fun(any): any
---@param fragment evolved.entity
---@return boolean is_applied
function registry.apply(entity, apply, fragment)
    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    local chunk = entity.__chunk
    if chunk == nil then return false end

    local components = chunk.__components[fragment]
    if components == nil then return false end

    do
        local component = components[entity.__index_in_chunk]

        component = apply(component)
        component = component == nil and true or component

        components[entity.__index_in_chunk] = component
    end

    return true
end

---@param chunk evolved.chunk
---@param apply fun(any): any
---@param fragment evolved.entity
---@return integer applied_count
function registry.chunk_apply(chunk, apply, fragment)
    local chunk_size = #chunk.__entities
    local chunk_components = chunk.__components
    local chunk_fragment_components = chunk_components[fragment]

    if chunk_size == 0 or chunk_fragment_components == nil then
        return 0
    end

    for i = 1, chunk_size do
        local component = chunk_fragment_components[i]

        component = apply(component)
        component = component == nil and true or component

        chunk_fragment_components[i] = component
    end

    return chunk_size
end

---@param query evolved.query
---@param apply fun(any): any
---@param fragment evolved.entity
---@return integer applied_count
function registry.query_apply(query, apply, fragment)
    local chunks = __execution_stack_acquire()

    for chunk in registry.query_execute(query) do
        chunks[#chunks + 1] = chunk
    end

    local applied_count = 0

    for i = 1, #chunks do
        local applied = registry.chunk_apply(chunks[i], apply, fragment)
        applied_count = applied_count + applied
    end

    __execution_stack_release(chunks)
    return applied_count
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
---@return boolean is_assigned
function registry.assign(entity, fragment, component)
    component = component == nil and true or component

    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    local chunk = entity.__chunk
    if chunk == nil then return false end

    local components = chunk.__components[fragment]
    if components == nil then return false end

    do
        components[entity.__index_in_chunk] = component
    end

    return true
end

---@param chunk evolved.chunk
---@param fragment evolved.entity
---@param component any
---@return integer assigned_count
function registry.chunk_assign(chunk, fragment, component)
    component = component == nil and true or component

    local chunk_size = #chunk.__entities
    local chunk_components = chunk.__components
    local chunk_fragment_components = chunk_components[fragment]

    if chunk_size == 0 or chunk_fragment_components == nil then
        return 0
    end

    for i = 1, chunk_size do
        chunk_fragment_components[i] = component
    end

    return chunk_size
end

---@param query evolved.query
---@param fragment evolved.entity
---@param component any
---@return integer assigned_count
function registry.query_assign(query, fragment, component)
    local chunks = __execution_stack_acquire()

    for chunk in registry.query_execute(query) do
        chunks[#chunks + 1] = chunk
    end

    local assigned_count = 0

    for i = 1, #chunks do
        local assigned = registry.chunk_assign(chunks[i], fragment, component)
        assigned_count = assigned_count + assigned
    end

    __execution_stack_release(chunks)
    return assigned_count
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
---@return boolean is_inserted
function registry.insert(entity, fragment, component)
    component = component == nil and true or component

    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    local old_chunk = entity.__chunk
    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if old_chunk == new_chunk then
        return false
    end

    if new_chunk ~= nil then
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components

        local old_index_in_chunk = entity.__index_in_chunk
        local new_index_in_chunk = #new_chunk.__entities + 1

        new_chunk_entities[new_index_in_chunk] = entity
        new_chunk_components[fragment][new_index_in_chunk] = component

        if old_chunk ~= nil then
            local old_chunk_components = old_chunk.__components
            for old_f, old_cs in pairs(old_chunk_components) do
                local new_cs = new_chunk_components[old_f]
                new_cs[new_index_in_chunk] = old_cs[old_index_in_chunk]
            end
            __detach_entity(entity)
        end

        entity.__chunk = new_chunk
        entity.__index_in_chunk = new_index_in_chunk

        __structural_changes = __structural_changes + 1
    else
        __detach_entity(entity)
    end

    return true
end

---@param chunk evolved.chunk
---@param fragment evolved.entity
---@param component any
---@return integer inserted_count
function registry.chunk_insert(chunk, fragment, component)
    component = component == nil and true or component

    local old_chunk = chunk
    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if old_chunk == new_chunk then
        return 0
    end

    local old_chunk_size = #old_chunk.__entities
    local old_chunk_entities = old_chunk.__entities
    local old_chunk_components = old_chunk.__components

    if new_chunk ~= nil then
        local new_chunk_size = #new_chunk.__entities
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components

        if new_chunk_size == 0 then
            new_chunk.__entities, old_chunk.__entities = old_chunk_entities, new_chunk_entities
            new_chunk_entities, old_chunk_entities = old_chunk_entities, new_chunk_entities

            new_chunk.__components, old_chunk.__components = old_chunk_components, new_chunk_components
            new_chunk_components, old_chunk_components = old_chunk_components, new_chunk_components

            if old_chunk_components[fragment] ~= nil then
                new_chunk_components[fragment] = {}
                old_chunk_components[fragment] = nil
            end
        else
            compat.move(
                old_chunk_entities, 1, old_chunk_size,
                new_chunk_size + 1, new_chunk_entities)

            for old_f, old_cs in pairs(old_chunk_components) do
                local new_cs = new_chunk_components[old_f]
                compat.move(old_cs, 1, old_chunk_size, new_chunk_size + 1, new_cs)
            end
        end

        do
            local new_chunk_fragment_components = new_chunk_components[fragment]

            for new_index_in_chunk = new_chunk_size + 1, new_chunk_size + old_chunk_size do
                new_chunk_fragment_components[new_index_in_chunk] = component
            end
        end

        for new_index_in_chunk = new_chunk_size + 1, new_chunk_size + old_chunk_size do
            local entity = new_chunk_entities[new_index_in_chunk]
            entity.__chunk, entity.__index_in_chunk = new_chunk, new_index_in_chunk
        end
    else
        for old_index_in_chunk = 1, old_chunk_size do
            local entity = old_chunk_entities[old_index_in_chunk]
            entity.__chunk, entity.__index_in_chunk = nil, 0
        end
    end

    if #old_chunk_entities ~= 0 then
        old_chunk.__entities = {}
    end

    for old_f, old_cs in pairs(old_chunk_components) do
        if #old_cs ~= 0 then
            old_chunk_components[old_f] = {}
        end
    end

    __structural_changes = __structural_changes + old_chunk_size
    return old_chunk_size
end

---@param query evolved.query
---@param fragment evolved.entity
---@param component any
---@return integer inserted_count
function registry.query_insert(query, fragment, component)
    local chunks = __execution_stack_acquire()

    for chunk in registry.query_execute(query) do
        chunks[#chunks + 1] = chunk
    end

    local inserted_count = 0

    for i = 1, #chunks do
        local inserted = registry.chunk_insert(chunks[i], fragment, component)
        inserted_count = inserted_count + inserted
    end

    __execution_stack_release(chunks)
    return inserted_count
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean is_removed
function registry.remove(entity, ...)
    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    local old_chunk = entity.__chunk
    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return false
    end

    if new_chunk ~= nil then
        local new_chunk_size = #new_chunk.__entities
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components

        local old_index_in_chunk = entity.__index_in_chunk
        local new_index_in_chunk = new_chunk_size + 1

        new_chunk_entities[new_index_in_chunk] = entity

        if old_chunk ~= nil then
            local old_chunk_components = old_chunk.__components
            for new_f, new_cs in pairs(new_chunk_components) do
                local old_cs = old_chunk_components[new_f]
                new_cs[new_index_in_chunk] = old_cs[old_index_in_chunk]
            end
            __detach_entity(entity)
        end

        entity.__chunk = new_chunk
        entity.__index_in_chunk = new_index_in_chunk

        __structural_changes = __structural_changes + 1
    else
        __detach_entity(entity)
    end

    return true
end

---@param chunk evolved.chunk
---@param ... evolved.entity fragments
---@return integer removed_count
function registry.chunk_remove(chunk, ...)
    local old_chunk = chunk
    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return 0
    end

    local old_chunk_size = #old_chunk.__entities
    local old_chunk_entities = old_chunk.__entities
    local old_chunk_components = old_chunk.__components

    if new_chunk ~= nil then
        local new_chunk_size = #new_chunk.__entities
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components

        if new_chunk_size == 0 then
            new_chunk.__entities, old_chunk.__entities = old_chunk_entities, new_chunk_entities
            new_chunk_entities, old_chunk_entities = old_chunk_entities, new_chunk_entities

            new_chunk.__components, old_chunk.__components = old_chunk_components, new_chunk_components
            new_chunk_components, old_chunk_components = old_chunk_components, new_chunk_components

            for i = 1, select('#', ...) do
                local fragment = select(i, ...)
                if new_chunk_components[fragment] ~= nil then
                    old_chunk_components[fragment] = {}
                    new_chunk_components[fragment] = nil
                end
            end
        else
            compat.move(
                old_chunk_entities, 1, old_chunk_size,
                new_chunk_size + 1, new_chunk_entities)

            for new_f, new_cs in pairs(new_chunk_components) do
                local old_cs = old_chunk_components[new_f]
                compat.move(old_cs, 1, old_chunk_size, new_chunk_size + 1, new_cs)
            end
        end

        for new_index_in_chunk = new_chunk_size + 1, new_chunk_size + old_chunk_size do
            local entity = new_chunk_entities[new_index_in_chunk]
            entity.__chunk, entity.__index_in_chunk = new_chunk, new_index_in_chunk
        end
    else
        for old_index_in_chunk = 1, old_chunk_size do
            local entity = old_chunk_entities[old_index_in_chunk]
            entity.__chunk, entity.__index_in_chunk = nil, 0
        end
    end

    if #old_chunk_entities ~= 0 then
        old_chunk.__entities = {}
    end

    for old_f, old_cs in pairs(old_chunk_components) do
        if #old_cs ~= 0 then
            old_chunk_components[old_f] = {}
        end
    end

    __structural_changes = __structural_changes + old_chunk_size
    return old_chunk_size
end

---@param query evolved.query
---@param ... evolved.entity fragments
---@return integer removed_count
function registry.query_remove(query, ...)
    local chunks = __execution_stack_acquire()

    for chunk in registry.query_execute(query) do
        chunks[#chunks + 1] = chunk
    end

    local removed_count = 0

    for i = 1, #chunks do
        local removed = registry.chunk_remove(chunks[i], ...)
        removed_count = removed_count + removed
    end

    __execution_stack_release(chunks)
    return removed_count
end

---@param entity evolved.entity
---@return evolved.entity
function registry.detach(entity)
    if not idpools.alive(__guids, entity.__guid) then
        return entity
    end

    if entity.__chunk ~= nil then
        __detach_entity(entity)
    end

    return entity
end

---@param chunk evolved.chunk
---@return integer detached_count
function registry.chunk_detach(chunk)
    local chunk_size = #chunk.__entities
    local chunk_entities = chunk.__entities
    local chunk_components = chunk.__components

    if chunk_size == 0 then
        return 0
    end

    for index_in_chunk = 1, chunk_size do
        local entity = chunk_entities[index_in_chunk]
        entity.__chunk = nil
        entity.__index_in_chunk = 0
    end

    do
        chunk.__entities = {}

        for f, _ in pairs(chunk_components) do
            chunk_components[f] = {}
        end
    end

    __structural_changes = __structural_changes + chunk_size
    return chunk_size
end

---@param query evolved.query
---@return integer detached_count
function registry.query_detach(query)
    local chunks = __execution_stack_acquire()

    for chunk in registry.query_execute(query) do
        chunks[#chunks + 1] = chunk
    end

    local detached_count = 0

    for i = 1, #chunks do
        local detached = registry.chunk_detach(chunks[i])
        detached_count = detached_count + detached
    end

    __execution_stack_release(chunks)
    return detached_count
end

---@param entity evolved.entity
---@return evolved.entity
function registry.destroy(entity)
    if not idpools.alive(__guids, entity.__guid) then
        return entity
    end

    if entity.__chunk ~= nil then
        __detach_entity(entity)
    end

    idpools.release(__guids, entity.__guid)

    return entity
end

---@param chunk evolved.chunk
---@return integer destroyed_count
function registry.chunk_destroy(chunk)
    local chunk_size = #chunk.__entities
    local chunk_entities = chunk.__entities
    local chunk_components = chunk.__components

    if chunk_size == 0 then
        return 0
    end

    for index_in_chunk = 1, chunk_size do
        local entity = chunk_entities[index_in_chunk]
        entity.__chunk = nil
        entity.__index_in_chunk = 0
        idpools.release(__guids, entity.__guid)
    end

    do
        chunk.__entities = {}

        for f, _ in pairs(chunk_components) do
            chunk_components[f] = {}
        end
    end

    __structural_changes = __structural_changes + chunk_size
    return chunk_size
end

---@param query evolved.query
---@return integer destroyed_count
function registry.query_destroy(query)
    local chunks = __execution_stack_acquire()

    for chunk in registry.query_execute(query) do
        chunks[#chunks + 1] = chunk
    end

    local destroyed_count = 0

    for i = 1, #chunks do
        local destroyed = registry.chunk_destroy(chunks[i])
        destroyed_count = destroyed_count + destroyed
    end

    __execution_stack_release(chunks)
    return destroyed_count
end

---@param ... evolved.entity fragments
---@return evolved.query
---@nodiscard
function registry.query(...)
    local include_list = {}
    local include_set = {}

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if not include_set[f] then
            include_set[f] = true
            include_list[#include_list + 1] = f
        end
    end

    table.sort(include_list, function(a, b)
        return a.__guid < b.__guid
    end)

    ---@type evolved.query
    local query = {
        __include_list = include_list,
        __exclude_list = {},
        __include_set = include_set,
        __exclude_set = {},
    }

    return setmetatable(query, evolved_query_mt)
end

---@param query evolved.query
---@param ... evolved.entity fragments
---@return evolved.query
---@nodiscard
function registry.query_include(query, ...)
    local include_list = {}
    local include_set = {}

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if not include_set[f] then
            include_set[f] = true
            include_list[#include_list + 1] = f
        end
    end

    for _, f in ipairs(query.__include_list) do
        if not include_set[f] then
            include_set[f] = true
            include_list[#include_list + 1] = f
        end
    end

    table.sort(include_list, function(a, b)
        return a.__guid < b.__guid
    end)

    ---@type evolved.query
    local new_query = {
        __include_list = include_list,
        __exclude_list = query.__exclude_list,
        __include_set = include_set,
        __exclude_set = query.__exclude_set,
    }

    return setmetatable(new_query, evolved_query_mt)
end

---@param query evolved.query
---@param ... evolved.entity fragments
---@return evolved.query
---@nodiscard
function registry.query_exclude(query, ...)
    local exclude_list = {}
    local exclude_set = {}

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if not exclude_set[f] then
            exclude_set[f] = true
            exclude_list[#exclude_list + 1] = f
        end
    end

    for _, f in ipairs(query.__exclude_list) do
        if not exclude_set[f] then
            exclude_set[f] = true
            exclude_list[#exclude_list + 1] = f
        end
    end

    table.sort(exclude_list, function(a, b)
        return a.__guid < b.__guid
    end)

    ---@type evolved.query
    local new_query = {
        __include_list = query.__include_list,
        __exclude_list = exclude_list,
        __include_set = query.__include_set,
        __exclude_set = exclude_set,
    }

    return setmetatable(new_query, evolved_query_mt)
end

---@param query evolved.query
---@return evolved.execution_iterator
---@return evolved.execution_state?
---@nodiscard
function registry.query_execute(query)
    local include_list, exclude_list =
        query.__include_list, query.__exclude_list

    if #include_list == 0 then
        return __execute_iterator
    end

    local main_fragment = include_list[#include_list]
    local main_fragment_chunks = __chunks[main_fragment]

    if main_fragment_chunks == nil or #main_fragment_chunks == 0 then
        return __execute_iterator
    end

    local execution_state, execution_stack = __execution_state_acquire(query)

    for _, main_fragment_chunk in ipairs(main_fragment_chunks) do
        if __chunk_has_all_fragment_list(main_fragment_chunk, include_list) then
            if not __chunk_has_any_fragment_list(main_fragment_chunk, exclude_list) then
                execution_stack[#execution_stack + 1] = main_fragment_chunk
            end
        end
    end

    return __execute_iterator, execution_state
end

---@param fragment evolved.entity
---@param ... evolved.entity fragments
---@return evolved.chunk
---@nodiscard
function registry.chunk(fragment, ...)
    local fragment_list = { fragment }
    local fragment_set = { [fragment] = true }

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if not fragment_set[f] then
            fragment_set[f] = true
            fragment_list[#fragment_list + 1] = f
        end
    end

    table.sort(fragment_list, function(a, b)
        return a.__guid < b.__guid
    end)

    local chunk = __root_chunk(fragment_list[1])

    for i = 2, #fragment_list do
        chunk = __chunk_with_fragment(chunk, fragment_list[i])
    end

    return chunk
end

---@param chunk evolved.chunk
---@return evolved.entity[]
---@nodiscard
function registry.chunk_entities(chunk)
    return chunk.__entities
end

---@param chunk evolved.chunk
---@param ... evolved.entity fragments
---@return any[] ... components
---@nodiscard
function registry.chunk_components(chunk, ...)
    local components = chunk.__components

    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    if fragment_count == 1 then
        local f1 = ...
        return components[f1]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        return components[f1], components[f2]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        return components[f1], components[f2], components[f3]
    end

    do
        local f1, f2, f3 = ...
        return components[f1], components[f2], components[f3],
            registry.chunk_components(chunk, select(4, ...))
    end
end

---
---
---
---
---

function evolved_entity_mt:__tostring()
    local index, version = idpools.unpack(self.__guid)

    return string.format('[%d;%d]', index, version)
end

evolved_entity_mt.guid = registry.guid
evolved_entity_mt.alive = registry.alive
evolved_entity_mt.get = registry.get
evolved_entity_mt.has = registry.has
evolved_entity_mt.has_all = registry.has_all
evolved_entity_mt.has_any = registry.has_any

evolved_entity_mt.set = registry.set
evolved_entity_mt.apply = registry.apply
evolved_entity_mt.assign = registry.assign
evolved_entity_mt.insert = registry.insert
evolved_entity_mt.remove = registry.remove
evolved_entity_mt.detach = registry.detach
evolved_entity_mt.destroy = registry.destroy

---
---
---
---
---

function evolved_query_mt:__tostring()
    local str = ''

    for i, f in ipairs(self.__include_list) do
        str = string.format('%s%s%s', str, i > 1 and '+' or '', f)
    end

    for _, f in ipairs(self.__exclude_list) do
        str = string.format('%s-%s', str, f)
    end

    return string.format('(%s)', str)
end

evolved_query_mt.set = registry.query_set
evolved_query_mt.apply = registry.query_apply
evolved_query_mt.assign = registry.query_assign
evolved_query_mt.insert = registry.query_insert
evolved_query_mt.remove = registry.query_remove
evolved_query_mt.detach = registry.query_detach
evolved_query_mt.destroy = registry.query_destroy

evolved_query_mt.include = registry.query_include
evolved_query_mt.exclude = registry.query_exclude
evolved_query_mt.execute = registry.query_execute

---
---
---
---
---

function evolved_chunk_mt:__tostring()
    local str = ''

    local chunk_iter = self; while chunk_iter do
        str = string.format('%s%s', chunk_iter.__fragment, str)
        chunk_iter = chunk_iter.__parent
    end

    return string.format('{%s}', str)
end

evolved_chunk_mt.set = registry.chunk_set
evolved_chunk_mt.apply = registry.chunk_apply
evolved_chunk_mt.assign = registry.chunk_assign
evolved_chunk_mt.insert = registry.chunk_insert
evolved_chunk_mt.remove = registry.chunk_remove
evolved_chunk_mt.detach = registry.chunk_detach
evolved_chunk_mt.destroy = registry.chunk_destroy

evolved_chunk_mt.entities = registry.chunk_entities
evolved_chunk_mt.components = registry.chunk_components

---
---
---
---
---

return registry
