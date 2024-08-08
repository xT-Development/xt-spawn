local lib               = lib
local qbx_core          = exports.qbx_core
local spawn_options     = lib.load('configs.spawns')
local utils             = lib.load('client.utils')

playerData = {}

local function cleanupPlayerSpawned()
    FreezeEntityPosition(cache.ped, false)
    SetEntityVisible(cache.ped, true)
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
    local spawnName = (info.type == 'normal' and spawn_options[info.location].label) or (info.type == 'current' and 'Last Location') or (info.type == 'house' and info.name)
    local confirmation = lib.alertDialog({
        header = 'Spawn Confirmation',
        content = ('Are you sure you want to spawn here?  \n\n**%s**'):format(spawnName),
        centered = true,
        cancel = true
    })
    return (confirmation == 'cancel') and false or confirmation
end

-- View Owned Houses --
local function housesMenu(houses)
    local spawnLocations = {}

    for x = 1, #houses do
        local houseInfo = houses[x]
        spawnLocations[#spawnLocations+1] = {
            label = houseInfo.label,
            icon = 'fas fa-house',
            args = {
                location = x,
                coords = houseInfo.coords,
                name = houseInfo.label,
                type = 'house'
            }
        }
    end

    lib.registerMenu({
        id = 'houses_spawn_menu',
        title = 'Choose House',
        position = 'top-left',
        onClose = function()
            lib.showMenu('spawn_menu')
        end,
        options = spawnLocations
    }, function(selected, scrollIndex, args)
        local locationIndex = args?.location or 0
        local confirmSpawn = spawnConfirmation(args)
        if confirmSpawn then
            spawnPlayer(args.coords)
        else
            lib.showMenu('spawn_menu')
        end
    end)
    lib.showMenu('houses_spawn_menu')
end

-- Open Spawn Menu --
local function spawnMenu()
    playerData = qbx_core:GetPlayerData()

    local spawnLocations = {}

    if playerData.position then
        spawnLocations[#spawnLocations+1] = {
            label = 'Last Location',
            icon = 'fas fa-map-pin',
            args = {
                coords = playerData.position,
                type = 'current'
            }
        }
    end

    for x = 1, #spawn_options do
        local info = spawn_options[x]
        local hasGroups = utils.groupsCheck(info.groups)
        if hasGroups then
            spawnLocations[#spawnLocations+1] = {
                label = info.label,
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
        end
    end

    local houses = lib.callback.await('qbx_spawn:server:getHouses')
    if houses and houses[1] then
        spawnLocations[#spawnLocations+1] = {
            label = 'View Owned Houses',
            icon = 'fas fa-house-chimney',
            description = 'Spawn at the front door of one of your owned properties!'
            args = houses
        }
    end

    lib.registerMenu({
        id = 'spawn_menu',
        title = 'Choose Spawn Location',
        position = 'top-left',
        canClose = false,
        options = spawnLocations
    }, function(selected, scrollIndex, args)
        if (selected ~= #spawnLocations) then
            local locationIndex = args?.location or 0
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