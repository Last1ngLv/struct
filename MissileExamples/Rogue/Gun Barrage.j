//TESH.scrollpos=93
//TESH.alwaysfold=0
library GunBarrage initializer Init uses SpellIndex, Missile, IsDestructableTree /* v1.1
*************************************************************************************
*
*   Instant cast.
*   Plays a custom animation and fires projectiles for a short duration.
*   Firing is canceled if the caster moves or issues another order.
*   Next ticks can scale area/damage progressively. 
*   Extra options:
*       - Optional fixed missile lifetime.
*       - Optional tree and uphill-cliff collision.
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer GUN_BARRAGE_ABILITY = 'S00A'
        //* Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        private constant boolean DAMAGE_IN_AOE = true
        private constant real AOE_DAMAGE_RADIUS = 75.
        private constant boolean AOE_CENTER_ON_HIT_UNIT = true
        //* Firing behavior.
        private constant real FIRE_DURATION = 1.20
        private constant real FIRE_INTERVAL = 0.20
        private constant real CANCEL_MOVE_DISTANCE = 12.
        //* Visual and animation options.
        private constant string CAST_ANIMATION = "attack"
        private constant real FIRST_ANIMATION_DELAY = 0.03
        private constant real RAPID_FIRE_ANIMATION_TIME_SCALE = 3.25
        private constant real ANIMATION_TIME_SCALE_ON_END = 1.00
        private constant string MUZZLE_FX = "Abilities\\Weapons\\Bolt\\BoltImpact.mdl"
        private constant string MUZZLE_ATTACH_POINT = "weapon"
        private constant string ON_HIT_FX = "war3mapImported\\Reaper's Claws Blue.mdl" //"Abilities\\Weapons\\Bolt\\BoltImpact.mdl"
        private constant string ON_HIT_FX_ATTACH_POINT = "chest"
        private constant string ON_DEATH_FX = "war3mapImported\\Reaper's Claws Blue.mdl"
        private constant string Missile_ORIGIN = "origin"
        //* Missile options.
        private constant real SHOT_FLY_HEIGHT = 65.
        private constant real MISSILE_DURATION = 0.25 //* 0.00 = normal speed/distance behavior.
        private constant real SHOT_MISSILE_SPEED = 26. // if have duration this it was disable
        private constant string SHOT_MISSILE_MODEL = "war3mapImported\\Reaper's Claws Blue.mdl"
        private constant real SHOT_MISSILE_SCALE = 0.95
        private constant boolean KILL_ON_UPHILL_CLIFF = true
        private constant boolean KILL_ON_TREE_COLLISION = true
        private constant boolean DESTROY_TREE_ON_COLLISION = false
        private constant real BASE_SHOT_COLLISION = 150.
        private constant real NEXT_TICK_EXTRA_COLLISION = 0.
        private constant real NEXT_TICK_EXTRA_DAMAGE = 10.
        private constant real NEXT_TICK_EXTRA_DAMAGE_PER_LEVEL = 5.
    endglobals

    //* Set projectile travel distance.
    private function GetFlyDistance takes integer level returns real
        return 150. + 100.*level
    endfunction
    //* Set damage per projectile.
    private function GetShotDamage takes integer level returns real
        return 25. + 20.*level
    endfunction
    //*  Set area scaling by shot index in the same rapid-fire window.
    private function GetShotCollision takes integer level, integer shotIndex returns real
        if (shotIndex <= 1) then
            return BASE_SHOT_COLLISION
        endif
        return BASE_SHOT_COLLISION + (shotIndex - 1)*NEXT_TICK_EXTRA_COLLISION
    endfunction
    //*  Set bonus damage scaling by shot index in the same rapid-fire window.
    private function GetShotBonusDamage takes integer level, integer shotIndex returns real
        if (shotIndex <= 1) then
            return 0.
        endif
        return (shotIndex - 1)*(NEXT_TICK_EXTRA_DAMAGE + NEXT_TICK_EXTRA_DAMAGE_PER_LEVEL*level)
    endfunction
    //* Filter valid targets.
    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
    endfunction
    //* Deal optional area damage around impact.
    private function DealAreaDamage takes Missile missile, real x, real y returns nothing
        local unit u
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, AOE_DAMAGE_RADIUS, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if FilterUnits(u, missile.owner) then
                call UnitDamageTarget(missile.source, u, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                if ON_HIT_FX != "" then
                    call DestroyEffect(AddSpecialEffectTarget(ON_HIT_FX, u, ON_HIT_FX_ATTACH_POINT))
                endif
            endif
        endloop
    endfunction
    //* Customize projectile options.
    private function CustomizeMissile takes Missile missile, integer level, integer shotIndex returns nothing
        if (MISSILE_DURATION > 0.) then
            call missile.flightTime2Speed(MISSILE_DURATION)
        else
            set missile.speed = SHOT_MISSILE_SPEED
        endif
        set missile.damage = GetShotDamage(level) + GetShotBonusDamage(level, shotIndex)
        set missile.collision = GetShotCollision(level, shotIndex)
        set missile.model = SHOT_MISSILE_MODEL
        set missile.scale = SHOT_MISSILE_SCALE
    endfunction

//========================================================================
//* Gun barrage code. Make changes carefully.
//========================================================================

    globals
        private Table active
        private real array startX
        private real array startY
        private real array aim
        private integer array startCliff
    endglobals

    //* Missile behavior for each bullet.
    private struct GunBullet extends array
        private static method onRemove takes Missile missile returns boolean
            if ON_DEATH_FX != "" then
                call DestroyEffect(AddSpecialEffectTarget(ON_DEATH_FX, missile.dummy, Missile_ORIGIN))
            endif
            set startCliff[missile] = 0
            return true
        endmethod

        private static method onCollide takes Missile missile, unit hit returns boolean
            if FilterUnits(hit, missile.owner) then
                if DAMAGE_IN_AOE then
                    if AOE_CENTER_ON_HIT_UNIT then
                        call DealAreaDamage(missile, GetUnitX(hit), GetUnitY(hit))
                    else
                        call DealAreaDamage(missile, missile.x, missile.y)
                    endif
                else
                    call UnitDamageTarget(missile.source, hit, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                    if ON_HIT_FX != "" then
                        call DestroyEffect(AddSpecialEffectTarget(ON_HIT_FX, hit, ON_HIT_FX_ATTACH_POINT))
                    endif
                endif
                return true
            endif
            return false
        endmethod

        private static method onDestructable takes Missile missile, destructable hit returns boolean
            if KILL_ON_TREE_COLLISION and IsDestructableTree(hit) and (GetWidgetLife(hit) > .405) then
                if DESTROY_TREE_ON_COLLISION then
                    call KillDestructable(hit)
                endif
                return true
            endif
            return false
        endmethod

        private static method onPeriod takes Missile missile returns boolean
            if KILL_ON_UPHILL_CLIFF and (GetTerrainCliffLevel(missile.x, missile.y) > startCliff[missile]) then
                return true
            endif
            return false
        endmethod

        implement MissileStruct
    endstruct

    private function IsCanceledByMovement takes SpellIndex dex returns boolean
        local real dx = GetUnitX(dex.source) - startX[dex]
        local real dy = GetUnitY(dex.source) - startY[dex]
        return (dx*dx + dy*dy) > (CANCEL_MOVE_DISTANCE*CANCEL_MOVE_DISTANCE)
    endfunction

    private function Cleanup takes SpellIndex dex returns nothing
        local integer id = GetHandleId(dex.source)
        if active.has(id) and (active[id] == dex) then
            call active.remove(id)
        endif
        if (GetUnitTypeId(dex.source) != 0) then
            call SetUnitTimeScale(dex.source, ANIMATION_TIME_SCALE_ON_END)
        endif
        set startX[dex] = 0.
        set startY[dex] = 0.
        set aim[dex] = 0.
        call ReleaseTimer(dex.clock)
        call dex.destroy()
    endfunction

    private function FireBullet takes SpellIndex dex returns nothing
        local real x = GetUnitX(dex.source)
        local real y = GetUnitY(dex.source)
        local integer shotIndex = dex.count + 1
        local Missile missile = Missile.create(x, y, SHOT_FLY_HEIGHT, aim[dex], GetFlyDistance(dex.level), SHOT_FLY_HEIGHT)
        call CustomizeMissile(missile, dex.level, shotIndex)
        set missile.source = dex.source
        set missile.owner = dex.user
        set startCliff[missile] = GetTerrainCliffLevel(x, y)
        set dex.count = shotIndex
        call GunBullet.launch(missile)
        call DestroyEffect(AddSpecialEffectTarget(MUZZLE_FX, dex.source, MUZZLE_ATTACH_POINT))
    endfunction

    private function OnPeriodic takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)

        if (GetUnitTypeId(dex.source) == 0) or (not UnitAlive(dex.source)) or (dex.phase < 0) or IsCanceledByMovement(dex) then
            call Cleanup(dex)
            set t = null
            return
        endif

        if dex.time <= 0. then
            call Cleanup(dex)
            set t = null
            return
        endif

        call SetUnitAnimation(dex.source, CAST_ANIMATION)
        call FireBullet(dex)
        set dex.time = dex.time - FIRE_INTERVAL

        if dex.time <= 0. then
            call Cleanup(dex)
        endif

        set t = null
    endfunction

    private function MarkCanceled takes unit whichUnit returns nothing
        local integer id = GetHandleId(whichUnit)
        if active.has(id) then
            call SetUnitTimeScale(whichUnit, ANIMATION_TIME_SCALE_ON_END)
            set SpellIndex(active[id]).phase = -1
        endif
    endfunction

    private function OnOrder takes nothing returns nothing
        call MarkCanceled(GetTriggerUnit())
    endfunction

    private function OnPointOrder takes nothing returns nothing
        call MarkCanceled(GetTriggerUnit())
    endfunction

    private function OnTargetOrder takes nothing returns nothing
        call MarkCanceled(GetTriggerUnit())
    endfunction

    private function DelayedStartAnimation takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit source = dex.source
        local integer id
        if (GetUnitTypeId(source) != 0) and UnitAlive(source) and (dex.phase >= 0) then
            set id = GetHandleId(source)
            if active.has(id) and (active[id] == dex) then
                call SetUnitAnimation(source, CAST_ANIMATION)
            endif
        endif
        call ReleaseTimer(t)
        set source = null
        set t = null
    endfunction

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local integer id = GetHandleId(source)
        local SpellIndex dex
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)

        //* Restart cleanly if still active from previous cast.
        if active.has(id) then
            call Cleanup(active[id])
        endif

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = GetTriggerPlayer()
        set dex.level = GetUnitAbilityLevel(source, GUN_BARRAGE_ABILITY)
        set dex.time = FIRE_DURATION
        set dex.count = 0
        set dex.phase = 1
        set dex.clock = NewTimerEx(dex)

        set startX[dex] = x
        set startY[dex] = y
        set aim[dex] = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set active[id] = dex

        //* First shot immediately.
        call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
        call TimerStart(NewTimerEx(dex), FIRST_ANIMATION_DELAY, false, function DelayedStartAnimation)
        call FireBullet(dex)
        set dex.time = dex.time - FIRE_INTERVAL

        if dex.time > 0. then
            call TimerStart(dex.clock, FIRE_INTERVAL, true, function OnPeriodic)
        else
            call Cleanup(dex)
        endif

        set source = null
    endfunction

    private function Init takes nothing returns nothing
        set active = Table.create()
        call RegisterSpellEffectEvent(GUN_BARRAGE_ABILITY, function OnEffect)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    endfunction
endlibrary
