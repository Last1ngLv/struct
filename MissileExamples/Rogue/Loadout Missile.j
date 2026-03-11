//TESH.scrollpos=0
//TESH.alwaysfold=0
library PlayerMissileLoadout initializer Init uses Table /* v2.0
*************************************************************************************
*
*   Stores per-player missile loadout using player handle as key. 
*   Stored values:
*       - integer ability rawcode
*       - real speed bonus (added to base speed in missile library)
*       - real damage value
*       - integer instance count (default 1)
*       - string missile model path
*       - string missile overlay model path (extra fx wrapper)
*
*   API:
*       call SetPlayerMissileLoadout(player p, integer abilityRawcode, real speedBonus, real damageValue, integer instanceCount, string missileModelPath, string overlayModelPath)
*       call SetPlayerMissileAbilityChoice(player p, integer abilityRawcode)
*       call SetPlayerMissileSpeedBonus(player p, real speedBonus)
*       call SetPlayerMissileDamageValue(player p, real damageValue)
*       call SetPlayerMissileInstanceCount(player p, integer instanceCount)
*       call AddPlayerMissileInstanceCount(player p, integer delta)
*       call SetPlayerMissileModelPath(player p, string modelPath)
*       call SetPlayerMissileOverlayModelPath(player p, string modelPath)
*       call SetPlayerLeapCasterFx(player p, string fx1, string fx2)
*       call SetPlayerLeapDummyFx(player p, string fx1, string fx2)
*       call SetPlayerLeapDummyScale(player p, real scale)
*       call SetPlayerLeapDummyFlightOffset(player p, real offset)
*       call SetPlayerLeapCompanionUnitId(player p, integer unitId)
*       call SetPlayerLeapImpactFx(player p, string fx)
*       integer a = GetPlayerMissileAbilityChoice(player p)
*       real    s = GetPlayerMissileSpeedBonus(player p)
*       real    d = GetPlayerMissileDamageValue(player p)
*       integer i = GetPlayerMissileInstanceCount(player p)
*       string  m = GetPlayerMissileModelPath(player p)
*       string  o = GetPlayerMissileOverlayModelPath(player p)
*       string lc1 = GetPlayerLeapCasterFx1(player p)
*       string lc2 = GetPlayerLeapCasterFx2(player p)
*       string ld1 = GetPlayerLeapDummyFx1(player p)
*       string ld2 = GetPlayerLeapDummyFx2(player p)
*       real   lds = GetPlayerLeapDummyScale(player p)
*       real   ldf = GetPlayerLeapDummyFlightOffset(player p)
*       integer ldu = GetPlayerLeapCompanionUnitId(player p)
*       string li = GetPlayerLeapImpactFx(player p)
*
*************************************************************************************/
    globals
        private constant integer MAX_PLAYER_SLOTS = bj_MAX_PLAYER_SLOTS
        private constant integer DEFAULT_CHOICE_ABILITY = 'AM02'
        private constant real    DEFAULT_SPEED_BONUS = 0.
        private constant real    DEFAULT_DAMAGE_VALUE = 1.
        private constant integer DEFAULT_INSTANCE_COUNT = 1
        private constant string  DEFAULT_MODEL_PATH = "Miss\\Shot Blue.mdx"
        private constant string  DEFAULT_OVERLAY_MODEL_PATH = "Miss\\Shot II Blue.mdx"
        
        private constant string  DEFAULT_LEAP_CASTER_FX1 = ""
        private constant string  DEFAULT_LEAP_CASTER_FX2 = ""
        private constant string  DEFAULT_LEAP_DUMMY_FX1 = ""
        private constant string  DEFAULT_LEAP_DUMMY_FX2 = ""
        private constant real    DEFAULT_LEAP_DUMMY_SCALE = 0.10
        private constant real    DEFAULT_LEAP_DUMMY_FLIGHT_OFFSET = 0.00
        private constant integer DEFAULT_LEAP_COMPANION_UNIT_ID = 'dumi'
        private constant string  DEFAULT_LEAP_IMPACT_FX = "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl"

        private Table byHandle
        private integer array chosenAbility
        private real array chosenSpeedBonus
        private real array chosenDamage
        private integer array chosenInstances
        private string array chosenModelPath
        private string array chosenOverlayPath

        private string array chosenLeapCasterFx1
        private string array chosenLeapCasterFx2
        private string array chosenLeapDummyFx1
        private string array chosenLeapDummyFx2
        private real array chosenLeapDummyScale
        private real array chosenLeapDummyFlightOffset
        private integer array chosenLeapCompanionUnitId
        private string array chosenLeapImpactFx
    endglobals

    private function SlotOfPlayer takes player p returns integer
        local integer hid
        local integer slot
        if p == null then
            return 1
        endif
        set hid = GetHandleId(p)
        if byHandle.has(hid) then
            return byHandle[hid]
        endif
        set slot = GetPlayerId(p) + 1
        if slot < 1 then
            set slot = 1
        elseif slot > MAX_PLAYER_SLOTS then
            set slot = MAX_PLAYER_SLOTS
        endif
        set byHandle[hid] = slot
        return slot
    endfunction

    function SetPlayerMissileLoadout takes player p, integer abilityRawcode, real speedBonus, real damageValue, integer instanceCount, string missileModelPath, string overlayModelPath returns nothing
        local integer slot = SlotOfPlayer(p)
        if instanceCount < 1 then
            set instanceCount = 1
        endif
        set chosenAbility[slot] = abilityRawcode
        set chosenSpeedBonus[slot] = speedBonus
        set chosenDamage[slot] = damageValue
        set chosenInstances[slot] = instanceCount
        set chosenModelPath[slot] = missileModelPath
        set chosenOverlayPath[slot] = overlayModelPath
    endfunction

    function SetPlayerMissileAbilityChoice takes player p, integer abilityRawcode returns nothing
        set chosenAbility[SlotOfPlayer(p)] = abilityRawcode
    endfunction

    function SetPlayerMissileSpeedBonus takes player p, real speedBonus returns nothing
        set chosenSpeedBonus[SlotOfPlayer(p)] = speedBonus
    endfunction

    function SetPlayerMissileDamageValue takes player p, real damageValue returns nothing
        set chosenDamage[SlotOfPlayer(p)] = damageValue
    endfunction

    function SetPlayerMissileInstanceCount takes player p, integer instanceCount returns nothing
        if instanceCount < 1 then
            set instanceCount = 1
        endif
        set chosenInstances[SlotOfPlayer(p)] = instanceCount
    endfunction

    function AddPlayerMissileInstanceCount takes player p, integer delta returns nothing
        local integer slot = SlotOfPlayer(p)
        local integer value = chosenInstances[slot] + delta
        if value < 1 then
            set value = 1
        endif
        set chosenInstances[slot] = value
    endfunction

    function SetPlayerMissileModelPath takes player p, string modelPath returns nothing
        set chosenModelPath[SlotOfPlayer(p)] = modelPath
    endfunction

    function SetPlayerMissileOverlayModelPath takes player p, string modelPath returns nothing
        set chosenOverlayPath[SlotOfPlayer(p)] = modelPath
    endfunction

    function SetPlayerLeapCasterFx takes player p, string fx1, string fx2 returns nothing
        local integer slot = SlotOfPlayer(p)
        set chosenLeapCasterFx1[slot] = fx1
        set chosenLeapCasterFx2[slot] = fx2
    endfunction

    function SetPlayerLeapDummyFx takes player p, string fx1, string fx2 returns nothing
        local integer slot = SlotOfPlayer(p)
        set chosenLeapDummyFx1[slot] = fx1
        set chosenLeapDummyFx2[slot] = fx2
    endfunction

    function SetPlayerLeapDummyScale takes player p, real scale returns nothing
        if scale <= 0. then
            set scale = 0.01
        endif
        set chosenLeapDummyScale[SlotOfPlayer(p)] = scale
    endfunction

    function SetPlayerLeapDummyFlightOffset takes player p, real offset returns nothing
        set chosenLeapDummyFlightOffset[SlotOfPlayer(p)] = offset
    endfunction

    function SetPlayerLeapCompanionUnitId takes player p, integer unitId returns nothing
        if unitId == 0 then
            set unitId = DEFAULT_LEAP_COMPANION_UNIT_ID
        endif
        set chosenLeapCompanionUnitId[SlotOfPlayer(p)] = unitId
    endfunction

    function SetPlayerLeapImpactFx takes player p, string fx returns nothing
        set chosenLeapImpactFx[SlotOfPlayer(p)] = fx
    endfunction

    function GetPlayerMissileAbilityChoice takes player p returns integer
        return chosenAbility[SlotOfPlayer(p)]
    endfunction

    function GetPlayerMissileSpeedBonus takes player p returns real
        return chosenSpeedBonus[SlotOfPlayer(p)]
    endfunction

    function GetPlayerMissileDamageValue takes player p returns real
        return chosenDamage[SlotOfPlayer(p)]
    endfunction

    function GetPlayerMissileInstanceCount takes player p returns integer
        return chosenInstances[SlotOfPlayer(p)]
    endfunction

    function GetPlayerMissileModelPath takes player p returns string
        return chosenModelPath[SlotOfPlayer(p)]
    endfunction

    function GetPlayerMissileOverlayModelPath takes player p returns string
        return chosenOverlayPath[SlotOfPlayer(p)]
    endfunction

    function GetPlayerLeapCasterFx1 takes player p returns string
        return chosenLeapCasterFx1[SlotOfPlayer(p)]
    endfunction

    function GetPlayerLeapCasterFx2 takes player p returns string
        return chosenLeapCasterFx2[SlotOfPlayer(p)]
    endfunction

    function GetPlayerLeapDummyFx1 takes player p returns string
        return chosenLeapDummyFx1[SlotOfPlayer(p)]
    endfunction

    function GetPlayerLeapDummyFx2 takes player p returns string
        return chosenLeapDummyFx2[SlotOfPlayer(p)]
    endfunction

    function GetPlayerLeapDummyScale takes player p returns real
        return chosenLeapDummyScale[SlotOfPlayer(p)]
    endfunction

    function GetPlayerLeapDummyFlightOffset takes player p returns real
        return chosenLeapDummyFlightOffset[SlotOfPlayer(p)]
    endfunction

    function GetPlayerLeapCompanionUnitId takes player p returns integer
        return chosenLeapCompanionUnitId[SlotOfPlayer(p)]
    endfunction

    function GetPlayerLeapImpactFx takes player p returns string
        return chosenLeapImpactFx[SlotOfPlayer(p)]
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0
        local player p
        set byHandle = Table.create()
        loop
            exitwhen i >= MAX_PLAYER_SLOTS
            set p = Player(i)
            call SetPlayerMissileLoadout(p, DEFAULT_CHOICE_ABILITY, DEFAULT_SPEED_BONUS, DEFAULT_DAMAGE_VALUE, DEFAULT_INSTANCE_COUNT, DEFAULT_MODEL_PATH, DEFAULT_OVERLAY_MODEL_PATH)
            
            // Default Leap FX
            call SetPlayerLeapCasterFx(p, DEFAULT_LEAP_CASTER_FX1, DEFAULT_LEAP_CASTER_FX2)
            call SetPlayerLeapDummyFx(p, DEFAULT_LEAP_DUMMY_FX1, DEFAULT_LEAP_DUMMY_FX2)
            call SetPlayerLeapDummyScale(p, DEFAULT_LEAP_DUMMY_SCALE)
            call SetPlayerLeapDummyFlightOffset(p, DEFAULT_LEAP_DUMMY_FLIGHT_OFFSET)
            call SetPlayerLeapCompanionUnitId(p, DEFAULT_LEAP_COMPANION_UNIT_ID)
            call SetPlayerLeapImpactFx(p, DEFAULT_LEAP_IMPACT_FX)
            
            set i = i + 1
        endloop
        set p = null
    endfunction
