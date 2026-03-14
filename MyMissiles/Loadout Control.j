//TESH.scrollpos=0
//TESH.alwaysfold=0
library LoadoutControl initializer Init uses SpellIndex, Missile, PlayerMissileLoadout, IsUnitChanneling, DamageTextUtil, LoadoutOrbBalance, LoadoutIntFullManaSwapNew, Table
//******************************************************************************
// Shotgun-style burst spell that reuses LoadoutMissile orb behavior.
//******************************************************************************
    globals
        private constant integer LOADOUT_CONTROL_SPELL = 'U0A3' //* Configure rawcode.

        //* Rapid Fire options.
        private constant real FIRE_DURATION = 1.0
        //private constant real FIRE_INTERVAL = FIRE_DURATION/(shots-1)
        private constant string CAST_ANIMATION = "attack"
        private constant real FIRST_ANIMATION_DELAY = 0.03
        private constant real RAPID_FIRE_ANIMATION_TIME_SCALE = 5.25
        private constant real ANIMATION_TIME_SCALE_ON_END = 4.00

        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC

        private constant integer BURST_COUNT = 2
        private constant real BURST_SPREAD_DEG = 10.
        private constant real MISSILE_START_Z = 75.
        private constant real BASE_MISSILE_SPEED = 1250.
        private constant real MIN_MISSILE_SPEED = 1.
        private constant real SHOT_DISTANCE = 550.
        private constant real MISSILE_COLLISION = 96.
        private constant real MISSILE_SCALE = 1.00
        private constant real BASE_DAMAGE_MULT = 1.25
        private constant string BASE_MISSILE_MODEL = "Abilities\\Weapons\\Bolt\\BoltImpact.mdl"
        private constant string WRAP_ATTACH_POINT = "origin"

        private constant integer CRIT_TEXT_R = 255
        private constant integer CRIT_TEXT_G = 0
        private constant integer CRIT_TEXT_B = 0
        private constant integer DARK_TEXT_R = 170
        private constant integer DARK_TEXT_G = 80
        private constant integer DARK_TEXT_B = 255
        private constant integer FIRE_TEXT_R = 255
        private constant integer FIRE_TEXT_G = 145
        private constant integer FIRE_TEXT_B = 40
        private constant integer POISON_TEXT_R = 60
        private constant integer POISON_TEXT_G = 255
        private constant integer POISON_TEXT_B = 60
        private constant integer RAY_TEXT_R = 70
        private constant integer RAY_TEXT_G = 170
        private constant integer RAY_TEXT_B = 255
        private constant integer WIND_TEXT_R = 255
        private constant integer WIND_TEXT_G = 225
        private constant integer WIND_TEXT_B = 40
        private constant string POISON_DOT_FX = "Abilities\\Spells\\NightElf\\shadowstrike\\shadowstrike.mdl"
        private constant string POISON_DOT_FX_ATTACH = "head"
    endglobals

    globals
        private integer array specialAbility
        private real array storedDamage
        private integer array effectInstances
        private integer array rayHitsLeft
        private boolean array bonusActive
        private effect array overlayFx
        private effect array poisonFx
        private timer array delayedAnimTimer

        //* Rapid fire state.
        private Table active
        private real array aim
    endglobals

    private keyword ControlCore

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
        return UnitDamageTarget(source, target, amount, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
    endfunction

    private function DamageArea takes unit source, player owner, real x, real y, real radius, real amount returns nothing
        local unit u
        if amount <= 0. or GetUnitTypeId(source) == 0 then
            return
        endif
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, radius, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if FilterUnits(u, owner) then
                call UnitDamageTarget(source, u, amount, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
            endif
        endloop
        set u = null
    endfunction

    private function OnPoisonTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        if (dex.count <= 0) or (GetUnitTypeId(dex.target) == 0) or (not UnitAlive(dex.target)) or (GetUnitTypeId(dex.source) == 0) then
            if poisonFx[dex] != null then
                call DestroyEffect(poisonFx[dex])
                set poisonFx[dex] = null
            endif
            call ReleaseTimer(t)
            call dex.destroy()
            set t = null
            return
        endif

        call UnitDamageTarget(dex.source, dex.target, dex.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
        call ShowCustomLoadoutText(dex.target, "-" + FormatLoadoutDamageText(dex.damage), POISON_TEXT_R, POISON_TEXT_G, POISON_TEXT_B)
        set dex.count = dex.count - 1
        if dex.count <= 0 then
            if poisonFx[dex] != null then
                call DestroyEffect(poisonFx[dex])
                set poisonFx[dex] = null
            endif
            call ReleaseTimer(t)
            call dex.destroy()
        endif
        set t = null
    endfunction

    private function ApplyPoison takes unit source, unit target, real damagePerSecond, real duration returns nothing
        local SpellIndex dex
        local integer ticks
        local real covered
        if (GetUnitTypeId(source) == 0) or (GetUnitTypeId(target) == 0) then
            return
        endif
        if damagePerSecond <= 0. or duration <= 0. or LOADOUT_ORB_POISON_TICK_INTERVAL <= 0. then
            return
        endif
        set ticks = R2I(duration/LOADOUT_ORB_POISON_TICK_INTERVAL)
        set covered = I2R(ticks)*LOADOUT_ORB_POISON_TICK_INTERVAL
        if covered < duration then
            set ticks = ticks + 1
        endif
        if ticks < 1 then
            set ticks = 1
        endif
        set dex = SpellIndex.create()
        set dex.source = source
        set dex.target = target
        set dex.damage = damagePerSecond
        if (POISON_DOT_FX != null) and (POISON_DOT_FX != "") then
            set poisonFx[dex] = AddSpecialEffectTarget(POISON_DOT_FX, target, POISON_DOT_FX_ATTACH)
        else
            set poisonFx[dex] = null
        endif

        call UnitDamageTarget(source, target, damagePerSecond, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
        call ShowCustomLoadoutText(target, FormatLoadoutDamageText(damagePerSecond), POISON_TEXT_R, POISON_TEXT_G, POISON_TEXT_B)

        set dex.count = ticks
        call TimerStart(NewTimerEx(dex), LOADOUT_ORB_POISON_TICK_INTERVAL, true, function OnPoisonTick)
    endfunction

    private struct ControlCore extends array
        private static method onCollide takes Missile missile, unit hit returns boolean
            local real baseDamage = storedDamage[missile]
            local real finalDamage = baseDamage
            local real extraDamage = 0.
            local real radius
            local boolean wasAlive
            local real bloodMult
            local integer remaining
            local integer bloodPct
            local integer inst = effectInstances[missile]
            local integer abil = specialAbility[missile]

            if not FilterUnits(hit, missile.owner) then
                return false
            endif

            if not bonusActive[missile] then
                call DamageUnit(missile.source, hit, baseDamage)
                return true
            endif

            if abil == LOADOUT_ORB_ABILITY_RAY then
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, baseDamage)
                if rayHitsLeft[missile] > 0 then
                    set remaining = rayHitsLeft[missile]
                    call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(baseDamage) + "/[" + I2S(remaining) + "]", RAY_TEXT_R, RAY_TEXT_G, RAY_TEXT_B)
                    if wasAlive and UnitAlive(hit) then
                        set rayHitsLeft[missile] = rayHitsLeft[missile] - 1
                    endif
                    return false
                endif
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(baseDamage) + "/[0]", RAY_TEXT_R, RAY_TEXT_G, RAY_TEXT_B)
                return true
            elseif abil == LOADOUT_ORB_ABILITY_FIRE then
                set finalDamage = LoadoutGetFireDamage(baseDamage, inst)
                call DamageUnit(missile.source, hit, finalDamage)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage), FIRE_TEXT_R, FIRE_TEXT_G, FIRE_TEXT_B)
                return true
            elseif abil == LOADOUT_ORB_ABILITY_POISON then
                call ApplyPoison(missile.source, hit, LoadoutGetPoisonTickDamage(baseDamage), LoadoutGetPoisonDuration(inst))
                return true
            elseif abil == LOADOUT_ORB_ABILITY_WIND then
                set radius = LoadoutGetWindAoe(inst)
                set finalDamage = LoadoutGetWindDamage(baseDamage)
                call DamageArea(missile.source, missile.owner, missile.x, missile.y, radius, finalDamage)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage) + "/[" + FormatLoadoutDamageText(radius) + "]", WIND_TEXT_R, WIND_TEXT_G, WIND_TEXT_B)
                return true
            elseif abil == LOADOUT_ORB_ABILITY_DARK then
                set extraDamage = LoadoutGetDarkBonus(hit, inst)
                set finalDamage = baseDamage + extraDamage
                call DamageUnit(missile.source, hit, finalDamage)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage), DARK_TEXT_R, DARK_TEXT_G, DARK_TEXT_B)
                return true
            elseif abil == LOADOUT_ORB_ABILITY_BLOOD then
                set bloodMult = LoadoutGetBloodRandomMultiplier(inst)
                set finalDamage = baseDamage*bloodMult
                set bloodPct = LoadoutBloodMultiplierToPercent(bloodMult)
                call DamageUnit(missile.source, hit, finalDamage)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage) + "   //" + I2S(bloodPct) + "%", CRIT_TEXT_R, CRIT_TEXT_G, CRIT_TEXT_B)
                return true
            endif

            call DamageUnit(missile.source, hit, baseDamage)
            return true
        endmethod

        private static method onFinish takes Missile missile returns boolean
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            if overlayFx[missile] != null then
                call DestroyEffect(overlayFx[missile])
            endif
            set overlayFx[missile] = null
            set specialAbility[missile] = 0
            set storedDamage[missile] = 0.
            set effectInstances[missile] = 0
            set rayHitsLeft[missile] = 0
            set bonusActive[missile] = false
            call SpellIndex(missile.data).destroy()
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function LaunchBurstMissile takes unit source, player owner, real x, real y, real angle, integer chosen, boolean burstBonus, real damage, integer instances, string baseModel, string wrapModel returns nothing
        local SpellIndex mDex = SpellIndex.create()
        local Missile missile = Missile.create(x, y, MISSILE_START_Z, angle, SHOT_DISTANCE, MISSILE_START_Z)
        local real speed = BASE_MISSILE_SPEED + GetPlayerMissileSpeedBonus(owner)

        if speed < MIN_MISSILE_SPEED then
            set speed = MIN_MISSILE_SPEED
        endif
        set mDex.source = source
        set mDex.user = owner
        set missile.source = source
        set missile.owner = owner
        set missile.data = mDex
        set missile.model = baseModel
        set missile.scale = MISSILE_SCALE
        set missile.collision = MISSILE_COLLISION
        call missile.setMovementSpeed(speed)

        set specialAbility[missile] = chosen
        set storedDamage[missile] = damage
        set effectInstances[missile] = instances
        set rayHitsLeft[missile] = LoadoutGetRayPierce(instances)
        set bonusActive[missile] = burstBonus

        if burstBonus and (wrapModel != null) and (wrapModel != "") then
            set overlayFx[missile] = AddSpecialEffectTarget(wrapModel, missile.dummy, WRAP_ATTACH_POINT)
        else
            set overlayFx[missile] = null
        endif

        call ControlCore.launch(missile)
    endfunction

    private function FireBurst takes SpellIndex dex returns nothing
        local unit source = dex.source
        local player owner = dex.user
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real baseAngle = aim[dex]
        local string baseModel = GetPlayerMissileModelPath(owner)
        local string wrapModel = GetPlayerMissileOverlayModelPath(owner)
        local real damage = GetPlayerMissileDamageValue(owner)*BASE_DAMAGE_MULT
        local integer instances = GetPlayerMissileInstanceCount(owner)
        local integer chosen = GetPlayerMissileAbilityChoice(owner)
        local integer chosenLevel = 0
        local boolean burstBonus
        local integer i = 0
        local real mid
        local real angle

        if GetUnitTypeId(source) == 0 then
            set source = null
            set owner = null
            return
        endif

        if chosen != 0 then
            set chosenLevel = GetUnitAbilityLevel(source, chosen)
        endif
        set burstBonus = (chosen != 0) and (chosenLevel > 0) and (chosenLevel < 5)
        if burstBonus then
            call LoadoutIntFullMana(source, chosen)
        endif

        if instances < 1 then
            set instances = 1
        endif
        if damage < 0. then
            set damage = 0.
        endif
        if (baseModel == null) or (baseModel == "") then
            set baseModel = BASE_MISSILE_MODEL
        endif

        set mid = (I2R(BURST_COUNT) - 1.)*0.5
        loop
            exitwhen i >= BURST_COUNT
            set angle = baseAngle + ((I2R(i) - mid)*BURST_SPREAD_DEG)*bj_DEGTORAD
            call LaunchBurstMissile(source, owner, x, y, angle, chosen, burstBonus, damage, instances, baseModel, wrapModel)
            set i = i + 1
        endloop
        set source = null
        set owner = null
    endfunction

    private function Cleanup takes SpellIndex dex returns nothing
        local integer id = GetHandleId(dex.source)
        if active.has(id) and (active[id] == dex) then
            call active.remove(id)
        endif
        if GetUnitTypeId(dex.source) != 0 then
            call SetUnitTimeScale(dex.source, ANIMATION_TIME_SCALE_ON_END)
        endif
        if delayedAnimTimer[dex] != null then
            call ReleaseTimer(delayedAnimTimer[dex])
            set delayedAnimTimer[dex] = null
        endif
        set aim[dex] = 0.
        call ReleaseTimer(dex.clock)
        call dex.destroy()
    endfunction

    private function DelayedStartAnimation takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit source = dex.source
        local integer id
        set delayedAnimTimer[dex] = null
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

    private function OnPeriodic takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)

        if (GetUnitTypeId(dex.source) == 0) or (not UnitAlive(dex.source)) or (not IsUnitChanneling(dex.source)) or (dex.phase < 0) then
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
        call FireBurst(dex)
        set dex.time = dex.time - FIRE_DURATION/(GetPlayerShortWeaponInterval(GetOwningPlayer(dex.source))+1)

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

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        local integer id = GetHandleId(source)
        local SpellIndex dex
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)

        if active.has(id) then
            call Cleanup(active[id])
        endif

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = owner
        set dex.time = FIRE_DURATION
        set dex.phase = 1
        set dex.clock = NewTimerEx(dex)
        set aim[dex] = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set active[id] = dex

        call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
        set delayedAnimTimer[dex] = NewTimerEx(dex)
        call TimerStart(delayedAnimTimer[dex], FIRST_ANIMATION_DELAY, false, function DelayedStartAnimation)
        call FireBurst(dex)
        set dex.time = dex.time - FIRE_DURATION/(GetPlayerShortWeaponInterval(GetOwningPlayer(source))+1)

        if dex.time > 0. then
            call TimerStart(dex.clock, FIRE_DURATION/(GetPlayerShortWeaponInterval(GetOwningPlayer(source))+1), true, function OnPeriodic)
        else
            call Cleanup(dex)
        endif

        set source = null
        set owner = null
    endfunction

    private function Init takes nothing returns nothing
        set active = Table.create()
        call RegisterSpellEffectEvent(LOADOUT_CONTROL_SPELL, function OnEffect)
        //call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    endfunction
endlibrary
