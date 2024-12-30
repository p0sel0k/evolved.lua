---@diagnostic disable: invisible
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
    evo.set(f1, evo.CONSTRUCT, function(_, _, a, b) return a - b end)
    evo.set(f2, evo.CONSTRUCT, function(_, _, c) return c end)
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
    evo.remove(e, f1, f2)
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
        local chunk, entities = evo.chunk(f1, f2, f3)
        assert(not chunk and not entities)
    end

    do
        local chunk, entities = evo.chunk(f3, f2, f1)
        assert(not chunk and not entities)
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
        assert(evo.get(entity, f2) == component * 2)
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
        assert(evo.get(entity, f2) == component * 2)
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
        evo.insert(q, evo.INCLUDE_LIST, f1, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f1, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f1, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f1, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f1, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f1, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f1, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f1, f2)

        assert(evo.batch_remove(q, f2, f3) == 3)
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
        evo.insert(q, evo.INCLUDE_LIST, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f2)

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
        evo.insert(q, evo.INCLUDE_LIST, f2)

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
            evo.set(q, evo.INCLUDE_LIST, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDE_LIST, f1, f2)

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
            evo.set(q, evo.INCLUDE_LIST, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDE_LIST, f1, f2)

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
                local chunk = assert(evo.chunk(f1, f2, f3))

                assert(chunk.__entities[1] == e3 and chunk.__entities[2] == e1)

                assert(chunk.__components[f1] == nil)
                assert(chunk.__components[f2] == nil)
                assert(chunk.__components[f3][1] == 43 and chunk.__components[f3][2] == 50)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDE_LIST, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDE_LIST, f1, f2)

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
                local chunk = assert(evo.chunk(f2))
                assert(chunk.__entities[1] == e1)
                assert(chunk.__components[f1] == nil)
                assert(chunk.__components[f2] == nil)
                assert(chunk.__components[f3] == nil)
            end

            do
                local chunk = assert(evo.chunk(f2, f3))
                assert(chunk.__entities[1] == e3)
                assert(chunk.__components[f1] == nil)
                assert(chunk.__components[f2] == nil)
                assert(chunk.__components[f3][1] == 43)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDE_LIST, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDE_LIST, f1, f2)

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
                local chunk = assert(evo.chunk(f1, f2, f3))
                assert(next(chunk.__entities) == nil)
                assert(chunk.__components[f1] == nil)
                assert(chunk.__components[f2] == nil)
                assert(next(chunk.__components[f3]) == nil)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDE_LIST, f1)
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDE_LIST, f1, f2)

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
                local chunk = assert(evo.chunk(f1, f2, f3))
                assert(next(chunk.__entities) == nil)
                assert(chunk.__components[f1] == nil)
                assert(chunk.__components[f2] == nil)
                assert(next(chunk.__components[f3]) == nil)
            end
        end
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDE_LIST, f1)

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
    evo.set(q, evo.INCLUDE_LIST, f1)

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
    evo.set(q, evo.INCLUDE_LIST, f1)

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
    evo.set(q, evo.INCLUDE_LIST, f1)

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
    evo.set(q, evo.INCLUDE_LIST, f1)

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
    evo.set(q, evo.INCLUDE_LIST, f1)

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
    evo.set(q, evo.INCLUDE_LIST, f1)
    evo.set(q, evo.INCLUDE_LIST, f2)

    local e1 = evo.id()
    assert(evo.insert(e1, f1, 41))

    local e2 = evo.id()
    assert(evo.insert(e2, f2, 42))

    do
        local iter, state = evo.execute(q)
        local chunk, entities = iter(state)

        assert(chunk == evo.chunk(f2))
        assert(entities and entities[1] == e2)
    end

    evo.set(q, evo.INCLUDE_LIST)

    do
        local iter, state = evo.execute(q)
        local chunk, entities = iter(state)

        assert(not chunk)
        assert(not entities)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDE_LIST, f1)

    evo.set(q, evo.EXCLUDE_LIST, f1)
    evo.set(q, evo.EXCLUDE_LIST, f2)

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

    evo.set(q, evo.EXCLUDE_LIST)

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
        local chunk, entities = iter(state)
        assert(not chunk and not entities)
    end

    evo.set(q, evo.EXCLUDE_LIST, f2)

    do
        local iter, state = evo.execute(q)
        local chunk, entities = iter(state)
        assert(not chunk and not entities)
    end

    evo.set(q, evo.INCLUDE_LIST, f1)

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
