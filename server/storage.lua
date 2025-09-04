Storage = Storage or {
    All = {}
}

---@class StashTarget
--- A structure representing a stash target.
--- @field label string The label for the stash target.
--- @field description string The description for the stash target.
--- @field icon string The icon for the stash target.

---@class StashData
--- A structure representing a stash entity.
--- @field label string The label for the stash.
--- @field slots number The number of slots in the stash.
--- @field target StashTarget The target information for open stash
--- @field disable boolean Indicates if the stash is disabled. Disables the stash target

---@class StorageData
--- A structure representing a storage entity.
--- @field id string|number The unique identifier for the storage entity.
--- @field model string The model of the storage entity.
--- @field name string The name of the storage entity.
--- @field coords vector3 The coordinates where the storage entity is located.
--- @field rotation vector3|number The rotation of the storage entity.
--- @field isPickupable string|boolean Indicates if the storage entity is pickupable.
--- @field stash table The stash information for the storage entity.
--- @field model string The model of the storage entity.

---@class Lock
--- A structure representing a lock entity.
--- @field code string The code for the lock.
--- @field name string The name/type of the lock.
--- @field locked boolean Indicates if the lock is currently locked. Changes targets from locked to unlocked / vice versa
--- @field owner string The identifier of the lock owner.
--- @field disable boolean Indicates if the lock is disabled. Will disable targets

---Create a new storage at a specific location
--- @param storageData StorageData
--- @return entityData table
function Storage.Create(storageData)
    if storageData.lock?.code then
        Lock.Create(storageData.id, storageData.lock.code)
        storageData.lock.code = nil
    end
    local entityData = Bridge.Entity.Create(storageData)
    Storage.All = Storage.All or {}
    Storage.All[entityData.id] = entityData
    return entityData
end

function Storage.GetClosest(coords)
    local closest = nil
    local closestDist = -1
    for id, _ in pairs(Storage.All) do
        local entity = Bridge.Entity.Get(id)
        local entityCoords = vector3(entity.coords.x, entity.coords.y, entity.coords.z)
        coords = vector3(coords.x, coords.y, coords.z)
        local dist = #(entityCoords - coords)
        if closestDist == -1 or dist < closestDist then
            closest = entity
            closestDist = dist
        end
    end
    return closest, closestDist
end

function Storage.New(name)
    local storageConfig = Storage.Config(name)
    if not storageConfig then return end
    local tbl = {}
    for k, v in pairs(storageConfig) do
        if v.lock?.code then
            Lock.Create(v.id, v.lock.code)
            v.lock.code = nil
        end
        tbl[k] = v
    end
    return tbl
end

function Storage.Place(id, name, coords, rotation, lock)
    local storageConfig = Storage.Config(name)
    print(json.encode(storageConfig))
    storageConfig.id = id
    storageConfig.coords = coords
    storageConfig.rotation = rotation or vector3(0.0, 0.0, 0.0)
    storageConfig.isPickupable = name
    if storageConfig.lock or lock?.name then
        storageConfig.lock = lock or storageConfig.lock or {}
        storageConfig.lock.name = storageConfig.lock.name or lock.name
    end
    
    local storage = Storage.Create(storageConfig)
    if storage.lock and not storage.lock.code then
        storage.lock.code = Lock.GetCode(id)
    end
    StorageSQL.Save(storage.id, storage)
    return storage
end

