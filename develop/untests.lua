local evolved = require 'evolved'

local iterators = require 'develop.iterators'
local utilities = require 'develop.utilities'

---@param name string
---@param func fun(...):...
---@param ... any
local function describe(name, func, ...)
    collectgarbage('stop')

    print(string.format('| untests | %s ...', name))

    local start_s = os.clock()
    local start_kb = collectgarbage('count')

    local success, result = pcall(func, ...)

    local finish_s = os.clock() - start_s
    local finish_kb = collectgarbage('count') - start_kb

    print(string.format('    %s | ms: %.2f | mb: %.2f',
        success and 'OK' or 'FAILED', finish_s * 1000, finish_kb / 1024))

    if not success then print('    ' .. result) end

    collectgarbage('restart')
end

describe('entity:entity', function()
    for _ = 1, 500 do
        local registry = evolved.registry()

        ---@type evolved.entity[]
        local all_fragments = {}
        local all_fragment_count = math.random(1, 10)
        for i = 1, all_fragment_count do all_fragments[i] = registry:entity() end

        for _ = 1, 100 do
            ---@type evolved.entity[]
            local insert_fragments = {}
            local insert_fragment_count = math.random(1, 10)
            for i = 1, insert_fragment_count do insert_fragments[i] = all_fragments[math.random(1, all_fragment_count)] end

            local e1 = registry:entity()
            for _, fragment in ipairs(insert_fragments) do e1:insert(fragment) end

            local e2 = registry:entity(unpack(insert_fragments))

            assert(e1.chunk == e2.chunk)
        end
    end
end)

describe('entity:chunk', function()
    for _ = 1, 500 do
        local registry = evolved.registry()

        ---@type evolved.entity[]
        local all_fragments = {}
        local all_fragment_count = math.random(1, 10)
        for i = 1, all_fragment_count do all_fragments[i] = registry:entity() end

        for _ = 1, 100 do
            local e1, e2 = registry:entity(), registry:entity()

            ---@type evolved.entity[]
            local insert_fragments = {}
            local insert_fragment_count = math.random(1, 10)
            for i = 1, insert_fragment_count do insert_fragments[i] = all_fragments[math.random(1, all_fragment_count)] end

            ---@type evolved.entity[]
            local remove_fragments = {}
            local remove_fragment_count = math.random(1, 10)
            for i = 1, remove_fragment_count do remove_fragments[i] = all_fragments[math.random(1, all_fragment_count)] end

            utilities.shuffle_array(insert_fragments)
            for _, fragment in ipairs(insert_fragments) do e1:insert(fragment) end

            utilities.shuffle_array(insert_fragments)
            for _, fragment in ipairs(insert_fragments) do e2:insert(fragment) end

            assert(e1.chunk == e2.chunk)

            utilities.shuffle_array(remove_fragments)
            for _, fragment in ipairs(remove_fragments) do e1:remove(fragment) end

            utilities.shuffle_array(remove_fragments)
            for _, fragment in ipairs(remove_fragments) do e2:remove(fragment) end

            assert(e1.chunk == e2.chunk)
        end
    end
end)

describe('query:chunks', function()
    for _ = 1, 500 do
        local registry = evolved.registry()

        ---@type evolved.entity[]
        local all_fragments = {}
        local all_fragment_count = math.random(1, 10)
        for i = 1, all_fragment_count do all_fragments[i] = registry:entity() end

        local function check_all_queries()
            for _, q in ipairs(registry.queries) do
                local query_chunk_count = iterators.count(q:chunks())
                local registry_chunk_count = iterators.count(iterators.filter(
                    iterators.values(registry.chunks),
                    function(chunk) return chunk:has_all_fragments(unpack(q.fragments)) end))
                assert(query_chunk_count == registry_chunk_count)
            end
        end

        ---@param n integer
        local function create_queries(n)
            for _ = 1, n do
                ---@type evolved.entity[]
                local query_fragments = {}
                local query_fragment_count = math.random(1, 5)
                for i = 1, query_fragment_count do
                    query_fragments[i] = all_fragments[math.random(1, all_fragment_count)]
                end

                registry:query(unpack(query_fragments))
            end
        end

        ---@param n integer
        local function create_entities(n)
            for _ = 1, n do
                ---@type evolved.entity[]
                local insert_fragments = {}
                local insert_fragment_count = math.random(1, 10)
                for i = 1, insert_fragment_count do
                    insert_fragments[i] = all_fragments[math.random(1, all_fragment_count)]
                end

                local e = registry:entity()
                for _, fragment in ipairs(insert_fragments) do e:insert(fragment) end
            end
        end

        create_entities(50)
        create_queries(10)
        check_all_queries()

        create_entities(50)
        create_queries(10)
        check_all_queries()
    end
end)
