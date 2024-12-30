# Roadmap

## Backlog

- should insert/assign throw errors on failure?
- add auto chunk count reducing
- every chunk can hold has_on_assign/has_on_insert/has_on_remove tags
- optimize batch operations for cases with moving entities to empty chunks
- should we clear chunk's components by on_insert tag callback?
- use table.new/clear for cached tables
- add `each :: entity -> {each_state? -> fragment?, component?}, each_state?` function
- replace chunk_list/fragment_list pools to one generic table pool
