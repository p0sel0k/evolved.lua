# Roadmap

## Backlog

- optimize batch operations for cases with moving entities to empty chunks
- should we clear chunk's components by on_insert tag callback?
- try to keep entity_chunks/places tables as arrays
- we shouldn't clear big reusable tables
- add fragment_builder:on_set/on_assign/on_insert/on_remove

## After first release

- auto chunk count reducing
- add REQUIRES fragment trait
- set/assign/insert/remove/clear/destroy for lists
