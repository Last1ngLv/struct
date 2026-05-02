library LoadoutMetalSlugSpecial initializer Init requires TimerUtils, SpellIndex, Missile, RegisterPlayerUnitEvent, DamageTextUtil, WeaponProfileConfig, WaveDamageCredit, Table, WeaponInventoryCore

    globals
        private constant real MISSILE_START_Z = 75.00
        private constant real MISSILE_GROUND_Z = 0.00
        private constant real DEFAULT_COLLISION = 96.00
        private constant real PIERCING_PULSE_INTERVAL = 0.12
        private constant real FLAME_PULSE_INTERVAL = 0.10
        private constant real DROP_BOUNCE_INTERVAL = 0.20
        private constant real GRENADE_ARC = 0.60
        private constant real DROP_BOUNCE_ARC = 0.45
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC

        private Table active

        private integer array castProfile
        private real array castAngle
        private real array castTargetX
        private real array castTargetY

        private integer array missileProfile
        private real array missileDamage
        private real array missileArea
        private real array missilePulseRemaining
        private real array missileSpeed
        private real array missileTravel
        private real array missileMaxRange
        private real array missileSegmentRange
        private unit array missileSource
        private player array missileOwner
    endglobals

    private function MinReal takes real a, real b returns real
        if a < b then
            return a
        endif
        return b
    endfunction

    private function GetSafeFireInterval takes integer profileId returns real
        local real duration = WeaponProfileGetCastDuration(profileId)
        local integer count = WeaponProfileGetCastCount(profileId)
        if duration <= 0. then
            return 0.03125
        endif
        if count <= 0 then
            return duration
        endif
        return duration / I2R(count)
    endfunction

    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
    endfunction

    private function DamageUnit takes unit source, unit target, real amount returns boolean
        if amount <= 0. then
            return false
        endif
        if (GetUnitTypeId(source) == 0) or (GetUnitTypeId(target) == 0) then
            return false
        endif
        call WaveRecordDamageCredit(source, target)
        return UnitDamageTarget(source, target, amount, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
    endfunction

    private function DamageArea takes unit source, player owner, real x, real y, real radius, real amount returns nothing
        local unit u
        if amount <= 0. or radius <= 0. or GetUnitTypeId(source) == 0 then
            return
        endif
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, radius, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if FilterUnits(u, owner) then
                call DamageUnit(source, u, amount)
            endif
        endloop
        set u = null
    endfunction

    private function ImpactFx takes integer profileId, real x, real y returns nothing
        local effect fx
        if profileId == WEAPON_PROFILE_DROP_SHOT then
            set fx = AddSpecialEffect(WeaponProfileGetMissileModel(profileId), x, y)
            call DestroyEffect(fx)
            set fx = null
        endif
    endfunction

    private function ConfigureDropBounceSegment takes Missile missile returns nothing
        local real remaining = missileMaxRange[missile] - missileTravel[missile]
        local real segment = MinReal(missileSpeed[missile]*DROP_BOUNCE_INTERVAL, remaining)
        if segment < 1.00 then
            set segment = 1.00
        endif
        set missileSegmentRange[missile] = segment
        call missile.impact.move(missile.x + segment*Cos(missile.angle), missile.y + segment*Sin(missile.angle), MISSILE_GROUND_Z)
        call missile.bounce()
        set missile.arc = DROP_BOUNCE_ARC
        set missile.recycle = false
    endfunction

    private struct MetalSlugSpecialCore extends array
        private static method onCollide takes Missile missile, unit hit returns boolean
            local integer profileId = missileProfile[missile]
            if profileId == WEAPON_PROFILE_ROCKET_LAUNCHER or profileId == WEAPON_PROFILE_SUPER_GRENADE then
                if not FilterUnits(hit, missileOwner[missile]) then
                    return false
                endif
                call DamageArea(missileSource[missile], missileOwner[missile], missile.x, missile.y, missileArea[missile], missileDamage[missile])
                return true
            endif
            return false
        endmethod

        private static method onFinish takes Missile missile returns boolean
            local integer profileId = missileProfile[missile]
            if profileId == WEAPON_PROFILE_DROP_SHOT then
                set missileTravel[missile] = missileTravel[missile] + missileSegmentRange[missile]
                call DamageArea(missileSource[missile], missileOwner[missile], missile.x, missile.y, missileArea[missile], missileDamage[missile])
                call ImpactFx(profileId, missile.x, missile.y)
                if missileTravel[missile] >= missileMaxRange[missile] then
                    return true
                endif
                call missile.flushHitWidgets()
                call ConfigureDropBounceSegment(missile)
                return false
            endif
            if profileId == WEAPON_PROFILE_GRENADE or profileId == WEAPON_PROFILE_SUPER_GRENADE or profileId == WEAPON_PROFILE_ROCKET_LAUNCHER then
                call DamageArea(missileSource[missile], missileOwner[missile], missile.x, missile.y, missileArea[missile], missileDamage[missile])
            endif
            return true
        endmethod

        private static method onDestructable takes Missile missile, destructable hit returns boolean
            if missileProfile[missile] == WEAPON_PROFILE_GRENADE then
                return false
            endif
            call DamageArea(missileSource[missile], missileOwner[missile], missile.x, missile.y, missileArea[missile], missileDamage[missile])
            return true
        endmethod

        private static method onTerrain takes Missile missile returns boolean
            if missileProfile[missile] == WEAPON_PROFILE_GRENADE or missileProfile[missile] == WEAPON_PROFILE_DROP_SHOT then
                return false
            endif
            call DamageArea(missileSource[missile], missileOwner[missile], missile.x, missile.y, missileArea[missile], missileDamage[missile])
            return true
        endmethod

        private static method onPeriod takes Missile missile returns boolean
            local integer profileId = missileProfile[missile]
            local real accel
            if profileId == WEAPON_PROFILE_SHOTGUN or profileId == WEAPON_PROFILE_FLAME_SHOT then
                set missilePulseRemaining[missile] = missilePulseRemaining[missile] - Missile_TIMER_TIMEOUT
                if missilePulseRemaining[missile] <= 0. then
                    call DamageArea(missileSource[missile], missileOwner[missile], missile.x, missile.y, missileArea[missile], missileDamage[missile])
                    if profileId == WEAPON_PROFILE_FLAME_SHOT then
                        set missilePulseRemaining[missile] = FLAME_PULSE_INTERVAL
                    else
                        set missilePulseRemaining[missile] = PIERCING_PULSE_INTERVAL
                    endif
                endif
                set accel = WeaponProfileGetAcceleration(profileId)
                if accel > 0. then
                    set missileSpeed[missile] = missileSpeed[missile] + accel
                    call missile.setMovementSpeed(missileSpeed[missile])
                endif
            endif
            return false
        endmethod

        private static method onRemove takes Missile missile returns boolean
            set missileProfile[missile] = WEAPON_PROFILE_NONE
            set missileDamage[missile] = 0.00
            set missileArea[missile] = 0.00
            set missilePulseRemaining[missile] = 0.00
            set missileSpeed[missile] = 0.00
            set missileTravel[missile] = 0.00
            set missileMaxRange[missile] = 0.00
            set missileSegmentRange[missile] = 0.00
            set missileSource[missile] = null
            set missileOwner[missile] = null
            call SpellIndex(missile.data).destroy()
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function LaunchSpecialMissile takes unit source, player owner, integer profileId, real angle, real targetX, real targetY returns nothing
        local real x = GetUnitX(source) + DEFAULT_COLLISION*Cos(angle)
        local real y = GetUnitY(source) + DEFAULT_COLLISION*Sin(angle)
        local real range = WeaponProfileGetRange(profileId)
        local real endZ = MISSILE_START_Z
        local Missile missile
        local SpellIndex dex = SpellIndex.create()
        local real speed = WeaponProfileGetMissileSpeed(profileId)

        if profileId == WEAPON_PROFILE_GRENADE then
            set angle = Atan2(targetY - y, targetX - x)
            set range = SquareRoot((targetX - x)*(targetX - x) + (targetY - y)*(targetY - y))
            set range = MinReal(range, WeaponProfileGetRange(profileId))
            set endZ = MISSILE_GROUND_Z
        elseif profileId == WEAPON_PROFILE_DROP_SHOT then
            set endZ = MISSILE_GROUND_Z
        endif
        if range < 1.00 then
            set range = 1.00
        endif
        set missile = Missile.create(x, y, MISSILE_START_Z, angle, range, endZ)

        set dex.source = source
        set dex.user = owner
        set missile.source = source
        set missile.owner = owner
        set missile.data = dex
        set missile.model = WeaponProfileGetTierMissileModel(profileId, 1)
        set missile.scale = WeaponProfileGetMissileScale(profileId)
        set missile.collision = DEFAULT_COLLISION
        if profileId == WEAPON_PROFILE_GRENADE then
            set missile.arc = GRENADE_ARC
        endif
        call missile.setMovementSpeed(speed)

        set missileProfile[missile] = profileId
        set missileDamage[missile] = WeaponProfileGetDamage(profileId)
        set missileArea[missile] = WeaponProfileGetArea(profileId)
        if profileId == WEAPON_PROFILE_DROP_SHOT then
            set missilePulseRemaining[missile] = DROP_BOUNCE_INTERVAL
        else
            set missilePulseRemaining[missile] = 0.00
        endif
        set missileSpeed[missile] = speed
        set missileTravel[missile] = 0.00
        set missileMaxRange[missile] = range
        set missileSegmentRange[missile] = range
        set missileSource[missile] = source
        set missileOwner[missile] = owner

        if profileId == WEAPON_PROFILE_DROP_SHOT then
            call ConfigureDropBounceSegment(missile)
        endif

        call MetalSlugSpecialCore.launch(missile)
    endfunction

    private function CleanupCast takes SpellIndex dex returns nothing
        local integer id = 0
        if dex == 0 or dex.phase == -999 then
            return
        endif
        set dex.phase = -999
        if GetUnitTypeId(dex.source) != 0 then
            set id = GetHandleId(dex.source)
            if active.has(id) and (active[id] == dex) then
                call active.remove(id)
            endif
        endif
        if dex.clock != null then
            call ReleaseTimer(dex.clock)
            set dex.clock = null
        endif
        set castProfile[dex] = WEAPON_PROFILE_NONE
        set castAngle[dex] = 0.00
        set castTargetX[dex] = 0.00
        set castTargetY[dex] = 0.00
        call dex.destroy()
    endfunction

    private function FireCastShot takes SpellIndex dex returns nothing
        if GetUnitTypeId(dex.source) == 0 or not UnitAlive(dex.source) then
            return
        endif
        if not WeaponInventoryConsumeShotForProfile(dex.user, castProfile[dex]) then
            return
        endif
        call SetUnitAnimation(dex.source, "attack")
        call LaunchSpecialMissile(dex.source, dex.user, castProfile[dex], castAngle[dex], castTargetX[dex], castTargetY[dex])
    endfunction

    private function OnCastTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local real step = GetSafeFireInterval(castProfile[dex])
        if dex.time <= 0. or GetUnitTypeId(dex.source) == 0 or not UnitAlive(dex.source) then
            call CleanupCast(dex)
            set t = null
            return
        endif
        call FireCastShot(dex)
        set dex.time = dex.time - step
        if dex.time <= 0. then
            call CleanupCast(dex)
        else
            call TimerStart(dex.clock, step, false, function OnCastTick)
        endif
        set t = null
    endfunction

    function LoadoutMetalSlugSpecialFireProfile takes unit source, player owner, integer profileId, real tx, real ty returns boolean
        local integer id = GetHandleId(source)
        local real duration = WeaponProfileGetCastDuration(profileId)
        local real step = GetSafeFireInterval(profileId)
        local SpellIndex dex
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)

        if not WeaponProfileIsWeapon(profileId) then
            return false
        endif

        if active.has(id) then
            set dex = active[id]
            if (GetUnitTypeId(dex.source) != 0) and UnitAlive(dex.source) then
                set castProfile[dex] = profileId
                set castAngle[dex] = Atan2(ty - y, tx - x)
                set castTargetX[dex] = tx
                set castTargetY[dex] = ty
                set dex.time = duration
                call SetUnitAnimation(dex.source, "attack")
                return true
            endif
            call CleanupCast(dex)
        endif

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = owner
        set dex.time = duration
        set dex.phase = 1
        set castProfile[dex] = profileId
        set castAngle[dex] = Atan2(ty - y, tx - x)
        set castTargetX[dex] = tx
        set castTargetY[dex] = ty
        set dex.clock = null
        set active[id] = dex

        call FireCastShot(dex)
        set dex.time = dex.time - step
        if dex.time > 0. then
            set dex.clock = NewTimerEx(dex)
            call SetTimerDebugTag(dex.clock, TIMER_DEBUG_TAG_LOADOUT_MISSILE)
            call TimerStart(dex.clock, step, false, function OnCastTick)
        else
            call CleanupCast(dex)
        endif

        return true
    endfunction

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        call LoadoutMetalSlugSpecialFireProfile(source, owner, WeaponProfileFromFireAbility(GetSpellAbilityId()), GetSpellTargetX(), GetSpellTargetY())
        set source = null
        set owner = null
    endfunction

    private function Init takes nothing returns nothing
        set active = Table.create()
        call RegisterSpellEffectEvent(WeaponProfileGetFireAbility(WEAPON_PROFILE_SHOTGUN), function OnEffect)
        call RegisterSpellEffectEvent(WeaponProfileGetFireAbility(WEAPON_PROFILE_ROCKET_LAUNCHER), function OnEffect)
        call RegisterSpellEffectEvent(WeaponProfileGetFireAbility(WEAPON_PROFILE_GRENADE), function OnEffect)
        call RegisterSpellEffectEvent(WeaponProfileGetFireAbility(WEAPON_PROFILE_DROP_SHOT), function OnEffect)
        call RegisterSpellEffectEvent(WeaponProfileGetFireAbility(WEAPON_PROFILE_FLAME_SHOT), function OnEffect)
        call RegisterSpellEffectEvent(WeaponProfileGetFireAbility(WEAPON_PROFILE_SUPER_GRENADE), function OnEffect)
    endfunction

endlibrary
