# evolved.lua

```
id :: id
pack :: integer, integer -> id
unpack :: id -> integer, integer
alive :: id -> boolean
destroy :: id -> ()
get :: entity, fragment...  -> component...
has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean
set :: entity, fragment, component, any... -> ()
assign :: entity, fragment, component, any... -> boolean
insert :: entity, fragment, component, any... -> boolean
remove :: entity, fragment... -> ()
clear :: entity -> ()
```

## [License (MIT)](./LICENSE.md)
