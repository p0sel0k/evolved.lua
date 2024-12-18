local evo = require 'evolved'

do
    local e1, e2 = evo.id(), evo.id()
    assert(e1 ~= e2)
end

do
    do
        local i0 = evo.id(0)
        assert(type(i0) == 'nil')
    end
    do
        local i1, i2 = evo.id()
        assert(type(i1) == 'number')
        assert(type(i2) == 'nil')
    end
    do
        local i1, i2 = evo.id(1)
        assert(type(i1) == 'number')
        assert(type(i2) == 'nil')
    end
    do
        local i1, i2, i3 = evo.id(2)
        assert(type(i1) == 'number')
        assert(type(i2) == 'number')
        assert(type(i3) == 'nil')
    end
    do
        local i1, i2, i3, i4 = evo.id(3)
        assert(type(i1) == 'number')
        assert(type(i2) == 'number')
        assert(type(i3) == 'number')
        assert(type(i4) == 'nil')
    end
    do
        local i1, i2, i3, i4, i5 = evo.id(4)
        assert(type(i1) == 'number')
        assert(type(i2) == 'number')
        assert(type(i3) == 'number')
        assert(type(i4) == 'number')
        assert(type(i5) == 'nil')
    end
end

do
    local f1, f2 = evo.id(2)
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
    local f1, f2 = evo.id(2)
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
    local f1, f2 = evo.id(2)

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
    local f1, f2 = evo.id(2)
    local e1, e2 = evo.id(2)

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
    local f1, f2 = evo.id(2)

    do
        local e1, e2 = evo.id(2)

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
    local f1, f2 = evo.id(2)
    local e1, e2 = evo.id(2)

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
    local f1, f2 = evo.id(2)

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

do
    local f1, f2 = evo.id(2)

    local e = evo.id()

    evo.set(e, f1, 41)
    assert(evo.get(e, f1) == 41)
    assert(evo.get(e, f2) == nil)

    evo.set(e, f1, 43)
    assert(evo.get(e, f1) == 43)
    assert(evo.get(e, f2) == nil)

    evo.set(e, f2, 42)
    assert(evo.get(e, f1) == 43)
    assert(evo.get(e, f2) == 42)

    evo.set(e, f2, 44)
    assert(evo.get(e, f1) == 43)
    assert(evo.get(e, f2) == 44)
end

do
    local f1, f2 = evo.id(2)
    local e1, e2 = evo.id(2)

    evo.set(e1, f1, 41)
    evo.set(e2, f1, 42)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f1) == 42 and evo.get(e2, f2) == nil)
    end

    evo.set(e1, f2, 43)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
        assert(evo.get(e2, f1) == 42 and evo.get(e2, f2) == nil)
    end

    evo.set(e2, f2, 44)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
        assert(evo.get(e2, f1) == 42 and evo.get(e2, f2) == 44)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.DEFAULT, 42)
    evo.set(f2, evo.DEFAULT, false)

    local e = evo.id()

    evo.set(e, f1)
    evo.set(e, f2)
    evo.set(e, f3)
    evo.set(e, f4, false)

    assert(evo.get(e, f1) == 42)
    assert(evo.get(e, f2) == false)
    assert(evo.get(e, f3) == true)
    assert(evo.get(e, f4) == false)
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)
    evo.set(f1, evo.CONSTRUCT, function(_, a, b) return a - b end)
    evo.set(f2, evo.CONSTRUCT, function(_, c) return c end)
    evo.set(f3, evo.CONSTRUCT, function() return nil end)
    evo.set(f4, evo.CONSTRUCT, function() return false end)
    evo.set(f5, evo.CONSTRUCT, function(e) return e end)

    local e = evo.id()

    evo.insert(e, f1, 43, 1)
    evo.insert(e, f2, false)
    evo.insert(e, f3, 43)
    evo.insert(e, f4, 43)
    evo.insert(e, f5)

    assert(evo.get(e, f1) == 42)
    assert(evo.get(e, f2) == false)
    assert(evo.get(e, f3) == true)
    assert(evo.get(e, f4) == false)
    assert(evo.get(e, f5) == e)

    evo.assign(e, f1, 42, 2)
    evo.assign(e, f2, true)
    evo.assign(e, f3, 43)
    evo.assign(e, f4, 43)
    evo.assign(e, f5, 43)

    assert(evo.get(e, f1) == 40)
    assert(evo.get(e, f2) == true)
    assert(evo.get(e, f3) == true)
    assert(evo.get(e, f4) == false)
    assert(evo.get(e, f5) == e)
end

do
    local f1, f2 = evo.id(2)
    evo.set(f1, evo.DEFAULT, 42)
    evo.set(f1, evo.CONSTRUCT, function() return nil end)
    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f2, evo.CONSTRUCT, function() return false end)

    local e = evo.id()

    evo.set(e, f1, 43)
    evo.set(e, f2, 43)

    assert(evo.get(e, f1) == 42)
    assert(evo.get(e, f2) == false)

    evo.set(e, f1, 43)
    evo.set(e, f2, 43)

    assert(evo.get(e, f1) == 42)
    assert(evo.get(e, f2) == false)
end

do
    local f = evo.id()
    local e = evo.id()

    local set_count = 0
    local assign_count = 0
    local insert_count = 0

    local last_set_component = nil
    local last_assign_component = nil
    local last_insert_component = nil

    evo.set(f, evo.ON_SET, function(entity, fragment, component)
        assert(entity == e)
        assert(fragment == f)
        set_count = set_count + 1
        last_set_component = component
    end)

    evo.set(f, evo.ON_ASSIGN, function(entity, fragment, component)
        assert(entity == e)
        assert(fragment == f)
        assign_count = assign_count + 1
        last_assign_component = component
    end)

    evo.set(f, evo.ON_INSERT, function(entity, fragment, component)
        assert(entity == e)
        assert(fragment == f)
        insert_count = insert_count + 1
        last_insert_component = component
    end)

    assert(evo.insert(e, f, 21))
    assert(set_count == 1)
    assert(assign_count == 0)
    assert(insert_count == 1)
    assert(last_insert_component == 21)

    assert(evo.assign(e, f, 42))
    assert(set_count == 2)
    assert(assign_count == 1)
    assert(insert_count == 1)
    assert(last_assign_component == 42)

    assert(evo.assign(e, f, 43))
    assert(set_count == 3)
    assert(assign_count == 2)
    assert(insert_count == 1)
    assert(last_assign_component == 43)

    evo.clear(e)
    assert(set_count == 3)
    assert(assign_count == 2)
    assert(insert_count == 1)

    evo.set(e, f, 44)
    assert(set_count == 4)
    assert(assign_count == 2)
    assert(insert_count == 2)
    assert(last_set_component == 44)
    assert(last_insert_component == 44)

    evo.set(e, f, 45)
    assert(set_count == 5)
    assert(assign_count == 3)
    assert(insert_count == 2)
    assert(last_set_component == 45)
    assert(last_assign_component == 45)
end
