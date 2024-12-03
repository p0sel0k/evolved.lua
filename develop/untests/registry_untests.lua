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

    assert(e:alive())
    assert(e.__chunk == evo.registry.chunk(f1, f2))

    assert(e:destroy())
    assert(not e:alive())
    assert(e.__chunk == nil)

    assert(not e:destroy())
    assert(not e:alive())
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
    assert(e:get(f) == nil)

    assert(e:insert(f, 84))
    assert(e:has(f))
    assert(e:get(f) == 84)

    assert(not e:insert(f, 21))
    assert(e:has(f))
    assert(e:get(f) == 84)

    assert(e:assign(f))
    assert(e:has(f))
    assert(e:get(f) == true)

    assert(e:assign(f, 21))
    assert(e:has(f))
    assert(e:get(f) == 21)
end

do
    local f = evo.registry.entity()

    do
        local e = evo.registry.entity()

        assert(e == e:set(f, 42))
        assert(e:get(f) == 42)

        assert(e == e:set(f, 21))
        assert(e:get(f) == 21)
    end

    do
        local e = evo.registry.entity()

        assert(not e:assign(f, 42))
        assert(e:get(f) == nil)

        assert(e:insert(f, 42))
        assert(e:get(f) == 42)

        assert(e:assign(f, 21))
        assert(e:get(f) == 21)

        assert(not e:insert(f, 42))
        assert(e:get(f) == 21)
    end
end

do
    local f1, f2, f3, f4, f5 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    local chunk = evo.registry.chunk(f1, f2, f3, f4)

    do
        evo.registry.entity():set(f1, 1)
        evo.registry.entity():set(f1, 1):set(f2, 2)
        evo.registry.entity():set(f1, 1):set(f2, 2):set(f3, 3)
        evo.registry.entity():set(f1, 1):set(f2, 2):set(f3, 3):set(f4, 4)
    end

    do
        assert(chunk:components() == nil)
    end

    do
        local fs1 = chunk:components(f1)
        assert(fs1 and fs1[1] == 1)
    end

    do
        local fs1, fs2 = chunk:components(f1, f2)
        assert(fs1 and fs1[1] == 1)
        assert(fs2 and fs2[1] == 2)
    end

    do
        local fs1, fs2, fs3 = chunk:components(f1, f2, f3)
        assert(fs1 and fs1[1] == 1)
        assert(fs2 and fs2[1] == 2)
        assert(fs3 and fs3[1] == 3)
    end

    do
        local fs1, fs2, fs3, fs4 = chunk:components(f1, f2, f3, f4)
        assert(fs1 and fs1[1] == 1)
        assert(fs2 and fs2[1] == 2)
        assert(fs3 and fs3[1] == 3)
        assert(fs4 and fs4[1] == 4)
    end

    do
        local a, fs1, b, fs2, c, fs3, d, fs4, e = chunk:components(f5, f1, f5, f2, f5, f3, f5, f4, f5)
        assert(fs1 and fs1[1] == 1)
        assert(fs2 and fs2[1] == 2)
        assert(fs3 and fs3[1] == 3)
        assert(fs4 and fs4[1] == 4)
        assert(a == nil and b == nil and c == nil and d == nil and e == nil)
    end
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()
    local e = evo.registry.entity()

    assert(e:insert(f1))
    assert(e:insert(f2))
    assert(e:alive())
    assert(e.__chunk == evo.registry.chunk(f1, f2))

    assert(e:detach())
    assert(e:alive())
    assert(e.__chunk == nil)

    assert(not e:detach())
    assert(e:alive())
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
    assert(e:alive())
    assert(e.__chunk == evo.registry.chunk(f1))

    assert(e:destroy())
    assert(not e:alive())
    assert(e.__chunk == nil)

    assert(not e:assign(f1, 42))
    assert(not e:assign(f2, 42))
    assert(not e:alive())
    assert(e.__chunk == nil)

    assert(not e:insert(f1, 42))
    assert(not e:insert(f2, 42))
    assert(not e:alive())
    assert(e.__chunk == nil)

    assert(not e:remove(f1, 42))
    assert(not e:remove(f2, 42))
    assert(not e:alive())
    assert(e.__chunk == nil)

    assert(not e:detach())
    assert(not e:alive())
    assert(e.__chunk == nil)
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()
    local e = evo.registry.entity()

    local function mul2(v) return v * 2 end
    local function null(_) end

    do
        assert(not e:apply(mul2, f1))
        assert(e.__chunk == nil)
        assert(not e:apply(null, f1))
        assert(e.__chunk == nil)

        assert(e:insert(f1, 21))
        assert(e:get(f1) == 21)
        assert(e.__chunk == evo.registry.chunk(f1))

        assert(e:apply(mul2, f1))
        assert(e:get(f1) == 42)
        assert(e.__chunk == evo.registry.chunk(f1))

        assert(e:apply(null, f1))
        assert(e:get(f1) == true)
        assert(e.__chunk == evo.registry.chunk(f1))
    end

    do
        assert(not e:apply(mul2, f2))
        assert(e:get(f1) == true)
        assert(e.__chunk == evo.registry.chunk(f1))
        assert(not e:apply(null, f2))
        assert(e:get(f1) == true)
        assert(e.__chunk == evo.registry.chunk(f1))

        assert(e:insert(f2, 4))
        assert(e:get(f2) == 4)
        assert(e.__chunk == evo.registry.chunk(f1, f2))

        assert(e:apply(mul2, f2))
        assert(e:get(f1) == true)
        assert(e:get(f2) == 8)
        assert(e.__chunk == evo.registry.chunk(f1, f2))

        assert(e:apply(null, f2))
        assert(e:get(f1) == true)
        assert(e:get(f2) == true)
        assert(e.__chunk == evo.registry.chunk(f1, f2))
    end
