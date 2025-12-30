StorageSQL = StorageSQL or {}

function StorageSQL.Create()
    assert(MySQL, "Tried using module MySQL without MySQL being loaded")
    local query = [[
        CREATE TABLE IF NOT EXISTS mrc_storage (
            id VARCHAR(50) PRIMARY KEY,
            data LONGTEXT
        );
    ]]
    MySQL.query.await(query)
end

function StorageSQL.Load()
    assert(MySQL, "Tried using module MySQL without MySQL being loaded")
    local result = MySQL.query.await("SELECT * FROM mrc_storage;")
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
    assert(MySQL, "Tried using module MySQL without MySQL being loaded")
    local encoded = json.encode(data)
    MySQL.query.await("INSERT INTO mrc_storage (id, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = ?;", { id, encoded, encoded })
end

function StorageSQL.Delete(id)
    assert(MySQL, "Tried using module MySQL without MySQL being loaded")
    MySQL.query.await("DELETE FROM mrc_storage WHERE id = ?;", { id })
end