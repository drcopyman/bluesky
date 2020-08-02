Config = Config or {}

Config.Location = { x = 1690.91, y = 2534.29, z = 57.1 }
Config.BlipName = "Bolingbroke Penitentiary"
Config.BlipSprite = 238
Config.BlipColor = 1 
Config.BlipSize = 0.75

Config.ExitPoint = {
    ['itemRetreivalCoords'] = { 
        { ['x'] = 1832.12, ['y'] = 2584.64, ['z'] = 45.95 },
        { ['x'] = 1835.44, ['y'] = 2584.64, ['z'] = 45.95 },
    },
    ['releaseCoords'] = { ['x'] = 1792.73, ['y'] = 2593.95, ['z'] = 45.60},
    ['doorIdent'] = 1, -- any door id of the set
    ['penalty'] = math.random(0,3)
}