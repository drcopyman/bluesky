AddEventHandler('Evidence:Shared:DependencyUpdate', RetrieveComponents)
    function RetrieveComponents()
        Database = exports['bs_base']:FetchComponent('Database')
        Callbacks = exports['bs_base']:FetchComponent('Callbacks')
        Logger = exports['bs_base']:FetchComponent('Logger')
        Utils = exports['bs_base']:FetchComponent('Utils')
        Inventory = exports['bs_base']:FetchComponent('Inventory')
        Items = exports['bs_base']:FetchComponent('Items')
        Chat = exports['bs_base']:FetchComponent('Chat')
        Execute = exports['bs_base']:FetchComponent('Execute')
        Evidence = exports['bs_base']:FetchComponent('Evidence')
    end
    
AddEventHandler('Core:Shared:Ready', function()
    exports['bs_base']:RequestDependencies('Evidence', {
        'Database',
        'Callbacks',
        'Logger',
        'Utils',
        'Inventory',
        'Items',
        'Chat',
        'Execute',
        'Evidence',
    }, function(error)
        if #error > 0 then return end 
        RetrieveComponents()
        RegisterCallbacks()
        Evidence.StartUp:Start()
    end)
end)

EVIDENCE = {
    StartUp = {
        Start = function(self)
            Citizen.CreateThread(function()
                while true do
                Citizen.Wait(1000)
                TriggerClientEvent('Evidence:Client:SendEvidence', -1, Evidence.Data.MainPool)
                end
            end)
        end,
    },
    Data = {
        MainPool = {
            ["AIRP"] = {},
            ["ALAMO"] = {},
            ["ALTA"] = {},
            ["ARMYB"] = {},
            ["BANHAMC"] = {},
            ["BANNING"] = {},
            ["BEACH"] = {},
            ["BHAMCA"] = {},
            ["BRADP"] = {},
            ["BRADT"] = {},
            ["BURTON"] = {},
            ["CALAFB"] = {},
            ["CANNY"] = {},
            ["CCREAK"] = {},
            ["CHAMH"] = {},
            ["CHIL"] = {},
            ["CHU"] = {},
            ["CMSW"] = {},
            ["CYPRE"] = {},
            ["DAVIS"] = {},
            ["DELBE"] = {},
            ["DELPE"] = {},
            ["DELSOL"] = {},
            ["DESRT"] = {},
            ["DOWNT"] = {},
            ["DTVINE"] = {},
            ["EAST_V"] = {},
            ["EBURO"] = {},
            ["ELGORL"] = {},
            ["ELYSIAN"] = {},
            ["GALFISH"] = {},
            ["GOLF"] = {},
            ["GRAPES"] = {},
            ["GREATC"] = {},
            ["HARMO"] = {},
            ["HAWICK"] = {},
            ["HORS"] = {},
            ["HUMLAB"] = {},
            ["JAIL"] = {},
            ["KOREAT"] = {},
            ["LACT"] = {},
            ["LAGO"] = {},
            ["LDAM"] = {},
            ["LEGSQU"] = {},
            ["LMESA"] = {},
            ["LOSPUER"] = {},
            ["MIRR"] = {},
            ["MORN"] = {},
            ["MOVIE"] = {},
            ["MTCHIL"] = {},
            ["MTGORDO"] = {},
            ["MTJOSE"] = {},
            ["MURRI"] = {},
            ["NCHU"] = {},
            ["NOOSE"] = {},
            ["OCEANA"] = {},
            ["PALCOV"] = {},
            ["PALETO"] = {},
            ["PALFOR"] = {},
            ["PALHIGH"] = {},
            ["PALMPOW"] = {},
            ["PBLUFF"] = {},
            ["PBOX"] = {},
            ["PROCOB"] = {},
            ["RANCHO"] = {},
            ["RGLEN"] = {},
            ["RICHM"] = {},
            ["ROCKF"] = {},
            ["RTRAK"] = {},
            ["SANAND"] = {},
            ["SANCHIA"] = {},
            ["SANDY"] = {},
            ["SKID"] = {},
            ["SLAB"] = {},
            ["STAD"] = {},
            ["STRAW"] = {},
            ["TATAMO"] = {},
            ["TERMINA"] = {},
            ["TEXTI"] = {},
            ["TONGVAH"] = {},
            ["TONGVAV"] = {},
            ["VCANA"] = {},
            ["VESP"] = {},
            ["VINE"] = {},
            ["WINDF"] = {},
            ["WVINE"] = {},
            ["ZANCUDO"] = {},
            ["ZP_ORT"] = {},
            ["ZQ_UAR"] = {}
        },
        Names = {
            ["AIRP"] = "Los Santos International Airport",
            ["ALAMO"] = "Alamo Sea",
            ["ALTA"] = "Alta",
            ["ARMYB"] = "Fort Zancudo",
            ["BANHAMC"] = "Banham Canyon Dr",
            ["BANNING"] = "Banning",
            ["BEACH"] = "Vespucci Beach",
            ["BHAMCA"] = "Banham Canyon",
            ["BRADP"] = "Braddock Pass",
            ["BRADT"] = "Braddock Tunnel",
            ["BURTON"] = "Burton",
            ["CALAFB"] = "Calafia Bridge",
            ["CANNY"] = "Raton Canyon",
            ["CCREAK"] = "Cassidy Creek",
            ["CHAMH"] = "Chamberlain Hills",
            ["CHIL"] = "Vinewood Hills",
            ["CHU ="] = "Chumash",
            ["CMSW"] = "Chiliad Mountain State Wilderness",
            ["CYPRE"] = "Cypress Flats",
            ["DAVIS"] = "Davis",
            ["DELBE"] = "Del Perro Beach",
            ["DELPE"] = "Del Perro",
            ["DELSOL"] = "La Puerta",
            ["DESRT"] = "Grand Senora Desert",
            ["DOWNT"] = "Downtown",
            ["DTVINE"] = "Downtown Vinewood",
            ["EAST_V"] = "East Vinewood",
            ["EBURO"] = "El Burro Heights",
            ["ELGORL"] = "El Gordo Lighthouse",
            ["ELYSIAN"] = "Elysian Island",
            ["GALFISH"] = "Galilee",
            ["GOLF"] = "GWC and Golfing Society",
            ["GRAPES"] = "Grapeseed",
            ["GREATC"] = "Great Chaparral",
            ["HARMO"] = "Harmony",
            ["HAWICK"] = "Hawick",
            ["HORS"] = "Vinewood Racetrack",
            ["HUMLAB"] = "Humane Labs and Research",
            ["JAIL"] = "Bolingbroke Penitentiary",
            ["KOREAT"] = "Little Seoul",
            ["LACT"] = "Land Act Reservoir",
            ["LAGO"] = "Lago Zancudo",
            ["LDAM"] = "Land Act Dam",
            ["LEGSQU"] = "Legion Square",
            ["LMESA"] = "La Mesa",
            ["LOSPUER"] = "La Puerta",
            ["MIRR"] = "Mirror Park",
            ["MORN"] = "Morningwood",
            ["MOVIE"] = "Richards Majestic",
            ["MTCHIL"] = "Mount Chiliad",
            ["MTGORDO"] = "Mount Gordo",
            ["MTJOSE"] = "Mount Josiah",
            ["MURRI"] = "Murrieta Heights",
            ["NCHU"] = "North Chumash",
            ["NOOSE"] = "N.O.O.S.E",
            ["OCEANA"] = "Pacific Ocean",
            ["PALCOV"] = "Paleto Cove",
            ["PALETO"] = "Paleto Bay",
            ["PALFOR"] = "Paleto Forest",
            ["PALHIGH"] = "Palomino Highlands",
            ["PALMPOW"] = "Palmer-Taylor Power Station",
            ["PBLUFF"] = "Pacific Bluffs",
            ["PBOX"] = "Pillbox Hill",
            ["PROCOB"] = "Procopio Beach",
            ["RANCHO"] = "Rancho",
            ["RGLEN"] = "Richman Glen",
            ["RICHM"] = "Richman",
            ["ROCKF"] = "Rockford Hills",
            ["RTRAK"] = "Redwood Lights Track",
            ["SANAND"] = "San Andreas",
            ["SANCHIA"] = "San Chianski Mountain Range",
            ["SANDY"] = "Sandy Shores",
            ["SKID"] = "Mission Row",
            ["SLAB"] = "Stab City",
            ["STAD"] = "Maze Bank Arena",
            ["STRAW"] = "Strawberry",
            ["TATAMO"] = "Tataviam Mountains",
            ["TERMINA"] = "Terminal",
            ["TEXTI"] = "Textile City",
            ["TONGVAH"] = "Tongva Hills",
            ["TONGVAV"] = "Tongva Valley",
            ["VCANA"] = "Vespucci Canals",
            ["VESP"] = "Vespucci",
            ["VINE"] = "Vinewood",
            ["WINDF"] = "Ron Alternates Wind Farm",
            ["WVINE"] = "West Vinewood",
            ["ZANCUDO"] = "Zancudo River",
            ["ZP_ORT"] = "Port of South Los Santos",
            ["ZQ_UAR"] = "Davis Quartz",
        }
    },
    Create = {
        DNA = function(self, zone, data)
            local addDNA = true
            
            if Evidence.Data.MainPool[zone]["dna"] == nil then
                Evidence.Data.MainPool[zone]["dna"] = {}
            end
            
            for k, v in pairs(Evidence.Data.MainPool[zone]["dna"]) do
                local distance = #(vector3(v.hitCoords.x, v.hitCoords.y, v.hitCoords.z) - vector3(data.hitCoords.x, data.hitCoords.y, data.hitCoords.z))
                if distance < 0.4 then
                    addDNA = false
                end
            end
            
            if addDNA then
                table.insert(Evidence.Data.MainPool[zone]["dna"], data)
            end
        end,
        Casing = function(self, zone, data)
            local addCasing = true
            
            if Evidence.Data.MainPool[zone]["casing"] == nil then
                Evidence.Data.MainPool[zone]["casing"] = {}
            end
            
            for k, v in pairs(Evidence.Data.MainPool[zone]["casing"]) do
                local distance = #(vector3(v.hitCoords.x, v.hitCoords.y, v.hitCoords.z) - vector3(data.hitCoords.x, data.hitCoords.y, data.hitCoords.z))
                if distance < 0.2 then
                    addCasing = false
                end
            end
            
            if addCasing then
                table.insert(Evidence.Data.MainPool[zone]["casing"], data)
            end
        end,
        BulletFragment = function(self, zone, data)
            local addBulletFragment = true
            
            if Evidence.Data.MainPool[zone]["bulletfragment"] == nil then
                Evidence.Data.MainPool[zone]["bulletfragment"] = {}
            end
            
            for k, v in pairs(Evidence.Data.MainPool[zone]["bulletfragment"]) do
                local distance = #(vector3(v.hitCoords.x, v.hitCoords.y, v.hitCoords.z) - vector3(data.hitCoords.x, data.hitCoords.y, data.hitCoords.z))
                if distance < 0.4 then
                    addBulletFragment = false
                end
            end
            
            if addBulletFragment then
                table.insert(Evidence.Data.MainPool[zone]["bulletfragment"], data)
            end
        end,
        VehicleFragment = function(self, zone, data)
            local addVehicleFragment = true
            
            if Evidence.Data.MainPool[zone]["vehiclefragment"] == nil then
                Evidence.Data.MainPool[zone]["vehiclefragment"] = {}
            end
            
            for k, v in pairs(Evidence.Data.MainPool[zone]["vehiclefragment"]) do
                local distance = #(vector3(v.hitCoords.x, v.hitCoords.y, v.hitCoords.z) - vector3(data.hitCoords.x, data.hitCoords.y, data.hitCoords.z))
                if distance < 0.4 then
                    addVehicleFragment = false
                end
            end
            
            if addVehicleFragment then
                table.insert(Evidence.Data.MainPool[zone]["vehiclefragment"], data)
            end
        end,
        Loco = function(self, zone, data)
            local addLoco = true
            
            if Evidence.Data.MainPool[zone]["loco"] == nil then
                Evidence.Data.MainPool[zone]["loco"] = {}
            end
            
            for k, v in pairs(Evidence.Data.MainPool[zone]["loco"]) do
                local distance = #(vector3(v.hitCoords.x, v.hitCoords.y, v.hitCoords.z) - vector3(data.hitCoords.x, data.hitCoords.y, data.hitCoords.z))
                if distance < 0.4 then
                    addLoco = false
                end
            end
            
            if addLoco then
                table.insert(Evidence.Data.MainPool[zone]["loco"], data)
            end
        end,
    },
    Delete = {

    }
}

