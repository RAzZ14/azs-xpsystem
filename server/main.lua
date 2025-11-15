-- Framework Detection
local Framework = nil
local PlayerData = {}

if Config.Framework == 'QBCore' then
    Framework = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'ESX' then
    Framework = exports['es_extended']:getSharedObject()
end

-- Framework Wrapper Functions
local function GetPlayer(source)
    if Config.Framework == 'QBCore' then
        return Framework.Functions.GetPlayer(source)
    elseif Config.Framework == 'ESX' then
        return Framework.GetPlayerFromId(source)
    end
end

local function GetPlayerIdentifier(Player)
    if Config.Framework == 'QBCore' then
        return Player.PlayerData.citizenid
    elseif Config.Framework == 'ESX' then
        return Player.identifier
    end
end

local function CreateCallback(name, cb)
    if Config.Framework == 'QBCore' then
        Framework.Functions.CreateCallback(name, cb)
    elseif Config.Framework == 'ESX' then
        Framework.RegisterServerCallback(name, cb)
    end
end

-- Database Setup
CreateThread(function()
    MySQL.ready(function()
        local identifierColumn = Config.Framework == 'QBCore' and 'citizenid' or 'identifier'
        MySQL.Sync.execute(string.format([[
            CREATE TABLE IF NOT EXISTS `player_xp` (
                `%s` VARCHAR(50) NOT NULL,
                `level` INT(11) NOT NULL DEFAULT 1,
                `current_xp` INT(11) NOT NULL DEFAULT 0,
                `total_xp` INT(11) NOT NULL DEFAULT 0,
                PRIMARY KEY (`%s`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], identifierColumn, identifierColumn))
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

local function LoadPlayerXP(identifier)
    local identifierColumn = Config.Framework == 'QBCore' and 'citizenid' or 'identifier'
    local result = MySQL.Sync.fetchSingle(string.format('SELECT * FROM player_xp WHERE %s = ?', identifierColumn), {identifier})

    if result then
        -- Calculate expected total_xp based on stored level and current_xp
        local expectedTotalXP = 0
        for i = 1, result.level - 1 do
            expectedTotalXP = expectedTotalXP + GetXPRequiredForLevel(i)
        end
        expectedTotalXP = expectedTotalXP + result.current_xp

        if expectedTotalXP ~= result.total_xp then
            -- total_xp was changed manually, recalculate level and current_xp
            local calculatedLevel, calculatedCurrentXP, _ = CalculateLevelFromXP(result.total_xp)
            MySQL.Sync.execute(string.format('UPDATE player_xp SET level = ?, current_xp = ? WHERE %s = ?', identifierColumn), {
                calculatedLevel, calculatedCurrentXP, identifier
            })
            PlayerData[identifier] = {
                level = calculatedLevel,
                current_xp = calculatedCurrentXP,
                total_xp = result.total_xp
            }
        else
            -- Use stored values as is
            PlayerData[identifier] = {
                level = result.level,
                current_xp = result.current_xp,
                total_xp = result.total_xp
            }
        end
    else
        MySQL.Sync.execute(string.format('INSERT INTO player_xp (%s, level, current_xp, total_xp) VALUES (?, ?, ?, ?)', identifierColumn), {
            identifier, 1, 0, 0
        })
        PlayerData[identifier] = {
            level = 1,
            current_xp = 0,
            total_xp = 0
        }
    end

    return PlayerData[identifier]
end

local function SavePlayerXP(identifier)
    if not PlayerData[identifier] then return end
    
    local identifierColumn = Config.Framework == 'QBCore' and 'citizenid' or 'identifier'
    MySQL.Async.execute(string.format('UPDATE player_xp SET level = ?, current_xp = ?, total_xp = ? WHERE %s = ?', identifierColumn), {
        PlayerData[identifier].level,
        PlayerData[identifier].current_xp,
        PlayerData[identifier].total_xp,
        identifier
    })
end

-- Player Load Events
if Config.Framework == 'QBCore' then
    RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
        LoadPlayerXP(Player.PlayerData.citizenid)
    end)
    
    RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
        local Player = GetPlayer(src)
        if Player then
            local identifier = GetPlayerIdentifier(Player)
            SavePlayerXP(identifier)
            PlayerData[identifier] = nil
        end
    end)
elseif Config.Framework == 'ESX' then
    RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
        LoadPlayerXP(xPlayer.identifier)
    end)
    
    RegisterNetEvent('esx:playerDropped', function(playerId, reason)
        local xPlayer = GetPlayer(playerId)
        if xPlayer then
            local identifier = GetPlayerIdentifier(xPlayer)
            SavePlayerXP(identifier)
            PlayerData[identifier] = nil
        end
    end)
end

AddEventHandler('playerDropped', function()
    local src = source
    local Player = GetPlayer(src)
    if Player then
        local identifier = GetPlayerIdentifier(Player)
        SavePlayerXP(identifier)
        PlayerData[identifier] = nil
    end
end)

CreateCallback('azs-xpsystem:server:getXPData', function(source, cb)
    local Player = GetPlayer(source)
    if not Player then return cb(nil) end

    local identifier = GetPlayerIdentifier(Player)
    LoadPlayerXP(identifier)  -- Always load fresh data from DB to reflect manual changes

    local data = PlayerData[identifier]
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
    local Player = GetPlayer(source)
    if not Player then return false end
    
    local identifier = GetPlayerIdentifier(Player)
    if not PlayerData[identifier] then
        LoadPlayerXP(identifier)
    end
    
    local data = PlayerData[identifier]
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
    
    SavePlayerXP(identifier)
    
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
    local Player = GetPlayer(source)
    if not Player then return false end
    
    local identifier = GetPlayerIdentifier(Player)
    if not PlayerData[identifier] then
        LoadPlayerXP(identifier)
    end
    
    local data = PlayerData[identifier]
    local oldLevel = data.level
    
    data.level = math.min(data.level + amount, Config.MaxLevel)
    data.current_xp = 0
    
    SavePlayerXP(identifier)
    
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
    local Player = GetPlayer(source)
    if not Player then return nil end
    
    local identifier = GetPlayerIdentifier(Player)
    if not PlayerData[identifier] then
        LoadPlayerXP(identifier)
    end
    
    return PlayerData[identifier]
end)

CreateThread(function()
    while true do
        Wait(300000)
        for identifier, _ in pairs(PlayerData) do
            SavePlayerXP(identifier)
        end
    end
end)
