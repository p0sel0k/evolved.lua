---@class evolved.vectors
local vectors = {}

---@class evolved.vector2
---@field x number
---@field y number
local vector2_mt = {}
vector2_mt.__index = vector2_mt

---@param x number
---@param y number
---@return evolved.vector2
---@nodiscard
local function vector2(x, y)
    ---@type evolved.vector2
    local v = { x = x, y = y }
    return setmetatable(v, vector2_mt)
end

---@param v evolved.vector2
---@return evolved.vector2
---@nodiscard
function vector2_mt.__unm(v)
    return vector2(-v.x, -v.y)
end

---@param a number | evolved.vector2
---@param b number | evolved.vector2
---@return evolved.vector2
---@nodiscard
function vector2_mt.__add(a, b)
    if type(a) == 'number' then
        return vector2(a + b.x, a + b.y)
    elseif type(b) == 'number' then
        return vector2(a.x + b, a.y + b)
    else
        return vector2(a.x + b.x, a.y + b.y)
    end
end

---@param a number | evolved.vector2
---@param b number | evolved.vector2
---@return evolved.vector2
---@nodiscard
function vector2_mt.__sub(a, b)
    if type(a) == 'number' then
        return vector2(a - b.x, a - b.y)
    elseif type(b) == 'number' then
        return vector2(a.x - b, a.y - b)
    else
        return vector2(a.x - b.x, a.y - b.y)
    end
end

---@param a number | evolved.vector2
---@param b number | evolved.vector2
---@return evolved.vector2
---@nodiscard
function vector2_mt.__mul(a, b)
    if type(a) == 'number' then
        return vector2(a * b.x, a * b.y)
    elseif type(b) == 'number' then
        return vector2(a.x * b, a.y * b)
    else
        return vector2(a.x * b.x, a.y * b.y)
    end
end

---@param a number | evolved.vector2
---@param b number | evolved.vector2
---@return evolved.vector2
---@nodiscard
function vector2_mt.__div(a, b)
    if type(a) == 'number' then
        return vector2(a / b.x, a / b.y)
    elseif type(b) == 'number' then
        return vector2(a.x / b, a.y / b)
    else
        return vector2(a.x / b.x, a.y / b.y)
    end
end

---@param a evolved.vector2
---@param b evolved.vector2
---@return boolean
---@nodiscard
function vector2_mt.__eq(a, b)
    return a.x == b.x and a.y == b.y
end

---@param a evolved.vector2
---@param b evolved.vector2
---@return boolean
---@nodiscard
function vector2_mt.__le(a, b)
    return a.x < b.x or (a.x == b.x and a.y <= b.y)
end

---@param a evolved.vector2
---@param b evolved.vector2
---@return boolean
---@nodiscard
function vector2_mt.__lt(a, b)
    return a.x < b.x or (a.x == b.x and a.y < b.y)
end

---@param v evolved.vector2
---@return string
---@nodiscard
function vector2_mt.__tostring(v)
    return string.format('(%f, %f)', v.x, v.y)
end

---
---
---
---
---

---@param x number
---@param y number
---@return evolved.vector2
---@nodiscard
function vectors.vector2(x, y)
    return vector2(x, y)
end

---@param v any
---@return boolean
---@nodiscard
function vectors.is_vector2(v)
    return getmetatable(v) == vector2_mt
end

return vectors
