library WeaponInventoryCore initializer Init requires WeaponProfileConfig, PlayerHeroState, PlayerMissileLoadout, TimerUtils

globals
    constant integer WEAPON_INVENTORY_SLOT_1 = 1
    constant integer WEAPON_INVENTORY_SLOT_2 = 2
    private constant integer WEAPON_INVENTORY_SLOT_COUNT = 2
    private constant integer WEAPON_INVENTORY_SLOT_STRIDE = 3

    private integer array WeaponInventorySlotProfile
    private integer array WeaponInventorySlotAmmo
    private integer array WeaponInventoryActiveSlot
    private integer array WeaponInventoryHudVersion
    private sound array WeaponInventorySoundA
    private sound array WeaponInventorySoundB
    private sound WeaponInventoryReloadSound = null
    private timer array WeaponInventorySoundTimer
    private integer array WeaponInventoryPendingSoundProfile
endglobals

private function WeaponInventoryKey takes integer pid, integer slot returns integer
    return pid*WEAPON_INVENTORY_SLOT_STRIDE + slot
endfunction

private function WeaponInventoryValidPid takes integer pid returns boolean
    return pid >= 0 and pid < bj_MAX_PLAYER_SLOTS
endfunction

private function WeaponInventoryValidSlot takes integer slot returns boolean
    return slot == WEAPON_INVENTORY_SLOT_1 or slot == WEAPON_INVENTORY_SLOT_2
endfunction

private function WeaponInventoryValidHero takes unit hero returns boolean
    return hero != null and GetUnitTypeId(hero) != 0
endfunction

private function WeaponInventoryMarkDirtyByPid takes integer pid returns nothing
    if WeaponInventoryValidPid(pid) then
        set WeaponInventoryHudVersion[pid] = WeaponInventoryHudVersion[pid] + 1
    endif
endfunction

private function WeaponInventoryRemoveLegacyAbilities takes unit hero returns nothing
    local integer profileId = WEAPON_PROFILE_HANDGUN
    loop
        exitwhen profileId > WEAPON_PROFILE_LAST
        call UnitRemoveAbility(hero, WeaponProfileGetSelectorAbility(profileId))
        call UnitRemoveAbility(hero, WeaponProfileGetFireAbility(profileId))
        set profileId = profileId + 1
    endloop
endfunction

private function WeaponInventoryApplyProfileStats takes player p, integer profileId returns nothing
    call SetPlayerMissileDamageValue(p, WeaponProfileGetDamage(profileId))
    call SetPlayerMissileSpeedBonus(p, 0.00)
    call SetPlayerMissileModelPath(p, WeaponProfileGetTierMissileModel(profileId, 1))
    call SetPlayerMissileOverlayModelPath(p, "")
    call SetPlayerMissileInstanceCount(p, 1)
    call SetPlayerMissileUseRapidFireMissile(p, true)
    call SetPlayerMissileUseRapidFireControl(p, false)
endfunction

private function WeaponInventoryGetSoundPathA takes integer profileId returns string
    if profileId == WEAPON_PROFILE_SHOTGUN then
        return "war3mapImported\\MSX_Shotgun.wav"
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return "war3mapImported\\MSX_Heavy_Machinegun.wav"
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return "war3mapImported\\MS4_Two_Machinegun.wav"
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return "war3mapImported\\MSX_Rocket_Launcher.wav"
    elseif profileId == WEAPON_PROFILE_ENEMY_CHASER then
        return "war3mapImported\\MSX_Enemy_Chaser.wav"
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return "war3mapImported\\MSX_Laser_Gun.wav"
    elseif profileId == WEAPON_PROFILE_DROP_SHOT then
        return "war3mapImported\\MSX_Drop_Shot.wav"
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return "war3mapImported\\MSX_Flame_Shot.wav"
    elseif profileId == WEAPON_PROFILE_IRON_LIZARD then
        return "war3mapImported\\MSX_Iron_Lizard.wav"
    elseif profileId == WEAPON_PROFILE_SUPER_GRENADE then
        return "war3mapImported\\MSX_Super_Grenade.wav"
    elseif profileId == WEAPON_PROFILE_THUNDER_SHOT then
        return "war3mapImported\\MS7_Thunder_Shot.wav"
    endif
    return ""
