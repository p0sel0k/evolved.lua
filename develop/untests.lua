require 'develop.unload' 'evolved'

local evo = require 'evolved'

evo.debug_mode(true)

do
    local i = evo.id()

    for _ = 1, 0xFFFFE do
        local _, v0 = evo.unpack(i)
        evo.destroy(i)
        i = evo.id()
        local _, v1 = evo.unpack(i)
        assert(v1 == v0 + 1)
    end

    do
        local _, v = evo.unpack(i)
        assert(v == 0xFFFFF)
    end

    evo.destroy(i)
    i = evo.id()

    do
        local _, v = evo.unpack(i)
        assert(v == 1)
    end
end

do
    local e1, e2 = evo.id(), evo.id()
    assert(e1 ~= e2)

    assert(evo.is_alive(e1))
    assert(evo.is_alive(e2))

    assert(evo.destroy(e1))

    assert(not evo.is_alive(e1))
    assert(evo.is_alive(e2))

    assert(evo.destroy(e1))
    assert(evo.destroy(e2))

    assert(not evo.is_alive(e1))
    assert(not evo.is_alive(e2))

    assert(evo.destroy(e1))
    assert(evo.destroy(e2))

    assert(not evo.is_alive(e1))
    assert(not evo.is_alive(e2))
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
    do
        local i1, i2, i3, i4, i5, i6 = evo.id(5)
        assert(type(i1) == 'number')
        assert(type(i2) == 'number')
        assert(type(i3) == 'number')
        assert(type(i4) == 'number')
        assert(type(i5) == 'number')
        assert(type(i6) == 'nil')
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
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.CONSTRUCT, function(a, b) return a - b end)
    evo.set(f2, evo.CONSTRUCT, function(c) return c end)
    evo.set(f3, evo.CONSTRUCT, function() return nil end)
    evo.set(f4, evo.CONSTRUCT, function() return false end)

    local e = evo.id()

    evo.insert(e, f1, 43, 1)
    evo.insert(e, f2, false)
    evo.insert(e, f3, 43)
    evo.insert(e, f4, 43)

    assert(evo.get(e, f1) == 42)
    assert(evo.get(e, f2) == false)
    assert(evo.get(e, f3) == true)
    assert(evo.get(e, f4) == false)

    evo.assign(e, f1, 42, 2)
    evo.assign(e, f2, true)
    evo.assign(e, f3, 43)
    evo.assign(e, f4, 43)

    assert(evo.get(e, f1) == 40)
    assert(evo.get(e, f2) == true)
    assert(evo.get(e, f3) == true)
    assert(evo.get(e, f4) == false)
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
    local remove_count = 0

    local last_set_new_component = nil
    local last_set_old_component = nil
    local last_assign_new_component = nil
    local last_assign_old_component = nil
    local last_insert_new_component = nil
    local last_remove_old_component = nil

    evo.set(f, evo.ON_SET, function(entity, fragment, new_component, old_component)
        assert(entity == e)
        assert(fragment == f)
        set_count = set_count + 1
        last_set_new_component = new_component
        last_set_old_component = old_component
    end)

    evo.set(f, evo.ON_ASSIGN, function(entity, fragment, new_component, old_component)
        assert(entity == e)
        assert(fragment == f)
        assign_count = assign_count + 1
        last_assign_new_component = new_component
        last_assign_old_component = old_component
    end)

    evo.set(f, evo.ON_INSERT, function(entity, fragment, new_component)
        assert(entity == e)
        assert(fragment == f)
        insert_count = insert_count + 1
        last_insert_new_component = new_component
    end)

    evo.set(f, evo.ON_REMOVE, function(entity, fragment, old_component)
        assert(entity == e)
        assert(fragment == f)
        remove_count = remove_count + 1
        last_remove_old_component = old_component
    end)

    assert(evo.insert(e, f, 21))
    assert(set_count == 1)
    assert(assign_count == 0)
    assert(insert_count == 1)
    assert(remove_count == 0)
    assert(last_set_old_component == nil)
    assert(last_set_new_component == 21)
    assert(last_insert_new_component == 21)

    assert(evo.assign(e, f, 42))
    assert(set_count == 2)
    assert(assign_count == 1)
    assert(insert_count == 1)
    assert(remove_count == 0)
    assert(last_set_new_component == 42)
    assert(last_set_old_component == 21)
    assert(last_assign_new_component == 42)
    assert(last_assign_old_component == 21)

    assert(evo.assign(e, f, 43))
    assert(set_count == 3)
    assert(assign_count == 2)
    assert(insert_count == 1)
    assert(remove_count == 0)
    assert(last_set_new_component == 43)
    assert(last_set_old_component == 42)
    assert(last_assign_new_component == 43)
    assert(last_assign_old_component == 42)

    evo.clear(e)
    assert(set_count == 3)
    assert(assign_count == 2)
    assert(insert_count == 1)
    assert(remove_count == 1)
    assert(last_remove_old_component == 43)

    evo.set(e, f, 44)
    assert(set_count == 4)
    assert(assign_count == 2)
    assert(insert_count == 2)
    assert(remove_count == 1)
    assert(last_set_new_component == 44)
    assert(last_set_old_component == nil)
    assert(last_insert_new_component == 44)

    evo.set(e, f, 45)
    assert(set_count == 5)
    assert(assign_count == 3)
    assert(insert_count == 2)
    assert(remove_count == 1)
    assert(last_set_new_component == 45)
    assert(last_set_old_component == 44)
    assert(last_assign_new_component == 45)
    assert(last_assign_old_component == 44)

    evo.destroy(e)
    assert(set_count == 5)
    assert(assign_count == 3)
    assert(insert_count == 2)
    assert(remove_count == 2)
    assert(last_remove_old_component == 45)
end

do
    local f1, f2 = evo.id(2)
    local e = evo.id()

    local remove_count = 0
    local last_removed_component = nil

    evo.set(f1, evo.ON_REMOVE, function(entity, fragment, component)
        assert(entity == e)
        assert(fragment == f1)
        remove_count = remove_count + 1
        last_removed_component = component
    end)

    evo.set(f2, evo.ON_REMOVE, function(entity, fragment, component)
        assert(entity == e)
        assert(fragment == f2)
        remove_count = remove_count + 1
        last_removed_component = component
    end)

    assert(evo.insert(e, f1, 42))
    evo.remove(e, f1, f2)
    assert(remove_count == 1)
    assert(last_removed_component == 42)

    assert(evo.insert(e, f1, 42))
    assert(evo.insert(e, f2, 43))
    evo.remove(e, f1, f2, f2)
    assert(remove_count == 3)
    assert(last_removed_component == 43)

    assert(evo.insert(e, f1, 44))
    assert(evo.insert(e, f2, 45))
    evo.clear(e)
    assert(remove_count == 5)

    assert(evo.insert(e, f1, 46))
    assert(evo.insert(e, f2, 47))
    evo.destroy(e)
    assert(remove_count == 7)
end

do
    local f = evo.id()
    local e = evo.id()

    assert(evo.insert(e, f, 42))
    assert(evo.has(e, f))
    assert(evo.is_alive(e))

    evo.destroy(e)
    assert(not evo.has(e, f))
    assert(not evo.is_alive(e))
end

do
    local f = evo.id()

    do
        local e = evo.id()
        assert(evo.is_empty(e))

        evo.insert(e, f, 42)
        assert(not evo.is_empty(e))

        evo.clear(e)
        assert(evo.is_empty(e))
    end

    do
        local e = evo.id()
        assert(evo.is_empty(e))

        evo.insert(e, f, 42)
        assert(not evo.is_empty(e))

        evo.destroy(e)
        assert(evo.is_empty(e))
    end
end

do
    local f1, f2, f3 = evo.id(3)

    local _ = evo.id()

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    local e2 = evo.id()
    assert(evo.insert(e2, f1, 42))
    assert(evo.insert(e2, f2, 43))

    local e2b = evo.id()
    assert(evo.insert(e2b, f1, 44))
    assert(evo.insert(e2b, f2, 45))

    do
        local chunk, entities = evo.chunk()
        assert(not chunk and not entities)
    end

    do
        local chunk, entities = evo.chunk(f1)
        assert(entities and entities[1] == e1)
        assert(chunk and evo.select(chunk, f1)[1] == 41)
    end

    do
        local chunk, entities = evo.chunk(f1, f2)
        assert(chunk == evo.chunk(f1, f2))
        assert(chunk == evo.chunk(f1, f1, f2))
        assert(chunk == evo.chunk(f1, f1, f2, f2))
        assert(chunk == evo.chunk(f1, f2, f2, f1))
        assert(chunk == evo.chunk(f2, f1))
        assert(chunk == evo.chunk(f2, f1, f2, f1))
        assert(entities and entities[1] == e2 and entities[2] == e2b)
        assert(chunk and evo.select(chunk, f1)[1] == 42 and evo.select(chunk, f2)[1] == 43)
        assert(chunk and evo.select(chunk, f1)[2] == 44 and evo.select(chunk, f2)[2] == 45)
    end

    do
        local chunk123, entities123 = evo.chunk(f1, f2, f3)
        local chunk321, entities321 = evo.chunk(f3, f2, f1)
        assert(chunk123 and #entities123 == 0)
        assert(chunk321 and #entities321 == 0)
        assert(chunk123 == chunk321 and entities123 == entities321)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f1, evo.DEFAULT, 42)

    local e1, e2, e3, e4 = evo.id(4)

    assert(evo.insert(e1, f3, 44))

    assert(evo.insert(e2, f1, 45))
    assert(evo.insert(e2, f2, 46))
    assert(evo.insert(e2, f3, 47))

    assert(evo.insert(e3, f1, 45))
    assert(evo.insert(e3, f2, 46))
    assert(evo.insert(e3, f3, 47))

    assert(evo.defer())
    assert(not evo.defer())

    evo.set(e1, f1)
    evo.set(e1, f2, 43)
    evo.remove(e2, f1, f2)
    evo.assign(e2, f3, 48)
    evo.clear(e3)
    evo.insert(e3, f1, 48)
    evo.insert(e3, f1, 49)
    evo.destroy(e4)

    assert(evo.get(e1, f1) == nil)
    assert(evo.get(e1, f2) == nil)
    assert(evo.get(e1, f3) == 44)

    assert(evo.get(e2, f1) == 45)
    assert(evo.get(e2, f2) == 46)
    assert(evo.get(e2, f3) == 47)

    assert(evo.get(e3, f1) == 45)
    assert(evo.get(e3, f2) == 46)
    assert(evo.get(e3, f3) == 47)

    assert(not evo.commit())
    assert(evo.commit())

    assert(evo.get(e1, f1) == 42)
    assert(evo.get(e1, f2) == 43)
    assert(evo.get(e1, f3) == 44)

    assert(evo.get(e2, f1) == nil)
    assert(evo.get(e2, f2) == nil)
    assert(evo.get(e2, f3) == 48)

    assert(evo.get(e3, f1) == 48)
    assert(evo.get(e3, f2) == nil)
    assert(evo.get(e3, f3) == nil)

    assert(not evo.is_alive(e4))
end

do
    local f1, f2 = evo.id(2)

    ---@param entity evolved.entity
    ---@param fragment evolved.fragment
    ---@param component evolved.component
    evo.set(f1, evo.ON_SET, function(entity, fragment, component)
        assert(fragment == f1)
        evo.insert(entity, f2, component * 2)
    end)

    ---@param entity evolved.entity
    ---@param fragment evolved.fragment
    ---@param component evolved.component
    evo.set(f1, evo.ON_REMOVE, function(entity, fragment, component)
        assert(fragment == f1)
        assert(component == 21)
        evo.remove(entity, f2)
    end)

    do
        local e = evo.id()

        assert(evo.set(e, f1, 21))
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.remove(e, f1)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
    do
        local e = evo.id()

        assert(evo.set(e, f1, 21))
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.clear(e)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
    do
        local e = evo.id()

        assert(evo.set(e, f1, 21))
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.destroy(e)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    ---@param entity evolved.entity
    ---@param fragment evolved.fragment
    ---@param component evolved.component
    evo.set(f1, evo.ON_INSERT, function(entity, fragment, component)
        assert(fragment == f1)
        evo.insert(entity, f2, component * 2)
    end)

    ---@param entity evolved.entity
    ---@param fragment evolved.fragment
    ---@param component evolved.component
    evo.set(f1, evo.ON_REMOVE, function(entity, fragment, component)
        assert(fragment == f1)
        assert(component == 21)
        evo.remove(entity, f2)
    end)

    do
        local e = evo.id()

        assert(evo.insert(e, f1, 21))
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.remove(e, f1)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
    do
        local e = evo.id()

        assert(evo.insert(e, f1, 21))
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.clear(e)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
    do
        local e = evo.id()

        assert(evo.insert(e, f1, 21))
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.destroy(e)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f1, 47))
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local e5 = evo.id()
        assert(evo.insert(e5, f2, 51))
        assert(evo.insert(e5, f3, 52))
        assert(evo.insert(e5, f4, 53))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f1, f2)

        assert(evo.batch_assign(q, f1, 60) == 3)

        assert(evo.get(e1, f1) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 60 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 60 and evo.get(e3, f3) == 46)
        assert(evo.get(e4, f1) == 60 and evo.get(e4, f3) == 49)
        assert(evo.get(e5, f1) == nil and evo.get(e5, f3) == 52)

        assert(evo.batch_assign(q, f3, 70) == 2)

        assert(evo.get(e1, f1) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 60 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 60 and evo.get(e3, f3) == 70)
        assert(evo.get(e4, f1) == 60 and evo.get(e4, f3) == 70)
        assert(evo.get(e5, f1) == nil and evo.get(e5, f3) == 52)
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_ASSIGN, function(entity, fragment, new_component, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + new_component + old_component
        end)

        evo.set(f3, evo.ON_ASSIGN, function(entity, fragment, new_component, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f3)
            component_sum = component_sum + new_component + old_component
        end)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f1, 47))
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local e5 = evo.id()
        assert(evo.insert(e5, f2, 51))
        assert(evo.insert(e5, f3, 52))
        assert(evo.insert(e5, f4, 53))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f1, f2)

        assert(evo.batch_assign(q, f1, 60) == 3)

        assert(entity_sum == e2 + e3 + e4)
        assert(component_sum == 42 + 44 + 47 + 60 + 60 + 60)
        entity_sum = 0
        component_sum = 0

        assert(evo.get(e1, f1) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 60 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 60 and evo.get(e3, f3) == 46)
        assert(evo.get(e4, f1) == 60 and evo.get(e4, f3) == 49)
        assert(evo.get(e5, f1) == nil and evo.get(e5, f3) == 52)

        assert(evo.batch_assign(q, f3, 70) == 2)

        assert(entity_sum == e3 + e4)
        assert(component_sum == 46 + 49 + 70 + 70)
        entity_sum = 0
        component_sum = 0

        assert(evo.get(e1, f1) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 60 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 60 and evo.get(e3, f3) == 70)
        assert(evo.get(e4, f1) == 60 and evo.get(e4, f3) == 70)
        assert(evo.get(e5, f1) == nil and evo.get(e5, f3) == 52)
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f1, 47))
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local e5 = evo.id()
        assert(evo.insert(e5, f2, 51))
        assert(evo.insert(e5, f3, 52))
        assert(evo.insert(e5, f4, 53))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f1, f2)

        assert(evo.batch_clear(q) == 3)

        assert(evo.is_alive(e1))
        assert(evo.is_alive(e2))
        assert(evo.is_alive(e3))
        assert(evo.is_alive(e4))
        assert(evo.is_alive(e5))

        assert(not evo.is_empty(e1))
        assert(evo.is_empty(e2))
        assert(evo.is_empty(e3))
        assert(evo.is_empty(e4))
        assert(not evo.is_empty(e5))
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + old_component
        end)

        evo.set(f2, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f2)
            component_sum = component_sum + old_component
        end)

        evo.set(f3, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f3)
            component_sum = component_sum + old_component
        end)

        evo.set(f4, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f4)
            component_sum = component_sum + old_component
        end)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f1, 47))
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local e5 = evo.id()
        assert(evo.insert(e5, f2, 51))
        assert(evo.insert(e5, f3, 52))
        assert(evo.insert(e5, f4, 53))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f1, f2)

        assert(evo.batch_clear(q) == 3)
        assert(entity_sum == e2 * 2 + e3 * 3 + e4 * 4)
        assert(component_sum == 42 + 43 + 44 + 45 + 46 + 47 + 48 + 49 + 50)

        assert(evo.is_alive(e1))
        assert(evo.is_alive(e2))
        assert(evo.is_alive(e3))
        assert(evo.is_alive(e4))
        assert(evo.is_alive(e5))

        assert(not evo.is_empty(e1))
        assert(evo.is_empty(e2))
        assert(evo.is_empty(e3))
        assert(evo.is_empty(e4))
        assert(not evo.is_empty(e5))
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f1, 47))
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local e5 = evo.id()
        assert(evo.insert(e5, f2, 51))
        assert(evo.insert(e5, f3, 52))
        assert(evo.insert(e5, f4, 53))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f1, f2)

        assert(evo.batch_destroy(q) == 3)

        assert(evo.is_alive(e1))
        assert(not evo.is_alive(e2))
        assert(not evo.is_alive(e3))
        assert(not evo.is_alive(e4))
        assert(evo.is_alive(e5))

        assert(not evo.is_empty(e1))
        assert(evo.is_empty(e2))
        assert(evo.is_empty(e3))
        assert(evo.is_empty(e4))
        assert(not evo.is_empty(e5))
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + old_component
        end)

        evo.set(f2, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f2)
            component_sum = component_sum + old_component
        end)

        evo.set(f3, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f3)
            component_sum = component_sum + old_component
        end)

        evo.set(f4, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f4)
            component_sum = component_sum + old_component
        end)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f1, 47))
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local e5 = evo.id()
        assert(evo.insert(e5, f2, 51))
        assert(evo.insert(e5, f3, 52))
        assert(evo.insert(e5, f4, 53))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f1, f2)

        assert(evo.batch_destroy(q) == 3)
        assert(entity_sum == e2 * 2 + e3 * 3 + e4 * 4)
        assert(component_sum == 42 + 43 + 44 + 45 + 46 + 47 + 48 + 49 + 50)

        assert(evo.is_alive(e1))
        assert(not evo.is_alive(e2))
        assert(not evo.is_alive(e3))
        assert(not evo.is_alive(e4))
        assert(evo.is_alive(e5))

        assert(not evo.is_empty(e1))
        assert(evo.is_empty(e2))
        assert(evo.is_empty(e3))
        assert(evo.is_empty(e4))
        assert(not evo.is_empty(e5))
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f1, 47))
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local e5 = evo.id()
        assert(evo.insert(e5, f2, 51))
        assert(evo.insert(e5, f3, 52))
        assert(evo.insert(e5, f4, 53))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f1, f2)

        assert(evo.batch_remove(q, f2, f3) == 3)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 42)
        assert(evo.get(e2, f2) == nil)
        assert(evo.get(e3, f1) == 44)
        assert(evo.get(e3, f2) == nil)
        assert(evo.get(e3, f3) == nil)
        assert(evo.get(e4, f1) == 47)
        assert(evo.get(e4, f2) == nil)
        assert(evo.get(e4, f3) == nil)
        assert(evo.get(e4, f4) == 50)
        assert(evo.get(e5, f1) == nil)
        assert(evo.get(e5, f2) == 51)
        assert(evo.get(e5, f3) == 52)
        assert(evo.get(e5, f4) == 53)
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + old_component
        end)

        evo.set(f2, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f2)
            component_sum = component_sum + old_component
        end)

        evo.set(f3, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f3)
            component_sum = component_sum + old_component
        end)

        evo.set(f4, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f4)
            component_sum = component_sum + old_component
        end)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f1, 47))
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local e5 = evo.id()
        assert(evo.insert(e5, f2, 51))
        assert(evo.insert(e5, f3, 52))
        assert(evo.insert(e5, f4, 53))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f1, f2)

        assert(evo.batch_remove(q, f2, f3, f3) == 3)
        assert(entity_sum == e2 + e3 * 2 + e4 * 2)
        assert(component_sum == 43 + 45 + 46 + 48 + 49)

        assert(not evo.has_any(e1, f2, f3))
        assert(not evo.has_any(e2, f2, f3))
        assert(not evo.has_any(e3, f2, f3))
        assert(not evo.has_any(e4, f2, f3))
        assert(evo.has_all(e5, f2, f3))
    end
end

