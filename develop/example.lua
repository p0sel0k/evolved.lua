local evo = require 'evolved.evolved'

local v2 = evo.vectors.vector2

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
    evo.registry.entity()
        :set(fragments.position, v2(512, 50))
        :set(fragments.velocity, v2(math.random(-20, 20), 20))
end

do
    local delta_time = evo.singles.get(singles.delta_time)

    for chunk in queries.bodies:execute() do
        local entities = chunk:entities()

        local positions, velocities = chunk:components(
            fragments.position,
            fragments.velocity)

        for i = 1, #entities do
            positions[i] = positions[i] + velocities[i] * delta_time
        end
    end
end