endfunction

private function WeaponInventoryGetSoundPathB takes integer profileId returns string
    if profileId == WEAPON_PROFILE_SHOTGUN then
        return "war3mapImported\\MS_Shotgun.wav"
    elseif profileId == WEAPON_PROFILE_HEAVY_MACHINE_GUN then
        return "war3mapImported\\MS_Heavy_Machinegun.wav"
    elseif profileId == WEAPON_PROFILE_TWO_MACHINE_GUN then
        return "war3mapImported\\MS5_Two_Machinegun.wav"
    elseif profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
        return "war3mapImported\\MS_Rocket_Launcher.wav"
    elseif profileId == WEAPON_PROFILE_LASER_GUN then
        return "war3mapImported\\MS2_Laser.wav"
    elseif profileId == WEAPON_PROFILE_FLAME_SHOT then
        return "war3mapImported\\MS_Flame_Shot.wav"
    endif
    return ""
endfunction

private function WeaponInventoryCreateSound takes string path returns sound
    local sound s
    if path == "" then
        return null
    endif
    call Preload(path)
    set s = CreateSound(path, false, false, false, 12700, 12700, "")
    call SetSoundVolume(s, 127)
    return s
endfunction

private function WeaponInventoryPlayLocalSound takes player p, sound s returns nothing
    if s != null and GetLocalPlayer() == p then
        call StartSound(s)
    endif
endfunction

private function WeaponInventoryPlayWeaponSoundNow takes player p, integer profileId returns nothing
    local sound s
    if profileId == WEAPON_PROFILE_HANDGUN or not WeaponProfileIsWeapon(profileId) then
        return
    endif
    set s = WeaponInventorySoundA[profileId]
    if WeaponInventorySoundB[profileId] != null and GetRandomInt(0, 1) == 1 then
        set s = WeaponInventorySoundB[profileId]
    endif
    call WeaponInventoryPlayLocalSound(p, s)
    set s = null
endfunction

private function WeaponInventoryPlayPendingWeaponSound takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local integer profileId = WeaponInventoryPendingSoundProfile[pid]
    set WeaponInventorySoundTimer[pid] = null
    set WeaponInventoryPendingSoundProfile[pid] = WEAPON_PROFILE_NONE
    call WeaponInventoryPlayWeaponSoundNow(Player(pid), profileId)
    call ReleaseTimer(t)
    set t = null
endfunction

private function WeaponInventoryQueueWeaponSound takes player p, integer profileId returns nothing
    local integer pid = GetPlayerId(p)
    if not WeaponInventoryValidPid(pid) or profileId == WEAPON_PROFILE_HANDGUN or not WeaponProfileIsWeapon(profileId) then
        return
    endif
    set WeaponInventoryPendingSoundProfile[pid] = profileId
    if WeaponInventorySoundTimer[pid] != null then
        return
    endif
    call WeaponInventoryPlayLocalSound(p, WeaponInventoryReloadSound)
    set WeaponInventorySoundTimer[pid] = NewTimerEx(pid)
    call SetTimerDebugTag(WeaponInventorySoundTimer[pid], TIMER_DEBUG_TAG_OTHER)
    call TimerStart(WeaponInventorySoundTimer[pid], 0.50, false, function WeaponInventoryPlayPendingWeaponSound)
endfunction

private function WeaponInventoryInitSounds takes nothing returns nothing
    local integer profileId = WEAPON_PROFILE_HANDGUN
    set WeaponInventoryReloadSound = WeaponInventoryCreateSound("war3mapImported\\reloadweapon.wav")
    loop
        exitwhen profileId > WEAPON_PROFILE_LAST
        set WeaponInventorySoundA[profileId] = WeaponInventoryCreateSound(WeaponInventoryGetSoundPathA(profileId))
        set WeaponInventorySoundB[profileId] = WeaponInventoryCreateSound(WeaponInventoryGetSoundPathB(profileId))
        set profileId = profileId + 1
    endloop