do
    do
        local f1, f2 = evo.id(2)
        evo.set(f2, evo.DEFAULT, 42)

        local e1 = evo.entity():set(f1, 11):build()
        local e2 = evo.entity():set(f1, 21):set(f2, 22):build()

        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22)

        local q = evo.query():include(f1):build()
        assert(evo.batch_insert(q, f2) == 1)

        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == 42)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22)
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f2)

        assert(evo.batch_insert(q, f1, 60) == 1)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 42)
        assert(evo.get(e3, f1) == 44)
        assert(evo.get(e4, f1) == 60)
    end
    do
        local f1, f2, f3, f4, f5 = evo.id(5)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_INSERT, function(entity, fragment, new_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + new_component
        end)

        evo.set(f5, evo.ON_INSERT, function(entity, fragment, new_component)
            entity_sum = entity_sum + entity
            assert(fragment == f5)
            component_sum = component_sum + new_component
        end)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f2)

        entity_sum = 0
        component_sum = 0
        assert(evo.batch_insert(q, f1, 60) == 1)
        assert(entity_sum == e4)
        assert(component_sum == 60)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 42)
        assert(evo.get(e3, f1) == 44)
        assert(evo.get(e4, f1) == 60)

        entity_sum = 0
        component_sum = 0
        assert(evo.batch_insert(q, f5, 70) == 3)
        assert(entity_sum == e2 + e3 + e4)
        assert(component_sum == 70 * 3)
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f2)

        assert(evo.batch_set(q, f1, 60) == 3)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 60)
        assert(evo.get(e3, f1) == 60)
        assert(evo.get(e4, f1) == 60)
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_ASSIGN, function(entity, fragment, new_component, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + new_component + old_component
        end)

        evo.set(f1, evo.ON_INSERT, function(entity, fragment, new_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + new_component
        end)

        local e1 = evo.id()
        assert(evo.insert(e1, f1, 41))

        local e2 = evo.id()
        assert(evo.insert(e2, f1, 42))
        assert(evo.insert(e2, f2, 43))

        local e3 = evo.id()
        assert(evo.insert(e3, f1, 44))
        assert(evo.insert(e3, f2, 45))
        assert(evo.insert(e3, f3, 46))

        local e4 = evo.id()
        assert(evo.insert(e4, f2, 48))
        assert(evo.insert(e4, f3, 49))
        assert(evo.insert(e4, f4, 50))

        local q = evo.id()
        evo.insert(q, evo.INCLUDES, f2)

        entity_sum = 0
        component_sum = 0
        assert(evo.batch_set(q, f1, 60) == 3)
        assert(entity_sum == e2 + e3 + e4)
        assert(component_sum == 42 + 60 + 44 + 60 + 60)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 60)
        assert(evo.get(e3, f1) == 60)
        assert(evo.get(e4, f1) == 60)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    local last_set_entity = 0
    local last_assign_entity = 0
    local last_remove_entity = 0

    evo.set(f1, evo.TAG)
    evo.set(f1, evo.CONSTRUCT, function() assert(false) end)
    evo.set(f1, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f1)
        assert(c == nil)
    end)
    evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
        last_assign_entity = e
        assert(f == f1)
        assert(c == nil)
    end)
    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        last_remove_entity = e
        assert(f == f1)
        assert(c == nil)
    end)

    evo.set(f2, evo.TAG)
    evo.set(f2, evo.CONSTRUCT, function() assert(false) end)
    evo.set(f2, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f2)
        assert(c == nil)
    end)
    evo.set(f2, evo.ON_ASSIGN, function(e, f, c)
        last_assign_entity = e
        assert(f == f2)
        assert(c == nil)
    end)
    evo.set(f2, evo.ON_REMOVE, function(e, f, c)
        last_remove_entity = e
        assert(f == f2)
        assert(c == nil)
    end)

    evo.set(f3, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f3)
        assert(c ~= nil)
    end)
    evo.set(f3, evo.ON_ASSIGN, function(e, f, c)
        last_assign_entity = e
        assert(f == f3)
        assert(c ~= nil)
    end)
    evo.set(f3, evo.ON_REMOVE, function(e, f, c)
        last_remove_entity = e
        assert(f == f3)
        assert(c ~= nil)
    end)

    do
        local e = evo.id()

        last_set_entity = 0
        assert(evo.set(e, f1, 41))
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and not evo.has(e, f2))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

        do
            last_set_entity = 0
            assert(evo.set(e, f1, 41))
            assert(last_set_entity == e)
            assert(evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        last_set_entity = 0
        assert(evo.set(e, f2, 42))
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and evo.has(e, f2))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

        do
            last_set_entity = 0
            assert(evo.set(e, f1, 42))
            assert(last_set_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            last_set_entity = 0
            assert(evo.set(e, f2, 42))
            assert(last_set_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        last_set_entity = 0
        assert(evo.set(e, f3, 43))
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

        do
            last_set_entity = 0
            assert(evo.set(e, f1, 42))
            assert(last_set_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

            last_set_entity = 0
            assert(evo.set(e, f2, 42))
            assert(last_set_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

            last_set_entity = 0
            assert(evo.set(e, f3, 44))
            assert(last_set_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 44)
        end
    end

    do
        local e = evo.id()

        last_set_entity = 0
        assert(evo.insert(e, f1))
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and not evo.has(e, f2))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

        do
            last_set_entity = 0
            assert(not evo.insert(e, f1))
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        last_set_entity = 0
        assert(evo.insert(e, f2, 42))
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and evo.has(e, f2))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

        do
            last_set_entity = 0
            assert(not evo.insert(e, f1))
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            last_set_entity = 0
            assert(not evo.insert(e, f2, 42))
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        last_set_entity = 0
        assert(evo.insert(e, f3, 43))
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

        do
            last_set_entity = 0
            assert(not evo.insert(e, f1))
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

            last_set_entity = 0
            assert(not evo.insert(e, f2, 42))
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

            last_set_entity = 0
            assert(not evo.insert(e, f3, 44))
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)
        end
    end

    do
        local e = evo.id()

        do
            last_assign_entity = 0
            assert(not evo.assign(e, f1))
            assert(last_assign_entity == 0)
            assert(not evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            assert(evo.insert(e, f1))
            assert(evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            last_assign_entity = 0
            assert(evo.assign(e, f1))
            assert(last_assign_entity == e)
            assert(evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            last_assign_entity = 0
            assert(not evo.assign(e, f2, 43))
            assert(last_assign_entity == 0)
            assert(evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            assert(evo.insert(e, f2, 43))
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            last_assign_entity = 0
            assert(evo.assign(e, f2, 44))
            assert(last_assign_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            last_assign_entity = 0
            assert(not evo.assign(e, f3, 44))
            assert(last_assign_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2) and not evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == nil)

            assert(evo.insert(e, f3, 44))
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 44)

            last_assign_entity = 0
            assert(evo.assign(e, f3, 45))
            assert(last_assign_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 45)
        end
    end

    do
        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))

            last_remove_entity = 0
            assert(evo.remove(e, f1))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))
            assert(evo.insert(e, f2, 42))

            last_remove_entity = 0
            assert(evo.remove(e, f1, f2))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))
            assert(evo.insert(e, f2, 42))
            assert(evo.insert(e, f3, 43))

            last_remove_entity = 0
            assert(evo.remove(e, f1, f2, f3))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2) and not evo.has(e, f3))
        end

        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))
            assert(evo.insert(e, f2, 42))
            assert(evo.insert(e, f3, 43))

            last_remove_entity = 0
            assert(evo.remove(e, f3))
            assert(last_remove_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2) and not evo.has(e, f3))

            last_remove_entity = 0
            assert(evo.remove(e, f1, f2, f3))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2) and not evo.has(e, f3))
        end
    end

    do
        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))

            last_remove_entity = 0
            assert(evo.clear(e) and evo.is_alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))
            assert(evo.insert(e, f2, 42))

            last_remove_entity = 0
            assert(evo.clear(e) and evo.is_alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))
            assert(evo.insert(e, f2, 42))
            assert(evo.insert(e, f3, 43))

            last_remove_entity = 0
            assert(evo.clear(e) and evo.is_alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2) and not evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == nil)
        end
    end

    do
        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))

            last_remove_entity = 0
            assert(evo.destroy(e) and not evo.is_alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))
            assert(evo.insert(e, f2, 42))

            last_remove_entity = 0
            assert(evo.destroy(e) and not evo.is_alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))
            assert(evo.insert(e, f2, 42))
            assert(evo.insert(e, f3, 43))

            last_remove_entity = 0
            assert(evo.destroy(e) and not evo.is_alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2) and not evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == nil)
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, f1, f2)

        do
            local e = evo.id()
            assert(evo.batch_assign(q, f1, 50) == 0)
            assert(not evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e = evo.id()
            assert(evo.insert(e, f1, 41))

            assert(evo.batch_assign(q, f1, 50) == 0)
            assert(evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e1 = evo.id()
            assert(evo.insert(e1, f1, 41))
            assert(evo.insert(e1, f2, 42))

            local e2 = evo.id()
            assert(evo.insert(e2, f1, 41))
            assert(evo.insert(e2, f2, 42))
            assert(evo.insert(e2, f3, 43))

            assert(evo.batch_assign(q, f1, 50) == 2)
            assert(evo.has(e1, f1) and evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and evo.has(e2, f2) and evo.has(e2, f3))
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil)
            assert(evo.get(e2, f1) == nil and evo.get(e2, f2) == nil and evo.get(e2, f3) == 43)

            assert(evo.batch_assign(q, f3, 51) == 1)
            assert(evo.has(e1, f1) and evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and evo.has(e2, f2) and evo.has(e2, f3))
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil)
            assert(evo.get(e2, f1) == nil and evo.get(e2, f2) == nil and evo.get(e2, f3) == 51)
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, f1, f2)

        do
            local e1 = evo.id()
            assert(evo.insert(e1, f1, 41))
            assert(evo.insert(e1, f2, 42))

            local e2 = evo.id()
            assert(evo.insert(e2, f1, 41))

            local e3 = evo.id()
            assert(evo.insert(e3, f1, 41))
            assert(evo.insert(e3, f2, 42))
            assert(evo.insert(e3, f3, 43))

            assert(evo.batch_insert(q, f3, 50) == 1)

            assert(evo.has(e1, f1) and evo.has(e1, f2) and evo.has(e1, f3))
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil and evo.get(e1, f3) == 50)

            assert(evo.has(e2, f1) and not evo.has(e2, f2) and not evo.has(e2, f3))
            assert(evo.get(e2, f1) == nil and evo.get(e2, f2) == nil and evo.get(e2, f3) == nil)

            assert(evo.has(e3, f1) and evo.has(e3, f2) and evo.has(e3, f3))
            assert(evo.get(e3, f1) == nil and evo.get(e3, f2) == nil and evo.get(e3, f3) == 43)

            do
                local chunk, chunk_entities = evo.chunk(f1, f2, f3)
                assert(chunk and chunk_entities)

                assert(chunk_entities[1] == e3 and chunk_entities[2] == e1)

                assert(#evo.select(chunk, f1) == 0)
                assert(#evo.select(chunk, f2) == 0)
                assert(evo.select(chunk, f3)[1] == 43 and evo.select(chunk, f3)[2] == 50)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, f1, f2)

        do
            local e1 = evo.id()
            assert(evo.insert(e1, f1, 41))
            assert(evo.insert(e1, f2, 42))

            local e2 = evo.id()
            assert(evo.insert(e2, f1, 41))

            local e3 = evo.id()
            assert(evo.insert(e3, f1, 41))
            assert(evo.insert(e3, f2, 42))
            assert(evo.insert(e3, f3, 43))

            assert(evo.batch_remove(q, f1) == 2)

            assert(not evo.has(e1, f1) and evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and not evo.has(e2, f2) and not evo.has(e2, f3))
            assert(not evo.has(e3, f1) and evo.has(e3, f2) and evo.has(e3, f3))

            do
                local chunk, chunk_entities = evo.chunk(f2)
                assert(chunk and chunk_entities)

                assert(chunk_entities[1] == e1)
                assert(#evo.select(chunk, f1) == 0)
                assert(#evo.select(chunk, f2) == 0)
                assert(#evo.select(chunk, f3) == 0)
            end

            do
                local chunk, chunk_entities = evo.chunk(f2, f3)
                assert(chunk and chunk_entities)

                assert(chunk_entities[1] == e3)
                assert(#evo.select(chunk, f1) == 0)
                assert(#evo.select(chunk, f2) == 0)
                assert(evo.select(chunk, f3)[1] == 43)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, f1, f2)

        do
            local e1 = evo.id()
            assert(evo.insert(e1, f1, 41))
            assert(evo.insert(e1, f2, 42))

            local e2 = evo.id()
            assert(evo.insert(e2, f1, 41))

            local e3 = evo.id()
            assert(evo.insert(e3, f1, 41))
            assert(evo.insert(e3, f2, 42))
            assert(evo.insert(e3, f3, 43))

            assert(evo.batch_clear(q) == 2)

            assert(evo.is_alive(e1))
            assert(evo.is_alive(e2))
            assert(evo.is_alive(e3))

            assert(not evo.has(e1, f1) and not evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and not evo.has(e2, f2) and not evo.has(e2, f3))
            assert(not evo.has(e3, f1) and not evo.has(e3, f2) and not evo.has(e3, f3))

            do
                local chunk, chunk_entities = evo.chunk(f1, f2, f3)
                assert(chunk and chunk_entities)

                assert(next(chunk_entities) == nil)
                assert(#evo.select(chunk, f1) == 0)
                assert(#evo.select(chunk, f2) == 0)
                assert(#evo.select(chunk, f3) == 0)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, f1, f2)

        do
            local e1 = evo.id()
            assert(evo.insert(e1, f1, 41))
            assert(evo.insert(e1, f2, 42))

            local e2 = evo.id()
            assert(evo.insert(e2, f1, 41))

            local e3 = evo.id()
            assert(evo.insert(e3, f1, 41))
            assert(evo.insert(e3, f2, 42))
            assert(evo.insert(e3, f3, 43))

            assert(evo.batch_destroy(q) == 2)

            assert(not evo.is_alive(e1))
            assert(evo.is_alive(e2))
            assert(not evo.is_alive(e3))

            assert(not evo.has(e1, f1) and not evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and not evo.has(e2, f2) and not evo.has(e2, f3))
            assert(not evo.has(e3, f1) and not evo.has(e3, f2) and not evo.has(e3, f3))

            do
                local chunk, chunk_entities = evo.chunk(f1, f2, f3)
                assert(chunk and chunk_entities)

                assert(next(chunk_entities) == nil)
                assert(#evo.select(chunk, f1) == 0)
                assert(#evo.select(chunk, f2) == 0)
                assert(#evo.select(chunk, f3) == 0)
            end
        end
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_set(q, f1, 42)
            assert(c == 0 and d == true)
        end
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.get(e1, f1) == 42)
    end

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_set(q, f2, 43)
            assert(c == 0 and d == true)
        end
        assert(evo.get(e1, f2) == nil)

        assert(evo.commit())
        assert(evo.get(e1, f2) == 43)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_assign(q, f1, 42)
            assert(c == 0 and d == true)
        end
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.get(e1, f1) == 42)
    end

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_assign(q, f2, 43)
            assert(c == 0 and d == true)
        end
        assert(evo.get(e1, f2) == nil)

        assert(evo.commit())
        assert(evo.get(e1, f2) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_insert(q, f1, 42)
            assert(c == 0 and d == true)
        end
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.get(e1, f1) == 41)
    end

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_insert(q, f2, 43)
            assert(c == 0 and d == true)
        end
        assert(evo.get(e1, f2) == nil)

        assert(evo.commit())
        assert(evo.get(e1, f2) == 43)
    end
end

do
    local f1 = evo.id(1)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_remove(q, f1)
            assert(c == 0 and d == true)
        end
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.get(e1, f1) == nil)
    end
end

do
    local f1 = evo.id(1)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_clear(q)
            assert(c == 0 and d == true)
        end
        assert(evo.is_alive(e1))
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.is_alive(e1))
        assert(evo.get(e1, f1) == nil)
    end
end

do
    local f1 = evo.id(1)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    do
        assert(evo.defer())

        do
            local c, d = evo.batch_destroy(q)
            assert(c == 0 and d == true)
        end
        assert(evo.is_alive(e1))
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(not evo.is_alive(e1))
        assert(evo.get(e1, f1) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)
    evo.set(q, evo.INCLUDES, f2)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    local e2 = evo.id()
    assert(evo.insert(e2, f2, 42))

    do
        local iter, state = evo.execute(q)

        local chunk, entities = iter(state)
        assert(chunk == evo.chunk(f2))
        assert(entities and entities[1] == e2)

        chunk, entities = iter(state)
        assert(not chunk)
        assert(not entities)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))
    assert(evo.insert(e1, f2, 42))

    local e2 = evo.id()
    assert(evo.insert(e2, f1, 43))
    assert(evo.insert(e2, f3, 44))

    do
        local entity_sum = 0

        for _, entities in evo.execute(q) do
            assert(#entities > 0)
            for _, e in ipairs(entities) do
                entity_sum = entity_sum + e
            end
        end

        assert(entity_sum == e1 + e2)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, f1)

    evo.set(q, evo.EXCLUDES, f1)
    evo.set(q, evo.EXCLUDES, f2)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    local e2 = evo.id()
    assert(evo.insert(e2, f1, 43))
    assert(evo.insert(e2, f2, 44))

    do
        local iter, state = evo.execute(q)
        local chunk, entities = iter(state)
        assert(chunk == evo.chunk(f1))
        assert(entities and entities[1] == e1)

        chunk, entities = iter(state)
        assert(not chunk)
        assert(not entities)
    end

    evo.set(q, evo.EXCLUDES)

    do
        local iter, state = evo.execute(q)
        local chunk, entities = iter(state)
        assert(chunk == evo.chunk(f1))
        assert(entities and entities[1] == e1)

        chunk, entities = iter(state)
        assert(chunk == evo.chunk(f1, f2))
        assert(entities and entities[1] == e2)

        chunk, entities = iter(state)
        assert(not chunk)
        assert(not entities)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    local e2 = evo.id()
    assert(evo.insert(e2, f1, 43))
    assert(evo.insert(e2, f2, 44))

    do
        local iter, state = evo.execute(q)
        local chunk = iter(state)
        assert(chunk and chunk ~= evo.chunk(f1))
    end

    evo.set(q, evo.EXCLUDES, f2)

    do
        local iter, state = evo.execute(q)
        local chunk = iter(state)
        assert(chunk and chunk ~= evo.chunk(f1))
    end

    evo.set(q, evo.INCLUDES, f1)

    do
        local iter, state = evo.execute(q)
        local chunk, entities = iter(state)
        assert(chunk == evo.chunk(f1))
        assert(entities and entities[1] == e1)
    end
end

do
    local f1, f2 = evo.id(3)

    do
        local e = evo.id()

        local iter, state = evo.each(e)
        local fragment, component = iter(state)
        assert(not fragment and not component)
    end

    do
        local e = evo.id()
        assert(evo.insert(e, f1, 41))

        local iter, state = evo.each(e)
        local fragment, component = iter(state)
        assert(fragment == f1 and component == 41)

        fragment, component = iter(state)
        assert(not fragment and not component)
    end

    do
        local e = evo.id()
        assert(evo.insert(e, f1, 41))
        assert(evo.insert(e, f2, 42))

        do
            local iter, state = evo.each(e)
            local fragment, component = iter(state)
            assert(fragment == f1 or fragment == f2)
            assert((fragment == f1 and component == 41) or (fragment == f2 and component == 42))

            fragment, component = iter(state)
            assert(fragment == f1 or fragment == f2)
            assert((fragment == f1 and component == 41) or (fragment == f2 and component == 42))

            fragment, component = iter(state)
            assert(not fragment and not component)
        end

        do
            local fragment_sum = 0
            local component_sum = 0
            for f, c in evo.each(e) do
                fragment_sum = fragment_sum + f
                component_sum = component_sum + c
            end
            assert(fragment_sum == f1 + f2)
            assert(component_sum == 41 + 42)
        end
    end

    do
        local s = evo.id()
        evo.set(s, evo.TAG)

        local e = evo.id()
        assert(evo.insert(e, f1))
        assert(evo.insert(e, s))

        do
            local iter, state = evo.each(e)
            local fragment, component = iter(state)
            assert(fragment == f1 or fragment == s)
            if fragment == f1 then
                assert(component == true)
            elseif fragment == s then
                assert(component == nil)
            end

            fragment, component = iter(state)
            assert(fragment == f1 or fragment == s)
            if fragment == f1 then
                assert(component == true)
            elseif fragment == s then
                assert(component == nil)
            end

            fragment, component = iter(state)
            assert(not fragment and not component)
        end
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local e = evo.entity()
            :set(f1, 41)
            :set(f2, 42)
            :build()
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
    end

    do
        local e = evo.entity()
            :set(f1, 11)
            :set(f1, 41)
            :build()
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
    end
end

do
    local f1 = evo.fragment():default(41):build()
    local f2 = evo.fragment():construct(function() return 42 end):build()
    local f3 = evo.fragment():tag():build()

    local e0 = evo.entity():build()
    assert(not evo.has_any(e0, f1, f2, f3))

    local e1 = evo.entity():set(f1):build()
    assert(evo.has(e1, f1))
    assert(evo.get(e1, f1) == 41)

    local e2 = evo.entity():set(f1):set(f2):build()
    assert(evo.has(e2, f1) and evo.has(e2, f2))
    assert(evo.get(e2, f1) == 41 and evo.get(e2, f2) == 42)

    local e3 = evo.entity():set(f1):set(f2):set(f3):build()
    assert(evo.has(e3, f1) and evo.has(e3, f2) and evo.has(e3, f3))
    assert(evo.get(e3, f1) == 41 and evo.get(e3, f2) == 42 and evo.get(e3, f3) == nil)

    ---@param q evolved.query
    ---@return evolved.entity[]
    local function collect_entities(q)
        local entities = {}
        for _, es, es_count in evo.execute(q) do
            assert(#es == es_count)
            for _, e in ipairs(es) do
                entities[#entities + 1] = e
            end
        end
        return entities
    end

    local q1 = evo.query():include(f1):build()
    local q2 = evo.query():include(f1, f2):build()
    local q3 = evo.query():include(f1):include(f2):exclude(f3):build()

    do
        local entities = collect_entities(q1)
        assert(#entities == 3)
        assert(entities[1] == e1)
        assert(entities[2] == e2)
        assert(entities[3] == e3)
    end

    do
        local entities = collect_entities(q2)
        assert(#entities == 2)
        assert(entities[1] == e2)
        assert(entities[2] == e3)
    end

    do
        local entities = collect_entities(q3)
        assert(#entities == 1)
        assert(entities[1] == e2)
    end
end

do
    local f1_assign_count = 0
    local f1_insert_count = 0
    local f2_set_count = 0
    local f2_remove_count = 0

    local FB = evo.fragment()

    local f1 = FB
        :on_assign(function(e, f, nc, oc)
            f1_assign_count = f1_assign_count + 1
            assert(evo.is_alive(e))
            assert(evo.is_alive(f))
            assert(nc == 42)
            assert(oc == 41)
        end)
        :on_insert(function(e, f, nc)
            f1_insert_count = f1_insert_count + 1
            assert(evo.is_alive(e))
            assert(evo.is_alive(f))
            assert(nc == 41)
        end)
        :build()

    local f2 = FB
        :on_set(function(e, f, nc, oc)
            f2_set_count = f2_set_count + 1
            assert(evo.is_alive(e))
            assert(evo.is_alive(f))
            if oc then
                assert(oc == 81)
                assert(nc == 82)
            else
                assert(nc == 81)
            end
        end)
        :on_remove(function(e, f, c)
            f2_remove_count = f2_remove_count + 1
            assert(evo.get(e, f) == nil)
            assert(evo.is_alive(f))
            assert(c == 82)
        end)
        :build()

    local e1 = evo.entity():set(f1, 41):build()
    assert(f1_assign_count == 0 and f1_insert_count == 1)

    local e2 = evo.entity():set(f1, 42):set(f1, 41):build()
    assert(f1_assign_count == 0 and f1_insert_count == 2)

    assert(evo.assign(e1, f1, 42))
    assert(f1_assign_count == 1 and f1_insert_count == 2)

    assert(evo.assign(e2, f1, 42))
    assert(f1_assign_count == 2 and f1_insert_count == 2)

    assert(evo.get(e1, f1) == 42 and evo.get(e2, f1) == 42)

    assert(evo.set(e1, f2, 81))
    assert(f2_set_count == 1)
    assert(evo.set(e1, f2, 82))
    assert(f2_set_count == 2)

    assert(evo.set(e2, f2, 81))
    assert(f2_set_count == 3)
    assert(evo.set(e2, f2, 82))
    assert(f2_set_count == 4)

    assert(evo.get(e1, f2) == 82 and evo.get(e2, f2) == 82)

    assert(evo.remove(e1, f1, f1, f2, f2) and evo.remove(e1, f1, f1, f2, f2))
    assert(f2_remove_count == 1)

    assert(evo.destroy(e2) and evo.destroy(e2))
    assert(f2_remove_count == 2)
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local e = evo.id()
        assert(not evo.multi_insert(e, {}))
        assert(not evo.multi_insert(e, {}, {}))
        assert(not evo.multi_insert(e, {}, { 41 }))
        assert(evo.is_alive(e) and evo.is_empty(e))

        assert(evo.multi_insert(e, { f1 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == true)

        assert(not evo.multi_insert(e, { f1 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == true)

        assert(evo.multi_insert(e, { f2 }, { 42, 43 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == true)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
    end

    do
        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2 }, { 41 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == true)

        assert(evo.multi_insert(e, { f1, f3 }, { 20, 43 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == true)
        assert(evo.has(e, f3) and evo.get(e, f3) == 43)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local e1 = evo.id()
        assert(evo.multi_insert(e1, { f1, f2 }, { 41, 42 }))
        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == 42)

        local e2 = evo.id()
        assert(evo.multi_insert(e2, { f1, f2 }, { 43, 44 }))
        assert(evo.has(e2, f1) and evo.get(e2, f1) == 43)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 44)

        assert(evo.multi_insert(e1, { f3 }))
        do
            local chunk, entities = evo.chunk(f1, f2)
            assert(entities and #entities == 1 and entities[1] == e2)
            assert(chunk and evo.select(chunk, f2)[1] == 44)
        end
    end

    do
        local e1, e2 = evo.id(2)
        evo.defer()
        do
            evo.multi_insert(e1, { f1, f2 }, { 41, 42 })
            evo.multi_insert(e2, { f2, f2 }, { 43, 44 })
        end
        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(evo.is_alive(e2) and evo.is_empty(e2))
        assert(evo.commit())
        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == 42)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 43)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f3, evo.TAG)

    local last_set_entity = 0
    local last_set_component = 0

    evo.set(f1, evo.ON_SET, function(e, f, c)
        assert(f == f1)
        last_set_entity = e
        last_set_component = c
    end)

    evo.set(f2, evo.ON_SET, function(e, f, c)
        assert(f == f2)
        last_set_entity = e
        last_set_component = c
    end)

    evo.set(f3, evo.ON_SET, function(e, f, c)
        assert(f == f3)
        last_set_entity = e
        last_set_component = c
    end)

    do
        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2 }, { 41, 42 }))
        assert(last_set_entity == e and last_set_component == 42)
    end

    do
        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2, f3 }, { 41, 42, 43 }))
        assert(last_set_entity == e and last_set_component == nil)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local e = evo.id()
        assert(not evo.multi_assign(e, {}))
        assert(not evo.multi_assign(e, {}, {}))
        assert(not evo.multi_assign(e, {}, { 41 }))
        assert(evo.is_alive(e) and evo.is_empty(e))

        assert(evo.multi_insert(e, { f1 }, { 21 }))
        assert(evo.multi_assign(e, { f1, f2 }, { 41, 42 }))
        assert(not evo.multi_assign(e, { f2 }, { 42 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)

        assert(not evo.multi_assign(e, { f3 }, { 43 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
        assert(not evo.has(e, f3) and evo.get(e, f3) == nil)

        assert(evo.multi_insert(e, { f2 }, { 22 }))
        assert(evo.multi_assign(e, { f2 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == true)
        assert(evo.multi_assign(e, { f2 }, { 42, 43 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
    end

    do
        local e1, e2 = evo.id(2)
        evo.defer()
        do
            evo.multi_insert(e1, { f1, f2 }, { 21, 22 })
            evo.multi_assign(e1, { f1, f2 }, { 41, 42 })

            evo.multi_insert(e2, { f1, f2 }, { 31, 32 })
            evo.multi_assign(e2, { f1, f2 }, { 51, 52 })
        end
        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(evo.is_alive(e2) and evo.is_empty(e2))
        assert(evo.commit())
        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == 42)
        assert(evo.has(e2, f1) and evo.get(e2, f1) == 51)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 52)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f3, evo.TAG)

    local last_set_entity = 0
    local last_set_component = 0

    evo.set(f1, evo.ON_SET, function(e, f, c)
        assert(f == f1)
        last_set_entity = e
        last_set_component = c
    end)

    evo.set(f2, evo.ON_SET, function(e, f, c)
        assert(f == f2)
        last_set_entity = e
        last_set_component = c
    end)

    evo.set(f3, evo.ON_SET, function(e, f, c)
        assert(f == f3)
        last_set_entity = e
        last_set_component = c
    end)

    do
        local e = evo.id()
        assert(not evo.multi_assign(e, { f1, f2 }, { 41, 42 }))
        assert(last_set_entity == 0 and last_set_component == 0)

        assert(evo.multi_insert(e, { f1, f2 }, { 21, 22 }))
        assert(last_set_entity == e and last_set_component == 22)

        assert(evo.multi_assign(e, { f1, f2 }, { 41, 42 }))
        assert(last_set_entity == e and last_set_component == 42)
    end

    do
        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2, f3 }, { 21, 22, 23 }))
        assert(last_set_entity == e and last_set_component == nil)

        last_set_entity, last_set_component = 0, 0
        assert(evo.multi_assign(e, { f1, f2, f3 }, { 41, 42, 43 }))
        assert(last_set_entity == e and last_set_component == nil)
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
        assert(evo.has(e, f3) and evo.get(e, f3) == nil)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f3, evo.TAG)

    do
        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2, f3 }, { 41, 42, 43 }))
        assert(evo.has_all(e, f1, f2, f3))

        assert(evo.multi_remove(e, {}))
        assert(evo.multi_remove(e, { f4 }))
        assert(evo.has_all(e, f1, f2, f3))

        assert(evo.multi_remove(e, { f3 }))
        assert(evo.has(e, f1) and evo.has(e, f2) and not evo.has(e, f3))
        assert(evo.get(e, f1) == 41 and evo.get(e, f2) == 42 and evo.get(e, f3) == nil)

        assert(evo.multi_remove(e, { f1, f2, f4 }))
        assert(not evo.has_any(e, f1, f2, f3))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == nil)
    end

    do
        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2, f3 }, { 41, 42, 43 }))
        assert(evo.has_all(e, f1, f2, f3))
        evo.defer()
        evo.multi_remove(e, { f1, f2 })
        assert(evo.has_all(e, f1, f2, f3))
        assert(evo.commit())
        assert(not evo.has(e, f1) and not evo.has(e, f2) and evo.has(e, f3))
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f3, evo.TAG)

    local last_remove_entity = 0
    local last_remove_component = 0

    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        assert(f == f1)
        last_remove_entity = e
        last_remove_component = c
    end)

    evo.set(f2, evo.ON_REMOVE, function(e, f, c)
        assert(f == f2)
        last_remove_entity = e
        last_remove_component = c
    end)

    evo.set(f3, evo.ON_REMOVE, function(e, f, c)
        assert(f == f3)
        last_remove_entity = e
        last_remove_component = c
    end)

    do
        local e = evo.id()
        assert(evo.multi_remove(e, { f1, f2 }))
        assert(last_remove_entity == 0 and last_remove_component == 0)

        assert(evo.multi_insert(e, { f1, f2, f3 }, { 41, 42 }))
        assert(last_remove_entity == 0 and last_remove_component == 0)
        assert(evo.multi_remove(e, { f1, f2 }))
        assert(last_remove_entity == e and last_remove_component == 42)
        assert(evo.multi_remove(e, { f3 }))
        assert(last_remove_entity == e and last_remove_component == nil)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local e1, e2 = evo.id(2)
        assert(evo.multi_insert(e1, { f1, f2, f3 }, { 41, 42, 43 }))
        assert(evo.multi_insert(e2, { f1, f2, f3 }, { 44, 45, 46 }))

        assert(evo.multi_remove(e1, { f1, f2 }))

        do
            local chunk, entities = evo.chunk(f1, f2, f3)
            assert(entities and #entities == 1 and entities[1] == e2)
            assert(chunk and evo.select(chunk, f2)[1] == 45)
        end

        do
            local chunk, entities = evo.chunk(f3)
            assert(entities and #entities == 1 and entities[1] == e1)
            assert(chunk and evo.select(chunk, f3)[1] == 43)
        end
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f3, evo.DEFAULT, 43)
    evo.set(f4, evo.TAG)


    do
        local e = evo.id()
        assert(not evo.multi_set(e, {}))
        assert(not evo.multi_set(e, {}, {}))
        assert(not evo.multi_set(e, {}, { 41 }))
        assert(evo.is_alive(e) and evo.is_empty(e))

        assert(evo.multi_set(e, { f1 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == true)

        assert(evo.multi_set(e, { f1 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == true)

        assert(evo.multi_set(e, { f1 }, { 41 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)

        assert(evo.multi_set(e, { f2 }, { 42 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)

        assert(evo.multi_set(e, { f2 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == true)

        assert(evo.multi_set(e, { f2, f3 }, { 42 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
        assert(evo.has(e, f3) and evo.get(e, f3) == 43)

        assert(evo.multi_set(e, { f3, f4 }, { 33, 44 }))
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
        assert(evo.has(e, f3) and evo.get(e, f3) == 33)
        assert(evo.has(e, f4) and evo.get(e, f4) == nil)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f3, evo.TAG)

    local last_assign_entity = 0
    local last_assign_new_component = 0
    local last_assign_old_component = 0

    evo.set(f1, evo.ON_ASSIGN, function(e, f, nc, oc)
        assert(f == f1)
        last_assign_entity = e
        last_assign_new_component = nc
        last_assign_old_component = oc
    end)

    evo.set(f2, evo.ON_ASSIGN, function(e, f, nc, oc)
        assert(f == f2)
        last_assign_entity = e
        last_assign_new_component = nc
        last_assign_old_component = oc
    end)

    evo.set(f3, evo.ON_ASSIGN, function(e, f, nc, oc)
        assert(f == f3)
        last_assign_entity = e
        last_assign_new_component = nc
        last_assign_old_component = oc
    end)

    local last_insert_entity = 0
    local last_insert_component = 0

    evo.set(f1, evo.ON_INSERT, function(e, f, nc)
        assert(f == f1)
        last_insert_entity = e
        last_insert_component = nc
    end)

    evo.set(f2, evo.ON_INSERT, function(e, f, nc)
        assert(f == f2)
        last_insert_entity = e
        last_insert_component = nc
    end)

    evo.set(f3, evo.ON_INSERT, function(e, f, nc)
        assert(f == f3)
        last_insert_entity = e
        last_insert_component = nc
    end)

    do
        last_assign_entity, last_assign_old_component, last_assign_new_component = 0, 0, 0
        last_insert_entity, last_insert_component = 0, 0

        local e = evo.id()
        assert(evo.multi_set(e, { f1 }))
        assert(last_assign_entity == 0 and last_assign_old_component == 0 and last_assign_new_component == 0)
        assert(last_insert_entity == e and last_insert_component == true)

        last_assign_entity, last_assign_old_component, last_assign_new_component = 0, 0, 0
        last_insert_entity, last_insert_component = 0, 0

        assert(evo.multi_set(e, { f1 }, { 41 }))
        assert(last_assign_entity == e and last_assign_old_component == true and last_assign_new_component == 41)
        assert(last_insert_entity == 0 and last_insert_component == 0)

        last_assign_entity, last_assign_old_component, last_assign_new_component = 0, 0, 0
        last_insert_entity, last_insert_component = 0, 0

        assert(evo.multi_set(e, { f1, f2 }, { 11 }))
        assert(last_assign_entity == e and last_assign_old_component == 41 and last_assign_new_component == 11)
        assert(last_insert_entity == e and last_insert_component == 42)
    end
end

do
    local f1 = evo.id()

    local assign_entity_sum = 0
    local assign_component_sum = 0
    local insert_entity_sum = 0
    local insert_component_sum = 0
    local remove_entity_sum = 0
    local remove_component_sum = 0

    evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
        assert(f == f1)
        assign_entity_sum = assign_entity_sum + e
        assign_component_sum = assign_component_sum + c
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        assert(f == f1)
        insert_entity_sum = insert_entity_sum + e
        insert_component_sum = insert_component_sum + c
    end)

    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        assert(f == f1)
        remove_entity_sum = remove_entity_sum + e
        remove_component_sum = remove_component_sum + c
    end)

    do
        assign_entity_sum, assign_component_sum = 0, 0
        insert_entity_sum, insert_component_sum = 0, 0

        local e = evo.id()
        assert(evo.multi_set(e, { f1, f1 }, { 41, 42 }))

        assert(assign_entity_sum == e and assign_component_sum == 42)
        assert(insert_entity_sum == e and insert_component_sum == 41)
    end

    do
        assign_entity_sum, assign_component_sum = 0, 0
        insert_entity_sum, insert_component_sum = 0, 0

        local e = evo.id()
        assert(evo.multi_set(e, { f1, f1, f1 }, { 41, 42, 43 }))

        assert(assign_entity_sum == e + e and assign_component_sum == 42 + 43)
        assert(insert_entity_sum == e and insert_component_sum == 41)
    end

    do
        assign_entity_sum, assign_component_sum = 0, 0
        insert_entity_sum, insert_component_sum = 0, 0

        local e = evo.id()
        assert(evo.insert(e, f1, 41))
        assert(evo.multi_assign(e, { f1, f1 }, { 42, 43 }))

        assert(assign_entity_sum == e + e and assign_component_sum == 42 + 43)
        assert(insert_entity_sum == e and insert_component_sum == 41)
    end

    do
        assign_entity_sum, assign_component_sum = 0, 0
        insert_entity_sum, insert_component_sum = 0, 0

        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f1 }, { 41, 42 }))

        assert(insert_entity_sum == e and insert_component_sum == 41)
    end

    do
        remove_entity_sum, remove_component_sum = 0, 0

        local e = evo.id()
        assert(evo.insert(e, f1, 41))
        assert(evo.multi_remove(e, { f1, f1 }))

        assert(remove_entity_sum == e and remove_component_sum == 41)
    end
end

do
    local f1, f2 = evo.id(2)
    local qb = evo.query()

    do
        local q = qb:build()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(includes == nil)
        assert(excludes == nil)
    end

    do
        local q = qb:include(f1):build()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(#includes == 1 and includes[1] == f1)
        assert(excludes == nil)
    end

    do
        local q = qb:include(f1, f2):build()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(#includes == 2 and includes[1] == f1 and includes[2] == f2)
        assert(excludes == nil)
    end

    do
        local q = qb:include(f1):include(f2):build()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(#includes == 2 and includes[1] == f1 and includes[2] == f2)
        assert(excludes == nil)
    end

    do
        local q = qb:exclude(f1):build()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(includes == nil)
        assert(#excludes == 1 and excludes[1] == f1)
    end

    do
        local q = qb:exclude(f1, f2):build()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(includes == nil)
        assert(#excludes == 2 and excludes[1] == f1 and excludes[2] == f2)
    end

    do
        local q = qb:exclude(f1):exclude(f2):build()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(includes == nil)
        assert(#excludes == 2 and excludes[1] == f1 and excludes[2] == f2)
    end

    do
        qb:include(f1)
        qb:exclude(f2)

        local q = qb:build()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(#includes == 1 and includes[1] == f1)
        assert(#excludes == 1 and excludes[1] == f2)
    end
end

do
    local f1, f2 = evo.id(2)
    local eb = evo.entity()

    do
        local e = eb:build()
        assert(evo.is_alive(e) and evo.is_empty(e))
    end

    do
        local e = eb:set(f1, 41):build()
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
    end

    do
        local e = eb:set(f1, 41):set(f2, 42):build()
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
    end

    do
        local e = eb:build()
        assert(evo.is_alive(e) and evo.is_empty(e))
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f3, evo.TAG)

    do
        local e = evo.spawn_with()
        assert(evo.is_alive(e) and evo.is_empty(e))
    end

    do
        local e = evo.spawn_with({})
        assert(evo.is_alive(e) and evo.is_empty(e))
    end

    do
        local e1 = evo.spawn_with({ f1 })
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)

        local e2 = evo.spawn_with({ f1 }, {})
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)

        local e3 = evo.spawn_with({ f1 }, { 41 })
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 41)
    end

    do
        local e1 = evo.spawn_with({ f1, f2 })
        assert(evo.has_all(e1, f1, f2))
        assert(evo.get(e1, f1) == true and evo.get(e1, f2) == true)

        local e2 = evo.spawn_with({ f1, f2 }, {})
        assert(evo.has_all(e2, f1, f2))
        assert(evo.get(e2, f1) == true and evo.get(e2, f2) == true)

        local e3 = evo.spawn_with({ f1, f2 }, { 41 })
        assert(evo.has_all(e3, f1, f2))
        assert(evo.get(e3, f1) == 41 and evo.get(e3, f2) == true)

        local e4 = evo.spawn_with({ f1, f2 }, { nil, 42 })
        assert(evo.has_all(e4, f1, f2))
        assert(evo.get(e4, f1) == true and evo.get(e4, f2) == 42)

        local e5 = evo.spawn_with({ f1, f2 }, { 41, 42 })
        assert(evo.has_all(e5, f1, f2))
        assert(evo.get(e5, f1) == 41 and evo.get(e5, f2) == 42)

        local e6 = evo.spawn_with({ f1, f2 }, { 41, 42, 43 })
        assert(evo.has_all(e6, f1, f2))
        assert(evo.get(e6, f1) == 41 and evo.get(e6, f2) == 42)
    end

    do
        local e1 = evo.spawn_with({ f3 })
        assert(evo.has(e1, f3))
        assert(evo.get(e1, f3) == nil)

        local e2 = evo.spawn_with({ f2, f3 })
        assert(evo.has_all(e2, f2, f3))
        assert(evo.get(e2, f2) == true and evo.get(e2, f3) == nil)

        local e3 = evo.spawn_with({ f2, f3 }, { 42 })
        assert(evo.has_all(e3, f2, f3))
        assert(evo.get(e3, f2) == 42 and evo.get(e3, f3) == nil)

        local e4 = evo.spawn_with({ f2, f3 }, { 42, 43, 44 })
        assert(evo.has_all(e4, f2, f3))
        assert(evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.DEFAULT, 21)
    evo.set(f3, evo.TAG)

    do
        local e = evo.spawn_with()
        assert(evo.is_alive(e) and evo.is_empty(e))
    end

    do
        local e = evo.spawn_with({})
        assert(evo.is_alive(e) and evo.is_empty(e))
    end

    do
        local e1 = evo.spawn_with({ f1 })
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)

        local e2 = evo.spawn_with({ f1 }, {})
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)

        local e3 = evo.spawn_with({ f1 }, { 41 })
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 41)
    end

    do
        local e1 = evo.spawn_with({ f1, f2 })
        assert(evo.has_all(e1, f1, f2))
        assert(evo.get(e1, f1) == true and evo.get(e1, f2) == 21)

        local e2 = evo.spawn_with({ f1, f2 }, {})
        assert(evo.has_all(e2, f1, f2))
        assert(evo.get(e2, f1) == true and evo.get(e2, f2) == 21)

        local e3 = evo.spawn_with({ f1, f2 }, { 41 })
        assert(evo.has_all(e3, f1, f2))
        assert(evo.get(e3, f1) == 41 and evo.get(e3, f2) == 21)

        local e4 = evo.spawn_with({ f1, f2 }, { nil, 42 })
        assert(evo.has_all(e4, f1, f2))
        assert(evo.get(e4, f1) == true and evo.get(e4, f2) == 42)

        local e5 = evo.spawn_with({ f1, f2 }, { 41, 42 })
        assert(evo.has_all(e5, f1, f2))
        assert(evo.get(e5, f1) == 41 and evo.get(e5, f2) == 42)

        local e6 = evo.spawn_with({ f1, f2 }, { 41, 42, 43 })
        assert(evo.has_all(e6, f1, f2))
        assert(evo.get(e6, f1) == 41 and evo.get(e6, f2) == 42)
    end

    do
        local e1 = evo.spawn_with({ f3 })
        assert(evo.has(e1, f3))
        assert(evo.get(e1, f3) == nil)

        local e2 = evo.spawn_with({ f2, f3 })
        assert(evo.has_all(e2, f2, f3))
        assert(evo.get(e2, f2) == 21 and evo.get(e2, f3) == nil)

        local e3 = evo.spawn_with({ f2, f3 }, { 42 })
        assert(evo.has_all(e3, f2, f3))
        assert(evo.get(e3, f2) == 42 and evo.get(e3, f3) == nil)

        local e4 = evo.spawn_with({ f2, f3 }, { 42, 43, 44 })
        assert(evo.has_all(e4, f2, f3))
        assert(evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil)
    end
end

do
    local cf = evo.id()
    local f1, f2, f3 = evo.id(3)

    evo.set(f1, cf)
    evo.set(f2, cf)
    evo.set(f3, cf)

    evo.set(f2, evo.DEFAULT, 21)
    evo.set(f3, evo.TAG)

    local set_count = 0
    local insert_count = 0

    local last_set_entity = 0
    local last_set_component = 0
    local last_insert_entity = 0
    local last_insert_component = 0

    local q = evo.query():include(cf):build()

    evo.batch_set(q, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f1 or f == f2 or f == f3)
        last_set_component = c
        set_count = set_count + 1
    end)

    evo.batch_set(q, evo.ON_INSERT, function(e, f, c)
        last_insert_entity = e
        assert(f == f1 or f == f2 or f == f3)
        last_insert_component = c
        insert_count = insert_count + 1
    end)

    assert(set_count == 0 and insert_count == 0)
    assert(last_set_entity == 0 and last_set_component == 0)
    assert(last_insert_entity == 0 and last_insert_component == 0)

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn_with({ f1 })
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == true)
        assert(last_insert_entity == e and last_insert_component == true)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn_with({ f2 })
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == 21)
        assert(last_insert_entity == e and last_insert_component == 21)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn_with({ f1, f2 })
        assert(set_count == 2 and insert_count == 2)
        assert(last_set_entity == e and last_set_component == 21)
        assert(last_insert_entity == e and last_insert_component == 21)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn_with({ f3 }, { 33 })
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == nil)
        assert(last_insert_entity == e and last_insert_component == nil)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn_with({ f3, f2 }, { 33, 22 })
        assert(set_count == 2 and insert_count == 2)
        assert(last_set_entity == e and last_set_component == nil)
        assert(last_insert_entity == e and last_insert_component == nil)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f3, evo.DEFAULT, 33)
    evo.set(f4, evo.TAG)

    do
        local e = evo.spawn_at()
        assert(evo.is_alive(e) and evo.is_empty(e))
    end

    do
        local c = evo.chunk(f1)

        local e1 = evo.spawn_at(c)
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)

        local e2 = evo.spawn_at(c, { f1 })
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)

        local e3 = evo.spawn_at(c, { f1, f2 })
        assert(evo.has(e3, f1) and evo.get(e3, f1) == true)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)

        local e4 = evo.spawn_at(c, { f1, f2 }, { 41 })
        assert(evo.has(e4, f1) and evo.get(e4, f1) == 41)
        assert(not evo.has(e4, f2) and evo.get(e4, f2) == nil)

        local e5 = evo.spawn_at(c, { f1, f2 }, { 41, 42 })
        assert(evo.has(e5, f1) and evo.get(e5, f1) == 41)
        assert(not evo.has(e5, f2) and evo.get(e5, f2) == nil)

        local e6 = evo.spawn_at(c, { f2 }, { 42 })
        assert(evo.has(e6, f1) and evo.get(e6, f1) == true)
        assert(not evo.has(e6, f2) and evo.get(e6, f2) == nil)
    end

    do
        local c = evo.chunk(f1, f2)

        local e1 = evo.spawn_at(c)
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)

        local e2 = evo.spawn_at(c, { f1 })
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)

        local e3 = evo.spawn_at(c, { f1, f2 })
        assert(evo.has(e3, f1) and evo.get(e3, f1) == true)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == true)

        local e4 = evo.spawn_at(c, { f1, f2, f3 })
        assert(evo.has(e4, f1) and evo.get(e4, f1) == true)
        assert(evo.has(e4, f2) and evo.get(e4, f2) == true)
        assert(not evo.has(e4, f3) and evo.get(e4, f3) == nil)

        local e5 = evo.spawn_at(c, { f1, f2 }, { 41 })
        assert(evo.has(e5, f1) and evo.get(e5, f1) == 41)
        assert(evo.has(e5, f2) and evo.get(e5, f2) == true)

        local e6 = evo.spawn_at(c, { f1, f2 }, { 41, 42 })
        assert(evo.has(e6, f1) and evo.get(e6, f1) == 41)
        assert(evo.has(e6, f2) and evo.get(e6, f2) == 42)

        local e7 = evo.spawn_at(c, { f1, f2, f3 }, { 41, 42, 43 })
        assert(evo.has(e7, f1) and evo.get(e7, f1) == 41)
        assert(evo.has(e7, f2) and evo.get(e7, f2) == 42)
        assert(not evo.has(e7, f3) and evo.get(e7, f3) == nil)

        local e8 = evo.spawn_at(c, { f3 }, { 43 })
        assert(evo.has(e8, f1) and evo.get(e8, f1) == true)
        assert(evo.has(e8, f2) and evo.get(e8, f2) == true)
        assert(not evo.has(e8, f3) and evo.get(e8, f3) == nil)

        local e9 = evo.spawn_at(c, { f2 }, { 42 })
        assert(evo.has(e9, f1) and evo.get(e9, f1) == true)
        assert(evo.has(e9, f2) and evo.get(e9, f2) == 42)
        assert(not evo.has(e9, f3) and evo.get(e9, f3) == nil)
    end

    do
        local c = evo.chunk(f2, f3, f4)

        local e1 = evo.spawn_at(c)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(evo.has(e1, f3) and evo.get(e1, f3) == 33)
        assert(evo.has(e1, f4) and evo.get(e1, f4) == nil)

        local e2 = evo.spawn_at(c, { f1 })
        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(evo.has(e2, f3) and evo.get(e2, f3) == 33)
        assert(evo.has(e2, f4) and evo.get(e2, f4) == nil)

        local e3 = evo.spawn_at(c, { f1 }, { 41 })
        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == true)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == 33)
        assert(evo.has(e3, f4) and evo.get(e3, f4) == nil)

        local e4 = evo.spawn_at(c, { f1, f3, f4 }, { 41, 43, 44 })
        assert(not evo.has(e4, f1) and evo.get(e4, f1) == nil)
        assert(evo.has(e4, f2) and evo.get(e4, f2) == true)
        assert(evo.has(e4, f3) and evo.get(e4, f3) == 43)
        assert(evo.has(e4, f4) and evo.get(e4, f4) == nil)
    end

    do
        local c = evo.chunk(f1, f2, f3)

        local e1 = evo.spawn_at(c, { f1, f2, f3 })
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(evo.has(e1, f3) and evo.get(e1, f3) == 33)
    end
