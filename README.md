# evolved.lua

```
id :: id
pack :: integer, integer -> id
unpack :: id -> integer, integer
alive :: id -> boolean
get :: entity, fragment...  -> component...
has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean
set :: entity, fragment, component, any... -> ()
assign :: entity, fragment, component, any... -> boolean
insert :: entity, fragment, component, any... -> boolean
remove :: entity, fragment... -> ()
clear :: entity -> ()
destroy :: entity -> ()
```

```
defer :: defer

defer:set :: id, fragment, component, any... -> defer
defer:assign :: id, fragment, component, any... -> defer
defer:insert :: id, fragment, component, any... -> defer
defer:remove :: id, fragment... -> defer
defer:clear :: id -> defer
defer:destroy :: id -> defer
defer:playback :: ()
```

## [License (MIT)](./LICENSE.md)