endfunction

function WeaponInventoryGetHudVersion takes player p returns integer
    return WeaponInventoryHudVersion[GetPlayerId(p)]
endfunction

function WeaponInventoryGetSlotProfile takes player p, integer slot returns integer
    local integer pid = GetPlayerId(p)
    local integer profileId
    if not WeaponInventoryValidPid(pid) or not WeaponInventoryValidSlot(slot) then
        return WEAPON_PROFILE_HANDGUN
    endif
    set profileId = WeaponInventorySlotProfile[WeaponInventoryKey(pid, slot)]
    if not WeaponProfileIsWeapon(profileId) then
        return WEAPON_PROFILE_HANDGUN
    endif
    return profileId
endfunction

function WeaponInventoryGetSlotAmmo takes player p, integer slot returns integer
    local integer pid = GetPlayerId(p)
    local integer profileId = WeaponInventoryGetSlotProfile(p, slot)
    if profileId == WEAPON_PROFILE_HANDGUN then
        return WEAPON_AMMO_INFINITE
    endif
    if not WeaponInventoryValidPid(pid) or not WeaponInventoryValidSlot(slot) then
        return 0
    endif
    return WeaponInventorySlotAmmo[WeaponInventoryKey(pid, slot)]
endfunction

function WeaponInventoryGetActiveSlot takes player p returns integer
    local integer pid = GetPlayerId(p)
    if not WeaponInventoryValidPid(pid) then
        return WEAPON_INVENTORY_SLOT_1
    endif
    if not WeaponInventoryValidSlot(WeaponInventoryActiveSlot[pid]) then
        set WeaponInventoryActiveSlot[pid] = WEAPON_INVENTORY_SLOT_1
    endif
    return WeaponInventoryActiveSlot[pid]
endfunction

function WeaponInventoryGetActiveProfile takes player p returns integer
    return WeaponInventoryGetSlotProfile(p, WeaponInventoryGetActiveSlot(p))
endfunction

function WeaponInventoryGetActiveAmmo takes player p returns integer
    return WeaponInventoryGetSlotAmmo(p, WeaponInventoryGetActiveSlot(p))
endfunction

function WeaponInventorySetSlotWeapon takes player p, integer slot, integer profileId, integer ammo returns boolean
    local integer pid = GetPlayerId(p)
    local integer key
    if not WeaponInventoryValidPid(pid) or not WeaponInventoryValidSlot(slot) or not WeaponProfileIsWeapon(profileId) then
        return false
    endif
    set key = WeaponInventoryKey(pid, slot)
    set WeaponInventorySlotProfile[key] = profileId
    if profileId == WEAPON_PROFILE_HANDGUN then
        set WeaponInventorySlotAmmo[key] = WEAPON_AMMO_INFINITE
    else
        if ammo < 0 then
            set ammo = 0
        endif
        set WeaponInventorySlotAmmo[key] = ammo
    endif
    call WeaponInventoryMarkDirtyByPid(pid)
    if WeaponInventoryActiveSlot[pid] == slot then
        call WeaponInventoryApplyProfileStats(p, profileId)
    endif
    return true
endfunction

function WeaponInventoryResetSlotToHandgun takes player p, integer slot returns nothing
    call WeaponInventorySetSlotWeapon(p, slot, WEAPON_PROFILE_HANDGUN, WEAPON_AMMO_INFINITE)
endfunction

function WeaponInventorySetActiveSlot takes player p, integer slot returns boolean
    local integer pid = GetPlayerId(p)
    if not WeaponInventoryValidPid(pid) or not WeaponInventoryValidSlot(slot) then
        return false
    endif
    set WeaponInventoryActiveSlot[pid] = slot
    call WeaponInventoryApplyProfileStats(p, WeaponInventoryGetSlotProfile(p, slot))
    call WeaponInventoryQueueWeaponSound(p, WeaponInventoryGetSlotProfile(p, slot))
    call WeaponInventoryMarkDirtyByPid(pid)
    return true
