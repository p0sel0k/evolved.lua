---@param pattern string
return function(pattern)
    for name, _ in pairs(package.loaded) do
        if name:match(pattern) then
            package.loaded[name] = nil
        end
    end
end
