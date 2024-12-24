# evolved.lua

```
id :: id

pack :: integer, integer -> id
unpack :: id -> integer, integer

defer :: ()
commit :: ()

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
```

## [License (MIT)](./LICENSE.md)
