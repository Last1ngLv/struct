library WeaponProfileConfig

globals
    constant integer WEAPON_PROFILE_NONE = 0
    constant integer WEAPON_PROFILE_HANDGUN = 1
    constant integer WEAPON_PROFILE_PISTOL = 1
    constant integer WEAPON_PROFILE_SHOTGUN = 2
    constant integer WEAPON_PROFILE_HEAVY_MACHINE_GUN = 3
    constant integer WEAPON_PROFILE_ASSAULT_RIFLE = 3
    constant integer WEAPON_PROFILE_TWO_MACHINE_GUN = 4
    constant integer WEAPON_PROFILE_RIFLE = 4
    constant integer WEAPON_PROFILE_ROCKET_LAUNCHER = 5
    constant integer WEAPON_PROFILE_PLASMA_AOE = 5
    constant integer WEAPON_PROFILE_ENEMY_CHASER = 6
    constant integer WEAPON_PROFILE_TRACKING_MISSILE = 6
    constant integer WEAPON_PROFILE_GRENADE = 7
    constant integer WEAPON_PROFILE_LASER_GUN = 8
    constant integer WEAPON_PROFILE_DROP_SHOT = 9
    constant integer WEAPON_PROFILE_FLAME_SHOT = 10
    constant integer WEAPON_PROFILE_IRON_LIZARD = 11
    constant integer WEAPON_PROFILE_SUPER_GRENADE = 12
    constant integer WEAPON_PROFILE_THUNDER_SHOT = 13
    constant integer WEAPON_PROFILE_LAST = 13

    constant integer WEAPON_MODE_SINGLE = 1
    constant integer WEAPON_MODE_BURST = 2
    constant integer WEAPON_MODE_RAPID = 3
    constant integer WEAPON_MODE_AOE = 4
    constant integer WEAPON_MODE_HOMING = 5
    constant integer WEAPON_MODE_DOUBLE_RAPID = 6
    constant integer WEAPON_MODE_PIERCING_AOE = 7
    constant integer WEAPON_MODE_BOUNCE_AOE = 8
    constant integer WEAPON_MODE_CHAINING_HOMING = 9

    constant integer WEAPON_BEHAVIOR_STRAIGHT = 1
    constant integer WEAPON_BEHAVIOR_DOUBLE_STRAIGHT = 2
    constant integer WEAPON_BEHAVIOR_STRAIGHT_AOE = 3
    constant integer WEAPON_BEHAVIOR_HOMING = 4
    constant integer WEAPON_BEHAVIOR_PIERCING_AOE = 5
    constant integer WEAPON_BEHAVIOR_DROP_BOUNCE = 6
    constant integer WEAPON_BEHAVIOR_BILLIARD_BOUNCE = 7
    constant integer WEAPON_BEHAVIOR_CHAINING_HOMING = 8

    constant integer WEAPON_AMMO_INFINITE = -1
    constant integer WEAPON_INVENTORY_FIRE_ABILITY = 'U0AF'
    constant integer WEAPON_INVENTORY_SELECT_SLOT_1_ABILITY = 'U0C1'
    constant integer WEAPON_INVENTORY_SELECT_SLOT_2_ABILITY = 'U0C2'
    constant integer WEAPON_PRISONER_UNIT_TYPE = 'pRSN'
endglobals

function WeaponProfileIsWeapon takes integer profileId returns boolean
    return profileId >= WEAPON_PROFILE_HANDGUN and profileId <= WEAPON_PROFILE_LAST
endfunction

function WeaponProfileGetMode takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN or profileId == WEAPON_PROFILE_LASER_GUN then
        return WEAPON_MODE_RAPID
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return WEAPON_MODE_DOUBLE_RAPID
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER or profileId == WEAPON_PROFILE_GRENADE or profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return WEAPON_MODE_AOE
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return WEAPON_MODE_HOMING
    elseif profileId == WEAPON_PROFILE_SHOTGUN or profileId == WEAPON_PROFILE_FLAME_SHOT then
        return WEAPON_MODE_PIERCING_AOE
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return WEAPON_MODE_BOUNCE_AOE
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return WEAPON_MODE_BOUNCE_AOE
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return WEAPON_MODE_CHAINING_HOMING
    endif
    return WEAPON_MODE_SINGLE
