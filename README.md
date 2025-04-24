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

## Predefs

```
TAG :: fragment
NAME :: fragment

DEFAULT :: fragment
DUPLICATE :: fragment

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

DISABLED :: fragment

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

chunk:alive :: boolean
chunk:empty :: boolean

chunk:has :: fragment -> boolean
chunk:has_all :: fragment... -> boolean
chunk:has_any :: fragment... -> boolean

chunk:entities :: entity[], integer
chunk:fragments :: fragment[], integer
chunk:components :: fragment... -> component[]...
```

## Builder

```
builder :: builder

builder:spawn :: entity
builder:clone :: entity -> entity

builder:has :: fragment -> boolean
builder:has_all :: fragment... -> boolean
builder:has_any :: fragment... -> boolean

builder:get :: fragment... -> component...

builder:set :: fragment, component -> builder
builder:remove :: fragment... -> builder
builder:clear :: builder

builder:tag :: builder
builder:name :: string -> builder

builder:default :: component -> builder
builder:duplicate :: {component -> component} -> builder

builder:include :: fragment... -> builder
builder:exclude :: fragment... -> builder

builder:on_set :: {entity, fragment, component, component?} -> builder
builder:on_assign :: {entity, fragment, component, component} -> builder
builder:on_insert :: {entity, fragment, component} -> builder
builder:on_remove :: {entity, fragment} -> builder

builder:group :: system -> builder

builder:query :: query -> builder
builder:execute :: {chunk, entity[], integer} -> builder

builder:prologue :: {} -> builder
builder:epilogue :: {} -> builder

builder:disabled :: builder

builder:destroy_policy :: id -> builder
```

## [License (MIT)](./LICENSE.md)
