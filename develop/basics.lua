local basics = {}

local __table_pack = (function()
    ---@diagnostic disable-next-line: deprecated
    return table.pack or function(...)
        return { n = select('#', ...), ... }
    end
end)()

local __table_unpack = (function()
    ---@diagnostic disable-next-line: deprecated
    return table.unpack or unpack
end)()

---@param pattern string
function basics.unload(pattern)
    for name, _ in pairs(package.loaded) do
        if name:match(pattern) then
            package.loaded[name] = nil
        end
    end
end

---@param modname string
function basics.describe_fuzz(modname)
    print(string.format('| %s ... |', modname))

    collectgarbage('collect')
    collectgarbage('stop')

    do
        local iters = 0

        local start_s = os.clock()
        local start_kb = collectgarbage('count')

        local success, result = pcall(function()
            repeat
                iters = iters + 1
                basics.unload(modname)
                require(modname)
            until os.clock() - start_s > 0.5
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
            print('|-- FUZZ FAIL: ' .. result)
        end
    end

    collectgarbage('restart')
    collectgarbage('collect')
end

---@param name string
---@param loop fun(...): ...
---@param init? fun(): ...
---@param fini? fun(...): ...
function basics.describe_bench(name, loop, init, fini)
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
            print('|-- WARMUP FAIL: ' .. result)
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
            print('|-- LOOP FAIL: ' .. result)
        end
    end

    if fini then
        local success, result = pcall(function()
            fini(__table_unpack(state))
        end)

        if not success then
            print('|-- FINI FAIL: ' .. result)
        end
    end

    collectgarbage('restart')
    collectgarbage('collect')
end

return basics
