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

function Storage.Create(configIndex)
    if not configIndex then return end
    local storageData = configIndex
    local config = nil
    if type(configIndex) == "string" then
        storageData = Storage.Config(configIndex)
        config = storageData
    else
        config = Storage.Config(storageData.name)
    end
    assert(storageData, "Storage.Create: Missing config for " .. tostring(configIndex))
    assert(storageData.model, "Storage.Create: Missing model in config for " .. tostring(configIndex))
    assert(storageData.coords, "Storage.Create: Missing coords in config for " .. tostring(configIndex))
    storageData.rotation = storageData.rotation or vector3(0.0, 0.0, 0.0)
    storageData.entityType = storageData.entityType or "object"
    storageData.id =  storageData.id or Bridge.Ids.CreateUniqueId(Storage.All)
    storageData.stash = true
    local entityData = Bridge.Entity.Create(storageData)
    assert(entityData.stash, "Storage.Create: Missing stash in config for " .. tostring(configIndex))
    local stash = config.stash or {}
    Bridge.Inventory.RegisterStash(entityData.id, stash.label, stash.slots, stash.maxWeight, nil, stash.target?.groups)
    Storage.All[entityData.id] = entityData
    return entityData
end

function Storage.Setup()
    -- Load existing storages from database
    local bulk = {}
    local sqlAll = StorageSQL.Load() or {}
    for k, v in pairs(sqlAll) do
        local storage = Storage.Create(v)

        if v.lock then
            Storage.AddLock(storage.id, v.lock, v.code)
        end
    end

    local all = Bridge.Tables.DeepClone(Config.Storages or {})
    for k, v in pairs(all) do
        for i, d in pairs(v.locations or {}) do
            local storage = {}
            storage.id = k .. i
            storage.model = v.model
            storage.name = k
            storage.coords = d.coords.xyz
            storage.heading = d.w or 0
            storage = Storage.Create(storage)
            if d.lock then
                Storage.AddLock(storage.id, d.lock, d.code)
            end
            d.code = nil
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
                local coords, rotation = Bridge.Callback.Trigger("mrc-storage:cb:PlaceStorage", src, k)
                if not coords then return end
                if not Bridge.Inventory.RemoveItem(src, v.item, 1) then return end
                local code = Lock.GetCode(storageId)
                Storage.Place(storageId, k, coords, rotation, lock, code)
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
            if closest.lock then
                return Bridge.Notify.SendNotify(src, "This storage is already locked.", "error", 5000)
            end
            closest.lock = id
            local code = itemData.metadata?.code

            if not code then
                code = Bridge.Callback.Trigger("mrc-storage:cb:UseLock", src, id, closest.id)
            end
            if not code then return end
            if not Bridge.Inventory.RemoveItem(src, lock.item, 1) then return end
            Storage.AddLock(closest.id, closest.lock, code, true)
            closest.owner = Bridge.Framework.GetPlayerIdentifier(src)
            closest.stash.disable = true
            StorageSQL.Save(closest.id, closest)
         end)
    end
end

function Storage.Get(id)
    if not id then return end
    return Storage.All[id]
end

function Storage.AddLock(storageId, _type, code, sync)
    if not storageId or not code then return end
    local storage = Storage.Get(storageId)
    if not storage then return end
    Lock.Create(storageId, code)
    storage.locked = true
    storage.lock = _type
    if sync then
        Bridge.Entity.Set(storageId, {
            lock = storage.lock,
            locked = true
        })
    end


    StorageSQL.Save(storage.id, storage)
end

function Storage.RemoveLock(storageId)
    if not storageId then return end
    local storage = Storage.Get(storageId)
    if not storage then return end
    storage.locked = false
    storage.lock = nil
    Lock.Destroy(storageId)
    StorageSQL.Save(storage.id, storage)

    Bridge.Entity.Set(storageId, {
        lock = false,
        locked = false
    })
end


function Storage.Lock(storageId, locked)
    if not storageId then return end
    local storage = Storage.Get(storageId)
    if not storage or not storage.lock then return end
    storage.locked = locked
    Bridge.Entity.Set(storageId, {
        lock = storage.lock,
        locked = locked
    })
end


function Storage.GetClosest(coords)
    local closest = nil
    local closestDist = -1
    for id, v in pairs(Storage.All) do
        local entity = v
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


function Storage.Place(id, name, coords, rotation, lock, code)
    coords = vector3(coords.x, coords.y, coords.z) + (Config.Storages[name].offset or vector3(0.0, 0.0, 0.0))
    rotation = rotation or vector3(0.0, 0.0, 0)
    local storage = Storage.Create({
        id = id,
        coords = coords,
        model = Config.Storages[name].model,
        name = name,
        rotation = rotation,
        isPickupable = true
    })
    if not storage then return end
    if lock and code then
        Storage.AddLock(id, lock, code, true)
    else
        StorageSQL.Save(storage.id, storage)
    end
    return storage
end

