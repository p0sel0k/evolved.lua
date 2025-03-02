# Roadmap

## Backlog

- add manual gc for unreachable chunks
- add destroing policies (fragments, phases, systems)
- add debug view for chunks with help of NAME fragment traits

## Known issues

- destroying of fragments leave chunks with dead fragments (destroing policies)
- destroying of systems can leave dead systems in the library state (destroying policies)
- destroying of phases can leave dead phases in the library state (destroying policies)

## After first release

- add system groups
- auto chunk count reducing
- add INDEX fragment trait
- add REQUIRES fragment trait
- use compact prefix-tree for chunks
- set/assign/insert/remove/clear/destroy for lists
- optional ffi component storages
- keep entity_chunks/places tables as arrays
