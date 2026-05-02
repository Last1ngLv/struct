library LoadoutIronLizard initializer Init requires TimerUtils, SpellIndex, Missile, RegisterPlayerUnitEvent, WeaponProfileConfig, WaveDamageCredit, Table, WeaponInventoryCore

    globals
        private constant real MISSILE_START_Z = 45.00
        private constant real MISSILE_COLLISION = 72.00
        private constant real MISSILE_FORWARD_OFFSET = 96.00
        private constant real LIZARD_RANGE = 3000.00
        private constant integer LIZARD_MAX_BOUNCES = 4
        private constant string IMPACT_ATTACH = "origin"
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC

        private Table active

        private real array castAngle
        private real array castTargetX
        private real array castTargetY

        private real array lizardDamage
        private integer array lizardBouncesLeft
        private unit array lizardSource
        private player array lizardOwner
    endglobals

    private function GetSafeFireInterval takes nothing returns real
        local real duration = WeaponProfileGetCastDuration(WEAPON_PROFILE_IRON_LIZARD)
        local integer count = WeaponProfileGetCastCount(WEAPON_PROFILE_IRON_LIZARD)
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

    private function ShowIronImpact takes unit target returns nothing
        local effect fx = AddSpecialEffectTarget(WeaponProfileGetMissileModel(WEAPON_PROFILE_IRON_LIZARD), target, IMPACT_ATTACH)
        call DestroyEffect(fx)
        set fx = null
    endfunction

    private function BounceIronLizard takes Missile missile, real normalX, real normalY returns boolean
        local real newAngle
        if lizardBouncesLeft[missile] <= 0 then
            return true
        endif
        set lizardBouncesLeft[missile] = lizardBouncesLeft[missile] - 1
        set newAngle = 2.00*Atan2(normalY - missile.y, normalX - missile.x) + bj_PI - missile.angle
        call missile.impact.move(missile.x + LIZARD_RANGE*Cos(newAngle), missile.y + LIZARD_RANGE*Sin(newAngle), MISSILE_START_Z)
        call missile.bounce()
        call missile.flushHitWidgets()
        set missile.recycle = false
        return false
    endfunction

    private struct IronLizardCore extends array
        private static method onCollide takes Missile missile, unit hit returns boolean
            if not FilterUnits(hit, lizardOwner[missile]) then
                return false
            endif
            call DamageUnit(lizardSource[missile], hit, lizardDamage[missile])
            call ShowIronImpact(hit)
            return false
        endmethod

        private static method onDestructable takes Missile missile, destructable hit returns boolean
            return false
        endmethod

        private static method onTerrain takes Missile missile returns boolean
            return BounceIronLizard(missile, missile.prevX, missile.prevY)
        endmethod

        private static method onFinish takes Missile missile returns boolean
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            set lizardDamage[missile] = 0.00
            set lizardBouncesLeft[missile] = 0
            set lizardSource[missile] = null
            set lizardOwner[missile] = null
            call SpellIndex(missile.data).destroy()
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function LaunchIronLizard takes unit source, player owner, real angle returns nothing
        local real x = GetUnitX(source) + MISSILE_FORWARD_OFFSET*Cos(angle)
        local real y = GetUnitY(source) + MISSILE_FORWARD_OFFSET*Sin(angle)
        local Missile missile = Missile.create(x, y, MISSILE_START_Z, angle, LIZARD_RANGE, MISSILE_START_Z)
        local SpellIndex dex = SpellIndex.create()

        set dex.source = source
        set dex.user = owner
        set missile.source = source
        set missile.owner = owner
        set missile.data = dex
        set missile.model = WeaponProfileGetTierMissileModel(WEAPON_PROFILE_IRON_LIZARD, 1)
        set missile.scale = WeaponProfileGetMissileScale(WEAPON_PROFILE_IRON_LIZARD)
        set missile.collision = MISSILE_COLLISION
        call missile.setMovementSpeed(WeaponProfileGetMissileSpeed(WEAPON_PROFILE_IRON_LIZARD))

        set lizardDamage[missile] = WeaponProfileGetDamage(WEAPON_PROFILE_IRON_LIZARD)
        set lizardBouncesLeft[missile] = LIZARD_MAX_BOUNCES
        set lizardSource[missile] = source
        set lizardOwner[missile] = owner

        call IronLizardCore.launch(missile)
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
        if not WeaponInventoryConsumeShotForProfile(dex.user, WEAPON_PROFILE_IRON_LIZARD) then
            return
        endif
        call SetUnitAnimation(dex.source, "attack")
        call LaunchIronLizard(dex.source, dex.user, castAngle[dex])
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

    function LoadoutIronLizardFire takes unit source, player owner, real tx, real ty returns boolean
        local integer id = GetHandleId(source)
        local real duration = WeaponProfileGetCastDuration(WEAPON_PROFILE_IRON_LIZARD)
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
        call LoadoutIronLizardFire(source, owner, GetSpellTargetX(), GetSpellTargetY())
        set source = null
        set owner = null
    endfunction

    private function Init takes nothing returns nothing
        set active = Table.create()
        call RegisterSpellEffectEvent(WeaponProfileGetFireAbility(WEAPON_PROFILE_IRON_LIZARD), function OnEffect)
    endfunction

endlibrary
