local evo = require 'evolved'

do
    local ns1 = evo.scheme_number()
    local ns2 = evo.scheme_number()

    local f1 = evo.builder():scheme(ns1):spawn()
    local f2 = evo.builder():scheme(ns2):spawn()

    local e1 = evo.builder():set(f1, 1):spawn()
    local e2 = evo.builder():set(f1, 3):set(f2, 4):spawn()

    do
        assert(evo.get(e1, f1) == 1 and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f1) == 3 and evo.get(e2, f2) == 4)
    end

    evo.set(e1, f2, 2)

    do
        assert(evo.get(e1, f1) == 1 and evo.get(e1, f2) == 2)
        assert(evo.get(e2, f1) == 3 and evo.get(e2, f2) == 4)
    end

    local es = evo.builder():set(f1, 5):set(f2, 6):multi_spawn(40)
    for _, e in ipairs(es) do assert(evo.get(e, f1) == 5 and evo.get(e, f2) == 6) end
end

do
    local ls1 = evo.scheme_list(evo.scheme_number(), 3)
    local ls2 = evo.scheme_list(evo.scheme_boolean(), 2)

    local f1 = evo.builder():scheme(ls1):spawn()
    local f2 = evo.builder():scheme(ls2):spawn()

    local e1 = evo.builder():set(f1, { 1, 2, 3 }):spawn()
    local e2 = evo.builder():set(f2, { true, false }):spawn()

    do
        local v = evo.get(e1, f1)
        assert(#v == 3 and v[1] == 1 and v[2] == 2 and v[3] == 3)
    end

    do
        local v = evo.get(e2, f2)
        assert(#v == 2 and v[1] == true and v[2] == false)
    end
end

do
    local rs1 = evo.scheme_record { v = evo.scheme_number() }
    local rs2 = evo.scheme_record { v1 = evo.scheme_number(), v2 = evo.scheme_number() }
    local rs3 = evo.scheme_record { n1 = rs2, n2 = rs1 }

    local f1 = evo.builder():scheme(rs1):spawn()
    local f2 = evo.builder():scheme(rs2):spawn()
    local f3 = evo.builder():scheme(rs3):spawn()

    local e1 = evo.builder():set(f1, { v = 42 }):spawn()
    local e2 = evo.builder():set(f2, { v1 = 21, v2 = 84 }):spawn()
    local e3 = evo.builder():set(f3, { n1 = { v1 = 1, v2 = 2 }, n2 = { v = 3 } }):spawn()

    assert(evo.get(e1, f1).v == 42)
    assert(evo.get(e2, f2).v1 == 21 and evo.get(e2, f2).v2 == 84)
    assert(evo.get(e3, f3).n1.v1 == 1 and evo.get(e3, f3).n1.v2 == 2 and evo.get(e3, f3).n2.v == 3)
end
