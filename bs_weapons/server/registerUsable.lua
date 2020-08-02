function registerUsables()
    Database.Game:find({
        collection = 'items',
        query = {
            type = 2
        }
    }, function(success, results)
        if not success then return; end
        for k, v in pairs(results) do
            Inventory.Items:RegisterUse(v.name, 'Weapons', function(source, item)
                local player = Fetch:Source(source)
                local char = player:GetData('Character')
                TriggerClientEvent('Weapons:Client:EquipWeapon', source, item, v.doAnimation)
            end)
        end
    end)
end