end

do
    local cf = evo.id()
    local f1, f2, f3 = evo.id(3)

    evo.set(f1, cf)
    evo.set(f2, cf)
    evo.set(f3, cf)

    evo.set(f2, evo.DEFAULT, 22)
    evo.set(f3, evo.TAG)

    local set_count = 0
    local insert_count = 0

    local last_set_entity = 0
    local last_set_component = 0
    local last_insert_entity = 0
    local last_insert_component = 0

    local q = evo.query():include(cf):build()

    evo.batch_set(q, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f1 or f == f2 or f == f3)
        last_set_component = c
        set_count = set_count + 1
    end)

    evo.batch_set(q, evo.ON_INSERT, function(e, f, c)
        last_insert_entity = e
        assert(f == f1 or f == f2 or f == f3)
        last_insert_component = c
        insert_count = insert_count + 1
    end)

    assert(set_count == 0 and insert_count == 0)
    assert(last_set_entity == 0 and last_set_component == 0)
    assert(last_insert_entity == 0 and last_insert_component == 0)

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local c = evo.chunk(f1)
        local e = evo.spawn_at(c)
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == true)
        assert(last_insert_entity == e and last_insert_component == true)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local c = evo.chunk(f2)
        local e = evo.spawn_at(c)
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == 22)
        assert(last_insert_entity == e and last_insert_component == 22)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local c = evo.chunk(f2, f1)
        local e = evo.spawn_at(c)
        assert(set_count == 2 and insert_count == 2)
        assert(last_set_entity == e and last_set_component == 22)
        assert(last_insert_entity == e and last_insert_component == 22)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local c = evo.chunk(f3)
        local e = evo.spawn_at(c)
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == nil)
        assert(last_insert_entity == e and last_insert_component == nil)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local c = evo.chunk(f3, f2)
        local e = evo.spawn_at(c, { f3, f2 }, { 33, 22 })
        assert(set_count == 2 and insert_count == 2)
        assert(last_set_entity == e and last_set_component == nil)
        assert(last_insert_entity == e and last_insert_component == nil)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f3, evo.DEFAULT, 3)
    evo.set(f4, evo.TAG)

    do
        assert(evo.defer())
        local e, d = evo.spawn_with()
        assert(evo.is_alive(e) and evo.is_empty(e))
        assert(not d)
        assert(evo.commit())
        assert(evo.is_alive(e) and evo.is_empty(e))
    end

    do
        assert(evo.defer())
        local e, d = evo.spawn_with({})
        assert(evo.is_alive(e) and evo.is_empty(e))
        assert(not d)
        assert(evo.commit())
        assert(evo.is_alive(e) and evo.is_empty(e))
    end

    do
        assert(evo.defer())
        local e1, d1 = evo.spawn_with({ f1 })
        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(d1)
        assert(evo.commit())
        assert(evo.is_alive(e1) and not evo.is_empty(e1))
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)

        assert(evo.defer())
        local e2, d2 = evo.spawn_with({ f1 }, {})
        assert(evo.is_alive(e2) and evo.is_empty(e2))
        assert(d2)
        assert(evo.commit())
        assert(evo.is_alive(e2) and not evo.is_empty(e2))
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)

        assert(evo.defer())
        local e3, d3 = evo.spawn_with({ f1 }, { 41 })
        assert(evo.is_alive(e3) and evo.is_empty(e3))
        assert(d3)
        assert(evo.commit())
        assert(evo.is_alive(e3) and not evo.is_empty(e3))
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 41)
    end

    do
        assert(evo.defer())
        local e1, d1 = evo.spawn_with({ f1, f2 })
        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(d1)
        assert(evo.commit())
        assert(evo.is_alive(e1) and not evo.is_empty(e1))
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)

        assert(evo.defer())
        local e2, d2 = evo.spawn_with({ f1, f2 }, {})
        assert(evo.is_alive(e2) and evo.is_empty(e2))
        assert(d2)
        assert(evo.commit())
        assert(evo.is_alive(e2) and not evo.is_empty(e2))
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)

        assert(evo.defer())
        local e3, d3 = evo.spawn_with({ f1, f2 }, { 41 })
        assert(evo.is_alive(e3) and evo.is_empty(e3))
        assert(d3)
        assert(evo.commit())
        assert(evo.is_alive(e3) and not evo.is_empty(e3))
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 41)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == true)

        assert(evo.defer())
        local e4, d4 = evo.spawn_with({ f1, f2 }, { nil, 42 })
        assert(evo.is_alive(e4) and evo.is_empty(e4))
        assert(d4)
        assert(evo.commit())
        assert(evo.is_alive(e4) and not evo.is_empty(e4))
        assert(evo.has(e4, f1) and evo.get(e4, f1) == true)
        assert(evo.has(e4, f2) and evo.get(e4, f2) == 42)

        assert(evo.defer())
        local e5, d5 = evo.spawn_with({ f1, f2 }, { 41, 42 })
        assert(evo.is_alive(e5) and evo.is_empty(e5))
        assert(d5)
        assert(evo.commit())
        assert(evo.is_alive(e5) and not evo.is_empty(e5))
        assert(evo.has(e5, f1) and evo.get(e5, f1) == 41)
        assert(evo.has(e5, f2) and evo.get(e5, f2) == 42)

        assert(evo.defer())
        local e6, d6 = evo.spawn_with({ f1, f2 }, { 41, 42, 43 })
        assert(evo.is_alive(e6) and evo.is_empty(e6))
        assert(d6)
        assert(evo.commit())
        assert(evo.is_alive(e6) and not evo.is_empty(e6))
        assert(evo.has(e6, f1) and evo.get(e6, f1) == 41)
        assert(evo.has(e6, f2) and evo.get(e6, f2) == 42)
    end

    do
        assert(evo.defer())
        local e1, d1 = evo.spawn_with({ f3, f4 })
        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(d1)
        assert(evo.commit())
        assert(evo.is_alive(e1) and not evo.is_empty(e1))
        assert(evo.has(e1, f3) and evo.get(e1, f3) == 3)
        assert(evo.has(e1, f4) and evo.get(e1, f4) == nil)

        assert(evo.defer())
        local e2, d2 = evo.spawn_with({ f3, f4 }, { 33, 44 })
        assert(evo.is_alive(e2) and evo.is_empty(e2))
        assert(d2)
        assert(evo.commit())
        assert(evo.is_alive(e2) and not evo.is_empty(e2))
        assert(evo.has(e2, f3) and evo.get(e2, f3) == 33)
        assert(evo.has(e2, f4) and evo.get(e2, f4) == nil)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)

    local e1 = evo.entity():set(f1, 11):build()
    local e2 = evo.entity():set(f1, 21):set(f2, 22):build()
    local e3 = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e4 = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()

    do
        local q = evo.query():include(f1):build()
        assert(evo.batch_multi_remove(q, {}) == 0)
        assert(evo.batch_multi_remove(q, { f5 }) == 0)
    end

    do
        local q = evo.query():include(f3):build()

        assert(evo.batch_multi_remove(q, { f4 }) == 1)
        assert(evo.has_all(e4, f1, f2, f3) and not evo.has(e4, f4))
        assert(evo.get(e4, f1) == 41)
        assert(evo.get(e4, f2) == 42)
        assert(evo.get(e4, f3) == 43)
        assert(evo.get(e4, f4) == nil)

        for chunk in evo.execute(q) do
            assert(next(evo.select(chunk, f4)) == nil)
        end

        do
            local chunk, entities = evo.chunk(f1, f2, f3)
            assert(chunk and entities)
            assert(#entities == 2)
            assert(entities[1] == e3, entities[2] == e4)
            assert(evo.select(chunk, f2)[1] == 32 and evo.select(chunk, f3)[1] == 33)
            assert(evo.select(chunk, f2)[2] == 42 and evo.select(chunk, f3)[2] == 43)
        end

        do
            local chunk, entities = evo.chunk(f1, f2, f3, f4)
            assert(chunk)
            assert(next(evo.select(chunk, f4)) == nil)
            assert(#entities == 0)
        end
    end

    do
        local q = evo.query():include(f2):build()

        assert(evo.batch_multi_remove(q, { f1 }) == 3)
        assert(evo.has_all(e1, f1) and not evo.has_any(e1, f2, f3, f4))
        assert(evo.has_all(e2, f2) and not evo.has_any(e2, f1, f3, f4))
        assert(evo.has_all(e3, f2, f3) and not evo.has_any(e3, f1, f4))
        assert(evo.has_all(e4, f2, f3) and not evo.has_any(e4, f1, f4))

        for chunk in evo.execute(q) do
            assert(next(evo.select(chunk, f1)) == nil)
        end

        assert(evo.batch_multi_remove(q, { f2, f3 }) == 3)
        assert(evo.has_all(e1, f1) and not evo.has_any(e1, f2, f3, f4))
        assert(not evo.has_any(e2, f1, f2, f3, f4))
        assert(not evo.has_any(e3, f1, f2, f3, f4))
        assert(not evo.has_any(e4, f1, f2, f3, f4))

        for chunk in evo.execute(q) do
            assert(next(evo.select(chunk, f2)) == nil)
            assert(next(evo.select(chunk, f3)) == nil)
        end

        do
            local chunk, entities = evo.chunk(f1, f2)
            assert(chunk)
            assert(next(evo.select(chunk, f1)) == nil)
            assert(next(evo.select(chunk, f2)) == nil)
            assert(#entities == 0)
        end

        do
            local chunk, entities = evo.chunk(f1, f2, f3)
            assert(chunk)
            assert(next(evo.select(chunk, f1)) == nil)
            assert(next(evo.select(chunk, f2)) == nil)
            assert(next(evo.select(chunk, f3)) == nil)
            assert(#entities == 0)
        end
    end

    do
        local q = evo.query():include(f1):build()

        assert(evo.defer())
        assert(evo.batch_multi_remove(q, { f1 }) == 0)
        assert(evo.has(e1, f1))
        assert(evo.commit())
        assert(not evo.has(e1, f1))
    end
end

do
    local f1, f2 = evo.id(2)

    evo.set(f2, evo.TAG)

    local last_remove_entity = 0
    local last_remove_component = 0
    local sum_removed_components = 0

    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        assert(f == f1)
        last_remove_entity = e
        last_remove_component = c
        sum_removed_components = sum_removed_components + c
    end)

    evo.set(f2, evo.ON_REMOVE, function(e, f, c)
        assert(f == f2)
        last_remove_entity = e
        last_remove_component = c
    end)

    local _ = evo.spawn_with({ f1 }, { 11 })
    local e2 = evo.spawn_with({ f1, f2 }, { 21, 22 })
    assert(last_remove_entity == 0 and last_remove_component == 0)

    do
        last_remove_entity = 0
        last_remove_component = 0
        sum_removed_components = 0

        local q = evo.query():include(f1):build()

        assert(evo.batch_multi_remove(q, { f1, f1 }) == 2)
        assert(last_remove_entity == e2 and last_remove_component == 21)
        assert(sum_removed_components == 11 + 21)
    end

    do
        last_remove_entity = 0
        last_remove_component = 0
        sum_removed_components = 0

        local q = evo.query():include(f2):build()

        assert(evo.batch_multi_remove(q, { f2 }) == 1)
        assert(last_remove_entity == e2 and last_remove_component == nil)
        assert(sum_removed_components == 0)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)

    local e1 = evo.entity():set(f1, 11):build()
    local e2 = evo.entity():set(f1, 21):set(f2, 22):build()
    local e3 = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e4 = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()

    assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
    assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
    assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == 33)
    assert(evo.get(e4, f1) == 41 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == 43 and evo.get(e4, f4) == 44)

    do
        local q = evo.query():include(f1):build()
        assert(evo.batch_multi_assign(q, {}) == 0)
        assert(evo.batch_multi_assign(q, { f5 }) == 0)
    end

    do
        local q = evo.query():include(f3):build()

        assert(evo.batch_multi_assign(q, { f4 }, { 54 }) == 1)
        assert(evo.get(e3, f3) == 33 and evo.get(e3, f4) == nil)
        assert(evo.get(e4, f3) == 43 and evo.get(e4, f4) == 54)
    end

    do
        local q = evo.query():include(f2):build()

        assert(evo.batch_multi_assign(q, { f1 }, { 51, 52 }) == 3)
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 51 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 51 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == 33)
        assert(evo.get(e4, f1) == 51 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == 43 and evo.get(e4, f4) == 54)

        assert(evo.batch_multi_assign(q, { f2, f3 }, { 52, 53 }) == 3)
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 51 and evo.get(e2, f2) == 52 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 51 and evo.get(e3, f2) == 52 and evo.get(e3, f3) == 53)
        assert(evo.get(e4, f1) == 51 and evo.get(e4, f2) == 52 and evo.get(e4, f3) == 53 and evo.get(e4, f4) == 54)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(4)

    evo.set(f2, evo.DEFAULT, 41)
    evo.set(f3, evo.TAG)

    local e1 = evo.entity():set(f1, 11):build()
    local e2 = evo.entity():set(f1, 21):set(f2, 22):build()
    local e3 = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e4 = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()

    assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
    assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
    assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == nil)
    assert(evo.get(e4, f1) == 41 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil and evo.get(e4, f4) == 44)

    do
        local q = evo.query():include(f1):build()
        assert(evo.batch_multi_assign(q, {}) == 0)
        assert(evo.batch_multi_assign(q, { f5 }) == 0)
    end

    do
        local q = evo.query():include(f3):build()

        assert(evo.batch_multi_assign(q, { f4 }, { 54 }) == 1)
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == nil)
        assert(evo.get(e4, f1) == 41 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil and evo.get(e4, f4) == 54)
    end

    do
        local q = evo.query():include(f2):build()

        assert(evo.batch_multi_assign(q, { f1 }, { 51, 52 }) == 3)
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 51 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 51 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == nil)
        assert(evo.get(e4, f1) == 51 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil and evo.get(e4, f4) == 54)

        assert(evo.batch_multi_assign(q, { f2, f3 }, { 52, 53 }) == 3)
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 51 and evo.get(e2, f2) == 52 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 51 and evo.get(e3, f2) == 52 and evo.get(e3, f3) == nil)
        assert(evo.get(e4, f1) == 51 and evo.get(e4, f2) == 52 and evo.get(e4, f3) == nil and evo.get(e4, f4) == 54)
    end

    do
        local q = evo.query():include(f1):build()

        assert(evo.batch_multi_assign(q, { f1 }) == 4)
        assert(evo.get(e1, f1) == true and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == true and evo.get(e2, f2) == 52 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == true and evo.get(e3, f2) == 52 and evo.get(e3, f3) == nil)
        assert(evo.get(e4, f1) == true and evo.get(e4, f2) == 52 and evo.get(e4, f3) == nil and evo.get(e4, f4) == 54)

        assert(evo.batch_multi_assign(q, { f2 }) == 3)
        assert(evo.get(e1, f1) == true and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == true and evo.get(e2, f2) == 41 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == true and evo.get(e3, f2) == 41 and evo.get(e3, f3) == nil)
        assert(evo.get(e4, f1) == true and evo.get(e4, f2) == 41 and evo.get(e4, f3) == nil and evo.get(e4, f4) == 54)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f3, evo.TAG)

    local sum_entity = 0
    local last_assign_entity = 0
    local last_assign_new_component = 0
    local last_assign_old_component = 0

    evo.set(f1, evo.ON_ASSIGN, function(e, f, nc, oc)
        assert(f == f1)
        sum_entity = sum_entity + e
        last_assign_entity = e
        last_assign_new_component = nc
        last_assign_old_component = oc
    end)

    evo.set(f2, evo.ON_ASSIGN, function(e, f, nc, oc)
        assert(f == f2)
        sum_entity = sum_entity + e
        last_assign_entity = e
        last_assign_new_component = nc
        last_assign_old_component = oc
    end)

    evo.set(f3, evo.ON_ASSIGN, function(e, f, nc, oc)
        assert(f == f3)
        sum_entity = sum_entity + e
        last_assign_entity = e
        last_assign_new_component = nc
        last_assign_old_component = oc
    end)

    local e1 = evo.entity():set(f1, 11):build()
    local e2 = evo.entity():set(f1, 21):set(f2, 22):build()
    local e3 = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()

    do
        local q = evo.query():include(f3):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_new_component = 0
        last_assign_old_component = 0

        assert(evo.batch_multi_assign(q, { f2 }, {}) == 1)
        assert(sum_entity == e3)
        assert(last_assign_entity == e3)
        assert(last_assign_new_component == 42)
        assert(last_assign_old_component == 32)
    end

    do
        local q = evo.query():include(f1):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_new_component = 0
        last_assign_old_component = 0

        assert(evo.batch_multi_assign(q, { f1 }, { 51 }) == 3)
        assert(sum_entity == e1 + e2 + e3)
        assert(last_assign_entity == e3)
        assert(last_assign_new_component == 51)
        assert(last_assign_old_component == 31)
    end

    do
        local q = evo.query():include(f1):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_new_component = 0
        last_assign_old_component = 0

        assert(evo.batch_multi_assign(q, { f1, f1 }, { 61, 61 }) == 3)
        assert(sum_entity == e1 + e2 + e3 + e1 + e2 + e3)
        assert(last_assign_entity == e3)
        assert(last_assign_new_component == 61)
        assert(last_assign_old_component == 61)
    end

    do
        local q = evo.query():include(f1):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_new_component = 0
        last_assign_old_component = 0

        assert(evo.batch_multi_assign(q, { f3 }, { 63 }) == 1)
        assert(sum_entity == e3)
        assert(last_assign_entity == e3)
        assert(last_assign_new_component == nil)
        assert(last_assign_old_component == nil)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    local e1 = evo.entity():set(f1, 11):build()
    local e2 = evo.entity():set(f1, 21):set(f2, 22):build()
    local e3 = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e4 = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()

    do
        local q = evo.query():include(f1):build()

        assert(evo.batch_multi_insert(q, {}) == 0)
        assert(evo.batch_multi_insert(q, { f1 }) == 0)
    end

    do
        local q = evo.query():include(f3):build()

        assert(evo.batch_multi_insert(q, { f4 }) == 1)
        assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == 33 and evo.get(e3, f4) == true)
        assert(evo.get(e4, f1) == 41 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == 43 and evo.get(e4, f4) == 44)

        do
            local c123, c123_es = evo.chunk(f1, f2, f3)
            assert(c123 and #c123_es == 0)
            assert(#evo.select(c123, f1) == 0)
            assert(#evo.select(c123, f2) == 0)
            assert(#evo.select(c123, f3) == 0)

            local c1234, c1234_es = evo.chunk(f1, f2, f3, f4)
            assert(c1234 and #c1234_es == 2)
            assert(#evo.select(c1234, f1) == 2)
            assert(#evo.select(c1234, f2) == 2)
            assert(#evo.select(c1234, f3) == 2)
            assert(#evo.select(c1234, f4) == 2)
        end
    end

    do
        local q = evo.query():include(f1):build()

        assert(evo.batch_multi_insert(q, { f3, f4 }, { 53, 54 }) == 2)
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == 53 and evo.get(e1, f4) == 54)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == 53 and evo.get(e2, f4) == 54)
        assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == 33 and evo.get(e3, f4) == true)
        assert(evo.get(e4, f1) == 41 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == 43 and evo.get(e4, f4) == 44)

        do
            local c1, c1_es = evo.chunk(f1)
            assert(c1 and #c1_es == 0)
            assert(#evo.select(c1, f1) == 0)
        end

        do
            local c12, c12_es = evo.chunk(f1, f2)
            assert(c12 and #c12_es == 0)
            assert(#evo.select(c12, f1) == 0)
            assert(#evo.select(c12, f2) == 0)
        end

        do
            local c134, c134_es = evo.chunk(f1, f3, f4)
            assert(c134 and #c134_es == 1)
            assert(#evo.select(c134, f1) == 1)
            assert(#evo.select(c134, f3) == 1)
            assert(#evo.select(c134, f4) == 1)
        end

        do
            local c1234, c1234_es = evo.chunk(f1, f2, f3, f4)
            assert(c1234 and #c1234_es == 3)
            assert(#evo.select(c1234, f1) == 3)
            assert(#evo.select(c1234, f2) == 3)
            assert(#evo.select(c1234, f3) == 3)
            assert(#evo.select(c1234, f4) == 3)
        end
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f2, evo.DEFAULT, 41)
    evo.set(f3, evo.TAG)

    local e1 = evo.entity():set(f1, 11):build()
    local e2 = evo.entity():set(f1, 21):set(f2, 22):build()
    local e3 = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e4 = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()

    assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
    assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
    assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == nil)
    assert(evo.get(e4, f1) == 41 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil and evo.get(e4, f4) == 44)

    do
        local q = evo.query():include(f1):build()
        assert(evo.batch_multi_insert(q, {}) == 0)
    end

    do
        local q = evo.query():include(f1):build()
        assert(evo.batch_multi_insert(q, { f2 }) == 1)

        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == nil)
        assert(evo.get(e4, f1) == 41 and evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil and evo.get(e4, f4) == 44)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)

    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f3, evo.TAG)

    local sum_entity = 0
    local last_insert_entity = 0
    local last_insert_component = 0

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        assert(f == f1)
        sum_entity = sum_entity + e
        last_insert_entity = e
        last_insert_component = c
    end)

    evo.set(f2, evo.ON_INSERT, function(e, f, c)
        assert(f == f2)
        sum_entity = sum_entity + e
        last_insert_entity = e
        last_insert_component = c
    end)

    evo.set(f3, evo.ON_INSERT, function(e, f, c)
        assert(f == f3)
        sum_entity = sum_entity + e
        last_insert_entity = e
        last_insert_component = c
    end)

    evo.set(f4, evo.ON_INSERT, function(e, f, c)
        assert(f == f4)
        sum_entity = sum_entity + e
        last_insert_entity = e
        last_insert_component = c
    end)

    evo.set(f5, evo.ON_INSERT, function(e, f, c)
        assert(f == f5)
        sum_entity = sum_entity + e
        last_insert_entity = e
        last_insert_component = c
    end)

    local e1 = evo.entity():set(f1, 11):build()
    local e2 = evo.entity():set(f1, 21):set(f2, 22):build()
    local e3 = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()

    do
        local q = evo.query():include(f1):build()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        assert(evo.batch_multi_insert(q, { f2 }) == 1)
        assert(sum_entity == e1)
        assert(last_insert_entity == e1)
        assert(last_insert_component == 42)
        assert(evo.has(e1, f1) and evo.has(e1, f2) and not evo.has(e1, f3))
        assert(evo.has(e2, f1) and evo.has(e2, f2) and not evo.has(e2, f3))
        assert(evo.has(e3, f1) and evo.has(e3, f2) and evo.has(e3, f3))
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == 42 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == nil)
    end

    do
        local q = evo.query():include(f2):build()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        assert(evo.batch_multi_insert(q, { f3 }) == 2)
        assert(sum_entity == e1 + e2)
        assert(last_insert_entity == e1)
        assert(last_insert_component == nil)
        assert(evo.has(e1, f1) and evo.has(e1, f2) and evo.has(e1, f3))
        assert(evo.has(e2, f1) and evo.has(e2, f2) and evo.has(e2, f3))
        assert(evo.has(e3, f1) and evo.has(e3, f2) and evo.has(e3, f3))
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == 42 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == nil)
    end

    do
        local q = evo.query():include(f1, f2, f3):build()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        assert(evo.batch_multi_insert(q, { f3, f4, f5, f5 }, { 53, 54, 55, 65 }) == 3)
        assert(sum_entity == e1 + e2 + e3 + e1 + e2 + e3)
        assert(last_insert_entity == e1)
        assert(last_insert_component == 55)
        assert(evo.has_all(e1, f1, f2, f3, f4, f5))
        assert(evo.has_all(e2, f1, f2, f3, f4, f5))
        assert(evo.has_all(e3, f1, f2, f3, f4, f5))
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == 42 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == nil)
        assert(evo.get(e1, f4) == 54 and evo.get(e1, f5) == 55)
        assert(evo.get(e2, f4) == 54 and evo.get(e2, f5) == 55)
        assert(evo.get(e3, f4) == 54 and evo.get(e3, f5) == 55)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f2, evo.DEFAULT, 52)
    evo.set(f4, evo.TAG)

    local e1a = evo.entity():set(f1, 11):build()
    local e1b = evo.entity():set(f1, 11):build()

    local e2a = evo.entity():set(f1, 21):set(f2, 22):build()
    local e2b = evo.entity():set(f1, 21):set(f2, 22):build()

    local e3a = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e3b = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()

    local e4a = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()
    local e4b = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()

    do
        local q = evo.query():include(f1):build()
        assert(evo.batch_multi_set(q, {}) == 0)
    end

    do
        local q = evo.query():include(f3):exclude(f4):build()
        assert(evo.batch_multi_set(q, { f3 }) == 2)
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == nil and evo.get(e1a, f3) == nil)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == nil and evo.get(e1b, f3) == nil)
        assert(evo.get(e2a, f1) == 21 and evo.get(e2a, f2) == 22 and evo.get(e2a, f3) == nil)
        assert(evo.get(e2b, f1) == 21 and evo.get(e2b, f2) == 22 and evo.get(e2b, f3) == nil)
        assert(evo.get(e3a, f1) == 31 and evo.get(e3a, f2) == 32 and evo.get(e3a, f3) == true)
        assert(evo.get(e3b, f1) == 31 and evo.get(e3b, f2) == 32 and evo.get(e3b, f3) == true)
        assert(evo.get(e4a, f1) == 41 and evo.get(e4a, f2) == 42 and evo.get(e4a, f3) == 43 and evo.get(e4a, f4) == nil)
        assert(evo.get(e4b, f1) == 41 and evo.get(e4b, f2) == 42 and evo.get(e4b, f3) == 43 and evo.get(e4b, f4) == nil)
    end

    do
        local q = evo.query():include(f3):exclude(f4):build()
        assert(evo.batch_multi_set(q, { f3 }, { 43, 44 }) == 2)
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == nil and evo.get(e1a, f3) == nil)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == nil and evo.get(e1b, f3) == nil)
        assert(evo.get(e2a, f1) == 21 and evo.get(e2a, f2) == 22 and evo.get(e2a, f3) == nil)
        assert(evo.get(e2b, f1) == 21 and evo.get(e2b, f2) == 22 and evo.get(e2b, f3) == nil)
        assert(evo.get(e3a, f1) == 31 and evo.get(e3a, f2) == 32 and evo.get(e3a, f3) == 43)
        assert(evo.get(e3b, f1) == 31 and evo.get(e3b, f2) == 32 and evo.get(e3b, f3) == 43)
        assert(evo.get(e4a, f1) == 41 and evo.get(e4a, f2) == 42 and evo.get(e4a, f3) == 43 and evo.get(e4a, f4) == nil)
        assert(evo.get(e4b, f1) == 41 and evo.get(e4b, f2) == 42 and evo.get(e4b, f3) == 43 and evo.get(e4b, f4) == nil)
    end

    do
        local q = evo.query():include(f2):exclude(f3, f4):build()
        assert(evo.batch_multi_set(q, { f2 }, {}) == 2)
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == nil and evo.get(e1a, f3) == nil)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == nil and evo.get(e1b, f3) == nil)
        assert(evo.get(e2a, f1) == 21 and evo.get(e2a, f2) == 52 and evo.get(e2a, f3) == nil)
        assert(evo.get(e2b, f1) == 21 and evo.get(e2b, f2) == 52 and evo.get(e2b, f3) == nil)
        assert(evo.get(e3a, f1) == 31 and evo.get(e3a, f2) == 32 and evo.get(e3a, f3) == 43)
        assert(evo.get(e3b, f1) == 31 and evo.get(e3b, f2) == 32 and evo.get(e3b, f3) == 43)
        assert(evo.get(e4a, f1) == 41 and evo.get(e4a, f2) == 42 and evo.get(e4a, f3) == 43 and evo.get(e4a, f4) == nil)
        assert(evo.get(e4b, f1) == 41 and evo.get(e4b, f2) == 42 and evo.get(e4b, f3) == 43 and evo.get(e4b, f4) == nil)
    end

    do
        local q = evo.query():include(f2):exclude(f3, f4):build()
        assert(evo.batch_multi_set(q, { f2 }, { 62, 63 }) == 2)
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == nil and evo.get(e1a, f3) == nil)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == nil and evo.get(e1b, f3) == nil)
        assert(evo.get(e2a, f1) == 21 and evo.get(e2a, f2) == 62 and evo.get(e2a, f3) == nil)
        assert(evo.get(e2b, f1) == 21 and evo.get(e2b, f2) == 62 and evo.get(e2b, f3) == nil)
        assert(evo.get(e3a, f1) == 31 and evo.get(e3a, f2) == 32 and evo.get(e3a, f3) == 43)
        assert(evo.get(e3b, f1) == 31 and evo.get(e3b, f2) == 32 and evo.get(e3b, f3) == 43)
        assert(evo.get(e4a, f1) == 41 and evo.get(e4a, f2) == 42 and evo.get(e4a, f3) == 43 and evo.get(e4a, f4) == nil)
        assert(evo.get(e4b, f1) == 41 and evo.get(e4b, f2) == 42 and evo.get(e4b, f3) == 43 and evo.get(e4b, f4) == nil)
    end
end

do
    local fc = evo.id()
    evo.set(fc, evo.TAG)

    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f2, evo.DEFAULT, 52)
    evo.set(f4, evo.TAG)

    evo.set(f1, fc)
    evo.set(f2, fc)
    evo.set(f3, fc)
    evo.set(f4, fc)

    local sum_entity = 0
    local last_assign_entity = 0
    local last_assign_component = 0

    do
        local q = evo.query():include(fc):build()
        evo.batch_set(q, evo.ON_ASSIGN, function(e, f, c)
            assert(f == f1 or f == f2 or f == f3 or f == f4)
            sum_entity = sum_entity + e
            last_assign_entity = e
            last_assign_component = c
        end)
    end

    local e2a = evo.entity():set(f1, 21):set(f2, 22):build()
    local e2b = evo.entity():set(f1, 21):set(f2, 22):build()

    local e3a = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e3b = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()

    local e4a = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()
    local e4b = evo.entity():set(f1, 41):set(f2, 42):set(f3, 43):set(f4, 44):build()

    do
        local q = evo.query():include(f1):build()
        assert(evo.batch_multi_set(q, {}) == 0)
    end

    do
        local q = evo.query():include(f2):exclude(f3, f4):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_multi_set(q, { f2 }) == 2)
        assert(sum_entity == e2a + e2b)
        assert(last_assign_entity == e2b)
        assert(last_assign_component == 52)
        assert(evo.get(e2a, f2) == 52 and evo.get(e2b, f2) == 52)

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_multi_set(q, { f2, f2 }) == 2)
        assert(sum_entity == e2a + e2b + e2a + e2b)
        assert(last_assign_entity == e2b)
        assert(last_assign_component == 52)
        assert(evo.get(e2a, f2) == 52 and evo.get(e2b, f2) == 52)
    end

    do
        local q = evo.query():include(f2):exclude(f3, f4):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_multi_set(q, { f2 }, { 62, 63 }) == 2)
        assert(sum_entity == e2a + e2b)
        assert(last_assign_entity == e2b)
        assert(last_assign_component == 62)
        assert(evo.get(e2a, f2) == 62 and evo.get(e2b, f2) == 62)

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_multi_set(q, { f2, f2 }, { 62, 63 }) == 2)
        assert(sum_entity == e2a + e2b + e2a + e2b)
        assert(last_assign_entity == e2b)
        assert(last_assign_component == 63)
        assert(evo.get(e2a, f2) == 63 and evo.get(e2b, f2) == 63)
    end

    do
        local q = evo.query():include(f3):exclude(f4):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_multi_set(q, { f3 }) == 2)
        assert(sum_entity == e3a + e3b)
        assert(last_assign_entity == e3b)
        assert(last_assign_component == true)
        assert(evo.get(e3a, f3) == true and evo.get(e3b, f3) == true)
    end

    do
        local q = evo.query():include(f4):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_multi_set(q, { f4 }, { 62, 63 }) == 2)
        assert(sum_entity == e4a + e4b)
        assert(last_assign_entity == e4b)
        assert(last_assign_component == nil)
        assert(evo.has(e4a, f4) and evo.has(e4b, f4))
        assert(evo.get(e4a, f4) == nil and evo.get(e4b, f4) == nil)

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_multi_set(q, { f4, f4 }, { 62, 63 }) == 2)
        assert(sum_entity == e4a + e4b + e4a + e4b)
        assert(last_assign_entity == e4b)
        assert(last_assign_component == nil)
        assert(evo.get(e2a, f4) == nil and evo.get(e2b, f4) == nil)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f2, evo.DEFAULT, 52)
    evo.set(f4, evo.TAG)

    local e1a = evo.entity():set(f1, 11):build()
    local e1b = evo.entity():set(f1, 11):build()

    local e2a = evo.entity():set(f1, 21):set(f2, 22):build()
    local e2b = evo.entity():set(f1, 21):set(f2, 22):build()

    local e3a = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e3b = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()

    do
        local q = evo.query():include(f2):exclude(f3, f4):build()
        assert(evo.batch_multi_set(q, { f3 }) == 2)
        assert(evo.get(e2a, f1) == 21 and evo.get(e2a, f2) == 22 and evo.get(e2a, f3) == true)
        assert(evo.get(e2b, f1) == 21 and evo.get(e2b, f2) == 22 and evo.get(e2b, f3) == true)
        assert(evo.get(e3a, f1) == 31 and evo.get(e3a, f2) == 32 and evo.get(e3a, f3) == 33)
        assert(evo.get(e3b, f1) == 31 and evo.get(e3b, f2) == 32 and evo.get(e3b, f3) == 33)
        do
            local c12, c12_es = evo.chunk(f1, f2)
            assert(c12 and #c12_es == 0)
            assert(#evo.select(c12, f1) == 0)
            assert(#evo.select(c12, f2) == 0)

            local c123, c123_es = evo.chunk(f1, f2, f3)
            assert(c123 and #c123_es == 4)
            assert(#evo.select(c123, f1) == 4)
            assert(#evo.select(c123, f2) == 4)
            assert(#evo.select(c123, f3) == 4)
        end
    end

    do
        local q = evo.query():include(f2, f3):exclude(f4):build()
        assert(evo.batch_multi_set(q, { f2, f3, f4, f4 }, { 62, 63, 64, 65 }) == 4)
        assert(evo.has_all(e2a, f2, f3, f4) and evo.has_all(e2b, f2, f3, f4))
        assert(evo.get(e2a, f1) == 21 and evo.get(e2a, f2) == 62 and evo.get(e2a, f3) == 63 and evo.get(e2a, f4) == nil)
        assert(evo.get(e2b, f1) == 21 and evo.get(e2b, f2) == 62 and evo.get(e2b, f3) == 63 and evo.get(e2b, f4) == nil)
        assert(evo.get(e3a, f1) == 31 and evo.get(e3a, f2) == 62 and evo.get(e3a, f3) == 63 and evo.get(e3a, f4) == nil)
        assert(evo.get(e3b, f1) == 31 and evo.get(e3b, f2) == 62 and evo.get(e3b, f3) == 63 and evo.get(e3b, f4) == nil)
    end

    do
        local q = evo.query():include(f1):exclude(f2, f3, f4):build()
        assert(evo.batch_multi_set(q, { f2, f1 }, { nil, 71 }) == 2)
        assert(evo.get(e1a, f1) == 71 and evo.get(e1a, f2) == 52)
        assert(evo.get(e1b, f1) == 71 and evo.get(e1b, f2) == 52)
        do
            local c1, c1_es = evo.chunk(f1)
            assert(c1 and #c1_es == 0)
            assert(#evo.select(c1, f1) == 0)

            local c12, c12_es = evo.chunk(f1, f2)
            assert(c12 and #c12_es == 2)
            assert(#evo.select(c12, f1) == 2)
            assert(#evo.select(c12, f2) == 2)
        end
    end
end

do
    local fc = evo.id()
    evo.set(fc, evo.TAG)

    local f0, f1, f2, f3, f4 = evo.id(5)

    evo.set(f2, evo.DEFAULT, 52)
    evo.set(f1, evo.TAG)

    evo.set(f0, fc)
    evo.set(f1, fc)
    evo.set(f2, fc)
    evo.set(f3, fc)
    evo.set(f4, fc)

    local sum_entity = 0
    local last_assign_entity = 0
    local last_assign_component = 0
    local last_insert_entity = 0
    local last_insert_component = 0

    do
        local q = evo.query():include(fc):build()
        evo.batch_set(q, evo.ON_ASSIGN, function(e, f, c)
            assert(f == f0 or f == f1 or f == f2 or f == f3 or f == f4)
            sum_entity = sum_entity + e
            last_assign_entity = e
            last_assign_component = c
        end)
        evo.batch_set(q, evo.ON_INSERT, function(e, f, c)
            assert(f == f0 or f == f1 or f == f2 or f == f3 or f == f4)
            sum_entity = sum_entity + e
            last_insert_entity = e
            last_insert_component = c
        end)
    end

    local e0a = evo.entity():set(f0, 0):build()
    local e0b = evo.entity():set(f0, 0):build()

    local e3a = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()
    local e3b = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()

    do
        local q = evo.query():include(f0):build()

        sum_entity = 0
        last_assign_entity, last_assign_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0

        assert(evo.batch_multi_set(q, { f1, f2 }, { 51 }) == 2)
        assert(sum_entity == e0a + e0b + e0a + e0b)
        assert(last_assign_entity == 0)
        assert(last_assign_component == 0)
        assert(last_insert_entity == e0b)
        assert(last_insert_component == 52)
        assert(evo.get(e0a, f0) == 0 and evo.get(e0a, f1) == nil and evo.get(e0a, f2) == 52 and evo.get(e0a, f3) == nil)
        assert(evo.get(e0b, f0) == 0 and evo.get(e0b, f1) == nil and evo.get(e0b, f2) == 52 and evo.get(e0b, f3) == nil)

        sum_entity = 0
        last_assign_entity, last_assign_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0

        assert(evo.batch_multi_set(q, { f1, f3, f2 }, { 61 }) == 2)
        assert(sum_entity == e0a + e0b + e0a + e0b + e0a + e0b)
        assert(last_assign_entity == e0b)
        assert(last_assign_component == 52)
        assert(last_insert_entity == e0b)
        assert(last_insert_component == true)
        assert(evo.get(e0a, f0) == 0 and evo.get(e0a, f1) == nil and evo.get(e0a, f2) == 52 and evo.get(e0a, f3) == true)
        assert(evo.get(e0b, f0) == 0 and evo.get(e0b, f1) == nil and evo.get(e0b, f2) == 52 and evo.get(e0b, f3) == true)
    end

    do
        local q = evo.query():include(f3):exclude(f0, f4):build()

        sum_entity = 0
        last_assign_entity, last_assign_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0

        assert(evo.batch_multi_set(q, { f3, f4 }, { 53, 54 }) == 2)
        assert(sum_entity == e3a + e3b + e3a + e3b)
        assert(last_assign_entity == e3b)
        assert(last_assign_component == 53)
        assert(last_insert_entity == e3b)
        assert(last_insert_component == 54)
        assert(evo.get(e3a, f1) == nil and evo.get(e3a, f2) == 32 and evo.get(e3a, f3) == 53 and evo.get(e3a, f4) == 54)
        assert(evo.get(e3b, f1) == nil and evo.get(e3b, f2) == 32 and evo.get(e3b, f3) == 53 and evo.get(e3b, f4) == 54)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    local e1 = evo.entity():set(f1, 11):build()
    local e2 = evo.entity():set(f1, 21):set(f2, 22):build()
    local e3 = evo.entity():set(f1, 31):set(f2, 32):set(f3, 33):build()

    assert(evo.defer())
    do
        local q = evo.query():include(f1):build()
        do
            local n, d = evo.batch_multi_insert(q, { f2 }, { 42 })
            assert(n == 0 and d == true)
        end
        do
            local n, d = evo.batch_multi_assign(q, { f3 }, { 43 })
            assert(n == 0 and d == true)
        end
        do
            local n, d = evo.batch_multi_remove(q, { f1 })
            assert(n == 0 and d == true)
        end
        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 31 and evo.get(e3, f2) == 32 and evo.get(e3, f3) == 33)
    end
    assert(evo.commit())
    do
        assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == 42 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == nil and evo.get(e2, f2) == 22 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == nil and evo.get(e3, f2) == 32 and evo.get(e3, f3) == 43)
    end
    assert(evo.defer())
    do
        local q = evo.query():include(f2):build()
        do
            local n, d = evo.batch_multi_set(q, { f3, f4 }, { 53, 54 })
            assert(n == 0 and d == true)
        end
    end
    assert(evo.commit())
    do
        assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == 42 and evo.get(e1, f3) == 53 and evo.get(e1, f4) == 54)
        assert(evo.get(e2, f1) == nil and evo.get(e2, f2) == 22 and evo.get(e2, f3) == 53 and evo.get(e2, f4) == 54)
        assert(evo.get(e3, f1) == nil and evo.get(e3, f2) == 32 and evo.get(e3, f3) == 53 and evo.get(e3, f4) == 54)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)
    local e = evo.entity():set(f1, 11):set(f2, 22):set(f3, 33):set(f4, 44):set(f5, 55):build()

    do
        local c1 = evo.get(e, f1)
        assert(c1 == 11)
    end
    do
        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 11 and c2 == 22)
    end
    do
        local c2, c1 = evo.get(e, f2, f1)
        assert(c1 == 11 and c2 == 22)
    end
    do
        local c1, c2, c3 = evo.get(e, f1, f2, f3)
        assert(c1 == 11 and c2 == 22 and c3 == 33)
    end
    do
        local c3, c2, c1 = evo.get(e, f3, f2, f1)
        assert(c1 == 11 and c2 == 22 and c3 == 33)
    end
    do
        local c1, c2, c3, c4 = evo.get(e, f1, f2, f3, f4)
        assert(c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44)
    end
    do
        local c1, c2, c3, c4, c5 = evo.get(e, f1, f2, f3, f4, f5)
        assert(c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44 and c5 == 55)
    end
    do
        local c5, c4, c3, c2, c1 = evo.get(e, f5, f4, f3, f2, f1)
        assert(c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44 and c5 == 55)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.DEFAULT, 42)

    local e1a = evo.entity():set(f1, 11):build()
    local e1b = evo.entity():set(f1, 11):build()

    local e2a = evo.entity():set(f1, 11):set(f2, 22):build()
    local e2b = evo.entity():set(f1, 11):set(f2, 22):build()

    local q = evo.query():include(f1):build()

    assert(evo.batch_insert(q, f2) == 2)
    assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42)
    assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42)
    assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 22)
    assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 22)

    assert(evo.batch_assign(q, f2) == 4)
    assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42)
    assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42)
    assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 42)
    assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 42)

    assert(evo.batch_assign(q, f1) == 4)
    assert(evo.get(e1a, f1) == true and evo.get(e1a, f2) == 42)
    assert(evo.get(e1b, f1) == true and evo.get(e1b, f2) == 42)
    assert(evo.get(e2a, f1) == true and evo.get(e2a, f2) == 42)
    assert(evo.get(e2b, f1) == true and evo.get(e2b, f2) == 42)

    assert(evo.batch_insert(q, f3) == 4)
    assert(evo.get(e1a, f1) == true and evo.get(e1a, f2) == 42 and evo.get(e1a, f3) == true)
    assert(evo.get(e1b, f1) == true and evo.get(e1b, f2) == 42 and evo.get(e1b, f3) == true)
    assert(evo.get(e2a, f1) == true and evo.get(e2a, f2) == 42 and evo.get(e2a, f3) == true)
    assert(evo.get(e2b, f1) == true and evo.get(e2b, f2) == 42 and evo.get(e2b, f3) == true)
