local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false
local currentData = {}

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(1000)
    end
    
    SendNUIMessage({
        action = 'setUIStyle',
        uiStyle = Config.UIStyle
    })
    
    QBCore.Functions.TriggerCallback('azs-xpsystem:server:getXPData', function(data)
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
        QBCore.Functions.TriggerCallback('azs-xpsystem:server:getXPData', function(data)
            if data then
                ToggleUI(true, data)
            end
        end)
    end
end)

RegisterNetEvent('azs-xpsystem:client:updateXP', function(data)
    currentData = data
    
    if data.gained_xp > 0 then
        QBCore.Functions.Notify(string.format(Config.Notifications.xpGained, data.gained_xp), 'success', 2000)
    end
    
    if data.leveled_up then
        QBCore.Functions.Notify(string.format(Config.Notifications.levelUp, data.level), 'success', 3000)
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
    QBCore.Functions.TriggerCallback('azs-xpsystem:server:getXPData', function(data)
        if data then
            ToggleUI(true, data)
        end
    end)
end)

exports('HideXPUI', function()
    ToggleUI(false)
end)