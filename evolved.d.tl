-- evolved.d.tl
-- evolve.lua ver.: 1.4
-- Teal declaration file for the public API of evolved.lua

local record Evolved

    record ID
    end

    type Entity = ID
    type Fragment = ID
    type Query = ID
    type System = ID
    type Component = any

    type Storage = { Component }
    type EachState = { integer, Chunk, integer, integer }
    type ExecuteState = { integer, { Chunk }, integer, {Fragment: integer} | nil }

    type EachIterator = function(state?: EachState): (Fragment | nil, Component | nil)
    type ExecuteIterator = function(state?: ExecuteState): (Chunk | nil, { Entity } | nil, integer | nil)

    type Execute = function(chunk: Chunk, entity_list: { Entity }, entity_count: integer)
    type Prologue = function()
    type Epilogue = function()

    type SetHook<T> = function(entity: Entity, fragment: Fragment, new: T, old?: T)
    type AssignHook<T> = function(entity: Entity, fragment: Fragment, new: T, old?: T)
    type InsertHook<T> = function(entity: Entity, fragment: Fragment, new: T)
    type RemoveHook<T> = function(entity: Entity, fragment: Fragment, component: T)

    record Chunk
        alive: function(self: Chunk): boolean
        empty: function(self: Chunk): boolean
        has: function(self: Chunk, fragment: Fragment): boolean
        has_all: function(self: Chunk, ...: Fragment): boolean
        has_any: function(self: Chunk, ...: Fragment): boolean
        entities: function(self: Chunk): ({ Entity }, number)
        fragments: function(self: Chunk): ({ Fragment }, number)
        components: function(self: Chunk, ...: Fragment): Storage...
    end

    record Builder
        build: function(self: Builder, prefab?: Entity): Entity
        multi_build: function(self: Builder, entity_count: number, prefab?: Entity): ({ Entity }, number)
        spawn: function(self: Builder): Entity
        multi_spawn: function(self: Builder, entity_count: number): ({ Entity }, number)
        clone: function(self: Builder, prefab: Entity): Entity
        multi_clone: function(self: Builder, entity_count: number, prefab: Entity): ({ Entity }, number)
        has: function(self: Builder, fragment: Fragment): boolean
        has_all: function(self: Builder, ...: Fragment): boolean
        has_any: function(self: Builder, ...: Fragment): boolean
        get: function(self: Builder, ...: Fragment): Component...
        set: function<T>(self: Builder, fragment: Fragment, component?: T): Builder
        remove: function(self: Builder, ...: Fragment): Builder
        clear: function(self: Builder): Builder
        tag: function(self: Builder): Builder
        name: function(self: Builder, name: string): Builder
        unique: function(self: Builder): Builder
        explicit: function(self: Builder): Builder
        internal: function(self: Builder): Builder
        default: function<T>(self: Builder, default: T): Builder
        duplicate: function<T>(self: Builder, duplicate: function(T): T): Builder
        prefab: function(self: Builder): Builder
        disabled: function(self: Builder): Builder
        include: function(self: Builder, ...: Fragment): Builder
        exclude: function(self: Builder, ...: Fragment): Builder
        require: function(self: Builder, ...: Fragment): Builder
        on_set: function<T>(self: Builder, on_set: SetHook<T>): Builder
        on_assign: function<T>(self: Builder, on_assign: AssignHook<T>): Builder
        on_insert: function<T>(self: Builder, on_insert: InsertHook<T>): Builder
        on_remove: function<T>(self: Builder, on_remove: RemoveHook<T>): Builder
        group: function(self: Builder, group: System): Builder
        query: function(self: Builder, query: Query): Builder
        execute: function(self: Builder, execute: Execute): Builder
        prologue: function(self: Builder, prologue: Prologue): Builder
        epilogue: function(self: Builder, epilogue: Epilogue): Builder
        destruction_policy: function(self: Builder, policy: ID): Builder
    end

    TAG: Fragment
    NAME: Fragment

    UNIQUE: Fragment
    EXPLICIT: Fragment
    INTERNAL: Fragment

    DEFAULT: Fragment
    DUPLICATE: Fragment

    PREFAB: Fragment
    DISABLED: Fragment

    INCLUDES: Fragment
    EXCLUDES: Fragment
    REQUIRES: Fragment

    ON_SET: Fragment
    ON_ASSIGN: Fragment
    ON_INSERT: Fragment
    ON_REMOVE: Fragment

    GROUP: Fragment

    QUERY: Fragment
    EXECUTE: Fragment
    PROLOGUE: Fragment
    EPILOGUE: Fragment

    DESTRUCTION_POLICY: Fragment
    DESTRUCTION_POLICY_DESTROY_ENTITY: ID
    DESTRUCTION_POLICY_REMOVE_FRAGMENT: ID

    id: function(count?: number): ID...
    name: function(...: ID): string...

    pack: function(primary: number, secondary: number): ID
    unpack: function(id: ID): (number, number)

    defer: function(): boolean
    commit: function(): boolean
    cancel: function(): boolean

    spawn: function(components?: { Fragment: Component }): Entity
    multi_spawn: function(entity_count: number, components?: { Fragment: Component }): ({ Entity }, number)

    clone: function(prefab: Entity, components?: { Fragment: Component }): Entity
    multi_clone: function(entity_count: number, prefab: Entity, components?: { Fragment: Component }): ({ Entity }, number)

    alive: function(entity: Entity): boolean
    alive_all: function(...: Entity): boolean
    alive_any: function(...: Entity): boolean

    empty: function(entity: Entity): boolean
    empty_all: function(...: Entity): boolean
    empty_any: function(...: Entity): boolean

    has: function(entity: Entity, fragment: Fragment): boolean
    has_all: function(entity: Entity, ...: Fragment): boolean
    has_any: function(entity: Entity, ...: Fragment): boolean

    get: function(entity: Entity, ...: Fragment): Component...
    set: function<T>(entity: Entity, fragment: Fragment, component: T)
    remove: function(entity: Entity, ...: Fragment)
    clear: function(...: Entity)
    destroy: function(...: Entity)

    batch_set: function<T>(query: Query, fragment: Fragment, component: T)
    batch_remove: function(query: Query, ...: Fragment)
    batch_clear: function(...: Query)
    batch_destroy: function(...: Query)

    each: function(entity: Entity): (EachIterator, EachState | nil)
    execute: function(query: Query): (ExecuteIterator, ExecuteState | nil)
    locate: function(entity: Entity): (any | nil, number)

    process: function(...: System)
    debug_mode: function(yesno: boolean)
    collect_garbage: function()

    chunk: function(fragment: Fragment, ...: Fragment): (Chunk, { Entity }, integer)
    builder: function(): Builder
end

return Evolved
