local basics = {}

local __table_pack = (function()
    return table.pack or function(...)
        return { n = select('#', ...), ... }
    end
end)()

local __table_unpack = (function()
    return table.unpack or unpack
end)()

---@param name string
---@param loop fun(...): ...
---@param init? fun(): ...
function basics.describe_bench(name, loop, init)
    collectgarbage('collect')
    collectgarbage('stop')

    print(string.format('| %s ... |', name))

    local iters = 0
    local state = init and __table_pack(init()) or {}

    pcall(function()
        local warmup_s = os.clock()
        repeat
            loop(__table_unpack(state))
        until os.clock() - warmup_s > 0.1
    end)

    local start_s = os.clock()
    local start_kb = collectgarbage('count')

    local success, result = pcall(function()
        repeat
            iters = iters + 1
            loop(__table_unpack(state))
        until os.clock() - start_s > 0.1
    end)

    local finish_s = os.clock()
    local finish_kb = collectgarbage('count')

    print(string.format('    %s | us: %.2f | op/s: %.2f | kb/i: %.2f | iters: %d',
        success and 'PASS' or 'FAIL',
        (finish_s - start_s) * 1e6 / iters,
        iters / (finish_s - start_s),
        (finish_kb - start_kb) / iters,
        iters))

    if not success then print('    ' .. result) end

    collectgarbage('restart')
    collectgarbage('collect')
end

return basics