end

do
    local f1, f2, f3 = evo.registry.entity(), evo.registry.entity(), evo.registry.entity()

    local e1 = evo.registry.entity():set(f1, 10)
    local e2 = evo.registry.entity():set(f1, 15)
    local e3 = evo.registry.entity():set(f1, 20):set(f2, 40)
    local e4 = evo.registry.entity():set(f1, 25):set(f2, 45)

    do
        local q = evo.registry.query(f2)
        local assigned, inserted = q:batch_set(f1, 42)
        assert(assigned == 2 and inserted == 0)
        assert(e1:get(f1) == 10 and e2:get(f1) == 15 and e3:get(f1) == 42 and e4:get(f1) == 42)
        assert(e1:get(f2) == nil and e2:get(f2) == nil and e3:get(f2) == 40 and e4:get(f2) == 45)
    end

    do
        local q = evo.registry.query(f1)
        local assigned, inserted = q:batch_set(f1, 21)
        assert(assigned == 4 and inserted == 0)
        assert(e1:get(f1) == 21 and e2:get(f1) == 21 and e3:get(f1) == 21 and e4:get(f1) == 21)
        assert(e1:get(f2) == nil and e2:get(f2) == nil and e3:get(f2) == 40 and e4:get(f2) == 45)
    end

    do
        local q = evo.registry.query(f1)
        local assigned, inserted = q:batch_set(f2, 84)
        assert(assigned == 2 and inserted == 2)
        assert(e1:get(f1) == 21 and e2:get(f1) == 21 and e3:get(f1) == 21 and e4:get(f1) == 21)
        assert(e1:get(f2) == 84 and e2:get(f2) == 84 and e3:get(f2) == 84 and e4:get(f2) == 84)
    end

    do
        local q = evo.registry.query(f1, f2)
        local assigned, inserted = q:batch_set(f3, 22)
        assert(assigned == 0 and inserted == 4)
        assert(e1:get(f1) == 21 and e2:get(f1) == 21 and e3:get(f1) == 21 and e4:get(f1) == 21)
        assert(e1:get(f2) == 84 and e2:get(f2) == 84 and e3:get(f2) == 84 and e4:get(f2) == 84)
        assert(e1:get(f3) == 22 and e2:get(f3) == 22 and e3:get(f3) == 22 and e4:get(f3) == 22)
    end
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()

    local e1 = evo.registry.entity():set(f1, 10)
    local e2 = evo.registry.entity():set(f1, 15)
    local e3 = evo.registry.entity():set(f1, 20):set(f2, 40)
    local e4 = evo.registry.entity():set(f1, 25):set(f2, 45)

    do
        local q = evo.registry.query(f2)
        assert(2 == q:batch_assign(f1, 42))
        assert(e1:get(f1) == 10 and e2:get(f1) == 15 and e3:get(f1) == 42 and e4:get(f1) == 42)
        assert(e3:get(f2) == 40 and e4:get(f2) == 45)
    end

    do
        local q = evo.registry.query(f1)
        assert(4 == q:batch_assign(f1, 21))
        assert(e1:get(f1) == 21 and e2:get(f1) == 21 and e3:get(f1) == 21 and e4:get(f1) == 21)
        assert(e3:get(f2) == 40 and e4:get(f2) == 45)
    end

    do
        local q = evo.registry.query(f1, f2)
        assert(2 == q:batch_assign(f1, nil))
        assert(e1:get(f1) == 21 and e2:get(f1) == 21 and e3:get(f1) == true and e4:get(f1) == true)
        assert(e3:get(f2) == 40 and e4:get(f2) == 45)
    end

    do
        local q = evo.registry.query(f1)
        assert(2 == q:batch_assign(f2, 42))
        assert(e1:get(f1) == 21 and e2:get(f1) == 21 and e3:get(f1) == true and e4:get(f1) == true)
        assert(e3:get(f2) == 42 and e4:get(f2) == 42)
    end

    do
        local q = evo.registry.query(f1):exclude(f2)
        assert(2 == q:batch_assign(f1, 84))
        assert(e1:get(f1) == 84 and e2:get(f1) == 84 and e3:get(f1) == true and e4:get(f1) == true)
        assert(e3:get(f2) == 42 and e4:get(f2) == 42)
    end
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()

    local function mul2(v) return v * 2 end
    local function null(_) end

    local e1 = evo.registry.entity():set(f1, 10)
    local e2 = evo.registry.entity():set(f1, 15)
    local e3 = evo.registry.entity():set(f1, 20):set(f2, 40)
    local e4 = evo.registry.entity():set(f1, 25):set(f2, 45)

    do
        local q = evo.registry.query(f2)
        assert(2 == q:batch_apply(mul2, f1))
        assert(e1:get(f1) == 10 and e2:get(f1) == 15 and e3:get(f1) == 40 and e4:get(f1) == 50)
        assert(e3:get(f2) == 40 and e4:get(f2) == 45)
    end

    do
        local q = evo.registry.query(f1)
        assert(4 == q:batch_apply(mul2, f1))
        assert(e1:get(f1) == 20 and e2:get(f1) == 30 and e3:get(f1) == 80 and e4:get(f1) == 100)
        assert(e3:get(f2) == 40 and e4:get(f2) == 45)
    end

    do
        local q = evo.registry.query(f1, f2)
        assert(2 == q:batch_apply(null, f1))
        assert(e1:get(f1) == 20 and e2:get(f1) == 30 and e3:get(f1) == true and e4:get(f1) == true)
        assert(e3:get(f2) == 40 and e4:get(f2) == 45)
    end

    do
        local q = evo.registry.query(f1)
        assert(2 == q:batch_apply(mul2, f2))
        assert(e1:get(f1) == 20 and e2:get(f1) == 30 and e3:get(f1) == true and e4:get(f1) == true)
        assert(e3:get(f2) == 80 and e4:get(f2) == 90)
    end

    do
        local q = evo.registry.query(f1):exclude(f2)
        assert(2 == q:batch_apply(mul2, f1))
        assert(e1:get(f1) == 40 and e2:get(f1) == 60 and e3:get(f1) == true and e4:get(f1) == true)
        assert(e3:get(f2) == 80 and e4:get(f2) == 90)
    end
