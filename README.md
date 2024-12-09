# evolved.lua

## Module `defers`

```
defers.defer -> (defer)
defers.set -> defer -> entity -> entity -> component -> (defer)
defers.assign -> defer -> entity -> entity -> component -> (defer)
defers.insert -> defer -> entity -> entity -> component -> (defer)
defers.remove -> defer -> entity -> entity... -> (defer)
defers.detach -> defer -> entity -> (defer)
defers.destroy -> defer -> entity -> (defer)
defers.playback -> defer -> (defer)
```

### Instance `defer`

```
defer:set -> entity -> entity -> component -> (defer)
defer:assign -> entity -> entity -> component -> (defer)
defer:insert -> entity -> entity -> component -> (defer)
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
registry.get -> entity -> entity... -> (component...)
registry.has -> entity -> entity -> (boolean)
registry.has_all -> entity -> entity... -> (boolean)
registry.has_any -> entity -> entity... -> (boolean)
registry.set -> entity -> entity -> component -> (entity)
registry.chunk_set -> chunk -> entity -> component -> (integer, integer)
registry.query_set -> query -> entity -> component -> (integer, integer)
registry.assign -> entity -> entity -> component -> (boolean)
registry.chunk_assign -> chunk -> entity -> component -> (integer)
registry.query_assign -> query -> entity -> component -> (integer)
registry.insert -> entity -> entity -> component -> (boolean)
registry.chunk_insert -> chunk -> entity -> component -> (integer)
registry.query_insert -> query -> entity -> component -> (integer)
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
registry.query_include -> query -> entity... -> query
registry.query_exclude -> query -> entity... -> query
registry.query_execute -> query -> ({execution_state? -> chunk?}, execution_state?)
registry.chunk -> entity -> entity... -> (chunk)
registry.chunk_entities -> chunk -> (entity[])
registry.chunk_components -> chunk -> entity... -> (component[]...)
```

### Instance `entity`

```
entity:guid -> (id)
entity:alive -> (boolean)
entity:get -> entity... -> (component...)
entity:has -> entity -> (boolean)
entity:has_all -> entity... -> (boolean)
entity:has_any -> entity... -> (boolean)
entity:set -> entity -> component -> (entity)
entity:assign -> entity -> component -> (boolean)
entity:insert -> entity -> component -> (boolean)
entity:remove -> entity... -> (boolean)
entity:detach -> (entity)
entity:destroy -> (entity)
```

### Instance `query`

```
query:set -> entity -> component -> (integer, integer)
query:assign -> entity -> component -> (integer)
query:insert -> entity -> component -> (integer)
query:remove -> entity... -> (integer)
query:detach -> (integer)
query:destroy -> (integer)
query:include -> entity... -> query
query:exclude -> entity... -> query
query:execute -> ({execution_state? -> chunk?}, execution_state?)
```

### Instance `chunk`

```
chunk:set -> entity -> component -> (integer, integer)
chunk:assign -> entity -> component -> (integer)
chunk:insert -> entity -> component -> (integer)
chunk:remove -> entity... -> (integer)
chunk:detach -> (integer)
chunk:destroy -> (integer)
chunk:entities -> (entity[])
chunk:components -> entity... -> (component[]...)
```

## Module `singles`

```
singles.single -> component -> (entity)
singles.get -> entity -> (component)
singles.has -> entity -> (boolean)
singles.set -> entity -> component -> (entity)
```

## Module `vectors`

```
vectors.vector2 -> number -> number -> (vector2)
vectors.is_vector2 -> any -> (boolean)
```

## [License (MIT)](./LICENSE.md)
