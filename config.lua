
Config = {}

Config.Settings = {
    debug = true,
}

Config.Pickup = {   
    label = "Pickup",
    description = "Put the object in your inventory",
    icon = "fas fa-boxes",
    distance = 2.0,
    lockedMovespeed = 0.9,
    anim = {
        dict = "anim@heists@box_carry@",
        name = "idle",
        flags = 49,
    }
}


Config.Lock = {
    ['storage_lock'] = { 
        item = "storage_lock", -- item name
        target = {
            lock = {
                label = "Lock",
                description = "Unlock",
                icon = "fa-solid fa-circle-notch",
                distance = 2.0
            },
            unlock = {
                label = "Unlock",
                description = "Lock",
                icon = "fa-solid fa-circle-notch",
                distance = 2.0
            }
        },     
    }
}


Config.BoltCutters = {
    ['bolt_cutters'] = {
        item = "bolt_cutters", -- item name
        uses = 5,
        progress = {            
            duration = 5000,
            label = "Cutting Lock",
            disable ={
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
            anim = {
                dict = "anim@scripted@heist@ig4_bolt_cutters@male@",
                clip = "action_male",
                flags = 49,
            },
            prop = {
                {
                    model = "m23_2_prop_m32_bolt_cutter_01a",
                    bone = 6286,
                    pos = vector3(0.0, 0.3, 0.0),
                    rot = vector3(0.0, 0.0, 0.0),
                }
            }
        },
    }
}

Config.Storages = {
    ["test_storage"] = {
        item = "storage_box", -- Dont include item if you dont want it to be an item. NOTE: must include a model
        model = "v_serv_abox_1", -- Can be nil if locations are setup.
        entityType = "object",
        offset = vector3(0.0, 0.0, 0.25), -- Model compensation offset for storage placement
        size = vector3(2.0, 2.0, 2.0), --controls size of boxzone if no model is specified
        locations = { -- Static locations. Storage cannot be picked up
            {coords = vector3(-840.74, 237.26, 72.69), lock = {name = "storage_lock", code = "R10 L0 R5"}}, -- if lock is defined here, it will override the default lock for this storage
        },
        stash = {
            label = "Open Stash",
            slots = 20, -- stash slot count
            maxWeight = 100000, -- max weight allowed
            target = {
                label = "Open Stash",
                description = "Access the stash to store or retrieve items.",
                icon = "fas fa-boxes",
            }
        },
        attach = {
            offset = vector3(0.0, 0.5, 0.0) -- offset from player when picked up and locked
        },
        debug = false, -- shows boxzone when no model is specified
    },
}









--- no entity support also withh predefined locations
--- bolt cutters
--- 