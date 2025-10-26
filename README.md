
# AZ SCRIPTS - XP AND LEVEL SYSTEM

Modern XP and Leveling system for QBCore and ESX with dual UI styles and smooth animations.

## 📦 Installation

1. Download and extract `azs-xpsystem` to your resources folder
2. Add `ensure azs-xpsystem` to your `server.cfg`
3. Restart your server
4. Database table creates automatically

## ⚙️ Configuration
Edit `config.lua`:

```lua
Config.BaseXPPerLevel = 100      -- Base XP per level
Config.XPMultiplier = 1.5        -- XP multiplier per level
Config.MaxLevel = 100            -- Maximum level
Config.UIStyle = 'circular'      -- 'circular' or 'rectangular'
Config.ToggleKey = 'F5'          -- Key to toggle UI
```
## 📤 Exports

### Server-Side Exports
#### AddXP
Awards XP to a player and handles level-ups automatically.

```lua
exports['azs-xpsystem']:AddXP(source, amount)
```

#### AddLevel
Directly increases a player's level (resets current XP).

```lua
exports['azs-xpsystem']:AddLevel(source, amount)
```

#### GetPlayerXPData
Retrieves complete XP data for a player.

```lua
exports['azs-xpsystem']:GetPlayerXPData(source)
```

### Client-Side Exports
#### AddXP
Awards XP to a player and handles level-ups automatically.

```lua
exports['azs-xpsystem']:AddXP(amount)
```

#### AddLevel
Directly increases a player's level (resets current XP).

```lua
exports['azs-xpsystem']:AddLevel(amount)
```

#### GetPlayerXPData
Retrieves complete XP data for a player.

```lua
exports['azs-xpsystem']:GetCurrentXPData()
```

#### ShowXPUI and HideXPUI
Manually shows and hide the XP interface.

```lua
exports['azs-xpsystem']:ShowXPUI()
exports['azs-xpsystem']:HideXPUI()
```

## 🖼️ Preview
## PREVIEW
<img
    src="https://i.imgur.com/l0u2icP.png"
/>
<img
    src="https://i.imgur.com/gAhvwMQ.png"
/>

## 💬 Support
[Discord](https://discord.gg/NvnXRKHyqT)<br>
[Documentation](https://az-scripts.gitbook.io/az-scripts/free-resource/azs-xpsystem)
