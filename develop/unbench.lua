local evolved = require 'evolved'
local utilities = require 'develop.utilities'

---@param name string
---@param func fun(...):...
---@param ... any
local function describe(name, func, ...)
    collectgarbage('stop')

    print(string.format('| unbench | %s ...', name))

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

describe('memory footprint of 1k entities', function()
    local registry = evolved.registry()
    for _ = 1, 1000 do registry:entity() end
end)

describe('memory footprint of 10k entities', function()
    local registry = evolved.registry()
    for _ = 1, 10000 do registry:entity() end
end)

describe('memory footprint of 100k entities', function()
    local registry = evolved.registry()
    for _ = 1, 100000 do registry:entity() end
end)
