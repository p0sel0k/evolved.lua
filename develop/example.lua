local evolved = require 'evolved.evolved'
local evolved_singles = require 'evolved.singles'
local evolved_vectors = require 'evolved.vectors'

local singles = {
    delta_time = evolved_singles.create(0.016),
}

local fragments = {
    position = evolved.create_entity(),
    velocity = evolved.create_entity(),
}

local queries = {
    bodies = evolved.create_query(
        fragments.position,
        fragments.velocity),
}

do
    local entity = evolved.create_entity()
    local position = evolved_vectors.vector2(512, 50)
    local velocity = evolved_vectors.vector2(math.random(-20, 20), 20)
    evolved.insert_component(entity, fragments.position, position)
    evolved.insert_component(entity, fragments.velocity, velocity)
end

do
    local dt = evolved_singles.get(singles.delta_time)

    for chunk in evolved.execute_query(queries.bodies) do
        local ps = chunk.components[fragments.position]
        local vs = chunk.components[fragments.velocity]

        for i in #chunk.entities do
            ps[i] = ps[i] + vs[i] * dt
        end
    end
end
