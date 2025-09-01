Storage = Storage or {}

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

---@class StorageData
--- A structure representing a storage entity.
--- @field id string|number The unique identifier for the storage entity.
--- @field name string The name of the storage entity.
--- @field coords vector3 The coordinates where the storage entity is located.
--- @field rotation vector3|number The rotation of the storage entity.
--- @field isPickupable string|boolean Indicates if the storage entity is pickupable.
--- @field stash table The stash information for the storage entity.
--- @field model string The model of the storage entity.

---Create a new storage at a specific location
--- @param storageData StorageData
--- @return entityData table
function Storage.New(storageData)
    return Bridge.ServerEntity.Create(storageData)
end

function Storage.Create(name)
    local storageConfig = Storage.Config(name)
    if not storageConfig then return end
    local tbl = {}
    for k, v in pairs(storageConfig) do
        tbl[k] = v
    end
    return Storage.New(tbl)
end

function Storage.Place(id, name, coords, rotation)
    local storageConfig = Storage.Config(name)
    storageConfig.id = id
    storageConfig.coords = coords
    storageConfig.rotation = rotation or vector3(0.0, 0.0, 0.0)
    storageConfig.isPickupable = name
    local storage = Storage.New(storageConfig)
    StorageSQL.Save(storage.id, storage)
    return storage
end

function Storage.Setup()
    local bulk = {}
    for k, v in pairs(Config.Storages) do
        for i, d in pairs(v.locations or {}) do
            v.name = k
            v.coords = d.xyz
            v.heading = d.w or 0
            v.entityType = "object"
            bulk[#bulk + 1] = v
        end
        if v.item then
            Bridge.Framework.RegisterUsableItem(v.item, function(source, itemData)
                local src = source
                if not src then return end
                local storageId = itemData.metadata?.storageId
                if not Bridge.Inventory.RemoveItem(src, v.item, 1) then return end
                local coords, rotation = Bridge.Callback.Trigger("mrc-storage:cb:PlaceStorage", src, k)
                if not coords then return Bridge.Inventory.AddItem(src, v.item, 1, nil, itemData.metadata) end
                local offset = v.offset or vector3(0.0, 0.0, 0.0)
                Storage.Place(storageId, k, coords + offset, rotation)
            end)
        end
    end
    Bridge.ServerEntity.CreateBulk(bulk)
end

RegisterNetEvent("mrc-storage:server:PickupStorage", function(id)
    local src = source
    if not src then return end
    local entity = Bridge.ServerEntity.Get(id)
    print(entity)
    if not entity then return end
    local config = Storage.Config(entity.isPickupable)
    if not config or not config.item then return end
    local coords = vector3(entity.coords.x, entity.coords.y, entity.coords.z)
    local dist = #(GetEntityCoords(GetPlayerPed(src)) - coords)
    if dist > 3.0 then return end
    if not Bridge.Inventory.AddItem(src, config.item, 1, nil, { storageId = id }) then return end
    Bridge.ServerEntity.Delete(id)
    StorageSQL.Delete(id)
end)

AddEventHandler("onResourceStart", function()
    StorageSQL.Create()
    Storage.Setup()
    local load = StorageSQL.Load()
    Wait(1000)
    Bridge.ServerEntity.CreateBulk(load)
end)

exports("Storage", function()
    return Storage
end)
