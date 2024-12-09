local compat = require 'evolved.compat'
local registry = require 'evolved.registry'

---@class evolved.defers
local defers = {}

---
---
---
---
---

---@enum evolved.defer_op
local evolved_defer_op = {
    set = 1,
    assign = 2,
    insert = 3,
    remove = 4,
    detach = 5,
    destroy = 6,
}

---@class (exact) evolved.__defer
---@field operations any[]
---@field operation_count integer

---@class evolved.defer : evolved.__defer
local evolved_defer_mt = {}
evolved_defer_mt.__index = evolved_defer_mt

---
---
---
---
---

---@type table<evolved.defer_op, fun(ops: any[], idx: integer): integer>
local __operation_processors = {
    [evolved_defer_op.set] = function(ops, idx)
        local entity = ops[idx + 1]
        local fragment = ops[idx + 2]
        local component = ops[idx + 3]
        registry.set(entity, fragment, component)
        return 4
    end,
    [evolved_defer_op.assign] = function(ops, idx)
        local entity = ops[idx + 1]
        local fragment = ops[idx + 2]
        local component = ops[idx + 3]
        registry.assign(entity, fragment, component)
        return 4
    end,
    [evolved_defer_op.insert] = function(ops, ids)
        local entity = ops[ids + 1]
        local fragment = ops[ids + 2]
        local component = ops[ids + 3]
        registry.insert(entity, fragment, component)
        return 4
    end,
    [evolved_defer_op.remove] = function(ops, idx)
        local entity = ops[idx + 1]
        local fragment_count = ops[idx + 2]
        registry.remove(entity, compat.unpack(ops, idx + 3, idx + 3 + fragment_count))
        return 3 + fragment_count
    end,
    [evolved_defer_op.detach] = function(ops, idx)
        local entity = ops[idx + 1]
        registry.detach(entity)
        return 2
    end,
    [evolved_defer_op.destroy] = function(ops, idx)
        local entity = ops[idx + 1]
        registry.destroy(entity)
        return 2
    end,
}

---
---
---
---
---

---@return evolved.defer
---@nodiscard
function defers.defer()
    ---@type evolved.__defer
    local defer = {
        operations = {},
        operation_count = 0,
    }
    ---@cast defer evolved.defer
    return setmetatable(defer, evolved_defer_mt)
end

---@param defer evolved.defer
---@param entity evolved.entity
---@param fragment evolved.entity
---@param component evolved.component
---@return evolved.defer
function defers.set(defer, entity, fragment, component)
    local operations = defer.operations
    local operation_count = defer.operation_count

    operations[operation_count + 1] = evolved_defer_op.set
    operations[operation_count + 2] = entity
    operations[operation_count + 3] = fragment
    operations[operation_count + 4] = component

    defer.operation_count = operation_count + 4
    return defer
end

---@param defer evolved.defer
---@param entity evolved.entity
---@param fragment evolved.entity
---@param component evolved.component
---@return evolved.defer
function defers.assign(defer, entity, fragment, component)
    local operations = defer.operations
    local operation_count = defer.operation_count

    operations[operation_count + 1] = evolved_defer_op.assign
    operations[operation_count + 2] = entity
    operations[operation_count + 3] = fragment
    operations[operation_count + 4] = component

    defer.operation_count = operation_count + 4
    return defer
end

---@param defer evolved.defer
---@param entity evolved.entity
---@param fragment evolved.entity
---@param component evolved.component
---@return evolved.defer
function defers.insert(defer, entity, fragment, component)
    local operations = defer.operations
    local operation_count = defer.operation_count

    operations[operation_count + 1] = evolved_defer_op.insert
    operations[operation_count + 2] = entity
    operations[operation_count + 3] = fragment
    operations[operation_count + 4] = component

    defer.operation_count = operation_count + 4
    return defer
end

---@param defer evolved.defer
---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return evolved.defer
function defers.remove(defer, entity, ...)
    local fragment_count = select('#', ...)
    if fragment_count == 0 then return defer end

    local operations = defer.operations
    local operation_count = defer.operation_count

    operations[operation_count + 1] = evolved_defer_op.remove
    operations[operation_count + 2] = entity
    operations[operation_count + 3] = fragment_count

    for i = 1, fragment_count do
        operations[operation_count + 3 + i] = select(i, ...)
    end

    defer.operation_count = operation_count + 3 + fragment_count
    return defer
end

---@param defer evolved.defer
---@param entity evolved.entity
---@return evolved.defer
function defers.detach(defer, entity)
    local operations = defer.operations
    local operation_count = defer.operation_count

    operations[operation_count + 1] = evolved_defer_op.detach
    operations[operation_count + 2] = entity

    defer.operation_count = operation_count + 2
    return defer
end

---@param defer evolved.defer
---@param entity evolved.entity
---@return evolved.defer
function defers.destroy(defer, entity)
    local operations = defer.operations
    local operation_count = defer.operation_count

    operations[operation_count + 1] = evolved_defer_op.destroy
    operations[operation_count + 2] = entity

    defer.operation_count = operation_count + 2
    return defer
end

---@param defer evolved.defer
---@return evolved.defer
function defers.playback(defer)
    local operations = defer.operations
    local operation_count = defer.operation_count

    local operation_index = 1; while operation_index <= operation_count do
        local operation = operations[operation_index]
        local processor = __operation_processors[operation]
        operation_index = operation_index + processor(operations, operation_index)
    end

    return defer
end

---
---
---
---
---

evolved_defer_mt.set = defers.set
evolved_defer_mt.assign = defers.assign
evolved_defer_mt.insert = defers.insert
evolved_defer_mt.remove = defers.remove
evolved_defer_mt.detach = defers.detach
evolved_defer_mt.destroy = defers.destroy
evolved_defer_mt.playback = defers.playback

---
---
---
---
---

return defers
