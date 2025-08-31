

Storage = Storage or {}


function Storage.New(data)
    return Bridge.ServerEntity.Create(data)
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
    if not Bridge.Inventory.AddItem(src, config.item, 1, nil, {storageId = id}) then return end
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