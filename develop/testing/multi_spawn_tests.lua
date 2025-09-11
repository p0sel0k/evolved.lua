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

do
    local f1, f2, f3 = evo.id(3)

    do
        local entity_list1, entity_list2

        evo.defer()
        do
            entity_list1 = evo.multi_spawn(2, { [f1] = 42, [f2] = "hello", [f3] = false })
            assert(entity_list1 and #entity_list1 == 2)
            assert(entity_list1[1] and evo.empty(entity_list1[1]))
            assert(entity_list1[2] and evo.empty(entity_list1[2]))
            assert(not entity_list1[3])

            entity_list2 = evo.multi_spawn(3, { [f2] = "world", [f3] = true })
            assert(entity_list2 and #entity_list2 == 3)
            assert(entity_list2[1] and evo.empty(entity_list2[1]))
            assert(entity_list2[2] and evo.empty(entity_list2[2]))
            assert(entity_list2[3] and evo.empty(entity_list2[3]))
        end
        evo.commit()
        do
            assert(entity_list1 and #entity_list1 == 2)
            assert(entity_list1[1] and not evo.empty(entity_list1[1]))
            assert(entity_list1[2] and not evo.empty(entity_list1[2]))
            assert(not entity_list1[3])
            assert(
                evo.get(entity_list1[1], f1) == 42 and
                evo.get(entity_list1[1], f2) == "hello" and
                evo.get(entity_list1[1], f3) == false)
            assert(
                evo.get(entity_list1[2], f1) == 42 and
                evo.get(entity_list1[2], f2) == "hello" and
                evo.get(entity_list1[2], f3) == false)

            assert(entity_list2 and #entity_list2 == 3)
            assert(entity_list2[1] and not evo.empty(entity_list2[1]))
            assert(entity_list2[2] and not evo.empty(entity_list2[2]))
            assert(entity_list2[3] and not evo.empty(entity_list2[3]))
            assert(not entity_list2[4])
            assert(
                evo.get(entity_list2[1], f1) == nil and
                evo.get(entity_list2[1], f2) == "world" and
                evo.get(entity_list2[1], f3) == true)
            assert(
                evo.get(entity_list2[2], f1) == nil and
                evo.get(entity_list2[2], f2) == "world" and
                evo.get(entity_list2[2], f3) == true)
            assert(
                evo.get(entity_list2[3], f1) == nil and
                evo.get(entity_list2[3], f2) == "world" and
                evo.get(entity_list2[3], f3) == true)
        end
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local prefab = evo.builder():set(f1, false):set(f2, 123):spawn()

        local entity_list1, entity_list2

        evo.defer()
        do
            entity_list1 = evo.multi_clone(2, prefab)
            assert(entity_list1 and #entity_list1 == 2)
            assert(entity_list1[1] and evo.empty(entity_list1[1]))
            assert(entity_list1[2] and evo.empty(entity_list1[2]))
            assert(not entity_list1[3])

            entity_list2 = evo.multi_clone(3, prefab, { [f2] = 456, [f3] = "world" })
            assert(entity_list2 and #entity_list2 == 3)
            assert(entity_list2[1] and evo.empty(entity_list2[1]))
            assert(entity_list2[2] and evo.empty(entity_list2[2]))
            assert(entity_list2[3] and evo.empty(entity_list2[3]))
        end
        evo.commit()
        do
            assert(entity_list1 and #entity_list1 == 2)
            assert(entity_list1[1] and not evo.empty(entity_list1[1]))
            assert(entity_list1[2] and not evo.empty(entity_list1[2]))
            assert(not entity_list1[3])
            assert(
                evo.get(entity_list1[1], f1) == false and
                evo.get(entity_list1[1], f2) == 123 and
                evo.get(entity_list1[1], f3) == nil)
            assert(
                evo.get(entity_list1[2], f1) == false and
                evo.get(entity_list1[2], f2) == 123 and
                evo.get(entity_list1[2], f3) == nil)

            assert(entity_list2 and #entity_list2 == 3)
            assert(entity_list2[1] and not evo.empty(entity_list2[1]))
            assert(entity_list2[2] and not evo.empty(entity_list2[2]))
            assert(entity_list2[3] and not evo.empty(entity_list2[3]))
            assert(not entity_list2[4])
            assert(
                evo.get(entity_list2[1], f1) == false and
                evo.get(entity_list2[1], f2) == 456 and
                evo.get(entity_list2[1], f3) == "world")
            assert(
                evo.get(entity_list2[2], f1) == false and
                evo.get(entity_list2[2], f2) == 456 and
                evo.get(entity_list2[2], f3) == "world")
            assert(
                evo.get(entity_list2[3], f1) == false and
                evo.get(entity_list2[3], f2) == 456 and
                evo.get(entity_list2[3], f3) == "world")
        end
    end
end
