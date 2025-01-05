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
    print(string.format('| %s ... |', name))

    local state = init and __table_pack(init()) or {}

    do
        local warmup_s = os.clock()

        local success, result = pcall(function()
            repeat
                loop(__table_unpack(state))
            until os.clock() - warmup_s > 0.1
        end)

        if not success then
            print('|-- FAIL: ' .. result)
            return
        end
    end

    collectgarbage('collect')
    collectgarbage('stop')

    do
        local iters = 0

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

        if success then
            print(string.format('|-- PASS | us: %.2f | op/s: %.2f | kb/i: %.2f | iters: %d',
                (finish_s - start_s) * 1e6 / iters,
                iters / (finish_s - start_s),
                (finish_kb - start_kb) / iters,
                iters))
        else
            print('|-- FAIL: ' .. result)
        end
    end

    collectgarbage('restart')
    collectgarbage('collect')
end

return basics
