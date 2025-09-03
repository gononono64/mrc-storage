
Lock = {
    All = {},
    property = "lock",
    defaults = {
        target = {
            lock = {
                label = "SetNot",
                description = "Unlock",
                icon = "fa-solid fa-circle-notch",
                distance = 2.0
            },
            unlock = {
                label = "notSet",
                description = "Unlock",
                icon = "fa-solid fa-circle-notch",
                distance = 2.0
            }
        }
    },
    OpenedBefore = {},
}


if not IsDuplicityVersion() then

    function Lock.AlreadyOpened(id)
        if not id then return false end
        return Lock.OpenedBefore[id] or false
    end   

    function Lock.OpenUi(entityData)
        local code = Dial.Open(entityData)
        if not code then return end
        TriggerServerEvent("mrc-storage:server:Unlock", entityData.id, code)
    end

    function Lock.SetLockTargets(entityData)
        local lock = entityData.lock or {}
        local isLocked = lock.locked
        local target = lock.target?[isLocked and "unlock" or "lock"]
        if not target then return end
        entityData.targets = entityData.targets or {}
        if isLocked then
            if not entityData.targets['lock'] then 
                entityData.targets['unlock'] = nil
                entityData.targets['lock'] = {
                    label = target.label or Lock.defaults.target.label,
                    description = target.description or Lock.defaults.target.description,
                    icon = target.icon or Lock.defaults.target.icon,
                    distance = target.distance or Lock.defaults.target.distance,
                    onSelect = Lock.OpenUi
                }
                Bridge.Entity.Set(entityData.id, "targets", entityData.targets)
                print("Locking storage:", entityData.id)
            end
            return
        end

        if entityData.targets['unlock'] then return end
        entityData.targets['lock'] = nil
        entityData.targets['unlock'] = {
            label = target.label or Lock.defaults.target.label,
            description = target.description or Lock.defaults.target.description,
            icon = target.icon or Lock.defaults.target.icon,
            distance = target.distance or Lock.defaults.target.distance,
            onSelect = function() 
                TriggerServerEvent("mrc-storage:server:Lock", entityData.id, nil) 
            end
        }
        Bridge.Entity.Set(entityData.id, "targets", entityData.targets)      
       print("Setting lock targets for entity:", entityData.id)
    end

    function Lock.OnSpawn(entityData)
        if not entityData or not entityData.id then return end
        entityData.targets = entityData.targets or {}
        Lock.SetLockTargets(entityData)
        if entityData.stash then 
            entityData.stash.disable = entityData.lock.locked
            Bridge.Entity.Set(entityData.id, "stash", entityData.stash)
        end
    end

    function Lock.OnUpdate(entityData)
        if not entityData.lock then return end
        local lock = entityData.lock
        if entityData.lock.disable then 
            entityData.targets['lock'] = nil 
            entityData.targets['unlock'] = nil
            Bridge.Entity.Set(entityData.id, "targets", entityData.targets)
            return 
        end
        Lock.SetLockTargets(entityData)
    end

    return Bridge.Entity.RegisterBehavior("lock", Lock)

else --SERVER

    function Lock.Create(id, code)
        Lock.All[id] = {
            code = code,
        }
    end

    function Lock.GetCode(id)
        return Lock.All[id] and Lock.All[id].code or nil
    end

    Bridge.Callback.Register("mrc-storage:cb:EnterCode", function(id, code)
        if code == Lock.GetCode(id) then
            return true
        end
        return false
    end)

    local function trim(s)
        return s:match("^%s*(.-)%s*$")
    end

    RegisterNetEvent("mrc-storage:server:Lock", function(id)
        local src = source
        if not src then return end
        local entity = Bridge.Entity.Get(id)
        if not entity or not entity.lock then return end
        local distance = #(GetEntityCoords(GetPlayerPed(src)) - vector3(entity.coords.x, entity.coords.y, entity.coords.z))
        if distance > 3.0 then return end
        entity.stash = entity.stash or {}
        entity.stash.disable = true
        entity.lock.locked = true
        Bridge.Entity.Set(id, { stash = entity.stash, lock = entity.lock })
    end)

    RegisterNetEvent("mrc-storage:server:Unlock", function(id, code)
        print("Unlocking storage:", id, "with code:", code)
        local src = source
        if not src then return end
        local entity = Bridge.Entity.Get(id)
        if not entity or not entity.lock then return end
        local distance = #(GetEntityCoords(GetPlayerPed(src)) - vector3(entity.coords.x, entity.coords.y, entity.coords.z))
        if distance > 3.0 then return end
        local realCode = trim(tostring(Lock.GetCode(id)))
        local inputCode = trim(tostring(code))
        if inputCode ~= realCode then return end
        entity.stash = entity.stash or {}
        entity.stash.disable = false
        entity.lock.locked = false
        print("Unlocking storage:", id, "with code:", code)
        Bridge.Entity.Set(id, { stash = entity.stash, lock = entity.lock })        
    end)
end
