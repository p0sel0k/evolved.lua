---@diagnostic disable: invisible
local evo = require 'evolved.evolved'

do
    local e = evo.registry.entity()
    assert(not evo.singles.has(e))
    assert(evo.singles.get(e) == nil)

    assert(evo.singles.set(e, 42))
    assert(evo.singles.has(e))
    assert(evo.singles.get(e) == 42)
end

do
    local s = evo.singles.single()
    assert(evo.singles.has(s))
    assert(evo.singles.get(s) == true)

    assert(s == evo.singles.set(s, 42))
    assert(evo.singles.get(s) == 42)
end

do
    local s = evo.singles.single(42)
    assert(evo.singles.has(s))
    assert(evo.singles.get(s) == 42)

    assert(s == evo.singles.set(s, true))
    assert(evo.singles.get(s) == true)

    assert(s == evo.singles.set(s, false))
    assert(evo.singles.get(s) == false)
end
