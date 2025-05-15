# Manual

## Identifiers

An identifier is a packed 40-bit integer. The first 20 bits represent the index, and the last 20 bits represent the version. To create a new identifier, use the `evolved.id` function.

```lua
---@param count? integer
---@return evolved.id ... ids
function evolved.id(count) end
```

The `count` parameter is optional and defaults to `1`. The function returns one or more identifiers, depending on the `count` parameter. The maximum number of alive identifiers is `2^20-1` (1048575). After that, the function will throw an error: `| evolved.lua | id index overflow`.

Identifiers can be recycled. When an identifier is no longer needed, use the `evolved.destroy` function to destroy it. This will free up the identifier for reuse.

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

Sometimes (for debugging purposes, for example), it is necessary to extract the index and version from an identifier, or to pack them back into an identifier. The `evolved.pack` and `evolved.unpack` functions can be used for this purpose.

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

First, we need to understand that entities and fragments are just identifiers. The difference between them is purely semantic. Entities are used to represent objects in the world, while fragments are used to represent types of components that can be attached to entities. Components, on the other hand, are any data that is attached to entities through fragments.

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

The main thing to understand here is that we can attach any data to any identifier using other identifiers. And yes, since fragments are just identifiers, we can use them as entities too! This is very useful for marking fragments with some metadata, for example.

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

In this example, we created a fragment called `serializable` and marked the fragments `position` and `velocity` as serializable. After that, we can write a function that will serialize entities, and this function will serialize only fragments that are marked as serializable. This is a very powerful feature of the library, and it allows us to create very flexible systems. By the way, fragments of fragments are usually called `traits`.
