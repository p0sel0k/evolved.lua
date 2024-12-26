# evolved.lua

```
id :: id

pack :: integer, integer -> id
unpack :: id -> integer, integer

defer :: boolean
commit :: boolean

get :: entity, fragment...  -> component...
has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean

set :: entity, fragment, component, any... -> boolean, boolean
assign :: entity, fragment, component, any... -> boolean, boolean
insert :: entity, fragment, component, any... -> boolean, boolean
remove :: entity, fragment... -> boolean, boolean
clear :: entity -> boolean, boolean

alive :: entity -> boolean
destroy :: entity -> boolean, boolean

select :: chunk, fragment... -> component[]...
execute :: query -> {execution_state? -> chunk?, entity[]?}, execution_state?
```

## [License (MIT)](./LICENSE.md)