RegisterServerEvent('Evidence:Server:PickupEvidence')
AddEventHandler('Evidence:Server:PickupEvidence', function(coords, zone, type, id)
    local char = exports['bs_base']:FetchComponent('Fetch'):Source(source):GetData('Character')
    local job, duty = char:GetData('Job').job, char:GetData('JobDuty')
    local currentEvidence = Evidence.Data.MainPool[zone][type][id]
    Evidence.Data.MainPool[zone][type][id] = nil

    if job == "police" and duty then
        Inventory:AddItem(char:GetData('ID'), "evidence-"..type, 1, currentEvidence, 1)
    else
        --CleanItem(coords, zone, type, id)
    end
end)

RegisterServerEvent('Evidence:RegisterEvidence')
AddEventHandler('Evidence:RegisterEvidence', function(data, zone)
    if data.type == "vehiclefragment" then
        Evidence.Create:VehicleFragment(zone, data)
    elseif data.type == "bulletfragment" then
        Evidence.Create:BulletFragment(zone, data)
    elseif data.type == "casing" then
        Evidence.Create:Casing(zone, data)
    elseif data.type == "dna" then
        Evidence.Create:DNA(zone, data)
    elseif data.type == "loco" then
        Evidence.Create:Loco(zone, data)        
    end
end)

function RegisterCallbacks()
    
    Callbacks:RegisterServerCallback('Evidence:Server:ReceivePools', function(source, data, cb)
        cb(Evidence.Data.MainPool)
    end)

end

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['bs_base']:RegisterComponent('Evidence', EVIDENCE)
end)