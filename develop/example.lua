local evo = require 'evolved.evolved'

local singles = {
    delta_time = evo.singles.single(0.016),
}

local fragments = {
    position = evo.registry.entity(),
    velocity = evo.registry.entity(),
}

local queries = {
    bodies = evo.registry.query(
        fragments.position,
        fragments.velocity),
}

do
    local entity = evo.registry.entity()
    entity:insert(fragments.position, evo.vectors.vector2(512, 50))
    entity:insert(fragments.velocity, evo.vectors.vector2(math.random(-20, 20), 20))
end

do
    local dt = evo.singles.get(singles.delta_time)

    for chunk in queries.bodies:execute() do
        local es = chunk:entities()
        local ps = chunk:components(fragments.position)
        local vs = chunk:components(fragments.velocity)

        for i = 1, #es do
            ps[i] = ps[i] + vs[i] * dt
        end
    end
end