endfunction

function WeaponInventoryEnsurePlayer takes player p returns nothing
    local integer pid = GetPlayerId(p)
    local unit hero = PlayerHero[pid]
    if not WeaponInventoryValidPid(pid) then
        set hero = null
        return
    endif
    if not WeaponInventoryValidSlot(WeaponInventoryActiveSlot[pid]) then
        set WeaponInventoryActiveSlot[pid] = WEAPON_INVENTORY_SLOT_1
    endif
    if not WeaponProfileIsWeapon(WeaponInventorySlotProfile[WeaponInventoryKey(pid, WEAPON_INVENTORY_SLOT_1)]) then
        call WeaponInventoryResetSlotToHandgun(p, WEAPON_INVENTORY_SLOT_1)
    endif
    if not WeaponProfileIsWeapon(WeaponInventorySlotProfile[WeaponInventoryKey(pid, WEAPON_INVENTORY_SLOT_2)]) then
        call WeaponInventoryResetSlotToHandgun(p, WEAPON_INVENTORY_SLOT_2)
    endif
    if WeaponInventoryValidHero(hero) then
        call WeaponInventoryRemoveLegacyAbilities(hero)
        if GetUnitAbilityLevel(hero, WEAPON_INVENTORY_FIRE_ABILITY) <= 0 then
            call UnitAddAbility(hero, WEAPON_INVENTORY_FIRE_ABILITY)
            call SetUnitAbilityLevel(hero, WEAPON_INVENTORY_FIRE_ABILITY, 1)
        endif
        if GetUnitAbilityLevel(hero, WEAPON_INVENTORY_SELECT_SLOT_1_ABILITY) <= 0 then
            call UnitAddAbility(hero, WEAPON_INVENTORY_SELECT_SLOT_1_ABILITY)
            call SetUnitAbilityLevel(hero, WEAPON_INVENTORY_SELECT_SLOT_1_ABILITY, 1)
        endif
        if GetUnitAbilityLevel(hero, WEAPON_INVENTORY_SELECT_SLOT_2_ABILITY) <= 0 then
            call UnitAddAbility(hero, WEAPON_INVENTORY_SELECT_SLOT_2_ABILITY)
            call SetUnitAbilityLevel(hero, WEAPON_INVENTORY_SELECT_SLOT_2_ABILITY, 1)
        endif
    endif
    call WeaponInventoryApplyProfileStats(p, WeaponInventoryGetActiveProfile(p))
    call WeaponInventoryMarkDirtyByPid(pid)
    set hero = null
endfunction

function WeaponInventoryGiveWeapon takes player p, integer profileId, integer ammo returns boolean
    local integer pid = GetPlayerId(p)
    local integer activeSlot
    local integer otherSlot
    local integer activeProfile
    local integer otherProfile
    local integer targetSlot
    local integer currentAmmo
    if not WeaponInventoryValidPid(pid) or not WeaponProfileIsWeapon(profileId) then
        return false
    endif
    call WeaponInventoryEnsurePlayer(p)
    if profileId == WEAPON_PROFILE_HANDGUN then
        return true
    endif
    if ammo <= 0 then
        set ammo = WeaponProfileGetDefaultAmmo(profileId)
    endif
    if WeaponInventoryGetSlotProfile(p, WEAPON_INVENTORY_SLOT_1) == profileId then
        set currentAmmo = WeaponInventoryGetSlotAmmo(p, WEAPON_INVENTORY_SLOT_1)
        call WeaponInventorySetSlotWeapon(p, WEAPON_INVENTORY_SLOT_1, profileId, currentAmmo + ammo)
        call WeaponInventoryQueueWeaponSound(p, profileId)
        return true
    endif
    if WeaponInventoryGetSlotProfile(p, WEAPON_INVENTORY_SLOT_2) == profileId then
        set currentAmmo = WeaponInventoryGetSlotAmmo(p, WEAPON_INVENTORY_SLOT_2)
        call WeaponInventorySetSlotWeapon(p, WEAPON_INVENTORY_SLOT_2, profileId, currentAmmo + ammo)
        call WeaponInventoryQueueWeaponSound(p, profileId)
        return true
    endif

    set activeSlot = WeaponInventoryGetActiveSlot(p)
    set otherSlot = WEAPON_INVENTORY_SLOT_1
    if activeSlot == WEAPON_INVENTORY_SLOT_1 then
        set otherSlot = WEAPON_INVENTORY_SLOT_2
    endif
    set activeProfile = WeaponInventoryGetSlotProfile(p, activeSlot)
    set otherProfile = WeaponInventoryGetSlotProfile(p, otherSlot)
    if activeProfile == WEAPON_PROFILE_HANDGUN then
        set targetSlot = activeSlot
    elseif otherProfile == WEAPON_PROFILE_HANDGUN then
        set targetSlot = otherSlot
    else
        set targetSlot = activeSlot
    endif
    if WeaponInventorySetSlotWeapon(p, targetSlot, profileId, ammo) then
        call WeaponInventoryQueueWeaponSound(p, profileId)
        return true
    endif
    return false
