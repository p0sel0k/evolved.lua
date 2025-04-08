local basics = require 'develop.basics'
basics.unload 'evolved'

local evo = require 'evolved'

local N = 1000
local B = evo.entity()
local F1, F2, F3, F4, F5 = evo.id(5)
local Q1 = evo.query():include(F1):build()

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
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 2 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            e[F2] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 3 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            e[F2] = true
            e[F3] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 4 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            e[F2] = true
            e[F3] = true
            e[F4] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 5 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            e[F2] = true
            e[F3] = true
            e[F4] = true
            e[F5] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create %d tables with 1 component / SoA', N),
    ---@param tables table
    function(tables)
        local fs1 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            tables[i] = e
        end
        tables[F1] = fs1
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 2 component / SoA', N),
    ---@param tables table
    function(tables)
        local fs1 = {}
        local fs2 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            fs2[i] = true
            tables[i] = e
        end
        tables[F1] = fs1
        tables[F2] = fs2
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 3 component / SoA', N),
    ---@param tables table
    function(tables)
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
        tables[F1] = fs1
        tables[F2] = fs2
        tables[F3] = fs3
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 4 component / SoA', N),
    ---@param tables table
    function(tables)
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
        tables[F1] = fs1
        tables[F2] = fs2
        tables[F3] = fs3
        tables[F4] = fs4
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 5 component / SoA', N),
    ---@param tables table
    function(tables)
        local fs1 = {}
        local fs2 = {}
        local fs3 = {}
        local fs4 = {}
        local fs5 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = i
            fs2[i] = i
            fs3[i] = i
            fs4[i] = i
            fs5[i] = i
            tables[i] = e
        end
        tables[F1] = fs1
        tables[F2] = fs2
        tables[F3] = fs3
        tables[F4] = fs4
        tables[F5] = fs5
    end, function()
        return {}
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

        for i = #entities, 1, -1 do
            destroy(entities[i])
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 1 component', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            set(e, F5)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            set(e, F5)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local build = B.build

        for i = 1, N do
            set(B, F1)
            entities[i] = build(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local build = B.build

        for i = 1, N do
            set(B, F1)
            set(B, F2)
            entities[i] = build(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local build = B.build

        for i = 1, N do
            set(B, F1)
            set(B, F2)
            set(B, F3)
            entities[i] = build(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local build = B.build

        for i = 1, N do
            set(B, F1)
            set(B, F2)
            set(B, F3)
            set(B, F4)
            entities[i] = build(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local build = B.build

        for i = 1, N do
            set(B, F1)
            set(B, F2)
            set(B, F3)
            set(B, F4)
            set(B, F5)
            entities[i] = build(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / multi-set', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = evo.multi_set

        for i = 1, N do
            local e = evo.id()
            set(e, { F1 })
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / multi-set', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = evo.multi_set

        for i = 1, N do
            local e = evo.id()
            set(e, { F1, F2 })
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / multi-set', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = evo.multi_set

        for i = 1, N do
            local e = evo.id()
            set(e, { F1, F2, F3 })
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / multi-set', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = evo.multi_set

        for i = 1, N do
            local e = evo.id()
            set(e, { F1, F2, F3, F4 })
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / multi-set', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = evo.multi_set

        for i = 1, N do
            local e = evo.id()
            set(e, { F1, F2, F3, F4, F5 })
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / spawn_at', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_at = evo.spawn_at

        local fragments = { F1 }
        local components = { true }

        local chunk = evo.chunk(F1)

        for i = 1, N do
            entities[i] = spawn_at(chunk, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / spawn_at', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_at = evo.spawn_at

        local fragments = { F1, F2 }
        local components = { true, true }

        local chunk = evo.chunk(F1, F2)

        for i = 1, N do
            entities[i] = spawn_at(chunk, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / spawn_at', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_at = evo.spawn_at

        local fragments = { F1, F2, F3 }
        local components = { true, true, true }

        local chunk = evo.chunk(F1, F2, F3)

        for i = 1, N do
            entities[i] = spawn_at(chunk, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / spawn_at', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_at = evo.spawn_at

        local fragments = { F1, F2, F3, F4 }
        local components = { true, true, true, true }

        local chunk = evo.chunk(F1, F2, F3, F4)

        for i = 1, N do
            entities[i] = spawn_at(chunk, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / spawn_at', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_at = evo.spawn_at

        local fragments = { F1, F2, F3, F4, F5 }
        local components = { true, true, true, true, true }

        local chunk = evo.chunk(F1, F2, F3, F4, F5)

        for i = 1, N do
            entities[i] = spawn_at(chunk, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / spawn_as', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_as = evo.spawn_as

        local fragments = { F1 }
        local components = { true }

        local prefab = evo.spawn_with(fragments, components)

        for i = 1, N do
            entities[i] = spawn_as(prefab, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / spawn_as', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_as = evo.spawn_as

        local fragments = { F1, F2 }
        local components = { true, true }

        local prefab = evo.spawn_with(fragments, components)

        for i = 1, N do
            entities[i] = spawn_as(prefab, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / spawn_as', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_as = evo.spawn_as

        local fragments = { F1, F2, F3 }
        local components = { true, true, true }

        local prefab = evo.spawn_with(fragments, components)

        for i = 1, N do
            entities[i] = spawn_as(prefab, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / spawn_as', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_as = evo.spawn_as

        local fragments = { F1, F2, F3, F4 }
        local components = { true, true, true, true }

        local prefab = evo.spawn_with(fragments, components)

        for i = 1, N do
            entities[i] = spawn_as(prefab, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / spawn_as', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_as = evo.spawn_as

        local fragments = { F1, F2, F3, F4, F5 }
        local components = { true, true, true, true, true }

        local prefab = evo.spawn_with(fragments, components)

        for i = 1, N do
            entities[i] = spawn_as(prefab, fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / spawn_with', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_with = evo.spawn_with

        local fragments = { F1 }
        local components = { true }

        for i = 1, N do
            entities[i] = spawn_with(fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / spawn_with', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_with = evo.spawn_with

        local fragments = { F1, F2 }
        local components = { true, true }

        for i = 1, N do
            entities[i] = spawn_with(fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / spawn_with', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_with = evo.spawn_with

        local fragments = { F1, F2, F3 }
        local components = { true, true, true }

        for i = 1, N do
            entities[i] = spawn_with(fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / spawn_with', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_with = evo.spawn_with

        local fragments = { F1, F2, F3, F4 }
        local components = { true, true, true, true }

        for i = 1, N do
            entities[i] = spawn_with(fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / spawn_with', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn_with = evo.spawn_with

        local fragments = { F1, F2, F3, F4, F5 }
        local components = { true, true, true, true, true }

        for i = 1, N do
            entities[i] = spawn_with(fragments, components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'
