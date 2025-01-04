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

DEFAULT :: fragment
CONSTRUCT :: fragment

ON_SET :: fragment
ON_ASSIGN :: fragment
ON_INSERT :: fragment
ON_REMOVE :: fragment

INCLUDE_LIST :: fragment
EXCLUDE_LIST :: fragment
```

## Functions

```
id :: integer? -> id...

pack :: integer, integer -> id
unpack :: id -> integer, integer

defer :: boolean
commit :: boolean

is_alive :: entity -> boolean
is_empty :: entity -> boolean

get :: entity, fragment...  -> component...
has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean

set :: entity, fragment, any... -> boolean, boolean
assign :: entity, fragment, any... -> boolean, boolean
insert :: entity, fragment, any... -> boolean, boolean
remove :: entity, fragment... -> boolean, boolean
clear :: entity -> boolean, boolean
destroy :: entity -> boolean, boolean

batch_set :: query, fragment, any... -> integer, boolean
batch_assign :: query, fragment, any... -> integer, boolean
batch_insert :: query, fragment, any... -> integer, boolean
batch_remove :: query, fragment... -> integer, boolean
batch_clear :: query -> integer, boolean
batch_destroy :: query -> integer, boolean

chunk :: fragment... -> chunk?, entity[]?
select :: chunk, fragment... -> component[]...

each :: entity -> {each_state? -> fragment?, component?}, each_state?
execute :: query -> {execute_state? -> chunk?, entity[]?}, execute_state?
```

## [License (MIT)](./LICENSE.md)
