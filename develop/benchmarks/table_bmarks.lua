local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

local F1, F2, F3, F4, F5 = evo.id(5)

print '----------------------------------------'

basics.describe_bench(string.format('Table Benchmarks: Allocate %d tables', N),
    function(tables)
        for i = 1, N do
            local t = {}
            tables[i] = t
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('Table Benchmarks: Allocate and Collect %d tables', N),
    function(tables)
        for i = 1, N do
            local t = {}
            tables[i] = t
        end

        for i = 1, N do
            tables[i] = nil
        end

        collectgarbage('collect')
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Table Benchmarks: Allocate %d tables with 1 component / AoS', N),
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('Table Benchmarks: Allocate %d tables with 3 components / AoS', N),
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

basics.describe_bench(string.format('Table Benchmarks: Allocate %d tables with 5 components / AoS', N),
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

basics.describe_bench(string.format('Table Benchmarks: Allocate %d tables with 1 component / SoA', N),
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

basics.describe_bench(string.format('Table Benchmarks: Allocate %d tables with 3 components / SoA', N),
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

basics.describe_bench(string.format('Table Benchmarks: Allocate %d tables with 5 components / SoA', N),
    function(tables)
        local fs1 = {}
        local fs2 = {}
        local fs3 = {}
        local fs4 = {}
        local fs5 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            fs2[i] = true
            fs3[i] = true
            fs4[i] = true
            fs5[i] = true
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
