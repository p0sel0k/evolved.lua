local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

local F1, F2, F3, F4, F5 = evo.id(5)

local Q1 = evo.builder():include(F1):spawn()

local B1 = evo.builder()
local B3 = evo.builder()
local B5 = evo.builder()

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
        local set, spawn = B1.set, B1.spawn

        for _ = 1, N do
            set(B1, F1)
            spawn(B1)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 3 components', N),
    function()
        local set, spawn = B3.set, B3.spawn

        for _ = 1, N do
            set(B3, F1)
            set(B3, F2)
            set(B3, F3)
            spawn(B3)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 5 components', N),
    function()
        local set, spawn = B5.set, B5.spawn

        for _ = 1, N do
            set(B5, F1)
            set(B5, F2)
            set(B5, F3)
            set(B5, F4)
            set(B5, F5)
            spawn(B5)
        end

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 1 required component', N),
    function()
        local set, spawn = B1.set, B1.spawn

        for _ = 1, N do
            set(B1, R1)
            spawn(B1)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 3 required components', N),
    function()
        local set, spawn = B3.set, B3.spawn

        for _ = 1, N do
            set(B3, R3)
            spawn(B3)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 5 required components', N),
    function()
        local set, spawn = B5.set, B5.spawn

        for _ = 1, N do
            set(B5, R5)
            spawn(B5)
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
