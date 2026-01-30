BoltCutters = {}

function BoltCutters.Setup()
    for k, v in pairs(Config.BoltCutters or {}) do
        Bridge.Framework.RegisterUsableItem(v.item, function(source, itemData)
            local src = source
            if not src then return end
            local uses = itemData.metadata?.uses or v.uses
            local coords = GetEntityCoords(GetPlayerPed(src))
            local closest, dist = Storage.GetClosest(coords)
            if not closest or dist > 3.0 then return end
            if not closest.lock then return end
            local success = Bridge.Callback.Trigger("mrc-storage:cb:UseBoltCutters", src, k)
            if not success then return end
            if uses <= 1 then
                if not Bridge.Inventory.RemoveItem(src, v.item, 1) then return end
            else
                Bridge.Inventory.SetMetadata(src, v.item, itemData.slot, {uses = uses - 1})
            end
            Storage.RemoveLock(closest.id)
        end)

    end
end