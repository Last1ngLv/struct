//TESH.scrollpos=0
//TESH.alwaysfold=0
library PlayerMissileLoadout initializer Init requires Table, WaveDamageCredit /* v2.0
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
*       call SetPlayerMissileHealOnHit(player p, real value)
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
*       real    h = GetPlayerMissileHealOnHit(player p)
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
        private constant real    DEFAULT_HEAL_ON_HIT = 0.25
        private constant boolean DEFAULT_USE_RAPID_FIRE_MISSILE = true
        private constant boolean DEFAULT_USE_RAPID_FIRE_CONTROL = false
        private constant boolean DEFAULT_USE_SMART_RECAST = false
        
        private constant string  DEFAULT_LEAP_CASTER_FX1 = ""
        private constant string  DEFAULT_LEAP_CASTER_FX2 = ""
        private constant string  DEFAULT_LEAP_DUMMY_FX1 = ""
        private constant string  DEFAULT_LEAP_DUMMY_FX2 = ""
        private constant real    DEFAULT_LEAP_DUMMY_SCALE = 0.10
        private constant real    DEFAULT_LEAP_DUMMY_FLIGHT_OFFSET = 0.00
        private constant integer DEFAULT_LEAP_COMPANION_UNIT_ID = 'dumi'
        private constant string  DEFAULT_LEAP_IMPACT_FX = "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl"
    
        private constant integer DEFAULT_ORB_LEVEL = 1
        private constant integer DEFAULT_POINTS_OF_MANA = 1

        private Table byHandle
        private integer array chosenAbility
        private real array chosenSpeedBonus
        private real array chosenDamage
        private integer array chosenInstances
        private string array chosenModelPath
        private string array chosenOverlayPath
        private real array chosenHealOnHit
        private boolean array chosenUseRapidFireMissile
        private boolean array chosenUseRapidFireControl
        private boolean array chosenUseSmartRecast

        private string array chosenLeapCasterFx1
        private string array chosenLeapCasterFx2
        private string array chosenLeapDummyFx1
        private string array chosenLeapDummyFx2
        private real array chosenLeapDummyScale
        private real array chosenLeapDummyFlightOffset
        private integer array chosenLeapCompanionUnitId
        private string array chosenLeapImpactFx
        
        // Nuevo: cantidad asociada a ShortWeaponInterval
        private integer array orbLevel             // Nuevo: nivel de orb
        private integer array pointsOfMana         // Nuevo: puntos de mana
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

    function SetPlayerMissileHealOnHit takes player p, real value returns nothing
        if value < 0. then
            set value = 0.
        endif
        set chosenHealOnHit[SlotOfPlayer(p)] = value
    endfunction

    // Backward-compatible helper: applies to both missile and control variants.
    function SetPlayerMissileUseRapidFireMissile takes player p, boolean flag returns nothing
        set chosenUseRapidFireMissile[SlotOfPlayer(p)] = flag
    endfunction

    function SetPlayerMissileUseRapidFireControl takes player p, boolean flag returns nothing
        set chosenUseRapidFireControl[SlotOfPlayer(p)] = flag
    endfunction
    
    function SetPlayerMissileUseRapidFire takes player p, boolean flag returns nothing
        call SetPlayerMissileUseRapidFireMissile(p, flag)
        call SetPlayerMissileUseRapidFireControl(p, flag)
    endfunction

    function SetPlayerMissileUseSmartRecast takes player p, boolean flag returns nothing
        set chosenUseSmartRecast[SlotOfPlayer(p)] = flag
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

    function GetPlayerMissileHealOnHit takes player p returns real
        return chosenHealOnHit[SlotOfPlayer(p)]
    endfunction

    // Backward-compatible helper: returns missile variant.
    function GetPlayerMissileUseRapidFireMissile takes player p returns boolean
        return chosenUseRapidFireMissile[SlotOfPlayer(p)]
    endfunction
    
    function GetPlayerMissileUseRapidFire takes player p returns boolean
        return GetPlayerMissileUseRapidFireMissile(p)
    endfunction

    function GetPlayerMissileUseRapidFireControl takes player p returns boolean
        return chosenUseRapidFireControl[SlotOfPlayer(p)]
    endfunction

    function GetPlayerMissileUseSmartRecast takes player p returns boolean
        return chosenUseSmartRecast[SlotOfPlayer(p)]
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
    
    //mys
    
    // ORB LEVEL
    function SetPlayerOrbLevel takes player p, integer value returns nothing
        if value < 0 then
            set value = 1
        endif
        set orbLevel[SlotOfPlayer(p)] = value
    endfunction

    // POINTS OF MANA
    function SetPlayerPointsOfMana takes player p, integer value returns nothing
        if value < 0 then
            set value = 1
        endif
        set pointsOfMana[SlotOfPlayer(p)] = value
    endfunction


    // =======================
    // GETTERS
    // =======================
    
    // ORB LEVEL
    function GetPlayerOrbLevel takes player p returns integer
        return orbLevel[SlotOfPlayer(p)]
    endfunction

    // POINTS OF MANA
    function GetPlayerPointsOfMana takes player p returns integer
        return pointsOfMana[SlotOfPlayer(p)]
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0
        local player p
        set byHandle = Table.create()
        loop
            exitwhen i >= MAX_PLAYER_SLOTS
            set p = Player(i)
            call SetPlayerMissileLoadout(p, DEFAULT_CHOICE_ABILITY, DEFAULT_SPEED_BONUS, DEFAULT_DAMAGE_VALUE, DEFAULT_INSTANCE_COUNT, DEFAULT_MODEL_PATH, DEFAULT_OVERLAY_MODEL_PATH)
            call SetPlayerMissileHealOnHit(p, DEFAULT_HEAL_ON_HIT)
            call SetPlayerMissileUseRapidFireMissile(p, DEFAULT_USE_RAPID_FIRE_MISSILE)
            call SetPlayerMissileUseRapidFireControl(p, DEFAULT_USE_RAPID_FIRE_CONTROL)
            call SetPlayerMissileUseSmartRecast(p, DEFAULT_USE_SMART_RECAST)
            
            // Default Leap FX
            call SetPlayerLeapCasterFx(p, DEFAULT_LEAP_CASTER_FX1, DEFAULT_LEAP_CASTER_FX2)
            call SetPlayerLeapDummyFx(p, DEFAULT_LEAP_DUMMY_FX1, DEFAULT_LEAP_DUMMY_FX2)
            call SetPlayerLeapDummyScale(p, DEFAULT_LEAP_DUMMY_SCALE)
            call SetPlayerLeapDummyFlightOffset(p, DEFAULT_LEAP_DUMMY_FLIGHT_OFFSET)
            call SetPlayerLeapCompanionUnitId(p, DEFAULT_LEAP_COMPANION_UNIT_ID)
            call SetPlayerLeapImpactFx(p, DEFAULT_LEAP_IMPACT_FX)
            
            call SetPlayerOrbLevel(p, 1)
            call SetPlayerPointsOfMana(p, 1)
            
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

        constant real LOADOUT_ORB_FIRE_DAMAGE_PERCENT_PER_INSTANCE = 0.25

        constant real LOADOUT_ORB_POISON_DURATION_PER_INSTANCE = 1.00
        constant real LOADOUT_ORB_POISON_TICK_INTERVAL = 0.50
        constant real LOADOUT_ORB_POISON_DAMAGE_MULT = 0.50

        constant real LOADOUT_ORB_WIND_BASE_AOE = 150.
        constant real LOADOUT_ORB_WIND_AOE_PER_INSTANCE = 25.
        constant real LOADOUT_ORB_WIND_BASE_DAMAGE = 0.

        constant real LOADOUT_ORB_DARK_BASE_CURRENT_HP_PERCENT = 0.00
        constant real LOADOUT_ORB_DARK_PERCENT_PER_INSTANCE = 0.01

        constant real LOADOUT_ORB_BLOOD_MIN_BASE_MULT = 0.00
        constant real LOADOUT_ORB_BLOOD_MAX_BASE_MULT = 2.00
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


library LoadoutMissile initializer Init requires TimerUtils, SpellIndex, Missile, PlayerMissileLoadout, DamageTextUtil, LoadoutOrbBalance, LoadoutIntFullManaSwapNew, WaveBarrierSkills, WeaponProfileConfig, WeaponInventoryCore /* v2.0
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
        private constant integer LOADOUT_MISSILE_RIFLE_SPELL = 'U0A6'
        private constant integer LOADOUT_MISSILE_ASSAULT_SPELL = 'U0A7'
        private constant integer LOADOUT_MISSILE_LASER_SPELL = 'U0A9'
        private constant integer LOADOUT_MISSILE_IRON_LIZARD_SPELL = 'U0AC'

        //* Rapid Fire options.
        private constant real FIRE_DURATION = 0.75
        private constant integer FIRE_COUNT = 5
        private constant string CAST_ANIMATION = "attack"
        private constant real FIRST_ANIMATION_DELAY = 0.03
        private constant real RAPID_FIRE_ANIMATION_TIME_SCALE = 10.25
        private constant real ANIMATION_TIME_SCALE_ON_END = 1.00

        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC

        //* Base missile defaults.
        private constant real BASE_MISSILE_SPEED = 2500.
        private constant real MIN_MISSILE_SPEED = 1.
        private constant real FIXED_TRAVEL_DISTANCE = 2250.
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
        private integer array poisonNext
        private integer array poisonPrev
        private integer poisonHead = 0
        private timer poisonTicker = null
        private timer array delayedAnimTimer

        //* Rapid fire state.
        private Table active
        private real array aim
        private integer array activeWeaponProfile
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
        call WaveRecordDamageCredit(source, target)
        return UnitDamageTarget(source, target, amount, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
    endfunction

    private function HealCasterOnHit takes unit source, player owner returns nothing
        local real healAmount
        if GetUnitTypeId(source) == 0 then
            return
        endif
        if not UnitAlive(source) then
            return
        endif
        set healAmount = GetPlayerMissileHealOnHit(owner)
        if healAmount <= 0. then
            return
        endif
        call SetUnitState(source, UNIT_STATE_LIFE, GetUnitState(source, UNIT_STATE_LIFE) + healAmount)
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
                call WaveRecordDamageCredit(source, u)
                call UnitDamageTarget(source, u, amount, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
            endif
        endloop
        set u = null
    endfunction

    private function GetBarrierProjectileKind takes Missile missile returns integer
        if bonusActive[missile] then
            if specialAbility[missile] == LOADOUT_ORB_ABILITY_WIND then
                return WAVE_BARRIER_PROJECTILE_KIND_WIND
            endif
            if specialAbility[missile] == LOADOUT_ORB_ABILITY_RAY then
                return WAVE_BARRIER_PROJECTILE_KIND_RAY
            endif
        endif
        return WAVE_BARRIER_PROJECTILE_KIND_NORMAL
    endfunction

    private function ResolveBarrierIntercept takes Missile missile returns integer
        local integer interaction = WaveBarrierCheckPlayerProjectile(missile, missile.owner, missile.x, missile.y, GetBarrierProjectileKind(missile))
        local real radius
        local real finalDamage
        if interaction == WAVE_BARRIER_INTERACTION_WIND then
            if bonusActive[missile] and specialAbility[missile] == LOADOUT_ORB_ABILITY_WIND then
                set radius = LoadoutGetWindAoe(effectInstances[missile])
                set finalDamage = LoadoutGetWindDamage(storedDamage[missile])
                call DamageArea(missile.source, missile.owner, missile.x, missile.y, radius, finalDamage)
            endif
            return WAVE_BARRIER_INTERACTION_WIND
        endif
        if interaction == WAVE_BARRIER_INTERACTION_RAY then
            if bonusActive[missile] and specialAbility[missile] == LOADOUT_ORB_ABILITY_RAY and rayHitsLeft[missile] > 0 then
                set rayHitsLeft[missile] = rayHitsLeft[missile] - 1
                return WAVE_BARRIER_INTERACTION_RAY
            endif
            return WAVE_BARRIER_INTERACTION_BLOCK
        endif
        return interaction
    endfunction

    private function PoisonListAdd takes SpellIndex dex returns nothing
        set poisonPrev[dex] = 0
        set poisonNext[dex] = poisonHead
        if poisonHead != 0 then
            set poisonPrev[poisonHead] = dex
        endif
        set poisonHead = dex
    endfunction

    private function PoisonListRemove takes SpellIndex dex returns nothing
        local integer p = poisonPrev[dex]
        local integer n = poisonNext[dex]
        if p != 0 then
            set poisonNext[p] = n
        else
            set poisonHead = n
        endif
        if n != 0 then
            set poisonPrev[n] = p
        endif
        set poisonPrev[dex] = 0
        set poisonNext[dex] = 0
    endfunction

    private function PoisonDestroy takes SpellIndex dex returns nothing
        call PoisonListRemove(dex)
        if poisonFx[dex] != null then
            call DestroyEffect(poisonFx[dex])
            set poisonFx[dex] = null
        endif
        call dex.destroy()
    endfunction

    private function OnPoisonTick takes nothing returns nothing
        local integer node = poisonHead
        local integer nextNode
        local SpellIndex dex
        loop
            exitwhen node == 0
            set dex = SpellIndex(node)
            set nextNode = poisonNext[node]
            if (dex.count <= 0) or (GetUnitTypeId(dex.target) == 0) or (not UnitAlive(dex.target)) or (GetUnitTypeId(dex.source) == 0) then
                call PoisonDestroy(dex)
            else
                call WaveRecordDamageCredit(dex.source, dex.target)
                call UnitDamageTarget(dex.source, dex.target, dex.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                call ShowCustomLoadoutText(dex.target, "-" + FormatLoadoutDamageText(dex.damage), POISON_TEXT_R, POISON_TEXT_G, POISON_TEXT_B)
                set dex.count = dex.count - 1
                if dex.count <= 0 then
                    call PoisonDestroy(dex)
                endif
            endif
            set node = nextNode
        endloop
        if (poisonHead == 0) and (poisonTicker != null) then
            call ReleaseTimer(poisonTicker)
            set poisonTicker = null
        endif
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
        if (POISON_DOT_FX != "") then
            set poisonFx[dex] = AddSpecialEffectTarget(POISON_DOT_FX, target, POISON_DOT_FX_ATTACH)
        else
            set poisonFx[dex] = null
        endif

        // Impact damage.
        call WaveRecordDamageCredit(source, target)
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
        call PoisonListAdd(dex)
        if poisonTicker == null then
            set poisonTicker = NewTimer()
            call SetTimerDebugTag(poisonTicker, TIMER_DEBUG_TAG_LOADOUT_MISSILE)
            call TimerStart(poisonTicker, LOADOUT_ORB_POISON_TICK_INTERVAL, true, function OnPoisonTick)
        endif
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
            local integer barrierInteraction

            set barrierInteraction = ResolveBarrierIntercept(missile)
            if barrierInteraction == WAVE_BARRIER_INTERACTION_BLOCK or barrierInteraction == WAVE_BARRIER_INTERACTION_WIND then
                return true
            endif
            if barrierInteraction == WAVE_BARRIER_INTERACTION_RAY then
                return false
            endif

            if not FilterUnits(hit, missile.owner) then
                return false
            endif

            if not bonusActive[missile] then
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, baseDamage)
                call HealCasterOnHit(missile.source, missile.owner)
                return wasAlive and UnitAlive(hit)
            endif

            if abil == LOADOUT_ORB_ABILITY_RAY then
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, baseDamage)
                call HealCasterOnHit(missile.source, missile.owner)

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
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, finalDamage)
                call HealCasterOnHit(missile.source, missile.owner)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage), FIRE_TEXT_R, FIRE_TEXT_G, FIRE_TEXT_B)
                return wasAlive and UnitAlive(hit)

            elseif abil == LOADOUT_ORB_ABILITY_POISON then
                set wasAlive = UnitAlive(hit)
                call ApplyPoison(missile.source, hit, LoadoutGetPoisonTickDamage(baseDamage), LoadoutGetPoisonDuration(inst))
                call HealCasterOnHit(missile.source, missile.owner)
                return wasAlive and UnitAlive(hit)

            elseif abil == LOADOUT_ORB_ABILITY_WIND then
                set radius = LoadoutGetWindAoe(inst)
                set finalDamage = LoadoutGetWindDamage(baseDamage)
                set wasAlive = UnitAlive(hit)
                call DamageArea(missile.source, missile.owner, missile.x, missile.y, radius, finalDamage)
                call HealCasterOnHit(missile.source, missile.owner)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage) + "/[" + FormatLoadoutDamageText(radius) + "]", WIND_TEXT_R, WIND_TEXT_G, WIND_TEXT_B)
                return wasAlive and UnitAlive(hit)

            elseif abil == LOADOUT_ORB_ABILITY_DARK then
                set extraDamage = LoadoutGetDarkBonus(hit, inst)
                set finalDamage = baseDamage + extraDamage
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, finalDamage)
                call HealCasterOnHit(missile.source, missile.owner)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage), DARK_TEXT_R, DARK_TEXT_G, DARK_TEXT_B)
                return wasAlive and UnitAlive(hit)

            elseif abil == LOADOUT_ORB_ABILITY_BLOOD then
                set bloodMult = LoadoutGetBloodRandomMultiplier(inst)
                set finalDamage = baseDamage*bloodMult
                set bloodPct = LoadoutBloodMultiplierToPercent(bloodMult)
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, finalDamage)
                call HealCasterOnHit(missile.source, missile.owner)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage) + "   //" + I2S(bloodPct) + "%", CRIT_TEXT_R, CRIT_TEXT_G, CRIT_TEXT_B)
                return wasAlive and UnitAlive(hit)
            endif

            set wasAlive = UnitAlive(hit)
            call DamageUnit(missile.source, hit, baseDamage)
            call HealCasterOnHit(missile.source, missile.owner)
            return wasAlive and UnitAlive(hit)
        endmethod

        private static method onFinish takes Missile missile returns boolean
            return true
        endmethod

        private static method onDestructable takes Missile missile, destructable hit returns boolean
            return true
        endmethod

        private static method onTerrain takes Missile missile returns boolean
            return true
        endmethod

        private static method onPeriod takes Missile missile returns boolean
            local integer barrierInteraction = ResolveBarrierIntercept(missile)
            if barrierInteraction == WAVE_BARRIER_INTERACTION_BLOCK or barrierInteraction == WAVE_BARRIER_INTERACTION_WIND then
                return true
            endif
            return false
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
            call WaveBarrierClearProjectileTrace(missile)
            call SpellIndex(missile.data).destroy()
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function Cleanup takes SpellIndex dex returns nothing
        local integer id = 0
        if dex == 0 or dex.phase == -999 then
            return
        endif
        set dex.phase = -999
        set id = GetHandleId(dex.source)
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
        set activeWeaponProfile[dex] = WEAPON_PROFILE_NONE
        if dex.clock != null then
            call ReleaseTimer(dex.clock)
            set dex.clock = null
        endif
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

    private function LaunchSingleLoadoutMissile takes unit source, player owner, real angle, real lateralOffset, integer profileId returns nothing
        local real x = GetUnitX(source) + lateralOffset*Cos(angle + bj_PI/2.)
        local real y = GetUnitY(source) + lateralOffset*Sin(angle + bj_PI/2.)
        local string baseModel
        local string wrapModel
        local real speed
        local real damage
        local integer instances
        local integer chosen
        local integer chosenLevel
        local SpellIndex mDex
        local Missile missile

        if not WeaponInventoryConsumeShotForProfile(owner, profileId) then
            return
        endif

        set missile = Missile.create(x, y, MISSILE_START_Z, angle, WeaponProfileGetRange(profileId), MISSILE_START_Z)
        set mDex = SpellIndex.create()
        set chosen = GetPlayerMissileAbilityChoice(owner)
        set chosenLevel = 0
        if chosen != 0 then
            set chosenLevel = GetUnitAbilityLevel(source, chosen)
        endif

        set speed = WeaponProfileGetMissileSpeed(profileId) + GetPlayerMissileSpeedBonus(owner)
        if speed < MIN_MISSILE_SPEED then
            set speed = MIN_MISSILE_SPEED
        endif
        set damage = WeaponProfileGetDamage(profileId)
        if damage < 0. then
            set damage = 0.
        endif
        set instances = GetPlayerMissileInstanceCount(owner)
        if instances < 1 then
            set instances = 1
        endif

        set baseModel = WeaponProfileGetTierMissileModel(profileId, 1)
        if (baseModel == "") then
            set baseModel = BASE_MISSILE_MODEL
        endif
        set wrapModel = GetPlayerMissileOverlayModelPath(owner)

        set mDex.source = source
        set mDex.user = owner
        set missile.source = source
        set missile.owner = owner
        set missile.data = mDex
        set missile.model = baseModel
        set missile.scale = WeaponProfileGetMissileScale(profileId)
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

        if bonusActive[missile] and (wrapModel != "") then
            set overlayFx[missile] = AddSpecialEffectTarget(wrapModel, missile.dummy, WRAP_ATTACH_POINT)
        else
            set overlayFx[missile] = null
        endif

        call LoadoutCore.launch(missile)
    endfunction

    private function FireMissile takes SpellIndex dex returns nothing
        local unit source = dex.source
        local player owner = dex.user
        local real angle = aim[dex]
        local integer profileId = activeWeaponProfile[dex]

        if not WeaponProfileIsWeapon(profileId) then
            set profileId = WEAPON_PROFILE_HANDGUN
        endif

        if WeaponProfileGetBehavior(profileId) == WEAPON_BEHAVIOR_DOUBLE_STRAIGHT then
            call LaunchSingleLoadoutMissile(source, owner, angle, -42.00, profileId)
            call LaunchSingleLoadoutMissile(source, owner, angle, 42.00, profileId)
        else
            call LaunchSingleLoadoutMissile(source, owner, angle, 0.00, profileId)
        endif

        set source = null
        set owner = null
    endfunction

    function GetLoadoutMissileMoveCastDuration takes nothing returns real
        return WeaponProfileGetCastDuration(WEAPON_PROFILE_HANDGUN)
    endfunction

    function GetLoadoutMissileMoveCastDurationForAbility takes integer abilityId returns real
        local integer profileId = WeaponProfileFromFireAbility(abilityId)
        if not WeaponProfileIsWeapon(profileId) then
            set profileId = WEAPON_PROFILE_HANDGUN
        endif
        return WeaponProfileGetCastDuration(profileId)
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

    private function OnPeriodic takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local real step = GetSafeFireInterval(activeWeaponProfile[dex])

        if (GetUnitTypeId(dex.source) == 0) or (not UnitAlive(dex.source)) or (dex.phase < 0) then
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
        set dex.time = dex.time - step

        if dex.time <= 0. then
            call Cleanup(dex)
        endif

        set t = null
    endfunction

    private function MarkCanceled takes unit whichUnit returns nothing
        local integer id = GetHandleId(whichUnit)
        if active.has(id) then
            // A running cast session is refreshed by recast; orders should not kill it.
            return
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

    function LoadoutMissileFireProfile takes unit source, player owner, integer profileId, real tx, real ty returns boolean
        local integer id = GetHandleId(source)
        local SpellIndex dex
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local boolean useRapid
        local real duration
        local real step

        if not WeaponProfileIsWeapon(profileId) then
            set profileId = WEAPON_PROFILE_HANDGUN
        endif
        set duration = WeaponProfileGetCastDuration(profileId)
        set step = GetSafeFireInterval(profileId)

        if active.has(id) then
            set dex = active[id]
            if (dex.phase >= 0) and (GetUnitTypeId(dex.source) != 0) and UnitAlive(dex.source) then
                set aim[dex] = Atan2(ty - y, tx - x)
                set activeWeaponProfile[dex] = profileId
                set dex.time = duration
                call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
                return true
            endif
            call Cleanup(dex)
        endif

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = owner
        set useRapid = GetPlayerMissileUseRapidFireMissile(owner)
        set activeWeaponProfile[dex] = profileId
        if useRapid and (duration > 0.) then
            set dex.time = duration
        else
            set dex.time = 0.
        endif
        set dex.phase = 1
        set dex.clock = NewTimerEx(dex)
        call SetTimerDebugTag(dex.clock, TIMER_DEBUG_TAG_LOADOUT_MISSILE)

        set aim[dex] = Atan2(ty - y, tx - x)
        set active[id] = dex

        call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
        set delayedAnimTimer[dex] = NewTimerEx(dex)
        call SetTimerDebugTag(delayedAnimTimer[dex], TIMER_DEBUG_TAG_LOADOUT_MISSILE)
        call TimerStart(delayedAnimTimer[dex], FIRST_ANIMATION_DELAY, false, function DelayedStartAnimation)
        call FireMissile(dex)
        set dex.time = dex.time - step

        if dex.time > 0. then
            call TimerStart(dex.clock, step, true, function OnPeriodic)
        else
            call Cleanup(dex)
        endif

        return true
    endfunction

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        call LoadoutMissileFireProfile(source, owner, WeaponProfileFromFireAbility(GetSpellAbilityId()), GetSpellTargetX(), GetSpellTargetY())
        set source = null
        set owner = null
    endfunction

    private function Init takes nothing returns nothing
        set active = Table.create()
        call RegisterSpellEffectEvent(LOADOUT_MISSILE_SPELL, function OnEffect)
        call RegisterSpellEffectEvent(LOADOUT_MISSILE_RIFLE_SPELL, function OnEffect)
        call RegisterSpellEffectEvent(LOADOUT_MISSILE_ASSAULT_SPELL, function OnEffect)
        call RegisterSpellEffectEvent(LOADOUT_MISSILE_LASER_SPELL, function OnEffect)
        // Iron Lizard has a dedicated billiard-bounce behavior in LoadoutIronLizard.
        //call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    endfunction
endlibrary
