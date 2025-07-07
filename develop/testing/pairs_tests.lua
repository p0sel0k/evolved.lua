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
        local ps_chunk = evo.chunk(evo.pair(p, s))
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(p)
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
    do
        local p, s = evo.id(2)
        local ps_chunk = evo.chunk(evo.pair(p, s))
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(s)
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
    do
        local p, s = evo.id(2)
        local ps_chunk = evo.chunk(evo.pair(p, s))
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(p, s)
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
end

do
    do
        local p, s = evo.id(2)
        local ps = evo.pair(evo.ANY, s)
        local e = evo.id()
        evo.set(e, p, 42)
        evo.destroy(s)
        evo.remove(e, ps)
    end

    do
        local p, s = evo.id(2)
        local ps = evo.pair(p, evo.ANY)
        local e = evo.id()
        evo.set(e, s, 42)
        evo.destroy(p)
        evo.remove(e, ps)
    end
end

do
    local p, s = evo.id(2)

    local e = evo.id()
    assert(not evo.has(e, evo.pair(p, s)))
    assert(not evo.has(e, evo.pair(p, evo.ANY)))
    assert(not evo.has(e, evo.pair(evo.ANY, s)))
    assert(not evo.has(e, evo.pair(evo.ANY, evo.ANY)))

    evo.set(e, p)
    assert(not evo.has(e, evo.pair(p, s)))
    assert(not evo.has(e, evo.pair(p, evo.ANY)))
    assert(not evo.has(e, evo.pair(evo.ANY, s)))
    assert(not evo.has(e, evo.pair(evo.ANY, evo.ANY)))

    evo.set(e, s)
    assert(not evo.has(e, evo.pair(p, s)))
    assert(not evo.has(e, evo.pair(p, evo.ANY)))
    assert(not evo.has(e, evo.pair(evo.ANY, s)))
    assert(not evo.has(e, evo.pair(evo.ANY, evo.ANY)))

    evo.set(e, evo.pair(p, s))
    assert(evo.has(e, evo.pair(p, s)))
    assert(evo.has(e, evo.pair(p, evo.ANY)))
    assert(evo.has(e, evo.pair(evo.ANY, s)))
    assert(evo.has(e, evo.pair(evo.ANY, evo.ANY)))
end

do
    local p1, s1, p2, s2 = evo.id(4)

    local e = evo.builder():set(evo.pair(p1, s1)):spawn()
    assert(evo.has(e, evo.pair(p1, s1)))
    assert(evo.has(e, evo.pair(p1, evo.ANY)))
    assert(evo.has(e, evo.pair(evo.ANY, s1)))
    assert(evo.has(e, evo.pair(evo.ANY, evo.ANY)))
    assert(not evo.has(e, evo.pair(p1, s2)))
    assert(not evo.has(e, evo.pair(p2, s1)))
    assert(not evo.has(e, evo.pair(p2, s2)))
    assert(not evo.has(e, evo.pair(p2, evo.ANY)))
    assert(not evo.has(e, evo.pair(evo.ANY, s2)))

    evo.set(e, evo.pair(p2, s2))

    assert(evo.has(e, evo.pair(p1, s1)))
    assert(evo.has(e, evo.pair(p1, evo.ANY)))
    assert(evo.has(e, evo.pair(evo.ANY, s1)))
    assert(evo.has(e, evo.pair(evo.ANY, evo.ANY)))
    assert(not evo.has(e, evo.pair(p1, s2)))
    assert(not evo.has(e, evo.pair(p2, s1)))
    assert(evo.has(e, evo.pair(p2, s2)))
    assert(evo.has(e, evo.pair(p2, evo.ANY)))
    assert(evo.has(e, evo.pair(evo.ANY, s2)))
end

