library LoadoutThunderShot initializer Init requires TimerUtils, SpellIndex, Missile, RegisterPlayerUnitEvent, WeaponProfileConfig, WaveDamageCredit, Table, WeaponInventoryCore

    globals
        private constant real MISSILE_START_Z = 75.00
        private constant real MISSILE_COLLISION = 96.00
        private constant real MISSILE_FORWARD_OFFSET = 96.00
        private constant real THUNDER_SEARCH_RADIUS = 650.00
        private constant real THUNDER_TURN_RATE = 1.35
        private constant real THUNDER_SCAN_INTERVAL = 0.05
        private constant real THUNDER_REPEAT_INTERVAL = 0.06
        private constant real THUNDER_WAVE_CURVE = 0.18
        private constant real THUNDER_WAVE_SEGMENT_RANGE = 420.00
        private constant real THUNDER_FREE_TRAVEL_RANGE = 2000.00
        private constant integer THUNDER_MAX_HITS = 15
        private constant string IMPACT_ATTACH = "origin"
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC

        private Table active

        private real array castAngle
        private real array castTargetX
        private real array castTargetY

        private real array thunderDamage
        private integer array thunderHitsLeft
        private real array thunderScanRemaining
        private integer array thunderWaveSign
        private unit array thunderLastHit
        private unit array thunderSource
        private player array thunderOwner
    endglobals

    private function GetSafeFireInterval takes nothing returns real
        local real duration = WeaponProfileGetCastDuration(WEAPON_PROFILE_THUNDER_SHOT)
        local integer count = WeaponProfileGetCastCount(WEAPON_PROFILE_THUNDER_SHOT)
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

    private function ShowThunderImpact takes unit target returns nothing
        local effect fx = AddSpecialEffectTarget(WeaponProfileGetMissileModel(WEAPON_PROFILE_THUNDER_SHOT), target, IMPACT_ATTACH)
        call DestroyEffect(fx)
        set fx = null
    endfunction

    private function ConfigureThunderWaveSegment takes Missile missile returns boolean
        local real remaining = THUNDER_FREE_TRAVEL_RANGE - missile.distance
        local real segment
        if remaining <= 0.00 then
            return false
        endif
        set segment = remaining
        if segment > THUNDER_WAVE_SEGMENT_RANGE then
            set segment = THUNDER_WAVE_SEGMENT_RANGE
        endif
        call missile.impact.move(missile.x + segment*Cos(missile.angle), missile.y + segment*Sin(missile.angle), MISSILE_START_Z)
        call missile.bounce()
        set missile.target = null
        set missile.turn = 0.00
        set missile.curve = THUNDER_WAVE_CURVE*I2R(thunderWaveSign[missile])
        set thunderWaveSign[missile] = -thunderWaveSign[missile]
        set missile.recycle = false
        return true
    endfunction

    private function FindThunderTarget takes Missile missile, unit excluded returns unit
        local unit u
        local unit chosen = null
        local real dx
        local real dy
        local real distSq
        local real bestSq = 0.00
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, THUNDER_SEARCH_RADIUS, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if u != excluded and FilterUnits(u, thunderOwner[missile]) then
                set dx = GetUnitX(u) - missile.x
                set dy = GetUnitY(u) - missile.y
                set distSq = dx*dx + dy*dy
                if chosen == null or distSq < bestSq then
                    set chosen = u
                    set bestSq = distSq
                endif
            endif
        endloop
        set u = null
        return chosen
    endfunction

    private function AssignThunderTarget takes Missile missile, unit target returns nothing
        if target != null and FilterUnits(target, thunderOwner[missile]) then
            set missile.target = target
            set missile.turn = THUNDER_TURN_RATE
            set missile.curve = 0.00
            set missile.recycle = false
        else
            set missile.target = null
            set missile.turn = 0.00
            call ConfigureThunderWaveSegment(missile)
        endif
    endfunction

    private function RefreshThunderTarget takes Missile missile returns nothing
        local unit target = missile.target
        set thunderScanRemaining[missile] = thunderScanRemaining[missile] - Missile_TIMER_TIMEOUT
        if target != null and FilterUnits(target, thunderOwner[missile]) then
            set target = null
            return
        endif
        if thunderScanRemaining[missile] > 0. then
            set target = null
            return
        endif
        set thunderScanRemaining[missile] = THUNDER_SCAN_INTERVAL
        set target = FindThunderTarget(missile, null)
        if target != null then
            call AssignThunderTarget(missile, target)
        endif
        set target = null
    endfunction

    private function FindNextThunderTarget takes Missile missile, unit excluded, unit fallback returns unit
        local unit target = FindThunderTarget(missile, excluded)
        if target == null and fallback != null and FilterUnits(fallback, thunderOwner[missile]) then
            set target = fallback
        endif
        return target
    endfunction

    private struct ThunderShotCore extends array
        private static method onCollide takes Missile missile, unit hit returns boolean
            local unit nextTarget
            local boolean wasAlive
            if not FilterUnits(hit, thunderOwner[missile]) then
                return false
            endif
            set wasAlive = UnitAlive(hit)
            call DamageUnit(thunderSource[missile], hit, thunderDamage[missile])
            call ShowThunderImpact(hit)
            set thunderHitsLeft[missile] = thunderHitsLeft[missile] - 1
            set thunderLastHit[missile] = hit
            if thunderHitsLeft[missile] <= 0 then
                set hit = null
                return true
            endif

            call missile.enableHitAfter(hit, THUNDER_REPEAT_INTERVAL)
            set nextTarget = FindThunderTarget(missile, hit)
            if nextTarget == null then
                if wasAlive and UnitAlive(hit) then
                    set nextTarget = hit
                else
                    set hit = null
                    return true
                endif
            endif
            call AssignThunderTarget(missile, nextTarget)
            set nextTarget = null
            set hit = null
            return false
        endmethod

        private static method onPeriod takes Missile missile returns boolean
            call RefreshThunderTarget(missile)
            return false
        endmethod

        private static method onFinish takes Missile missile returns boolean
            local unit nextTarget
            if thunderHitsLeft[missile] <= 0 then
                return true
            endif
            set nextTarget = FindNextThunderTarget(missile, null, thunderLastHit[missile])
            if nextTarget != null then
                call AssignThunderTarget(missile, nextTarget)
                set nextTarget = null
                return false
            endif
            set nextTarget = null
            if thunderLastHit[missile] != null then
                return true
            endif
            return not ConfigureThunderWaveSegment(missile)
        endmethod

        private static method onDestructable takes Missile missile, destructable hit returns boolean
            return false
        endmethod

        private static method onTerrain takes Missile missile returns boolean
            return false
        endmethod

        private static method onRemove takes Missile missile returns boolean
            set thunderDamage[missile] = 0.00
            set thunderHitsLeft[missile] = 0
            set thunderScanRemaining[missile] = 0.00
            set thunderWaveSign[missile] = 0
            set thunderLastHit[missile] = null
            set thunderSource[missile] = null
            set thunderOwner[missile] = null
            set missile.target = null
            set missile.turn = 0.00
            call SpellIndex(missile.data).destroy()
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function LaunchThunderShot takes unit source, player owner, real angle returns nothing
        local real x = GetUnitX(source) + MISSILE_FORWARD_OFFSET*Cos(angle)
        local real y = GetUnitY(source) + MISSILE_FORWARD_OFFSET*Sin(angle)
        local Missile missile = Missile.create(x, y, MISSILE_START_Z, angle, WeaponProfileGetRange(WEAPON_PROFILE_THUNDER_SHOT), MISSILE_START_Z)
        local SpellIndex dex = SpellIndex.create()

        set dex.source = source
        set dex.user = owner
        set missile.source = source
        set missile.owner = owner
        set missile.data = dex
        set missile.model = WeaponProfileGetTierMissileModel(WEAPON_PROFILE_THUNDER_SHOT, 1)
        set missile.scale = WeaponProfileGetMissileScale(WEAPON_PROFILE_THUNDER_SHOT)
        set missile.collision = MISSILE_COLLISION
        call missile.setMovementSpeed(WeaponProfileGetMissileSpeed(WEAPON_PROFILE_THUNDER_SHOT))

        set thunderDamage[missile] = WeaponProfileGetDamage(WEAPON_PROFILE_THUNDER_SHOT)
        set thunderHitsLeft[missile] = THUNDER_MAX_HITS
        set thunderScanRemaining[missile] = 0.00
        set thunderWaveSign[missile] = 1
        set thunderLastHit[missile] = null
        set thunderSource[missile] = source
        set thunderOwner[missile] = owner
        call ConfigureThunderWaveSegment(missile)

        call ThunderShotCore.launch(missile)
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
        set castAngle[dex] = 0.00
        set castTargetX[dex] = 0.00
        set castTargetY[dex] = 0.00
        call dex.destroy()
    endfunction

    private function FireCastShot takes SpellIndex dex returns nothing
        if GetUnitTypeId(dex.source) == 0 or not UnitAlive(dex.source) then
            return
        endif
        if not WeaponInventoryConsumeShotForProfile(dex.user, WEAPON_PROFILE_THUNDER_SHOT) then
            return
        endif
        call SetUnitAnimation(dex.source, "attack")
        call LaunchThunderShot(dex.source, dex.user, castAngle[dex])
    endfunction

    private function OnCastTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local real step = GetSafeFireInterval()
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

    function LoadoutThunderShotFire takes unit source, player owner, real tx, real ty returns boolean
        local integer id = GetHandleId(source)
        local real duration = WeaponProfileGetCastDuration(WEAPON_PROFILE_THUNDER_SHOT)
        local real step = GetSafeFireInterval()
        local SpellIndex dex
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)

        if active.has(id) then
            set dex = active[id]
            if (GetUnitTypeId(dex.source) != 0) and UnitAlive(dex.source) then
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
        call LoadoutThunderShotFire(source, owner, GetSpellTargetX(), GetSpellTargetY())
        set source = null
        set owner = null
    endfunction

    private function Init takes nothing returns nothing
        set active = Table.create()
        call RegisterSpellEffectEvent(WeaponProfileGetFireAbility(WEAPON_PROFILE_THUNDER_SHOT), function OnEffect)
    endfunction

endlibrary
