//TESH.scrollpos=0
//TESH.alwaysfold=0
library LunarSlash initializer Init uses SpellIndex /* v1.0
*************************************************************************************
*
*   Instant melee slash in a crescent-shaped frontal area.
*   Enters a short rapid-fire sequence:
*       - Fires slashes every RAPID_FIRE_INTERVAL for RAPID_FIRE_DURATION.
*       - Next ticks can scale area and damage.
*   Sequence is canceled if the caster moves or issues another order.
*   Deals bonus damage at the outer edge.
*
*************************************************************************************/
//** 
//*  User settings:
//*  ==============
    globals
        private constant integer LUNAR_SLASH_ABILITY = 'A010'
        //* Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        //* Rapid fire options.
        private constant real RAPID_FIRE_DURATION = 1.20
        private constant real RAPID_FIRE_INTERVAL = 0.40
        private constant real CANCEL_MOVE_DISTANCE = 12.
        //* Arc shape options.
        private constant real CONE_ANGLE_DEGREES = 130.
        private constant real NEXT_TICK_EXTRA_ANGLE_DEGREES = 12.
        private constant real INNER_RADIUS = 70.
        private constant real OUTER_EDGE_START_FACTOR = 0.70
        private constant real OUTER_EDGE_BONUS_DAMAGE_FACTOR = 0.35
        //* Tick scaling options.
        private constant real NEXT_TICK_EXTRA_RADIUS = 24.
        private constant real NEXT_TICK_EXTRA_DAMAGE = 16.
        private constant real NEXT_TICK_EXTRA_DAMAGE_PER_LEVEL = 8.
        //* Effect options.
        private constant string CAST_FX = "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl"
        private constant string CAST_FX_ATTACH_POINT = "weapon"
        private constant string ARC_FX = "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl"
        private constant string HIT_FX = "Abilities\\Spells\\NightElf\\FanOfKnives\\FanOfKnivesMissile.mdl"
        private constant string HIT_FX_ATTACH_POINT = "chest"
        private constant string SLASH_ANIMATION = "attack"
    endglobals

    //* Set arc radius.
    private function GetOuterRadius takes integer level returns real
        return 240. + 35.*level
    endfunction
    //* Set base damage.
    private function GetBaseDamage takes integer level returns real
        return 45. + 45.*level
    endfunction
    //* Scale radius for following rapid-fire ticks.
    private function GetTickOuterRadius takes integer level, integer tick returns real
        return GetOuterRadius(level) + (tick - 1)*NEXT_TICK_EXTRA_RADIUS
    endfunction
    //* Scale base damage for following rapid-fire ticks.
    private function GetTickBaseDamage takes integer level, integer tick returns real
        return GetBaseDamage(level) + (tick - 1)*(NEXT_TICK_EXTRA_DAMAGE + NEXT_TICK_EXTRA_DAMAGE_PER_LEVEL*level)
    endfunction
    //* Scale cone angle for following rapid-fire ticks.
    private function GetTickConeHalfAngle takes integer tick returns real
        return (CONE_ANGLE_DEGREES + (tick - 1)*NEXT_TICK_EXTRA_ANGLE_DEGREES)*.5*bj_DEGTORAD
    endfunction
    //* Set how many visual points are used for the crescent effect.
    private function GetArcEffectCount takes integer level returns integer
        return 7
    endfunction
    //* Filter valid targets.
    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
    endfunction

