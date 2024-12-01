---@diagnostic disable: invisible
local evo = require 'evolved.evolved'

do
    local f = evo.registry.entity()
    local e = evo.registry.entity()
    local d = evo.defers.defer():set(e, f, 42)
    assert(not e:has(f))
    assert(d == d:playback())
    assert(e:get(f) == 42)

    evo.defers.defer():set(e, f, 84):playback()
    assert(e:get(f) == 84)
end

do
    local mul2 = function(v) return v * 2 end

    local f1, f2 = evo.registry.entity(), evo.registry.entity()
    local e = evo.registry.entity():set(f1, 21)
    local d = evo.defers.defer():apply(e, mul2, f1)
    assert(e:get(f1) == 21)
    assert(d == d:playback())
    assert(e:get(f1) == 42)

    evo.defers.defer():apply(e, mul2, f2):playback()
    assert(not e:has(f2) and e:get(f1) == 42)
end

do
    local mul2 = function(v) return v * 2 end
    local mul3 = function(v) return v * 3 end

    local f1, f2 = evo.registry.entity(), evo.registry.entity()
    local e = evo.registry.entity():set(f1, 21):set(f2, 42)
    local d = evo.defers.defer():apply(e, mul2, f1):apply(e, mul3, f2)
    assert(e:get(f1) == 21 and e:get(f2) == 42)
    assert(d == d:playback())
    assert(e:get(f1) == 42 and e:get(f2) == 126)
end

do
    local f = evo.registry.entity()
    local e = evo.registry.entity():set(f, 21)
    local d = evo.defers.defer():assign(e, f, 42)
    assert(e:get(f) == 21)
    assert(d == d:playback())
    assert(e:get(f) == 42)

    evo.defers.defer():assign(e, f, 84):playback()
    assert(e:get(f) == 84)
end

do
    local f = evo.registry.entity()
    local e = evo.registry.entity()
    local d = evo.defers.defer():insert(e, f, 42)
    assert(not e:has(f))
    assert(d == d:playback())
    assert(e:get(f) == 42)

    evo.defers.defer():insert(e, f, 84):playback()
    assert(e:get(f) == 42)
end

do
    local f = evo.registry.entity()
    local e = evo.registry.entity():set(f, 21)
    local d = evo.defers.defer():remove(e)
    assert(e:get(f) == 21)
    assert(d == d:playback())
    assert(e:get(f) == 21)
end

do
    local f = evo.registry.entity()
    local e = evo.registry.entity():set(f, 21)
    local d = evo.defers.defer():remove(e, f)
    assert(e:get(f) == 21)
    assert(d == d:playback())
    assert(not e:has(f))
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()
    local e = evo.registry.entity():set(f1, 21):set(f2, 42)
    assert(e:get(f1) == 21 and e:get(f2) == 42)
    evo.defers.defer():remove(e, f1, f2):playback()
    assert(not e:has(f1) and not e:has(f2))
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()
    local e = evo.registry.entity():set(f1, 4):set(f2, 2)
    local d = evo.defers.defer():detach(e)
    assert(e:alive() and e:has_all(f1, f2))
    assert(d == d:playback())
    assert(e:alive() and not e:has_any(f1, f2))
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()
    local e = evo.registry.entity():set(f1, 4):set(f2, 2)
    local d = evo.defers.defer():destroy(e)
    assert(e:alive() and e:has_all(f1, f2))
    assert(d == d:playback())
    assert(not e:alive() and not e:has_any(f1, f2))
end
