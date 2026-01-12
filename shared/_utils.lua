

Bridge = Bridge or exports['community_bridge']:Bridge()
Storage = Storage or {
    All = {}
}

function Storage.Config(name)
    local obj = Bridge.Tables.DeepClone(Config.Storages[name])
    assert(obj, "Storage.Config: Missing storage config for " .. tostring(name))
    obj.locations = nil
    return obj
end

Utils = {}
function Utils.ToArray(tbl)
    local arr = {}
    for _, v in pairs(tbl) do
        table.insert(arr, v)
    end
    return arr
end


function Utils.Trim(s)
    return s:match("^%s*(.-)%s*$")
end