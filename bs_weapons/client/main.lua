local currentWeaponActive = {}
local isLoggedIn, GLOBAL_PED, GLOBAL_COORDS = false, nil, nil
local _character = nil

AddEventHandler('Weapons:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['bs_base']:FetchComponent('Callbacks')
    Weapons = exports['bs_base']:FetchComponent('Weapons')
    Inventory = exports['bs_base']:FetchComponent('Inventory')
    Utils = exports['bs_base']:FetchComponent('Utils')
    Evidence = exports['bs_base']:FetchComponent('Evidence')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['bs_base']:RequestDependencies('Weapons', {
        'Callbacks',
        'Weapons',
        'Inventory',
        'Utils',
        'Evidence'
    }, function(error)  
        if #error > 0 then return; end
        RetrieveComponents()
    end)
end)

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Citizen.Wait(0)
	end
end

function CameraForwardVec()
    local rot = (math.pi / 180.0) * GetGameplayCamRot(2)
    return vector3(-math.sin(rot.z) * math.abs(math.cos(rot.x)), math.cos(rot.z) * math.abs(math.cos(rot.x)), math.sin(rot.x))
end

function Raycast(dist)
    local start = GetGameplayCamCoord()
    local target = start + (CameraForwardVec() * dist)

    local ray = StartShapeTestRay(start, target, -1, GLOBAL_PED, 1)
    local a, b, c, d, ent = GetShapeTestResult(ray)
    return {
        a = a,
        b = b,
        HitPosition = c,
        HitCoords = d,
        HitEntity = ent
    }
end

function WaterTest()
    local fV, sV = TestVerticalProbeAgainstAllWater(GLOBAL_COORDS.x, GLOBAL_COORDS.y, GLOBAL_COORDS.z, 0, 1.0)
    return fV
end

RegisterNetEvent('Weapons:Client:EquipWeapon')
AddEventHandler('Weapons:Client:EquipWeapon', function(weapon, doAnim)
    if weapon and weapon.MetaData.SerialNumber then
        local letsMakeSomeMeta = {
            ['name'] = weapon.Name,
            ['serial'] = weapon.MetaData.SerialNumber,
            ['owner'] = weapon.Owner,
            ['hash'] = GetHashKey(weapon.Name),
            ['ammo'] = weapon.MetaData.ammo,
            ['_id'] = weapon._id,
            ['info'] = weapon.details,
            ['config'] = weapon.details.weaponConfig
        }

        letsMakeSomeMeta.info.weaponConfig = nil
        Weapons.Process:Weapon(letsMakeSomeMeta)
    end
end)

RegisterNetEvent('Characters:Client:Logout')
AddEventHandler('Characters:Client:Logout', function()
    if currentWeaponActive._id ~= nil then
        Weapons.UnEquip:Weapon(currentWeaponActive, function(processed)
            if processed then
                currentWeaponActive = {}
            end                    
        end)
        isLoggedIn, GLOBAL_PED, GLOBAL_COORDS = false, nil, nil
        _character = nil
    end
end)

RegisterNetEvent('Characters:Client:SetData')
AddEventHandler('Characters:Client:SetData', function()
    _character = exports['bs_base']:FetchComponent('Player').LocalPlayer:GetData('Character'):GetData()
end)

RegisterNetEvent('Characters:Client:Spawn')
AddEventHandler('Characters:Client:Spawn', function()
    isloggedIn = true
    createSpawnThreads()
end)

function createSpawnThreads()
    GLOBAL_PED = PlayerPedId()
    GLOBAL_COORDS = GetEntityCoords(GLOBAL_PED)
    _character = exports['bs_base']:FetchComponent('Player').LocalPlayer:GetData('Character'):GetData()

    Citizen.CreateThread(function()
        while isloggedIn do
            local playerPed = PlayerPedId()
            if playerPed ~= GLOBAL_PED then
                GLOBAL_PED = playerPed
            end
            Citizen.Wait(500)
        end
    end)

    Citizen.CreateThread(function()
        while isloggedIn do
            Citizen.Wait(200)
            GLOBAL_COORDS = GetEntityCoords(GLOBAL_PED)
        end
    end)
