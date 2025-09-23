local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

local F1, F2, F3, F4, F5 = evo.id(5)

local Q1 = evo.builder():include(F1):spawn()

print '----------------------------------------'

basics.describe_bench(string.format('Migration Benchmarks: Defer Set | %d entities with 1 component', N),
    function()
        local id, set = evo.id, evo.set

        evo.defer()
        for _ = 1, N do
            local e = id()
            set(e, F1)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Migration Benchmarks: Defer Set | %d entities with 3 components', N),
    function()
        local id, set = evo.id, evo.set

        evo.defer()
        for _ = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Migration Benchmarks: Defer Set | %d entities with 5 components', N),
    function()
        local id, set = evo.id, evo.set

        evo.defer()
        for _ = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            set(e, F5)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Migration Benchmarks: Simple Set | %d entities with 1 component', N),
    function()
        local id, set = evo.id, evo.set

        for _ = 1, N do
            local e = id()
            set(e, F1)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Migration Benchmarks: Simple Set | %d entities with 3 components', N),
    function()
        local id, set = evo.id, evo.set

        for _ = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Migration Benchmarks: Simple Set | %d entities with 5 components', N),
    function()
        local id, set = evo.id, evo.set

        for _ = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            set(e, F5)
        end

        evo.batch_destroy(Q1)
    end)
