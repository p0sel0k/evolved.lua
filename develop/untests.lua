local evo = require 'evolved'

do
    local e1, e2 = evo.id(), evo.id()
    assert(e1 ~= e2)
end

do
    local f1, f2 = evo.id(), evo.id()
    local e = evo.id()

    do
        assert(not evo.has(e, f1))
        assert(not evo.has(e, f2))
        assert(not evo.has_all(e, f1, f2))
        assert(not evo.has_any(e, f1, f2))
    end

    do
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == nil and c2 == nil)
    end

    assert(evo.insert(e, f1, 41))

    do
        assert(evo.has(e, f1))
        assert(not evo.has(e, f2))
        assert(not evo.has_all(e, f1, f2))
        assert(evo.has_any(e, f1, f2))
    end

    do
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == nil)

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 41 and c2 == nil)
    end

    assert(evo.insert(e, f2, 42))

    do
        assert(evo.has(e, f1))
        assert(evo.has(e, f2))
        assert(evo.has_all(e, f1, f2))
        assert(evo.has_any(e, f1, f2))
    end

    do
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 42)

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 41 and c2 == 42)
    end
end

do
    local f1, f2 = evo.id(), evo.id()
    local e = evo.id()

    assert(evo.insert(e, f1, 41))
    assert(not evo.insert(e, f1, 42))

    assert(evo.insert(e, f2, 42))
    assert(not evo.insert(e, f1, 42))
    assert(not evo.insert(e, f2, 41))

    do
        assert(evo.has_all(e, f1, f2))
        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 41 and c2 == 42)
    end
end

do
    local f1, f2 = evo.id(), evo.id()

    do
        local e = evo.id()
        assert(evo.insert(e, f1, 41))
        assert(evo.insert(e, f2, 42))

        evo.remove(e, f1)

        assert(not evo.has(e, f1))
        assert(evo.has(e, f2))

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == nil and c2 == 42)
    end

    do
        local e = evo.id()
        assert(evo.insert(e, f1, 41))
        assert(evo.insert(e, f2, 42))

        evo.remove(e, f2)

        assert(evo.has(e, f1))
        assert(not evo.has(e, f2))

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 41 and c2 == nil)
    end

    do
        local e = evo.id()
        assert(evo.insert(e, f1, 41))
        assert(evo.insert(e, f2, 42))

        evo.remove(e, f1, f2)

        assert(not evo.has_any(e, f1, f2))

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == nil and c2 == nil)
    end
end

do
    local f1, f2 = evo.id(), evo.id()
    local e1, e2 = evo.id(), evo.id()

    assert(evo.insert(e1, f1, 41))
    assert(evo.insert(e2, f2, 42))

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == nil)
    end

    assert(evo.insert(e1, f2, 43))

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
        assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == nil)
    end

    assert(evo.insert(e2, f1, 44))

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
        assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == 44)
    end
end

do
    local f1, f2 = evo.id(), evo.id()

    do
        local e1, e2 = evo.id(), evo.id()

        assert(evo.insert(e1, f1, 41))
        assert(evo.insert(e1, f2, 43))
        assert(evo.insert(e2, f1, 44))
        assert(evo.insert(e2, f2, 42))

        do
            assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
            assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == 44)
        end

        evo.remove(e1, f1)

        do
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == 43)
            assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == 44)
        end

        evo.remove(e2, f1)

        do
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == 43)
            assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == nil)
        end
    end
end

do
    local f1, f2 = evo.id(), evo.id()
    local e1, e2 = evo.id(), evo.id()

    assert(evo.insert(e1, f1, 41))
    assert(evo.insert(e1, f2, 43))
    assert(evo.insert(e2, f1, 44))
    assert(evo.insert(e2, f2, 42))

    evo.clear(e1)

    do
        assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == 44)
    end

    evo.clear(e2)

    do
        assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == nil and evo.get(e2, f1) == nil)
    end
end

do
    local f1, f2 = evo.id(), evo.id()

    local e = evo.id()

    assert(not evo.assign(e, f1, 41))
    assert(evo.get(e, f1) == nil)

    assert(evo.insert(e, f1, 41))
    assert(evo.assign(e, f1, 42))
    assert(evo.get(e, f1) == 42)

    assert(not evo.assign(e, f2, 43))
    assert(evo.get(e, f2) == nil)

    assert(evo.insert(e, f2, 43))
    assert(evo.assign(e, f2, 44))
    assert(evo.get(e, f2) == 44)
end
