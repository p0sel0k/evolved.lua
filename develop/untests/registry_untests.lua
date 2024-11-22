local evo = require 'evolved.evolved'

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()

    local e = evo.registry.entity()
    assert(e.chunk == nil)

    evo.registry.insert(e, f1)
    assert(evo.registry.has(e, f1))
    assert(not evo.registry.has(e, f2))

    evo.registry.insert(e, f2)
    assert(evo.registry.has(e, f1))
    assert(evo.registry.has(e, f2))

    evo.registry.remove(e, f1)
    assert(not evo.registry.has(e, f1))
    assert(evo.registry.has(e, f2))

    evo.registry.remove(e, f2)
    assert(not evo.registry.has(e, f1))
    assert(not evo.registry.has(e, f2))
end

do
    local f = evo.registry.entity()
    local e = evo.registry.entity()

    if not os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") then
        assert(not pcall(evo.registry.get, e, f))
        assert(not pcall(evo.registry.assign, e, f, 42))
    end

    assert(evo.registry.get_or(e, f) == nil)
    assert(evo.registry.get_or(e, f, 42) == 42)

    evo.registry.insert(e, f, 84)

    assert(evo.registry.get(e, f) == 84)
    assert(evo.registry.get_or(e, f) == 84)
    assert(evo.registry.get_or(e, f, 42) == 84)

    if not os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") then
        assert(not pcall(evo.registry.insert, e, f, 42))
    end

    evo.registry.assign(e, f)
    assert(evo.registry.get(e, f) == true)

    evo.registry.assign(e, f, 21)
    assert(evo.registry.get(e, f) == 21)
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()

    local e = evo.registry.entity()

    evo.registry.insert(e, f1, f1.guid)
    assert(e.chunk == evo.registry.chunk(f1))

    do
        local chunk_f1 = evo.registry.chunk(f1)
        assert(#chunk_f1.entities == 1)
        assert(#chunk_f1.components[f1] == 1)
    end

    evo.registry.insert(e, f2, f2.guid)
    assert(e.chunk == evo.registry.chunk(f1, f2))

    do
        local chunk_f1 = evo.registry.chunk(f1)
        assert(#chunk_f1.entities == 0)
        assert(#chunk_f1.components[f1] == 0)

        local chunk_f1_f2 = evo.registry.chunk(f1, f2)
        assert(#chunk_f1_f2.entities == 1)
        assert(#chunk_f1_f2.components[f1] == 1)
        assert(#chunk_f1_f2.components[f2] == 1)
    end

    evo.registry.remove(e, f1)
    assert(e.chunk == evo.registry.chunk(f2))

    do
        local chunk_f1 = evo.registry.chunk(f1)
        assert(#chunk_f1.entities == 0)
        assert(#chunk_f1.components[f1] == 0)

        local chunk_f2 = evo.registry.chunk(f2)
        assert(#chunk_f2.entities == 1)
        assert(#chunk_f2.components[f2] == 1)

        local chunk_f1_f2 = evo.registry.chunk(f1, f2)
        assert(#chunk_f1_f2.entities == 0)
        assert(#chunk_f1_f2.components[f1] == 0)
        assert(#chunk_f1_f2.components[f2] == 0)
    end
end

for _ = 1, 100 do
    local insert_fragments = {} ---@type evolved.entity[]
    local insert_fragment_count = math.random(1, 10)

    for _ = 1, insert_fragment_count do
        local fragment = evo.registry.entity()
        table.insert(insert_fragments, fragment)
    end

    local remove_fragments = {} ---@type evolved.entity[]
    local remove_fragment_count = math.random(1, insert_fragment_count)

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
            evo.registry.insert(e1, f, f.guid)
        end

        shuffle_array(insert_fragments)
        for _, f in ipairs(insert_fragments) do
            evo.registry.insert(e2, f, f.guid)
        end

        assert(e1.chunk == e2.chunk)
        assert(evo.registry.has_all(e1, unpack(insert_fragments)))
        assert(evo.registry.has_all(e2, unpack(insert_fragments)))

        shuffle_array(remove_fragments)
        for _, f in ipairs(remove_fragments) do
            if evo.registry.has(e1, f) then
                evo.registry.remove(e1, f)
            end
        end

        shuffle_array(remove_fragments)
        for _, f in ipairs(remove_fragments) do
            if evo.registry.has(e2, f) then
                evo.registry.remove(e2, f)
            end
        end

        assert(e1.chunk == e2.chunk)
        assert(not evo.registry.has_any(e1, unpack(remove_fragments)))
        assert(not evo.registry.has_any(e2, unpack(remove_fragments)))

        if e1.chunk ~= nil then
            for f, _ in pairs(e1.chunk.components) do
                assert(evo.registry.get(e1, f) == f.guid)
                assert(evo.registry.get(e2, f) == f.guid)
            end
        end
    end
end

do
    local f1, f2, f3 = evo.registry.entity(), evo.registry.entity(), evo.registry.entity()

    local e1 = evo.registry.entity()
    evo.registry.insert(e1, f1)

    local e2 = evo.registry.entity()
    evo.registry.insert(e2, f1)
    evo.registry.insert(e2, f2)

    local e3 = evo.registry.entity()
    evo.registry.insert(e3, f1)
    evo.registry.insert(e3, f2)
    evo.registry.insert(e3, f3)

    do
        local e = evo.registry.entity()

        evo.registry.insert(e, f1)
        evo.registry.remove(e, f1)

        evo.registry.insert(e, f1)
        evo.registry.insert(e, f2)
        evo.registry.remove(e, f1)
        evo.registry.remove(e, f2)

        evo.registry.insert(e, f1)
        evo.registry.insert(e, f2)
        evo.registry.insert(e, f3)
        evo.registry.remove(e, f1)
        evo.registry.remove(e, f2)
        evo.registry.remove(e, f3)
    end

    local q1 = evo.registry.query(f1)
    local q2 = evo.registry.query(f1, f2)
    local q3 = evo.registry.query(f1, f2, f3)

    ---@param query evolved.query
    ---@return evolved.entity[]
    ---@nodiscard
    local function collect_query_entities(query)
        local entities = {} ---@type evolved.entity[]
        for chunk in evo.registry.execute(query) do
            for _, e in ipairs(chunk.entities) do
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
