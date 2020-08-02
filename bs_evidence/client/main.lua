characterLoaded, _charData = false, nil
GLOBAL_COORDS, GLOBAL_PED = nil, nil

AddEventHandler('Evidence:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['bs_base']:FetchComponent('Callbacks')
    Logger = exports['bs_base']:FetchComponent('Logger')
    Jobs = exports['bs_base']:FetchComponent('Jobs')
    Evidence = exports['bs_base']:FetchComponent('Evidence')
    Progress = exports['bs_base']:FetchComponent('Progress')
    Markers = exports['bs_base']:FetchComponent('Markers')
    Menu = exports['bs_base']:FetchComponent('Menu')
    Notification = exports['bs_base']:FetchComponent('Notification')
    Inventory = exports['bs_base']:FetchComponent('Inventory')
    Utils = exports['bs_base']:FetchComponent('Utils')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['bs_base']:RequestDependencies('Evidence', {
        'Callbacks',
        'Logger',
        'Utils',
        'Jobs',
        'Evidence',
        'Progress',
        'Markers',
        'Menu',
        'Notification',
        'Inventory',
    }, function(error)  
        if #error > 0 then return; end
        RetrieveComponents()
    end) 
end)

RegisterNetEvent('Evidence:Client:SendEvidence')
AddEventHandler('Evidence:Client:SendEvidence', function(data)
    if characterLoaded then
        Evidence.Funcs:EvidencePool(data)
    end
end)

RegisterNetEvent('Evidence:Client:SendEvidencePool')
AddEventHandler('Evidence:Client:SendEvidencePool', function(pool, data)
    if characterLoaded then
        Evidence.Funcs:SubPool(pool, data)
    end
end)