end

do
    local fc = evo.id()
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f3, evo.TAG)

    evo.set(f1, fc)
    evo.set(f2, fc)
    evo.set(f3, fc)
    evo.set(f4, fc)

    local sum_entity = 0
    local last_assign_entity = 0
    local last_assign_component = 0
    local last_insert_entity = 0
    local last_insert_component = 0

    do
        local q = evo.query():include(fc):build()
        evo.batch_insert(q, evo.ON_ASSIGN, function(e, f, c)
            assert(f == f1 or f == f2 or f == f3 or f == f4)
            sum_entity = sum_entity + e
            last_assign_entity = e
            last_assign_component = c
        end)
        evo.batch_insert(q, evo.ON_INSERT, function(e, f, c)
            assert(f == f1 or f == f2 or f == f3 or f == f4)
            sum_entity = sum_entity + e
            last_insert_entity = e
            last_insert_component = c
        end)
    end

    local e1a = evo.entity():set(f1, 11):build()
    local e1b = evo.entity():set(f1, 11):build()

    local e2a = evo.entity():set(f1, 11):set(f2, 22):build()
    local e2b = evo.entity():set(f1, 11):set(f2, 22):build()

    do
        local q = evo.query():include(f1):build()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        assert(evo.batch_insert(q, f2) == 2)
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42)
        assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 22)
        assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 22)

        assert(sum_entity == e1a + e1b)
        assert(last_insert_entity == e1b)
        assert(last_insert_component == 42)
    end

    do
        local q = evo.query():include(f2):build()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        assert(evo.batch_insert(q, f3) == 4)
        assert(evo.has_all(e1a, f1, f2, f3) and evo.has_all(e1b, f1, f2, f3))
        assert(evo.has_all(e2a, f1, f2, f3) and evo.has_all(e2b, f1, f2, f3))
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42 and evo.get(e1a, f3) == nil)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42 and evo.get(e1b, f3) == nil)
        assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 22 and evo.get(e2a, f3) == nil)
        assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 22 and evo.get(e2b, f3) == nil)
    end

    do
        local q = evo.query():include(f2):build()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        assert(evo.batch_insert(q, f4) == 4)
        assert(evo.has_all(e1a, f1, f2, f3, f4) and evo.has_all(e1b, f1, f2, f3, f4))
        assert(evo.has_all(e2a, f1, f2, f3, f4) and evo.has_all(e2b, f1, f2, f3, f4))
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42 and evo.get(e1a, f3) == nil and evo.get(e1a, f4) == true)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42 and evo.get(e1b, f3) == nil and evo.get(e1b, f4) == true)
        assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 22 and evo.get(e2a, f3) == nil and evo.get(e2a, f4) == true)
        assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 22 and evo.get(e2b, f3) == nil and evo.get(e2b, f4) == true)
    end

    do
        local q = evo.query():include(f3):build()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_assign(q, f2) == 4)
        assert(sum_entity == e1a + e1b + e2a + e2b)
        assert(last_assign_entity == e1b)
        assert(last_assign_component == 42)

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        assert(evo.batch_assign(q, f1) == 4)
        assert(sum_entity == e1a + e1b + e2a + e2b)
        assert(last_assign_entity == e1b)
        assert(last_assign_component == true)
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local e = evo.id()
        assert(evo.defer())
        do
            local s, d = evo.multi_set(e, { f1 }, { 11 })
            assert(not s and d == true)
            assert(not evo.has_any(e, f1))
        end
        assert(evo.commit())
        do
            assert(evo.has_all(e, f1))
            assert(evo.get(e, f1) == 11)
        end
        assert(evo.defer())
        do
            local s, d = evo.multi_set(e, { f1, f2 }, { 21, 22 })
            assert(not s and d == true)
            assert(not evo.has_any(e, f2))
        end
        assert(evo.commit())
        do
            assert(evo.has_all(e, f1, f2))
            assert(evo.get(e, f1) == 21 and evo.get(e, f2) == 22)
        end
    end
