---@diagnostic disable: invisible
local evo = require 'evolved.evolved'

do
    local f1, f2, f3 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    local e = evo.registry.entity()
    assert(e.__chunk == nil)

    assert(e:insert(f1))
    assert(e:has(f1))
    assert(not e:has(f2))

    assert(e:insert(f2))
    assert(e:has(f1))
    assert(e:has(f2))

    assert(e:remove(f1))
    assert(not e:has(f1))
    assert(e:has(f2))

    assert(e:remove(f2))
    assert(not e:has(f1))
    assert(not e:has(f2))

    assert(e:insert(f3))
    assert(not e:remove(f2))
    assert(not e:remove())
end

do
    local f1, f2 =
        evo.registry.entity(),
        evo.registry.entity()

    local e = evo.registry.entity()

    assert(e:insert(f1))
    assert(e:insert(f2))

    assert(e:is_alive())
    assert(e.__chunk == evo.registry.chunk(f1, f2))

    assert(e:destroy())
    assert(not e:is_alive())
    assert(e.__chunk == nil)

    assert(not e:destroy())
    assert(not e:is_alive())
    assert(e.__chunk == nil)
end

do
    local f1, f2, f3, f4, f5 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    local e = evo.registry.entity()

    assert(e:insert(f1, f1:guid()))
    assert(e:insert(f2, f2:guid()))
    assert(e:insert(f3, f3:guid()))
    assert(e:insert(f4, f4:guid()))

    assert(e:remove(f1, f2, f5))

    assert(e.__chunk == evo.registry.chunk(f3, f4))
end