EVIDENCE = {
    Data = { 
        MainPool = {},
        DistancePool = {}
    },
    Funcs = {
        EvidencePool = function(self, data)
            Evidence.Data.MainPool = data
        end,
        SubPool = function(self, pool, data)
            Evidence.Data.MainPool[pool] = data
        end,
        DrawText = function(self, x,y,z,text)
            local onScreen,_x,_y=World3dToScreen2d(x,y,z)
            local px,py,pz=table.unpack(GetGameplayCamCoords())
            SetTextScale(0.28, 0.28)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextColour(255, 255, 255, 245)
            SetTextOutline(true)
            SetTextEntry("STRING")
            SetTextCentre(1)
            AddTextComponentString(text)
            DrawText(_x,_y)
        end,
    },
    GetPool = {
        MainPool = function(self)
            return (Evidence.Data.MainPool or {})
        end,
        SubPool = function(self, pool)
            return (Evidence.Data.MainPool[pool] or {})
        end,
    },
    Create = {
        DNA = function(self, zone, data, cb)
            TriggerServerEvent('Evidence:RegisterEvidence', {type = "dna", zone = zone, data = data})
        end,
        VehicleFragment = function(self, zone, data, cb)
            TriggerServerEvent('Evidence:RegisterEvidence', {type = "vehiclefragment", zone = zone, data = data})
        end,
        BulletFragment = function(self, zone, data, cb)
            TriggerServerEvent('Evidence:RegisterEvidence', {type = "bulletfragment", zone = zone, data = data})
        end,
        BulletCasing = function(self, zone, data, cb)
            TriggerServerEvent('Evidence:RegisterEvidence', {type = "casing", zone = zone, data = data})
        end,
        Loco = function(self, zone, data, cb)
            TriggerServerEvent('Evidence:RegisterEvidence', {type = "loco", zone = zone, data = data})
        end
    },
    Startup = {
        Start = function(self)
            Callbacks:ServerCallback('Evidence:Server:ReceivePools', {}, function(data)
                Evidence.Data.MainPool = data
                _charData = exports['bs_base']:FetchComponent('Player').LocalPlayer:GetData('Character'):GetData()
                characterLoaded = true
            end)
        end,
        CharacterLoad = function(self)
            storedEvidence = {}

            Citizen.CreateThread(function()
                while characterLoaded do
                Citizen.Wait(500)
                    if characterLoaded then
                        local playerPed = PlayerPedId()
                        if playerPed ~= GLOBAL_PED then
                            GLOBAL_PED = playerPed
                        end
                    end
                end
            end)

            Citizen.CreateThread(function()
                while characterLoaded do
                    if GLOBAL_PED and GLOBAL_COORDS then
                        local scanDistance = 10
                        local minScan = 8
                        local closestID = false
                        local internalType = false
                        local internalType2 = false
                        local pedZone = GetNameOfZone(GLOBAL_COORDS.x, GLOBAL_COORDS.y, GLOBAL_COORDS.z)
                        if (GetSelectedPedWeapon(GLOBAL_PED) == -1951375401 and IsPlayerFreeAiming(PlayerId())) then
                            if Evidence.Data.MainPool[pedZone] then
                                for t, x in pairs(Evidence.Data.MainPool[pedZone]) do
                                    for l, q in pairs(x) do
                                        if (q.type ~= "casing" and _charData.Job.job == "police" and _charData.JobDuty) or (q.type == "casing") then
                                            local distance = #(GLOBAL_COORDS - vector3(q.hitCoords.x, q.hitCoords.y, q.hitCoords.z))
                                            if distance <= scanDistance then
                                                if distance < minScan then
                                                    minScan = distance
                                                    closestID = pedZone
                                                    internalType = t
                                                    internalType2 = l
                                                end
                                                
                                                if q.type == "bulletfragment" and _charData.Job.job == "police" and _charData.JobDuty then
                                                    DrawMarker(0, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 56, 165, 61, 250, false, false, 2, false, false, false, false)
                                                elseif q.type == "vehiclefragment" and _charData.Job.job == "police" and _charData.JobDuty then
                                                    if q.vehicle.class == 8 or q.vehicle.class == 9 then -- motorbikes
                                                        DrawMarker(37, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, q.vehicle.r, q.vehicle.g, q.vehicle.b, 250, false, false, 2, false, false, false, false)
                                                    elseif q.vehicle.class == 10 or q.vehicle.class == 11 or q.vehicle.class == 12 then -- trucks
                                                        DrawMarker(39, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, q.vehicle.r, q.vehicle.g, q.vehicle.b, 250, false, false, 2, false, false, false, false)
                                                    elseif q.vehicle.class == 13 then -- bycycles
                                                        DrawMarker(38, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, q.vehicle.r, q.vehicle.g, q.vehicle.b, 250, false, false, 2, false, false, false, false)
                                                    elseif q.vehicle.class == 16 then -- planes
                                                        DrawMarker(33, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, q.vehicle.r, q.vehicle.g, q.vehicle.b, 250, false, false, 2, false, false, false, false)
                                                    elseif q.vehicle.class == 15 then -- helis
                                                        DrawMarker(34, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, q.vehicle.r, q.vehicle.g, q.vehicle.b, 250, false, false, 2, false, false, false, false)
                                                    elseif q.vehicle.class == 14 then -- boats
                                                        DrawMarker(35, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, q.vehicle.r, q.vehicle.g, q.vehicle.b, 250, false, false, 2, false, false, false, false)
                                                    else
                                                        DrawMarker(36, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, q.vehicle.r, q.vehicle.g, q.vehicle.b, 250, false, false, 2, false, false, false, false)
                                                    end
                                                elseif q.type == "dna" or q.type == "loco" and _charData.Job.job == "police" and _charData.JobDuty then
                                                    DrawMarker(28, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.1, 0.1, 0.1, 255, 0, 0, 250, false, false, 2, false, false, false, false)
                                                elseif q.type == "casing" then
                                                    DrawMarker(27, q.hitCoords.x, q.hitCoords.y, q.hitCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, 56, 0, 1, 250, false, false, 2, false, false, false, false)
                                                end
                                            end
                                        end
                                    end
                                end

                                if closestID and internalType and internalType2 then
                                    drawMsg = Evidence.Data.MainPool[closestID][internalType][internalType2].type
                                    if drawMsg == "vehiclefragment" then
                                        drawMsg = "Vehicle Fragment"
                                    else
                                        drawMsg = Config.Labels[drawMsg]
                                    end
                                    
                                    local actionSettings = {
                                        task = "WORLD_HUMAN_JANITOR"
                                    }
                                    
                                    local action = "Cleaning Evidence"
                                    local time = math.random(10000,15000)
                                    
                                    if (_charData.Job.job == "police" and _charData.JobDuty) then
                                        drawMsg = drawMsg .."\n[E] Collect Evidence"
                                        actionSettings = {
                                            animDict = "amb@code_human_police_investigate@idle_b",
                                            anim = "idle_f",
                                            flags = 49,
                                        }
                                        time = math.random(5000,10000)
                                        action = "Collecting Evidence"                                        
                                    else
                                        drawMsg = drawMsg .."\n[E] Clean Evidence"
                                    end
                                    local allowPress = true
                                    Evidence.Funcs:DrawText(Evidence.Data.MainPool[closestID][internalType][internalType2].hitCoords.x, Evidence.Data.MainPool[closestID][internalType][internalType2].hitCoords.y, Evidence.Data.MainPool[closestID][internalType][internalType2].hitCoords.z+0.23, drawMsg)
                                    if IsControlJustReleased(0,38) and minScan < 1.2 and allowPress then
                                        allowPress = false
                                        
                                        Progress:Progress({
                                            name = "evidence_pickup_clean",
                                            duration = time,
                                            label = action,
                                            useWhileDead = false,
                                            canCancel = true,
                                            vehicle = false,
                                            controlDisables = {
                                                disableMovement = false,
                                                disableCarMovement = false,
                                                disableMouse = false,
                                                disableCombat = false,
                                            },
                                            animation = actionSettings,
                                        }, function(status)
                                            allowPress = true
                                            if not status then
                                                TriggerServerEvent('Evidence:Server:PickupEvidence', GLOBAL_COORDS, closestID, internalType, internalType2)                                            
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                    Citizen.Wait(5)
                end
            end)

            Citizen.CreateThread(function()
                while characterLoaded do
                    Citizen.Wait(200)
                    if characterLoaded then
                        GLOBAL_COORDS = GetEntityCoords(GLOBAL_PED)
                    end
                end
            end)
        end,
    }
}

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['bs_base']:RegisterComponent('Evidence', EVIDENCE)
end)

AddEventHandler('Characters:Client:Updated', function()
    _charData = exports['bs_base']:FetchComponent('Player').LocalPlayer:GetData('Character'):GetData()
end)

AddEventHandler('Characters:Client:Spawn', function()
    GLOBAL_PED = PlayerPedId()
    GLOBAL_COORDS = GetEntityCoords(GLOBAL_PED)
    characterLoaded = true
    Evidence.Startup:CharacterLoad()
    Evidence.Startup:Start()
end)

RegisterNetEvent('Characters:Client:Logout')
AddEventHandler('Characters:Client:Logout', function()
    characterLoaded = false
    _charData = nil
    Evidence.Data.MainPool = {}
end)