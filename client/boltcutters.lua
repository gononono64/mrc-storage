
Bridge.Callback.Register("mrc-storage:cb:UseBoltCutters", function(configName)
    local boltCuttersConfig = Config.BoltCutters[configName]
    if not boltCuttersConfig then return end
    local success = Bridge.ProgressBar.Open(boltCuttersConfig.progress)
    return success
end)
