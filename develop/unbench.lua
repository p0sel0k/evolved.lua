package.loaded['evolved'] = nil
local evo = require 'evolved'

local __table_pack = (function()
    return table.pack or function(...)
        return { n = select('#', ...), ... }
    end
end)()

local __table_unpack = (function()
    return table.unpack or unpack
end)()

---@param name string
---@param loop fun(...): ...
---@param init? fun(): ...
local function __bench_describe(name, loop, init)
    collectgarbage('collect')
    collectgarbage('stop')

    print(string.format('| %s ... |', name))

    local iters = 0
    local state = init and __table_pack(init()) or {}

    local start_s = os.clock()
    local start_kb = collectgarbage('count')

    local success, result = pcall(function()
        repeat
            iters = iters + 1
            loop(__table_unpack(state))
        until os.clock() - start_s > 0.2
    end)

    local finish_s = os.clock()
    local finish_kb = collectgarbage('count')

    print(string.format('    %s | us: %.2f | op/s: %.2f | kb/i: %.2f',
        success and 'PASS' or 'FAIL',
        (finish_s - start_s) * 1e6 / iters,
        iters / (finish_s - start_s),
        (finish_kb - start_kb) / iters))

    if not success then print('    ' .. result) end

    collectgarbage('restart')
    collectgarbage('collect')
end

---@param tables table[]
__bench_describe('create and destroy 1k tables', function(tables)
    for i = 1, 1000 do
        local t = {}
        tables[i] = t
    end

    for i = 1, #tables do
        tables[i] = nil
    end

    collectgarbage('collect')
end, function()
    return {}
end)

---@param entities evolved.id[]
__bench_describe('create and destroy 1k entities', function(entities)
    local id = evo.id
    local destroy = evo.destroy

    for i = 1, 1000 do
        local e = id()
        entities[i] = e
    end

    for i = 1, #entities do
        destroy(entities[i])
    end
end, function()
    return {}
end)

---@param f1 evolved.fragment
---@param entities evolved.id[]
__bench_describe('create and destroy 1k entities with one component', function(f1, entities)
    local id = evo.id
    local insert = evo.insert
    local destroy = evo.destroy

    for i = 1, 1000 do
        local e = id()
        entities[i] = e

        insert(e, f1)
    end

    for i = 1, #entities do
        destroy(entities[i])
    end
end, function()
    local f1 = evo.id(2)
    return f1, {}
end)

---@param f1 evolved.fragment
---@param f2 evolved.fragment
---@param entities evolved.id[]
__bench_describe('create and destroy 1k entities with two components', function(f1, f2, entities)
    local id = evo.id
    local insert = evo.insert
    local destroy = evo.destroy

    for i = 1, 1000 do
        local e = id()
        entities[i] = e

        insert(e, f1)
        insert(e, f2)
    end

    for i = 1, #entities do
        destroy(entities[i])
    end
end, function()
    local f1, f2 = evo.id(2)
    return f1, f2, {}
end)

---@param f1 evolved.fragment
---@param f2 evolved.fragment
---@param f3 evolved.fragment
---@param entities evolved.id[]
__bench_describe('create and destroy 1k entities with three components', function(f1, f2, f3, entities)
    local id = evo.id
    local insert = evo.insert
    local destroy = evo.destroy

    for i = 1, 1000 do
        local e = id()
        entities[i] = e

        insert(e, f1)
        insert(e, f2)
        insert(e, f3)
    end

    for i = 1, #entities do
        destroy(entities[i])
    end
end, function()
    local f1, f2, f3 = evo.id(3)
    return f1, f2, f3, {}
end)

---
--- initial
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 312.60 | op/s: 3199.00 | kb/i: 0.05
| create and destroy 1k entities with one component ... |
    PASS | us: 1570.31 | op/s: 636.82 | kb/i: 0.63
| create and destroy 1k entities with two components ... |
    PASS | us: 2780.82 | op/s: 359.61 | kb/i: 0.91
| create and destroy 1k entities with three components ... |
    PASS | us: 4060.00 | op/s: 246.31 | kb/i: 1.67
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.22 | op/s: 81840.80 | kb/i: 0.00
| create and destroy 1k entities with one component ... |
    PASS | us: 56.22 | op/s: 17786.07 | kb/i: 0.02
