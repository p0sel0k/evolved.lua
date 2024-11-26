---@class evolved.idpools
local idpools = {}

---
---
---
---
---

---@alias evolved.id integer

---@class evolved.idpool
---@field package __freelist_ids evolved.id[]
---@field package __available_index integer
local evolved_idpool_mt = {}
evolved_idpool_mt.__index = evolved_idpool_mt

---
---
---
---
---

---@return evolved.idpool
function idpools.idpool()
    ---@type evolved.idpool
    local idpool = {
        __freelist_ids = {},
        __available_index = 0,
    }
    return setmetatable(idpool, evolved_idpool_mt)
end

---@param index integer
---@param version integer
---@return evolved.id
function idpools.pack(index, version)
    assert(index >= 1 and index <= 0xFFFFF, 'id index out of range [1;0xFFFFF]')
    assert(version >= 1 and version <= 0x7FF, 'id version out of range [1;0x7FF]')
    return index + version * 0x100000
end

---@param id evolved.id
---@return integer index
---@return integer version
function idpools.unpack(id)
    local index = id % 0x100000
    local version = (id - index) / 0x100000
    return index, version
end

---@param idpool evolved.idpool
---@param id evolved.id
---@return boolean
---@nodiscard
function idpools.alive(idpool, id)
    local index = id % 0x100000
    return idpool.__freelist_ids[index] == id
end

---@param idpool evolved.idpool
---@return evolved.id
---@nodiscard
function idpools.acquire(idpool)
    if idpool.__available_index ~= 0 then
        local index = idpool.__available_index
        local freelist_id = idpool.__freelist_ids[index]
        idpool.__available_index = freelist_id % 0x100000
        local version = freelist_id - idpool.__available_index

        local acquired_id = index + version
        idpool.__freelist_ids[index] = acquired_id
        return acquired_id
    else
        if #idpool.__freelist_ids == 0xFFFFF then
            error('id index overflow', 2)
        end

        local index = #idpool.__freelist_ids + 1
        local version = 0x100000

        local acquired_id = index + version
        idpool.__freelist_ids[index] = acquired_id
        return acquired_id
    end
end

---@param idpool evolved.idpool
---@param id evolved.id
function idpools.release(idpool, id)
    local index = id % 0x100000
    local version = id - index

    if idpool.__freelist_ids[index] ~= id then
        error('id is not acquired or already released', 2)
    end

    version = version == 0x7FF00000
        and 0x100000
        or version + 0x100000

    idpool.__freelist_ids[index] = idpool.__available_index + version
    idpool.__available_index = index
end

---
---
---
---
---

evolved_idpool_mt.pack = idpools.pack
evolved_idpool_mt.unpack = idpools.unpack
evolved_idpool_mt.alive = idpools.alive
evolved_idpool_mt.acquire = idpools.acquire
evolved_idpool_mt.release = idpools.release

---
---
---
---
---

return idpools
