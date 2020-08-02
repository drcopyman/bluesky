local currentJobCount, currentJobIdent = 0, {}
local randomJobTime = math.random(10000,30000)
local releaseEligability, inPrison, timeRemaining = false, false, 0
local doingaJob, doingExcercise, doingFood = false, false, false
local blip, prisonBlip = 0, 0
local _isLoggedIn = false


AddEventHandler('Prison:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['bs_base']:FetchComponent('Callbacks')
    Logger = exports['bs_base']:FetchComponent('Logger')
    Jobs = exports['bs_base']:FetchComponent('Jobs')
    Police = exports['bs_base']:FetchComponent('Police')
    Markers = exports['bs_base']:FetchComponent('Markers')
    Menu = exports['bs_base']:FetchComponent('Menu')
    Notification = exports['bs_base']:FetchComponent('Notification')
    Hud = exports['bs_base']:FetchComponent('Hud')
    Action = exports['bs_base']:FetchComponent('Action')
    Prison = exports['bs_base']:FetchComponent('Prison')
    Utils = exports['bs_base']:FetchComponent('Utils')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['bs_base']:RequestDependencies('Prison', {
        'Callbacks',
        'Logger',
        'Jobs',
        'Police',
        'Markers',
        'Menu',
        'Notification',
        'Game',
        'Hud',
        'Vehicle',
        'Action',
        'Prison',
        'Utils',
    }, function(error)  
        if #error > 0 then return; end
        RetrieveComponents()
    end) 
end)

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['bs_base']:RegisterComponent('Prison', PRISON)
end)

AddEventHandler('Characters:Client:Spawn', function()
    if blip > 0 then
        RemoveBlip(blip)
        blip = 0
    end
    _isLoggedIn = true
    _character = exports['bs_base']:FetchComponent('Player').LocalPlayer:GetData('Character'):GetData()
    GLOBAL_PED = PlayerPedId()
    GLOBAL_COORDS = GetEntityCoords(GLOBAL_PED)
    startTicks()
    if _character.Prison ~= nil then
        if _character.Prison > 0 then
            Prison:SendToPrison(tonumber(_character.Prison), true)
        end
    end
end)

RegisterNetEvent('Prisons:Client:UpdatePrisonTimer')
AddEventHandler('Prisons:Client:UpdatePrisonTimer', function(action, message, silent)
    if action == "updateTime" then
        if type(message) == "number" then
            if message < 3 then
                Notification.Persistent:Remove('prisonCurrentJob')
                doingaJob = false
                doingExcercise = false
                doingFood = false
                currentJobCount = 0
                if blip > 0 then
                    RemoveBlip(blip)
                    blip = 0
                end
            end
            if not silent then
                Notification:Info('You have '..message..' months remaining in prison.', 5000)
            end
            timeRemaining = tonumber(message)
        else
            Notification:Info(message)
            timeRemaining = 0
        end
    elseif action == "updateJob" then
        Notification.Persistent:Info('prisonCurrentJob', message, 5000)
    end
end)

RegisterNetEvent('Characters:Client:Logout')
AddEventHandler('Characters:Client:Logout', function()
    _isLoggedIn = false
    Notification.Persistent:Remove('prisonCurrentJob')
    doingaJob = false
    doingExcercise = false
    doingFood = false
    currentJobCount = 0
    if blip > 0 then
        RemoveBlip(blip)
        blip = 0
    end
end)

RegisterNetEvent('Prisons:Client:ReleaseEligability')
AddEventHandler('Prisons:Client:ReleaseEligability', function(tog)
    if tog then
        Callbacks:ServerCallback('Prisons:Server:ReleaseInmate', {}, function()
            Notification.Persistent:Remove('prisonCurrentJob')
            inPrison = false
            doingaJob = false
            doingExcercise = false
            doingFood = false
            currentJobCount = 0
            if blip > 0 then
                RemoveBlip(blip)
                blip = 0
            end
        end)
    end

    releaseEligability = tog

    Citizen.CreateThread(function()
        while releaseEligability do
            local distance = #(vector3(GLOBAL_COORDS.x, GLOBAL_COORDS.y, GLOBAL_COORDS.z) - vector3(Config.ExitPoint.releaseCoords.x, Config.ExitPoint.releaseCoords.y, Config.ExitPoint.releaseCoords.z))
            print(distance)
            if distance < 1.9 then
                if IsControlJustPressed(0, 38) then
                    if releaseEligability then
                        print('setting free')
                        TriggerServerEvent('Prison:Server:SetPlayerFree')
                    else
                        print('returning to cell')
                        TriggerServerEvent('Prison:Server:SendBackInside')
                    end
                end
            end
            Citizen.Wait(4) -- change before push
        end
    end)
end)

