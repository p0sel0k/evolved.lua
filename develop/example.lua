local evolved = require 'evolved'

local registry = evolved.registry()

local fragments = {
    position = registry:entity(),
    velocity = registry:entity(),
}

do
    local entity = registry:entity()
    entity:insert(fragments.position)
    entity:insert(fragments.velocity)
end

do
    local query = registry:query(
        fragments.position,
        fragments.velocity)
end