function Storage.Attach(storageId, targetSrc)
    local storage = Storage.Get(storageId)
    if not storage then return end
    if storage.attach then return end
    local config = Storage.Config(storage.name)
    if not config or not config.attach then return end
    storage.attach = storage.attach or {}
    storage.attach.target = targetSrc
    storage.attach.offset = config.attach.offset
    storage.attach.rotation = config.attach.rotation
    Bridge.Entity.Set(storageId, { attach = storage.attach })
end

function Storage.Detach(storageId, coords, rotation)
    local storage = Storage.Get(storageId)
    if not storage then return end
    if not storage.attach then return end
    storage.attach = false
    storage.coords = vector3(coords.x, coords.y, coords.z)
    storage.rotation = vector3(rotation.x, rotation.y, rotation.z)
    StorageSQL.Save(storage.id, storage)
    Bridge.Entity.Set(storageId, { attach = false, coords = storage.coords, rotation = storage.rotation })
end

function Storage.Open(id, src)
    local entityData = Storage.Get(id)
    if not entityData then return print(string.format("[Storage] Open: Entity %s does not exist", id)) end
    local coords = vector3(entityData.coords.x, entityData.coords.y, entityData.coords.z)
    if not coords then return end
    local distance = #(GetEntityCoords(GetPlayerPed(src)) - coords)
    if distance > 3.0 then
        return Bridge.Notify.SendNotify(src, "You are too far from the storage.", "error", 5000)
    end
    Bridge.Inventory.OpenStash(src, "stash", id)
end

RegisterNetEvent("mrc-storage:server:PickupStorage", function(id)
    local src = source
    if not src then return end
    local entity = Bridge.Entity.Get(id)
    if not entity then return end
    if not entity.isPickupable then return end
    local coords = vector3(entity.coords.x, entity.coords.y, entity.coords.z)
    local dist = #(GetEntityCoords(GetPlayerPed(src)) - coords)
    if dist > 3.0 then return end
    local config = Storage.Config(entity.name)
    if not config or not config.item then return end
    if not entity.locked then
        if not Bridge.Inventory.AddItem(src, config.item, 1, nil, { storageId = id, lock = entity.lock }) then return end
        Bridge.Entity.Delete(id)
        return StorageSQL.Delete(id)
    end
    Storage.Attach(id, src)
end)

RegisterNetEvent("mrc-storage:server:DropStorage", function(id)
    local src = source
    if not src then return end
    local entity = Bridge.Entity.Get(id)
    if not entity then return end
    local config = Storage.Config(entity.name)
    if not config or not config.item then return end
    local player = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(player)
    Storage.Detach(id, playerCoords - vector3(0, 0, 1.0), vector3(0, 0, 0))
end)

RegisterNetEvent("mrc-storage:server:OpenStash", function(id)
    local src = source
    if not src then return end
    Storage.Open(id, src)
end)

RegisterNetEvent("mrc-storage:server:Lock", function(id)
    local src = source
    if not src then return end
    local entity = Bridge.Entity.Get(id)
    if not entity or not entity.lock then return end
    local distance = #(GetEntityCoords(GetPlayerPed(src)) - vector3(entity.coords.x, entity.coords.y, entity.coords.z))
    if distance > 3.0 then return end
    Storage.Lock(entity.id, true)
end)

RegisterNetEvent("mrc-storage:server:Unlock", function(id, code)
    local src = source
    if not src then return end
    local entity = Bridge.Entity.Get(id)
    if not entity or not entity.lock then return end
    local distance = #(GetEntityCoords(GetPlayerPed(src)) - vector3(entity.coords.x, entity.coords.y, entity.coords.z))
    if distance > 3.0 then return end
    local realCode = Utils.Trim(tostring(Lock.GetCode(id)))
    local inputCode = Utils.Trim(tostring(code))
    if inputCode ~= realCode then return end
    Storage.Lock(entity.id, false)
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    StorageSQL.Create()
    Wait(1000)
    Storage.Setup()
    BoltCutters.Setup()
end)

exports("Storage", function()
    return Storage
end)


if Bridge.Inventory.GetResourceName() ~= "ox_inventory" then return end

local hookId = nil
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
        local fromId = payload.fromInventory
        local toId = payload.toInventory
        local fromIsStorage = Storage.Get(fromId)
        local toIsStorage = Storage.Get(toId)
        if not fromIsStorage and not toIsStorage then return end
        local name = fromIsStorage?.name or toIsStorage?.name
        if not name then return end
        local config = Config.Storages[name].stash
        if not config then return end
        local blacklist = config.blacklist
        local whitelist = config.whitelist
        local itemName = payload.fromSlot?.name
        if not itemName then return end
        local swappedItemName = type(payload.toSlot) == "table" and payload.toSlot.name
        if swappedItemName then
            if whitelist and not whitelist[swappedItemName] then return false end
            if blacklist and blacklist[swappedItemName] then return false end
        end

        if whitelist and not whitelist[itemName] then return false end
        if blacklist and blacklist[itemName] then return false end
        return true
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if not hookId then return end
    exports.ox_inventory:removeHooks(hookId)
end)
