# evolved.lua

```
id :: id
alive :: id -> boolean
destroy :: id -> ()
get :: entity, fragment...  -> component...
has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean
set :: entity, fragment, component -> ()
assign :: entity, fragment, component -> boolean
insert :: entity, fragment, component -> boolean
remove :: entity, fragment... -> ()
clear :: entity -> ()
```

## [License (MIT)](./LICENSE.md)