--[[ wildcard getting
do
    local p, s1, s2 = evo.id(3)

    do
        local e = evo.builder()
            :set(evo.pair(p, s1), 42)
            :spawn()

        assert(evo.has(e, evo.pair(p, s1)))
        assert(evo.get(e, evo.pair(p, s1)) == 42)

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)

        assert(evo.has(e, evo.pair(p, evo.ANY)))
        assert(evo.get(e, evo.pair(p, evo.ANY)) == 42)

        assert(evo.has(e, evo.pair(evo.ANY, s1)))
        assert(evo.get(e, evo.pair(evo.ANY, s1)) == 42)

        assert(not evo.has(e, evo.pair(evo.ANY, s2)))
        assert(evo.get(e, evo.pair(evo.ANY, s2)) == nil)

        assert(evo.has(e, evo.pair(evo.ANY, evo.ANY)))
        assert(evo.get(e, evo.pair(evo.ANY, evo.ANY)) == 42)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p, s1), 42)
            :set(evo.pair(p, s2), 84)
            :spawn()

        assert(evo.has(e, evo.pair(p, s1)))
        assert(evo.get(e, evo.pair(p, s1)) == 42)

        assert(evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == 84)

        assert(evo.has(e, evo.pair(p, evo.ANY)))
        assert(evo.get(e, evo.pair(p, evo.ANY)) == 42)

        assert(evo.has(e, evo.pair(evo.ANY, s1)))
        assert(evo.get(e, evo.pair(evo.ANY, s1)) == 42)

        assert(evo.has(e, evo.pair(evo.ANY, s2)))
        assert(evo.get(e, evo.pair(evo.ANY, s2)) == 84)

        assert(evo.has(e, evo.pair(evo.ANY, evo.ANY)))
        assert(evo.get(e, evo.pair(evo.ANY, evo.ANY)) == 42)
    end
end]]

do
    local p1, s1, s2 = evo.id(3)

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :spawn()

        evo.set(e, evo.pair(p1, s1), 84)
        assert(evo.get(e, evo.pair(p1, s1)) == 84)
        assert(evo.get(e, evo.pair(p1, s2)) == nil)

        evo.set(e, evo.pair(p1, s2), 42)
        assert(evo.get(e, evo.pair(p1, s1)) == 84)
        assert(evo.get(e, evo.pair(p1, s2)) == 42)

        evo.set(e, evo.pair(p1, evo.ANY), 21)
        assert(evo.get(e, evo.pair(p1, s1)) == 21)
        assert(evo.get(e, evo.pair(p1, s2)) == 21)
    end
end

do
    local p1, s1, p2, s2 = evo.id(4)

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        evo.remove(e, evo.pair(p1, evo.ANY))
        assert(not evo.has(e, evo.pair(p1, s1)))
        assert(evo.get(e, evo.pair(p1, s1)) == nil)
        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(evo.get(e, evo.pair(p1, s2)) == nil)
        assert(evo.has(e, evo.pair(p2, s1)))
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
        assert(evo.has(e, evo.pair(p2, s2)))
        assert(evo.get(e, evo.pair(p2, s2)) == 63)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        evo.remove(e, evo.pair(evo.ANY, s2))
        assert(evo.has(e, evo.pair(p1, s1)))
        assert(evo.get(e, evo.pair(p1, s1)) == 42)
        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(evo.get(e, evo.pair(p1, s2)) == nil)
        assert(evo.has(e, evo.pair(p2, s1)))
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
        assert(not evo.has(e, evo.pair(p2, s2)))
        assert(evo.get(e, evo.pair(p2, s2)) == nil)
    end
end