//========================================================================
//* Lunar slash code. Make changes carefully.
//========================================================================

    globals
        private Table active
        private real array startX
        private real array startY
        private real array facing
    endglobals

    private function AbsReal takes real r returns real
        if r < 0. then
            return -r
        endif
        return r
    endfunction

    private function AngleDiff takes real a, real b returns real
        local real d = a - b
        if d > bj_PI then
            set d = d - 2.*bj_PI
        elseif d < -bj_PI then
            set d = d + 2.*bj_PI
        endif
        return AbsReal(d)
    endfunction

    private function IsInLunarArc takes unit u, real x, real y, real facing, real halfAngle, real innerSq, real outerSq returns boolean
        local real dx = GetUnitX(u) - x
        local real dy = GetUnitY(u) - y
        local real sq = dx*dx + dy*dy
        if (sq < innerSq) or (sq > outerSq) then
            return false
        endif
        return AngleDiff(Atan2(dy, dx), facing) <= halfAngle
    endfunction

    private function RunArcEffects takes real x, real y, real facing, real outerRadius, integer count, real halfAngle returns nothing
        local integer i = 0
        local real step
        local real a = facing - halfAngle
        local real px
        local real py
        if count < 1 then
            return
        endif
        set step = (2.*halfAngle)/count
        loop
            exitwhen i > count
            set px = x + outerRadius*Cos(a)
            set py = y + outerRadius*Sin(a)
            call DestroyEffect(AddSpecialEffect(ARC_FX, px, py))
            set a = a + step
            set i = i + 1
        endloop
    endfunction

    private function DoSlashTick takes SpellIndex dex returns nothing
        local integer tick = dex.count + 1
        local unit source = dex.source
        local player owner = dex.user
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real outerRadius = GetTickOuterRadius(dex.level, tick)
        local real outerSq = outerRadius*outerRadius
        local real innerSq = INNER_RADIUS*INNER_RADIUS
        local real edgeStart = outerRadius*OUTER_EDGE_START_FACTOR
        local real edgeStartSq = edgeStart*edgeStart
        local real halfAngle = GetTickConeHalfAngle(tick)
        local real baseDamage = GetTickBaseDamage(dex.level, tick)
        local real bonusDamage = baseDamage*OUTER_EDGE_BONUS_DAMAGE_FACTOR
        local unit u
        local real dx
        local real dy
        local real sq
        call SetUnitAnimation(source, SLASH_ANIMATION)
        call DestroyEffect(AddSpecialEffectTarget(CAST_FX, source, CAST_FX_ATTACH_POINT))
        call RunArcEffects(x, y, facing[dex], outerRadius, GetArcEffectCount(dex.level), halfAngle)
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, outerRadius, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if FilterUnits(u, owner) and IsInLunarArc(u, x, y, facing[dex], halfAngle, innerSq, outerSq) then
                set dx = GetUnitX(u) - x
                set dy = GetUnitY(u) - y
                set sq = dx*dx + dy*dy
                if sq >= edgeStartSq then
                    call UnitDamageTarget(source, u, baseDamage + bonusDamage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                else
                    call UnitDamageTarget(source, u, baseDamage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                endif
                call DestroyEffect(AddSpecialEffectTarget(HIT_FX, u, HIT_FX_ATTACH_POINT))
            endif
        endloop
        set dex.count = tick
    endfunction

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
        set startX[dex] = 0.
        set startY[dex] = 0.
        set facing[dex] = 0.
        call ReleaseTimer(dex.clock)
        call dex.destroy()
    endfunction

    private function OnPeriodic takes nothing returns nothing
        local SpellIndex dex = GetTimerData(GetExpiredTimer())
        if (GetUnitTypeId(dex.source) == 0) or (not UnitAlive(dex.source)) or (dex.phase < 0) or IsCanceledByMovement(dex) then
            call Cleanup(dex)
            return
        endif
        if dex.time <= 0. then
            call Cleanup(dex)
            return
        endif
        call DoSlashTick(dex)
        set dex.time = dex.time - RAPID_FIRE_INTERVAL
        if dex.time <= 0. then
            call Cleanup(dex)
        endif
    endfunction

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local integer id = GetHandleId(source)
        local SpellIndex dex = SpellIndex.create()
        if active.has(id) then
            call Cleanup(active[id])
        endif
        set dex.source = source
        set dex.user = GetTriggerPlayer()
        set dex.level = GetUnitAbilityLevel(source, LUNAR_SLASH_ABILITY)
        set dex.time = RAPID_FIRE_DURATION
        set dex.count = 0
        set dex.phase = 1
        set dex.clock = NewTimerEx(dex)
        set startX[dex] = GetUnitX(source)
        set startY[dex] = GetUnitY(source)
        set facing[dex] = Atan2(GetSpellTargetY() - GetUnitY(source), GetSpellTargetX() - GetUnitX(source))
        set active[id] = dex
        //* First slash immediately.
        call DoSlashTick(dex)
        set dex.time = dex.time - RAPID_FIRE_INTERVAL
        if dex.time > 0. then
            call TimerStart(dex.clock, RAPID_FIRE_INTERVAL, true, function OnPeriodic)
        else
            call Cleanup(dex)
        endif
        set source = null
    endfunction

    private function MarkCanceled takes unit whichUnit returns nothing
        local integer id = GetHandleId(whichUnit)
        if active.has(id) then
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

    private function Init takes nothing returns nothing
        set active = Table.create()
        call RegisterSpellEffectEvent(LUNAR_SLASH_ABILITY, function OnEffect)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    endfunction
endlibrary
