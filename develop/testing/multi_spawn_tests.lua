local evo = require 'evolved'

do
    local entity_list

    do
        entity_list = evo.multi_spawn(0)
        assert(entity_list and #entity_list == 0)

        entity_list = evo.multi_spawn(0, {})
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.multi_spawn(-1)
        assert(entity_list and #entity_list == 0)

        entity_list = evo.multi_spawn(-1, {})
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.builder():multi_spawn(0)
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.builder():multi_spawn(-1)
        assert(entity_list and #entity_list == 0)
    end
end

do
    local entity_list

    do
        entity_list = evo.multi_spawn(1)
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])

        entity_list = evo.multi_spawn(1, {})
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])
    end

    do
        entity_list = evo.multi_spawn(2)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])

        entity_list = evo.multi_spawn(2, {})
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])
    end

    do
        entity_list = evo.builder():multi_spawn(1)
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])
    end

    do
        entity_list = evo.builder():multi_spawn(2)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])
    end
end

do
    local entity_list

    local prefab = evo.id()

    do
        entity_list = evo.multi_clone(0, prefab)
        assert(entity_list and #entity_list == 0)

        entity_list = evo.multi_clone(0, prefab, {})
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.multi_clone(-1, prefab)
        assert(entity_list and #entity_list == 0)

        entity_list = evo.multi_clone(-1, prefab, {})
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.builder():multi_clone(0, prefab)
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.builder():multi_clone(-1, prefab)
        assert(entity_list and #entity_list == 0)
    end
end

do
    local entity_list

    local prefab = evo.id()

    do
        entity_list = evo.multi_clone(1, prefab)
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])

        entity_list = evo.multi_clone(1, prefab, {})
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])
    end

    do
        entity_list = evo.multi_clone(2, prefab)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])

        entity_list = evo.multi_clone(2, prefab, {})
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])
    end

    do
        entity_list = evo.builder():multi_clone(1, prefab)
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])
    end

    do
        entity_list = evo.builder():multi_clone(2, prefab)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local entity_list

        entity_list = evo.multi_spawn(2, { [f1] = true, [f2] = 123 })
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == true and evo.get(entity_list[1], f2) == 123)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == true and evo.get(entity_list[2], f2) == 123)

        entity_list = evo.multi_spawn(2, { [f1] = false, [f2] = 456 })
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == false and evo.get(entity_list[1], f2) == 456)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == false and evo.get(entity_list[2], f2) == 456)
    end

    do
        local prefab = evo.builder():set(f1, true):set(f2, 123):spawn()

        local entity_list

        entity_list = evo.multi_clone(2, prefab)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == true and evo.get(entity_list[1], f2) == 123)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == true and evo.get(entity_list[2], f2) == 123)

        entity_list = evo.multi_clone(2, prefab, {})
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == true and evo.get(entity_list[1], f2) == 123)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == true and evo.get(entity_list[2], f2) == 123)

        entity_list = evo.multi_clone(2, prefab, { [f1] = false, [f2] = 456 })
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == false and evo.get(entity_list[1], f2) == 456)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == false and evo.get(entity_list[2], f2) == 456)
    end
end
