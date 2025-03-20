# evolved.lua (work in progress)

> Evolved ECS (Entity-Component-System) for Lua

[![language][badge.language]][language]
[![license][badge.license]][license]

[badge.language]: https://img.shields.io/badge/language-Lua-orange
[badge.license]: https://img.shields.io/badge/license-MIT-blue

[language]: https://en.wikipedia.org/wiki/Lua_(programming_language)
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
CONSTRUCT :: fragment

INCLUDES :: fragment
EXCLUDES :: fragment

ON_SET :: fragment
ON_ASSIGN :: fragment
ON_INSERT :: fragment
ON_REMOVE :: fragment

PHASE :: fragment
GROUP :: fragment
AFTER :: fragment

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

is_alive :: chunk | entity -> boolean
is_alive_all :: chunk | entity... -> boolean
is_alive_any :: chunk | entity... -> boolean

is_empty :: chunk | entity -> boolean
is_empty_all :: chunk | entity... -> boolean
is_empty_any :: chunk | entity... -> boolean

has :: chunk | entity, fragment -> boolean
has_all :: chunk | entity, fragment... -> boolean
has_any :: chunk | entity, fragment... -> boolean

get :: entity, fragment...  -> component...

set :: entity, fragment, any... -> boolean, boolean
remove :: entity, fragment... -> boolean, boolean
clear :: entity... -> boolean, boolean
destroy :: entity... -> boolean, boolean

multi_set :: entity, fragment[], component[]? -> boolean, boolean
multi_remove :: entity, fragment[] -> boolean, boolean

batch_set :: chunk | query, fragment, any... -> integer, boolean
batch_remove :: chunk | query, fragment... -> integer, boolean
batch_clear :: chunk | query... -> integer, boolean
batch_destroy :: chunk | query... -> integer, boolean

batch_multi_set :: chunk | query, fragment[], component[]? -> integer, boolean
batch_multi_remove :: chunk | query, fragment[] -> integer, boolean

chunk :: fragment, fragment... -> chunk, entity[], integer

entities :: chunk -> entity[], integer
fragments :: chunk -> fragment[], integer
components :: chunk, fragment... -> component[]...

each :: entity -> {each_state? -> fragment?, component?}, each_state?
execute :: query -> {execute_state? -> chunk?, entity[]?, integer?}, execute_state?

process :: phase... -> ()

spawn_at :: chunk?, fragment[]?, component[]? -> entity, boolean
spawn_with :: fragment[]?, component[]? -> entity, boolean

debug_mode :: boolean -> ()
collect_garbage :: boolean, boolean
```

## Builders

```
entity :: entity_builder
entity_builder:set :: fragment, any... -> entity_builder
entity_builder:build :: entity, boolean
```

```
fragment :: fragment_builder
fragment_builder:tag :: fragment_builder
fragment_builder:name :: string -> fragment_builder
fragment_builder:single :: component -> fragment_builder
fragment_builder:default :: component -> fragment_builder
fragment_builder:construct :: {any... -> component} -> fragment_builder
fragment_builder:on_set :: {entity, fragment, component, component?} -> fragment_builder
fragment_builder:on_assign :: {entity, fragment, component, component} -> fragment_builder
fragment_builder:on_insert :: {entity, fragment, component} -> fragment_builder
fragment_builder:on_remove :: {entity, fragment} -> fragment_builder
fragment_builder:destroy_policy :: id -> fragment_builder
fragment_builder:build :: fragment, boolean
```

```
query :: query_builder
query_builder:name :: string -> query_builder
query_builder:single :: component -> query_builder
query_builder:include :: fragment... -> query_builder
query_builder:exclude :: fragment... -> query_builder
query_builder:build :: query, boolean
```

```
group :: group_builder
group_builder:name :: string -> group_builder
group_builder:single :: component -> group_builder
group_builder:disable :: group_builder
group_builder:phase :: phase -> group_builder
group_builder:after :: group... -> group_builder
group_builder:prologue :: {} -> group_builder
group_builder:epilogue :: {} -> group_builder
group_builder:build :: group, boolean
```

```
phase :: phase_builder
phase_builder:name :: string -> phase_builder
phase_builder:single :: component -> phase_builder
phase_builder:disable :: phase_builder
phase_builder:prologue :: {} -> phase_builder
phase_builder:epilogue :: {} -> phase_builder
phase_builder:build :: phase, boolean
```

```
system :: system_builder
system_builder:name :: string -> system_builder
system_builder:single :: component -> system_builder
system_builder:disable :: system_builder
system_builder:group :: group -> system_builder
system_builder:query :: query -> system_builder
system_builder:execute :: {chunk, entity[], integer} -> system_builder
system_builder:prologue :: {} -> system_builder
system_builder:epilogue :: {} -> system_builder
system_builder:build :: system, boolean
```

## [License (MIT)](./LICENSE.md)
