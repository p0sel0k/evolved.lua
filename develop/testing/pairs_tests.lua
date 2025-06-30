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

do
    local p1, s1 = evo.id(2)
    evo.set(p1, s1)
    evo.set(s1, p1)
    assert(not evo.has(evo.pair(p1, s1), p1))
    assert(not evo.has(evo.pair(p1, s1), s1))
    assert(not evo.has_all(evo.pair(p1, s1), p1, s1))
    assert(not evo.has_any(evo.pair(p1, s1), p1, s1))
    assert(evo.get(evo.pair(p1, s1), p1) == nil)
    assert(evo.get(evo.pair(p1, s1), s1) == nil)
end

do
    local p, s1, s2 = evo.id(3)

    do
        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        evo.remove(e, evo.pair(p, s1))

        assert(not evo.has(e, evo.pair(p, s1)))
        assert(evo.get(e, evo.pair(p, s1)) == nil)

        assert(evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == 42)

        evo.remove(e, evo.pair(p, s2))

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        evo.remove(e, evo.pair(p, s2))

        assert(evo.has(e, evo.pair(p, s1)))
        assert(evo.get(e, evo.pair(p, s1)) == 21)

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)

        evo.remove(e, evo.pair(p, s1))

        assert(not evo.has(e, evo.pair(p, s1)))
        assert(evo.get(e, evo.pair(p, s1)) == nil)

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)
    end
end

do
    local p1, p2, s1, s2 = evo.id(4)

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :spawn()

        evo.remove(e, evo.pair(p1, evo.ANY))

        assert(not evo.has(e, evo.pair(p1, s1)))
        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(not evo.has(e, evo.pair(p1, evo.ANY)))

        assert(evo.has(e, evo.pair(p2, s1)))
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
        assert(evo.has(e, evo.pair(p2, s2)))
        assert(evo.get(e, evo.pair(p2, s2)) == 22)
        assert(evo.has(e, evo.pair(p2, evo.ANY)))
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :spawn()

        evo.remove(e, evo.pair(p2, evo.ANY))

        assert(not evo.has(e, evo.pair(p2, s1)))
        assert(not evo.has(e, evo.pair(p2, s2)))
        assert(not evo.has(e, evo.pair(p2, evo.ANY)))

        assert(evo.has(e, evo.pair(p1, s1)))
        assert(evo.get(e, evo.pair(p1, s1)) == 11)
        assert(evo.has(e, evo.pair(p1, s2)))
        assert(evo.get(e, evo.pair(p1, s2)) == 12)
        assert(evo.has(e, evo.pair(p1, evo.ANY)))
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :spawn()

        evo.remove(e, evo.pair(evo.ANY, s1))

        assert(not evo.has(e, evo.pair(p1, s1)))
        assert(not evo.has(e, evo.pair(p2, s1)))
        assert(not evo.has(e, evo.pair(evo.ANY, s1)))

        assert(evo.has(e, evo.pair(p1, s2)))
        assert(evo.get(e, evo.pair(p1, s2)) == 12)
        assert(evo.has(e, evo.pair(p2, s2)))
        assert(evo.get(e, evo.pair(p2, s2)) == 22)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :spawn()

        evo.remove(e, evo.pair(evo.ANY, s2))

        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(not evo.has(e, evo.pair(p2, s2)))
        assert(not evo.has(e, evo.pair(evo.ANY, s2)))

        assert(evo.has(e, evo.pair(p1, s1)))
        assert(evo.get(e, evo.pair(p1, s1)) == 11)
        assert(evo.has(e, evo.pair(p2, s1)))
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :set(p1, s1)
            :set(p2, s2)
            :spawn()

        evo.remove(e, evo.pair(evo.ANY, evo.ANY))

        assert(not evo.has(e, evo.pair(p1, s1)))
        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(not evo.has(e, evo.pair(p2, s1)))
        assert(not evo.has(e, evo.pair(p2, s2)))

        assert(evo.has(e, p1) and evo.get(e, p1) == s1)
        assert(evo.has(e, p2) and evo.get(e, p2) == s2)
    end
end

do
    local p1, s1, p2, s2 = evo.id(4)

    local e = evo.builder()
        :set(evo.pair(p1, s1), 42)
        :spawn()

    evo.remove(e, evo.pair(p2, evo.ANY))
    evo.remove(e, evo.pair(evo.ANY, s2))

    assert(evo.has(e, evo.pair(p1, s1)))
    assert(evo.get(e, evo.pair(p1, s1)) == 42)

    evo.remove(e, evo.pair(p1, s1))

    assert(not evo.has(e, evo.pair(p1, s1)))
    assert(evo.get(e, evo.pair(p1, s1)) == nil)
