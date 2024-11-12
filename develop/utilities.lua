local utilities = {}

---@param vs any[]
function utilities.shuffle_array(vs)
    for i = 1, #vs do
        local j = math.random(i, #vs)
        vs[i], vs[j] = vs[j], vs[i]
    end
end

return utilities
