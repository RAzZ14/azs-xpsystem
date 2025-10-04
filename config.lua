Config = {}

-- General Settings
Config.MaxLevel = 100
Config.BaseXPPerLevel = 1000
Config.XPMultiplier = 1.15

-- Toggle key to show/hide UI
Config.ToggleKey = 'F5'

-- Time UI stays visible after gaining XP (in ms)
Config.ShowTime = 4000

-- UI Style ('circular' or 'rectangular')
Config.UIStyle = 'rectangular' -- 'circular' ou 'rectangular'

-- Notifications
Config.Notifications = {
    levelUp = 'Level Up! You are now level %s',
    xpGained = '+%s XP gained'
}