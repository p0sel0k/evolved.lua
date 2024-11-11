local evolved = require 'evolved'

---@param name string
---@param func fun(...):...
---@param ... any
local function describe(name, func, ...)
    collectgarbage('stop')

    print(string.format('- %s ...', name))

    local start_s = os.clock()
    local start_kb = collectgarbage('count')

    local success, result = pcall(func, ...)

    local finish_s = os.clock() - start_s
    local finish_kb = collectgarbage('count') - start_kb

    print(string.format('    %s | ms: %.2f | mb: %.2f',
        success and 'OK' or 'FAILED', finish_s * 1000, finish_kb / 1024))

    if not success then print('    ' .. result) end

    collectgarbage('restart')
end