PRISON = {
    SendToPrison = function(self, time, spawn)
        Callbacks:ServerCallback('Prisons:Server:AllocateCell', { time = time }, function(cellLocation)
            if spawn then
                DoScreenFadeIn(1000)
                Citizen.Wait(1001)
            end
            inPrison = true
            currentJobCount = 0
            releaseEligability = false
            SetEntityCoords(GLOBAL_PED, cellLocation.x, cellLocation.y, cellLocation.z, 0, 0, 0, false)
            SetEntityHeading(GLOBAL_PED, cellLocation.h)
            Citizen.Wait(1001)
            DoScreenFadeIn(1000)
            startJob()
        end)
    end,
    ReduceTime = function(self)
        if releaseEligability then return; end
        if timeRemaining < 3 then return; end
        if not _isLoggedIn then return; end
        TriggerServerEvent('Prison:Server:ReduceTimeWork')
    end,
}

function startTicks()
    Citizen.CreateThread(function()
        if prisonBlip > 0 then
            RemoveBlip(prisonBlip)
        end
        prisonBlip = AddBlipForCoord(Config.Location.x, Config.Location.y, Config.Location.z)
        SetBlipSprite(prisonBlip, Config.BlipSprite)
        SetBlipDisplay(prisonBlip, 4)
        SetBlipScale  (prisonBlip, Config.BlipSize)
        SetBlipColour (prisonBlip, Config.BlipColor)
        SetBlipAsShortRange(prisonBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.BlipName)
        EndTextCommandSetBlipName(prisonBlip)
    end)

    Citizen.CreateThread(function()
        while _isLoggedIn do
            GLOBAL_PED = PlayerPedId()
            Citizen.Wait(1000)
        end
    end)

    Citizen.CreateThread(function()
        while _isLoggedIn do
            if GLOBAL_PED then
                GLOBAL_COORDS = GetEntityCoords(GLOBAL_PED)
            end
            Citizen.Wait(200)
        end
    end)

    Citizen.CreateThread(function()
        while _isLoggedIn do
            Citizen.Wait(0)
            local letSleep = true
            local distance = #(GLOBAL_COORDS - vector3(Config.Location.x, Config.Location.y, Config.Location.z))
            if distance < 300.0 then
                letSleep = false
                SetPedDensityMultiplierThisFrame(0.0)
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
            end

            if letSleep then
                Citizen.Wait(1000)
            end
        end
    end)
end

