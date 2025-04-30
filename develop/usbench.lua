local basics = require 'develop.basics'
basics.unload 'evolved'

local evo = require 'evolved'
local tiny = require 'develop.3rdparty.tiny'

local N = 1000

print '----------------------------------------'

basics.describe_bench(string.format('Tiny Entity Cycle: %d entities', N),
    function(world)
        world:update(0.016)
    end, function()
        local world = tiny.world()

        for i = 1, N do
            world:addEntity({ a = i })
        end

        local A = tiny.processingSystem()
        A.filter = tiny.requireAll('a')
        A.process = function(_, e) world:addEntity({ b = e.a }) end
        A.postProcess = function(_) world:refresh() end

        local B = tiny.processingSystem()
        B.filter = tiny.requireAll('b')
        B.process = function(_, e) world:removeEntity(e) end
        B.postProcess = function(_) world:refresh() end

        world:addSystem(A)
        world:addSystem(B)

        world:refresh()

        return world
    end)

basics.describe_bench(string.format('Evolved Entity Cycle (Defer): %d entities', N),
    function(a, b, A, B)
        evo.defer()
        do
            for chunk, _, entity_count in evo.execute(A) do
                local as = chunk:components(a)
                for i = 1, entity_count do
                    evo.set(evo.id(), b, as[i])
                end
            end
        end
        evo.commit()

        evo.batch_destroy(B)
    end, function()
        local a, b = evo.id(2)

        for i = 1, N do
            evo.builder():set(a, i):spawn()
        end

        local A = evo.builder():include(a):spawn()
        local B = evo.builder():include(b):spawn()

        return a, b, A, B
    end, function(_, _, A, _)
        evo.batch_destroy(A)
    end)

basics.describe_bench(string.format('Evolved Entity Cycle (Manual): %d entities', N),
    function(a, b, A, B)
        local to_create = {}
        local to_create_count = 0

        for chunk, _, entity_count in evo.execute(A) do
            local as = chunk:components(a)
            for i = 1, entity_count do
                to_create_count = to_create_count + 1
                to_create[to_create_count] = as[i]
            end
        end

        for i = 1, to_create_count do
            local e = evo.id()
            evo.set(e, b, to_create[i])
        end

        evo.batch_destroy(B)
    end, function()
        local a, b = evo.id(2)

        for i = 1, N do
            evo.builder():set(a, i):spawn()
        end

        local A = evo.builder():include(a):spawn()
        local B = evo.builder():include(b):spawn()

        return a, b, A, B
    end, function(_, _, A, _)
        evo.batch_destroy(A)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Tiny Simple Iteration: %d entities', N),
    function(world)
        world:update(0.016)
    end, function()
        local world = tiny.world()

        for i = 1, N do
            world:addEntity({ a = i, b = i })
            world:addEntity({ a = i, b = i, c = i })
            world:addEntity({ a = i, b = i, c = i, d = i })
            world:addEntity({ a = i, b = i, c = i, e = i })
        end

        local AB = tiny.processingSystem()
        AB.filter = tiny.requireAll('a', 'b')
        AB.process = function(_, e) e.a, e.b = e.b, e.a end

        local CD = tiny.processingSystem()
        CD.filter = tiny.requireAll('c', 'd')
        CD.process = function(_, e) e.c, e.d = e.d, e.c end

        local CE = tiny.processingSystem()
        CE.filter = tiny.requireAll('c', 'e')
        CE.process = function(_, e) e.c, e.e = e.e, e.c end

        world:addSystem(AB)
        world:addSystem(CD)
        world:addSystem(CE)

        world:refresh()

        return world
    end)

basics.describe_bench(string.format('Evolved Simple Iteration: %d entities', N),
    ---@param a evolved.entity
    ---@param b evolved.entity
    ---@param c evolved.entity
    ---@param d evolved.entity
    ---@param e evolved.entity
    ---@param AB evolved.query
    ---@param CD evolved.query
    ---@param CE evolved.query
    function(a, b, c, d, e, AB, CD, CE)
        for chunk, _, entity_count in evo.execute(AB) do
            local as, bs = chunk:components(a, b)
            for i = 1, entity_count do
                as[i], bs[i] = bs[i], as[i]
            end
        end

        for chunk, _, entity_count in evo.execute(CD) do
            local cs, ds = chunk:components(c, d)
            for i = 1, entity_count do
                cs[i], ds[i] = ds[i], cs[i]
            end
        end

        for chunk, _, entity_count in evo.execute(CE) do
            local cs, es = chunk:components(c, e)
            for i = 1, entity_count do
                cs[i], es[i] = es[i], cs[i]
            end
        end
    end, function()
        local a, b, c, d, e = evo.id(5)

        for i = 1, N do
            evo.builder():set(a, i):set(b, i):spawn()
            evo.builder():set(a, i):set(b, i):set(c, i):spawn()
            evo.builder():set(a, i):set(b, i):set(c, i):set(d, i):spawn()
            evo.builder():set(a, i):set(b, i):set(c, i):set(e, i):spawn()
        end

        local AB = evo.builder():include(a, b):spawn()
        local CD = evo.builder():include(c, d):spawn()
        local CE = evo.builder():include(c, e):spawn()

        return a, b, c, d, e, AB, CD, CE
    end, function(_, _, _, _, _, AB, CD, CE)
        evo.batch_destroy(AB)
        evo.batch_destroy(CD)
        evo.batch_destroy(CE)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Tiny Packed Iteration: %d entities', N),
    function(world)
        world:update(0.016)
    end, function()
        local world = tiny.world()

        for i = 1, N do
            world:addEntity({ a = i, b = i, c = i, d = i, e = i })
        end

        local A = tiny.processingSystem()
        A.filter = tiny.requireAll('a')
        A.process = function(_, e) e.a = e.a * 2 end

        local B = tiny.processingSystem()
        B.filter = tiny.requireAll('b')
        B.process = function(_, e) e.b = e.b * 2 end

        local C = tiny.processingSystem()
        C.filter = tiny.requireAll('c')
        C.process = function(_, e) e.c = e.c * 2 end

        local D = tiny.processingSystem()
        D.filter = tiny.requireAll('d')
        D.process = function(_, e) e.d = e.d * 2 end

        local E = tiny.processingSystem()
        E.filter = tiny.requireAll('e')
        E.process = function(_, e) e.e = e.e * 2 end

        world:addSystem(A)
        world:addSystem(B)
        world:addSystem(C)
        world:addSystem(D)
        world:addSystem(E)

        world:refresh()

        return world
    end)

