# Roadmap

## Backlog

- Improve the performance of required fragments by caching first-level required chunks.
- Improve the performance of builders that are used multiple times by caching hint chunks.
- Queries can cache major chunks to avoid finding them every time.
- Should we make one builder:build method instead of :spawn and :clone?
- Add multi-spawn to the builder to spawn multiple entities at once.
- Add a function to shrink storages to free unused memory.
- Should we cache the result of without_unique_fragments to clone faster?
- observers and events
- add INDEX fragment trait
- use compact prefix-tree for chunks
- optional ffi component storages
- add EXCLUSIVE fragment trait
