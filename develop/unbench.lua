package.loaded['evolved'] = nil
local evo = require 'evolved'

local basics = require 'develop.basics'

local N = 1000

print '----------------------------------------'

basics.describe_bench(string.format('create %d tables', N),
    ---@param tables table[]
    function(tables)
        for i = 1, N do
            local t = {}
            tables[i] = t
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and collect %d tables', N),
    ---@param tables table[]
    function(tables)
        for i = 1, N do
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

print '----------------------------------------'

basics.describe_bench(string.format('create %d tables with 1 component / AoS', N),
    ---@param f1 table
    ---@param tables table
    function(f1, tables)
        for i = 1, N do
            local e = {}
            e[f1] = true
            tables[i] = e
        end
    end, function()
        local f1 = {}
        return f1, {}
    end)

basics.describe_bench(string.format('create %d tables with 2 component / AoS', N),
    ---@param f1 table
    ---@param f2 table
    ---@param tables table
    function(f1, f2, tables)
        for i = 1, N do
            local e = {}
            e[f1] = true
            e[f2] = true
            tables[i] = e
        end
    end, function()
        local f1, f2 = {}, {}
        return f1, f2, {}
    end)

basics.describe_bench(string.format('create %d tables with 3 component / AoS', N),
    ---@param f1 table
    ---@param f2 table
    ---@param f3 table
    ---@param tables table
    function(f1, f2, f3, tables)
        for i = 1, N do
            local e = {}
            e[f1] = true
            e[f2] = true
            e[f3] = true
            tables[i] = e
        end
    end, function()
        local f1, f2, f3 = {}, {}, {}
        return f1, f2, f3, {}
    end)

basics.describe_bench(string.format('create %d tables with 4 component / AoS', N),
    ---@param f1 table
    ---@param f2 table
    ---@param f3 table
    ---@param f4 table
    ---@param tables table
    function(f1, f2, f3, f4, tables)
        for i = 1, N do
            local e = {}
            e[f1] = true
            e[f2] = true
            e[f3] = true
            e[f4] = true
            tables[i] = e
        end
    end, function()
        local f1, f2, f3, f4 = {}, {}, {}, {}
        return f1, f2, f3, f4, {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create %d tables with 1 component / SoA', N),
    ---@param f1 table
    ---@param tables table
    function(f1, tables)
        local fs1 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            tables[i] = e
        end
        tables[f1] = fs1
    end, function()
        local f1 = {}
        return f1, {}
    end)

basics.describe_bench(string.format('create %d tables with 2 component / SoA', N),
    ---@param f1 table
    ---@param f2 table
    ---@param tables table
    function(f1, f2, tables)
        local fs1 = {}
        local fs2 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            fs2[i] = true
            tables[i] = e
        end
        tables[f1] = fs1
        tables[f2] = fs2
    end, function()
        local f1, f2 = {}, {}
        return f1, f2, {}
    end)

basics.describe_bench(string.format('create %d tables with 3 component / SoA', N),
    ---@param f1 table
    ---@param f2 table
    ---@param f3 table
    ---@param tables table
    function(f1, f2, f3, tables)
        local fs1 = {}
        local fs2 = {}
        local fs3 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            fs2[i] = true
            fs3[i] = true
            tables[i] = e
        end
        tables[f1] = fs1
        tables[f2] = fs2
        tables[f3] = fs3
    end, function()
        local f1, f2, f3 = {}, {}, {}
        return f1, f2, f3, {}
    end)

basics.describe_bench(string.format('create %d tables with 4 component / SoA', N),
    ---@param f1 table
    ---@param f2 table
    ---@param f3 table
    ---@param f4 table
    ---@param tables table
    function(f1, f2, f3, f4, tables)
        local fs1 = {}
        local fs2 = {}
        local fs3 = {}
        local fs4 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = i
            fs2[i] = i
            fs3[i] = i
            fs4[i] = i
            tables[i] = e
        end
        tables[f1] = fs1
        tables[f2] = fs2
        tables[f3] = fs3
        tables[f4] = fs4
    end, function()
        local f1, f2, f3, f4 = {}, {}, {}, {}
        return f1, f2, f3, f4, {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local destroy = evo.destroy

        for i = 1, N do
            local e = id()
            entities[i] = e
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 1 component', N),
    ---@param f1 evolved.fragment
    ---@param entities evolved.id[]
    function(f1, entities)
        local id = evo.id
        local insert = evo.insert
        local destroy = evo.destroy

        for i = 1, N do
            local e = id()
            insert(e, f1)
            entities[i] = e
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local f1 = evo.id(2)
        return f1, {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components', N),
    ---@param f1 evolved.fragment
    ---@param f2 evolved.fragment
    ---@param entities evolved.id[]
    function(f1, f2, entities)
        local id = evo.id
        local insert = evo.insert
        local destroy = evo.destroy

        for i = 1, N do
            local e = id()
            insert(e, f1)
            insert(e, f2)
            entities[i] = e
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local f1, f2 = evo.id(2)
        return f1, f2, {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components', N),
    ---@param f1 evolved.fragment
    ---@param f2 evolved.fragment
    ---@param f3 evolved.fragment
    ---@param entities evolved.id[]
    function(f1, f2, f3, entities)
        local id = evo.id
        local insert = evo.insert
        local destroy = evo.destroy

        for i = 1, N do
            local e = id()
            insert(e, f1)
            insert(e, f2)
            insert(e, f3)
            entities[i] = e
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local f1, f2, f3 = evo.id(3)
        return f1, f2, f3, {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components', N),
    ---@param f1 evolved.fragment
    ---@param f2 evolved.fragment
    ---@param f3 evolved.fragment
    ---@param f4 evolved.fragment
    ---@param entities evolved.id[]
    function(f1, f2, f3, f4, entities)
        local id = evo.id
        local insert = evo.insert
        local destroy = evo.destroy

        for i = 1, N do
            local e = id()
            insert(e, f1)
            insert(e, f2)
            insert(e, f3)
            insert(e, f4)
            entities[i] = e
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local f1, f2, f3, f4 = evo.id(4)
        return f1, f2, f3, f4, {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities / builder', N),
    ---@param b evolved.entity_builder
    ---@param entities evolved.id[]
    function(b, entities)
        local build = b.build
        local destroy = evo.destroy

        for i = 1, N do
            entities[i] = build(b)
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local b = evo.entity()
        return b, {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 1 components / builder', N),
    ---@param b evolved.entity_builder
    ---@param f1 evolved.fragment
    ---@param entities evolved.id[]
    function(b, f1, entities)
        local set = b.set
        local build = b.build
        local destroy = evo.destroy

        for i = 1, N do
            set(b, f1)
            entities[i] = build(b)
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local b = evo.entity()
        local f1 = evo.id(1)
        return b, f1, {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / builder', N),
    ---@param b evolved.entity_builder
    ---@param f1 evolved.fragment
    ---@param f2 evolved.fragment
    ---@param entities evolved.id[]
    function(b, f1, f2, entities)
        local set = b.set
        local build = b.build
        local destroy = evo.destroy

        for i = 1, N do
            set(b, f1)
            set(b, f2)
            entities[i] = build(b)
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local b = evo.entity()
        local f1, f2 = evo.id(2)
        return b, f1, f2, {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / builder', N),
    ---@param b evolved.entity_builder
    ---@param f1 evolved.fragment
    ---@param f2 evolved.fragment
    ---@param f3 evolved.fragment
    ---@param entities evolved.id[]
    function(b, f1, f2, f3, entities)
        local set = b.set
        local build = b.build
        local destroy = evo.destroy

        for i = 1, N do
            set(b, f1)
            set(b, f2)
            set(b, f3)
            entities[i] = build(b)
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local b = evo.entity()
        local f1, f2, f3 = evo.id(3)
        return b, f1, f2, f3, {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / builder', N),
    ---@param b evolved.entity_builder
    ---@param f1 evolved.fragment
    ---@param f2 evolved.fragment
    ---@param f3 evolved.fragment
    ---@param f4 evolved.fragment
    ---@param entities evolved.id[]
    function(b, f1, f2, f3, f4, entities)
        local set = b.set
        local build = b.build
        local destroy = evo.destroy

        for i = 1, N do
            set(b, f1)
            set(b, f2)
            set(b, f3)
            set(b, f4)
            entities[i] = build(b)
        end

        for i = 1, #entities do
            destroy(entities[i])
        end
    end, function()
        local b = evo.entity()
        local f1, f2, f3, f4 = evo.id(4)
        return b, f1, f2, f3, f4, {}
    end)

print '----------------------------------------'

---
--- initial
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 312.60 | op/s: 3199.00 | kb/i: 0.05
| create and destroy 1k entities with 1 component ... |
    PASS | us: 1570.31 | op/s: 636.82 | kb/i: 0.63
| create and destroy 1k entities with 2 components ... |
    PASS | us: 2780.82 | op/s: 359.61 | kb/i: 0.91
| create and destroy 1k entities with 3 components ... |
    PASS | us: 4060.00 | op/s: 246.31 | kb/i: 1.67
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.22 | op/s: 81840.80 | kb/i: 0.00
| create and destroy 1k entities with 1 component ... |
    PASS | us: 56.22 | op/s: 17786.07 | kb/i: 0.02
| create and destroy 1k entities with 2 components ... |
    PASS | us: 412.73 | op/s: 2422.89 | kb/i: 0.11
| create and destroy 1k entities with 3 components ... |
    PASS | us: 611.62 | op/s: 1635.00 | kb/i: 0.17
]]

---
--- unpack ids without dedicated functions
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 255.40 | op/s: 3915.42 | kb/i: 0.04
| create and destroy 1k entities with 1 component ... |
    PASS | us: 1248.45 | op/s: 801.00 | kb/i: 0.50
| create and destroy 1k entities with 2 components ... |
    PASS | us: 2208.79 | op/s: 452.74 | kb/i: 0.73
| create and destroy 1k entities with 3 components ... |
    PASS | us: 3278.69 | op/s: 305.00 | kb/i: 1.37
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.12 | op/s: 82482.59 | kb/i: 0.00
| create and destroy 1k entities with 1 component ... |
    PASS | us: 69.05 | op/s: 14482.59 | kb/i: 0.03
| create and destroy 1k entities with 2 components ... |
    PASS | us: 400.40 | op/s: 2497.51 | kb/i: 0.09
| create and destroy 1k entities with 3 components ... |
    PASS | us: 574.71 | op/s: 1740.00 | kb/i: 0.14
]]

---
--- hook flags for chunks
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 255.40 | op/s: 3915.42 | kb/i: 0.04
| create and destroy 1k entities with 1 component ... |
    PASS | us: 1005.03 | op/s: 995.00 | kb/i: 0.41
| create and destroy 1k entities with 2 components ... |
    PASS | us: 1747.83 | op/s: 572.14 | kb/i: 0.59
| create and destroy 1k entities with 3 components ... |
    PASS | us: 2576.92 | op/s: 388.06 | kb/i: 1.08
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.20 | op/s: 81940.30 | kb/i: 0.00
| create and destroy 1k entities with 1 component ... |
    PASS | us: 53.66 | op/s: 18636.82 | kb/i: 0.02
| create and destroy 1k entities with 2 components ... |
    PASS | us: 357.02 | op/s: 2801.00 | kb/i: 0.09
| create and destroy 1k entities with 3 components ... |
    PASS | us: 533.33 | op/s: 1875.00 | kb/i: 0.15
]]

---
--- construct flags for chunks
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 253.49 | op/s: 3945.00 | kb/i: 0.04
| create and destroy 1k entities with 1 component ... |
    PASS | us: 913.64 | op/s: 1094.53 | kb/i: 0.37
| create and destroy 1k entities with 2 components ... |
    PASS | us: 1562.50 | op/s: 640.00 | kb/i: 0.53
| create and destroy 1k entities with 3 components ... |
    PASS | us: 2280.90 | op/s: 438.42 | kb/i: 0.97
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.05 | op/s: 82995.02 | kb/i: 0.00
| create and destroy 1k entities with 1 component ... |
    PASS | us: 53.61 | op/s: 18651.74 | kb/i: 0.02
| create and destroy 1k entities with 2 components ... |
    PASS | us: 232.02 | op/s: 4310.00 | kb/i: 0.06
| create and destroy 1k entities with 3 components ... |
    PASS | us: 329.49 | op/s: 3035.00 | kb/i: 0.10
]]

---
--- after chunks refactoring
---

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 254.45 | op/s: 3930.00 | kb/i: 0.04
| create and destroy 1k entities with 1 component ... |
    PASS | us: 897.32 | op/s: 1114.43 | kb/i: 0.36
| create and destroy 1k entities with 2 components ... |
    PASS | us: 1481.48 | op/s: 675.00 | kb/i: 0.49
| create and destroy 1k entities with 3 components ... |
    PASS | us: 2126.32 | op/s: 470.30 | kb/i: 0.90
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.31 | op/s: 81248.76 | kb/i: 0.00
| create and destroy 1k entities with 1 component ... |
    PASS | us: 46.97 | op/s: 21288.56 | kb/i: 0.02
| create and destroy 1k entities with 2 components ... |
    PASS | us: 75.19 | op/s: 13300.00 | kb/i: 0.03
| create and destroy 1k entities with 3 components ... |
    PASS | us: 108.28 | op/s: 9235.00 | kb/i: 0.06
]]
