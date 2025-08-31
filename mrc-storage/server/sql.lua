
StorageSQL = StorageSQL or {}

function StorageSQL.Create()
    Bridge.SQL.Create("mrc_storage", {
        {name = "id", type = "VARCHAR(50) PRIMARY KEY"},
        {name = "data", type = "LONGTEXT" } -- JSON data,
    })
end

function StorageSQL.Load()
    local result = Bridge.SQL.GetAll("mrc_storage")
    local allData = {}

    for _, data in pairs(result or {}) do
        local id = data.id
        if id then
            allData[id] = json.decode(data.data or "{}")
        end
    end

    return allData
end

function StorageSQL.Save(id, data)
    Bridge.SQL.InsertOrUpdate("mrc_storage", {
        id = id,
        data = json.encode(data)
    })
end

function StorageSQL.Delete(id)
    Bridge.SQL.Delete("mrc_storage", "id = '" .. id .. "'")
end