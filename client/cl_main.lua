local lib               = lib
local qbx_core          = exports.qbx_core
local config            = lib.load('configs.client')
local utils             = lib.load('client.utils')

playerData = {}

local function cleanupPlayerSpawned()
    FreezeEntityPosition(cache.ped, false)
    SetEntityVisible(cache.ped, true)
    playerData = {}
end

local function playerLoaded()
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end

-- Spawns Player --
local function spawnPlayer(coords)
    utils.setChoosingSpawnState(false)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    lib.waitFor(function()
        if utils.setPlayerCoords(coords) then
            return true
        end
    end, 'failed to set coords', 10000)
    FreezeEntityPosition(cache.ped, true)
    utils.switchToPlayer()
    playerLoaded()
    cleanupPlayerSpawned()
end

-- Confirm Spawn Location --
local function spawnConfirmation(info)
    local spawnName = (info.type == 'normal' and config.spawns[info.location].label) or (info.type == 'current' and 'Last Location') or (info.type == 'house' and info.name)
    local confirmation = lib.alertDialog({
        header = 'Spawn Confirmation',
        content = ('Are you sure you want to spawn here?  \n\n**%s**'):format(spawnName),
        centered = true,
        cancel = true
    })
    return (confirmation == 'confirm')
end

-- View Owned Houses --
local function housesMenu(houses)
    local spawnLocations = {}

    for x = 1, #houses do
        local optionID = #spawnLocations+1
        local houseInfo = houses[x]
        spawnLocations[optionID] = {
            label = houseInfo.label,
            title = houseInfo.label,
            icon = 'fas fa-house',
            args = {
                location = x,
                coords = houseInfo.coords,
                name = houseInfo.label,
                type = 'house'
            }
        }

        if config.useContext then
            spawnLocations[optionID].onSelect = function()
                local confirmSpawn = spawnConfirmation(spawnLocations[optionID].args)
                if confirmSpawn then
                    spawnPlayer(spawnLocations[optionID].args.coords)
                else
                    lib.showContext('houses_spawn_menu')
                end
            end
        end
    end

    if config.useContext then
        lib.registerContext({
            id = 'houses_spawn_menu',
            title = 'Choose House',
            menu = 'spawn_menu',
            canClose = false,
            options = spawnLocations
        })
        lib.showContext('houses_spawn_menu')
    else
        lib.registerMenu({
            id = 'houses_spawn_menu',
            title = 'Choose House',
            position = 'top-left',
            onClose = function()
                lib.showMenu('spawn_menu')
            end,
            options = spawnLocations
        }, function(selected, scrollIndex, args)
            local confirmSpawn = spawnConfirmation(args)
            if confirmSpawn then
                spawnPlayer(args.coords)
            else
                lib.showMenu('spawn_menu')
            end
        end)
        lib.showMenu('houses_spawn_menu')
    end
end

-- Open Spawn Menu --
local function spawnMenu()
    playerData = qbx_core:GetPlayerData()

    local spawnLocations = {}

    if playerData.position then
        local optionID = #spawnLocations+1
        spawnLocations[optionID] = {
            label = 'Last Location',
            title = 'Last Location',
            icon = 'fas fa-map-pin',
            args = {
                coords = playerData.position,
                type = 'current'
            }
        }

        if config.useContext then
            spawnLocations[optionID].onSelect = function()
                local confirmSpawn = spawnConfirmation(spawnLocations[optionID].args)
                if confirmSpawn then
                    spawnPlayer(spawnLocations[optionID].args.coords)
                else
                    lib.showContext('spawn_menu')
                end
            end
        end
    end

    for x = 1, #config.spawns do
        local info = config.spawns[x]
        local hasGroups = utils.groupsCheck(info.groups)
        if hasGroups then
            local optionID = #spawnLocations+1
            spawnLocations[optionID] = {
                label = info.label,
                title = info.label,
                description = info?.description,
                icon = info?.icon,
                iconColor = info?.iconColor,
                iconAnimation = info?.iconAnimation,
                args = {
                    location = x,
                    coords = info.coords,
                    type = 'normal'
                }
            }

            if config.useContext then
                spawnLocations[optionID].onSelect = function()
                    local confirmSpawn = spawnConfirmation(spawnLocations[optionID].args)
                    if confirmSpawn then
                        spawnPlayer(spawnLocations[optionID].args.coords)
                    else
                        lib.showContext('spawn_menu')
                    end
                end
            end
        end
    end

    local houses = lib.callback.await('qbx_spawn:server:getHouses')
    if houses and houses[1] then
        local optionID = #spawnLocations+1
        spawnLocations[optionID] = {
            label = 'View Owned Houses',
            title = 'View Owned Houses',
            icon = 'fas fa-house-chimney',
            description = 'Spawn at the front door of one of your owned properties!',
            args = houses
        }

        if config.useContext then
            spawnLocations[optionID].onSelect = function()
                housesMenu(houses)
            end
        end
    end

    if config.useContext then
        lib.registerContext({
            id = 'spawn_menu',
            title = 'Choose Spawn Location',
            canClose = false,
            options = spawnLocations
        })
        lib.showContext('spawn_menu')
    else
        lib.registerMenu({
            id = 'spawn_menu',
            title = 'Choose Spawn Location',
            position = 'top-left',
            canClose = false,
            options = spawnLocations
        }, function(selected, scrollIndex, args)
            if (selected ~= #spawnLocations) then
                local confirmSpawn = spawnConfirmation(args)
                if confirmSpawn then
                    spawnPlayer(args.coords)
                else
                    lib.showMenu('spawn_menu')
                end
            else
                housesMenu(args)
            end
        end)
        lib.showMenu('spawn_menu')
    end
end

local GetPlayerSwitchState = GetPlayerSwitchState
local function openSpawnUI()
    SetEntityVisible(cache.ped, false)
    DoScreenFadeOut(500)
    Wait(1000)
    DoScreenFadeIn(500)
    utils.setChoosingSpawnState(true)

    SwitchOutPlayer(cache.ped, 0, 1)

    while GetPlayerSwitchState() ~= 5 do
        Wait(0)
    end

    spawnMenu()
end

AddEventHandler('qb-spawn:client:setupSpawns', openSpawnUI)