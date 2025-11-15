-- Framework Detection
local Framework = nil
local isUIOpen = false
local currentData = {}

CreateThread(function()
    if Config.Framework == 'QBCore' then
        Framework = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'ESX' then
        Framework = exports['es_extended']:getSharedObject()
    end
end)

-- Framework Wrapper Functions
local function TriggerCallback(name, cb, ...)
    if Config.Framework == 'QBCore' then
        Framework.Functions.TriggerCallback(name, cb, ...)
    elseif Config.Framework == 'ESX' then
        Framework.TriggerServerCallback(name, cb, ...)
    end
end

local function Notify(message, type, duration)
    if Config.Framework == 'QBCore' then
        Framework.Functions.Notify(message, type, duration)
    elseif Config.Framework == 'ESX' then
        Framework.ShowNotification(message)
    end
end

local function IsPlayerLoaded()
    if Config.Framework == 'QBCore' then
        return LocalPlayer.state.isLoggedIn
    elseif Config.Framework == 'ESX' then
        return Framework.IsPlayerLoaded()
    end
    return false
end

CreateThread(function()
    while not IsPlayerLoaded() do
        Wait(1000)
    end
    
    SendNUIMessage({
        action = 'setUIStyle',
        uiStyle = Config.UIStyle
    })
    
    TriggerCallback('azs-xpsystem:server:getXPData', function(data)
        if data then
            currentData = data
        end
    end)
end)

local function ToggleUI(show, data)
    if show and data then
        currentData = data
    end
    
    isUIOpen = show
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = show and 'show' or 'hide',
        data = show and currentData or nil,
        uiStyle = Config.UIStyle
    })
end

local function ShowUITemporary(data, duration)
    ToggleUI(true, data)
    
    CreateThread(function()
        Wait(duration or Config.ShowTime)
        if isUIOpen then
            ToggleUI(false)
        end
    end)
end

RegisterKeyMapping('togglexp', 'Toggle XP Display', 'keyboard', Config.ToggleKey)

RegisterCommand('togglexp', function()
    if isUIOpen then
        ToggleUI(false)
    else
        TriggerCallback('azs-xpsystem:server:getXPData', function(data)
            if data then
                ToggleUI(true, data)
            end
        end)
    end
end)

RegisterNetEvent('azs-xpsystem:client:updateXP', function(data)
    currentData = data
    
    if data.gained_xp > 0 then
        Notify(string.format(Config.Notifications.xpGained, data.gained_xp), 'success', 2000)
    end
    
    if data.leveled_up then
        Notify(string.format(Config.Notifications.levelUp, data.level), 'success', 3000)
    end
    
    ShowUITemporary(data)
end)

exports('AddXP', function(amount)
    TriggerServerEvent('azs-xpsystem:server:addXP', amount)
end)

exports('AddLevel', function(amount)
    TriggerServerEvent('azs-xpsystem:server:addLevel', amount)
end)

exports('GetCurrentXPData', function()
    return currentData
end)

exports('ShowXPUI', function()
    TriggerCallback('azs-xpsystem:server:getXPData', function(data)
        if data then
            ToggleUI(true, data)
        end
    end)
end)

exports('HideXPUI', function()
    ToggleUI(false)
end)

-- command to add XP
RegisterCommand('addxp', function(source, args, raw)
    local amount = tonumber(args[1])
    if amount and amount > 0 then
        TriggerServerEvent('azs-xpsystem:server:addXP', amount)
        Notify('Added ' .. amount .. ' XP.', 'success', 2000)
    else
        Notify('Usage: /addxp <amount>', 'error', 2000)
    end
end, false)