end

do
    local f1, f2 = evo.id(2)

    assert(evo.defer())
    local c2, c12 = evo.chunk(f2), evo.chunk(f2, f1)
    local e2 = evo.spawn_at(c2, { f2 }, { 22 })
    local e12 = evo.spawn_at(c12, { f1, f2 }, { 11, 12 })
    assert(evo.is_alive(e2) and evo.is_empty(e2))
    assert(evo.is_alive(e12) and evo.is_empty(e12))
    assert(evo.commit())
    assert(evo.is_alive(e2) and not evo.is_empty(e2))
    assert(evo.is_alive(e12) and not evo.is_empty(e12))
    assert(evo.has(e2, f2) and evo.get(e2, f2) == 22)
    assert(evo.has(e12, f1) and evo.get(e12, f1) == 11)
    assert(evo.has(e12, f2) and evo.get(e12, f2) == 12)
end

do
    local id = evo.pack(7, 3)
    local index, version = evo.unpack(id)
    assert(index == 7 and version == 3)
end

do
    local id = evo.pack(0xBCDEF, 0xFEDCB)
    local index, version = evo.unpack(id)
    assert(index == 0xBCDEF and version == 0xFEDCB)
end

do
    local id = evo.pack(0xFFFFF, 0xFFFFF)
    local index, version = evo.unpack(id)
    assert(index == 0xFFFFF and version == 0xFFFFF)
end

do
    local f1, f2 = evo.id(2)

    local e = evo.id()

    assert(evo.set(e, f1, 11))
    assert(evo.set(e, f1))

    assert(evo.set(e, f2, 22))
    assert(evo.assign(e, f2))

    assert(evo.get(e, f1) == true and evo.get(e, f2) == true)

    assert(evo.destroy(e))
    assert(not evo.has(e, f1) and not evo.has(e, f2))
    assert(not evo.has_all(e, f1, f2) and not evo.has_any(e, f1, f2))

    assert(not evo.set(e, f1, 11))
    assert(not evo.assign(e, f1, 11))
    assert(not evo.insert(e, f1, 11))
    assert(evo.remove(e, f1))
    assert(evo.clear(e))

    assert(not evo.multi_set(e, { f1 }, { 11 }))
    assert(not evo.multi_assign(e, { f1 }, { 11 }))
    assert(not evo.multi_insert(e, { f1 }, { 11 }))
    assert(evo.multi_remove(e, { f1 }))
end

