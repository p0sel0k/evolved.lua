---@diagnostic disable: unused-local

local evo = require 'evolved'

---@class evolved.vector2
---@field x number
---@field y number

---@param x number
---@param y number
---@return evolved.vector2
---@nodiscard
local function vector2(x, y)
    ---@type evolved.vector2
    return { x = x, y = y }
end

local groups = {
    awake = evo.system():build(),
    physics = evo.system():build(),
    graphics = evo.system():build(),
    shutdown = evo.system():build(),
}

local singles = {
    delta_time = evo.fragment():single(0.016):build(),
    physics_gravity = evo.fragment():single(vector2(0, 9.81)):build(),
}

local fragments = {
    force = evo.fragment():build(),
    position = evo.fragment():build(),
    velocity = evo.fragment():build(),
}

local queries = {
    physics_bodies = evo.query()
        :include(fragments.force, fragments.position, fragments.velocity)
        :build(),
}

local awake_system = evo.system()
    :group(groups.awake)
    :prologue(function()
        print '-= | Awake | =-'
        evo.entity()
            :set(fragments.force, vector2(0, 0))
            :set(fragments.position, vector2(0, 0))
            :set(fragments.velocity, vector2(0, 0))
            :build()
    end):build()

local integrate_forces_system = evo.system()
    :group(groups.physics)
    :query(queries.physics_bodies)
    :execute(function(chunk, entities, entity_count)
        ---@type number, evolved.vector2
        local delta_time, physics_gravity =
            evo.get(singles.delta_time, singles.delta_time),
            evo.get(singles.physics_gravity, singles.physics_gravity)

        ---@type evolved.vector2[], evolved.vector2[]
        local forces, velocities = evo.components(chunk,
            fragments.force, fragments.velocity)

        for i = 1, entity_count do
            local force, velocity = forces[i], velocities[i]

            velocity.x = velocity.x + (physics_gravity.x + force.x) * delta_time
            velocity.y = velocity.y + (physics_gravity.y + force.y) * delta_time
        end
    end):build()

local integrate_velocities_system = evo.system()
    :group(groups.physics)
    :query(queries.physics_bodies)
    :execute(function(chunk, entities, entity_count)
        ---@type number
        local delta_time =
            evo.get(singles.delta_time, singles.delta_time)

        ---@type evolved.vector2[], evolved.vector2[], evolved.vector2[]
        local forces, positions, velocities = evo.components(chunk,
            fragments.force, fragments.position, fragments.velocity)

        for i = 1, entity_count do
            local force, position, velocity = forces[i], positions[i], velocities[i]

            position.x = position.x + velocity.x * delta_time
            position.y = position.y + velocity.y * delta_time

            force.x = 0
            force.y = 0
        end
    end):build()

local graphics_system = evo.system()
    :group(groups.graphics)
    :query(queries.physics_bodies)
    :execute(function(chunk, entities, entity_count)
        ---@type evolved.vector2[]
        local positions = evo.components(chunk,
            fragments.position)

        for i = 1, entity_count do
            local entity, position = entities[i], positions[i]

            print(string.format(
                '|-> {entity %d} at {%.4f, %.4f}',
                entity, position.x, position.y))
        end
    end):build()

local shutdown_system = evo.system()
    :group(groups.shutdown)
    :epilogue(function()
        print '-= | Shutdown | =-'
        evo.batch_destroy(queries.physics_bodies)
    end):build()

do
    evo.process(groups.awake)

    for _ = 1, 10 do
        evo.process(groups.physics)
        evo.process(groups.graphics)
    end

    evo.process(groups.shutdown)
end
