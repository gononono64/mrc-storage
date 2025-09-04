local Pickupable = {
    property = "isPickupable",
    default = {},
    Holding = nil
}

function Pickupable.OnSpawn(entityData)
    if not entityData or not entityData.id then return end
    entityData.targets = entityData.targets or {}
    entityData.targets['pickup'] =  {
        label = Config.Pickup.label,
        description = Config.Pickup.description,
        icon = Config.Pickup.icon,
        distance = Config.Pickup.distance,
        onSelect = function(entityData)
            TriggerServerEvent("mrc-storage:server:PickupStorage", entityData.id)
        end
    }
    Bridge.Entity.Set(entityData.id, "targets", entityData.targets)
end

function Pickupable.OnUpdate(entityData)
    if not entityData.attach then return end
    if entityData.attach.disable then return end
    if Pickupable.Holding then return end
    local islocal = entityData.attach.target == GetPlayerServerId(PlayerId())
    if not islocal then return end
    Pickupable.Holding = true
    local ped = PlayerPedId()
    local animName = Config.Pickup.anim.name
    local animDict = Config.Pickup.anim.dict
    local animId = Bridge.Anim.Play(entityData.id, ped, animDict, animName,  8.0, -8.0, -1, 49, 0.0, function(success, reason)
    end)
    CreateThread(function()
        local entity = entityData
        
        while not entity.attach.disable do
            entity = Bridge.Entity.Get(entity.id)
            Wait(3)
            SetPedMoveRateOverride(PlayerPedId(), Config.Pickup.lockedMovespeed or 1.0)
            DisableControlAction(0, 21, true) -- Disable the sprint key
            if IsControlJustPressed(0, 38) then
                local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0, -1.0)
                TriggerServerEvent("mrc-storage:server:DropStorage", entityData.id, coords)
                Pickupable.Holding = false
            end
        end
        Pickupable.Holding = false
        Bridge.Anim.Stop(animId)
    end)

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


Bridge.Entity.RegisterBehavior("isPickupable", Pickupable)
