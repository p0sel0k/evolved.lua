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
    local f1, f2, f3 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    local e = evo.registry.entity()
    assert(e == e:set(f1):set(f2):set(f3))
    assert(e:has_all(f1, f2, f3))
    assert(e == e:del():del(f1))
    assert(not e:has(f1) and e:has_all(f2, f3))
    assert(e == e:del(f2, f3, f3))
    assert(not e:has_any(f1, f2, f3))
end

do
    local f1, f2, f3, f4, f5 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    local e = evo.registry.entity()
    assert(e == e:set(f1, 1):set(f2, 2))

    do
        assert(nil == e:get())

        local c1 = e:get(f1)
        assert(c1 == 1)

        local c3 = e:get(f3)
        assert(c3 == nil)

        local c4, c5 = e:get(f4, f5)
        assert(c4 == nil and c5 == nil)
    end

    do
        local c1, c2 = e:get(f1, f2)
        assert(c1 == 1 and c2 == 2)
    end

    do
        local c2, c1 = e:get(f2, f1)
        assert(c1 == 1 and c2 == 2)
    end

    do
        local c3, c4, c1, c2 = e:get(f3, f4, f1, f2)
        assert(c1 == 1 and c2 == 2 and c3 == nil and c4 == nil)
    end

    assert(e == e:set(f3, 3):set(f4, 4))

    do
        local c4, c3, c2 = e:get(f4, f3, f2)
        assert(c2 == 2 and c3 == 3 and c4 == 4)
    end

    do
        local c1, c2, c3, c4 = e:get(f1, f2, f3, f4)
        assert(c1 == 1 and c2 == 2 and c3 == 3 and c4 == 4)
    end

    do
        local c5, c1, c2, c3, c4 = e:get(f5, f1, f2, f3, f4)
        assert(c1 == 1 and c2 == 2 and c3 == 3 and c4 == 4 and c5 == nil)
    end

    assert(e == e:set(f5, false))

    do
        local c5, c1, c2, c3, c4 = e:get(f5, f1, f2, f3, f4)
        assert(c1 == 1 and c2 == 2 and c3 == 3 and c4 == 4 and c5 == false)
    end
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
    assert(not e:has(f))
    assert(e:get_or(f) == nil)
    assert(e:get_or(f, 42) == 42)

    assert(e:insert(f, 84))
    assert(e:has(f))
    assert(e:get_or(f) == 84)
    assert(e:get_or(f, 42) == 84)

    assert(not e:insert(f, 21))
    assert(e:has(f))
    assert(e:get_or(f) == 84)
    assert(e:get_or(f, 42) == 84)

    assert(e:assign(f))
    assert(e:has(f))
    assert(e:get_or(f) == true)
    assert(e:get_or(f, 42) == true)

    assert(e:assign(f, 21))
    assert(e:has(f))
    assert(e:get_or(f) == 21)
    assert(e:get_or(f, 42) == 21)
end

do
    local f = evo.registry.entity()

    do
        local e = evo.registry.entity()

        assert(e == e:set(f, 42))
        assert(e:get_or(f) == 42)

        assert(e == e:set(f, 21))
        assert(e:get_or(f) == 21)
    end

    do
        local e = evo.registry.entity()

        assert(not e:assign(f, 42))
        assert(e:get_or(f) == nil)

        assert(e:insert(f, 42))
        assert(e:get_or(f) == 42)

        assert(e:assign(f, 21))
        assert(e:get_or(f) == 21)

        assert(not e:insert(f, 42))
        assert(e:get_or(f) == 21)
    end
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()
    local e = evo.registry.entity()

    assert(e:insert(f1))
    assert(e:insert(f2))
    assert(e:is_alive())
    assert(e.__chunk == evo.registry.chunk(f1, f2))

    assert(e == e:detach())
    assert(e:is_alive())
    assert(e.__chunk == nil)

    assert(e == e:detach())
    assert(e:is_alive())
    assert(e.__chunk == nil)
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

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()

    local e = evo.registry.entity()
    assert(e:insert(f1))
    assert(e:is_alive())
    assert(e.__chunk == evo.registry.chunk(f1))

    assert(e:destroy())
    assert(not e:is_alive())
    assert(e.__chunk == nil)

    assert(not e:assign(f1, 42))
    assert(not e:assign(f2, 42))
    assert(not e:is_alive())
    assert(e.__chunk == nil)

    assert(not e:insert(f1, 42))
    assert(not e:insert(f2, 42))
    assert(not e:is_alive())
    assert(e.__chunk == nil)

    assert(not e:remove(f1, 42))
    assert(not e:remove(f2, 42))
    assert(not e:is_alive())
    assert(e.__chunk == nil)

    assert(e == e:detach())
    assert(not e:is_alive())
    assert(e.__chunk == nil)
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
        e1:remove(evo.compat.unpack(remove_fragments))

        shuffle_array(remove_fragments)
        for _, f in ipairs(remove_fragments) do
            e2:remove(f)
        end

        assert(e1.__chunk == e2.__chunk)
        assert(not e1:has_any(evo.compat.unpack(remove_fragments)))
        assert(not e2:has_any(evo.compat.unpack(remove_fragments)))

        if e1.__chunk ~= nil then
            for f, _ in pairs(e1.__chunk.__components) do
                assert(e1:get_or(f) == f.__guid)
                assert(e2:get_or(f) == f.__guid)
            end
        end
    end