function Storage.Setup()
    local bulk = {}
    local load = StorageSQL.Load()
    for k, v in pairs(load) do
        if v.lock?.code then
            Lock.Create(v.id, v.lock.code)
            v.lock.code = nil
        end
        bulk[#bulk + 1] = v
        Storage.All[v.id] = v
    end
    local all = Bridge.Tables.DeepClone(Config.Storages or {})
    for k, v in pairs(all) do
        for i, d in pairs(v.locations or {}) do
            local storage = {}
            storage.id = k..i
            storage.model = v.model
            storage.name = k
            storage.coords = d.coords.xyz
            storage.heading = d.w or 0
            storage.entityType = v.entityType or "object"
            if d.lock then
                storage.lock = Config.Lock[d.lock.name]
                storage.lock.locked = true
                Lock.Create(storage.id, d.lock.code)
                storage.stash = v.stash or {}
                storage.stash.disable = true
            end
            storage.debug = v.debug
            bulk[#bulk + 1] = storage
        end
        v.locations = nil
        if v.item then
            Bridge.Framework.RegisterUsableItem(v.item, function(source, itemData)
                local src = source
                if not src then return end
                local storageId = itemData.metadata?.storageId
                local lock = itemData.metadata?.lock
                if not Bridge.Inventory.RemoveItem(src, v.item, 1) then return end
                local coords, rotation = Bridge.Callback.Trigger("mrc-storage:cb:PlaceStorage", src, k)
                if not coords then return Bridge.Inventory.AddItem(src, v.item, 1, nil, itemData.metadata) end
                local offset = v.offset or vector3(0.0, 0.0, 0.0)
                Storage.Place(storageId, k, coords + offset, rotation, lock)
            end)
        end
    end
    Bridge.Entity.CreateBulk(bulk)

    for id, lock in pairs(Config.Lock) do 
         Bridge.Framework.RegisterUsableItem(lock.item, function(source, itemData)
            local src = source
            if not src then return end
            local coords = GetEntityCoords(GetPlayerPed(src))
            local closest, dist = Storage.GetClosest(coords)
            if not closest or dist > 3.0 then return end
            if closest.lock and not closest.lock.disable then 
                return Bridge.Notify.SendNotify(src, "This storage is already locked.", "error", 5000)
            end
            closest.lock = Config.Lock[id]
            closest.lock.name = id
            local code = itemData.metadata?.code
            if not code then 
                code = Bridge.Callback.Trigger("mrc-storage:cb:UseLock", src, id, closest.id) 
            end
            if not code then return end
            Lock.Create(closest.id, code)
            closest.lock = Config.Lock[id] or {}
            closest.lock.disable = false
            closest.lock.name = id
            closest.lock.locked = true
            closest.lock.owner = Bridge.Framework.GetPlayerIdentifier(src)
            closest.stash.disable = true
            Bridge.Entity.Set(closest.id, {
                lock = closest.lock,
                stash = closest.stash
            })
            closest.lock.code = code
            StorageSQL.Save(closest.id, closest)
         end)
    end
end

RegisterNetEvent("mrc-storage:server:PickupStorage", function(id)
    local src = source
    if not src then return end
    local entity = Bridge.Entity.Get(id)
    if not entity then return end
    local config = Storage.Config(entity.isPickupable)
    if not config or not config.item then return end
    local coords = vector3(entity.coords.x, entity.coords.y, entity.coords.z)
    local dist = #(GetEntityCoords(GetPlayerPed(src)) - coords)
    if dist > 3.0 then return end
    if not entity.lock or not entity.lock.locked then
        if not Bridge.Inventory.AddItem(src, config.item, 1, nil, { storageId = id, lock = entity.lock }) then return end
        Bridge.Entity.Delete(id)
        return StorageSQL.Delete(id)
    end
    entity.attach = entity.attach or {}
    entity.attach.disable = false
    entity.attach.target = src
    entity.attach.offset = config.attach.offset
    entity.attach.rotation = config.attach.rotation
    Bridge.Entity.Set(id, { attach = entity.attach })
end)

RegisterNetEvent("mrc-storage:server:DropStorage", function(id, coords)
    local src = source
    if not src then return end
    local entity = Bridge.Entity.Get(id)
    if not entity then return end
    local config = Storage.Config(entity.isPickupable)
    if not config or not config.item then return end
    local player = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(player)
    local dist = #(playerCoords - coords)
    if dist > 3.0 then return end
    entity.attach = entity.attach or {}
    entity.attach.disable = true
    entity.coords = vector3(coords.x, coords.y, coords.z)
    Bridge.Entity.Set(id, { coords = coords, attach = entity.attach })
    entity.attach = nil
    Bridge.Entity.Set(id, { rotation = vector3(0, 0, entity.rotation.z or 0) })
    if entity.lock and not entity.lock.code then
        entity.lock.code = Lock.GetCode(id)
    end
    StorageSQL.Save(id, entity)
end)

AddEventHandler("onResourceStart", function()
    StorageSQL.Create()
    Wait(1000)
    Storage.Setup()
    BoltCutters.Setup()
end)

exports("Storage", function()
    return Storage
end)
