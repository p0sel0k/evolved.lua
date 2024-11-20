local evo = require 'evolved.evolved'

local singles = {
    delta_time = evo.singles.create(0.016),
}

local fragments = {
    position = evo.registry.create_entity(),
    velocity = evo.registry.create_entity(),
}

local queries = {
    bodies = evo.registry.create_query(
        fragments.position,
        fragments.velocity),
}

do
    local entity = evo.registry.create_entity()
    local position = evo.vectors.vector2(512, 50)
    local velocity = evo.vectors.vector2(math.random(-20, 20), 20)
    evo.registry.insert_component(entity, fragments.position, position)
    evo.registry.insert_component(entity, fragments.velocity, velocity)
end

do
    local dt = evo.singles.get(singles.delta_time)

    for chunk in evo.registry.execute_query(queries.bodies) do
        local ps = chunk.components[fragments.position]
        local vs = chunk.components[fragments.velocity]

        for i in #chunk.entities do
            ps[i] = ps[i] + vs[i] * dt
        end
    end
end
