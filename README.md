# MRC Storage

A FiveM resource for advanced, configurable storage containers with lock and pickup mechanics.  
Supports QBCore and OX Inventory. Requires [community_bridge](https://github.com/gononono64/community_bridge).

---

## Features & Capabilities

- Create storage containers that can be placed in the world or picked up as items.
- Supports both static (predefined) and dynamic (player-placed) storage locations.
- Storage can be locked with custom codes using lock items or in location definition.
- Bolt cutters can be used to break locks (with configurable uses and animations).
- Storage containers have configurable stash slots and weight limits.
- Storage are attached to players when picked up and locked.
- Players cannot run and the movement speed can be controlled while the player is carrying a storage.
- Fully configurable target interactions (pickup, open stash, lock/unlock).
- Debug mode for visualizing storage zones.
- Supports QBCore and OX Inventory item definitions.
- Requires community_bridge for framework compatibility.

---

## Requirements

- A FiveM server
- [community_bridge](https://github.com/TheOrderFivem/community_bridge/tree/crowleys-branch) (must start before mrc-storage)
- QBCore or ESX framework
- Inventory system
- Target system (qb-target or ox_target)
- oxmysql
---

## Installation

### 1. Add the resource

- Download mrc-storage.
- Place the `mrc-storage` folder in your server’s `resources` directory.
- In your `server.cfg`, add:
  ```
  ensure community_bridge
  ensure mrc-storage
  ```

### 2. Add the images

- Copy all `.png` files from `mrc-storage/images/` to your inventory’s image folder:
  - QBCore: `resources/qb-inventory/html/images/`
  - OX Inventory: `resources/ox_inventory/web/images/`
  - Other inventories: See your inventory’s documentation.

### 3. Add the items

Paste the following item definitions into your inventory’s items file:

#### QBCore (`qb-core/shared/items.lua`)
```lua
['storage_box']      = {['name'] = 'storage_box',      ['label'] = 'Storage Box',      ['weight'] = 2500, ['type'] = 'item', ['image'] = 'storage_box.png',      ['unique'] = false, ['useable'] = false, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A box for storing items'},
['storage_lock']     = {['name'] = 'storage_lock',     ['label'] = 'Storage Lock',     ['weight'] = 1000, ['type'] = 'item', ['image'] = 'storage_lock.png',     ['unique'] = false, ['useable'] = false, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A lock for securing storage'},
['bolt_cutters']     = {['name'] = 'bolt_cutters',     ['label'] = 'Bolt Cutters',     ['weight'] = 1000, ['type'] = 'item', ['image'] = 'bolt_cutters.png',     ['unique'] = false, ['useable'] = false, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A tool for cutting locks'},
```

#### OX Inventory (`ox_inventory/data/items.lua`)
```lua
["storage_box"] = {
    label = "Storage Box",
    weight = 2500,
    stack = true,
    close = true,
    description = "A box for storing items",
},
["storage_lock"] = {
    label = "Storage Lock",
    weight = 1000,
    stack = true,
    close = true,
    description = "A lock for securing storage",
},
["bolt_cutters"] = {
    label = "Bolt Cutters",
    weight = 1000,
    stack = true,
    close = true,
    description = "A tool for cutting locks",
},
```

---

## 4. Restart your server

Restart your FiveM server so everything loads.

---

## Configuration

Edit `config.lua` in the mrc-storage folder to customize storage models, lock codes, stash slots, weight limits, pickup behavior, and more.

---

## Support

For issues or questions, open an issue on GitHub or join the [Discord](https://discord.gg/2CJa9vz5) linked in the project.

---
