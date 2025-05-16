# Manual

## Identifiers

An identifier is a packed 40-bit integer. The first 20 bits represent the index, and the last 20 bits represent the version. To create a new identifier, use the `evolved.id` function.

```lua
---@param count? integer
---@return evolved.id ... ids
function evolved.id(count) end
```

The `count` parameter is optional and defaults to `1`. The function returns one or more identifiers depending on the `count` parameter. The maximum number of alive identifiers is `2^20-1` (1048575). After that, the function will throw an error: `| evolved.lua | id index overflow`.

Identifiers can be recycled. When an identifier is no longer needed, use the `evolved.destroy` function to destroy it. This will free the identifier for reuse.

```lua
---@param ... evolved.id ids
function evolved.destroy(...) end
```

The `evolved.destroy` function takes one or more identifiers as arguments. Destroyed identifiers will be added to the recycler free list. It is safe to call `evolved.destroy` on identifiers that are not alive; the function will simply ignore them.

After destroying an identifier, it can be reused by calling the `evolved.id` function again. The new identifier will have the same index as the destroyed one, but a different version. The version is incremented each time an identifier is destroyed. This mechanism allows us to reuse indices and to know whether an identifier is alive or not.

The set of `evolved.alive` functions can be used to check whether identifiers are alive.

```lua
---@param id evolved.id
---@return boolean
function evolved.alive(id) end

---@param ... evolved.id ids
---@return boolean
function evolved.alive_all(...) end

---@param ... evolved.id ids
---@return boolean
function evolved.alive_any(...) end
```

Sometimes (for debugging purposes, for example), it is necessary to extract the index and version from an identifier or to pack them back into an identifier. The `evolved.pack` and `evolved.unpack` functions can be used for this purpose.

```lua
---@param index integer
---@param version integer
---@return evolved.id id
function evolved.pack(index, version) end

---@param id evolved.id
---@return integer index
---@return integer version
function evolved.unpack(id) end
```

Here is a short example of how to use identifiers:

```lua
local evolved = require 'evolved'

local id = evolved.id() -- create a new identifier
assert(evolved.alive(id)) -- check that the identifier is alive

local index, version = evolved.unpack(id) -- unpack the identifier
assert(evolved.pack(index, version) == id) -- pack it back

evolved.destroy(id) -- destroy the identifier
assert(not evolved.alive(id)) -- check that the identifier is not alive now
```

## Entities, Fragments, and Components

First, you need to understand that entities and fragments are just identifiers. The difference between them is purely semantic. Entities are used to represent objects in the world, while fragments are used to represent types of components that can be attached to entities. Components, on the other hand, are any data that is attached to entities through fragments.

```lua
---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.component any
```

Here is a simple example of how to attach a component to an entity:

```lua
local evolved = require 'evolved'

local entity, fragment = evolved.id(2)

evolved.set(entity, fragment, 100)
assert(evolved.get(entity, fragment) == 100)
```

I know it's not very clear yet, but don't worry, we'll get there. In the next example, I'm going to name the entity and fragment, so it will be easier to understand what's going on here.

```lua
local evolved = require 'evolved'

local player = evolved.id()

local health = evolved.id()
local stamina = evolved.id()

evolved.set(player, health, 100)
evolved.set(player, stamina, 50)

assert(evolved.get(player, health) == 100)
assert(evolved.get(player, stamina) == 50)
```

We created an entity called `player` and two fragments called `health` and `stamina`. We attached the components `100` and `50` to the entity through these fragments. After that, we can retrieve the components using the `evolved.get` function.

We'll cover the `evolved.set` and `evolved.get` functions in more detail later in the section about modifying operations. For now, let's just say that they are used to set and get components from entities through fragments.

The main thing to understand here is that you can attach any data to any identifier by using other identifiers.

### Traits

Since fragments are just identifiers, you can use them as entities too! Fragments of fragments are usually called `traits`. This is very useful, for example, for marking fragments with some metadata.

```lua
local evolved = require 'evolved'

local serializable = evolved.id()

local position = evolved.id()
evolved.set(position, serializable, true)

local velocity = evolved.id()
evolved.set(velocity, serializable, true)

local player = evolved.id()
evolved.set(player, position, {x = 0, y = 0})
evolved.set(player, velocity, {x = 0, y = 0})
```

In this example, we create a trait called `serializable` and mark the fragments `position` and `velocity` as serializable. After that, you can write a function that will serialize entities, and this function will serialize only fragments that are marked as serializable. This is a very powerful feature of the library, and it allows you to create very flexible systems.

### Singletons

Fragments can even be attached to themselves; this is called a singleton. Use this when you want to store some data without having a separate entity. For example, you can use it to store global data, like the game state or the current level.

```lua
local evolved = require 'evolved'

local gravity = evolved.id()
evolved.set(gravity, gravity, 10)

assert(evolved.get(gravity, gravity) == 10)
```

## Chunks

