local common = require 'develop.unbench.common_unbench'

local tiny = require 'develop.3rdparty.tiny'

print '********************'
print '***** tiny-ecs *****'
print '********************'

common.describe('Packed Iteration', function(w)
    tiny.update(w, 0.016)
end, function()
    local w = tiny.world()

    for _ = 1, 10000 do
        tiny.addEntity(w, { a = 0, b = 0, c = 0, d = 0, e = 0 })
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

    tiny.addSystem(w, A)
    tiny.addSystem(w, B)
    tiny.addSystem(w, C)
    tiny.addSystem(w, D)
    tiny.addSystem(w, E)

    tiny.refresh(w)
    return w
end)

common.describe('Simple Iteration', function(w)
    tiny.update(w, 0.016)
end, function()
    local w = tiny.world()

    for _ = 1, 10000 do
        tiny.addEntity(w, { a = 0, b = 0 })
        tiny.addEntity(w, { a = 0, b = 0, c = 0 })
        tiny.addEntity(w, { a = 0, b = 0, c = 0, d = 0 })
        tiny.addEntity(w, { a = 0, b = 0, c = 0, e = 0 })
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

    tiny.addSystem(w, AB)
    tiny.addSystem(w, CD)
    tiny.addSystem(w, CE)

    tiny.refresh(w)
    return w
end)

common.describe('Fragmented Iteration', function(w)
    tiny.update(w, 0.016)
end, function()
    local w = tiny.world()

    for i = 1, 26 do
        for _ = 1, 10000 do
            local char = string.char(string.byte('a') + i - 1)
            tiny.addEntity(w, { [char] = 0, data = 0 })
        end
    end

    local Data = tiny.processingSystem()
    Data.filter = tiny.requireAll('data')
    Data.process = function(_, e) e.data = e.data * 2 end

    local Z = tiny.processingSystem()
    Z.filter = tiny.requireAll('z')
    Z.process = function(_, e) e.z = e.z * 2 end

    tiny.addSystem(w, Data)
    tiny.addSystem(w, Z)

    tiny.refresh(w)
    return w
end)

common.describe('Entity Cycle', function(w)
    tiny.update(w, 0.016)
end, function()
    local w = tiny.world()

    for _ = 1, 1000 do
        tiny.addEntity(w, { a = 0 })
    end

    local A = tiny.processingSystem()
    A.filter = tiny.requireAll('a')
    A.process = function(_, e) tiny.addEntity(w, { b = e.a }) end
    A.postProcess = function(_) tiny.refresh(w) end

    local B = tiny.processingSystem()
    B.filter = tiny.requireAll('b')
    B.process = function(_, e) tiny.removeEntity(w, e) end
    B.postProcess = function(_) tiny.refresh(w) end

    tiny.addSystem(w, A)
    tiny.addSystem(w, B)

    tiny.refresh(w)
    return w
end)

common.describe('Add / Remove', function(w)
    tiny.update(w, 0.016)
end, function()
    local w = tiny.world()

    for _ = 1, 10000 do
        tiny.addEntity(w, { a = 0 })
    end

    local A = tiny.processingSystem()
    A.filter = tiny.requireAll('a')
    A.process = function(_, e)
        e.b = 0
        tiny.addEntity(w, e)
    end
    A.postProcess = function(_) tiny.refresh(w) end

    local AB = tiny.processingSystem()
    AB.filter = tiny.requireAll('a', 'b')
    AB.process = function(_, e)
        e.b = nil
        tiny.addEntity(w, e)
    end
    AB.postProcess = function(_) tiny.refresh(w) end

    tiny.addSystem(w, A)
    tiny.addSystem(w, AB)

    tiny.refresh(w)
    return w
end)
