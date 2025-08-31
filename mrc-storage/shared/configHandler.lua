
Bridge = Bridge or exports['community_bridge']:Bridge()
Storage = Storage or {}
function Storage.Config(name)
    return Config.Storages[name]
end