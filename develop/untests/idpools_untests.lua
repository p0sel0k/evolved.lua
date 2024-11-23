---@diagnostic disable: invisible
local evo = require 'evolved.evolved'

do
    local p1 = evo.idpools.idpool()
    local p2 = evo.idpools.idpool()
    assert(p1 ~= p2)
end

do
    local p = evo.idpools.idpool()

    local i1_1 = evo.idpools.acquire_id(p)
    assert(i1_1 == 0x100001)

    local i2_1 = evo.idpools.acquire_id(p)
    assert(i2_1 == 0x100002)

    do
        local i, v = evo.idpools.unpack_id(i1_1)
        assert(i == 1 and v == 1)
    end

    do
        local i, v = evo.idpools.unpack_id(i2_1)
        assert(i == 2 and v == 1)
    end
end

do
    local p = evo.idpools.idpool()

    local i1_1 = evo.idpools.acquire_id(p)
    local i2_1 = evo.idpools.acquire_id(p)
    assert(evo.idpools.is_id_alive(p, i1_1))
    assert(evo.idpools.is_id_alive(p, i2_1))

    evo.idpools.release_id(p, i1_1)
    assert(not evo.idpools.is_id_alive(p, i1_1))
    assert(evo.idpools.is_id_alive(p, i2_1))

    evo.idpools.release_id(p, i2_1)
    assert(not evo.idpools.is_id_alive(p, i1_1))
    assert(not evo.idpools.is_id_alive(p, i2_1))

    local i2_2 = evo.idpools.acquire_id(p)
    assert(i2_2 == 0x200002)

    local i1_2 = evo.idpools.acquire_id(p)
    assert(i1_2 == 0x200001)

    assert(not evo.idpools.is_id_alive(p, i1_1))
    assert(not evo.idpools.is_id_alive(p, i2_1))
    assert(evo.idpools.is_id_alive(p, i1_2))
    assert(evo.idpools.is_id_alive(p, i2_2))
end

do
    local p = evo.idpools.idpool()

    for _ = 1, 0xFFFFF - 1 do
        _ = evo.idpools.acquire_id(p)
    end

    assert(evo.idpools.acquire_id(p) == 0x1FFFFF)

    if not os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") then
        assert(not pcall(evo.idpools.acquire_id, p))
    end
end

do
    local p = evo.idpools.idpool()

    for _ = 1, 0x7FF - 1 do
        evo.idpools.release_id(p, evo.idpools.acquire_id(p))
    end

    local i1_7FF = evo.idpools.acquire_id(p)
    assert(i1_7FF == 0x7FF00001)
    evo.idpools.release_id(p, i1_7FF)

    local i1_1 = evo.idpools.acquire_id(p)
    assert(i1_1 == 0x100001)
    evo.idpools.release_id(p, i1_1)
end
