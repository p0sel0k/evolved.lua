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

do
    local s = evo.scheme_number()

    local f1 = evo.builder():scheme(s):spawn()
    local f2 = evo.builder():scheme(s):spawn()
    local f3 = evo.builder():scheme(s):spawn()

    local b = evo.builder():set(f1, 42)

    local es = {}
    for i = 1, 12 do es[i] = b:spawn() end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == 42) end

    for _, e in ipairs(es) do evo.set(e, f2, 84) end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == 42 and evo.get(e, f2) == 84) end

    for _, e in ipairs(es) do evo.remove(e, f1) end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == nil and evo.get(e, f2) == 84) end

    local q_f2 = evo.builder():include(f2):spawn()

    evo.batch_set(q_f2, f3, 21)
    for _, e in ipairs(es) do assert(evo.get(e, f2) == 84 and evo.get(e, f3) == 21) end

    evo.batch_remove(q_f2, f2)
    for _, e in ipairs(es) do assert(evo.get(e, f2) == nil and evo.get(e, f3) == 21) end
end

do
    local s = evo.scheme_number()

    local f1 = evo.builder():scheme(s):spawn()
    local f2 = evo.builder():scheme(s):spawn()
    local f3 = evo.builder():scheme(s):spawn()

    local b = evo.builder():set(f1, 42)

    local es = {}
    for i = 1, 12 do es[i] = b:spawn() end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == 42) end

    for _, e in ipairs(es) do evo.set(e, f2, 84) end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == 42 and evo.get(e, f2) == 84) end

    for _, e in ipairs(es) do evo.remove(e, f1) end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == nil and evo.get(e, f2) == 84) end

    local q_f2 = evo.builder():include(f2):spawn()

    do
        b:remove(f1):set(f2, 84):set(f3, 21)
        for _ = 1, 12 do es[#es + 1] = b:spawn() end
    end

    evo.batch_set(q_f2, f3, 21)
    for _, e in ipairs(es) do assert(evo.get(e, f2) == 84 and evo.get(e, f3) == 21) end

    evo.batch_remove(q_f2, f2)
    for _, e in ipairs(es) do assert(evo.get(e, f2) == nil and evo.get(e, f3) == 21) end
end

do
    local s = evo.scheme_number()

    local f1 = evo.builder():scheme(s):spawn()
    local f2 = evo.builder():scheme(s):spawn()
    local f3 = evo.builder():scheme(s):spawn()

    local b = evo.builder():set(f1, 42)

    local es = {}
    for i = 1, 12 do es[i] = b:spawn() end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == 42) end

    for _, e in ipairs(es) do evo.set(e, f2, 84) end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == 42 and evo.get(e, f2) == 84) end

    for _, e in ipairs(es) do evo.remove(e, f1) end
    for _, e in ipairs(es) do assert(evo.get(e, f1) == nil and evo.get(e, f2) == 84) end

    local q_f2 = evo.builder():include(f2):spawn()
    local q_f3 = evo.builder():include(f3):spawn()

    do
        b:remove(f1):set(f2, 84):set(f3, 21)
        b:multi_spawn(24)
        evo.batch_destroy(q_f3)
    end

    evo.batch_set(q_f2, f3, 21)
    for _, e in ipairs(es) do assert(evo.get(e, f2) == 84 and evo.get(e, f3) == 21) end

    evo.batch_remove(q_f2, f2)
    for _, e in ipairs(es) do assert(evo.get(e, f2) == nil and evo.get(e, f3) == 21) end
end

do
    local s = evo.scheme_number()

    local f1 = evo.builder():scheme(s):spawn()
    local f2 = evo.builder():scheme(s):spawn()

    local ec = evo.builder():set(f1, 21):set(f2, 42):multi_spawn(11)
    for _, e in ipairs(ec) do assert(evo.get(e, f1) == 21 and evo.get(e, f2) == 42) end

    local q_f1 = evo.builder():include(f1):spawn()

    evo.batch_remove(q_f1, f1)
    for _, e in ipairs(ec) do assert(evo.get(e, f1) == nil and evo.get(e, f2) == 42) end
end

do
    local ns1 = evo.scheme_number()

    local f = evo.builder():scheme(ns1):spawn()

    local e = evo.builder():set(f, 42):spawn()
    assert(evo.get(e, f) == 42)

    local ns2 = evo.scheme_number()
    evo.set(f, evo.SCHEME, ns2)
    assert(evo.get(e, f) == 42)

    local ns3 = evo.scheme_boolean()
    evo.set(f, evo.SCHEME, ns3)
    assert(evo.get(e, f) == true)
end
