local evo = require 'evolved'

do
    local p1, s1 = evo.id(2)
    local pair1 = evo.pair(p1, s1)
    local p2, s2 = evo.unpair(pair1)
    assert(p1 == p2 and s1 == s2)
end

do
    local p, s1, s2 = evo.id(3)

    local e1 = evo.id()
    evo.set(e1, evo.pair(p, s1), 11)

    local e12 = evo.id()
    evo.set(e12, evo.pair(p, s1), 21)
    evo.set(e12, evo.pair(p, s2), 42)

    assert(evo.has(e1, evo.pair(p, s1)))
    assert(evo.get(e1, evo.pair(p, s1)) == 11)
    assert(evo.has(e12, evo.pair(p, s1)))
    assert(evo.get(e12, evo.pair(p, s1)) == 21)

    assert(not evo.has(e1, evo.pair(p, s2)))
    assert(evo.get(e1, evo.pair(p, s2)) == nil)
    assert(evo.has(e12, evo.pair(p, s2)))
    assert(evo.get(e12, evo.pair(p, s2)) == 42)

    assert(evo.has(e1, evo.pair(p, evo.ANY)))
    assert(evo.has(e1, evo.pair(evo.ANY, s1)))
    assert(not evo.has(e1, evo.pair(evo.ANY, s2)))
    assert(evo.has(e12, evo.pair(p, evo.ANY)))
    assert(evo.has(e12, evo.pair(evo.ANY, s1)))
    assert(evo.has(e12, evo.pair(evo.ANY, s2)))

    assert(not evo.has_all(e1, evo.pair(evo.ANY, s1), evo.pair(evo.ANY, s2)))
    assert(evo.has_any(e1, evo.pair(evo.ANY, s1), evo.pair(evo.ANY, s2)))
    assert(evo.has_all(e12, evo.pair(evo.ANY, s1), evo.pair(evo.ANY, s2)))
    assert(evo.has_any(e12, evo.pair(evo.ANY, s1), evo.pair(evo.ANY, s2)))
end

do
    local p1, p2, s = evo.id(3)

    local e1 = evo.id()
    evo.set(e1, evo.pair(p1, s), 11)

    local e12 = evo.id()
    evo.set(e12, evo.pair(p1, s), 21)
    evo.set(e12, evo.pair(p2, s), 42)

    assert(evo.has(e1, evo.pair(p1, s)))
    assert(evo.get(e1, evo.pair(p1, s)) == 11)
    assert(evo.has(e12, evo.pair(p1, s)))
    assert(evo.get(e12, evo.pair(p1, s)) == 21)

    assert(not evo.has(e1, evo.pair(p2, s)))
    assert(evo.get(e1, evo.pair(p2, s)) == nil)
    assert(evo.has(e12, evo.pair(p2, s)))
    assert(evo.get(e12, evo.pair(p2, s)) == 42)

    assert(evo.has(e1, evo.pair(p1, evo.ANY)))
    assert(not evo.has(e1, evo.pair(p2, evo.ANY)))
    assert(evo.has(e1, evo.pair(evo.ANY, s)))
    assert(evo.has(e12, evo.pair(p1, evo.ANY)))
    assert(evo.has(e12, evo.pair(p2, evo.ANY)))
    assert(evo.has(e12, evo.pair(evo.ANY, s)))

    assert(not evo.has_all(e1, evo.pair(p1, evo.ANY), evo.pair(p2, evo.ANY)))
    assert(evo.has_any(e1, evo.pair(p1, evo.ANY), evo.pair(p2, evo.ANY)))
    assert(evo.has_all(e12, evo.pair(p1, evo.ANY), evo.pair(p2, evo.ANY)))
    assert(evo.has_any(e12, evo.pair(p1, evo.ANY), evo.pair(p2, evo.ANY)))
end

do
    local p1, s1, p2, s2 = evo.id(4)
    evo.set(p1, s1)
    evo.set(s1, p1)
    evo.set(p2, s2)
    assert(evo.empty(evo.pair(p1, s1)))
    assert(evo.empty(evo.pair(p2, s2)))
    assert(evo.empty_all(evo.pair(p1, s1), evo.pair(p2, s2)))
    assert(evo.empty_any(evo.pair(p1, s1), evo.pair(p2, s2)))
    assert(not evo.empty_all(evo.pair(p1, s1), evo.pair(p2, s2), p1))
    assert(evo.empty_any(evo.pair(p1, s1), evo.pair(p2, s2), p1))
    assert(evo.empty_all(evo.pair(p1, s1), evo.pair(p2, s2), s2))
    assert(evo.empty_any(evo.pair(p1, s1), evo.pair(p2, s2), s2))
end