| create and destroy 1k entities with two components ... |
    PASS | us: 412.73 | op/s: 2422.89 | kb/i: 0.11
| create and destroy 1k entities with three components ... |
    PASS | us: 611.62 | op/s: 1635.00 | kb/i: 0.17
]]

---
--- unpack ids without dedicated functions
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 255.40 | op/s: 3915.42 | kb/i: 0.04
| create and destroy 1k entities with one component ... |
    PASS | us: 1248.45 | op/s: 801.00 | kb/i: 0.50
| create and destroy 1k entities with two components ... |
    PASS | us: 2208.79 | op/s: 452.74 | kb/i: 0.73
| create and destroy 1k entities with three components ... |
    PASS | us: 3278.69 | op/s: 305.00 | kb/i: 1.37
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.12 | op/s: 82482.59 | kb/i: 0.00
| create and destroy 1k entities with one component ... |
    PASS | us: 69.05 | op/s: 14482.59 | kb/i: 0.03
| create and destroy 1k entities with two components ... |
    PASS | us: 400.40 | op/s: 2497.51 | kb/i: 0.09
| create and destroy 1k entities with three components ... |
    PASS | us: 574.71 | op/s: 1740.00 | kb/i: 0.14
]]

---
--- hook flags for chunks
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 255.40 | op/s: 3915.42 | kb/i: 0.04
| create and destroy 1k entities with one component ... |
    PASS | us: 1005.03 | op/s: 995.00 | kb/i: 0.41
| create and destroy 1k entities with two components ... |
    PASS | us: 1747.83 | op/s: 572.14 | kb/i: 0.59
| create and destroy 1k entities with three components ... |
    PASS | us: 2576.92 | op/s: 388.06 | kb/i: 1.08
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.20 | op/s: 81940.30 | kb/i: 0.00
| create and destroy 1k entities with one component ... |
    PASS | us: 53.66 | op/s: 18636.82 | kb/i: 0.02
| create and destroy 1k entities with two components ... |
    PASS | us: 357.02 | op/s: 2801.00 | kb/i: 0.09
| create and destroy 1k entities with three components ... |
    PASS | us: 533.33 | op/s: 1875.00 | kb/i: 0.15
]]

---
--- construct flags for chunks
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 253.49 | op/s: 3945.00 | kb/i: 0.04
| create and destroy 1k entities with one component ... |
    PASS | us: 913.64 | op/s: 1094.53 | kb/i: 0.37
| create and destroy 1k entities with two components ... |
    PASS | us: 1562.50 | op/s: 640.00 | kb/i: 0.53
| create and destroy 1k entities with three components ... |
    PASS | us: 2280.90 | op/s: 438.42 | kb/i: 0.97
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.05 | op/s: 82995.02 | kb/i: 0.00
| create and destroy 1k entities with one component ... |
    PASS | us: 53.61 | op/s: 18651.74 | kb/i: 0.02
| create and destroy 1k entities with two components ... |
    PASS | us: 232.02 | op/s: 4310.00 | kb/i: 0.06
| create and destroy 1k entities with three components ... |
    PASS | us: 329.49 | op/s: 3035.00 | kb/i: 0.10
]]

---
--- after chunks refactoring
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 254.45 | op/s: 3930.00 | kb/i: 0.04
| create and destroy 1k entities with one component ... |
    PASS | us: 897.32 | op/s: 1114.43 | kb/i: 0.36
| create and destroy 1k entities with two components ... |
    PASS | us: 1481.48 | op/s: 675.00 | kb/i: 0.49
| create and destroy 1k entities with three components ... |
    PASS | us: 2126.32 | op/s: 470.30 | kb/i: 0.90
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.31 | op/s: 81248.76 | kb/i: 0.00
| create and destroy 1k entities with one component ... |
    PASS | us: 46.97 | op/s: 21288.56 | kb/i: 0.02
| create and destroy 1k entities with two components ... |
    PASS | us: 75.19 | op/s: 13300.00 | kb/i: 0.03
| create and destroy 1k entities with three components ... |
    PASS | us: 108.28 | op/s: 9235.00 | kb/i: 0.06
]]
