local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

CreateThread(function()
    MySQL.ready(function()
        MySQL.Sync.execute([[
            CREATE TABLE IF NOT EXISTS `player_xp` (
                `citizenid` VARCHAR(50) NOT NULL,
                `level` INT(11) NOT NULL DEFAULT 1,
                `current_xp` INT(11) NOT NULL DEFAULT 0,
                `total_xp` INT(11) NOT NULL DEFAULT 0,
                PRIMARY KEY (`citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)
end)

local function GetXPRequiredForLevel(level)
    if level <= 1 then return Config.BaseXPPerLevel end
    return math.floor(Config.BaseXPPerLevel * (Config.XPMultiplier ^ (level - 1)))
end

local function CalculateLevelFromXP(totalXP)
    local level = 1
    local xpUsed = 0
    
    while level < Config.MaxLevel do
        local xpNeeded = GetXPRequiredForLevel(level)
        if totalXP < xpUsed + xpNeeded then
            return level, totalXP - xpUsed, xpNeeded
        end
        xpUsed = xpUsed + xpNeeded
        level = level + 1
    end
    
    return Config.MaxLevel, 0, 0
end

local function LoadPlayerXP(citizenid)
    local result = MySQL.Sync.fetchSingle('SELECT * FROM player_xp WHERE citizenid = ?', {citizenid})
    
    if result then
        PlayerData[citizenid] = {
            level = result.level,
            current_xp = result.current_xp,
            total_xp = result.total_xp
        }
    else
        MySQL.Sync.execute('INSERT INTO player_xp (citizenid, level, current_xp, total_xp) VALUES (?, ?, ?, ?)', {
            citizenid, 1, 0, 0
        })
        PlayerData[citizenid] = {
            level = 1,
            current_xp = 0,
            total_xp = 0
        }
    end
    
    return PlayerData[citizenid]
end

local function SavePlayerXP(citizenid)
    if not PlayerData[citizenid] then return end
    
    MySQL.Async.execute('UPDATE player_xp SET level = ?, current_xp = ?, total_xp = ? WHERE citizenid = ?', {
        PlayerData[citizenid].level,
        PlayerData[citizenid].current_xp,
        PlayerData[citizenid].total_xp,
        citizenid
    })
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    LoadPlayerXP(Player.PlayerData.citizenid)
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        SavePlayerXP(Player.PlayerData.citizenid)
        PlayerData[Player.PlayerData.citizenid] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        SavePlayerXP(Player.PlayerData.citizenid)
        PlayerData[Player.PlayerData.citizenid] = nil
    end
end)

QBCore.Functions.CreateCallback('azs-xpsystem:server:getXPData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    
    local citizenid = Player.PlayerData.citizenid
    if not PlayerData[citizenid] then
        LoadPlayerXP(citizenid)
    end
    
    local data = PlayerData[citizenid]
    local xpNeeded = GetXPRequiredForLevel(data.level)
    
    cb({
        level = data.level,
        current_xp = data.current_xp,
        total_xp = data.total_xp,
        xp_needed = xpNeeded,
        progress = (data.current_xp / xpNeeded) * 100
    })
end)

local function AddXP(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    if not PlayerData[citizenid] then
        LoadPlayerXP(citizenid)
    end
    
    local data = PlayerData[citizenid]
    local oldLevel = data.level
    
    data.current_xp = data.current_xp + amount
    data.total_xp = data.total_xp + amount
    
    local xpNeeded = GetXPRequiredForLevel(data.level)
    local leveledUp = false
    
    while data.current_xp >= xpNeeded and data.level < Config.MaxLevel do
        data.current_xp = data.current_xp - xpNeeded
        data.level = data.level + 1
        leveledUp = true
        xpNeeded = GetXPRequiredForLevel(data.level)
    end
    
    SavePlayerXP(citizenid)
    
    local newXpNeeded = GetXPRequiredForLevel(data.level)
    TriggerClientEvent('azs-xpsystem:client:updateXP', source, {
        level = data.level,
        current_xp = data.current_xp,
        total_xp = data.total_xp,
        xp_needed = newXpNeeded,
        progress = (data.current_xp / newXpNeeded) * 100,
        gained_xp = amount,
        leveled_up = leveledUp,
        old_level = oldLevel
    })
    
    return true
end

local function AddLevel(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    if not PlayerData[citizenid] then
        LoadPlayerXP(citizenid)
    end
    
    local data = PlayerData[citizenid]
    local oldLevel = data.level
    
    data.level = math.min(data.level + amount, Config.MaxLevel)
    data.current_xp = 0
    
    SavePlayerXP(citizenid)
    
    local xpNeeded = GetXPRequiredForLevel(data.level)
    TriggerClientEvent('azs-xpsystem:client:updateXP', source, {
        level = data.level,
        current_xp = data.current_xp,
        total_xp = data.total_xp,
        xp_needed = xpNeeded,
        progress = 0,
        gained_xp = 0,
        leveled_up = true,
        old_level = oldLevel
    })
    
    return true
end

RegisterNetEvent('azs-xpsystem:server:addXP', function(amount)
    AddXP(source, amount)
end)

RegisterNetEvent('azs-xpsystem:server:addLevel', function(amount)
    AddLevel(source, amount)
end)

exports('AddXP', AddXP)
exports('AddLevel', AddLevel)
exports('GetPlayerXPData', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local citizenid = Player.PlayerData.citizenid
    if not PlayerData[citizenid] then
        LoadPlayerXP(citizenid)
    end
    
    return PlayerData[citizenid]
end)

CreateThread(function()
    while true do
        Wait(300000)
        for citizenid, _ in pairs(PlayerData) do
            SavePlayerXP(citizenid)
        end
    end
end)