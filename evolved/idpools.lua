local bit = require 'bit'

---@class evolved.idpools
local idpools = {}

---@class evolved.idpool
---@field acquired_ids integer[]
---@field available_index integer
local evolved_idpool_mt = {}
evolved_idpool_mt.__index = evolved_idpool_mt

---@return evolved.idpool
function idpools.idpool()
    ---@type evolved.idpool
    local self = {
        acquired_ids = {},
        available_index = 0,
    }
    return setmetatable(self, evolved_idpool_mt)
end

---@param id integer
---@return integer index
---@return integer version
function idpools.unpack_id(id)
    return bit.band(id, 0xFFFFF), bit.rshift(id, 20)
end

---@param idpool evolved.idpool
---@return integer
---@nodiscard
function idpools.acquire_id(idpool)
    if idpool.available_index ~= 0 then
        local index = idpool.available_index
        local version = bit.band(idpool.acquired_ids[index], 0x7FF00000)
        idpool.available_index = bit.band(idpool.acquired_ids[index], 0xFFFFF)
        idpool.acquired_ids[index] = index + version
        return idpool.acquired_ids[index]
    end

    if #idpool.acquired_ids == 0xFFFFF then
        error('id index overflow', 2)
    end

    local index, version = #idpool.acquired_ids + 1, 0x100000
    idpool.acquired_ids[index] = index + version
    return idpool.acquired_ids[index]
end

---@param idpool evolved.idpool
---@param id integer
function idpools.release_id(idpool, id)
    local index = bit.band(id, 0xFFFFF)
    local version = bit.band(id, 0x7FF00000)
    version = version == 0x7FF00000 and 0x100000 or version + 0x100000
    idpool.acquired_ids[index] = idpool.available_index + version
    idpool.available_index = index
end

---@param idpool evolved.idpool
---@param id integer
---@return boolean
---@nodiscard
function idpools.is_id_alive(idpool, id)
    local index = bit.band(id, 0xFFFFF)
    return idpool.acquired_ids[index] == id
end

return idpools
