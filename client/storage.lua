Storage = Storage or {
    All = {}
}

function Storage.Get(id)
    local entityData = Bridge.Entity.Get(id)
    if not entityData then return nil end
    return entityData
end

function Storage.SetTargets(id, name)
    local entityData = Storage.Get(id)
    if not entityData then return end
    local storageConfig = Config.Storages[name]
    if not storageConfig then return end
    local stashTargets = storageConfig.stash?.target or {}
    local rawTargets = entityData.rawTargets or {}
    rawTargets.stash = {
        label = stashTargets.label,
        icon = stashTargets.icon,
        description = stashTargets.description,
        groups = stashTargets.groups,
        canInteract = function(_)
            local entData = Bridge.Entity.Get(id)
            return not entData.locked
        end,
        onSelect = function()
            TriggerServerEvent("mrc-storage:server:OpenStash", id)
        end
    }
    rawTargets.pickup =  {
        label = Config.Pickup.label,
        description = Config.Pickup.description,
        icon = Config.Pickup.icon,
        distance = Config.Pickup.distance,
        onSelect = function()
            TriggerServerEvent("mrc-storage:server:PickupStorage", id)
        end
    }

    Bridge.Entity.SetKey(entityData.id, "rawTargets", rawTargets)
    local targets = Utils.ToArray(rawTargets)
    table.sort(targets, function(a, b) return (a.label < b.label) end)
    Bridge.Entity.SetTargets(entityData.id, targets)
end

function Storage.AddLockTargets(id, lockName, isLocked)
    local storage = Bridge.Entity.Get(id)
    if not storage then return end
    local lock = Config.Lock[lockName] or {}

    local target = lock.target?[ "unlock"]
    if not target then return end
    storage.rawTargets = storage.rawTargets or {}
    if not storage.rawTargets['unlock'] then
        storage.rawTargets['unlock'] = {
            label = target.label,
            description = target.description,
            icon = target.icon,
            distance = target.distance,
            canInteract = function(_)
                local ent = Bridge.Entity.Get(storage.id)
                if not ent then return false end
                return ent.locked
            end,
            onSelect = function()
                local ent = Bridge.Entity.Get(storage.id)
                Lock.OpenUi(ent)
            end
        }
    end

    target = lock.target?[ "lock"]
    if not storage.rawTargets['lock'] then
        storage.rawTargets['lock'] = {
            label = target.label,
            description = target.description,
            icon = target.icon,
            distance = target.distance or Lock.defaults.target.distance,
             canInteract = function(_)
                local ent = Bridge.Entity.Get(storage.id)
                if not ent then return false end
                return not ent.locked
            end,
            onSelect = function()
                TriggerServerEvent("mrc-storage:server:Lock", storage.id, nil)
            end
        }
    end
    Bridge.Entity.SetKey(storage.id, "rawTargets", storage.rawTargets)
    local targets = Utils.ToArray(storage.rawTargets)
    table.sort(targets, function(a, b) return (a.label < b.label) end)
    Bridge.Entity.SetTargets(storage.id, targets)
    return storage.rawTargets
end

function Storage.RemoveLockTargets(id)
    local storage = Storage.Get(id)
    if not storage then return end
    if not storage.rawTargets then return end
    storage.rawTargets['lock'] = nil
    storage.rawTargets['unlock'] = nil
    Bridge.Entity.SetKey(storage.id, "rawTargets", storage.rawTargets)
    local targets = Utils.ToArray(storage.rawTargets)
    table.sort(targets, function(a, b) return (a.label < b.label) end)
    Bridge.Entity.SetTargets(storage.id, targets)
    return storage.rawTargets
end

Bridge.Entity.SetOnCreate('stash', function(_entityData)
    local carrying = false
    _entityData.OnSpawn = function(entityData)
        Storage.SetTargets(entityData.id, entityData.name)
    end

    _entityData.OnRemove = function(entityData)
        Bridge.Target.RemoveLocalEntity(entityData.spawned)
    end

    _entityData.OnLock = function(entityData, key, value, old)
        if not value then return Storage.RemoveLockTargets(entityData.id) end
        Storage.AddLockTargets(entityData.id, value, entityData.locked)
    end

    _entityData.OnCoords = function(entityData, key, value, old)
        -- if not value then return end
        CreateThread(function()
            Wait(100)
            Bridge.Entity.UpdateCoords(entityData.id, vector3(value.x, value.y, value.z))
        end)
    end

    _entityData.OnRotation = function(entityData, key, value, old)
        -- if not value then return end
        CreateThread(function()
            Wait(100)
            Bridge.Entity.UpdateRotation(entityData.id, vector3(value.x, value.y, value.z))
        end)
    end

    _entityData.OnAttach = function(entityData, key, value, old)
        Bridge.Entity.SetAttach(entityData.id, value)
        carrying = (value and entityData.id) or false
        if not value then return end
        local playerPed = PlayerPedId()
        local targetSrc = value.target
        if not targetSrc then return end
        local targetPlayer = GetPlayerFromServerId(targetSrc)
        if targetPlayer == -1 then return end
        local targetPed = GetPlayerPed(targetPlayer)
        if not targetPed or targetPed == 0 then return end
        if targetPed ~= playerPed then return end
        local anim = Config.Pickup.anim
        Bridge.Anim.Play(entityData.id, playerPed, anim.dict, anim.name, anim.blendIn or 8.0, anim.blendOut or -8.0, anim.duration or -1, anim.flags)
        CreateThread(function()
            while carrying do
                if IsControlJustPressed(0, 38) then -- E
                    TriggerServerEvent("mrc-storage:server:DropStorage", entityData.id)
                end
                Wait(1)
            end
            Bridge.Anim.Stop(entityData.id)
        end)
    end

    return _entityData
end)

Bridge.Callback.Register("mrc-storage:cb:PlaceStorage", function(configName)
    local storageConfig = Config.Storages[configName]
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
