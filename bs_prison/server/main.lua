local inPrison = {}

AddEventHandler('Prison:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Database = exports['bs_base']:FetchComponent('Database')
    Middleware = exports['bs_base']:FetchComponent('Middleware')
    Callbacks = exports['bs_base']:FetchComponent('Callbacks')
    Logger = exports['bs_base']:FetchComponent('Logger')
    Utils = exports['bs_base']:FetchComponent('Utils')
    Fetch = exports['bs_base']:FetchComponent('Fetch')
    Chat = exports['bs_base']:FetchComponent('Chat')
    Jobs = exports['bs_base']:FetchComponent('Jobs')
    Police = exports['bs_base']:FetchComponent('Police')
    Inventory = exports['bs_base']:FetchComponent('Inventory')
    Prison = exports['bs_base']:FetchComponent('Prison')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['bs_base']:RequestDependencies('Prison', {
        'Database',
        'Middleware',
        'Callbacks',
        'Logger',
        'Utils',
        'Fetch',
        'Chat',
        'Jobs',
        'Police',
        'Inventory',
        'Prison',
    }, function(error)
        if #error > 0 then return end -- Do something to handle if not all dependencies loaded
        RetrieveComponents()
        RegisterCallbacks()
        processInmateTimes()
        RegisterMiddleware()
    end)
end)

function RegisterMiddleware()
    Middleware:Add('Characters:Logout', function(source)
        for k, v in pairs(Config.EntryCell) do
            if v.allocated and v.allocator == source then
                v.allocated = false
                v.allocator = 0
                for k, v in pairs(inPrison) do
                    if v.source == source then
                        inPrison[k] = nil
                        success = true
                        break;
                    end
                end
                break;
            end
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        Utils:Print(inPrison)
    end
end)

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['bs_base']:RegisterComponent('Prison', PRISON)
end)

RegisterServerEvent('Prison:Server:ReduceTimeWork')
AddEventHandler('Prison:Server:ReduceTimeWork', function()
    local _src = source
    if _src then
        local randomReduction = math.random(1,2)
        for k, v in pairs(inPrison) do
            if v.source == source then
                if v.time > 2 then
                    v.time = (v.time - randomReduction)
                    v.reduceIn = 60
                    if v.time < 0 then
                        v.time = 0
                    end
                    local char = Fetch:Source(v.source):GetData('Character')
                    char:SetData('Prison', tonumber(v.time))
                    TriggerClientEvent('Prisons:Client:UpdatePrisonTimer', tonumber(v.source), "updateTime", "Your sentence has been reduced by "..randomReduction.." months.")
                    if v.time == 0 then
                        -- eligable for release
                        TriggerClientEvent('Prisons:Client:UpdatePrisonTimer', tonumber(v.source), "updateTime", "You are elibable for release.")
                        TriggerClientEvent('Prisons:Client:ReleaseEligability', tonumber(v.source), true)
                        inPrison[k] = nil
                    else
                        TriggerClientEvent('Prisons:Client:UpdatePrisonTimer', tonumber(v.source), "updateTime", v.time, true)
                        TriggerClientEvent('Prisons:Client:ReleaseEligability', tonumber(v.source), false)
                    end
                end
            end
        end
    end
end)

function processInmateTimes()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10000)
            for k, v in pairs(inPrison) do
                if v.reduceIn > 0 then
                    v.reduceIn = (v.reduceIn - 10)
                end
            end
        end
    end)
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000)
            for k, v in pairs(inPrison) do
                if v.time > 0 and v.reduceIn <= 0 then
                    -- reduction in time by 1 minute (1 month) and reset timer to 60 seconds to not skip minutes
                    v.time = (v.time - 1)
                    v.reduceIn = 60
                    if v.time < 0 then
                        v.time = 0
                    end
                    local char = Fetch:Source(v.source):GetData('Character')
                    char:SetData('Prison', tonumber(v.time))
                    if v.time == 0 then
                        -- eligable for release
                        TriggerClientEvent('Prisons:Client:UpdatePrisonTimer', tonumber(v.source), "updateTime", "You are elibable for release.")
                        TriggerClientEvent('Prisons:Client:ReleaseEligability', tonumber(v.source), true)
                        inPrison[k] = nil
                    else    
                        TriggerClientEvent('Prisons:Client:UpdatePrisonTimer', tonumber(v.source), "updateTime", v.time, false)
                        TriggerClientEvent('Prisons:Client:ReleaseEligability', tonumber(v.source), false)
                    end
                end
            end
        end
    end)
end

function RegisterCallbacks()
    Callbacks:RegisterServerCallback('Prisons:Server:AllocateCell', function(source, data, cb)
        local success = false
        local char = Fetch:Source(source):GetData('Character')
        for k, v in pairs(Config.EntryCell) do
            if v.allocated == false and v.allocator == 0 then
                v.allocated = true
                v.allocator = source
                table.insert(inPrison, { ['source'] = source, ['cell'] = v, ['time'] = tonumber(data.time), ['reduceIn'] = 60 })
                char:SetData('Prison', tonumber(data.time))
                success = true
                TriggerClientEvent('Prisons:Client:UpdatePrisonTimer', tonumber(v.allocator), "updateTime", tonumber(data.time), false)
                cb(v)
                break;
            end
        end

        if not success then
            cb(success)
        end
    end)
    Callbacks:RegisterServerCallback('Prisons:Server:ReleaseInmate', function(source, data, cb)
        local success = false
        for k, v in pairs(Config.EntryCell) do
            if v.allocated and v.allocator == source then
                v.allocated = false
                v.allocator = 0
                for k, v in pairs(inPrison) do
                    if v.source == source then
                        inPrison[k] = nil
                        success = true
                        break;
                    end
                end
                break;
            end
        end
        
        cb(success)
    end)
end

PRISON = {
    GetInmates = function(self, cb)
        if cb then
            cb(inPrison)
        else
            return inPrison
        end
    end,
}