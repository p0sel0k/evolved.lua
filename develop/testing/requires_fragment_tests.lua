local evo = require 'evolved'

do
    local f1, f2 = evo.id(2)
    evo.set(f1, evo.REQUIRES)
    evo.set(f2, evo.REQUIRES, evo.get(f1, evo.REQUIRES))
    local f1_rs = evo.get(f1, evo.REQUIRES)
    local f2_rs = evo.get(f2, evo.REQUIRES)
    assert(f1_rs and f2_rs and #f1_rs == 0 and #f2_rs == 0 and f1_rs ~= f2_rs)
end

do
    local f1, f2 = evo.id(2)
    local f3 = evo.builder():require(f1):require(f2):spawn()
    local f3_rs = evo.get(f3, evo.REQUIRES)
    assert(f3_rs and #f3_rs == 2 and f3_rs[1] == f1 and f3_rs[2] == f2)
end

do
    local f1, f2 = evo.id(2)
    local f3 = evo.builder():require(f1, f2):spawn()
    local f3_rs = evo.get(f3, evo.REQUIRES)
    assert(f3_rs and #f3_rs == 2 and f3_rs[1] == f1 and f3_rs[2] == f2)
end
