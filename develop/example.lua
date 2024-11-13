local evolved = require 'evolved'

local registry = evolved.registry()

local fragments = {
    position = registry:entity(),
    velocity = registry:entity(),
}

do
    registry:entity(
        fragments.position,
        fragments.velocity)
end

do
    local entity = registry:entity()
    entity:insert(fragments.position)
    entity:insert(fragments.velocity)
end

do
    local query = registry:query(
        fragments.position,
        fragments.velocity)

    for chunk in query:chunks() do
        local ps = chunk.components[fragments.position]
        local vs = chunk.components[fragments.position]

        for i = 1, #chunk.entities do
        end
    end
end
