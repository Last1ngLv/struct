library WeaponInventorySystem initializer Init requires WeaponInventoryCore, LoadoutMissile, LoadoutMetalSlugSpecial, LoadoutRocketLauncher, LoadoutIronLizard, LoadoutThunderShot, RegisterPlayerUnitEvent

private function WeaponInventoryIsStraightProfile takes integer profileId returns boolean
    return profileId == WEAPON_PROFILE_HANDGUN or profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN or profileId == WEAPON_PROFILE_TWO_MACHINE_GUN or profileId == WEAPON_PROFILE_LASER_GUN
endfunction

function WeaponInventoryFireActive takes player p, real targetX, real targetY returns boolean
    local integer profileId = WeaponInventoryGetActiveProfile(p)
    local integer pid = GetPlayerId(p)
    local unit hero = PlayerHero[pid]
    local boolean ok = false

    if hero == null or GetUnitTypeId(hero) == 0 or not UnitAlive(hero) then
        set hero = null
        return false
    endif
    call WeaponInventoryEnsurePlayer(p)
    if not WeaponInventoryCanStartFire(p) then
        set hero = null
        return false
    endif

    if WeaponInventoryIsStraightProfile(profileId) then
        set ok = LoadoutMissileFireProfile(hero, p, profileId, targetX, targetY)
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        set ok = LoadoutRocketLauncherFire(hero, p, targetX, targetY)
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        set ok = LoadoutIronLizardFire(hero, p, targetX, targetY)
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        set ok = LoadoutThunderShotFire(hero, p, targetX, targetY)
    else
        set ok = LoadoutMetalSlugSpecialFireProfile(hero, p, profileId, targetX, targetY)
    endif

    set hero = null
    return ok
endfunction

private function OnFireEffect takes nothing returns nothing
    call WeaponInventoryFireActive(GetTriggerPlayer(), GetSpellTargetX(), GetSpellTargetY())
endfunction

private function OnAnySpellCast takes nothing returns nothing
    local integer abilityId = GetSpellAbilityId()
    if abilityId == WEAPON_INVENTORY_SELECT_SLOT_1_ABILITY then
        call WeaponInventorySetActiveSlot(GetTriggerPlayer(), WEAPON_INVENTORY_SLOT_1)
    elseif abilityId == WEAPON_INVENTORY_SELECT_SLOT_2_ABILITY then
        call WeaponInventorySetActiveSlot(GetTriggerPlayer(), WEAPON_INVENTORY_SLOT_2)
    endif
endfunction

private function Init takes nothing returns nothing
    call RegisterSpellEffectEvent(WEAPON_INVENTORY_FIRE_ABILITY, function OnFireEffect)
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_CAST, function OnAnySpellCast)
endfunction

endlibrary