function startExcercise()
    doingExcercise = true

    Citizen.CreateThread(function()
        local randomExcercise = math.random(#Config.ExcercisePoints)
        if randomExcercise > 0 then
            TriggerEvent('Prisons:Client:UpdatePrisonTimer', "updateJob", "Your current task is: "..Config.ExcercisePoints[randomExcercise].label)
            blip = AddBlipForCoord(Config.ExcercisePoints[randomExcercise].x, Config.ExcercisePoints[randomExcercise].y, Config.ExcercisePoints[randomExcercise].z)
            SetBlipSprite(blip, 402)
            SetBlipDisplay(blip, 4)
            SetBlipScale  (blip, 0.75)
            SetBlipColour (blip, 78)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("[~r~Prison~s~] "..Config.ExcercisePoints[randomExcercise].label)
            EndTextCommandSetBlipName(blip)

            while doingExcercise and timeRemaining > 2 and _isLoggedIn do
                Citizen.Wait(4)
                local distance = #(GLOBAL_COORDS - vector3(Config.ExcercisePoints[randomExcercise].x, Config.ExcercisePoints[randomExcercise].y, Config.ExcercisePoints[randomExcercise].z))
                if distance < 10.0 then
                    DrawMarker(27, Config.ExcercisePoints[randomExcercise].x, Config.ExcercisePoints[randomExcercise].y, Config.ExcercisePoints[randomExcercise].z-0.99, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 200, false, true, 2, true, nil, nil, false)
                end

                if IsControlJustPressed(0, 38) and distance < 1.2 then
                    if blip > 0 then
                        RemoveBlip(blip)
                        blip = 0
                    end
                    doingExcercise = false
                    startJob()
                end
            end
        end
    end)
end

function startFood()
    doingFood = true
    Citizen.CreateThread(function()
        local randomFood = math.random(#Config.FoodPoints)
        blip = AddBlipForCoord(Config.FoodPoints[randomFood].x, Config.FoodPoints[randomFood].y, Config.FoodPoints[randomFood].z)
        TriggerEvent('Prisons:Client:UpdatePrisonTimer', "updateJob", "Your current task is: Eat & Drink")
        SetBlipSprite(blip, 402)
        SetBlipDisplay(blip, 4)
        SetBlipScale  (blip, 0.75)
        SetBlipColour (blip, 78)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("[~r~Prison~s~] Eat & Drink")
        EndTextCommandSetBlipName(blip)

        while doingFood and timeRemaining > 2 and _isLoggedIn do
            Citizen.Wait(4)
            local distance = #(GLOBAL_COORDS - vector3(Config.FoodPoints[randomFood].x, Config.FoodPoints[randomFood].y, Config.FoodPoints[randomFood].z))
            if distance < 10.0 then
                DrawMarker(27, Config.FoodPoints[randomFood].x, Config.FoodPoints[randomFood].y, Config.FoodPoints[randomFood].z-0.99, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 200, false, true, 2, true, nil, nil, false)
            end

            if IsControlJustPressed(0, 38) and distance < 1.2 then
                if blip > 0 then
                    RemoveBlip(blip)
                    blip = 0
                end
                doingFood = false
                startJob()
            end
        end
    end)
end

function startJob()
    Notification.Persistent:Remove('prisonCurrentJob')
    doingaJob = false
    currentJobCount = currentJobCount + 1
    if currentJobCount > 7 then
        currentJobCount = 0
    end

    if blip > 0 then
        RemoveBlip(blip)
        blip = 0
    end
    
    if timeRemaining < 3 then return; end
    if releaseEligability then return; end
    if not _isLoggedIn then return; end

    Citizen.CreateThread(function()
        Citizen.Wait(randomJobTime)
        randomJobTime = math.random(10000,30000)
        if timeRemaining > 2 then
            if currentJobCount == 7 then
                startExcercise()
                return;
            elseif currentJobCount == 6 then
                startFood()
                return;
            else   
                local randomJobId = math.random(#Config.Jobs)
                TriggerEvent('Prisons:Client:UpdatePrisonTimer', "updateJob", "Your current job is: "..Config.Jobs[randomJobId].label)
                doingaJob = true
                Citizen.CreateThread(function()
                    blip = AddBlipForCoord(Config.Jobs[randomJobId].x, Config.Jobs[randomJobId].y, Config.Jobs[randomJobId].z)
                    SetBlipSprite(blip, 402)
                    SetBlipDisplay(blip, 4)
                    SetBlipScale  (blip, 0.75)
                    SetBlipColour (blip, 78)
                    SetBlipAsShortRange(blip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("[~r~Prison~s~] "..Config.Jobs[randomJobId].label)
                    EndTextCommandSetBlipName(blip)
                    local completeingJob = false
                    
                    local function doJobAnimations()
                        completeingJob = true
                        Citizen.CreateThread(function()
                            if (Config.Jobs[randomJobId].animation ~= nil) or (Config.Jobs[randomJobId].task ~= nil) then
                                if Config.Jobs[randomJobId].animation == nil and Config.Jobs[randomJobId].task ~= nil then
                                    local cSCoords
                                    local propSpawn
                                    local netid
                                    local prop_net
                                    if Config.Jobs[randomJobId].prop ~= nil then
                                        cSCoords = GetOffsetFromEntityInWorldCoords(GLOBAL_PED, 0.0, 0.0, -5.0)
                                        propSpawn = CreateObject(GetHashKey(Config.Jobs[randomJobId].prop), cSCoords.x, cSCoords.y, cSCoords.z, 1, 1, 1)
                                        netid = ObjToNet(propSpawn)
                                    end
                                    TaskStartScenarioInPlace(GLOBAL_PED, Config.Jobs[randomJobId].task, 0, true)

                                    if Config.Jobs[randomJobId].prop ~= nil then
                                        AttachEntityToEntity(propSpawn,GLOBAL_PED,GetPedBoneIndex(GLOBAL_PED, 28422),-0.005,0.0,0.0,190.0,190.0,-50.0,1,1,0,1,0,1)
                                        prop_net = netid
                                        Citizen.Wait(Config.Jobs[randomJobId].duration)
                                        DetachEntity(NetToObj(prop_net), 1, 1)
                                        DeleteEntity(NetToObj(prop_net))
                                        prop_net = nil
                                    else
                                        Citizen.Wait(Config.Jobs[randomJobId].duration)
                                    end

                                    ClearPedTasks(GLOBAL_PED)

                                elseif Config.Jobs[randomJobId].animation ~= nil and Config.Jobs[randomJobId].task == nil then
                                    local cSCoords
                                    local propSpawn
                                    local netid
                                    local prop_net
                                    if Config.Jobs[randomJobId].prop ~= nil then
                                        cSCoords = GetOffsetFromEntityInWorldCoords(GLOBAL_PED, 0.0, 0.0, -5.0)
                                        propSpawn = CreateObject(GetHashKey(Config.Jobs[randomJobId].prop), cSCoords.x, cSCoords.y, cSCoords.z, 1, 1, 1)
                                        netid = ObjToNet(propSpawn)
                                    end

                                    if not HasAnimDictLoaded(Config.Jobs[randomJobId].animation) then
                                        RequestAnimDict(Config.Jobs[randomJobId].animation)
                                
                                        while not HasAnimDictLoaded(Config.Jobs[randomJobId].animation) do
                                            Citizen.Wait(1)
                                        end
                                    end

                                    TaskPlayAnim(GLOBAL_PED, Config.Jobs[randomJobId].animation, Config.Jobs[randomJobId].dict, 8.0, -8.0, Config.Jobs[randomJobId].duration, 0, 0, false, false, false)

                                    if Config.Jobs[randomJobId].prop ~= nil then
                                        AttachEntityToEntity(propSpawn, GLOBAL_PED, GetPedBoneIndex(GLOBAL_PED, 28422), -0.005, 0.0 ,0.0 ,360.0 ,360.0,0.0,1,1,0,1,0,1)
                                        prop_net = netid
                                        Citizen.Wait(Config.Jobs[randomJobId].duration)
                                        DetachEntity(NetToObj(prop_net), 1, 1)
                                        DeleteEntity(NetToObj(prop_net))
                                        prop_net = nil
                                    else
                                        Citizen.Wait(Config.Jobs[randomJobId].duration)
                                    end

                                    ClearPedTasks(GLOBAL_PED)

                                end
                            else
                                local cSCoords
                                local propSpawn
                                local netid
                                local prop_net
                                if Config.Jobs[randomJobId].prop ~= nil then
                                    cSCoords = GetOffsetFromEntityInWorldCoords(GLOBAL_PED, 0.0, 0.0, -5.0)
                                    propSpawn = CreateObject(GetHashKey(Config.Jobs[randomJobId].prop), cSCoords.x, cSCoords.y, cSCoords.z, 1, 1, 1)
                                    netid = ObjToNet(propSpawn)
                                end
                                if Config.Jobs[randomJobId].prop ~= nil then
                                    AttachEntityToEntity(propSpawn,GLOBAL_PED,GetPedBoneIndex(GLOBAL_PED, 28422),-0.005,0.0,0.0,190.0,190.0,-50.0,1,1,0,1,0,1)
                                    prop_net = netid
                                    Citizen.Wait(Config.Jobs[randomJobId].duration)
                                    DetachEntity(NetToObj(prop_net), 1, 1)
                                    DeleteEntity(NetToObj(prop_net))
                                    prop_net = nil
                                else
                                    Citizen.Wait(Config.Jobs[randomJobId].duration)
                                end
                            end
                            Prison:ReduceTime()
                            doingaJob = false
                            startJob()
                        end)
                    end
                    
                    while doingaJob and timeRemaining > 2 and _isLoggedIn do
                        Citizen.Wait(4)
                        local distance = #(GLOBAL_COORDS - vector3(Config.Jobs[randomJobId].x, Config.Jobs[randomJobId].y, Config.Jobs[randomJobId].z))
                        if distance < 10.0 and not completeingJob then
                            DrawMarker(27, Config.Jobs[randomJobId].x, Config.Jobs[randomJobId].y, Config.Jobs[randomJobId].z-0.99, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 200, false, true, 2, true, nil, nil, false)
                        end
                        
                        if IsControlJustPressed(0, 38) and distance < 1.2 and not completeingJob then
                            if blip > 0 then
                                RemoveBlip(blip)
                                blip = 0
                            end
                            doJobAnimations()
                        end
                    end
                end)
            end
        end
    end)
end