do
    local p1, p2, s1, s2 = evo.id(4)

    ---@param o evolved.entity
    ---@param s evolved.fragment
    ---@return evolved.fragment[], evolved.component[], number
    local function collect_primaries(o, s)
        local fragments, components, count = {}, {}, 0

        for f, c in evo.primaries(o, s) do
            count = count + 1

            fragments[count] = f
            components[count] = c

            do
                local ff, cc = evo.primary(o, s, count)
                assert(ff == f and cc == c)
            end
        end

        assert(evo.primary_count(o, s) == count)
        return fragments, components, count
    end

    ---@param o evolved.entity
    ---@param p evolved.fragment
    ---@return evolved.fragment[], evolved.component[], number
    local function collect_secondaries(o, p)
        local fragments, components, count = {}, {}, 0

        for f, c in evo.secondaries(o, p) do
            count = count + 1
            fragments[count] = f
            components[count] = c
        end

        return fragments, components, count
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :spawn()

        assert(evo.primary(e, s1) == p1)
        assert(evo.primary(e, s2) == nil)

        assert(evo.secondary(e, p1) == s1)
        assert(evo.secondary(e, p2) == nil)

        assert(evo.primary_count(e, s1) == 1)
        assert(evo.primary_count(e, s2) == 0)
        assert(evo.secondary_count(e, p1) == 1)
        assert(evo.secondary_count(e, p2) == 0)

        do
            local p_list, c_list, count = collect_primaries(e, s1)
            assert(#p_list == 1 and #c_list == 1 and count == 1)
            assert(p_list[1] == p1 and c_list[1] == 42)
        end

        do
            local p_list, c_list, count = collect_primaries(e, s2)
            assert(#p_list == 0 and #c_list == 0 and count == 0)
        end

        do
            local s_list, c_list, count = collect_secondaries(e, p1)
            assert(#s_list == 1 and #c_list == 1 and count == 1)
            assert(s_list[1] == s1 and c_list[1] == 42)
        end

        do
            local s_list, c_list, count = collect_secondaries(e, p2)
            assert(#s_list == 0 and #c_list == 0 and count == 0)
        end
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        do
            assert(evo.primary_count(e, s1) == 2)
            assert(evo.primary_count(e, s2) == 2)
            assert(evo.secondary_count(e, p1) == 2)
            assert(evo.secondary_count(e, p2) == 2)
        end

        do
            local pp, cc = evo.primary(e, s1)
            assert(pp == p1 and cc == 42)

            pp, cc = evo.primary(e, s1, 1)
            assert(pp == p1 and cc == 42)

            pp, cc = evo.primary(e, s1, 2)
            assert(pp == p2 and cc == 21)

            pp, cc = evo.primary(e, s1, 3)
            assert(pp == nil and cc == nil)
        end

        do
            local pp, cc = evo.primary(e, s2)
            assert(pp == p1 and cc == 84)

            pp, cc = evo.primary(e, s2, 1)
            assert(pp == p1 and cc == 84)

            pp, cc = evo.primary(e, s2, 2)
            assert(pp == p2 and cc == 63)

            pp, cc = evo.primary(e, s2, 3)
            assert(pp == nil and cc == nil)
        end

        do
            local pp, cc = evo.secondary(e, p1)
            assert(pp == s1 and cc == 42)

            pp, cc = evo.secondary(e, p1, 1)
            assert(pp == s1 and cc == 42)

            pp, cc = evo.secondary(e, p1, 2)
            assert(pp == s2 and cc == 84)

            pp, cc = evo.secondary(e, p1, 3)
            assert(pp == nil and cc == nil)
        end

        do
            local pp, cc = evo.secondary(e, p2)
            assert(pp == s1 and cc == 21)

            pp, cc = evo.secondary(e, p2, 1)
            assert(pp == s1 and cc == 21)

            pp, cc = evo.secondary(e, p2, 2)
            assert(pp == s2 and cc == 63)

            pp, cc = evo.secondary(e, p2, 3)
            assert(pp == nil and cc == nil)
        end

        do
            local p_list, c_list, count = collect_primaries(e, s1)
            assert(#p_list == 2 and #c_list == 2 and count == 2)
            assert(p_list[1] == p1 and c_list[1] == 42)
            assert(p_list[2] == p2 and c_list[2] == 21)
        end

        do
            local p_list, c_list, count = collect_primaries(e, s2)
            assert(#p_list == 2 and #c_list == 2 and count == 2)
            assert(p_list[1] == p1 and c_list[1] == 84)
            assert(p_list[2] == p2 and c_list[2] == 63)
        end

        do
            local s_list, c_list, count = collect_secondaries(e, p1)
            assert(#s_list == 2 and #c_list == 2 and count == 2)
            assert(s_list[1] == s1 and c_list[1] == 42)
            assert(s_list[2] == s2 and c_list[2] == 84)
        end

        do
            local s_list, c_list, count = collect_secondaries(e, p2)
            assert(#s_list == 2 and #c_list == 2 and count == 2)
            assert(s_list[1] == s1 and c_list[1] == 21)
            assert(s_list[2] == s2 and c_list[2] == 63)
        end
    end
end

do
    local p, s = evo.id(2)

    local e = evo.id()

    assert(not evo.primary(e, s))
    assert(not evo.primary(e, s, 1))
    assert(not evo.primary(e, s, 2))
    assert(not evo.primary(e, s, 0))
    assert(not evo.primary(e, s, -1))
    assert(not evo.primary(e, s, -2))

    assert(not evo.secondary(e, p))
    assert(not evo.secondary(e, p, 1))
    assert(not evo.secondary(e, p, 2))
    assert(not evo.secondary(e, p, 0))
    assert(not evo.secondary(e, p, -1))
    assert(not evo.secondary(e, p, -2))

    assert(evo.primary_count(e, s) == 0)
    assert(evo.secondary_count(e, p) == 0)

    assert(evo.primaries(e, s)() == nil)
    assert(evo.secondaries(e, p)() == nil)
end

do
    local p1, p2, s1, s2 = evo.id(4)

    local e = evo.builder()
        :set(evo.pair(p1, s1), 42)
        :set(evo.pair(p1, s2), 84)
        :set(evo.pair(p2, s1), 21)
        :set(evo.pair(p2, s2), 63)
        :spawn()

    assert(evo.primary(e, evo.ANY) == nil)
    assert(evo.primary(e, evo.ANY, 1) == nil)
    assert(evo.primary(e, evo.ANY, 2) == nil)

    assert(evo.secondary(e, evo.ANY) == nil)
    assert(evo.secondary(e, evo.ANY, 1) == nil)
    assert(evo.secondary(e, evo.ANY, 2) == nil)

    assert(evo.primaries(e, evo.ANY)() == nil)
    assert(evo.secondaries(e, evo.ANY)() == nil)

    assert(evo.primary_count(e, evo.ANY) == 0)
    assert(evo.secondary_count(e, evo.ANY) == 0)
end

do
    local f, p1, p2, s1, s2 = evo.id(5)

    do
        local e = evo.builder()
            :set(f)
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        local ef = evo.builder()
            :set(f)
            :spawn()

        evo.set(e, evo.pair(p1, evo.ANY), 99)

        assert(evo.get(e, evo.pair(p1, s1)) == 99)
        assert(evo.get(e, evo.pair(p1, s2)) == 99)
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
        assert(evo.get(e, evo.pair(p2, s2)) == 63)

        local q = evo.builder():include(f):spawn()
        evo.batch_set(q, evo.pair(p1, evo.ANY), 42)

        assert(evo.get(e, evo.pair(p1, s1)) == 42)
        assert(evo.get(e, evo.pair(p1, s2)) == 42)
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
        assert(evo.get(e, evo.pair(p2, s2)) == 63)

        assert(evo.has(ef, f))
        assert(not evo.has(ef, evo.pair(evo.ANY, evo.ANY)))
    end

    do
        local e = evo.builder()
            :set(f)
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        local ef = evo.builder()
            :set(f)
            :spawn()

        evo.set(e, evo.pair(evo.ANY, s1), 99)

        assert(evo.get(e, evo.pair(p1, s1)) == 99)
        assert(evo.get(e, evo.pair(p1, s2)) == 84)
        assert(evo.get(e, evo.pair(p2, s1)) == 99)
        assert(evo.get(e, evo.pair(p2, s2)) == 63)

        local q = evo.builder():include(f):spawn()
        evo.batch_set(q, evo.pair(evo.ANY, s1), 42)

        assert(evo.get(e, evo.pair(p1, s1)) == 42)
        assert(evo.get(e, evo.pair(p1, s2)) == 84)
        assert(evo.get(e, evo.pair(p2, s1)) == 42)
        assert(evo.get(e, evo.pair(p2, s2)) == 63)

        assert(evo.has(ef, f))
        assert(not evo.has(ef, evo.pair(evo.ANY, evo.ANY)))
    end

    do
        local e = evo.builder()
            :set(f)
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        local ef = evo.builder()
            :set(f)
            :spawn()

        evo.set(e, evo.pair(evo.ANY, evo.ANY), 99)

        assert(evo.get(e, evo.pair(p1, s1)) == 99)
        assert(evo.get(e, evo.pair(p1, s2)) == 99)
        assert(evo.get(e, evo.pair(p2, s1)) == 99)
        assert(evo.get(e, evo.pair(p2, s2)) == 99)

        local q = evo.builder():include(f):spawn()
        evo.batch_set(q, evo.pair(evo.ANY, evo.ANY), 42)

        assert(evo.get(e, evo.pair(p1, s1)) == 42)
        assert(evo.get(e, evo.pair(p1, s2)) == 42)
        assert(evo.get(e, evo.pair(p2, s1)) == 42)
        assert(evo.get(e, evo.pair(p2, s2)) == 42)

        assert(evo.has(ef, f))
        assert(not evo.has(ef, evo.pair(evo.ANY, evo.ANY)))
    end
end

-- TODO:
-- How should required fragments work with pairs?
-- How can we set defaults for paired fragments?
-- Prevent setting wildcard pairs to entities!
