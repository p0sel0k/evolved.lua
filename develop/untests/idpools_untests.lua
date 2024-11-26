---@diagnostic disable: invisible
local evo = require 'evolved.evolved'

do
    local p1 = evo.idpools.idpool()
    local p2 = evo.idpools.idpool()
    assert(p1 ~= p2)
end

do
    local p = evo.idpools.idpool()

    local i1_1 = p:acquire()
    assert(i1_1 == 0x100001)

    local i2_1 = p:acquire()
    assert(i2_1 == 0x100002)

    do
        local i, v = p.unpack(i1_1)
        assert(i == 1 and v == 1)
    end

    do
        local i, v = p.unpack(i2_1)
        assert(i == 2 and v == 1)
    end
end

do
    local p = evo.idpools.idpool()

    local i1_1 = p:acquire()
    local i2_1 = p:acquire()
    assert(p:alive(i1_1))
    assert(p:alive(i2_1))

    p:release(i1_1)
    assert(not p:alive(i1_1))
    assert(p:alive(i2_1))

    p:release(i2_1)
    assert(not p:alive(i1_1))
    assert(not p:alive(i2_1))

    local i2_2 = p:acquire()
    assert(i2_2 == 0x200002)

    local i1_2 = p:acquire()
    assert(i1_2 == 0x200001)

    assert(not p:alive(i1_1))
    assert(not p:alive(i2_1))
    assert(p:alive(i1_2))
    assert(p:alive(i2_2))
end

do
    local p = evo.idpools.idpool()

    for _ = 1, 0xFFFFF - 1 do
        _ = p:acquire()
    end

    assert(p:acquire() == 0x1FFFFF)

    if not os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") then
        assert(not pcall(evo.idpools.acquire, p))
    end
end

do
    local p = evo.idpools.idpool()

    for _ = 1, 0x7FF - 1 do
        p:release(p:acquire())
    end

    local i1_7FF = p:acquire()
    assert(i1_7FF == 0x7FF00001)
    p:release(i1_7FF)

    local i1_1 = p:acquire()
    assert(i1_1 == 0x100001)
    p:release(i1_1)
end

for _ = 1, 100 do
    local o_index = math.random(0xFFFFF)
    local o_version = math.random(0x7FF)

    local id = evo.idpools.pack(o_index, o_version)

    local r_index, r_version = evo.idpools.unpack(id)

    assert(o_index == r_index)
    assert(o_version == r_version)
end