endfunction

function WeaponProfileGetBehavior takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return WEAPON_BEHAVIOR_DOUBLE_STRAIGHT
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER or profileId == WEAPON_PROFILE_GRENADE or profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return WEAPON_BEHAVIOR_STRAIGHT_AOE
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return WEAPON_BEHAVIOR_HOMING
    elseif profileId == WEAPON_PROFILE_SHOTGUN or profileId == WEAPON_PROFILE_FLAME_SHOT then
        return WEAPON_BEHAVIOR_PIERCING_AOE
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return WEAPON_BEHAVIOR_DROP_BOUNCE
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return WEAPON_BEHAVIOR_BILLIARD_BOUNCE
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return WEAPON_BEHAVIOR_CHAINING_HOMING
    endif
    return WEAPON_BEHAVIOR_STRAIGHT
endfunction

function WeaponProfileGetSelectorAbility takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_HANDGUN then
        return 'U0B1'
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 'U0B2'
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 'U0B3'
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 'U0B4'
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 'U0B5'
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return 'U0B6'
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return 'U0B7'
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return 'U0B8'
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 'U0B9'
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 'U0BA'
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return 'U0BB'
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 'U0BC'
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 'U0BD'
    endif
    return 0
endfunction

function WeaponProfileGetFireAbility takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_HANDGUN then
        return 'U0A1'
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 'U0A3'
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 'U0A4'
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 'U0A5'
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 'U0A6'
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return 'U0A7'
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return 'U0A8'
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return 'U0A9'
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 'U0AA'
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 'U0AB'
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return 'U0AC'
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 'U0AD'
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 'U0AE'
    endif
    return 0
endfunction

function WeaponProfileFromSelectorAbility takes integer abilityId returns integer
    local integer profileId = WEAPON_PROFILE_HANDGUN
    loop
        exitwhen profileId > WEAPON_PROFILE_LAST
        if abilityId == WeaponProfileGetSelectorAbility(profileId) then
            return profileId
        endif
        set profileId = profileId + 1
    endloop
    return WEAPON_PROFILE_NONE
endfunction

function WeaponProfileFromFireAbility takes integer abilityId returns integer
    local integer profileId = WEAPON_PROFILE_HANDGUN
    loop
        exitwhen profileId > WEAPON_PROFILE_LAST
        if abilityId == WeaponProfileGetFireAbility(profileId) then
            return profileId
        endif
        set profileId = profileId + 1
    endloop
    return WEAPON_PROFILE_NONE
endfunction

function WeaponProfileGetTexture takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_HANDGUN then
        return 'MA01'
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 'MA02'
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return 'MA03'
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 'MA04'
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 'MA06'
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 'MA05'
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 'MA07'
    endif
    return 'MA01'
endfunction

function WeaponProfileGetName takes integer profileId returns string
    if profileId == WEAPON_PROFILE_HANDGUN then
        return "Handgun"
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return "Shotgun"
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return "Heavy Machine Gun"
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return "Two Machine Gun"
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return "Rocket Launcher"
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return "Enemy Chaser"
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return "Grenade"
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return "Laser Gun"
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return "Drop Shot"
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return "Flame Shot"
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return "Iron Lizard"
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return "Super Grenade"
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return "Thunder Shot"
    endif
    return "Arma"
endfunction

function WeaponProfileGetRole takes integer profileId returns string
    if profileId == WEAPON_PROFILE_HANDGUN then
        return "Arma base"
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return "Blast frontal"
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return "DPS sostenido"
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return "Doble cadencia"
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return "Cohete explosivo"
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return "Misil guiado"
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return "Granada"
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return "Laser rapido"
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return "Rebote explosivo"
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return "Llama perforante"
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return "Disparo rasante"
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return "Granada pesada"
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return "Rayo encadenado"
    endif
    return "Arma"
endfunction

function WeaponProfileGetDamage takes integer profileId returns real
    if profileId == WEAPON_PROFILE_HANDGUN then
        return 1.00
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 3.00
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return 0.50
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 0.75
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 2.00
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 2.50
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return 5.00
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return 1.00
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 2.50
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 2.00
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return 2.75
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 3.50
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 1.50
    endif
    return 1.00
endfunction

function WeaponProfileGetCastDuration takes integer profileId returns real
    return 1.00
