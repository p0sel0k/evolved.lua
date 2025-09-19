local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 10000

print '----------------------------------------'

basics.describe_bench(string.format('Scheme Benchmarks: Evolved AoS Processing | %d entities', N),
    function(w)
        evo.process(w)
    end,

    function()
        local wf = evo.builder()
            :set(evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
            :spawn()

        local pf = evo.builder():set(wf):spawn()
        local vf = evo.builder():set(wf):spawn()

        evo.multi_spawn(N, {
            [wf] = true,
            [pf] = { x = 0, y = 0, z = 0, w = 0 },
            [vf] = { x = 0, y = 0, z = 0, w = 0 },
        })

        evo.builder()
            :set(wf)
            :set(evo.GROUP, wf)
            :set(evo.QUERY, evo.builder():set(wf):include(pf, vf):spawn())
            :set(evo.EXECUTE, function(chunk, _, entity_count)
                local ps, vs = chunk:components(pf, vf)

                for i = 1, entity_count do
                    local p, s = ps[i], vs[i]
                    p.x = p.x + s.x
                    p.y = p.y + s.y
                end
            end)
            :spawn()

        return wf
    end,

    function(w)
        evo.destroy(w)
    end)

basics.describe_bench(string.format('Scheme Benchmarks: Evolved SoA Processing | %d entities', N),
    function(w)
        evo.process(w)
    end,

    function()
        local wf = evo.builder()
            :set(evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
            :spawn()

        local pxf = evo.builder():set(wf):spawn()
        local pyf = evo.builder():set(wf):spawn()
        local pzf = evo.builder():set(wf):spawn()
        local pwf = evo.builder():set(wf):spawn()
        local vxf = evo.builder():set(wf):spawn()
        local vyf = evo.builder():set(wf):spawn()
        local vzf = evo.builder():set(wf):spawn()
        local vwf = evo.builder():set(wf):spawn()

        evo.multi_spawn(N, {
            [wf] = true,
            [pxf] = 0,
            [pyf] = 0,
            [pzf] = 0,
            [pwf] = 0,
            [vxf] = 0,
            [vyf] = 0,
            [vzf] = 0,
            [vwf] = 0,
        })

        evo.builder()
            :set(wf)
            :set(evo.GROUP, wf)
            :set(evo.QUERY, evo.builder():set(wf):include(pxf, pyf, vxf, vyf):spawn())
            :set(evo.EXECUTE, function(chunk, _, entity_count)
                local pxs, pys = chunk:components(pxf, pyf)
                local vxs, vys = chunk:components(vxf, vyf)

                for i = 1, entity_count do
                    pxs[i] = pxs[i] + vxs[i]
                    pys[i] = pys[i] + vys[i]
                end
            end)
            :spawn()

        return wf
    end,

    function(w)
        evo.destroy(w)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Scheme Benchmarks: Evolved-FFI AoS Processing | %d entities', N),
    function(w)
        evo.process(w)
    end,

    function()
        local wf = evo.builder()
            :set(evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
            :spawn()

        local vector4 = evo.scheme_record {
            x = evo.scheme_number(),
            y = evo.scheme_number(),
            z = evo.scheme_number(),
            w = evo.scheme_number(),
        }

        local pf = evo.builder():set(wf):set(evo.SCHEME, vector4):spawn()
        local vf = evo.builder():set(wf):set(evo.SCHEME, vector4):spawn()

        evo.multi_spawn(N, {
            [wf] = true,
            [pf] = { x = 0, y = 0, z = 0, w = 0 },
            [vf] = { x = 0, y = 0, z = 0, w = 0 },
        })

        evo.builder()
            :set(wf)
            :set(evo.GROUP, wf)
            :set(evo.QUERY, evo.builder():set(wf):include(pf, vf):spawn())
            :set(evo.EXECUTE, function(chunk, _, entity_count)
                local ps, vs = chunk:components(pf, vf)

                for i = 1, entity_count do
                    local p, s = ps[i], vs[i]
                    p.x = p.x + s.x
                    p.y = p.y + s.y
                end
            end)
            :spawn()

        return wf
    end,

    function(w)
        evo.destroy(w)
    end)

basics.describe_bench(string.format('Scheme Benchmarks: Evolved-FFI SoA Processing | %d entities', N),
    function(w)
        evo.process(w)
    end,

    function()
        local wf = evo.builder()
            :set(evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
            :spawn()

        local pxf = evo.builder():set(wf):set(evo.SCHEME, evo.scheme_number()):spawn()
        local pyf = evo.builder():set(wf):set(evo.SCHEME, evo.scheme_number()):spawn()
        local pzf = evo.builder():set(wf):set(evo.SCHEME, evo.scheme_number()):spawn()
        local pwf = evo.builder():set(wf):set(evo.SCHEME, evo.scheme_number()):spawn()
        local vxf = evo.builder():set(wf):set(evo.SCHEME, evo.scheme_number()):spawn()
        local vyf = evo.builder():set(wf):set(evo.SCHEME, evo.scheme_number()):spawn()
        local vzf = evo.builder():set(wf):set(evo.SCHEME, evo.scheme_number()):spawn()
        local vwf = evo.builder():set(wf):set(evo.SCHEME, evo.scheme_number()):spawn()

        evo.multi_spawn(N, {
            [wf] = true,
            [pxf] = 0,
            [pyf] = 0,
            [pzf] = 0,
            [pwf] = 0,
            [vxf] = 0,
            [vyf] = 0,
            [vzf] = 0,
            [vwf] = 0,
        })

        evo.builder()
            :set(wf)
            :set(evo.GROUP, wf)
            :set(evo.QUERY, evo.builder():set(wf):include(pxf, pyf, vxf, vyf):spawn())
            :set(evo.EXECUTE, function(chunk, _, entity_count)
                local pxs, pys = chunk:components(pxf, pyf)
                local vxs, vys = chunk:components(vxf, vyf)

                for i = 1, entity_count do
                    pxs[i] = pxs[i] + vxs[i]
                    pys[i] = pys[i] + vys[i]
                end
            end)
            :spawn()

        return wf
    end,

    function(w)
        evo.destroy(w)
    end)