end

do
    local f1, f2, f3, p1, s1, p2, s2 = evo.id(7)
    evo.set(f1, evo.REQUIRES, { f2 })
    evo.set(f2, evo.DEFAULT, 84)
    evo.set(f2, evo.REQUIRES, { evo.pair(p2, s2) })
    evo.set(p1, evo.REQUIRES, { f3 })
    evo.set(s1, evo.REQUIRES, { f3 })
    evo.set(p2, evo.REQUIRES, { f3 })
    evo.set(s2, evo.REQUIRES, { f3 })

    local e = evo.builder()
        :set(f1, 21)
        :set(evo.pair(p1, s1), 42)
        :spawn()

    assert(evo.has(e, evo.pair(p1, s1)))
    assert(evo.get(e, evo.pair(p1, s1)) == 42)

    assert(evo.has(e, evo.pair(p2, s2)))
    assert(evo.get(e, evo.pair(p2, s2)) == true)

    assert(evo.has(e, f1))
    assert(evo.get(e, f1) == 21)

    assert(evo.has(e, f2))
    assert(evo.get(e, f2) == 84)

    assert(not evo.has(e, f3))
    assert(evo.get(e, f3) == nil)
end

do
    local p1, p2, s1, s2 = evo.id(4)

    do
        local e1 = evo.builder()
            :set(evo.pair(p1, s1))
            :set(evo.pair(p1, s2))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(p1, evo.ANY))
        evo.remove(e2, evo.pair(p1, evo.ANY))
        assert(evo.empty_all(e1, e2))
    end

    do
        local e1 = evo.builder()
            :set(evo.pair(p1, s1))
            :set(evo.pair(p2, s1))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(evo.ANY, s1))
        evo.remove(e2, evo.pair(evo.ANY, s1))
        assert(evo.empty_all(e1, e2))
    end

    do
        local e1 = evo.builder()
            :set(evo.pair(p1, s1))
            :set(evo.pair(p1, s2))
            :set(evo.pair(p2, s1))
            :set(evo.pair(p2, s2))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(evo.ANY, evo.ANY))
        evo.remove(e2, evo.pair(evo.ANY, evo.ANY))
        assert(evo.empty_all(e1, e2))
    end
end

do
    local f, p1, p2, s1, s2 = evo.id(5)

    do
        local e1 = evo.builder()
            :set(f, 42)
            :set(evo.pair(p1, s1))
            :set(evo.pair(p1, s2))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(p1, evo.ANY))
        evo.remove(e2, evo.pair(p1, evo.ANY))

        assert(evo.has(e1, f) and evo.has(e2, f))
        assert(not evo.has(e1, evo.pair(evo.ANY, evo.ANY)))
    end

    do
        local e1 = evo.builder()
            :set(f, 42)
            :set(evo.pair(p1, s1))
            :set(evo.pair(p2, s1))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(evo.ANY, s1))
        evo.remove(e2, evo.pair(evo.ANY, s1))

        assert(evo.has(e1, f) and evo.has(e2, f))
        assert(not evo.has(e1, evo.pair(evo.ANY, evo.ANY)))
    end

    do
        local e1 = evo.builder()
            :set(f, 42)
            :set(evo.pair(p1, s1))
            :set(evo.pair(p1, s2))
            :set(evo.pair(p2, s1))
            :set(evo.pair(p2, s2))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(evo.ANY, evo.ANY))
        evo.remove(e2, evo.pair(evo.ANY, evo.ANY))

        assert(evo.has(e1, f) and evo.has(e2, f))
        assert(not evo.has(e1, evo.pair(evo.ANY, evo.ANY)))
    end
end

do
    do
        local p, s = evo.id(2)
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        local ps_chunk = evo.chunk(evo.pair(p, s))
        assert(tostring(ps_chunk) == '<${p,s}>')
    end
    do
        local p, s = evo.id(2)
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(p)
        local ps_chunk = evo.chunk(evo.pair(p, s))
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
    do
        local p, s = evo.id(2)
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(s)
        local ps_chunk = evo.chunk(evo.pair(p, s))
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
    do
        local p, s = evo.id(2)
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(p, s)
        local ps_chunk = evo.chunk(evo.pair(p, s))
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
end

-- TODO:
-- How should required fragments work with pairs?
-- How can we set defaults for paired fragments?
-- Prevent setting wildcard pairs to entities!
-- Should paired fragments be greater than common fragments?