end

do
    local f1, f2 = evo.registry.entity(), evo.registry.entity()

    do
        local e1 = evo.registry.entity():set(f1, 10)
        local e2 = evo.registry.entity():set(f1, 15)
        local e3 = evo.registry.entity():set(f1, 20):set(f2, 40)
        local e4 = evo.registry.entity():set(f1, 25):set(f2, 45)

        local q = evo.registry.query(f1)

        assert(2 == q:batch_insert(f2, 42))
        assert(e1:get(f1) == 10 and e2:get(f1) == 15 and e3:get(f1) == 20 and e4:get(f1) == 25)
        assert(e1:get(f2) == 42 and e2:get(f2) == 42 and e3:get(f2) == 40 and e4:get(f2) == 45)
    end
end

do
    local f1, f2, f3, f4 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    do
        local e1 = evo.registry.entity():set(f1, 10)
        local e2 = evo.registry.entity():set(f1, 15)
        local e3 = evo.registry.entity():set(f1, 20):set(f2, 40):set(f4, 42)
        local e4 = evo.registry.entity():set(f1, 25):set(f2, 45):set(f3, 55)
        local e5 = evo.registry.entity():set(f3, 65)

        do
            local q = evo.registry.query(f2)

            assert(2 == q:batch_remove(f1, f4))
            assert(e1.__chunk == evo.registry.chunk(f1))
            assert(e2.__chunk == evo.registry.chunk(f1))
            assert(e3.__chunk == evo.registry.chunk(f2))
            assert(e4.__chunk == evo.registry.chunk(f2, f3))
            assert(e5.__chunk == evo.registry.chunk(f3))
            assert(e1:get(f1) == 10 and e2:get(f1) == 15)
            assert(e3:get(f2) == 40 and e4:get(f2) == 45 and e4:get(f3) == 55)

            assert(2 == q:batch_remove(f2))
            assert(e1.__chunk == evo.registry.chunk(f1))
            assert(e2.__chunk == evo.registry.chunk(f1))
            assert(e3.__chunk == nil)
            assert(e4.__chunk == evo.registry.chunk(f3))
            assert(e5.__chunk == evo.registry.chunk(f3))
            assert(e1:get(f1) == 10 and e2:get(f1) == 15)
            assert(e3:get(f2) == nil and e4:get(f2) == nil and e4:get(f3) == 55)
            assert(e5:get(f3) == 65)
        end

        do
            local q = evo.registry.query(f3)
            assert(0 == q:batch_remove(f1))
            assert(2 == q:batch_remove(f3))
        end
    end
