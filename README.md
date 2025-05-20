# evolved.lua (work in progress)

> Evolved ECS (Entity-Component-System) for Lua

[![lua5.1][badge.lua5.1]][lua5.1]
[![lua5.4][badge.lua5.4]][lua5.4]
[![luajit][badge.luajit]][luajit]
[![license][badge.license]][license]

[badge.lua5.1]: https://img.shields.io/github/actions/workflow/status/BlackMATov/evolved.lua/.github/workflows/lua5.1.yml?label=Lua%205.1
[badge.lua5.4]: https://img.shields.io/github/actions/workflow/status/BlackMATov/evolved.lua/.github/workflows/lua5.4.yml?label=Lua%205.4
[badge.luajit]: https://img.shields.io/github/actions/workflow/status/BlackMATov/evolved.lua/.github/workflows/luajit.yml?label=LuaJIT
[badge.license]: https://img.shields.io/badge/license-MIT-blue

[lua5.1]: https://github.com/BlackMATov/evolved.lua/actions?query=workflow%3Alua5.1
[lua5.4]: https://github.com/BlackMATov/evolved.lua/actions?query=workflow%3Alua5.4
[luajit]: https://github.com/BlackMATov/evolved.lua/actions?query=workflow%3Aluajit
[license]: https://en.wikipedia.org/wiki/MIT_License

[evolved]: https://github.com/BlackMATov/evolved.lua

## Requirements

- [lua](https://www.lua.org/) **>= 5.1**
- [luajit](https://luajit.org/) **>= 2.0**

## Aliases

```
id :: implementation-specific

entity :: id
fragment :: id
query :: id
system :: id

component :: any
storage :: component[]

default :: component
duplicate :: {component -> component}

execute :: {chunk, entity[], integer}
prologue :: {}
epilogue :: {}

set_hook :: {entity, fragment, component, component?}
assign_hook :: {entity, fragment, component, component}
insert_hook :: {entity, fragment, component}
remove_hook :: {entity, fragment, component}

each_state :: implementation-specific
execute_state :: implementation-specific

each_iterator :: {each_state? -> fragment?, component?}
execute_iterator :: {execute_state? -> chunk?, entity[]?, integer?}
```

## Predefs

```
TAG :: fragment
NAME :: fragment

UNIQUE :: fragment
EXPLICIT :: fragment

DEFAULT :: fragment
DUPLICATE :: fragment

PREFAB :: fragment
DISABLED :: fragment

INCLUDES :: fragment
EXCLUDES :: fragment

ON_SET :: fragment
ON_ASSIGN :: fragment
ON_INSERT :: fragment
ON_REMOVE :: fragment

GROUP :: fragment

QUERY :: fragment
EXECUTE :: fragment

PROLOGUE :: fragment
EPILOGUE :: fragment

DESTROY_POLICY :: fragment
DESTROY_POLICY_DESTROY_ENTITY :: id
DESTROY_POLICY_REMOVE_FRAGMENT :: id
```

## Functions

```
id :: integer? -> id...

pack :: integer, integer -> id
unpack :: id -> integer, integer

defer :: boolean
commit :: boolean

spawn :: <fragment, component>? -> entity
clone :: entity -> <fragment, component>? -> entity

alive :: entity -> boolean
alive_all :: entity... -> boolean
alive_any :: entity... -> boolean

empty :: entity -> boolean
empty_all :: entity... -> boolean
empty_any :: entity... -> boolean

has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean

get :: entity, fragment...  -> component...

set :: entity, fragment, component -> ()
remove :: entity, fragment... -> ()
clear :: entity... -> ()
destroy :: entity... -> ()

batch_set :: query, fragment, component -> ()
batch_remove :: query, fragment... -> ()
batch_clear :: query... -> ()
batch_destroy :: query... -> ()

each :: entity -> {each_state? -> fragment?, component?}, each_state?
execute :: query -> {execute_state? -> chunk?, entity[]?, integer?}, execute_state?

process :: system... -> ()

debug_mode :: boolean -> ()
collect_garbage :: ()
```

## Chunk

```
chunk :: fragment, fragment... -> chunk, entity[], integer

chunk_mt:alive :: boolean
chunk_mt:empty :: boolean

chunk_mt:has :: fragment -> boolean
chunk_mt:has_all :: fragment... -> boolean
chunk_mt:has_any :: fragment... -> boolean

chunk_mt:entities :: entity[], integer
chunk_mt:fragments :: fragment[], integer
chunk_mt:components :: fragment... -> storage...
```

## Builder

```
builder :: builder

builder_mt:spawn :: entity
builder_mt:clone :: entity -> entity

builder_mt:has :: fragment -> boolean
builder_mt:has_all :: fragment... -> boolean
builder_mt:has_any :: fragment... -> boolean

builder_mt:get :: fragment... -> component...

builder_mt:set :: fragment, component -> builder
builder_mt:remove :: fragment... -> builder
builder_mt:clear :: builder

builder_mt:tag :: builder
builder_mt:name :: string -> builder

builder_mt:unique :: builder
builder_mt:explicit :: builder

builder_mt:default :: component -> builder
builder_mt:duplicate :: {component -> component} -> builder

builder_mt:prefab :: builder
builder_mt:disabled :: builder

builder_mt:include :: fragment... -> builder
builder_mt:exclude :: fragment... -> builder

builder_mt:on_set :: {entity, fragment, component, component?} -> builder
builder_mt:on_assign :: {entity, fragment, component, component} -> builder
builder_mt:on_insert :: {entity, fragment, component} -> builder
builder_mt:on_remove :: {entity, fragment} -> builder

builder_mt:group :: system -> builder

builder_mt:query :: query -> builder
builder_mt:execute :: {chunk, entity[], integer} -> builder

builder_mt:prologue :: {} -> builder
builder_mt:epilogue :: {} -> builder

builder_mt:destroy_policy :: id -> builder
```

## [License (MIT)](./LICENSE.md)
