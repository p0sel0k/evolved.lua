# evolved.lua

## Module `idpools`

```
idpools.idpool -> (idpool)
idpools.pack -> integer -> integer -> (id)
idpools.unpack -> id -> (integer, integer)
idpools.acquire -> idpool -> (id)
idpools.release -> idpool -> id -> ()
idpools.is_alive -> idpool -> id -> (boolean)
```

### Instance `idpool`

```
idpool.pack -> integer -> integer -> (id)
idpool.unpack -> id -> (integer, integer)
idpool:acquire -> (id)
idpool:release -> id -> ()
idpool:is_alive -> id -> (boolean)
```

## Module `registry`

```
registry.entity -> (entity)
registry.is_alive -> entity -> (boolean)
registry.destroy -> entity -> ()
registry.get -> entity -> entity -> (any)
registry.get_or -> entity -> entity -> any -> (any)
registry.has -> entity -> entity -> (boolean)
registry.has_all -> entity -> entity -> entity... -> (boolean)
registry.has_any -> entity -> entity -> entity... -> (boolean)
registry.assign -> entity -> entity -> any -> ()
registry.insert -> entity -> entity -> any -> ()
registry.remove -> entity -> entity -> ()
registry.query -> entity -> entity... -> (query)
registry.execute -> query -> (() -> (chunk?))
registry.chunk -> entity -> entity... -> (chunk)
registry.entities -> chunk -> entity -> (entity[])
registry.components -> chunk -> entity -> (any[])
```

### Instance `entity`

```
enity:is_alive -> (boolean)
enity:destroy -> ()
enity:get -> entity -> (any)
enity:get_or -> entity -> any -> (any)
enity:has -> entity -> (boolean)
enity:has_all -> entity -> entity... -> (boolean)
enity:has_any -> entity -> entity... -> (boolean)
enity:assign -> entity -> any -> ()
enity:insert -> entity -> any -> ()
enity:remove -> entity -> ()
```

### Instance `query`

```
query:execute -> (() -> (chunk?))
```

### Instance `chunk`

```
chunk:entities -> entity -> (entity[])
chunk:components -> entity -> (any[])
```

## Module `singles`

```
singles.single -> any -> (entity)
singles.get -> entity -> (any)
singles.has -> entity -> (boolean)
singles.assign -> entity -> any -> ()
```

## Module `vectors`

```
vectors.vector2 -> number -> number -> (vector2)
vectors.is_vector2 -> any -> (boolean)
```

## [License (MIT)](./LICENSE.md)
