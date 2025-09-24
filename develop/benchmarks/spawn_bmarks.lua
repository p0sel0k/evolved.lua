local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

local F1, F2, F3, F4, F5 = evo.id(5)

local Q1 = evo.builder():include(F1):spawn()

local R1 = evo.builder():require(F1):spawn()
local R3 = evo.builder():require(F1, F2, F3):spawn()
local R5 = evo.builder():require(F1, F2, F3, F4, F5):spawn()

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 1 component', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 3 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 5 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 1 required component', N),
    function()
        local spawn = evo.spawn

        local components = { [R1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 3 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [R3] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 5 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [R5] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 1 component', N),
    function()
        local builder = evo.builder()

        for _ = 1, N do
            builder:set(F1):spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 3 components', N),
    function()
        local builder = evo.builder()

        for _ = 1, N do
            builder:set(F1):set(F2):set(F3):spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 5 components', N),
    function()
        local builder = evo.builder()

        for _ = 1, N do
            builder:set(F1):set(F2):set(F3):set(F4):set(F5):spawn()
        end

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 1 required component', N),
    function()
        local builder = evo.builder()

        for _ = 1, N do
            builder:set(R1):spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 3 required components', N),
    function()
        local builder = evo.builder()

        for _ = 1, N do
            builder:set(R3):spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 5 required components', N),
    function()
        local builder = evo.builder()

        for _ = 1, N do
            builder:set(R5):spawn()
        end

        evo.batch_destroy(Q1)
    end)
print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 1 component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 3 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 5 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 1 required component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 3 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [R3] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 5 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [R5] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)
