local _isLoggedIn = false
local GLOBAL_PED, GLOBAL_COORDS = nil, nil
local blips = {}
local closeMarkers = {}
local _character = nil

AddEventHandler('Police:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['bs_base']:FetchComponent('Callbacks')
    Logger = exports['bs_base']:FetchComponent('Logger')
    Jobs = exports['bs_base']:FetchComponent('Jobs')
    Police = exports['bs_base']:FetchComponent('Police')
    Markers = exports['bs_base']:FetchComponent('Markers')
    Menu = exports['bs_base']:FetchComponent('Menu')
    Notification = exports['bs_base']:FetchComponent('Notification')
    Game = exports['bs_base']:FetchComponent('Game')
    Hud = exports['bs_base']:FetchComponent('Hud')
    Vehicle = exports['bs_base']:FetchComponent('Vehicle')
    Action = exports['bs_base']:FetchComponent('Action')
    Prison = exports['bs_base']:FetchComponent('Prison')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['bs_base']:RequestDependencies('Police', {
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
        'Prison'
    }, function(error)  
        if #error > 0 then return; end
        RetrieveComponents()
    end) 
end)

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['bs_base']:RegisterComponent('Police', POLICE)
end)

AddEventHandler('Characters:Client:Spawn', function()
    _isLoggedIn = true
    _character = exports['bs_base']:FetchComponent('Player').LocalPlayer:GetData('Character'):GetData()
    GLOBAL_PED = PlayerPedId()
    GLOBAL_COORDS = GetEntityCoords(GLOBAL_PED)
    startTicks()
    Police:DoBlips()
end)

RegisterNetEvent('Characters:Client:SetData')
AddEventHandler('Characters:Client:SetData', function()
    _character = exports['bs_base']:FetchComponent('Player').LocalPlayer:GetData('Character'):GetData()
end)

RegisterNetEvent('Characters:Client:Logout')
AddEventHandler('Characters:Client:Logout', function()
    _isLoggedIn = false
    GLOBAL_COORDS, GLOBAL_PED = nil, nil
    Police:RemoveBlips()
    Police:RemoveMarkers()
end)

function startTicks()
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

    Police:DoMarkers()
end