endlibrary

library LoadoutOrbBalance
    globals
        constant integer LOADOUT_ORB_ABILITY_RAY = 'AM05'
        constant integer LOADOUT_ORB_ABILITY_FIRE = 'AM04'
        constant integer LOADOUT_ORB_ABILITY_POISON = 'AM02'
        constant integer LOADOUT_ORB_ABILITY_WIND = 'AM06'
        constant integer LOADOUT_ORB_ABILITY_DARK = 'AM03'
        constant integer LOADOUT_ORB_ABILITY_BLOOD = 'AM01'

        constant real LOADOUT_ORB_FIRE_DAMAGE_PERCENT_PER_INSTANCE = 0.50

        constant real LOADOUT_ORB_POISON_DURATION_PER_INSTANCE = 1.00
        constant real LOADOUT_ORB_POISON_TICK_INTERVAL = 1.00
        constant real LOADOUT_ORB_POISON_DAMAGE_MULT = 1.00

        constant real LOADOUT_ORB_WIND_BASE_AOE = 150.
        constant real LOADOUT_ORB_WIND_AOE_PER_INSTANCE = 50.
        constant real LOADOUT_ORB_WIND_BASE_DAMAGE = 0.

        constant real LOADOUT_ORB_DARK_BASE_CURRENT_HP_PERCENT = 0.00
        constant real LOADOUT_ORB_DARK_PERCENT_PER_INSTANCE = 0.01

        constant real LOADOUT_ORB_BLOOD_MIN_BASE_MULT = 1.00
        constant real LOADOUT_ORB_BLOOD_MAX_BASE_MULT = 4.00
        constant real LOADOUT_ORB_BLOOD_RANGE_PER_INSTANCE = 0.25
    endglobals

    function LoadoutClampInstance takes integer inst returns integer
        if inst < 1 then
            return 1
        endif
        return inst
    endfunction

    function LoadoutGetRayPierce takes integer inst returns integer
        return LoadoutClampInstance(inst)
    endfunction

    function LoadoutGetFireDamage takes real baseDamage, integer inst returns real
        return baseDamage*(1. + LOADOUT_ORB_FIRE_DAMAGE_PERCENT_PER_INSTANCE*LoadoutClampInstance(inst))
    endfunction

    function LoadoutGetPoisonDuration takes integer inst returns real
        return LOADOUT_ORB_POISON_DURATION_PER_INSTANCE*LoadoutClampInstance(inst)
    endfunction

    function LoadoutGetPoisonTickDamage takes real baseDamage returns real
        return baseDamage*LOADOUT_ORB_POISON_DAMAGE_MULT
    endfunction

    function LoadoutGetWindAoe takes integer inst returns real
        return LOADOUT_ORB_WIND_BASE_AOE + LOADOUT_ORB_WIND_AOE_PER_INSTANCE*LoadoutClampInstance(inst)
    endfunction

    function LoadoutGetWindDamage takes real baseDamage returns real
        return LOADOUT_ORB_WIND_BASE_DAMAGE + baseDamage
    endfunction

    function LoadoutGetDarkBonus takes unit target, integer inst returns real
        local real pct = LOADOUT_ORB_DARK_BASE_CURRENT_HP_PERCENT + LOADOUT_ORB_DARK_PERCENT_PER_INSTANCE*LoadoutClampInstance(inst)
        return GetWidgetLife(target)*pct
    endfunction

    function LoadoutGetBloodMinMultiplier takes integer inst returns real
        return LOADOUT_ORB_BLOOD_MIN_BASE_MULT + LOADOUT_ORB_BLOOD_RANGE_PER_INSTANCE*LoadoutClampInstance(inst)
    endfunction

    function LoadoutGetBloodMaxMultiplier takes integer inst returns real
        return LOADOUT_ORB_BLOOD_MAX_BASE_MULT + LOADOUT_ORB_BLOOD_RANGE_PER_INSTANCE*LoadoutClampInstance(inst)
    endfunction

    function LoadoutGetBloodRandomMultiplier takes integer inst returns real
        local real minMult = LoadoutGetBloodMinMultiplier(inst)
        local real maxMult = LoadoutGetBloodMaxMultiplier(inst)
        if maxMult < minMult then
            set maxMult = minMult
        endif
        return GetRandomReal(minMult, maxMult)
    endfunction

    function LoadoutBloodMultiplierToPercent takes real mult returns integer
        return R2I(mult*100. + 0.5)
    endfunction