do
    local f1 = evo.id(2)

    local e = evo.id()
    assert(evo.clear(e) and evo.clear(e))
    assert(evo.set(e, f1, 11))
    assert(evo.clear(e) and evo.clear(e))
    assert(evo.destroy(e) and evo.destroy(e))
    assert(evo.clear(e))
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f3, evo.TAG)

    local last_assign_f2_new_component = 0
    local last_assign_f2_old_component = 0

    local last_insert_f2_new_component = 0
    local last_insert_f3_new_component = 0

    evo.set(f2, evo.ON_ASSIGN, function(_, f, nc, oc)
        assert(f == f2)
        last_assign_f2_new_component = nc
        last_assign_f2_old_component = oc
    end)

    evo.set(f2, evo.ON_INSERT, function(_, f, nc)
        assert(f == f2)
        last_insert_f2_new_component = nc
    end)

    evo.set(f3, evo.ON_INSERT, function(_, f, nc)
        assert(f == f3)
        last_insert_f3_new_component = nc
    end)

    do
        local e = evo.id()

        assert(evo.multi_set(e, { f1, f2, f3 }, { 11, 22 }))
        assert(evo.has_all(e, f1, f2, f3))
        assert(evo.get(e, f1) == 11 and evo.get(e, f2) == 22 and evo.get(e, f3) == nil)
        assert(last_assign_f2_new_component == 0 and last_assign_f2_old_component == 0)

        assert(evo.multi_set(e, { f1, f2, f3, f3 }, {}))
        assert(evo.has_all(e, f1, f2, f3))
        assert(evo.get(e, f1) == true and evo.get(e, f2) == 42 and evo.get(e, f3) == nil)
        assert(last_assign_f2_new_component == 42 and last_assign_f2_old_component == 22)
        assert(last_insert_f3_new_component == nil)

        assert(evo.multi_assign(e, { f1, f2, f3 }, { 11, 22, 33 }))
        assert(evo.get(e, f1) == 11 and evo.get(e, f2) == 22 and evo.get(e, f3) == nil)
        assert(evo.multi_assign(e, { f1, f2, f3 }, {}))
        assert(evo.get(e, f1) == true and evo.get(e, f2) == 42 and evo.get(e, f3) == nil)
    end

    do
        local e = evo.id()

        assert(evo.multi_set(e, { f1, f1, f3, f3 }, {}))
        assert(evo.has_all(e, f1, f3))
        assert(evo.get(e, f1) == true and evo.get(e, f3) == nil)
    end

    do
        local e = evo.id()

        assert(evo.multi_set(e, { f1, f1, f2, f2, f3 }, {}))
        assert(evo.has_all(e, f1, f2, f3))
        assert(evo.get(e, f1) == true and evo.get(e, f2) == 42 and evo.get(e, f3) == nil)
    end

    do
        local e = evo.id()

        last_insert_f2_new_component = 0

        assert(evo.multi_insert(e, { f2, f2 }, { nil, 22 }))
        assert(evo.get(e, f2) == 42)
        assert(last_insert_f2_new_component == 42)
    end
end

do
    local f1, f2 = evo.id(2)

    evo.set(f1, evo.DEFAULT, 41)

    do
        local e = evo.id()

        assert(evo.multi_insert(e, { f1, f2 }))
        assert(evo.get(e, f1) == 41 and evo.get(e, f2) == true)
        assert(evo.multi_assign(e, { f1, f2 }, { 11, 22 }))
        assert(evo.get(e, f1) == 11 and evo.get(e, f2) == 22)
        assert(evo.multi_assign(e, { f1, f2 }))
        assert(evo.get(e, f1) == 41 and evo.get(e, f2) == true)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)
    local e = evo.spawn_with({ f1, f2, f3, f4, f5 }, { 1, 2, 3, 4, 5 })

    local c, es = evo.chunk(f1, f2, f3, f4, f5)
    assert(c and es and #es == 1 and es[1] == e)

    do
        local c1, c2 = evo.select(c, f1, f2)
        assert(c1 and #c1 == 1 and c1[1] == 1)
        assert(c2 and #c2 == 1 and c2[1] == 2)
    end

    do
        local c1, c2, c3 = evo.select(c, f1, f2, f3)
        assert(c1 and #c1 == 1 and c1[1] == 1)
        assert(c2 and #c2 == 1 and c2[1] == 2)
        assert(c3 and #c3 == 1 and c3[1] == 3)
    end

    do
        local c1, c2, c3, c4 = evo.select(c, f1, f2, f3, f4)
        assert(c1 and #c1 == 1 and c1[1] == 1)
        assert(c2 and #c2 == 1 and c2[1] == 2)
        assert(c3 and #c3 == 1 and c3[1] == 3)
        assert(c4 and #c4 == 1 and c4[1] == 4)
    end

    do
        local c1, c2, c3, c4, c5 = evo.select(c, f1, f2, f3, f4, f5)
        assert(c1 and #c1 == 1 and c1[1] == 1)
        assert(c2 and #c2 == 1 and c2[1] == 2)
        assert(c3 and #c3 == 1 and c3[1] == 3)
        assert(c4 and #c4 == 1 and c4[1] == 4)
        assert(c5 and #c5 == 1 and c5[1] == 5)
    end
end

do
    local f0, f1, f2, f3, f4, f5 = evo.id(6)

    evo.set(f0, evo.CONSTRUCT, function()
        return 42
    end)

    evo.set(f1, evo.CONSTRUCT, function(a1)
        return a1
    end)

    evo.set(f2, evo.CONSTRUCT, function(a1, a2)
        return a1 + a2
    end)

    evo.set(f3, evo.CONSTRUCT, function(a1, a2, a3)
        return a1 + a2 + a3
    end)

    evo.set(f4, evo.CONSTRUCT, function(a1, a2, a3, a4)
        return a1 + a2 + a3 + a4
    end)

    evo.set(f5, evo.CONSTRUCT, function(a1, a2, a3, a4, a5)
        return a1 + a2 + a3 + a4 + a5
    end)

    do
        local e1 = evo.id()
        evo.set(e1, f0)
        evo.set(e1, f1, 1)
        evo.set(e1, f2, 1, 2)
        evo.set(e1, f3, 1, 2, 3)
        evo.set(e1, f4, 1, 2, 3, 4)
        evo.set(e1, f5, 1, 2, 3, 4, 5)
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e1, f5) == 1 + 2 + 3 + 4 + 5)
    end
    do
        local e1 = evo.id()
        evo.insert(e1, f0)
        evo.insert(e1, f1, 1)
        evo.insert(e1, f2, 1, 2)
        evo.insert(e1, f3, 1, 2, 3)
        evo.insert(e1, f4, 1, 2, 3, 4)
        evo.insert(e1, f5, 1, 2, 3, 4, 5)
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e1, f5) == 1 + 2 + 3 + 4 + 5)
    end
    do
        local e1 = evo.id()
        evo.multi_insert(e1, { f0, f1, f2, f3, f4, f5 })
        evo.assign(e1, f0)
        evo.assign(e1, f1, 1)
        evo.assign(e1, f2, 1, 2)
        evo.assign(e1, f3, 1, 2, 3)
        evo.assign(e1, f4, 1, 2, 3, 4)
        evo.assign(e1, f5, 1, 2, 3, 4, 5)
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e1, f5) == 1 + 2 + 3 + 4 + 5)
    end
    do
        local e1, e2, e3, e4, e5 = evo.id(5)
        evo.multi_insert(e1, { f1, f2, f3, f4, f5 })
        evo.multi_insert(e2, { f1, f2, f3, f4, f5 })
        evo.multi_insert(e3, { f1, f2, f3, f4, f5 })
        evo.multi_insert(e4, { f1, f2, f3, f4, f5 })
        evo.multi_insert(e5, { f1, f2, f3, f4, f5 })
        evo.remove(e1, f0, f1)
        evo.remove(e2, f0, f1, f2)
        evo.remove(e3, f0, f1, f2, f3)
        evo.remove(e4, f0, f1, f2, f3, f4)
        evo.remove(e5, f0, f1, f2, f3, f4, f5)
        assert(
            evo.get(e1, f1) == nil and
            evo.get(e1, f2) == true and
            evo.get(e1, f3) == true and
            evo.get(e1, f4) == true and
            evo.get(e1, f5) == true)
        assert(
            evo.get(e2, f1) == nil and
            evo.get(e2, f2) == nil and
            evo.get(e2, f3) == true and
            evo.get(e2, f4) == true and
            evo.get(e2, f5) == true)
        assert(
            evo.get(e3, f1) == nil and
            evo.get(e3, f2) == nil and
            evo.get(e3, f3) == nil and
            evo.get(e3, f4) == true and
            evo.get(e3, f5) == true)
        assert(
            evo.get(e4, f1) == nil and
            evo.get(e4, f2) == nil and
            evo.get(e4, f3) == nil and
            evo.get(e4, f4) == nil and
            evo.get(e4, f5) == true)
    end
    do
        local e1, e2 = evo.id(2)
        assert(evo.defer())
        evo.set(e1, f0)
        evo.set(e1, f1, 1)
        evo.set(e1, f2, 1, 2)
        evo.set(e1, f3, 1, 2, 3)
        evo.set(e1, f4, 1, 2, 3, 4)
        evo.set(e1, f5, 1, 2, 3, 4, 5)
        evo.set(e2, f0)
        evo.set(e2, f1, 1)
        evo.set(e2, f2, 1, 2)
        evo.set(e2, f3, 1, 2, 3)
        evo.set(e2, f4, 1, 2, 3, 4)
        evo.set(e2, f5, 1, 2, 3, 4, 5)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e1, f5) == 1 + 2 + 3 + 4 + 5)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e2, f5) == 1 + 2 + 3 + 4 + 5)
    end
    do
        local e1, e2 = evo.id(2)
        assert(evo.defer())
        evo.insert(e1, f0)
        evo.insert(e1, f1, 1)
        evo.insert(e1, f2, 1, 2)
        evo.insert(e1, f3, 1, 2, 3)
        evo.insert(e1, f4, 1, 2, 3, 4)
        evo.insert(e1, f5, 1, 2, 3, 4, 5)
        evo.insert(e2, f0)
        evo.insert(e2, f1, 1)
        evo.insert(e2, f2, 1, 2)
        evo.insert(e2, f3, 1, 2, 3)
        evo.insert(e2, f4, 1, 2, 3, 4)
        evo.insert(e2, f5, 1, 2, 3, 4, 5)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e1, f5) == 1 + 2 + 3 + 4 + 5)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e2, f5) == 1 + 2 + 3 + 4 + 5)
    end
    do
        local e1, e2 = evo.id(2)
        evo.multi_insert(e1, { f0, f1, f2, f3, f4, f5 })
        evo.multi_insert(e2, { f0, f1, f2, f3, f4, f5 })
        assert(evo.defer())
        evo.assign(e1, f0)
        evo.assign(e1, f1, 1)
        evo.assign(e1, f2, 1, 2)
        evo.assign(e1, f3, 1, 2, 3)
        evo.assign(e1, f4, 1, 2, 3, 4)
        evo.assign(e1, f5, 1, 2, 3, 4, 5)
        evo.assign(e2, f0)
        evo.assign(e2, f1, 1)
        evo.assign(e2, f2, 1, 2)
        evo.assign(e2, f3, 1, 2, 3)
        evo.assign(e2, f4, 1, 2, 3, 4)
        evo.assign(e2, f5, 1, 2, 3, 4, 5)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e1, f5) == 1 + 2 + 3 + 4 + 5)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e2, f5) == 1 + 2 + 3 + 4 + 5)
    end
    do
        local e1, e2, e3, e4, e5 = evo.id(5)
        evo.multi_insert(e1, { f1, f2, f3, f4, f5 })
        evo.multi_insert(e2, { f1, f2, f3, f4, f5 })
        evo.multi_insert(e3, { f1, f2, f3, f4, f5 })
        evo.multi_insert(e4, { f1, f2, f3, f4, f5 })
        evo.multi_insert(e5, { f1, f2, f3, f4, f5 })
        assert(evo.defer())
        evo.remove(e1, f1)
        evo.remove(e2, f1, f2)
        evo.remove(e3, f1, f2, f3)
        evo.remove(e4, f1, f2, f3, f4)
        evo.remove(e5, f1, f2, f3, f4, f5)
        assert(evo.commit())
        assert(
            evo.get(e1, f1) == nil and
            evo.get(e1, f2) == true and
            evo.get(e1, f3) == true and
            evo.get(e1, f4) == true and
            evo.get(e1, f5) == true)
        assert(
            evo.get(e2, f1) == nil and
            evo.get(e2, f2) == nil and
            evo.get(e2, f3) == true and
            evo.get(e2, f4) == true and
            evo.get(e2, f5) == true)
        assert(
            evo.get(e3, f1) == nil and
            evo.get(e3, f2) == nil and
            evo.get(e3, f3) == nil and
            evo.get(e3, f4) == true and
            evo.get(e3, f5) == true)
        assert(
            evo.get(e4, f1) == nil and
            evo.get(e4, f2) == nil and
            evo.get(e4, f3) == nil and
            evo.get(e4, f4) == nil and
            evo.get(e4, f5) == true)
    end
end

do
    local fa, f0, f1, f2, f3, f4, f5 = evo.id(7)
    local q0 = evo.query():include(fa):build()

    evo.set(f0, evo.CONSTRUCT, function()
        return 42
    end)

    evo.set(f1, evo.CONSTRUCT, function(a1)
        return a1
    end)

    evo.set(f2, evo.CONSTRUCT, function(a1, a2)
        return a1 + a2
    end)

    evo.set(f3, evo.CONSTRUCT, function(a1, a2, a3)
        return a1 + a2 + a3
    end)

    evo.set(f4, evo.CONSTRUCT, function(a1, a2, a3, a4)
        return a1 + a2 + a3 + a4
    end)

    evo.set(f5, evo.CONSTRUCT, function(a1, a2, a3, a4, a5)
        return a1 + a2 + a3 + a4 + a5
    end)

    do
        local e1 = evo.entity():set(fa):build()
        local e2 = evo.entity():set(fa):build()
        assert(evo.defer())
        evo.batch_set(q0, f0)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.defer())
        evo.batch_set(q0, f1, 1)
        assert(evo.commit())
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e2, f1) == 1)
        assert(evo.defer())
        evo.batch_set(q0, f2, 1, 2)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.defer())
        evo.batch_set(q0, f3, 1, 2, 3)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.defer())
        evo.batch_set(q0, f4, 1, 2, 3, 4)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.defer())
        evo.batch_set(q0, f5, 1, 2, 3, 4, 5)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e1, f5) == 1 + 2 + 3 + 4 + 5)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e2, f5) == 1 + 2 + 3 + 4 + 5)
    end
    do
        local e1 = evo.entity():set(fa):build()
        local e2 = evo.entity():set(fa):build()
        assert(evo.defer())
        evo.batch_insert(q0, f0)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.defer())
        evo.batch_insert(q0, f1, 1)
        assert(evo.commit())
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e2, f1) == 1)
        assert(evo.defer())
        evo.batch_insert(q0, f2, 1, 2)
        assert(evo.commit())
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.defer())
        evo.batch_insert(q0, f3, 1, 2, 3)
        assert(evo.commit())
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.defer())
        evo.batch_insert(q0, f4, 1, 2, 3, 4)
        assert(evo.commit())
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f4) == 1 + 2 + 3 + 4)
        assert(evo.defer())
        evo.batch_insert(q0, f5, 1, 2, 3, 4, 5)
        assert(evo.commit())
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e1, f5) == 1 + 2 + 3 + 4 + 5)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e2, f5) == 1 + 2 + 3 + 4 + 5)
    end
    do
        local e1 = evo.entity():set(fa):build()
        local e2 = evo.entity():set(fa):build()
        assert(evo.defer())
        evo.batch_insert(q0, f0, 0)
        evo.batch_assign(q0, f0)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.defer())
        evo.batch_insert(q0, f1, 0)
        evo.batch_assign(q0, f1, 1)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e2, f1) == 1)
        assert(evo.defer())
        evo.batch_insert(q0, f2, 0, 0)
        evo.batch_assign(q0, f2, 1, 2)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.defer())
        evo.batch_insert(q0, f3, 0, 0, 0)
        evo.batch_assign(q0, f3, 1, 2, 3)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.defer())
        evo.batch_insert(q0, f4, 0, 0, 0, 0)
        evo.batch_assign(q0, f4, 1, 2, 3, 4)
        assert(evo.commit())
        assert(evo.get(e1, f0) == 42)
        assert(evo.get(e2, f0) == 42)
        assert(evo.get(e1, f1) == 1)
        assert(evo.get(e1, f2) == 1 + 2)
        assert(evo.get(e1, f3) == 1 + 2 + 3)
        assert(evo.get(e1, f4) == 1 + 2 + 3 + 4)
        assert(evo.get(e2, f1) == 1)
        assert(evo.get(e2, f2) == 1 + 2)
        assert(evo.get(e2, f3) == 1 + 2 + 3)
        assert(evo.get(e2, f4) == 1 + 2 + 3 + 4)
    end
    do
        local e1 = evo.entity()
            :set(fa)
            :build()
        local e2 = evo.entity()
            :set(fa)
            :build()
        assert(evo.defer())
        evo.batch_remove(q0)
        assert(evo.commit())
        assert(evo.get(e1, fa) == true)
        assert(evo.get(e2, fa) == true)
    end
    do
        local e1 = evo.entity()
            :set(fa)
            :set(f1, 1)
            :build()
        local e2 = evo.entity()
            :set(fa)
            :set(f1, 1)
            :build()
        assert(evo.defer())
        evo.batch_remove(q0, f1)
        assert(evo.commit())
        assert(evo.get(e1, f1) == nil)
        assert(evo.get(e2, f1) == nil)
    end
    do
        local e1 = evo.entity()
            :set(fa)
            :set(f1, 1)
            :set(f2, 1, 2)
            :build()
        local e2 = evo.entity()
            :set(fa)
            :set(f1, 1)
            :set(f2, 1, 2)
            :build()
        assert(evo.defer())
        evo.batch_remove(q0, f1, f2)
        assert(evo.commit())
        assert(evo.get(e1, f1) == nil)
        assert(evo.get(e2, f1) == nil)
        assert(evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == nil)
    end
    do
        local e1 = evo.entity()
            :set(fa)
            :set(f1, 1)
            :set(f2, 1, 2)
            :set(f3, 1, 2, 3)
            :build()
        local e2 = evo.entity()
            :set(fa)
            :set(f1, 1)
            :set(f2, 1, 2)
            :set(f3, 1, 2, 3)
            :build()
        assert(evo.defer())
        evo.batch_remove(q0, f1, f2, f3)
        assert(evo.commit())
        assert(evo.get(e1, f1) == nil)
        assert(evo.get(e2, f1) == nil)
        assert(evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == nil)
        assert(evo.get(e1, f3) == nil)
        assert(evo.get(e2, f3) == nil)
    end
    do
        local e1 = evo.entity()
            :set(fa)
            :set(f1, 1)
            :set(f2, 1, 2)
            :set(f3, 1, 2, 3)
            :set(f4, 1, 2, 3, 4)
            :build()
        local e2 = evo.entity()
            :set(fa)
            :set(f1, 1)
            :set(f2, 1, 2)
            :set(f3, 1, 2, 3)
            :set(f4, 1, 2, 3, 4)
            :build()
        assert(evo.defer())
        evo.batch_remove(q0, f1, f2, f3, f4)
        assert(evo.commit())
        assert(evo.get(e1, f1) == nil)
        assert(evo.get(e2, f1) == nil)
        assert(evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == nil)
        assert(evo.get(e1, f3) == nil)
        assert(evo.get(e2, f3) == nil)
        assert(evo.get(e1, f4) == nil)
        assert(evo.get(e2, f4) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    local assign_count = 0
    local insert_count = 0
    local remove_count = 0

    do
        evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
            assign_count = assign_count + 1
            assert(f == f1)
            assert(evo.get(e, f1) == c)

            do
                local s, d = evo.assign(e, f2, c)
                assert(s and not d)
            end
        end)

        evo.set(f1, evo.ON_INSERT, function(e, f, c)
            insert_count = insert_count + 1
            assert(f == f1)
            assert(evo.get(e, f1) == c)

            do
                local s, d = evo.insert(e, f2, c)
                assert(s and not d)
            end
        end)

        evo.set(f1, evo.ON_REMOVE, function(e, f, c)
            remove_count = remove_count + 1
            assert(f == f1)
            assert(c == 51)
            assert(evo.get(e, f1) == nil)

            do
                local s, d = evo.remove(e, f2)
                assert(s and not d)
            end
        end)
    end

    do
        evo.set(f2, evo.ON_ASSIGN, function(e, f, c)
            assign_count = assign_count + 1
            assert(f == f2)
            assert(evo.get(e, f1) == c)
            assert(evo.get(e, f2) == c)
        end)

        evo.set(f2, evo.ON_INSERT, function(e, f, c)
            insert_count = insert_count + 1
            assert(f == f2)
            assert(evo.get(e, f1) == c)
            assert(evo.get(e, f2) == c)
        end)

        evo.set(f2, evo.ON_REMOVE, function(e, f, c)
            remove_count = remove_count + 1
            assert(f == f2)
            assert(c == 51)
            assert(evo.get(e, f2) == nil)
        end)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        assert(evo.set(e, f1, 41))
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 41)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        assert(evo.set(e, f1, 51))
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 0)

        assert(evo.remove(e, f1))
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        assert(evo.multi_set(e, { f1 }, { 41 }))
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 41)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        assert(evo.multi_set(e, { f1 }, { 51 }))
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 0)

        assert(evo.multi_remove(e, { f1 }))
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        assert(evo.insert(e, f1, 41))
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 41)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        assert(evo.assign(e, f1, 51))
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 0)

        assert(evo.remove(e, f1))
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        assert(evo.multi_insert(e, { f1 }, { 41 }))
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 41)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        assert(evo.multi_assign(e, { f1 }, { 51 }))
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 0)

        assert(evo.multi_remove(e, { f1 }))
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        assert(evo.insert(e, f1, 51))
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        assert(evo.clear(e))
        assert(assign_count == 0 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        assert(evo.insert(e, f1, 51))
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        assert(evo.destroy(e))
        assert(assign_count == 0 and insert_count == 2 and remove_count == 2)
    end
end

do
    local f1, f2 = evo.id(2)

    local assign_count = 0
    local insert_count = 0
    local remove_count = 0

    evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
        assign_count = assign_count + 1
        assert(f == f1)
        assert(c == 51)
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 52)
    end)

    evo.set(f2, evo.ON_ASSIGN, function(e, f, c)
        assign_count = assign_count + 1
        assert(f == f2)
        assert(c == 52)
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 52)
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        insert_count = insert_count + 1
        assert(f == f1)
        assert(c == 41)
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 42)
    end)

    evo.set(f2, evo.ON_INSERT, function(e, f, c)
        insert_count = insert_count + 1
        assert(f == f2)
        assert(c == 42)
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 42)
    end)

    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        remove_count = remove_count + 1
        assert(f == f1)
        assert(c == 51)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end)

    evo.set(f2, evo.ON_REMOVE, function(e, f, c)
        remove_count = remove_count + 1
        assert(f == f2)
        assert(c == 52)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end)

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()
        assert(evo.multi_set(e, { f1, f2 }, { 41, 42 }))

        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2 }, { 41, 42 }))

        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2 }, { 41, 42 }))
        assert(evo.multi_assign(e, { f1, f2 }, { 51, 52 }))
        assert(evo.multi_remove(e, { f1, f2 }))

        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2 }, { 41, 42 }))
        assert(evo.multi_assign(e, { f1, f2 }, { 51, 52 }))
        assert(evo.clear(e))

        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()
        assert(evo.multi_insert(e, { f1, f2 }, { 41, 42 }))
        assert(evo.multi_assign(e, { f1, f2 }, { 51, 52 }))
        assert(evo.destroy(e))

        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end
end

do
    local f0, f1 = evo.id(2)
    local q0 = evo.query():include(f0):build()

    local assign_count = 0
    local insert_count = 0
    local remove_count = 0

    local e1, e2 = evo.id(2)

    evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
        assign_count = assign_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(evo.get(e1, f1) == c)
        assert(evo.get(e2, f1) == c)
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        insert_count = insert_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(evo.get(e1, f1) == c)
        assert(evo.get(e2, f1) == c)
    end)

    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        remove_count = remove_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(c == 51)
        assert(evo.get(e1, f1) == nil)
        assert(evo.get(e2, f1) == nil)
    end)

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        assert(evo.insert(e1, f0) and evo.insert(e2, f0))

        assert(evo.batch_insert(q0, f1, 41))
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        assert(evo.batch_assign(q0, f1, 51))
        assert(assign_count == 2 and insert_count == 2 and remove_count == 0)

        assert(evo.batch_remove(q0, f1))
        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)

        assert(evo.batch_insert(q0, f1, 51))
        assert(assign_count == 2 and insert_count == 4 and remove_count == 2)

        assert(evo.batch_clear(q0))
        assert(assign_count == 2 and insert_count == 4 and remove_count == 4)

        assert(evo.insert(e1, f0) and evo.insert(e2, f0))
        assert(evo.batch_insert(q0, f1, 51))
        assert(assign_count == 2 and insert_count == 6 and remove_count == 4)

        assert(evo.batch_destroy(q0))
        assert(assign_count == 2 and insert_count == 6 and remove_count == 6)
    end
