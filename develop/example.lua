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
    local position = evo.vectors.vector2(512, 50)
    local velocity = evo.vectors.vector2(math.random(-20, 20), 20)
    evo.registry.insert(entity, fragments.position, position)
    evo.registry.insert(entity, fragments.velocity, velocity)
end

do
    local dt = evo.singles.get(singles.delta_time)

    for chunk in evo.registry.execute(queries.bodies) do
        local es = evo.registry.chunk_entities(chunk)
        local ps = evo.registry.chunk_components(chunk, fragments.position)
        local vs = evo.registry.chunk_components(chunk, fragments.velocity)

        for i = 1, #es do
            ps[i] = ps[i] + vs[i] * dt
        end
    end
end