endlibrary


library LoadoutMissile initializer Init uses SpellIndex, Missile, PlayerMissileLoadout, IsUnitChanneling, DamageTextUtil, LoadoutOrbBalance, LoadoutIntFullManaSwapNew /* v2.0
*************************************************************************************
*
*   Base missile behavior:
*       - Base speed: 650 + stored speed bonus.
*       - Base damage: stored real damage.
*       - Base model: stored model path (fallback to default).
*       - Ends on first collide by default.
*
*   Bonus behavior only applies if:
*       GetUnitAbilityLevel(caster, chosenAbilityRawcode) < 5 and > 0.
*
*   Supported abilities (6):
*       Ray, Fire, Poison, Wind, Dark, Blood
*
*************************************************************************************/
//**
//* User settings:
//* ==============
    globals
        private constant integer LOADOUT_MISSILE_SPELL = 'U0A1'

        //* Rapid Fire options.
        private constant real FIRE_DURATION = 1.20
        private constant real FIRE_INTERVAL = 0.10
        private constant string CAST_ANIMATION = "attack"
        private constant real FIRST_ANIMATION_DELAY = 0.03
        private constant real RAPID_FIRE_ANIMATION_TIME_SCALE = 3.25
        private constant real ANIMATION_TIME_SCALE_ON_END = 1.00

        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC

        //* Base missile defaults.
        private constant real BASE_MISSILE_SPEED = 650.
        private constant real MIN_MISSILE_SPEED = 1.
        private constant real FIXED_TRAVEL_DISTANCE = 1500.
        private constant real MISSILE_START_Z = 75.
        private constant string BASE_MISSILE_MODEL = "Miss\\Shot Blue.mdx"
        private constant real MISSILE_SCALE = 1.00
        private constant real MISSILE_COLLISION = 96.

        //* Damage text.
        private constant real DAMAGE_TEXT_SIZE = 0.020
        private constant real DAMAGE_TEXT_Z = 90.
        private constant real DAMAGE_TEXT_VY = 0.035
        private constant real DAMAGE_TEXT_LIFE = 1.00
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

        //* Optional color for wrapper overlay model if needed externally.
        private constant string WRAP_ATTACH_POINT = "origin"
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

    private keyword LoadoutCore

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
        if amount <= 0. then
            return
        endif
        if GetUnitTypeId(source) == 0 then
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
        if damagePerSecond <= 0. then
            return
        endif
        if duration <= 0. then
            return
        endif
        if LOADOUT_ORB_POISON_TICK_INTERVAL <= 0. then
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

        // Impact damage.
        call UnitDamageTarget(source, target, damagePerSecond, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
        call ShowCustomLoadoutText(target, FormatLoadoutDamageText(damagePerSecond), POISON_TEXT_R, POISON_TEXT_G, POISON_TEXT_B)

        if ticks <= 0 then
            if poisonFx[dex] != null then
                call DestroyEffect(poisonFx[dex])
                set poisonFx[dex] = null
            endif
            call dex.destroy()
            return
        endif

        set dex.count = ticks
        call TimerStart(NewTimerEx(dex), LOADOUT_ORB_POISON_TICK_INTERVAL, true, function OnPoisonTick)
    endfunction

    private struct LoadoutCore extends array
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

                // rayHitsLeft means "how many units can be pierced".
                // If the hit unit dies, do not consume a pierce slot.
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

    private function Cleanup takes SpellIndex dex returns nothing
        local integer id = GetHandleId(dex.source)
        if active.has(id) and (active[id] == dex) then
            call active.remove(id)
        endif
        if (GetUnitTypeId(dex.source) != 0) then
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

    private function FireMissile takes SpellIndex dex returns nothing
        local unit source = dex.source
        local player owner = dex.user
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real angle = aim[dex]
        local string baseModel
        local string wrapModel
        local real speed
        local real damage
        local integer instances
        local integer chosen
        local integer chosenLevel
        local SpellIndex mDex = SpellIndex.create()
        local Missile missile = Missile.create(x, y, MISSILE_START_Z, angle, FIXED_TRAVEL_DISTANCE, MISSILE_START_Z)

        set chosen = GetPlayerMissileAbilityChoice(owner)
        set chosenLevel = 0
        if chosen != 0 then
            set chosenLevel = GetUnitAbilityLevel(source, chosen)
        endif

        set speed = BASE_MISSILE_SPEED + GetPlayerMissileSpeedBonus(owner)
        if speed < MIN_MISSILE_SPEED then
            set speed = MIN_MISSILE_SPEED
        endif
        set damage = GetPlayerMissileDamageValue(owner)
        if damage < 0. then
            set damage = 0.
        endif
        set instances = GetPlayerMissileInstanceCount(owner)
        if instances < 1 then
            set instances = 1
        endif

        set baseModel = GetPlayerMissileModelPath(owner)
        if (baseModel == null) or (baseModel == "") then
            set baseModel = BASE_MISSILE_MODEL
        endif
        set wrapModel = GetPlayerMissileOverlayModelPath(owner)

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
        set rayHitsLeft[missile] = LoadoutGetRayPierce(effectInstances[missile])
        set bonusActive[missile] = (chosen != 0) and (chosenLevel > 0) and (chosenLevel < 5)
        if bonusActive[missile] then
            call LoadoutIntFullMana(source,chosen)
        endif

        if bonusActive[missile] and (wrapModel != null) and (wrapModel != "") then
            set overlayFx[missile] = AddSpecialEffectTarget(wrapModel, missile.dummy, WRAP_ATTACH_POINT)
            //aqui la cosita del mana
        else
            set overlayFx[missile] = null
        endif

        call LoadoutCore.launch(missile)

        set source = null
        set owner = null
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
        call FireMissile(dex)
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

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local integer id = GetHandleId(source)
        local SpellIndex dex
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)

        if active.has(id) then
            call Cleanup(active[id])
        endif

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = GetTriggerPlayer()
        set dex.time = FIRE_DURATION
        set dex.phase = 1
        set dex.clock = NewTimerEx(dex)

        set aim[dex] = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set active[id] = dex

        call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
        set delayedAnimTimer[dex] = NewTimerEx(dex)
        call TimerStart(delayedAnimTimer[dex], FIRST_ANIMATION_DELAY, false, function DelayedStartAnimation)
        call FireMissile(dex)
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
        call RegisterSpellEffectEvent(LOADOUT_MISSILE_SPELL, function OnEffect)
        //call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    endfunction
endlibrary
