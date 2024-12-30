# evolved.lua (work in progress)

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
select :: chunk, fragment... -> component[]?...
execute :: query -> {execute_state? -> chunk?, entity[]?}, execute_state?
```

## [License (MIT)](./LICENSE.md)
