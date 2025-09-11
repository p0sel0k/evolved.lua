local evo = require 'evolved'
local basics = require 'develop.basics'

local N = 1000

local F1, F2, F3, F4, F5 = evo.id(5)
local Q1 = evo.builder():include(F1):spawn()

print '----------------------------------------'

basics.describe_bench(string.format('Multi Spawn Benchmarks: Simple Spawn | %d entities with 1 component', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Multi Spawn Benchmarks: Simple Spawn | %d entities with 5 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Multi Spawn Benchmarks: Multi Spawn | %d entities with 1 component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Multi Spawn Benchmarks: Multi Spawn | %d entities with 5 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)