basics.describe_bench(string.format('Evolved Packed Iteration: %d entities', N),
    ---@param a evolved.entity
    ---@param b evolved.entity
    ---@param c evolved.entity
    ---@param d evolved.entity
    ---@param e evolved.entity
    ---@param A evolved.query
    ---@param B evolved.query
    ---@param C evolved.query
    ---@param D evolved.query
    ---@param E evolved.query
    function(a, b, c, d, e, A, B, C, D, E)
        for chunk, _, entity_count in evo.execute(A) do
            local as = chunk:components(a)
            for i = 1, entity_count do
                as[i] = as[i] * 2
            end
        end

        for chunk, _, entity_count in evo.execute(B) do
            local bs = chunk:components(b)
            for i = 1, entity_count do
                bs[i] = bs[i] * 2
            end
        end

        for chunk, _, entity_count in evo.execute(C) do
            local cs = chunk:components(c)
            for i = 1, entity_count do
                cs[i] = cs[i] * 2
            end
        end

        for chunk, _, entity_count in evo.execute(D) do
            local ds = chunk:components(d)
            for i = 1, entity_count do
                ds[i] = ds[i] * 2
            end
        end

        for chunk, _, entity_count in evo.execute(E) do
            local es = chunk:components(e)
            for i = 1, entity_count do
                es[i] = es[i] * 2
            end
        end
    end, function()
        local a, b, c, d, e = evo.id(5)

        for i = 1, N do
            evo.builder():set(a, i):set(b, i):set(c, i):set(d, i):set(e, i):spawn()
        end

        local A = evo.builder():include(a):spawn()
        local B = evo.builder():include(b):spawn()
        local C = evo.builder():include(c):spawn()
        local D = evo.builder():include(d):spawn()
        local E = evo.builder():include(e):spawn()

        return a, b, c, d, e, A, B, C, D, E
    end, function(_, _, _, _, _, A, _, _, _, _)
        evo.batch_destroy(A)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Tiny Fragmented Iteration: %d entities', N),
    function(world)
        world:update(0.016)
    end, function()
        local world = tiny.world()

        ---@type string[]
        local chars = {}

        for i = 1, 26 do
            chars[i] = string.char(string.byte('a') + i - 1)
        end

        for _, char in ipairs(chars) do
            for i = 1, N do
                world:addEntity({ [char] = i, data = i })
            end
        end

        local Data = tiny.processingSystem()
        Data.filter = tiny.requireAll('data')
        Data.process = function(_, e) e.data = e.data * 2 end

        local Last = tiny.processingSystem()
        Last.filter = tiny.requireAll('z')
        Last.process = function(_, e) e.z = e.z * 2 end

        world:addSystem(Data)
        world:addSystem(Last)

        world:refresh()

        return world
    end)

basics.describe_bench(string.format('Evolved Fragmented Iteration: %d entities', N),
    ---@param data evolved.entity
    ---@param last evolved.entity
    ---@param Data evolved.query
    ---@param Last evolved.query
    function(data, last, Data, Last)
        for chunk, _, entity_count in evo.execute(Data) do
            local ds = chunk:components(data)
            for i = 1, entity_count do
                ds[i] = ds[i] * 2
            end
        end

        for chunk, _, entity_count in evo.execute(Last) do
            local ls = chunk:components(last)
            for i = 1, entity_count do
                ls[i] = ls[i] * 2
            end
        end
    end, function()
        local data = evo.id()

        ---@type evolved.fragment[]
        local chars = {}

        for i = 1, 26 do
            chars[i] = evo.id()
        end

        for _, char in ipairs(chars) do
            for i = 1, N do
                evo.builder():set(char, i):set(data, i):spawn()
            end
        end

        local Data = evo.builder():include(data):spawn()
        local Last = evo.builder():include(chars[#chars]):spawn()

        return data, chars[#chars], Data, Last
    end, function(_, _, Data, _)
        evo.batch_destroy(Data)
    end)
