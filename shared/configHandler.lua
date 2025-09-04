
Bridge = Bridge or exports['community_bridge']:Bridge()
Storage = Storage or {
    All = {}
}

function Storage.Config(name)
    local obj = Bridge.Tables.DeepClone(Config.Storages[name])
    obj.locations = nil
    return obj
end