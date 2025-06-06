local evo = require 'evolved'

evo.debug_mode(true)

---
---
---
---
---

for _ = 1, 1000 do
    local initial_index = math.random(1, 0xFFFFF)
    local initial_version = math.random(1, 0xFFFFF)

    local packed_id = evo.pack(initial_index, initial_version)
    local unpacked_index, unpacked_version = evo.unpack(packed_id)

    assert(initial_index == unpacked_index)
    assert(initial_version == unpacked_version)
end
