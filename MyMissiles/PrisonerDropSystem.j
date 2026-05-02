library PrisonerDropSystem initializer Init requires TimerUtils, PlayerUtils, PlayerHeroState, WeaponInventoryCore, WaveDamageCredit

globals
    private constant real PRISONER_DROP_CHANCE = 10.00
    private constant integer PRISONER_CAP = 64
    private constant integer PICKUP_CAP = 64
    private constant real PRISONER_TICK = 0.10
    private constant real PRISONER_RESCUE_RANGE = 250.00
    private constant real PRISONER_PICKUP_RANGE = 125.00
    private constant real PRISONER_RESCUE_DELAY = 1.25
    private constant real PRISONER_DROP_OFFSET = 75.00
    private constant real PRISONER_ASCEND_TARGET = 5000.00
    private constant real PRISONER_ASCEND_SPEED = 500.00
    private constant real PRISONER_WANDER_RADIUS = 420.00
    private constant real PRISONER_WANDER_INTERVAL = 1.75
    private constant real PRISONER_LIFETIME = 45.00
    private constant real PICKUP_LIFETIME = 60.00
    private constant string PRISONER_RESCUE_SOUND_PATH = "war3mapImported\\tenkiuv2.wav"

    private timer PrisonerTicker = null
    private sound PrisonerRescueSound = null

    private unit array PrisonerUnit
    private integer array PrisonerOwnerPid
    private integer array PrisonerProfile
    private integer array PrisonerState
    private real array PrisonerStateTime
    private real array PrisonerWanderTime
    private real array PrisonerLifeTime

    private unit array PickupUnit
    private integer array PickupOwnerPid
    private integer array PickupProfile
    private real array PickupLifeTime
endglobals

private function PrisonerDistanceSq takes real ax, real ay, real bx, real by returns real
    local real dx = ax - bx
    local real dy = ay - by
    return dx*dx + dy*dy
endfunction

private function PrisonerAnyActive takes nothing returns boolean
    local integer i = 0
    loop
        exitwhen i >= PRISONER_CAP
        if PrisonerUnit[i] != null then
            return true
        endif
        set i = i + 1
    endloop
    set i = 0
    loop
        exitwhen i >= PICKUP_CAP
        if PickupUnit[i] != null then
            return true
        endif
        set i = i + 1
    endloop
    return false
endfunction

private function PrisonerClear takes integer i returns nothing
    if PrisonerUnit[i] != null then
        call RemoveUnit(PrisonerUnit[i])
    endif
    set PrisonerUnit[i] = null
    set PrisonerOwnerPid[i] = -1
    set PrisonerProfile[i] = WEAPON_PROFILE_NONE
    set PrisonerState[i] = 0
    set PrisonerStateTime[i] = 0.00
    set PrisonerWanderTime[i] = 0.00
    set PrisonerLifeTime[i] = 0.00
endfunction

private function PickupClear takes integer i, boolean killFirst returns nothing
    if PickupUnit[i] != null then
        if killFirst then
            call KillUnit(PickupUnit[i])
        endif
        call RemoveUnit(PickupUnit[i])
    endif
    set PickupUnit[i] = null
    set PickupOwnerPid[i] = -1
    set PickupProfile[i] = WEAPON_PROFILE_NONE
    set PickupLifeTime[i] = 0.00
endfunction

private function PrisonerAlloc takes nothing returns integer
    local integer i = 0
    loop
        exitwhen i >= PRISONER_CAP
        if PrisonerUnit[i] == null then
            return i
        endif
        set i = i + 1
    endloop
    return -1
endfunction

private function PickupAlloc takes nothing returns integer
    local integer i = 0
    loop
        exitwhen i >= PICKUP_CAP
        if PickupUnit[i] == null then
            return i
        endif
        set i = i + 1
    endloop
    return -1
endfunction

private function PrisonerRandomProfile takes nothing returns integer
    return GetRandomInt(WEAPON_PROFILE_SHOTGUN, WEAPON_PROFILE_LAST)
endfunction

private function PickupCreate takes integer pid, integer profileId, real x, real y, real facing returns nothing
    local integer slot = PickupAlloc()
    local integer unitTypeId = WeaponProfileGetPickupUnitType(profileId)
    if slot < 0 or unitTypeId == 0 then
        return
    endif
    set PickupUnit[slot] = CreateUnit(Player(pid), unitTypeId, x, y, facing)
    if PickupUnit[slot] == null then
        set PickupOwnerPid[slot] = -1
        set PickupProfile[slot] = WEAPON_PROFILE_NONE
        return
    endif
    call UnitAddAbility(PickupUnit[slot], 'Avul')
    call UnitAddAbility(PickupUnit[slot], 'Aloc')
    set PickupOwnerPid[slot] = pid
    set PickupProfile[slot] = profileId
    set PickupLifeTime[slot] = 0.00
endfunction

