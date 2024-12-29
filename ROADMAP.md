# Roadmap

## Backlog

- add tag-fragment trait
- should insert/assign throw errors on failure?
- add auto chunk count reducing
- batching api for set/assign/insert/remove/clear/destroy
- every chunk can hold has_on_assign/has_on_insert/has_on_remove tags
- rename alive/empty to is_alive/is_empty
- optimize batch operations for cases with moving entities to empty chunks
- optimize batch operations for cases with fragments without constructs
- don't create empty exclude_set in execution every time when it's not exist
