---@diagnostic disable: unused-local

local evo = require 'evolved'

---@class vector2
---@field x number
---@field y number

---@param x number
---@param y number
local function vector2(x, y)
    ---@type vector2
    return { x = x, y = y }
end

local phases = {
    awake = evo.phase():build(),
    physics = evo.phase():build(),
    graphics = evo.phase():build(),
    shutdown = evo.phase():build(),
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
    bodies = evo.query()
        :include(fragments.force, fragments.position, fragments.velocity)
        :build(),
}

local awake_system = evo.system()
    :phase(phases.awake)
    :process(function()
        print '-= Awake =-'
        evo.entity()
            :set(fragments.force, vector2(0, 0))
            :set(fragments.position, vector2(0, 0))
            :set(fragments.velocity, vector2(0, 0))
            :build()
    end):build()

local integrate_forces_system = evo.system()
    :phase(phases.physics)
    :query(queries.bodies)
    :execute(function(chunk, entities, entity_count)
        ---@type number, vector2
        local delta_time, physics_gravity =
            evo.get(singles.delta_time, singles.delta_time),
            evo.get(singles.physics_gravity, singles.physics_gravity)

        ---@type vector2[], vector2[]
        local forces, velocities = evo.select(chunk, fragments.force, fragments.velocity)

        for i = 1, entity_count do
            local force, velocity = forces[i], velocities[i]

            force.x = force.x + physics_gravity.x * delta_time
            force.y = force.y + physics_gravity.y * delta_time

            velocity.x = velocity.x + force.x * delta_time
            velocity.y = velocity.y + force.y * delta_time
        end
    end):build()

local integrate_velocities_system = evo.system()
    :phase(phases.physics)
    :after(integrate_forces_system)
    :query(queries.bodies)
    :execute(function(chunk, entities, entity_count)
        ---@type number
        local delta_time =
            evo.get(singles.delta_time, singles.delta_time)

        ---@type vector2[], vector2[]
        local positions, velocities = evo.select(chunk, fragments.position, fragments.velocity)

        for i = 1, entity_count do
            local position, velocity = positions[i], velocities[i]

            position.x = position.x + velocity.x * delta_time
            position.y = position.y + velocity.y * delta_time
        end
    end):build()

local graphics_system = evo.system()
    :phase(phases.graphics)
    :query(queries.bodies)
    :execute(function(chunk, entities, entity_count)
        ---@type vector2[]
        local positions = evo.select(chunk, fragments.position)

        for i = 1, entity_count do
            local entity, position = entities[i], positions[i]

            print(string.format(
                '- {entity %d} at {%.4f, %.4f}',
                entity, position.x, position.y))
        end
    end):build()

local shutdown_system = evo.system()
    :phase(phases.shutdown)
    :process(function()
        print '-= Shutdown =-'
        evo.batch_destroy(queries.bodies)
    end):build()

do
    evo.process(phases.awake)

    for _ = 1, 10 do
        evo.process(phases.physics)
        evo.process(phases.graphics)
    end

    evo.process(phases.shutdown)
end