private function PrisonerBeginRescue takes integer i, unit hero returns nothing
    local real dx = GetUnitX(hero) - GetUnitX(PrisonerUnit[i])
    local real dy = GetUnitY(hero) - GetUnitY(PrisonerUnit[i])
    call IssueImmediateOrder(PrisonerUnit[i], "stop")
    call SetUnitFacing(PrisonerUnit[i], Atan2(dy, dx)*bj_RADTODEG)
    call SetUnitAnimation(PrisonerUnit[i], "attack")
    call PauseUnit(PrisonerUnit[i], true)
    if PrisonerRescueSound != null then
        call StartSound(PrisonerRescueSound)
    endif
    set PrisonerState[i] = 1
    set PrisonerStateTime[i] = 0.00
endfunction

private function PrisonerDropWeapon takes integer i returns nothing
    local real facing = GetUnitFacing(PrisonerUnit[i])
    local real angle = facing*bj_DEGTORAD
    local real x = GetUnitX(PrisonerUnit[i]) + PRISONER_DROP_OFFSET*Cos(angle)
    local real y = GetUnitY(PrisonerUnit[i]) + PRISONER_DROP_OFFSET*Sin(angle)
    call PickupCreate(PrisonerOwnerPid[i], PrisonerProfile[i], x, y, facing)
    call PauseUnit(PrisonerUnit[i], false)
    call SetUnitAnimation(PrisonerUnit[i], "stand")
    call SetUnitFlyHeight(PrisonerUnit[i], PRISONER_ASCEND_TARGET, PRISONER_ASCEND_SPEED)
    set PrisonerState[i] = 2
    set PrisonerStateTime[i] = 0.00
endfunction

private function PrisonerUpdateWander takes integer i returns nothing
    local real x
    local real y
    set PrisonerWanderTime[i] = PrisonerWanderTime[i] + PRISONER_TICK
    if PrisonerWanderTime[i] < PRISONER_WANDER_INTERVAL then
        return
    endif
    set PrisonerWanderTime[i] = 0.00
    if GetRandomInt(0, 2) == 0 then
        call IssueImmediateOrder(PrisonerUnit[i], "stop")
    else
        set x = GetUnitX(PrisonerUnit[i]) + GetRandomReal(-PRISONER_WANDER_RADIUS, PRISONER_WANDER_RADIUS)
        set y = GetUnitY(PrisonerUnit[i]) + GetRandomReal(-PRISONER_WANDER_RADIUS, PRISONER_WANDER_RADIUS)
        call IssuePointOrder(PrisonerUnit[i], "move", x, y)
    endif
endfunction

private function PrisonerUpdateActive takes integer i returns nothing
    local unit hero = PlayerHero[PrisonerOwnerPid[i]]
    local real px = GetUnitX(PrisonerUnit[i])
    local real py = GetUnitY(PrisonerUnit[i])
    if hero != null and GetUnitTypeId(hero) != 0 and UnitAlive(hero) then
        if PrisonerDistanceSq(px, py, GetUnitX(hero), GetUnitY(hero)) <= PRISONER_RESCUE_RANGE*PRISONER_RESCUE_RANGE then
            call PrisonerBeginRescue(i, hero)
        else
            call PrisonerUpdateWander(i)
        endif
    else
        call PrisonerUpdateWander(i)
    endif
    set hero = null
endfunction

private function PrisonerUpdateRescueDelay takes integer i returns nothing
    set PrisonerStateTime[i] = PrisonerStateTime[i] + PRISONER_TICK
    if PrisonerStateTime[i] >= PRISONER_RESCUE_DELAY then
        call PrisonerDropWeapon(i)
    endif
endfunction

private function PrisonerUpdateAscend takes integer i returns nothing
    set PrisonerStateTime[i] = PrisonerStateTime[i] + PRISONER_TICK
    if GetUnitFlyHeight(PrisonerUnit[i]) >= PRISONER_ASCEND_TARGET - 25.00 or PrisonerStateTime[i] >= (PRISONER_ASCEND_TARGET/PRISONER_ASCEND_SPEED) + 1.00 then
        call PrisonerClear(i)
    endif
endfunction

private function PickupUpdate takes integer i returns nothing
    local integer playerIndex = 0
    local User u
    local unit hero
    loop
        exitwhen playerIndex >= User.AmountPlaying
        set u = User.fromPlaying(playerIndex)
        set hero = PlayerHero[u.id]
        if hero != null and GetUnitTypeId(hero) != 0 and UnitAlive(hero) then
            if PrisonerDistanceSq(GetUnitX(PickupUnit[i]), GetUnitY(PickupUnit[i]), GetUnitX(hero), GetUnitY(hero)) <= PRISONER_PICKUP_RANGE*PRISONER_PICKUP_RANGE then
                call WeaponInventoryGiveWeapon(u.toPlayer(), PickupProfile[i], WeaponProfileGetDefaultAmmo(PickupProfile[i]))
                call PickupClear(i, true)
                set hero = null
                return
            endif
        endif
        set playerIndex = playerIndex + 1
    endloop
    set hero = null

    if PickupOwnerPid[i] >= 0 and PickupOwnerPid[i] < bj_MAX_PLAYER_SLOTS and not User.fromIndex(PickupOwnerPid[i]).isPlaying then
        if PickupUnit[i] != null then
            call PickupClear(i, true)
            return
        endif
    endif

    set PickupLifeTime[i] = PickupLifeTime[i] + PRISONER_TICK
    if PickupLifeTime[i] >= PICKUP_LIFETIME then
        call PickupClear(i, false)
    endif