end

WEAPONS = {
    Process = {
        Weapon = function(self, details)
            if currentWeaponActive._id ~= nil then
                if currentWeaponActive._id == details._id then
                    Weapons.UnEquip:Weapon(details, function(processed)
                        if processed then
                            Weapons.Process:SaveWeapon(currentWeaponActive, function(saved)
                                currentWeaponActive = {}
                            end)
                        end                    
                    end)
                else
                    Weapons.UnEquip:Weapon(details, function(processed)
                        if processed then
                            Weapons.Process:SaveWeapon(currentWeaponActive, function(saved)
                                currentWeaponActive = {}
                                Weapons.Equip:Weapon(details, function(done)
                                    if done then
                                        currentWeaponActive = details
                                        Weapons.Process:WeaponManagement()
                                    end
                                end)
                            end)
                        end                    
                    end)
                end
            else
                Weapons.Equip:Weapon(details, function(done)
                    if done then
                        currentWeaponActive = details
                        Weapons.Process:WeaponManagement()
                    end
                end)
                
            end
        end,
        WeaponManagement = function(self)
            Citizen.CreateThread(function()
                local removingWeapon = false
                while not currentWeaponActive._id do Wait(5) end
                while currentWeaponActive._id do
                    SetPedCanSwitchWeapon(GLOBAL_PED, false)
                    local currentAmmo = GetAmmoInPedWeapon(GLOBAL_PED, currentWeaponActive.hash)
                    if currentAmmo ~= currentWeaponActive.ammo then
                        currentWeaponActive.ammo = currentAmmo
                        if currentAmmo == 0 and currentWeaponActive.ammo == 0 and not removingWeapon then
                            removingWeapon = true
                            if HasPedGotWeapon(GLOBAL_PED, currentWeaponActive.hash, false) then
                                Weapons.Process:SaveWeapon(currentWeaponActive, function(saved)
                                    currentWeaponActive = {}
                                end)
                            end
                        end
                    end
                    Citizen.Wait(50)
                end
            end)

            Citizen.CreateThread(function()
                local processCasing = false
                while not currentWeaponActive._id do Wait(5) end
                while currentWeaponActive._id do
                    if not currentWeaponActive.config.dropsFragments then break; end
                    
                    if GLOBAL_PED and GLOBAL_PED then

                        if IsPedShooting(GLOBAL_PED) then
                            local pedZone = GetNameOfZone(GLOBAL_COORDS.x, GLOBAL_COORDS.y, GLOBAL_COORDS.z)
                            local casingFragmentLink = math.random(100000000,999999999)

                            -- Lets create a casing for this weapon being fired at the peds coords
                            local casingDetails = {
                                ['weapon'] = GetSelectedPedWeapon(GLOBAL_PED),
                                ['zone'] = pedZone,
                                ['link'] = casingFragmentLink,
                                ['weaponInfo'] = currentWeaponActive,
                                ['hitCoords'] = {['x'] = GLOBAL_COORDS.x, ['y'] = GLOBAL_COORDS.y, ['z'] = (GLOBAL_COORDS.z - 0.98) },
                                ['type'] = "casing",
                            }

                            TriggerServerEvent('Evidence:RegisterEvidence', casingDetails, pedZone)

                            local a = Raycast(150.0)

                            if a and a.HitPosition then
                                -- Lets create a fragment as this projectile has hit something
                                local projectileZone = GetNameOfZone(a.HitPosition.x, a.HitPosition.y, a.HitPosition.z)
                                local projectileDetails = {
                                    ['weapon'] = GetSelectedPedWeapon(GLOBAL_PED),
                                    ['zone'] = projectileZone,
                                    ['link'] = casingFragmentLink,
                                    ['weaponInfo'] = currentWeaponActive,
                                    ['hitCoords'] = {['x'] = a.HitPosition.x, ['y'] = a.HitPosition.y, ['z'] = a.HitPosition.z },
                                }
                                if IsEntityAVehicle(a.HitEntity) and math.random(100) > 34 then
                                    projectileDetails['type'] = "vehiclefragment"
                                    projectileDetails['vehicle'] = { ['color'] = {['r'] = r, ['g'] = g, ['b'] = b}, ['plate'] = GetVehicleNumberPlateText(a.HitEntity), ['class'] = GetVehicleClass(a.HitEntity) }
                                elseif IsEntityAPed(a.HitEntity) and IsPedAPlayer(a.HitEntity) and math.random(100) > 34 then
                                    projectileDetails['type'] = "dna"
                                    projectileDetails['player'] = {  }
                                elseif IsEntityAPed(a.HitEntity) and not IsPedAPlayer(a.HitEntity) and math.random(100) > 34 then
                                    projectileDetails['type'] = "loco"
                                    projectileDetails['loco'] = { }
                                elseif not IsEntityAPed(a.HitEntity) and not IsEntityAVehicle(a.HitEntity) and math.random(100) > 34 then
                                    projectileDetails['type'] = "bulletfragment"
                                    projectileDetails['bullet'] = {  }
                                end

                                TriggerServerEvent('Evidence:RegisterEvidence', projectileDetails, projectileZone)
                            end
                        end
                    end
                    Citizen.Wait(3)
                end
            end)

            Citizen.CreateThread(function()
                local processingDelete = false
                while not currentWeaponActive._id do Wait(5) end
                while not processingDelete and currentWeaponActive.config.deleteOnNilAmmo do
                    if not processingDelete then
                        local shooting = IsPedShooting(GLOBAL_PED)
                        if shooting then
                            processingDelete = true
                            Weapons.Process:DeleteWeapon(currentWeaponActive, function(saved)
                                Weapons.UnEquip:Weapon(currentWeaponActive, function(processed)
                                    if processed then
                                        currentWeaponActive = {}
                                    end                    
                                end)
                            end)
                        end
                    end
                    Citizen.Wait(5)
                end
            end)

            Citizen.CreateThread(function()
                while not currentWeaponActive._id do Wait(5) end
                while currentWeaponActive._id do
                    Citizen.Wait(10000)
                    if currentWeaponActive._id then
                        Weapons.Process:SaveWeapon(currentWeaponActive, function(saved)

                        end)
                    end
                end
            end)
        end,
        SaveWeapon = function(self, details, cb)
            Callbacks:ServerCallback('Weapons:Server:SaveWeapon', details, function(complete)
                cb(complete)
            end)            
        end,
        DeleteWeapon = function(self, details, cb)
            Callbacks:ServerCallback('Weapons:Server:DeleteWeapon', details, function(complete)
                cb(complete)
            end)  
        end,
    },
    Equip = {
        Weapon = function(self, det, cb)
            if det.config.doAnimation then
                if det.config.animation.intro.one then
                    loadAnimDict(det.config.animation.intro.one.dict)
                end
                if det.config.animation.intro.two then
                    loadAnimDict(det.config.animation.intro.two.dict)
                end
            end
            local disablefiring = true
            Citizen.CreateThread(function()
                Citizen.CreateThread(function()
                    while disablefiring do
                        DisablePlayerFiring(PlayerId(), true)
                        Citizen.Wait(1)
                    end
                end)
                GiveWeaponToPed(PlayerPedId(), det.hash, 0, false, true)
                SetPedAmmo(PlayerPedId(), det.hash, det.ammo)
                if det.config.doAnimation then
                    local charJob = _character.Job.job
                    if not (det.config.animation.noPDAnim and (charJob == 'police' or charJob == 'corrections') and _character.JobDuty) then
                        if det.config.animation.intro.one then
                            SetPedCurrentWeaponVisible(PlayerPedId(), 0, 0, 1, 1)
                            TaskPlayAnim(PlayerPedId(), det.config.animation.intro.one.dict, det.config.animation.intro.one.anim, (det.config.animation.intro.one.time+0.0), 1.0, -1, 50, 0, 0, 0, 0)
                            Citizen.Wait(1000)
                            SetPedCurrentWeaponVisible(PlayerPedId(), 1, 0, 1, 1)
                            Citizen.Wait((det.config.animation.intro.one.time * 1000) + (det.config.animation.intro.one.additionalWait and (det.config.animation.intro.one.additionalWait * 1000) or 0))
                            ClearPedTasks(PlayerPedId())
                        end 
                        if det.config.animation.intro.two then
                            TaskPlayAnim(PlayerPedId(), det.config.animation.intro.two.dict, det.config.animation.intro.two.anim, (det.config.animation.intro.two.time + 0.0), 2.0, -1, 48, 10, 0, 0, 0)
                            Citizen.Wait(det.config.animation.intro.two.time * 1000)
                            ClearPedTasks(PlayerPedId())
                        end
                    end
                end
                disablefiring = false
                DisablePlayerFiring(PlayerId(), false)
                cb(true)
            end)
        end,
        Ammo = function(self, det, cb)
            
        end,
    },
    UnEquip = {
        Weapon = function(self, det, cb)
            local disablefiring = true
            Citizen.CreateThread(function()
                while disablefiring do
                    DisablePlayerFiring(PlayerId(), true)
                    Citizen.Wait(1)
                end
            end)
            if det.config.doAnimation then
                if det.config.animation.outro.one then
                    loadAnimDict(det.config.animation.outro.one.dict)
                end
                if det.config.animation.outro.two then
                    loadAnimDict(det.config.animation.outro.two.dict)
                end
            end

            Citizen.CreateThread(function()
                if det.config.doAnimation then
                    local charJob = _character.Job.job
                    if not (det.config.animation.noPDAnim and (charJob == 'police' or charJob == 'corrections') and _character.JobDuty) then
                        if det.config.animation.outro.one then
                            TaskPlayAnim(PlayerPedId(), det.config.animation.outro.one.dict, det.config.animation.outro.one.anim, (det.config.animation.outro.one.time+0.0), 2.0, -1, 48, 10, 0, 0, 0)
                            Citizen.Wait((det.config.animation.outro.one.time * 1000) + (det.config.animation.outro.one.additionalWait and (det.config.animation.outro.one.additionalWait * 1000) or 0))
                            ClearPedTasks(PlayerPedId())
                        end
                        if det.config.animation.outro.two then
                            TaskPlayAnim(PlayerPedId(), det.config.animation.outro.two.dict, det.config.animation.outro.two.anim, (det.config.animation.outro.two.time+0.0), 2.0, -1, 50, 2.0, 0, 0, 0)
                            Citizen.Wait(det.config.animation.outro.one.time)
                            ClearPedTasks(PlayerPedId())
                        end
                    end
                end
                SetPedAmmo(PlayerPedId(), det.hash, 0)
                RemoveWeaponFromPed(PlayerPedId(), det.hash)
                disablefiring = false
                DisablePlayerFiring(PlayerId(), false)
                SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)
                cb(true)
            end)
        end,
        UnequipFromInventory = function(self, id)
            if currentWeaponActive and currentWeaponActive._id == id then   
                Weapons.UnEquip:Weapon(currentWeaponActive, function(done)
                    Weapons.Process:SaveWeapon(currentWeaponActive, function()
                        currentWeaponActive = {}
                    end)
                end)
            end
        end,
    }
}

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['bs_base']:RegisterComponent('Weapons', WEAPONS)
end)