end

do
    local f0, f1, f2 = evo.id(3)
    local q0 = evo.query():include(f0):build()

    local assign_count = 0
    local insert_count = 0
    local remove_count = 0

    local e1, e2 = evo.id(2)

    evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
        assign_count = assign_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(c == 51)
        assert(evo.get(e1, f1) == 51)
        assert(evo.get(e2, f1) == 51)
        assert(evo.get(e1, f2) == 52)
        assert(evo.get(e2, f2) == 52)
    end)

    evo.set(f2, evo.ON_ASSIGN, function(e, f, c)
        assign_count = assign_count + 1
        assert(e == e1 or e == e2)
        assert(f == f2)
        assert(c == 52)
        assert(evo.get(e1, f1) == 51)
        assert(evo.get(e2, f1) == 51)
        assert(evo.get(e1, f2) == 52)
        assert(evo.get(e2, f2) == 52)
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        insert_count = insert_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(c == 41)
        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 41)
        assert(evo.get(e1, f2) == 42)
        assert(evo.get(e2, f2) == 42)
    end)

    evo.set(f2, evo.ON_INSERT, function(e, f, c)
        insert_count = insert_count + 1
        assert(e == e1 or e == e2)
        assert(f == f2)
        assert(c == 42)
        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 41)
        assert(evo.get(e1, f2) == 42)
        assert(evo.get(e2, f2) == 42)
    end)

    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        remove_count = remove_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(c == 51)
        assert(evo.get(e1, f1) == nil)
        assert(evo.get(e2, f1) == nil)
        assert(evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == nil)
    end)

    evo.set(f2, evo.ON_REMOVE, function(e, f, c)
        remove_count = remove_count + 1
        assert(e == e1 or e == e2)
        assert(f == f2)
        assert(c == 52)
        assert(evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == nil)
        assert(evo.get(e1, f1) == nil)
        assert(evo.get(e2, f1) == nil)
    end)

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        assert(evo.insert(e1, f0) and evo.insert(e2, f0))

        assert(evo.batch_multi_insert(q0, { f1, f2 }, { 41, 42 }))
        assert(assign_count == 0 and insert_count == 4 and remove_count == 0)

        assert(evo.batch_multi_assign(q0, { f1, f2 }, { 51, 52 }))
        assert(assign_count == 4 and insert_count == 4 and remove_count == 0)

        assert(evo.batch_multi_remove(q0, { f1, f2 }))
        assert(assign_count == 4 and insert_count == 4 and remove_count == 4)

        assert(evo.batch_multi_set(q0, { f1, f2 }, { 41, 42 }))
        assert(assign_count == 4 and insert_count == 8 and remove_count == 4)

        assert(evo.batch_multi_set(q0, { f1, f2 }, { 51, 52 }))
        assert(assign_count == 8 and insert_count == 8 and remove_count == 4)

        assert(evo.batch_multi_remove(q0, { f1, f2 }))
        assert(assign_count == 8 and insert_count == 8 and remove_count == 8)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)

    local assign_count = 0

    evo.set(f4, evo.ON_ASSIGN, function()
        assign_count = assign_count + 1
    end)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    local e12 = evo.id()
    assert(evo.insert(e12, f1, 41))
    assert(evo.insert(e12, f2, 42))

    local e35 = evo.id()
    assert(evo.insert(e35, f3, 43))
    assert(evo.insert(e35, f5, 45))

    local e34 = evo.id()
    assert(evo.insert(e34, f3, 43))
    assert(evo.insert(e34, f4, 44))

    evo.set(f1, evo.ON_ASSIGN, function()
        assign_count = assign_count + 1
    end)

    evo.set(f3, evo.ON_ASSIGN, function()
        assign_count = assign_count + 1
    end)

    assert(assign_count == 0)

    assert(evo.assign(e1, f1, 41))
    assert(assign_count == 1)

    assert(evo.assign(e12, f1, 42))
    assert(assign_count == 2)

    assert(evo.assign(e34, f3, 43))
    assert(assign_count == 3)

    assert(evo.assign(e35, f3, 43))
    assert(assign_count == 4)
end

do
    local f1, f2, f3 = evo.id(3)
    local set_count = 0

    evo.set(f1, evo.ON_SET, function() set_count = set_count + 1 end)
    evo.set(f2, evo.ON_SET, function() set_count = set_count + 1 end)
    evo.set(f3, evo.ON_SET, function() set_count = set_count + 1 end)

    local e13 = evo.id()
    assert(evo.set(e13, f1, 41) and evo.set(e13, f3, 43))
    assert(set_count == 2)

    local e123 = evo.id()
    assert(evo.set(e123, f1, 41) and evo.set(e123, f2, 42) and evo.set(e123, f3, 43))
    assert(set_count == 5)

    assert(evo.assign(e123, f1, 41) and evo.assign(e123, f2, 42) and evo.assign(e123, f3, 43))
    assert(set_count == 8)

    do
        set_count = 0

        assert(evo.remove(f1, evo.ON_SET))

        evo.set(e13, f1, 41)
        assert(set_count == 0)
        evo.set(e13, f3, 43)
        assert(set_count == 1)

        evo.set(e123, f1, 41)
        assert(set_count == 1)
        evo.set(e123, f2, 42)
        assert(set_count == 2)
        evo.set(e123, f3, 43)
        assert(set_count == 3)
    end

    do
        set_count = 0

        assert(evo.remove(f2, evo.ON_SET))

        evo.set(e13, f1, 41)
        assert(set_count == 0)
        evo.set(e13, f3, 43)
        assert(set_count == 1)

        evo.set(e123, f1, 41)
        assert(set_count == 1)
        evo.set(e123, f2, 42)
        assert(set_count == 1)
        evo.set(e123, f3, 43)
        assert(set_count == 2)
    end
end

do
    local f1, f2 = evo.id(2)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))
    assert(evo.insert(e1, f2, 42))

    evo.set(f1, evo.DEFAULT, 51)
    evo.set(f2, evo.CONSTRUCT, function() return 52 end)

    assert(evo.assign(e1, f1))
    assert(evo.assign(e1, f2))

    assert(evo.get(e1, f1) == 51)
    assert(evo.get(e1, f2) == 52)
end

do
    local f1, f2 = evo.id(2)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    local e2 = evo.id()
    assert(evo.insert(e2, f1, 41))
    assert(evo.insert(e2, f2, 42))

    assert(evo.get(e1, f1) == 41)
    assert(evo.get(e2, f1) == 41)
    assert(evo.get(e2, f2) == 42)

    assert(evo.insert(f1, evo.TAG))
    assert(evo.get(e1, f1) == nil)
    assert(evo.get(e2, f1) == nil)
    assert(evo.get(e2, f2) == 42)

    assert(evo.remove(f1, evo.TAG))
    assert(evo.get(e1, f1) == true)
    assert(evo.get(e2, f1) == true)
    assert(evo.get(e2, f2) == 42)

    assert(evo.insert(f2, evo.TAG))
    assert(evo.get(e1, f1) == true)
    assert(evo.get(e2, f1) == true)
    assert(evo.get(e2, f2) == nil)

    assert(evo.insert(f2, evo.DEFAULT, 42))
    assert(evo.remove(f2, evo.TAG))
    assert(evo.get(e1, f1) == true)
    assert(evo.get(e2, f1) == true)
    assert(evo.get(e2, f2) == 42)

    assert(evo.set(f1, evo.DEFAULT, 81))
    assert(evo.set(f2, evo.DEFAULT, 82))
    assert(evo.get(e1, f1) == true)
    assert(evo.get(e2, f1) == true)
    assert(evo.get(e2, f2) == 42)
end