endfunction

private function PrisonerTick takes nothing returns nothing
    local integer i = 0
    loop
        exitwhen i >= PRISONER_CAP
        if PrisonerUnit[i] != null then
            set PrisonerLifeTime[i] = PrisonerLifeTime[i] + PRISONER_TICK
            if PrisonerLifeTime[i] >= PRISONER_LIFETIME and PrisonerState[i] == 0 then
                call PrisonerClear(i)
            elseif PrisonerState[i] == 0 then
                call PrisonerUpdateActive(i)
            elseif PrisonerState[i] == 1 then
                call PrisonerUpdateRescueDelay(i)
            elseif PrisonerState[i] == 2 then
                call PrisonerUpdateAscend(i)
            endif
        endif
        set i = i + 1
    endloop
    set i = 0
    loop
        exitwhen i >= PICKUP_CAP
        if PickupUnit[i] != null then
            call PickupUpdate(i)
        endif
        set i = i + 1
    endloop
    if not PrisonerAnyActive() and PrisonerTicker != null then
        call PauseTimer(PrisonerTicker)
    endif
endfunction

private function PrisonerEnsureTicker takes nothing returns nothing
    if PrisonerTicker == null then
        set PrisonerTicker = NewTimer()
        call SetTimerDebugTag(PrisonerTicker, TIMER_DEBUG_TAG_OTHER)
    endif
    call TimerStart(PrisonerTicker, PRISONER_TICK, true, function PrisonerTick)
endfunction

function PrisonerDropTrySpawnForPid takes unit killedEnemy, integer pid returns boolean
    local integer slot
    local integer profileId
    local real x
    local real y
    if killedEnemy == null or GetUnitTypeId(killedEnemy) == 0 then
        return false
    endif
    if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
        return false
    endif
    if PlayerHero[pid] == null or GetUnitTypeId(PlayerHero[pid]) == 0 then
        return false
    endif
    if GetRandomReal(0.00, 100.00) > PRISONER_DROP_CHANCE then
        return false
    endif
    set slot = PrisonerAlloc()
    if slot < 0 then
        return false
    endif
    set profileId = PrisonerRandomProfile()
    set x = GetUnitX(killedEnemy)
    set y = GetUnitY(killedEnemy)
    set PrisonerUnit[slot] = CreateUnit(Player(pid), WEAPON_PRISONER_UNIT_TYPE, x, y, GetRandomReal(0.00, 360.00))
    if PrisonerUnit[slot] == null then
        call PrisonerClear(slot)
        return false
    endif
    call UnitAddAbility(PrisonerUnit[slot], 'Avul')
    call UnitAddAbility(PrisonerUnit[slot], 'Aloc')
    call UnitAddAbility(PrisonerUnit[slot], 'Amrf')
    call UnitRemoveAbility(PrisonerUnit[slot], 'Amrf')
    set PrisonerOwnerPid[slot] = pid
    set PrisonerProfile[slot] = profileId
    set PrisonerState[slot] = 0
    set PrisonerStateTime[slot] = 0.00
    set PrisonerWanderTime[slot] = PRISONER_WANDER_INTERVAL
    set PrisonerLifeTime[slot] = 0.00
    call PrisonerEnsureTicker()
    return true
endfunction

function PrisonerDropTrySpawn takes unit killedEnemy returns boolean
    return PrisonerDropTrySpawnForPid(killedEnemy, WaveGetDamageCreditOwnerPid(killedEnemy))
endfunction

private function Init takes nothing returns nothing
    local integer i = 0
    call Preload(PRISONER_RESCUE_SOUND_PATH)
    set PrisonerRescueSound = CreateSound(PRISONER_RESCUE_SOUND_PATH, false, false, false, 12700, 12700, "")
    call SetSoundVolume(PrisonerRescueSound, 127)
    loop
        exitwhen i >= PRISONER_CAP
        set PrisonerOwnerPid[i] = -1
        set PrisonerProfile[i] = WEAPON_PROFILE_NONE
        set i = i + 1
    endloop
    set i = 0
    loop
        exitwhen i >= PICKUP_CAP
        set PickupOwnerPid[i] = -1
        set PickupProfile[i] = WEAPON_PROFILE_NONE
        set i = i + 1
    endloop
endfunction

endlibrary
