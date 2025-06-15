local evo = require 'evolved'

do
    local p1, s1 = evo.id(2)
    local pair1 = evo.pair(p1, s1)
    local p2, s2 = evo.unpair(pair1)
    assert(p1 == p2 and s1 == s2)
end