end

do
    local f1, f2, f3 = evo.registry.entity(), evo.registry.entity(), evo.registry.entity()

    do
        local e1 = evo.registry.entity():set(f1, 10)
        local e2 = evo.registry.entity():set(f1, 15)
        local e3 = evo.registry.entity():set(f1, 20):set(f2, 40)
        local e4 = evo.registry.entity():set(f1, 25):set(f2, 45):set(f3, 55)
        local e5 = evo.registry.entity():set(f3, 65)

        do
            local q = evo.registry.query(f2):exclude(f3)
            assert(1 == q:batch_detach())
            assert(e1.__chunk == evo.registry.chunk(f1))
            assert(e2.__chunk == evo.registry.chunk(f1))
            assert(e3.__chunk == nil)
            assert(e4.__chunk == evo.registry.chunk(f1, f2, f3))
            assert(e5.__chunk == evo.registry.chunk(f3))
            assert(#evo.registry.chunk(f1, f2):entities() == 0)
            assert(#evo.registry.chunk(f1, f2):components(f1) == 0)
            assert(#evo.registry.chunk(f1, f2):components(f2) == 0)
            assert(e1:alive() and e2:alive() and e3:alive() and e4:alive() and e5:alive())
        end

        do
            local q = evo.registry.query(f1)
            assert(3 == q:batch_detach())
            assert(e1.__chunk == nil)
            assert(e2.__chunk == nil)
            assert(e3.__chunk == nil)
            assert(e4.__chunk == nil)
            assert(e5.__chunk == evo.registry.chunk(f3))
            assert(e1:alive() and e2:alive() and e3:alive() and e4:alive() and e5:alive())
        end
    end
end

do
    local f1, f2, f3 = evo.registry.entity(), evo.registry.entity(), evo.registry.entity()

    do
        local e1 = evo.registry.entity():set(f1, 10)
        local e2 = evo.registry.entity():set(f1, 15)
        local e3 = evo.registry.entity():set(f1, 20):set(f2, 40)
        local e4 = evo.registry.entity():set(f1, 25):set(f2, 45):set(f3, 55)
        local e5 = evo.registry.entity():set(f3, 65)

        do
            local q = evo.registry.query(f2):exclude(f3)
            assert(1 == q:batch_destroy())
            assert(e1.__chunk == evo.registry.chunk(f1))
            assert(e2.__chunk == evo.registry.chunk(f1))
            assert(e3.__chunk == nil)
            assert(e4.__chunk == evo.registry.chunk(f1, f2, f3))
            assert(e5.__chunk == evo.registry.chunk(f3))
            assert(#evo.registry.chunk(f1, f2):entities() == 0)
            assert(#evo.registry.chunk(f1, f2):components(f1) == 0)
            assert(#evo.registry.chunk(f1, f2):components(f2) == 0)
            assert(e1:alive() and e2:alive() and not e3:alive() and e4:alive() and e5:alive())
        end

        do
            local q = evo.registry.query(f1)
            assert(3 == q:batch_destroy())
            assert(e1.__chunk == nil)
            assert(e2.__chunk == nil)
            assert(e3.__chunk == nil)
            assert(e4.__chunk == nil)
            assert(e5.__chunk == evo.registry.chunk(f3))
            assert(not e1:alive() and not e2:alive() and not e3:alive() and not e4:alive() and e5:alive())
        end
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
                assert(e1:get(f) == f.__guid)
                assert(e2:get(f) == f.__guid)
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

    local query1 = evo.registry.query(f1, f1)
    local query2 = query1:include(f2, f3, f2)
    local query3 = query2:exclude(f4, f5, f5)

    assert(query1 ~= query2)
    assert(query2 ~= query3)

    assert(includes(query1, f1) and not includes(query1, f2) and not includes(query1, f3))
    assert(includes(query2, f1) and includes(query2, f2) and includes(query2, f3))
    assert(includes(query3, f1) and includes(query3, f2) and includes(query3, f3))

    assert(not excludes(query1, f4) and not excludes(query1, f5))
    assert(not excludes(query2, f4) and not excludes(query2, f5))
    assert(excludes(query3, f4) and excludes(query3, f5))

    assert(includes(query3, f1) and includes(query3, f2) and includes(query3, f3))
    assert(not includes(query3, f4) and not includes(query3, f5))
    assert(excludes(query3, f4) and excludes(query3, f5))
    assert(not excludes(query3, f1) and not excludes(query3, f2) and not excludes(query3, f3))
end

do
    local f1, f2, f3 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    evo.registry.entity():set(f2):set(f1)

    local q0 = evo.registry.query()
    local q1 = evo.registry.query(f3)

    assert(q0:execute())
    assert(q1:execute())
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

do
    local f1, f2, f3, f4 =
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity(),
        evo.registry.entity()

    evo.registry.entity():set(f1)
    evo.registry.entity():set(f1):set(f2)

    if not os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") then
        assert(not pcall(function()
            local q = evo.registry.query(f1)
            for chunk in q:execute() do
                for _, e in ipairs(chunk:entities()) do
                    assert(e:insert(f2))
                end
            end
        end))
        assert(not pcall(function()
            local q = evo.registry.query(f1, f2)
            for chunk in q:execute() do
                for _, e in ipairs(chunk:entities()) do
                    assert(e:insert(f3))
                end
            end
        end))
        assert(pcall(function()
            local q = evo.registry.query(f1)
            for chunk in q:execute() do
                for _, e in ipairs(chunk:entities()) do
                    assert(not e:assign(f4))
                end
            end
        end))
    end
end