end

do
    local f1, f2, f3, f4 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    local e1 = evo.registry.entity():set(f1)
    local e2 = evo.registry.entity():set(f1):set(f2)
    local e3 = evo.registry.entity():set(f1):set(f2):set(f3)

    local e4 = evo.registry.entity():set(f1):set(f4)
    local e5 = evo.registry.entity():set(f1):set(f2):set(f4)
    local e6 = evo.registry.entity():set(f1):set(f2):set(f3):set(f4)

    local q0 = evo.registry.query()
    local q1 = evo.registry.query(f1)
    local q2 = evo.registry.query(f1, f2, f1)
    local q3 = evo.registry.query(f1, f2, f3, f3)

    ---@param query evolved.query
    ---@return evolved.entity[]
    ---@nodiscard
    local function collect_entity_sorted_list(query)
        local entities = {} ---@type evolved.entity[]
        for chunk in query:execute() do
            for _, e in ipairs(chunk:entities()) do
                table.insert(entities, e)
            end
        end
        table.sort(entities, function(a, b)
            return a.__guid < b.__guid
        end)
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

    assert(is_array_equal(q0.__include_list, {}))
    assert(is_array_equal(q1.__include_list, { f1 }))
    assert(is_array_equal(q2.__include_list, { f1, f2 }))
    assert(is_array_equal(q3.__include_list, { f1, f2, f3 }))

    assert(is_array_equal(collect_entity_sorted_list(q0), {}))
    assert(is_array_equal(collect_entity_sorted_list(q1), { e1, e2, e3, e4, e5, e6 }))
    assert(is_array_equal(collect_entity_sorted_list(q2), { e2, e3, e5, e6 }))
    assert(is_array_equal(collect_entity_sorted_list(q3), { e3, e6 }))
end

do
    local f1, f2, f3, f4, f5 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    local query = evo.registry.query(f1, f1)
    assert(query == query:include(f2, f3, f2))
    assert(query == query:exclude(f4, f5, f5))

    ---@param q evolved.query
    ---@param f evolved.entity
    ---@return boolean
    ---@nodiscard
    local function includes(q, f)
        for _, qf in ipairs(q.__include_list) do
            if qf:guid() == f:guid() then
                return true
            end
        end
        return false
    end

    ---@param q evolved.query
    ---@param f evolved.entity
    ---@return boolean
    ---@nodiscard
    local function excludes(q, f)
        for _, qf in ipairs(q.__exclude_list) do
            if qf:guid() == f:guid() then
                return true
            end
        end
        return false
    end

    assert(includes(query, f1) and includes(query, f2) and includes(query, f3))
    assert(not includes(query, f4) and not includes(query, f5))
    assert(excludes(query, f4) and excludes(query, f5))
    assert(not excludes(query, f1) and not excludes(query, f2) and not excludes(query, f3))
end

for _ = 1, 100 do
    local all_fragments = {} ---@type evolved.entity[]
    local all_fragment_count = math.random(10, 20)

    local half_fragment_count = math.floor(all_fragment_count / 2)
    local quarter_fragment_count = math.floor(all_fragment_count / 4)

    for _ = 1, all_fragment_count do
        table.insert(all_fragments, evo.registry.entity())
    end

    ---@param array any[]
    local function shuffle_array(array)
        for i = #array, 2, -1 do
            local j = math.random(i)
            array[i], array[j] = array[j], array[i]
        end
    end

    ---@param query evolved.query
    ---@return table<evolved.entity, boolean>
    ---@nodiscard
    local function collect_entity_set(query)
        local entities = {} ---@type table<evolved.entity, boolean>
        for chunk in query:execute() do
            for _, e in ipairs(chunk:entities()) do
                entities[e] = true
            end
        end
        return entities
    end

    for _ = 1, 100 do
        shuffle_array(all_fragments)
        local e = evo.registry.entity()
        for i = 1, math.random(1, half_fragment_count) do
            local f = all_fragments[i]
            e:insert(f, f:guid())
        end
    end

    for _ = 1, 100 do
        shuffle_array(all_fragments)
        local inc_fs = evo.compat.pack(evo.compat.unpack(all_fragments, 1, math.random(0, quarter_fragment_count)))
        shuffle_array(all_fragments)
        local exc_fs = evo.compat.pack(evo.compat.unpack(all_fragments, 1, math.random(0, quarter_fragment_count)))

        local inc_q = evo.registry.query(evo.compat.unpack(inc_fs))
        local exc_q = evo.registry.query(evo.compat.unpack(inc_fs)):exclude(evo.compat.unpack(exc_fs))

        local inc_es = collect_entity_set(inc_q)
        local exc_es = collect_entity_set(exc_q)

        for e, _ in pairs(inc_es) do
            assert(e:has_all(evo.compat.unpack(inc_fs)))
            assert(not exc_es[e] == e:has_any(evo.compat.unpack(exc_fs)))
        end

        for e, _ in pairs(exc_es) do
            assert(inc_es[e] ~= nil)
            assert(e:has_all(evo.compat.unpack(inc_fs)))
            assert(not e:has_any(evo.compat.unpack(exc_fs)))
        end
    end
end
