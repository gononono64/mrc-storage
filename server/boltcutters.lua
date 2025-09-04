BoltCutters = {}

Config.BoltCutters = {
    ['bolt_cutters'] = {
        item = "bolt_cutters", -- item name
        progress = {
            uses = 5,
            duration = 5000,
            label = "Cutting Lock",
            anim = {
                dict = "anim@heists@box_carry@",
                name = "idle",
                flags = 49,
            },
            prop = {
                {
                    model = "prop_tool_bolt_cutter",
                    bone = 60309,
                    coords = vector3(0.0, 0.0, 0.0),
                    rotation = vector3(0.0, 0.0, 0.0),
                }
            }
        },
    }
}

function BoltCutters.Setup()
    local load = StorageSQL.Load()
    for k, v in pairs(Config.BoltCutters) do
        Bridge.Framework.RegisterUsableItem(v.item, function(source, itemData)
            local src = source
            if not src then return end
            local uses = itemData.metadata?.uses or v.progress.uses
            local coords = GetEntityCoords(GetPlayerPed(src))
            local closest, dist = Storage.GetClosest(coords)
            if not closest or dist > 3.0 then return end
            if not closest.lock or closest.lock.disable then return end
            local success = Bridge.Callback.Trigger("mrc-storage:cb:UseBoltCutters", src, k)
            if not success then return end
            if uses <= 1 then
                if not Bridge.Inventory.RemoveItem(src, v.item, 1) then return end
            else
                Bridge.Inventory.SetMetadata(src, v.item, itemData.slot, {uses = uses - 1})
            end
            if closest.lock then
                closest.lock.disable = true
                closest.lock.locked = false
            end
            if closest.stash then
                closest.stash.disable = false
            end
            Bridge.Entity.Set(closest.id, {lock = closest.lock, stash = closest.stash})
            StorageSQL.Save(closest.id, closest)
        end)
        
    end
    Bridge.Entity.CreateBulk(load)
end