do
    local f1, f2 = evo.id(2)

    local q1 = evo.query():include(f1):build()

    local e1a = evo.entity():set(f1, 1):build()
    local e1b = evo.entity():set(f1, 11):build()

    do
        local c1, c1_es = evo.chunk(f1)
        assert(c1 and c1_es and #c1_es == 2)
        assert(c1_es[1] == e1a and c1_es[2] == e1b)
        assert(evo.select(c1, f1)[1] == 1 and evo.select(c1, f1)[2] == 11)
    end

    assert(evo.batch_insert(q1, f2, 2) == 2)

    do
        local c1, c1_es = evo.chunk(f1)
        assert(c1 and c1_es and #c1_es == 0)

        local c12, c12_es = evo.chunk(f1, f2)
        assert(c12 and c12_es and #c12_es == 2)
        assert(c12_es[1] == e1a and c12_es[2] == e1b)
        assert(evo.select(c12, f1)[1] == 1 and evo.select(c12, f1)[2] == 11)
        assert(evo.select(c12, f2)[1] == 2 and evo.select(c12, f2)[2] == 2)
    end

    local e1c = evo.entity():set(f1, 111):build()
    local e1d = evo.entity():set(f1, 1111):build()

    do
        local c1, c1_es = evo.chunk(f1)
        assert(c1 and c1_es and #c1_es == 2)
        assert(c1_es[1] == e1c and c1_es[2] == e1d)
        assert(evo.select(c1, f1)[1] == 111 and evo.select(c1, f1)[2] == 1111)
    end

    assert(evo.batch_insert(q1, f2, 22) == 2)

    do
        local c1, c1_es = evo.chunk(f1)
        assert(c1 and c1_es and #c1_es == 0)

        local c12, c12_es = evo.chunk(f1, f2)
        assert(c12 and c12_es and #c12_es == 4)
        assert(c12_es[1] == e1a and c12_es[2] == e1b)
        assert(c12_es[3] == e1c and c12_es[4] == e1d)
        assert(evo.select(c12, f1)[1] == 1 and evo.select(c12, f1)[2] == 11)
        assert(evo.select(c12, f1)[3] == 111 and evo.select(c12, f1)[4] == 1111)
        assert(evo.select(c12, f2)[1] == 2 and evo.select(c12, f2)[2] == 2)
        assert(evo.select(c12, f2)[3] == 22 and evo.select(c12, f2)[4] == 22)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    local q1 = evo.query():include(f1):build()

    local e123a = evo.entity():set(f1, 1):set(f2, 2):set(f3, 3):build()
    local e123b = evo.entity():set(f1, 11):set(f2, 22):set(f3, 33):build()

    do
        local c123, c123_es = evo.chunk(f1, f2, f3)
        assert(c123 and c123_es and #c123_es == 2)
        assert(c123_es[1] == e123a and c123_es[2] == e123b)
        assert(evo.select(c123, f1)[1] == 1 and evo.select(c123, f1)[2] == 11)
        assert(evo.select(c123, f2)[1] == 2 and evo.select(c123, f2)[2] == 22)
        assert(evo.select(c123, f3)[1] == 3 and evo.select(c123, f3)[2] == 33)
    end

    assert(evo.batch_remove(q1, f2) == 2)

    do
        local c13, c13_es = evo.chunk(f3, f1)
        assert(c13 and c13_es and #c13_es == 2)
        assert(c13_es[1] == e123a and c13_es[2] == e123b)
        assert(evo.select(c13, f1)[1] == 1 and evo.select(c13, f1)[2] == 11)
        assert(evo.select(c13, f2)[1] == nil and evo.select(c13, f2)[2] == nil)
        assert(evo.select(c13, f3)[1] == 3 and evo.select(c13, f3)[2] == 33)
    end

    local e3a = evo.entity():set(f3, 3):build()
    local e3b = evo.entity():set(f3, 33):build()

    do
        local c3, c3_es = evo.chunk(f3)
        assert(c3 and c3_es and #c3_es == 2)
        assert(c3_es[1] == e3a and c3_es[2] == e3b)
        assert(evo.select(c3, f3)[1] == 3 and evo.select(c3, f3)[2] == 33)
    end

    assert(evo.batch_remove(q1, f1) == 2)

    do
        local c3, c3_es = evo.chunk(f3)
        assert(c3 and c3_es and #c3_es == 4)
        assert(c3_es[1] == e3a and c3_es[2] == e3b)
        assert(c3_es[3] == e123a and c3_es[4] == e123b)
        assert(evo.select(c3, f1)[1] == nil and evo.select(c3, f1)[2] == nil)
        assert(evo.select(c3, f1)[3] == nil and evo.select(c3, f1)[4] == nil)
        assert(evo.select(c3, f2)[1] == nil and evo.select(c3, f2)[2] == nil)
        assert(evo.select(c3, f2)[3] == nil and evo.select(c3, f2)[4] == nil)
        assert(evo.select(c3, f3)[1] == 3 and evo.select(c3, f3)[2] == 33)
        assert(evo.select(c3, f3)[3] == 3 and evo.select(c3, f3)[4] == 33)
    end
end

do
    do
        local f = evo.fragment():default():build()
        assert(not evo.has(f, evo.DEFAULT))
    end

    do
        local f = evo.fragment():single():build()
        assert(not evo.has(f, f))
    end

    do
        local f = evo.fragment():single(42):build()
        assert(evo.has(f, f) and evo.get(f, f) == 42)
    end
end

do
    local s1 = evo.system():build()
    do
        local after = evo.get(s1, evo.AFTER)
        assert(after == nil)
    end

    local s2 = evo.system():after(s1):build()
    do
        local after = evo.get(s2, evo.AFTER)
        assert(#after == 1 and after[1] == s1)
    end

    local s3 = evo.system():after(s1, s2):build()
    do
        local after = evo.get(s3, evo.AFTER)
        assert(#after == 2 and after[1] == s1 and after[2] == s2)
    end
end

do
    local f1, f2 = evo.id(2)

    local e1a = evo.entity():set(f1, 1):build()
    local e1b = evo.entity():set(f1, 2):build()

    local e12 = evo.entity():set(f1, 3):set(f2, 4):build()

    do
        local c1, c1_es, c1_ec = evo.chunk(f1)
        assert(c1 and c1_es and c1_ec)
        assert(c1_ec == 2 and #c1_es == 2 and c1_es[1] == e1a and c1_es[2] == e1b)
    end

    do
        local c12, c12_es, c12_ec = evo.chunk(f1, f2)
        assert(c12 and c12_es and c12_ec)
        assert(c12_ec == 1 and #c12_es == 1 and c12_es[1] == e12)
    end
end

do
    local f = evo.fragment():build()
    assert(evo.get(f, evo.NAME) == nil)

    local q = evo.query():build()
    assert(evo.get(q, evo.NAME) == nil)

    local p = evo.phase():build()
    assert(evo.get(p, evo.NAME) == nil)

    local s = evo.system():build()
    assert(evo.get(s, evo.NAME) == nil)
end

do
    local fb = evo.fragment()
    local qb = evo.query()
    local pb = evo.phase()
    local sb = evo.system()

    do
        local f = fb:name('fragment'):build()
        assert(evo.get(f, evo.NAME) == 'fragment')

        local q = qb:name('query'):build()
        assert(evo.get(q, evo.NAME) == 'query')

        local p = pb:name('phase'):build()
        assert(evo.get(p, evo.NAME) == 'phase')

        local s = sb:name('system'):build()
        assert(evo.get(s, evo.NAME) == 'system')
    end

    do
        local f = fb:build()
        assert(evo.get(f, evo.NAME) == nil)

        local q = qb:build()
        assert(evo.get(q, evo.NAME) == nil)

        local p = pb:build()
        assert(evo.get(p, evo.NAME) == nil)

        local s = sb:build()
        assert(evo.get(s, evo.NAME) == nil)
    end
end

do
    local fb = evo.fragment()
    local qb = evo.query()
    local pb = evo.phase()
    local sb = evo.system()

    do
        local f = fb:single(false):build()
        assert(evo.get(f, f) == false)

        local q = qb:single(false):build()
        assert(evo.get(q, q) == false)

        local p = pb:single(false):build()
        assert(evo.get(p, p) == false)

        local s = sb:single(false):build()
        assert(evo.get(s, s) == false)
    end

    do
        local f = fb:build()
        assert(evo.get(f, f) == nil)

        local q = qb:build()
        assert(evo.get(q, q) == nil)

        local p = pb:build()
        assert(evo.get(p, p) == nil)

        local s = sb:build()
        assert(evo.get(s, s) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    local c12 = assert(evo.chunk(f1, f2))

    local e1a = evo.entity():set(f1, 1):build()
    local e1b = evo.entity():set(f1, 2):build()

    local e12a = evo.entity():set(f1, 3):set(f2, 4):build()
    local e12b = evo.entity():set(f1, 5):set(f2, 6):build()

    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 2 and c1_ec == 2)
        assert(c1_es[1] == e1a and c1_es[2] == e1b)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 0 and c2_ec == 0)

        local c12_es, c12_ec = evo.entities(c12)
        assert(c12_es and #c12_es == 2 and c12_ec == 2)
        assert(c12_es[1] == e12a and c12_es[2] == e12b)
    end

    assert(evo.remove(e12a, f1) and evo.remove(e12b, f1))
    assert(evo.insert(e1a, f2, 7) and evo.insert(e1b, f2, 8))

    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 2 and c2_ec == 2)
        assert(c2_es[1] == e12a and c2_es[2] == e12b)

        local c12_es, c12_ec = evo.entities(c12)
        assert(c12_es and #c12_es == 2 and c12_ec == 2)
        assert(c12_es[1] == e1a and c12_es[2] == e1b)
    end
end

do
    local f1, f2 = evo.id(2)
    local c1 = assert(evo.chunk(f1))
    assert(evo.set(f2, f1))
    assert(evo.destroy(f1))
    do
        assert(not evo.is_alive(f1))
        assert(evo.is_alive(f2))
        assert(evo.is_empty(f2))

        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)
    end
end

do
    local f1 = evo.id()
    local c1 = assert(evo.chunk(f1))
    assert(evo.set(f1, f1))
    assert(evo.destroy(f1))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)
    end
end

do
    local f1, f2 = evo.id(2)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    local c12 = assert(evo.chunk(f1, f2))
    assert(evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_REMOVE_FRAGMENT))
    assert(evo.set(f1, f1))
    assert(evo.set(f2, f1))
    assert(evo.set(f2, f2))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 0 and c2_ec == 0)

        local c12_es, c12_ec = evo.entities(c12)
        assert(c12_es and #c12_es == 1 and c12_ec == 1)
        assert(c12_es[1] == f2)
    end
    assert(evo.destroy(f1))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 1 and c2_ec == 1)
        assert(c2_es[1] == f2)

        local c12_es, c12_ec = evo.entities(c12)
        assert(c12_es and #c12_es == 0 and c12_ec == 0)
    end
end

do
    local f1, f2 = evo.id(2)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    local c12 = assert(evo.chunk(f1, f2))
    assert(evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_DESTROY_ENTITY))
    assert(evo.set(f1, f1))
    assert(evo.set(f2, f1))
    assert(evo.set(f2, f2))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 0 and c2_ec == 0)

        local c12_es, c12_ec = evo.entities(c12)
        assert(c12_es and #c12_es == 1 and c12_ec == 1)
        assert(c12_es[1] == f2)
    end
    assert(evo.destroy(f1))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 0 and c2_ec == 0)

        local c12_es, c12_ec = evo.entities(c12)
        assert(c12_es and #c12_es == 0 and c12_ec == 0)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    assert(evo.set(f2, f1))
    assert(evo.set(f3, f2))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 1 and c1_ec == 1)
        assert(c1_es[1] == f2)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
    assert(evo.destroy(f1))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    assert(evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_REMOVE_FRAGMENT))
    assert(evo.set(f2, f1))
    assert(evo.set(f3, f2))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 1 and c1_ec == 1)
        assert(c1_es[1] == f2)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
    assert(evo.destroy(f1))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    assert(evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_DESTROY_ENTITY))
    assert(evo.set(f2, f1))
    assert(evo.set(f3, f2))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 1 and c1_ec == 1)
        assert(c1_es[1] == f2)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
    assert(evo.destroy(f1))
    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)

        local c2_es, c2_ec = evo.entities(c2)
        assert(c2_es and #c2_es == 0 and c2_ec == 0)
    end
end

do
    local f1, f2, f3, f4, ft = evo.id(5)
    assert(evo.set(f1, ft))
    assert(evo.set(f2, ft))
    assert(evo.set(f3, ft))
    assert(evo.set(f3, evo.DESTROY_POLICY, evo.DESTROY_POLICY_DESTROY_ENTITY))
    local qt = evo.query():include(ft):build()

    local c4 = assert(evo.chunk(f4))
    local c14 = assert(evo.chunk(f1, f4))
    local c24 = assert(evo.chunk(f2, f4))
    local c234 = assert(evo.chunk(f2, f3, f4))
    local c124 = assert(evo.chunk(f1, f2, f4))

    local e14 = evo.entity():set(f1, 1):set(f4, 2):build()
    local e24 = evo.entity():set(f2, 3):set(f4, 4):build()
    local e234 = evo.entity():set(f2, 5):set(f3, 6):set(f4, 7):build()
    local e124 = evo.entity():set(f1, 8):set(f2, 6):set(f4, 9):build()

    assert(evo.batch_destroy(qt))

    do
        local c4_es, c4_ec = evo.entities(c4)
        assert(c4_es and #c4_es == 3 and c4_ec == 3)
        assert(c4_es[1] == e14 and c4_es[2] == e24 and c4_es[3] == e124)
    end

    assert(#evo.entities(c14) == 0)
    assert(#evo.entities(c24) == 0)
    assert(#evo.entities(c124) == 0)
    assert(#evo.entities(c234) == 0)

    assert(evo.is_alive(e14) and not evo.is_empty(e14))
    assert(evo.is_alive(e24) and not evo.is_empty(e24))
    assert(not evo.is_alive(e234) and evo.is_empty(e234))
    assert(evo.is_alive(e124) and not evo.is_empty(e124))
end

do
    local f1 = evo.id()
    assert(evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_DESTROY_ENTITY))
    assert(evo.set(f1, f1, f1))

    local remove_count = 0
    assert(evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        assert(e == f1)
        assert(f == f1)
        assert(c == f1)
        remove_count = remove_count + 1
    end))

    local c1 = assert(evo.chunk(f1))

    assert(evo.destroy(f1))

    do
        assert(not evo.is_alive(f1))
        assert(remove_count == 1)

        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)
    end
end

do
    local f1 = evo.id()
    assert(evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_REMOVE_FRAGMENT))
    assert(evo.set(f1, f1, f1))

    local remove_count = 0
    assert(evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        assert(e == f1)
        assert(f == f1)
        assert(c == f1)
        remove_count = remove_count + 1
    end))

    local c1 = assert(evo.chunk(f1))

    assert(evo.destroy(f1))

    do
        assert(not evo.is_alive(f1))
        assert(remove_count == 1)

        local c1_es, c1_ec = evo.entities(c1)
        assert(c1_es and #c1_es == 0 and c1_ec == 0)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    assert(evo.set(f1, evo.NAME, 'f1'))
    assert(evo.set(f2, evo.NAME, 'f2'))
    assert(evo.set(f3, evo.NAME, 'f3'))

    local c1 = evo.chunk(f1)
    local c12 = evo.chunk(f1, f2)
    local c13 = evo.chunk(f1, f3)
    local c123 = evo.chunk(f1, f2, f3)

    local e1a = evo.entity():set(f1, 1):build()
    local e1b = evo.entity():set(f1, 2):build()

    local e12a = evo.entity():set(f1, 3):set(f2, 4):build()
    local e12b = evo.entity():set(f1, 5):set(f2, 6):build()

    local e123a = evo.entity():set(f1, 7):set(f2, 8):set(f3, 9):build()
    local e123b = evo.entity():set(f1, 10):set(f2, 11):set(f3, 12):build()

    assert(evo.destroy(f2))

    do
        assert(c1 and c12 and c13 and c123)
    end

    do
        local c1_es, c1_ec = evo.entities(c1)
        assert(c1 and c1_es and c1_ec)
        assert(c1_ec == 4 and #c1_es == 4)
        assert(c1_es[1] == e1a and c1_es[2] == e1b and c1_es[3] == e12a and c1_es[4] == e12b)
    end

    do
        local c12_es, c12_ec = evo.entities(c12)
        assert(c12 and c12_es and c12_ec)
        assert(c12_ec == 0 and #c12_es == 0)
    end

    do
        local c13_es, c13_ec = evo.entities(c13)
        assert(c13 and c13_es and c13_ec)
        assert(c13_ec == 2 and #c13_es == 2)
        assert(c13_es[1] == e123a and c13_es[2] == e123b)
    end

    do
        local c123_es, c123_ec = evo.entities(c123)
        assert(c123 and c123_es and c123_ec)
        assert(c123_ec == 0 and #c123_es == 0)
    end
end

do
    do
        local f1, f2 = evo.id(2)
        evo.set(f1, f1)
        evo.set(f2, f1)
        evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_DESTROY_ENTITY)
        assert(evo.destroy(f1))
        assert(not evo.is_alive(f1))
        assert(not evo.is_alive(f2))
    end

    do
        local f1, f2 = evo.id(2)
        evo.set(f1, f1)
        evo.set(f2, f1)
        evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_REMOVE_FRAGMENT)
        assert(evo.destroy(f1))
        assert(not evo.is_alive(f1))
        assert(evo.is_alive(f2) and evo.is_empty(f2))
    end
end

do
    local f1, f2 = evo.id(2)

    evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_DESTROY_ENTITY)

    local e12a = evo.entity():set(f1, 1):set(f2, 2):build()
    local e12b = evo.entity():set(f1, 3):set(f2, 4):build()
    local e_e12a_e12b = evo.entity():set(e12a, 11):set(e12b, 22):build()

    local e2a = evo.entity():set(f2, 5):build()
    local e2b = evo.entity():set(f2, 6):build()
    local e_e2a_e2b = evo.entity():set(e2a, 55):set(e2b, 66):build()

    assert(evo.destroy(f1))

    do
        assert(not evo.is_alive(e12a) and not evo.is_alive(e12b))
        assert(evo.is_alive(e_e12a_e12b) and evo.is_empty(e_e12a_e12b))

        assert(evo.is_alive(e2a) and evo.is_alive(e2b))
        assert(evo.is_alive(e_e2a_e2b) and not evo.is_empty(e_e2a_e2b))
    end

    do
        local c2, c2_es, c2_ec = evo.chunk(f2)
        assert(c2 and c2_es and c2_ec)
        assert(#c2_es == 2 and c2_ec == 2)
        assert(c2_es[1] == e2a and c2_es[2] == e2b)
    end
end

do
    local f1, f2 = evo.id(2)

    evo.set(f1, evo.NAME, "f1")
    evo.set(f2, evo.NAME, "f2")

    do
        local c12 = evo.chunk(f1, f2)

        local f3 = evo.id()
        evo.set(f3, evo.TAG)
        local c123 = evo.chunk(f2, f1, f3)
        evo.spawn_at(c123)

        assert(c12, c123)
    end

    evo.set(f1, evo.DESTROY_POLICY, evo.DESTROY_POLICY_REMOVE_FRAGMENT)

    local e12a = evo.entity():set(f1, 1):set(f2, 2):build()
    local e12b = evo.entity():set(f1, 3):set(f2, 4):build()
    local e_e12a_e12b = evo.entity():set(e12a, 11):set(e12b, 22):build()

    local e2a = evo.entity():set(f2, 5):build()
    local e2b = evo.entity():set(f2, 6):build()
    local e_e2a_e2b = evo.entity():set(e2a, 55):set(e2b, 66):build()

    assert(evo.destroy(f1))

    do
        assert(evo.is_alive(e12a) and evo.is_alive(e12b))
        assert(evo.is_alive(e_e12a_e12b) and not evo.is_empty(e_e12a_e12b))
        assert(evo.is_alive(e2a) and evo.is_alive(e2b))
        assert(evo.is_alive(e_e2a_e2b) and not evo.is_empty(e_e2a_e2b))
    end

    do
        local c2, c2_es, c2_ec = evo.chunk(f2)
        assert(c2 and c2_es and c2_ec)
        assert(#c2_es == 4 and c2_ec == 4)
        assert(c2_es[1] == e2a and c2_es[2] == e2b and c2_es[3] == e12a and c2_es[4] == e12b)
    end
end

do
    local fb = evo.fragment()

    local f1 = fb:build()
    local f2 = fb:destroy_policy(evo.DESTROY_POLICY_DESTROY_ENTITY):build()
    local f3 = fb:destroy_policy(evo.DESTROY_POLICY_REMOVE_FRAGMENT):build()

    assert(evo.get(f1, evo.DESTROY_POLICY) == nil)
    assert(evo.get(f2, evo.DESTROY_POLICY) == evo.DESTROY_POLICY_DESTROY_ENTITY)
    assert(evo.get(f3, evo.DESTROY_POLICY) == evo.DESTROY_POLICY_REMOVE_FRAGMENT)
end

do
    local f1, f2, f3 = evo.id(3)

    local c1 = evo.chunk(f1)
    local c23 = evo.chunk(f2, f3)

    assert(c1 and c23)

    assert(#evo.fragments(c1) == 1)
    assert(evo.fragments(c1)[1] == f1)

    assert(#evo.fragments(c23) == 2)
    assert(evo.fragments(c23)[1] == f2)
    assert(evo.fragments(c23)[2] == f3)
end

do
    local f0, f1, f2, f3 = evo.id(4)

    local e1 = evo.entity():set(f0, 0):set(f1, 1):build()
    local e12 = evo.entity():set(f0, 0):set(f1, 2):set(f2, 3):build()
    local e123 = evo.entity():set(f0, 0):set(f1, 4):set(f2, 5):set(f3, 6):build()

    evo.entity():set(f1, 41):build()
    evo.entity():set(f1, 42):set(f2, 43):build()

    do
        local q1 = evo.query():include(f0, f1):build()

        local iter, state = evo.execute(q1)

        local chunk, entity_list = iter(state)
        assert(entity_list and #entity_list == 1)
        assert(chunk == evo.chunk(f0, f1) and entity_list[1] == e1)

        chunk, entity_list = iter(state)
        assert(entity_list and #entity_list == 1)
        assert(chunk == evo.chunk(f0, f1, f2) and entity_list[1] == e12)

        chunk, entity_list = iter(state)
        assert(entity_list and #entity_list == 1)
        assert(chunk == evo.chunk(f0, f1, f2, f3) and entity_list[1] == e123)

        chunk, entity_list = iter(state)
        assert(not chunk and not entity_list)
    end

    do
        local q1 = evo.query():include(f0, f1):exclude(f3):build()

        local iter, state = evo.execute(q1)

        local chunk, entity_list = iter(state)
        assert(entity_list and #entity_list == 1)
        assert(chunk == evo.chunk(f0, f1) and entity_list[1] == e1)

        chunk, entity_list = iter(state)
        assert(entity_list and #entity_list == 1)
        assert(chunk == evo.chunk(f0, f1, f2) and entity_list[1] == e12)

        chunk, entity_list = iter(state)
        assert(not chunk and not entity_list)
    end
end

do
    local f1, f2 = evo.id(2)
    local q12 = evo.query():include(f1, f2):build()

    do
        local iter, state = evo.execute(q12)
        local chunk, entity_list, entity_count = iter(state)
        assert(not chunk and not entity_list and not entity_count)
    end
end

do
    local f1, f2 = evo.id(2)
    local qe12 = evo.query():exclude(f1, f2):build()

    evo.entity():set(f1, 1):build()
    evo.entity():set(f2, 2):build()
    local e12 = evo.entity():set(f1, 3):set(f2, 4):build()

    local c1 = evo.chunk(f1)
    local c2 = evo.chunk(f2)
    local c12 = evo.chunk(f1, f2)

    do
        local matched_chunk_count = 0
        local matched_entity_count = 0

        for c, es, ec in evo.execute(qe12) do
            assert(ec > 0)
            assert(#es == ec)
            assert(c ~= c1 and c ~= c2 and c ~= c12)
            matched_chunk_count = matched_chunk_count + 1
            matched_entity_count = matched_entity_count + ec
        end

        assert(matched_chunk_count > 0)
        assert(matched_entity_count > 0)
    end

    assert(evo.assign(qe12, evo.EXCLUDES))

    do
        local matched_chunk_count = 0
        local matched_entity_count = 0

        for _, es, ec in evo.execute(qe12) do
            assert(ec > 0)
            assert(#es == ec)
            matched_chunk_count = matched_chunk_count + 1
            matched_entity_count = matched_entity_count + ec
        end

        assert(matched_chunk_count > 0)
        assert(matched_entity_count > 0)
    end

    assert(evo.insert(qe12, evo.INCLUDES, f1, f2))

    do
        local iter, state = evo.execute(qe12)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk == c12)
        assert(entity_list and #entity_list == 1)
        assert(entity_count and entity_count == 1)
        assert(entity_list[1] == e12)
    end
end

do
    local f1, f2 = evo.id(2)

    assert(evo.insert(f1, evo.NAME, 'f1'))
    assert(evo.insert(f2, evo.NAME, 'f2'))

    local old_c1 = assert(evo.chunk(f1))
    local old_c12 = assert(evo.chunk(f1, f2))

    local e1 = evo.entity():set(f1, 1):build()

    evo.collect_garbage()

    local e12 = evo.entity():set(f1, 2):set(f2, 3):build()

    do
        assert(old_c1 == evo.chunk(f1))

        local old_c1_es, old_c1_ec = evo.entities(old_c1)
        assert(old_c1_es and old_c1_ec)
        assert(#old_c1_es == 1 and old_c1_ec == 1)
        assert(old_c1_es[1] == e1)
    end

    do
        local new_c12 = assert(evo.chunk(f1, f2))
        assert(old_c12 ~= new_c12)

        local new_c12_es, new_c12_ec = evo.entities(new_c12)
        assert(new_c12_es and new_c12_ec)
        assert(#new_c12_es == 1 and new_c12_ec == 1)
        assert(new_c12_es[1] == e12)
    end

    assert(evo.destroy(e1))
    assert(evo.destroy(e12))

    evo.collect_garbage()

    do
        local new_c1 = assert(evo.chunk(f1))
        assert(old_c1 ~= new_c1)

        local new_c12 = assert(evo.chunk(f1, f2))
        assert(old_c12 ~= new_c12)
    end
end

do
    local f1 = evo.id()
    local old_c1 = evo.chunk(f1)

    assert(evo.defer())

    assert(not evo.collect_garbage())
    assert(old_c1 == evo.chunk(f1))

    assert(evo.commit())

    assert(old_c1 ~= evo.chunk(f1))
end

do
    do
        local f1 = evo.id()

        local e1, e2 = evo.id(2)
        assert(evo.insert(e1, f1, f1))
        assert(evo.insert(e2, f1, f1))

        assert(evo.clear(e1, e2))

        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(evo.is_alive(e2) and evo.is_empty(e2))
    end

    do
        local f1 = evo.id()

        local e1, e2, e3, e4, e5 = evo.id(5)
        assert(evo.insert(e1, f1, f1))
        assert(evo.insert(e2, f1, f1))
        assert(evo.insert(e3, f1, f1))
        assert(evo.insert(e4, f1, f1))
        assert(evo.insert(e5, f1, f1))

        assert(evo.clear(e1, e2, e3, e4, e5))

        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(evo.is_alive(e2) and evo.is_empty(e2))
        assert(evo.is_alive(e3) and evo.is_empty(e3))
        assert(evo.is_alive(e4) and evo.is_empty(e4))
        assert(evo.is_alive(e5) and evo.is_empty(e5))
    end
end

do
    do
        local f1 = evo.id()

        local e1, e2, e3 = evo.id(3)
        assert(evo.insert(e1, f1, f1))
        assert(evo.insert(e2, f1, f1))
        assert(evo.insert(e3, f1, f1))

        assert(evo.defer())
        do
            assert(not evo.clear(e1, e2, e3))
            assert(evo.is_alive(e1) and not evo.is_empty(e1))
            assert(evo.is_alive(e2) and not evo.is_empty(e2))
            assert(evo.is_alive(e3) and not evo.is_empty(e3))
        end
        assert(evo.commit())

        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(evo.is_alive(e2) and evo.is_empty(e2))
        assert(evo.is_alive(e3) and evo.is_empty(e3))
    end

    do
        local f1 = evo.id()

        local e1, e2, e3, e4, e5 = evo.id(5)
        assert(evo.insert(e1, f1, f1))
        assert(evo.insert(e2, f1, f1))
        assert(evo.insert(e3, f1, f1))
        assert(evo.insert(e4, f1, f1))
        assert(evo.insert(e5, f1, f1))

        assert(evo.defer())
        do
            assert(not evo.clear(e1, e2, e3, e4, e5))
            assert(evo.is_alive(e1) and not evo.is_empty(e1))
            assert(evo.is_alive(e2) and not evo.is_empty(e2))
            assert(evo.is_alive(e3) and not evo.is_empty(e3))
            assert(evo.is_alive(e4) and not evo.is_empty(e4))
            assert(evo.is_alive(e5) and not evo.is_empty(e5))
        end
        assert(evo.commit())

        assert(evo.is_alive(e1) and evo.is_empty(e1))
        assert(evo.is_alive(e2) and evo.is_empty(e2))
        assert(evo.is_alive(e3) and evo.is_empty(e3))
        assert(evo.is_alive(e4) and evo.is_empty(e4))
        assert(evo.is_alive(e5) and evo.is_empty(e5))
    end
end

do
    do
        local f1 = evo.id()

        local e1, e2 = evo.id(2)
        assert(evo.insert(e1, f1, f1))
        assert(evo.insert(e2, f1, f1))

        assert(evo.destroy(e1, e2))

        assert(not evo.is_alive(e1) and evo.is_empty(e1))
        assert(not evo.is_alive(e2) and evo.is_empty(e2))
    end

    do
        local f1 = evo.id()

        local e1, e2, e3, e4, e5 = evo.id(5)
        assert(evo.insert(e1, f1, f1))
        assert(evo.insert(e2, f1, f1))
        assert(evo.insert(e3, f1, f1))
        assert(evo.insert(e4, f1, f1))
        assert(evo.insert(e5, f1, f1))

        assert(evo.destroy(e1, e2, e3, e4, e5))

        assert(not evo.is_alive(e1) and evo.is_empty(e1))
        assert(not evo.is_alive(e2) and evo.is_empty(e2))
        assert(not evo.is_alive(e3) and evo.is_empty(e3))
        assert(not evo.is_alive(e4) and evo.is_empty(e4))
        assert(not evo.is_alive(e5) and evo.is_empty(e5))
    end
end

do
    do
        local f1 = evo.id()

        local e1, e2, e3 = evo.id(3)
        assert(evo.insert(e1, f1, f1))
        assert(evo.insert(e2, f1, f1))
        assert(evo.insert(e3, f1, f1))

        assert(evo.defer())
        do
            assert(not evo.destroy(e1, e2, e3))
            assert(evo.is_alive(e1) and not evo.is_empty(e1))
            assert(evo.is_alive(e2) and not evo.is_empty(e2))
            assert(evo.is_alive(e3) and not evo.is_empty(e3))
        end
        assert(evo.commit())

        assert(not evo.is_alive(e1) and evo.is_empty(e1))
        assert(not evo.is_alive(e2) and evo.is_empty(e2))
        assert(not evo.is_alive(e3) and evo.is_empty(e3))
    end

    do
        local f1 = evo.id()

        local e1, e2, e3, e4, e5 = evo.id(5)
        assert(evo.insert(e1, f1, f1))
        assert(evo.insert(e2, f1, f1))
        assert(evo.insert(e3, f1, f1))
        assert(evo.insert(e4, f1, f1))
        assert(evo.insert(e5, f1, f1))

        assert(evo.defer())
        do
            assert(not evo.destroy(e1, e2, e3, e4, e5))
            assert(evo.is_alive(e1) and not evo.is_empty(e1))
            assert(evo.is_alive(e2) and not evo.is_empty(e2))
            assert(evo.is_alive(e3) and not evo.is_empty(e3))
            assert(evo.is_alive(e4) and not evo.is_empty(e4))
            assert(evo.is_alive(e5) and not evo.is_empty(e5))
        end
        assert(evo.commit())

        assert(not evo.is_alive(e1) and evo.is_empty(e1))
        assert(not evo.is_alive(e2) and evo.is_empty(e2))
        assert(not evo.is_alive(e3) and evo.is_empty(e3))
        assert(not evo.is_alive(e4) and evo.is_empty(e4))
        assert(not evo.is_alive(e5) and evo.is_empty(e5))
    end
end

do
    local f1 = evo.id()
    local e1, e2 = evo.id(2)
    assert(evo.insert(e1, f1, f1))
    assert(evo.insert(e2, f1, f1))
    assert(evo.clear(e1, e2, e1, e1))
    assert(evo.is_alive(e1) and evo.is_empty(e1))
    assert(evo.is_alive(e2) and evo.is_empty(e2))
end

do
    local f1 = evo.id()
    local e1, e2 = evo.id(2)
    assert(evo.insert(e1, f1, f1))
    assert(evo.insert(e2, f1, f1))
    assert(evo.destroy(e1, e2, e1, e1))
    assert(not evo.is_alive(e1) and evo.is_empty(e1))
    assert(not evo.is_alive(e2) and evo.is_empty(e2))
end

do
    local f1, f2 = evo.id(2)

    local q1, q2 = evo.id(2)
    assert(evo.insert(q1, evo.INCLUDES, f1))
    assert(evo.insert(q2, evo.INCLUDES, f2))

    local e1, e2 = evo.id(2)
    assert(evo.insert(e1, f1, f1))
    assert(evo.insert(e2, f2, f2))

    assert(evo.batch_clear() == 0)

    assert(evo.is_alive(e1) and not evo.is_empty(e1))
    assert(evo.is_alive(e2) and not evo.is_empty(e2))

    assert(evo.batch_clear(q1, q2, q1, q1) == 2)

    assert(evo.is_alive(e1) and evo.is_empty(e1))
    assert(evo.is_alive(e2) and evo.is_empty(e2))
end

do
    local f1, f2 = evo.id(2)

    local q1, q2 = evo.id(2)
    assert(evo.insert(q1, evo.INCLUDES, f1))
    assert(evo.insert(q2, evo.INCLUDES, f2))

    local e1, e2 = evo.id(2)
    assert(evo.insert(e1, f1, f1))
    assert(evo.insert(e2, f2, f2))

    assert(evo.defer())
    do
        assert(evo.batch_clear(q2, q1, q2, q2) == 0)
        assert(evo.is_alive(e1) and not evo.is_empty(e1))
        assert(evo.is_alive(e2) and not evo.is_empty(e2))
    end
    assert(evo.commit())

    assert(evo.is_alive(e1) and evo.is_empty(e1))
    assert(evo.is_alive(e2) and evo.is_empty(e2))
end

do
    local f1, f2 = evo.id(2)

    local q1, q2 = evo.id(2)
    assert(evo.insert(q1, evo.INCLUDES, f1))
    assert(evo.insert(q2, evo.INCLUDES, f2))

    local e1, e2 = evo.id(2)
    assert(evo.insert(e1, f1, f1))
    assert(evo.insert(e2, f2, f2))

    assert(evo.batch_destroy() == 0)

    assert(evo.is_alive(e1) and not evo.is_empty(e1))
    assert(evo.is_alive(e2) and not evo.is_empty(e2))

    assert(evo.batch_destroy(q1, q2, q1, q1) == 2)

    assert(not evo.is_alive(e1) and evo.is_empty(e1))
    assert(not evo.is_alive(e2) and evo.is_empty(e2))
end

do
    local f1, f2 = evo.id(2)

    local q1, q2 = evo.id(2)
    assert(evo.insert(q1, evo.INCLUDES, f1))
    assert(evo.insert(q2, evo.INCLUDES, f2))

    local e1, e2 = evo.id(2)
    assert(evo.insert(e1, f1, f1))
    assert(evo.insert(e2, f2, f2))

    assert(evo.defer())
    do
        assert(evo.batch_destroy(q2, q1, q2, q2) == 0)
        assert(evo.is_alive(e1) and not evo.is_empty(e1))
        assert(evo.is_alive(e2) and not evo.is_empty(e2))
    end
    assert(evo.commit())

    assert(not evo.is_alive(e1) and evo.is_empty(e1))
    assert(not evo.is_alive(e2) and evo.is_empty(e2))
end

do
    local a1, a2, a3, a4, a5 = evo.id(5)

    assert(evo.is_alive())
    assert(evo.is_alive(a1))
    assert(evo.is_alive(a1, a2))
    assert(evo.is_alive(a1, a2, a3))
    assert(evo.is_alive(a1, a2, a3, a4))
    assert(evo.is_alive(a1, a2, a3, a4, a5))

    local d1, d2 = evo.id(2)
    assert(evo.destroy(d1, d2))

    assert(not evo.is_alive(d1))
    assert(not evo.is_alive(d1, d2))
    assert(not evo.is_alive(d1, a1))
    assert(not evo.is_alive(a1, d1))
    assert(not evo.is_alive(d1, d2, a1))
    assert(not evo.is_alive(d1, a1, a2))
    assert(not evo.is_alive(d1, a1, a2, d2, a3))
    assert(not evo.is_alive(d1, a1, a2, d2, a3, d1))
end

do
    local e1, e2, e3, e4, e5 = evo.id(5)

    assert(evo.is_empty())
    assert(evo.is_empty(e1))
    assert(evo.is_empty(e1, e2))
    assert(evo.is_empty(e1, e2, e3))
    assert(evo.is_empty(e1, e2, e3, e4))
    assert(evo.is_empty(e1, e2, e3, e4, e5))

    local d1, d2 = evo.id(2)
    assert(evo.destroy(d1, d2))

    assert(evo.is_empty(d1))
    assert(evo.is_empty(d1, d2))
    assert(evo.is_empty(d1, e1))
    assert(evo.is_empty(e1, d1))
    assert(evo.is_empty(d1, d2, e1))
    assert(evo.is_empty(d1, e1, e2))
    assert(evo.is_empty(d1, e1, e2, d2, e3))
    assert(evo.is_empty(d1, e1, e2, d2, e3, d1))

    local f1, f2 = evo.id(2)
    assert(evo.insert(f1, f1) and evo.insert(f2, f2))

    assert(not evo.is_empty(f1))
    assert(not evo.is_empty(f1, f2))
    assert(not evo.is_empty(f1, e1))
    assert(not evo.is_empty(e1, f1))
    assert(not evo.is_empty(f1, f2, e1))
    assert(not evo.is_empty(f1, e1, e2))
    assert(not evo.is_empty(f1, e1, e2, f2, e3))
    assert(not evo.is_empty(f1, e1, e2, f2, e3, f1))
end

do
    local f1, f2, f3, f4, f5, f6 = evo.id(6)

    local e2 = evo.spawn_with({ f1, f2 })
    local e5 = evo.spawn_with({ f1, f2, f3, f4, f5 })

    assert(evo.has_all(e2, f1))
    assert(evo.has_all(e2, f1, f2))
    assert(evo.has_all(e2, f2, f1))
    assert(evo.has_all(e2, f2, f1, f2))
    assert(not evo.has_all(e2, f1, f2, f3))

    assert(evo.has_all(e5, f1))
    assert(evo.has_all(e5, f1, f2))
    assert(evo.has_all(e5, f1, f2, f3))
    assert(evo.has_all(e5, f1, f2, f3, f4))
    assert(evo.has_all(e5, f1, f2, f3, f4, f5))

    assert(not evo.has_all(e5, f6, f1, f2, f3, f4, f5))
    assert(not evo.has_all(e5, f1, f2, f3, f4, f5, f6))
    assert(not evo.has_all(e5, f1, f2, f6, f3, f4, f5))
end

do
    local f1, f2, f3, f4, f5, f6, f7 = evo.id(7)

    local e2 = evo.spawn_with({ f1, f2 })
    local e5 = evo.spawn_with({ f1, f2, f3, f4, f5 })

    assert(evo.has_all(e2))
    assert(not evo.has_any(e2))

    assert(evo.has_any(e2, f1))
    assert(evo.has_any(e2, f1, f2))
    assert(evo.has_any(e2, f2, f1))
    assert(evo.has_any(e2, f2, f1, f2))
    assert(evo.has_any(e2, f1, f2, f3))
    assert(evo.has_any(e2, f3, f4, f5, f6, f7, f1))

    assert(not evo.has_any(e2, f3))
    assert(not evo.has_any(e2, f3, f4))
    assert(not evo.has_any(e2, f3, f7, f4))

    assert(evo.has_any(e5, f1))
    assert(evo.has_any(e5, f1, f2))
    assert(evo.has_any(e5, f1, f2, f3))
    assert(evo.has_any(e5, f1, f2, f3, f4))
    assert(evo.has_any(e5, f1, f2, f3, f4, f5))

    assert(evo.has_any(e5, f6, f1, f2, f3, f4, f5))
    assert(evo.has_any(e5, f1, f2, f3, f4, f5, f6))
    assert(evo.has_any(e5, f1, f2, f6, f3, f4, f5))

    assert(not evo.has_any(e5, f7))
    assert(not evo.has_any(e5, f7, f7))
    assert(not evo.has_any(e5, f7, f7, f6))
end
