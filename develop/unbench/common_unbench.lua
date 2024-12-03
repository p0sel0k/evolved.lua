local evo = require 'evolved.evolved'

local common = {}

---@param name string
---@param loop fun(...): ...
---@param init fun(): ...
function common.describe(name, loop, init)
    collectgarbage('stop')

    print(string.format('| %s ... |', name))

    local state = evo.compat.pack(init())

    local iters = 0
    local start_s = os.clock()
    local start_kb = collectgarbage('count')

    local success, result = pcall(function()
        repeat
            iters = iters + 1
            loop(evo.compat.unpack(state))
        until os.clock() - start_s > 0.2
    end)

    local finish_s = os.clock()
    local finish_kb = collectgarbage('count')

    print(string.format('    %s | us: %.2f | op/s: %.2f | kb/i: %.2f',
        success and 'OK' or 'FAILED',
        (finish_s - start_s) * 1000 * 1000 / iters,
        iters / (finish_s - start_s),
        (finish_kb - start_kb) / iters))

    if not success then print('    ' .. result) end

    collectgarbage('restart')
    collectgarbage('collect')
end

return common
