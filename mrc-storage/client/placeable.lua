local Pickupable = {
    property = "isPickupable",
    default = {}
}

function Pickupable.OnSpawn(entityData)
    if not entityData or not entityData.id then return end
    entityData.targets = entityData.targets or {}
    table.insert(entityData.targets, {
        label = Config.Pickup.label,
        description = Config.Pickup.description,
        icon = Config.Pickup.icon,
        distance = Config.Pickup.distance,
        onSelect = function(entityData)
            TriggerServerEvent("mrc-storage:server:PickupStorage", entityData.id)
        end
    })
    Bridge.ClientEntity.Set(entityData.id, "targets", entityData.targets)
end

--cb
Bridge.Callback.Register("mrc-storage:cb:PlaceStorage", function(configName)
    local storageConfig = Storage.Config(configName)
    if not storageConfig then return end
    local data = Bridge.PlaceableObject.Create(storageConfig.model, {
        depth = 3.0,                -- Starting distance from player
        allowNormal = true,        -- Allow switching back to normal mode from movement
        disableSphere = true,      -- Hide position indicator sphere
        depthStep = 0.1,            -- Step size for depth adjustment (scroll + modifier)
        rotationStep = 0.5,         -- Step size for rotation (scroll)
        heightStep = 0.5,           -- Step size for height adjustment (Q/E)
        movementStep = 0.1,         -- Step size for WASD movement
        movementStepFast = 0.5,     -- Step size for fast movement (WASD + Shift)
        maxDepth = 5.0,             -- Maximum distance from player
    })
    if not data then return end
    return data.coords, data.rotation
end)


Bridge.ClientEntity.RegisterBehavior("isPickupable", Pickupable)