do
    local f = evo.registry.entity()
    local e = evo.registry.entity()

    assert(not e:assign(f, 42))

    assert(e:get(f) == nil)
    assert(e:get(f, 42) == 42)

    assert(e:insert(f, 84))

    assert(e:get(f) == 84)
    assert(e:get(f, 42) == 84)

    assert(not e:insert(f, 42))
    assert(e:get(f) == 42)

    assert(e:assign(f))
    assert(e:get(f) == true)

    e:assign(f, 21)
    assert(e:get(f) == 21)
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()

    local e = evo.registry.entity()

    e:insert(f1, f1.__guid)
    assert(e.__chunk == evo.registry.chunk(f1))

    do
        local chunk_f1 = evo.registry.chunk(f1)
        assert(#chunk_f1.__entities == 1)
        assert(#chunk_f1.__components[f1] == 1)
    end

    e:insert(f2, f2.__guid)
    assert(e.__chunk == evo.registry.chunk(f1, f2))

    do
        local chunk_f1 = evo.registry.chunk(f1)
        assert(#chunk_f1.__entities == 0)
        assert(#chunk_f1.__components[f1] == 0)

        local chunk_f1_f2 = evo.registry.chunk(f1, f2)
        assert(#chunk_f1_f2.__entities == 1)
        assert(#chunk_f1_f2.__components[f1] == 1)
        assert(#chunk_f1_f2.__components[f2] == 1)
    end

    e:remove(f1)
    assert(e.__chunk == evo.registry.chunk(f2))

    do
        local chunk_f1 = evo.registry.chunk(f1)
        assert(#chunk_f1.__entities == 0)
        assert(#chunk_f1.__components[f1] == 0)

        local chunk_f2 = evo.registry.chunk(f2)
        assert(#chunk_f2.__entities == 1)
        assert(#chunk_f2.__components[f2] == 1)

        local chunk_f1_f2 = evo.registry.chunk(f1, f2)
        assert(#chunk_f1_f2.__entities == 0)
        assert(#chunk_f1_f2.__components[f1] == 0)
        assert(#chunk_f1_f2.__components[f2] == 0)
    end
end

for _ = 1, 100 do
    local insert_fragments = {} ---@type evolved.entity[]
    local insert_fragment_count = math.random(0, 10)

    for _ = 1, insert_fragment_count do
        local fragment = evo.registry.entity()
        table.insert(insert_fragments, fragment)
    end

    local remove_fragments = {} ---@type evolved.entity[]
    local remove_fragment_count = math.random(0, insert_fragment_count)

    for _ = 1, remove_fragment_count do
        local fragment = insert_fragments[math.random(1, #insert_fragments)]
        table.insert(remove_fragments, fragment)
    end

    ---@param array any[]
    local function shuffle_array(array)
        for i = #array, 2, -1 do
            local j = math.random(i)
            array[i], array[j] = array[j], array[i]
        end
    end

    local entities = {} ---@type evolved.entity[]

    for _ = 1, 100 do
        local e1, e2 = evo.registry.entity(), evo.registry.entity()
        table.insert(entities, e1)
        table.insert(entities, e2)

        shuffle_array(insert_fragments)
        for _, f in ipairs(insert_fragments) do
            e1:insert(f, f.__guid)
        end

        shuffle_array(insert_fragments)
        for _, f in ipairs(insert_fragments) do
            e2:insert(f, f.__guid)
        end

        assert(e1.__chunk == e2.__chunk)
        assert(e1:has_all(evo.compat.unpack(insert_fragments)))
        assert(e2:has_all(evo.compat.unpack(insert_fragments)))

        shuffle_array(remove_fragments)
        for _, f in ipairs(remove_fragments) do
            if e1:has(f) then
                e1:remove(f)
            end
        end

        shuffle_array(remove_fragments)
        for _, f in ipairs(remove_fragments) do
            if e2:has(f) then
                e2:remove(f)
            end
        end

        assert(e1.__chunk == e2.__chunk)
        assert(not e1:has_any(evo.compat.unpack(remove_fragments)))
        assert(not e2:has_any(evo.compat.unpack(remove_fragments)))

        if e1.__chunk ~= nil then
            for f, _ in pairs(e1.__chunk.__components) do
                assert(e1:get(f) == f.__guid)
                assert(e2:get(f) == f.__guid)
            end
        end
    end
end

do
    local f1, f2, f3 = evo.registry.entity(), evo.registry.entity(), evo.registry.entity()

    local e1 = evo.registry.entity()
    e1:insert(f1)

    local e2 = evo.registry.entity()
    e2:insert(f1)
    e2:insert(f2)

    local e3 = evo.registry.entity()
    e3:insert(f1)
    e3:insert(f2)
    e3:insert(f3)

    do
        local e = evo.registry.entity()

        e:insert(f1)
        e:remove(f1)

        e:insert(f1)
        e:insert(f2)
        e:remove(f1)
        e:remove(f2)

        e:insert(f1)
        e:insert(f2)
        e:insert(f3)
        e:remove(f1)
        e:remove(f2)
        e:remove(f3)
    end

    local q1 = evo.registry.query(f1)
    local q2 = evo.registry.query(f1, f2)
    local q3 = evo.registry.query(f1, f2, f3)

    ---@param query evolved.query
    ---@return evolved.entity[]
    ---@nodiscard
    local function collect_query_entities(query)
        local entities = {} ---@type evolved.entity[]
        for chunk in query:execute() do
            for _, e in ipairs(chunk:entities()) do
                table.insert(entities, e)
            end
        end
        return entities
    end

    ---@param array1 any[]
    ---@param array2 any[]
    ---@return boolean
    ---@nodiscard
    local function is_array_equal(array1, array2)
        if #array1 ~= #array2 then
            return false
        end
        for i = 1, #array1 do
            if array1[i] ~= array2[i] then
                return false
            end
        end
        return true
    end

    assert(is_array_equal(collect_query_entities(q1), { e1, e2, e3 }))
    assert(is_array_equal(collect_query_entities(q2), { e2, e3 }))
    assert(is_array_equal(collect_query_entities(q3), { e3 }))
end
