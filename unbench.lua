local evolved = require 'evolved'

---@param name string
---@param func fun(...):...
---@param ... any
local function describe(name, func, ...)
    collectgarbage('stop')

    print(string.format('- %s ...', name))

    local start_s = os.clock()
    local start_kb = collectgarbage('count')

    local success = pcall(func, ...)

    local finish_s = os.clock() - start_s
    local finish_kb = collectgarbage('count') - start_kb

    print(string.format('    %s | ms: %f | kb: %f',
        success and 'OK' or 'FAILED', finish_s * 1000, finish_kb))

    collectgarbage('restart')
end
