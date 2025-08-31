
Config = {}

Config.Pickup = {   
    label = "Pickup",
    description = "Put the object in your inventory",
    icon = "fas fa-boxes",
    distance = 2.0
}

Config.Storages = {
    ["test_storage"] = {
        item = "storage_box", -- dont include item name if you dont want it to be an item
        model = "v_serv_abox_1",
        offset = vector3(0.0, 0.0, 0.25), -- offset from location that was picked while placing
        locations = {
            vector4(-591.66, 2931.48, 14.43, 0.0), -- leave empty for no locations
        },
        stash = {
            label = "Open Stash",
            slots = 20,
            maxWeight = 100000,
            target = {
                label = "Open Stash",
                description = "Access the stash to store or retrieve items.",
                icon = "fas fa-boxes"
            }
        },
    }
}