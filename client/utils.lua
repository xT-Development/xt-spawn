local playerState = LocalPlayer.state

local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local SetEntityHeading = SetEntityHeading
local GetPlayerSwitchState = GetPlayerSwitchState
local DisableAllControlActions = DisableAllControlActions
local HasCollisionLoadedAroundEntity = HasCollisionLoadedAroundEntity

local function initDisableControlsThread()
    CreateThread(function()
        while playerState.choosingSpawn do
            DisableAllControlActions(0)
            Wait(0)
        end
    end)
end

local function loadingSpinner()
    local playerName = ('%s %s'):format(playerData.charinfo.firstname, playerData.charinfo.lastname)
    AddTextEntry("SPAWNSTR", ("Spawning %s..."):format(playerName))
    BeginTextCommandBusyspinnerOn("SPAWNSTR")
    EndTextCommandBusyspinnerOn(4)

    CreateThread(function()
        while GetPlayerSwitchState() ~= 12 do
            Wait(0)
        end

        BusyspinnerOff()
    end)
end

local utils = {}

function utils.setPlayerCoords(coords)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z - 0.9, 0, 0, 0, false)
    SetEntityHeading(cache.ped, coords.w)
    local dist = #(vec3(coords.x, coords.y, coords.z - 0.9) - GetEntityCoords(cache.ped))
    return (dist <= 5) or false
end

function utils.groupsCheck(groups)
    if not groups then return true end
    local callback = false
    for x = 1, #groups do
        if playerData.job and playerData.job.name == groups[x] then
            callback = true
            break
        end
    end
    return callback
end

function utils.setChoosingSpawnState(isChoosing)
    playerState.choosingSpawn = isChoosing
    if isChoosing then
        initDisableControlsThread()
    end
end

function utils.switchToPlayer() -- https://github.com/overextended/ox_core/blob/lua/client/spawn.lua#L187
    SetGameplayCamRelativeHeading(0)

    while GetPlayerSwitchState() ~= 5 do
        Wait(0)
    end

    SwitchInPlayer(cache.ped)
    loadingSpinner()

    while GetPlayerSwitchState() ~= 12 do
        Wait(0)
    end

    while not HasCollisionLoadedAroundEntity(cache.ped) do
        Wait(10)
    end
end

return utils