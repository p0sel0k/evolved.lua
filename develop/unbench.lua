local evo = require 'evolved.evolved'

---@param name string
---@param loop fun(...): ...
---@param init fun(): ...
local function describe(name, loop, init)
    collectgarbage('stop')

    print(string.format('| %s ... |', name))

    local state = evo.compat.pack(init())

    local iters = 0
    local start_s = os.clock()
    local start_kb = collectgarbage('count')

    local success, result = pcall(function()
        while os.clock() - start_s < 1.0 do
            iters = iters + 1
            loop(evo.compat.unpack(state))
        end
    end)

    local finish_s = os.clock()
    local finish_kb = collectgarbage('count')

    print(string.format('    %s | us: %.2f | op/s: %.2f | kb/i: %.2f',
        success and 'OK' or 'FAILED',
        (finish_s - start_s) * 1000 * 1000 / iters,
        iters / (finish_s - start_s),
        (finish_kb - start_kb) / iters))

    if not success then print('    ' .. result) end

    collectgarbage('restart')
end

---@param a evolved.entity
---@param b evolved.entity
---@param c evolved.entity
---@param d evolved.entity
---@param e evolved.entity
---@param A evolved.query
---@param B evolved.query
---@param C evolved.query
---@param D evolved.query
---@param E evolved.query
describe('Packed Iteration', function(a, b, c, d, e, A, B, C, D, E)
    for chunk in A:execute() do
        local as = chunk:components(a)
        for i = 1, #chunk:entities() do
            as[i] = as[i] * 2
        end
    end

    for chunk in B:execute() do
        local bs = chunk:components(b)
        for i = 1, #chunk:entities() do
            bs[i] = bs[i] * 2
        end
    end

    for chunk in C:execute() do
        local cs = chunk:components(c)
        for i = 1, #chunk:entities() do
            cs[i] = cs[i] * 2
        end
    end

    for chunk in D:execute() do
        local ds = chunk:components(d)
        for i = 1, #chunk:entities() do
            ds[i] = ds[i] * 2
        end
    end

    for chunk in E:execute() do
        local es = chunk:components(e)
        for i = 1, #chunk:entities() do
            es[i] = es[i] * 2
        end
    end
end, function()
    local A, B, C, D, E =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    for _ = 1, 1000 do
        evo.registry.entity()
            :set(A, 0)
            :set(B, 0)
            :set(C, 0)
            :set(D, 0)
            :set(E, 0)
    end

    return
        A, B, C, D, E,
        evo.registry.query(A),
        evo.registry.query(B),
        evo.registry.query(C),
        evo.registry.query(D),
        evo.registry.query(E)
end)

describe('Simple Iteration', function(a, b, c, d, e, AB, CD, CE)
    for chunk in AB:execute() do
        local as, bs = chunk:components(a, b)
        for i = 1, #chunk:entities() do
            as[i], bs[i] = bs[i], as[i]
        end
    end

    for chunk in CD:execute() do
        local cs, ds = chunk:components(c, d)
        for i = 1, #chunk:entities() do
            cs[i], ds[i] = ds[i], cs[i]
        end
    end

    for chunk in CE:execute() do
        local cs, es = chunk:components(c, e)
        for i = 1, #chunk:entities() do
            cs[i], es[i] = es[i], cs[i]
        end
    end
end, function()
    local A, B, C, D, E =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    for _ = 1, 1000 do
        evo.registry.entity():set(A, 0):set(B, 0)
        evo.registry.entity():set(A, 0):set(B, 0):set(C, 0)
        evo.registry.entity():set(A, 0):set(B, 0):set(C, 0):set(D, 0)
        evo.registry.entity():set(A, 0):set(B, 0):set(C, 0):set(E, 0)
    end

    return A, B, C, D, E,
        evo.registry.query(A, B),
        evo.registry.query(C, D),
        evo.registry.query(C, E)
end)

---@param d evolved.entity
---@param z evolved.entity
---@param D evolved.query
---@param Z evolved.query
describe('Fragmented Iteration', function(d, z, D, Z)
    for chunk in D:execute() do
        local ds = chunk:components(d)
        for i = 1, #chunk:entities() do
            ds[i] = ds[i] * 2
        end
    end

    for chunk in Z:execute() do
        local zs = chunk:components(z)
        for i = 1, #chunk:entities() do
            zs[i] = zs[i] * 2
        end
    end
end, function()
    local cs, d = {}, evo.registry.entity()
    for i = 1, 26 do cs[i] = evo.registry.entity() end

    for i = 1, #cs do
        for _ = 1, 100 do
            evo.registry.entity():set(cs[i], 0):set(d, 0)
        end
    end

    return d, cs[#cs],
        evo.registry.query(d),
        evo.registry.query(cs[#cs])
end)

---@param a evolved.entity
---@param b evolved.entity
---@param A evolved.query
---@param B evolved.query
describe('Entity Cycle', function(a, b, A, B)
    ---@type any[]
    local to_create = {}

    for chunk in A:execute() do
        local as = chunk:components(a)
        for i = 1, #chunk:entities() do
            to_create[#to_create + 1] = as[i]
        end
    end

    for i = 1, #to_create do
        evo.registry.entity():set(b, to_create[i])
    end

    ---@type evolved.entity[]
    local to_destroy = {}

    for chunk in B:execute() do
        local es = chunk:entities()
        for i = 1, #es do
            to_destroy[#to_destroy + 1] = es[i]
        end
    end

    for i = 1, #to_destroy do
        evo.registry.destroy(to_destroy[i])
    end
end, function()
    local a, b =
        evo.registry.entity(),
        evo.registry.entity()

    for _ = 1, 1000 do
        evo.registry.entity():set(a, 0)
    end

    return a, b,
        evo.registry.query(a),
        evo.registry.query(b)
end)

---@param a evolved.entity
---@param b evolved.entity
---@param A evolved.query
---@param AB evolved.query
describe('Add / Remove', function(a, b, A, AB)
    ---@type evolved.entity[]
    local to_change = {}

    for chunk in A:execute() do
        local es = chunk:entities()
        for i = 1, #es do
            to_change[#to_change + 1] = es[i]
        end
    end

    for i = 1, #to_change do
        to_change[i]:set(b)
    end

    ---@type evolved.entity[]
    local to_remove = {}

    for chunk in AB:execute() do
        local es = chunk:entities()
        for i = 1, #es do
            to_remove[#to_remove + 1] = es[i]
        end
    end

    for i = 1, #to_remove do
        to_remove[i]:remove(b)
    end
end, function()
    local a, b =
        evo.registry.entity(),
        evo.registry.entity()

    for _ = 1, 1000 do
        evo.registry.entity():set(a)
    end

    return a, b,
        evo.registry.query(a),
        evo.registry.query(b)
end)
