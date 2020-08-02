local inCustody = {}

AddEventHandler('Police:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Database = exports['bs_base']:FetchComponent('Database')
    Callbacks = exports['bs_base']:FetchComponent('Callbacks')
    Logger = exports['bs_base']:FetchComponent('Logger')
    Utils = exports['bs_base']:FetchComponent('Utils')
    Fetch = exports['bs_base']:FetchComponent('Fetch')
    Chat = exports['bs_base']:FetchComponent('Chat')
    Jobs = exports['bs_base']:FetchComponent('Jobs')
    Police = exports['bs_base']:FetchComponent('Police')
    Inventory = exports['bs_base']:FetchComponent('Inventory')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['bs_base']:RequestDependencies('Police', {
        'Database',
        'Callbacks',
        'Logger',
        'Utils',
        'Fetch',
        'Chat',
        'Jobs',
        'Police',
        'Inventory',
    }, function(error)
        if #error > 0 then return end -- Do something to handle if not all dependencies loaded
        RetrieveComponents()
        RegisterCallbacks()
        RegisterChatCommands()
        Database.Game:delete({
            collection = 'inventory',
            query = {
                invType = 9
            }
        }, function(success, done)
            if not success then return end
            if done > 0 then
                Logger:Log('Police', 'Deleted '..done..' items from the Police Trash Inventorys')
            end
        end)
    end)
end)

RegisterServerEvent('Police:Server:openEvidence')
AddEventHandler('Police:Server:openEvidence', function(etype, caseId)
    local _src = source
    if etype == "evidenceStorage" then
        if caseId and tonumber(caseId) > 9999 then
            Inventory:OpenSecondary(_src, 8, caseId)
        end
    else
        Inventory:OpenSecondary(_src, 9, caseId)
    end
end)

function RegisterCallbacks()
    Callbacks:RegisterServerCallback('Police:Server:GetOnDuty', function(source, data, cb)
        Police:GetOnDuty(function(total)
            cb(total)
        end)
    end)
    Callbacks:RegisterServerCallback('Police:Server:GetPolice', function(source, data, cb)
        Police:GetPolice(function(total)
            cb(total)
        end)
    end)
    Callbacks:RegisterServerCallback('Police:Server:GetDutyCount', function(source, data, cb)
        Police:GetDutyCount(function(total)
            cb(total)
        end)
    end)
end

POLICE = {
    GetInCustody = function(self, source, cb)
        if inCustody[source] then
            if cb then
                cb(inCustody[source])
            else
                return inCustody[source]
            end
        else
            if cb then
                cb(false)
            else
                return false
            end
        end
    end,
    GetPolice = function(self, cb)
        if not cb then
            return Jobs:GetFromJob('police')
        else
            cb(Jobs:GetFromJob('police'))
        end
    end,
    GetOnDuty = function(self, cb)
        if not cb then
            return Jobs:GetOnDuty('police')
        else
            cb(Jobs:GetOnDuty('police'))
        end
    end,
    GetDutyCount = function(self, cb)
        if not cb then
            return Job:GetOnDutyCount('police')
        else
            cb(Job:GetOnDutyCount('police'))
        end
    end,
}

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['bs_base']:RegisterComponent('Police', POLICE)
end)

function RegisterChatCommands()
    Chat:RegisterCommand('jail', function(source, args, rawCommand)
        local char = Fetch:Source(source):GetData('Character')
        local job = char:GetData('Job').job
        if (job == "police" or job == "judge") and char:GetData('JobDuty') then
            TriggerClientEvent('Police:Clien:JailPlayer', tonumber(args[1]), tonumber(args[2]))
        end
    end, {
        help = 'Jail a Civilian',
        params = {
            {
                name = 'ID', 
                help = 'Server ID' 
            },
            {
                name = 'Time',
                help = 'Time in Months to Serve'
            },
    }
    }, 2, { { name = "police", gradelevel = 1 } })
end