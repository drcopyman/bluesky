
AddEventHandler('Weapons:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports['bs_base']:FetchComponent('Callbacks')
    Database = exports['bs_base']:FetchComponent('Database')
    Fetch = exports['bs_base']:FetchComponent('Fetch')
    Weapons = exports['bs_base']:FetchComponent('Fetch')
    Inventory = exports['bs_base']:FetchComponent('Inventory')
    Utils = exports['bs_base']:FetchComponent('Utils')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['bs_base']:RequestDependencies('Weapons', {
        'Callbacks',
        'Database',
        'Fetch',
        'Weapons',
        'Inventory',
        'Utils',
    }, function(error)  
        if #error > 0 then return; end
        RetrieveComponents()
        registerUsables()
        registerCallbacks()
    end)
end)

function registerCallbacks()
    Callbacks:RegisterServerCallback('Weapons:Server:DeleteWeapon', function(source, data, cb)
        Database.Game:deleteOne({
            collection = 'inventory',
            query = {
                _id = data._id
            },
        }, function(success, result)
            cb(success)
        end)
    end)

    Callbacks:RegisterServerCallback('Weapons:Server:SaveWeapon', function(source, data, cb)
        Database.Game:updateOne({
            collection = 'inventory',
            query = {
                _id = data._id
            },
            update = {
                ['$set'] = {
                    MetaData = { ['SerialNumber'] = data.serial, ['ammo'] = data.ammo }
                }
            }
        }, function(success, result)
            cb(success)
        end)
    end)
end

WEAPONS = {

}

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['bs_base']:RegisterComponent('Weapons', WEAPONS)
end)