endfunction

function WeaponProfileGetCastCount takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_HANDGUN then
        return 6
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 6
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return 12
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 12
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 6
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 6
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return 6
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return 12
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 6
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 6
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return 6
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 6
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 6
    endif
    return 1
endfunction

function WeaponProfileGetShotsPerSecond takes integer profileId returns integer
    return WeaponProfileGetCastCount(profileId)
endfunction

function WeaponProfileGetInterval takes integer profileId returns real
    return WeaponProfileGetCastDuration(profileId) / I2R(WeaponProfileGetCastCount(profileId))
endfunction

function WeaponProfileGetRange takes integer profileId returns real
    if profileId == WEAPON_PROFILE_SHOTGUN then
        return 1250.00
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 1750.00
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 1750.00
    elseif profileId == WEAPON_PROFILE_GRENADE or profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 1250.00
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return 1750.00
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 1750.00
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 1750.00
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return 3000.00
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 2000.00
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return 1750.00
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 1750.00
    endif
    return 1750.00
endfunction

function WeaponProfileGetProjectileCount takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 2
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 15
    endif
    return 1
endfunction

function WeaponProfileGetArea takes integer profileId returns real
    if profileId == WEAPON_PROFILE_SHOTGUN then
        return 250.00
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 250.00
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 250.00
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return 300.00
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 300.00
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 250.00
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 350.00
    endif
    return 0.00
endfunction

function WeaponProfileGetCost takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_HANDGUN then
        return 0
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 2
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return 2
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 3
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 3
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 4
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return 2
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return 4
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 4
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 4
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return 3
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 5
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 5
    endif
    return 1
endfunction

function WeaponProfileGetDefaultAmmo takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_HANDGUN then
        return WEAPON_AMMO_INFINITE
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN or profileId == WEAPON_PROFILE_TWO_MACHINE_GUN or profileId == WEAPON_PROFILE_LASER_GUN then
        return 200
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return 50
    elseif profileId == WEAPON_PROFILE_SHOTGUN or profileId == WEAPON_PROFILE_ROCKET_LAUNCHER or profileId == WEAPON_PROFILE_ENEMY_CHASER or profileId == WEAPON_PROFILE_DROP_SHOT or profileId == WEAPON_PROFILE_FLAME_SHOT or profileId == WEAPON_PROFILE_IRON_LIZARD or profileId == WEAPON_PROFILE_SUPER_GRENADE or profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 100
    endif
    return 0
endfunction

function WeaponProfileGetPickupUnitType takes integer profileId returns integer
    if profileId == WEAPON_PROFILE_HANDGUN then
        return 'wP01'
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 'wP02'
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return 'wP03'
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return 'wP04'
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 'wP05'
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 'wP06'
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return 'wP07'
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return 'wP08'
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 'wP09'
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 'wP0A'
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return 'wP0B'
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 'wP0C'
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 'wP0D'
    endif
    return 0
endfunction

function WeaponProfileFromPickupUnitType takes integer unitTypeId returns integer
    local integer profileId = WEAPON_PROFILE_HANDGUN
    loop
        exitwhen profileId > WEAPON_PROFILE_LAST
        if unitTypeId == WeaponProfileGetPickupUnitType(profileId) then
            return profileId
        endif
        set profileId = profileId + 1
    endloop
    return WEAPON_PROFILE_NONE
endfunction

function WeaponProfileGetMissileModel takes integer profileId returns string
    if profileId == WEAPON_PROFILE_HANDGUN then
        return "Miss\\Shot Blue.mdx"
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN or profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return "Miss\\Shot II Blue.mdx"
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return "Miss\\Runic Rocket.mdx"
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return "Miss\\Valiant Charge Royal.mdx"
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return "Miss\\Voyager Rocket.mdx"
    elseif profileId == WEAPON_PROFILE_GRENADE or profileId == WEAPON_PROFILE_DROP_SHOT or profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return "Miss\\Chain Grenade Blue.mdx"
    elseif profileId == WEAPON_PROFILE_LASER_GUN or profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return "Psionic Shot Blue.mdx"
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return "Miss\\Fireball Major.mdx"
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return "Miss\\Arcade Bolt Blues.mdx"
    endif
    return "Miss\\Shot Blue.mdx"
endfunction