The next thing we need to understand is that all non-empty entities are stored in chunks. Chunks are just tables that store entities and their components together. Each unique combination of fragments is stored in a separate chunk. This means that if you have two entities with the same fragments, they will be stored in the `<health, stamina>` chunk. If you have another entity with the fragments `health`, `stamina`, and `mana`, it will be stored in the `<health, stamina, mana>` chunk. This is very useful for performance reasons, as it allows us to store entities with the same fragments together, making it easier to iterate, filter, and process them.

```lua
local evolved = require 'evolved'

local health, stamina, mana = evolved.id(3)

local entity1 = evolved.id()
evolved.set(entity1, health, 100)
evolved.set(entity1, stamina, 50)

local entity2 = evolved.id()
evolved.set(entity2, health, 75)
evolved.set(entity2, stamina, 40)

local entity3 = evolved.id()
evolved.set(entity3, health, 50)
evolved.set(entity3, stamina, 30)
evolved.set(entity3, mana, 20)
```

Here is what the chunks will look like after the code above has executed:

| chunk   | health | stamina |
| ------- | :----: | :-----: |
| entity1 |  100   |   50    |
| entity2 |   75   |   40    |

| chunk   | health | stamina | mana  |
| ------- | :----: | :-----: | :---: |
| entity3 |   50   |   30    |  20   |

Usually, you don't need to operate on chunks directly, but you can use the `evolved.chunk` function to get the specific chunk.

```lua
---@param fragment evolved.fragment
---@param ... evolved.fragment fragments
---@return evolved.chunk chunk
function evolved.chunk(fragment, ...) end
```

The `evolved.chunk` function takes one or more fragments as arguments and returns the chunk for this combination. After that, you can use the chunk's methods to retrieve their entities, fragments, and components.

```lua
---@param self evolved.chunk
---@return evolved.entity[] entity_list
---@return integer entity_count
function chunk_mt:entities() end

---@param self evolved.chunk
---@return evolved.fragment[] fragment_list
---@return integer fragment_count
function chunk_mt:fragments() end

---@param self evolved.chunk
---@param ... evolved.fragment fragments
---@return evolved.component[] ... component_lists
function chunk_mt:components(...) end
```

Full example:

```lua
local evolved = require 'evolved'

local health, stamina, mana = evolved.id(3)

local entity1 = evolved.id()
evolved.set(entity1, health, 100)
evolved.set(entity1, stamina, 50)

local entity2 = evolved.id()
evolved.set(entity2, health, 75)
evolved.set(entity2, stamina, 40)

local entity3 = evolved.id()
evolved.set(entity3, health, 50)
evolved.set(entity3, stamina, 30)
evolved.set(entity3, mana, 20)

-- get (or create if it doesn't exist) the chunk <health, stamina>
local chunk = evolved.chunk(health, stamina)

-- get the list of entities in the chunk and the number of them
local entity_list, entity_count = chunk:entities()

-- get the columns of components in the chunk
local health_components = chunk:components(health)
local stamina_components = chunk:components(stamina)

for i = 1, entity_count do
    local entity = entity_list[i]

    local entity_health = health_components[i]
    local entity_stamina = stamina_components[i]

    -- do something with the entity and its components
    print(string.format(
        'Entity: %d, Health: %d, Stamina: %d',
        entity, entity_health, entity_stamina))
end

-- Expected output:
-- Entity: 1048602, Health: 100, Stamina: 50
-- Entity: 1048603, Health: 75, Stamina: 40
```

## Structural Changes

Every time we add or remove a fragment from an entity, the entity will be migrated to a new chunk. This is done automatically by the library, of course. However, you should be aware of this because it can affect performance, especially if you have many fragments on the entity. This is called a `structural change`.

You should try to avoid structural changes, especially in performance-critical code. For example, you can spawn entities with all the fragments they will ever need and avoid changing them during the entity's lifetime. Overriding existing components is not a structural change, so you can do it freely.

```lua
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity
function evolved.spawn(components) end

---@param prefab evolved.entity
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity
function evolved.clone(prefab, components) end
```

The `evolved.spawn` function allows you to spawn an entity with all the necessary fragments. It takes a table of components as an argument, where the keys are fragments and the values are components. By the way, you don't need to create this `components` table every time; consider using a predefined table for maximum performance.

You can also use the `evolved.clone` function to clone an existing entity. This is useful for creating entities with the same fragments as an existing entity but with different components.

```lua
local evolved = require 'evolved'

local health, stamina = evolved.id(2)

-- spawn an entity with all the necessary fragments
local enemy1 = evolved.spawn {
  [health] = 100,
  [stamina] = 50,
}

-- spawn another entity with the same fragments,
-- but with a different component for some of them
local enemy2 = evolved.clone(enemy1, {
    [health] = 50,
})

-- there are no structural changes here,
-- we just override existing components
evolved.set(enemy1, health, 75)
evolved.set(enemy1, stamina, 42)
```
