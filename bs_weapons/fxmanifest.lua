fx_version 'bodacious'
games {'gta5'} -- 'gta5' for GTAv / 'rdr3' for Red Dead 2, 'gta5','rdr3' for both

description 'Blue Sky Weapons'
name 'Blue Sky: [bs_weapons]'
author '[Chris Rogers]'
version 'v1.0.0'
url 'https://www.blueskyrp.com'

server_scripts {
    'config/main.lua',
    'server/registerUsable.lua',
    'server/main.lua',
}

client_scripts {
    'config/main.lua',
    'client/main.lua',
}