
Lock = {
    All = {},
}

function Lock.OpenUi(entityData)
    local lock = entityData.lock or {}
    local code = nil
    if lock.type == "keypad" then
        code = Keypad.Open(entityData)
    else
        code = Dial.Open(entityData)
    end
    if not code then return end
    TriggerServerEvent("mrc-storage:server:Unlock", entityData.id, code)
end