POLICE = {
    CheckNearStation = function(self, reqdist, cb)
        local withinRange = false
        for k, v in pairs(Config.Locations) do
            local distance = #(GLOBAL_COORDS - vector3(v.location.x, v.location.y, v.location.z))
            if distance < reqdist then
                withinRange = true
                cb(true)
            end
        end

        if not withinRange then
            cb(false)
        end
    end,
    DoBlips = function(self)
        for k, v in pairs(Config.Locations) do
            blips[k] = AddBlipForCoord(v.location.x, v.location.y, v.location.z)
            SetBlipSprite(blips[k], Config.Blips.type)
            SetBlipDisplay(blips[k], 4)
            SetBlipScale  (blips[k], Config.Blips.scale)
            SetBlipColour (blips[k], Config.Blips.color)
            SetBlipAsShortRange(blips[k], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Police Station")
            EndTextCommandSetBlipName(blips[k])
        end
    end,
    RemoveBlips = function(self)
        for k, v in pairs(blips) do
            RemoveBlip(v)
        end
        blips = {}
    end,
    ToggleDuty = function(self)
        if _character.Job.job == "police" then
            TriggerServerEvent('Jobs:Server:ToggleDuty')
        end
    end,
    DoMarkers = function(self)
        for k, v in pairs(Config.Locations) do
            local location = vector3(v.location.x, v.location.y, v.location.z)
            Markers.MarkerGroups:Add('police'..k, location, Config.DrawDistance)
            for q, x in pairs(v.markers) do
                local innerlocation = vector3(x.coords.x, x.coords.y, x.coords.z-(q == "garage" and 0.0 or q == "helipad" and 0.0 or 0.98))
                local size = (q == "garage" and 1.0 or q == "helipad" and 1.0 or 0.5)
                Markers.Markers:Add('police'..k, k..q, innerlocation, (q == "garage" and 36 or q == "helipad" and 34 or 27), vector3(size, size, size), (q == "evidenceTrash" and { r = 255, b = 0, g = 0 } or { r = 255, b = 255, g = 0 }), function()
                    return (x.public or (not x.public and _character.Job.job == 'police' and (not x.dutyNeeded or (x.dutyNeeded and _character.JobDuty))))
                end, x.message, (q == "garage" and 1.5 or q == "helipad" and 1.5 or 1.0), function()
                    if q == "evidenceTrash" then
                        self:OpenEvidence('evidenceTrash', k)
                    elseif q == "evidenceStorage" then
                        self:OpenEvidence('evidenceStorage')
                    elseif q == "duty" then
                        self:ToggleDuty()
                    elseif q == "garage" then
                        self:OpenVehicleGarage(k)
                    elseif q == "helipad" then
                        self:OpenHelicopterGarage(k)
                    end
                end)
            end
        end
    end,
    RemoveMarkers = function(self)
        for k, v in pairs(Config.Locations) do
            Markers.MarkerGroups:Remove('police'..k)
        end
    end,
    OpenEvidence = function(self, etype, k)
        if (_character.Job.job == 'police' or _character.Job.job == "judge") and _character.JobDuty then
            if etype == 'evidenceTrash' then
                TriggerServerEvent('Police:Server:openEvidence', etype, k)
            elseif etype == 'evidenceStorage' then
                local evidenceNumber
                local menu = Menu:Create('evidenceMenu', 'Evidence Storage')
                menu.Add:Number('Case Number', {
                    disabled = false,
                    min = Config.MinCaseNumber,
                    max = 100000,
                    current = nil,
                }, function(data)
                    evidenceNumber = data.data.value
                end)

                menu.Add:Button('Open Storage', { success = true }, function(data)
                    if evidenceNumber ~= nil and tonumber(evidenceNumber) >= Config.MinCaseNumber then
                        TriggerServerEvent('Police:Server:openEvidence', etype, evidenceNumber)
                        menu:Close()
                    else
                        Notification:Error('Case Numbers are numbers of 10000+', 3600)
                    end
                end)
                menu:Show()
            end
        end
    end,
    OpenVehicleGarage = function(self, station)
        if station and _character.Job.job == 'police' and _character.JobDuty then
            local menu = Menu:Create('vehicleGarageMenu'..station, Config.Locations[station].name..' Garage')
            for k, v in pairs(Config.Locations[station].markers.garage.availableVehicles) do
                if k <= _character.Job.grade.level then
                    for t,q in pairs(v) do
                        menu.Add:Button(q, {  }, function(data)
                            Game.Vehicles:Spawn({ x = Config.Locations[station].markers.garage.spawnCoords.x, y = Config.Locations[station].markers.garage.spawnCoords.y, z = Config.Locations[station].markers.garage.spawnCoords.z }, q, Config.Locations[station].markers.garage.spawnCoords.h, function(vehicle)
                                SetVehicleLivery(vehicle, tonumber(Config.Locations[station].markers.garage.livery[1][1]))
                                Vehicle.Keys:GetKeys(GetVehicleNumberPlateText(vehicle), true)
                                Notification:Success('Vehicle Retreived', 2500)
                            end)
                            menu:Close()
                        end)
                    end
                end
            end
            menu:Show()
        end
    end,
    OpenHelicopterGarage = function(self, station)
        if station and _character.Job.job == 'police' and _character.JobDuty then
            local menu = Menu:Create('helipadGarageMenu'..station, Config.Locations[station].name..' Helipad')
            for k, v in pairs(Config.Locations[station].markers.helipad.availableVehicles) do
                if k <= _character.Job.grade.level then
                    for t,q in pairs(v) do
                        menu.Add:Button(q, {  }, function(data)
                            Game.Vehicles:Spawn({ x = Config.Locations[station].markers.helipad.spawnCoords.x, y = Config.Locations[station].markers.helipad.spawnCoords.y, z = Config.Locations[station].markers.helipad.spawnCoords.z }, q, Config.Locations[station].markers.helipad.spawnCoords.h, function(vehicle)
                                SetVehicleLivery(vehicle, tonumber(Config.Locations[station].markers.helipad.livery[1][1]))
                                Vehicle.Keys:GetKeys(GetVehicleNumberPlateText(vehicle), true)
                                Notification:Success('Vehicle Retreived', 2500)
                            end)
                            menu:Close() 
                        end)
                    end
                end
            end
            menu:Show()
        end
    end,
    JailPlayer = function(self, loc, time)
        JailPlayer(loc, time)
    end,
}

function JailPlayer(loc, time)
    if loc ~= nil then
        if Config.PhotoShoots[loc] == nil then
            loc = 1
        end
        local playerPed = GLOBAL_PED
        local playerCurrentCoords = GLOBAL_COORDS
        local doingPhotoshoot = true

        local currentLocation = Config.PhotoShoots[loc]
        if currentLocation ~= nil then
            for k, v in pairs(currentLocation.neededProps) do
                RequestModel(GetHashKey(v))
                while not HasModelLoaded(GetHashKey(v)) do
                    Citizen.Wait(1)
                end
            end

            local boardHash = GetHashKey("prop_police_id_board")
            local overlayHash = GetHashKey("prop_police_id_text")


            RequestModel(currentLocation.officerModel)

            while not HasModelLoaded(currentLocation.officerModel) do
                Citizen.Wait(1)
            end
            local policeOfficer = CreatePed(5, currentLocation.officerModel, currentLocation.officerCoords.x, currentLocation.officerCoords.y, currentLocation.officerCoords.z, currentLocation.officerCoords.h, false)
            local shootCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", currentLocation.officerCoords.x, currentLocation.officerCoords.y, currentLocation.officerCoords.z+1.3, 0.00, 0.00, 0.00, 70.00, false, 0)
            PointCamAtCoord(shootCam, currentLocation.playerCoords.x, currentLocation.playerCoords.y, currentLocation.playerCoords.z)
            TaskStartScenarioInPlace(policeOfficer, "WORLD_HUMAN_PAPARAZZI", -1, false)

            Citizen.CreateThread(function()
                while doingPhotoshoot do
                    DisableControlAction(0, 24, true) -- Attack
                    DisableControlAction(0, 257, true) -- Attack 2
                    DisableControlAction(0, 25, true) -- Aim
                    DisableControlAction(0, 263, true) -- Melee Attack 1
                    DisableControlAction(0, 32, true) -- W
                    DisableControlAction(0, 34, true) -- A
                    DisableControlAction(0, 31, true) -- S
                    DisableControlAction(0, 30, true) -- D
                    DisableControlAction(0, 45, true) -- Reload
                    DisableControlAction(0, 22, true) -- Jump
                    DisableControlAction(0, 44, true) -- Cover
                    DisableControlAction(0, 37, true) -- Select Weapon
                    DisableControlAction(0, 23, true) -- Also 'enter'?
                    DisableControlAction(0, 288,  true) -- Disable phone
                    DisableControlAction(0, 289, true) -- Inventory
                    DisableControlAction(0, 170, true) -- Animations
                    DisableControlAction(0, 167, true) -- Job
                    DisableControlAction(0, 0, true) -- Disable changing view
                    DisableControlAction(0, 26, true) -- Disable looking behind
                    DisableControlAction(0, 73, true) -- Disable clearing animation
                    DisableControlAction(2, 199, true) -- Disable pause screen
                    DisableControlAction(0, 59, true) -- Disable steering in vehicle
                    DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
                    DisableControlAction(0, 72, true) -- Disable reversing in vehicle
                    DisableControlAction(2, 36, true) -- Disable going stealth
                    DisableControlAction(0, 47, true)  -- Disable weapon
                    DisableControlAction(0, 264, true) -- Disable melee
                    DisableControlAction(0, 257, true) -- Disable melee
                    DisableControlAction(0, 140, true) -- Disable melee
                    DisableControlAction(0, 141, true) -- Disable melee
                    DisableControlAction(0, 142, true) -- Disable melee
                    DisableControlAction(0, 143, true) -- Disable melee
                    DisableControlAction(0, 75, true)  -- Disable exit vehicle
                    DisableControlAction(27, 75, true) -- Disable exit vehicle
                    DisableControlAction(0, 344, true) -- Toggle Hud
                    Citizen.Wait(1)
                end
            end)

            Citizen.CreateThread(function()
                DoScreenFadeOut(1500)
                Citizen.Wait(1501)
                Hud:Hide()
                SetEntityCoords(playerPed, currentLocation.playerCoords.x, currentLocation.playerCoords.y, currentLocation.playerCoords.z, 0.0, 0.0, 0.0, false)
                Citizen.Wait(500)
                local board = CreateObject(boardHash, currentLocation.playerCoords.x, currentLocation.playerCoords.y, currentLocation.playerCoords.z, false, true, false)
                local overlay = CreateObject(overlayHash, currentLocation.playerCoords.x, currentLocation.playerCoords.y, currentLocation.playerCoords.z, false, true, false)
                AttachEntityToEntity(overlay, board, -1, 4103, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                SetModelAsNoLongerNeeded(boardHash)
                SetModelAsNoLongerNeeded(overlayHash)
                ClearPedWetness(playerPed)
                ClearPedBloodDamage(playerPed)
                ClearPlayerWantedLevel(PlayerId())
                SetCurrentPedWeapon(playerPed, GetHashKey("weapon_unarmed"), 1)
                AttachEntityToEntity(board, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                local dict = "mp_character_creation@lineup@male_a"
                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do
                    Citizen.Wait(10)
                end

                local board_scaleform = LoadScaleform("mugshot_board_01")
                local handle = CreateNamedRenderTargetForModel("ID_Text", overlayHash)

                Citizen.CreateThread(function()
                    while handle do
                        HideHudAndRadarThisFrame()
                        SetTextRenderId(handle)
                        Set_2dLayer(4)
                        Citizen.InvokeNative(0xC6372ECD45D73BCD, 1)
                        DrawScaleformMovie(board_scaleform, 0.405, 0.37, 0.81, 0.74, 255, 255, 255, 255, 0)
                        Citizen.InvokeNative(0xC6372ECD45D73BCD, 0)
                        SetTextRenderId(GetDefaultScriptRendertargetRenderId())
        
                        Citizen.InvokeNative(0xC6372ECD45D73BCD, 1)
                        Citizen.InvokeNative(0xC6372ECD45D73BCD, 0)
                        if _character then
                            CallScaleformMethod(board_scaleform, 'SET_BOARD', "Sentenced", _character.First..' '.._character.Last, "Blue Sky", time.." Months", 0, 1337, 116)
                        end
                        Citizen.Wait(0)
                    end
                end)

                holdingSign = true
                TaskPlayAnim(playerPed, dict, "loop_raised", 8.0, 8.0, -1, 49, 0, false, false, false)
                SetEntityHeading(policeOfficer, currentLocation.officerCoords.h)
                SetEntityHeading(playerPed, currentLocation.playerCoords.h)
                TaskLookAtEntity(playerPed, policeOfficer, -1, 2048, 3)
                SetCamActive(shootCam, true)
                RenderScriptCams(true, true, 0, true, true)
                Citizen.Wait(1501)
                DoScreenFadeIn(1500)
                Citizen.Wait(5000)
                SetEntityHeading(playerPed, currentLocation.playerCoords.h+90.0)
                SetEntityHeading(policeOfficer, currentLocation.officerCoords.h)
                Citizen.Wait(5000)
                SetEntityHeading(playerPed, currentLocation.playerCoords.h-90.0)
                SetEntityHeading(policeOfficer, currentLocation.officerCoords.h)
                Citizen.Wait(5000)
                SetEntityHeading(playerPed, currentLocation.playerCoords.h)
                SetEntityHeading(policeOfficer, currentLocation.officerCoords.h)
                Citizen.Wait(5000)
                ClearPedTasks(policeOfficer)
                TaskLookAtEntity(policeOfficer, playerPed, -1, 2048, 3)
                Citizen.Wait(1000)
                SetEntityHeading(policeOfficer, currentLocation.officerCoords.h)
                ClearPedSecondaryTask(playerPed)
                DeleteObject(overlay)
                DeleteObject(board)
                holdingSign = false
                DoScreenFadeOut(1501)
                Citizen.Wait(1500)
                doingPhotoshoot = false
                handle = nil
                RenderScriptCams(false, false, 0, false, false)
                DestroyCam(shootCam, false)
                DeletePed(policeOfficer)
                Prison:SendToPrison(time)
                Hud:Show()
            end)
        end
    end
end

RegisterNetEvent('Police:Clien:JailPlayer')
AddEventHandler('Police:Clien:JailPlayer', function(time)
    local done = false
    for k, v in pairs(Config.Locations) do
        local plyDistance = #(GLOBAL_COORDS - vector3(v.location.x, v.location.y, v.location.z))
        if plyDistance < 200.0 then
            print('Shoot Selected', k)
            Police:JailPlayer(k, time)
            done = true
            break;
        end
    end
    
    if not done then
        Police:JailPlayer(1, time)
    end
end)