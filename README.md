# evolved.lua

## Module `defers`

```
defers.defer -> (defer)
defers.set -> defer -> entity -> entity -> any -> (defer)
defers.apply -> defer -> entity -> {any -> any} -> entity -> (defer)
defers.assign -> defer -> entity -> entity -> any -> (defer)
defers.insert -> defer -> entity -> entity -> any -> (defer)
defers.remove -> defer -> entity -> entity... -> (defer)
defers.detach -> defer -> entity -> (defer)
defers.destroy -> defer -> entity -> (defer)
defers.playback -> defer -> (defer)
```

### Instance `defer`

```
defer:set -> entity -> entity -> any -> (defer)
defer:apply -> entity -> {any -> any} -> entity -> (defer)
defer:assign -> entity -> entity -> any -> (defer)
defer:insert -> entity -> entity -> any -> (defer)
defer:remove -> entity -> entity... -> (defer)
defer:detach -> entity -> (defer)
defer:destroy -> entity -> (defer)
defer:playback -> (defer)
```

## Module `idpools`

```
idpools.idpool -> (idpool)
idpools.pack -> integer -> integer -> (id)
idpools.unpack -> id -> (integer, integer)
idpools.alive -> idpool -> id -> (boolean)
idpools.acquire -> idpool -> (id)
idpools.release -> idpool -> id -> ()
```

### Instance `idpool`

```
idpool.pack -> integer -> integer -> (id)
idpool.unpack -> id -> (integer, integer)
idpool:alive -> id -> (boolean)
idpool:acquire -> (id)
idpool:release -> id -> ()
```

## Module `registry`

```
registry.entity -> (entity)
registry.guid -> entity -> (id)
registry.alive -> entity -> (boolean)
registry.get -> entity -> entity... -> (any...)
registry.has -> entity -> entity -> (boolean)
registry.has_all -> entity -> entity... -> (boolean)
registry.has_any -> entity -> entity... -> (boolean)
registry.set -> entity -> entity -> any -> (entity)
registry.chunk_set -> chunk -> entity -> any -> (integer, integer)
registry.query_set -> query -> entity -> any -> (integer, integer)
registry.apply -> entity -> {any -> any} -> entity -> (boolean)
registry.chunk_apply -> chunk -> {any -> any} -> entity -> (integer)
registry.query_apply -> query -> {any -> any} -> entity -> (integer)
registry.assign -> entity -> entity -> any -> (boolean)
registry.chunk_assign -> chunk -> entity -> any -> (integer)
registry.query_assign -> query -> entity -> any -> (integer)
registry.insert -> entity -> entity -> any -> (boolean)
registry.chunk_insert -> chunk -> entity -> any -> (integer)
registry.query_insert -> query -> entity -> any -> (integer)
registry.remove -> entity -> entity... -> (boolean)
registry.chunk_remove -> chunk -> entity... -> (integer)
registry.query_remove -> query -> entity... -> (integer)
registry.detach -> entity -> (entity)
registry.chunk_detach -> chunk -> (integer)
registry.query_detach -> query -> (integer)
registry.destroy -> entity -> (entity)
registry.chunk_destroy -> chunk -> (integer)
registry.query_destroy -> query -> (integer)
registry.query -> entity... -> (query)
registry.include -> query -> entity... -> query
registry.exclude -> query -> entity... -> query
registry.execute -> query -> ({execution_state? -> chunk?}, execution_state?)
registry.chunk -> entity -> entity... -> (chunk)
registry.entities -> chunk -> (entity[])
registry.components -> chunk -> entity... -> (any[]...)
```

### Instance `entity`

```
entity:guid -> (id)
entity:alive -> (boolean)
entity:get -> entity... -> (any...)
entity:has -> entity -> (boolean)
entity:has_all -> entity... -> (boolean)
entity:has_any -> entity... -> (boolean)

entity:set -> entity -> any -> (entity)
entity:apply -> {any -> any} -> entity -> (boolean)
entity:assign -> entity -> any -> (boolean)
entity:insert -> entity -> any -> (boolean)
entity:remove -> entity... -> (boolean)
entity:detach -> (entity)
entity:destroy -> (entity)
```

### Instance `query`

```
query:include -> entity... -> query
query:exclude -> entity... -> query
query:execute -> ({execution_state? -> chunk?}, execution_state?)

query:set -> entity -> any -> (integer, integer)
query:apply -> {any -> any} -> entity -> (integer)
query:assign -> entity -> any -> (integer)
query:insert -> entity -> any -> (integer)
query:remove -> entity... -> (integer)
query:detach -> (integer)
query:destroy -> (integer)
```

### Instance `chunk`

```
chunk:entities -> (entity[])
chunk:components -> entity... -> (any[]...)

chunk:set -> entity -> any -> (integer, integer)
chunk:apply -> {any -> any} -> entity -> (integer)
chunk:assign -> entity -> any -> (integer)
chunk:insert -> entity -> any -> (integer)
chunk:remove -> entity... -> (integer)
chunk:detach -> (integer)
chunk:destroy -> (integer)
```

## Module `singles`

```
singles.single -> any -> (entity)
singles.set -> entity -> any -> (entity)
singles.get -> entity -> (any)
singles.has -> entity -> (boolean)
```

## Module `vectors`

```
vectors.vector2 -> number -> number -> (vector2)
vectors.is_vector2 -> any -> (boolean)
```

## [License (MIT)](./LICENSE.md)
