---@diagnostic disable: unused-local

local evo = require 'evolved'

evo.debug_mode(true)

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

local consts = {
    delta_time = 0.016,
    physics_gravity = vector2(0, 9.81),
}

local groups = {
    awake = evo.spawn(),
    physics = evo.spawn(),
    graphics = evo.spawn(),
    shutdown = evo.spawn(),
}

local fragments = {
    force = evo.spawn(),
    position = evo.spawn(),
    velocity = evo.spawn(),
}

local queries = {
    physics_bodies = evo.builder()
        :include(fragments.force, fragments.position, fragments.velocity)
        :spawn(),
}

local awake_system = evo.builder()
    :group(groups.awake)
    :prologue(function()
        print '-= | Awake | =-'
        evo.builder()
            :set(fragments.force, vector2(0, 0))
            :set(fragments.position, vector2(0, 0))
            :set(fragments.velocity, vector2(0, 0))
            :spawn()
    end):spawn()

local integrate_forces_system = evo.builder()
    :group(groups.physics)
    :query(queries.physics_bodies)
    :execute(function(chunk, entities, entity_count)
        local delta_time, physics_gravity =
            consts.delta_time, consts.physics_gravity

        ---@type evolved.vector2[], evolved.vector2[]
        local forces, velocities = chunk:components(
            fragments.force, fragments.velocity)

        for i = 1, entity_count do
            local force, velocity = forces[i], velocities[i]

            velocity.x = velocity.x + (physics_gravity.x + force.x) * delta_time
            velocity.y = velocity.y + (physics_gravity.y + force.y) * delta_time
        end
    end):spawn()

local integrate_velocities_system = evo.builder()
    :group(groups.physics)
    :query(queries.physics_bodies)
    :execute(function(chunk, entities, entity_count)
        local delta_time =
            consts.delta_time

        ---@type evolved.vector2[], evolved.vector2[], evolved.vector2[]
        local forces, positions, velocities = chunk:components(
            fragments.force, fragments.position, fragments.velocity)

        for i = 1, entity_count do
            local force, position, velocity = forces[i], positions[i], velocities[i]

            position.x = position.x + velocity.x * delta_time
            position.y = position.y + velocity.y * delta_time

            force.x = 0
            force.y = 0
        end
    end):spawn()

local graphics_system = evo.builder()
    :group(groups.graphics)
    :query(queries.physics_bodies)
    :execute(function(chunk, entities, entity_count)
        ---@type evolved.vector2[]
        local positions = chunk:components(
            fragments.position)

        for i = 1, entity_count do
            local entity, position = entities[i], positions[i]

            print(string.format(
                '|-> {entity %d} at {%.4f, %.4f}',
                entity, position.x, position.y))
        end
    end):spawn()

local shutdown_system = evo.builder()
    :group(groups.shutdown)
    :epilogue(function()
        print '-= | Shutdown | =-'
        evo.batch_destroy(queries.physics_bodies)
    end):spawn()

do
    evo.process(groups.awake)

    for _ = 1, 10 do
        evo.process(groups.physics)
        evo.process(groups.graphics)
    end

    evo.process(groups.shutdown)
end
