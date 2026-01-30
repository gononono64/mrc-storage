
Lock = {
    All = {},
}

function Lock.Create(id, code)
    Lock.All[id] = {
        code = code,
    }
end

function Lock.GetCode(id)
    return Lock.All[id] and Lock.All[id].code or nil
end

function Lock.Destroy(id)
    Lock.All[id] = nil
end

Bridge.Callback.Register("mrc-storage:cb:EnterCode", function(id, code)
    if code == Lock.GetCode(id) then
        return true
    end
    return false
end)