endfunction

function WeaponInventoryConsumeShotForProfile takes player p, integer profileId returns boolean
    local integer pid = GetPlayerId(p)
    local integer slot = WeaponInventoryGetActiveSlot(p)
    local integer key = WeaponInventoryKey(pid, slot)
    local integer ammo
    if not WeaponInventoryValidPid(pid) or not WeaponProfileIsWeapon(profileId) then
        return false
    endif
    if profileId == WEAPON_PROFILE_HANDGUN then
        return true
    endif
    if WeaponInventorySlotProfile[key] != profileId then
        return false
    endif
    set ammo = WeaponInventorySlotAmmo[key]
    if ammo <= 0 then
        call WeaponInventoryResetSlotToHandgun(p, slot)
        return false
    endif
    set ammo = ammo - 1
    if ammo <= 0 then
        call WeaponInventoryResetSlotToHandgun(p, slot)
    else
        set WeaponInventorySlotAmmo[key] = ammo
        call WeaponInventoryMarkDirtyByPid(pid)
    endif
    return true
endfunction

function WeaponInventoryConsumeShot takes player p returns boolean
    return WeaponInventoryConsumeShotForProfile(p, WeaponInventoryGetActiveProfile(p))
endfunction

function WeaponInventoryCanStartFire takes player p returns boolean
    local integer profileId = WeaponInventoryGetActiveProfile(p)
    if profileId == WEAPON_PROFILE_HANDGUN then
        return true
    endif
    if WeaponInventoryGetActiveAmmo(p) > 0 then
        return true
    endif
    call WeaponInventoryResetSlotToHandgun(p, WeaponInventoryGetActiveSlot(p))
    return false
endfunction

function WeaponInventoryResetActiveSlotOnDeath takes player p returns nothing
    call WeaponInventoryResetSlotToHandgun(p, WeaponInventoryGetActiveSlot(p))
endfunction

private function Init takes nothing returns nothing
    local integer pid = 0
    call WeaponInventoryInitSounds()
    loop
        exitwhen pid >= bj_MAX_PLAYER_SLOTS
        set WeaponInventoryActiveSlot[pid] = WEAPON_INVENTORY_SLOT_1
        set WeaponInventorySlotProfile[WeaponInventoryKey(pid, WEAPON_INVENTORY_SLOT_1)] = WEAPON_PROFILE_HANDGUN
        set WeaponInventorySlotAmmo[WeaponInventoryKey(pid, WEAPON_INVENTORY_SLOT_1)] = WEAPON_AMMO_INFINITE
        set WeaponInventorySlotProfile[WeaponInventoryKey(pid, WEAPON_INVENTORY_SLOT_2)] = WEAPON_PROFILE_HANDGUN
        set WeaponInventorySlotAmmo[WeaponInventoryKey(pid, WEAPON_INVENTORY_SLOT_2)] = WEAPON_AMMO_INFINITE
        set WeaponInventoryHudVersion[pid] = 1
        set pid = pid + 1
    endloop
endfunction

endlibrary