function WeaponProfileGetTierMissileModel takes integer profileId, integer tier returns string
    // Tier hook: por ahora todos empiezan en Blue. Luego se cambian aca
    // por Purple/Red/Yellow/Green/Orange sin tocar los loadouts.
    return WeaponProfileGetMissileModel(profileId)
endfunction

function WeaponProfileGetMissileScale takes integer profileId returns real
    if profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return 2.00
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 2.00
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 2.00
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return 1.25
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 2.00
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 1.15
    endif
    return 1.00
endfunction

function WeaponProfileGetMissileSpeed takes integer profileId returns real
    if profileId == WEAPON_PROFILE_LASER_GUN then
        return 15500.00
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return 6500.00
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return 2300.00
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 900.00
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return 2000.00
    elseif profileId == WEAPON_PROFILE_GRENADE or profileId == WEAPON_PROFILE_DROP_SHOT or profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return 1500.00
    endif
    return 2700.00
endfunction

function WeaponProfileGetAcceleration takes integer profileId returns real
    if profileId == WEAPON_PROFILE_FLAME_SHOT then
        return 90.00
    endif
    return 0.00
endfunction

function WeaponProfileGetDescription takes integer profileId returns string
    if profileId == WEAPON_PROFILE_HANDGUN then
        return "Disparo normal siempre disponible.\nBase segura aunque mueras."
    elseif profileId == WEAPON_PROFILE_SHOTGUN then
        return "Blast grande y rapido.\nAtraviesa enemigos y daÃ±a\nen area durante el camino."
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return "Cadencia alta y estable.\nMuy buena con efectos por impacto."
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return "Dos lineas de disparo.\n8 ciclos por segundo, 16 balas reales."
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return "Cohete recto explosivo.\nBuen area y presion frontal."
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return "Misil guiado que busca enemigos.\nConsistente contra objetivos moviles."
    elseif profileId == WEAPON_PROFILE_GRENADE then
        return "Granadas explosivas.\nArea confiable a media distancia."
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return "Laser de maxima cadencia.\n10 disparos por segundo y alta velocidad."
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return "Rebota continuamente.\nHace area en cada rebote hasta chocar."
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return "Llama corta y perforante.\nLenta al inicio, acelera rapido."
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return "Proyectil rasante de presion.\nFuerte para lineas frontales."
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return "Granada pesada recta.\nGran escala y gran area."
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return "Rayo veloz en onda sin objetivo.\nBusca enemigos cercanos hasta 15 impactos."
    endif
    return "Selecciona un arma para ver sus datos."
endfunction

function WeaponProfileGetDetailText takes integer profileId returns string
    local string projectileText = I2S(WeaponProfileGetProjectileCount(profileId))
    if profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        set projectileText = "2 por ciclo"
    endif

    if WeaponProfileGetArea(profileId) > 0.00 then
        return "|cff99ccffTipo: " + WeaponProfileGetRole(profileId) + "|r\nDano: |cffffcc00" + R2S(WeaponProfileGetDamage(profileId)) + "|r\nDisparos/s: |cffffcc00" + I2S(WeaponProfileGetShotsPerSecond(profileId)) + "|r\nRango: |cffffcc00" + I2S(R2I(WeaponProfileGetRange(profileId))) + "|r\nArea: |cffffcc00" + I2S(R2I(WeaponProfileGetArea(profileId))) + "|r\nProyectiles: |cffffcc00" + projectileText + "|r\nCosto: |cffffcc00" + I2S(WeaponProfileGetCost(profileId)) + " oro|r\n\n" + WeaponProfileGetDescription(profileId)
    endif

    return "|cff99ccffTipo: " + WeaponProfileGetRole(profileId) + "|r\nDano: |cffffcc00" + R2S(WeaponProfileGetDamage(profileId)) + "|r\nDisparos/s: |cffffcc00" + I2S(WeaponProfileGetShotsPerSecond(profileId)) + "|r\nRango: |cffffcc00" + I2S(R2I(WeaponProfileGetRange(profileId))) + "|r\nProyectiles: |cffffcc00" + projectileText + "|r\nCosto: |cffffcc00" + I2S(WeaponProfileGetCost(profileId)) + " oro|r\n\n" + WeaponProfileGetDescription(profileId)
endfunction

endlibrary
