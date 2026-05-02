//TESH.scrollpos=0
//TESH.alwaysfold=0
library LoadoutRocketLauncher initializer Init requires TimerUtils, SpellIndex, Missile, PlayerMissileLoadout, DamageTextUtil, LoadoutOrbBalance, LoadoutIntFullManaSwapNew, Table, WaveBarrierSkills, WaveDamageCredit, WeaponProfileConfig, WeaponInventoryCore
//******************************************************************************
// Shotgun-style burst spell that reuses TimerUtils, LoadoutMissile orb behavior.
//******************************************************************************
    globals
        private constant integer LOADOUT_ROCKET_LAUNCHER_SPELL = 'U0A5' //* Configure rawcode.

        //* Rapid Fire options.
        private constant real FIRE_DURATION = 1.00
        private constant integer FIRE_COUNT = 6
        private constant string CAST_ANIMATION = "attack"
        private constant real FIRST_ANIMATION_DELAY = 0.03
        private constant real RAPID_FIRE_ANIMATION_TIME_SCALE = 5.25
        private constant real ANIMATION_TIME_SCALE_ON_END = 1.00

        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC

        private constant integer BURST_COUNT = 1
        private constant real BURST_SPREAD_DEG = 05.
        private constant real BURST_STAGGER_INTERVAL = 0.03
        private constant real MISSILE_START_Z = 75.
        private constant real BASE_MISSILE_SPEED = 2000.
        private constant real MIN_MISSILE_SPEED = 1.
        private constant real SHOT_DISTANCE = 2000.
        private constant real MISSILE_COLLISION = 96.
        private constant real HOMING_SEARCH_RADIUS = 725. 
        private constant real HOMING_TURN_RATE = 0.60
        private constant real HOMING_SCAN_INTERVAL = 0.10
        private constant real MISSILE_SCALE = 1.00
        private constant real BASE_DAMAGE_MULT = 1
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
        private integer array poisonNext
        private integer array poisonPrev
        private integer poisonHead = 0
        private timer poisonTicker = null
        private timer array delayedAnimTimer
        private real array homingScanRemaining

        private timer array burstTimer
        private integer array burstShotIndex
        private real array burstBaseAngle
        private real array burstX
        private real array burstY
        private real array burstDamage
        private integer array burstInstances
        private integer array burstChosen
        private boolean array burstBonusActive
        private string array burstBaseModel
        private string array burstWrapModel

        //* Rapid fire state.
        private Table active
        private real array aim
    endglobals

    private keyword RocketLauncherCore

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
        if amount <= 0. or GetUnitTypeId(source) == 0 then
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

    private function IsHomingTargetValid takes Missile missile, unit target returns boolean
        return target != null and GetUnitTypeId(target) != 0 and FilterUnits(target, missile.owner)
    endfunction

    private function FindHomingTarget takes Missile missile returns unit
        local unit u
        local unit chosen = null
        local real dx
        local real dy
        local real distSq
        local real bestSq = 0.

        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, HOMING_SEARCH_RADIUS, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if IsHomingTargetValid(missile, u) then
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

    private function ResumeStraightFlight takes Missile missile returns nothing
        call missile.impact.move(missile.x + SHOT_DISTANCE*Cos(missile.angle), missile.y + SHOT_DISTANCE*Sin(missile.angle), missile.z)
        call missile.bounce()
        set missile.curve = 0.
        set missile.turn = 0.
    endfunction

    private function RefreshHoming takes Missile missile returns nothing
        local unit target = missile.target

        set homingScanRemaining[missile] = homingScanRemaining[missile] - Missile_TIMER_TIMEOUT
        if IsHomingTargetValid(missile, target) then
            return
        endif

        if target != null then
            set missile.target = null
            call ResumeStraightFlight(missile)
        endif

        if homingScanRemaining[missile] > 0. then
            return
        endif

        set homingScanRemaining[missile] = HOMING_SCAN_INTERVAL
        set target = FindHomingTarget(missile)
        if target != null then
            set missile.target = target
            set missile.turn = HOMING_TURN_RATE
        endif

        set target = null
    endfunction

    private function ContinueHomingAfterKill takes Missile missile returns boolean
        set missile.target = null
        set homingScanRemaining[missile] = 0.
        call ResumeStraightFlight(missile)
        return false
    endfunction

    function GetLoadoutRocketLauncherMoveCastDuration takes nothing returns real
        return WeaponProfileGetCastDuration(WEAPON_PROFILE_ENEMY_CHASER)
    endfunction

    private function GetSafeFireInterval takes nothing returns real
        local real duration = WeaponProfileGetCastDuration(WEAPON_PROFILE_ENEMY_CHASER)
        local integer count = WeaponProfileGetCastCount(WEAPON_PROFILE_ENEMY_CHASER)
        if duration <= 0. then
            return 0.03125
        endif
        if count <= 0 then
            return duration
        endif
        return duration / I2R(count)
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
        if (POISON_DOT_FX != "") then
            set poisonFx[dex] = AddSpecialEffectTarget(POISON_DOT_FX, target, POISON_DOT_FX_ATTACH)
        else
            set poisonFx[dex] = null
        endif

        call WaveRecordDamageCredit(source, target)
        call UnitDamageTarget(source, target, damagePerSecond, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
        call ShowCustomLoadoutText(target, FormatLoadoutDamageText(damagePerSecond), POISON_TEXT_R, POISON_TEXT_G, POISON_TEXT_B)

        set dex.count = ticks
        call PoisonListAdd(dex)
        if poisonTicker == null then
            set poisonTicker = NewTimer()
            call SetTimerDebugTag(poisonTicker, TIMER_DEBUG_TAG_LOADOUT_ROCKET)
            call TimerStart(poisonTicker, LOADOUT_ORB_POISON_TICK_INTERVAL, true, function OnPoisonTick)
        endif
    endfunction

    private struct RocketLauncherCore extends array
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
                if wasAlive and not UnitAlive(hit) then
                    return ContinueHomingAfterKill(missile)
                endif
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
                if wasAlive and not UnitAlive(hit) then
                    return ContinueHomingAfterKill(missile)
                endif
                return true
            elseif abil == LOADOUT_ORB_ABILITY_FIRE then
                set finalDamage = LoadoutGetFireDamage(baseDamage, inst)
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, finalDamage)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage), FIRE_TEXT_R, FIRE_TEXT_G, FIRE_TEXT_B)
                if wasAlive and not UnitAlive(hit) then
                    return ContinueHomingAfterKill(missile)
                endif
                return true
            elseif abil == LOADOUT_ORB_ABILITY_POISON then
                set wasAlive = UnitAlive(hit)
                call ApplyPoison(missile.source, hit, LoadoutGetPoisonTickDamage(baseDamage), LoadoutGetPoisonDuration(inst))
                if wasAlive and not UnitAlive(hit) then
                    return ContinueHomingAfterKill(missile)
                endif
                return true
            elseif abil == LOADOUT_ORB_ABILITY_WIND then
                set radius = LoadoutGetWindAoe(inst)
                set finalDamage = LoadoutGetWindDamage(baseDamage)
                set wasAlive = UnitAlive(hit)
                call DamageArea(missile.source, missile.owner, missile.x, missile.y, radius, finalDamage)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage) + "/[" + FormatLoadoutDamageText(radius) + "]", WIND_TEXT_R, WIND_TEXT_G, WIND_TEXT_B)
                if wasAlive and not UnitAlive(hit) then
                    return ContinueHomingAfterKill(missile)
                endif
                return true
            elseif abil == LOADOUT_ORB_ABILITY_DARK then
                set extraDamage = LoadoutGetDarkBonus(hit, inst)
                set finalDamage = baseDamage + extraDamage
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, finalDamage)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage), DARK_TEXT_R, DARK_TEXT_G, DARK_TEXT_B)
                if wasAlive and not UnitAlive(hit) then
                    return ContinueHomingAfterKill(missile)
                endif
                return true
            elseif abil == LOADOUT_ORB_ABILITY_BLOOD then
                set bloodMult = LoadoutGetBloodRandomMultiplier(inst)
                set finalDamage = baseDamage*bloodMult
                set bloodPct = LoadoutBloodMultiplierToPercent(bloodMult)
                set wasAlive = UnitAlive(hit)
                call DamageUnit(missile.source, hit, finalDamage)
                call ShowCustomLoadoutText(hit, FormatLoadoutDamageText(finalDamage) + "   //" + I2S(bloodPct) + "%", CRIT_TEXT_R, CRIT_TEXT_G, CRIT_TEXT_B)
                if wasAlive and not UnitAlive(hit) then
                    return ContinueHomingAfterKill(missile)
                endif
                return true
            endif

            set wasAlive = UnitAlive(hit)
            call DamageUnit(missile.source, hit, baseDamage)
            if wasAlive and not UnitAlive(hit) then
                return ContinueHomingAfterKill(missile)
            endif
            return true
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
            call RefreshHoming(missile)
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
            set homingScanRemaining[missile] = 0.
            set missile.target = null
            set missile.turn = 0.
            call WaveBarrierClearProjectileTrace(missile)
            call SpellIndex(missile.data).destroy()
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function LaunchBurstMissile takes unit source, player owner, real x, real y, real angle, integer chosen, boolean burstBonus, real damage, integer instances, string baseModel, string wrapModel returns nothing
        local SpellIndex mDex = SpellIndex.create()
        local Missile missile = Missile.create(x, y, MISSILE_START_Z, angle, SHOT_DISTANCE, MISSILE_START_Z)
        local real speed = WeaponProfileGetMissileSpeed(WEAPON_PROFILE_ENEMY_CHASER) + GetPlayerMissileSpeedBonus(owner)

        if speed < MIN_MISSILE_SPEED then
            set speed = MIN_MISSILE_SPEED
        endif
        set mDex.source = source
        set mDex.user = owner
        set missile.source = source
        set missile.owner = owner
        set missile.data = mDex
        set missile.model = baseModel
        set missile.scale = WeaponProfileGetMissileScale(WEAPON_PROFILE_ENEMY_CHASER)
        set missile.collision = MISSILE_COLLISION
        call missile.setMovementSpeed(speed)
        set missile.turn = 0.
        set missile.target = null

        set specialAbility[missile] = chosen
        set storedDamage[missile] = damage
        set effectInstances[missile] = instances
        set rayHitsLeft[missile] = LoadoutGetRayPierce(instances)
        set bonusActive[missile] = burstBonus
        set homingScanRemaining[missile] = 0.

        if burstBonus and (wrapModel != "") then
            set overlayFx[missile] = AddSpecialEffectTarget(wrapModel, missile.dummy, WRAP_ATTACH_POINT)
        else
            set overlayFx[missile] = null
        endif

        call RocketLauncherCore.launch(missile)
    endfunction

    private function BurstOffsetForShot takes integer shot, integer burstCount returns real
        local integer pairIndex
        if burstCount <= 0 then
            return 0.0
        endif
        if ModuloInteger(burstCount, 2) == 1 then
            if shot == 0 then
                return 0.0
            endif
            set pairIndex = (shot + 1)/2
            if ModuloInteger(shot, 2) == 1 then
                return I2R(pairIndex)
            endif
            return -I2R(pairIndex)
        endif
        set pairIndex = shot/2
        if ModuloInteger(shot, 2) == 0 then
            return -(I2R(pairIndex) + 0.5)
        endif
        return I2R(pairIndex) + 0.5
    endfunction

    private function BurstStop takes SpellIndex dex returns nothing
        if burstTimer[dex] != null then
            call ReleaseTimer(burstTimer[dex])
            set burstTimer[dex] = null
        endif
        set burstShotIndex[dex] = 0
        set burstBaseAngle[dex] = 0.0
        set burstX[dex] = 0.0
        set burstY[dex] = 0.0
        set burstDamage[dex] = 0.0
        set burstInstances[dex] = 0
        set burstChosen[dex] = 0
        set burstBonusActive[dex] = false
        set burstBaseModel[dex] = ""
        set burstWrapModel[dex] = ""
    endfunction

    private function GetBurstStaggerInterval takes nothing returns real
        local real step = GetSafeFireInterval()
        local real burstStep

        if BURST_COUNT <= 1 then
            return 0.03125
        endif

        set burstStep = step / I2R(BURST_COUNT)
        if burstStep <= 0. then
            return BURST_STAGGER_INTERVAL
        endif
        if burstStep < BURST_STAGGER_INTERVAL then
            return burstStep
        endif
        return BURST_STAGGER_INTERVAL
    endfunction

    private function BurstLaunchShot takes SpellIndex dex, integer shot returns nothing
        local integer burstCount = BURST_COUNT
        local real angle
        if shot < 0 or shot >= burstCount then
            return
        endif
        if not WeaponInventoryConsumeShotForProfile(dex.user, WEAPON_PROFILE_ENEMY_CHASER) then
            return
        endif
        set angle = burstBaseAngle[dex] + (BurstOffsetForShot(shot, burstCount)*BURST_SPREAD_DEG)*bj_DEGTORAD
        call LaunchBurstMissile(dex.source, dex.user, burstX[dex], burstY[dex], angle, burstChosen[dex], burstBonusActive[dex], burstDamage[dex], burstInstances[dex], burstBaseModel[dex], burstWrapModel[dex])
    endfunction

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
        if GetUnitTypeId(dex.source) != 0 then
            call SetUnitTimeScale(dex.source, ANIMATION_TIME_SCALE_ON_END)
        endif
        if delayedAnimTimer[dex] != null then
            call ReleaseTimer(delayedAnimTimer[dex])
            set delayedAnimTimer[dex] = null
        endif
        call BurstStop(dex)
        set aim[dex] = 0.
        if dex.clock != null then
            call ReleaseTimer(dex.clock)
            set dex.clock = null
        endif
        call dex.destroy()
    endfunction

    private function OnBurstTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local integer shot

        if dex == 0 then
            call ReleaseTimer(t)
            set t = null
            return
        endif

        if (burstTimer[dex] != t) then
            set t = null
            return
        endif

        if (burstShotIndex[dex] >= BURST_COUNT) or (GetUnitTypeId(dex.source) == 0) or (not UnitAlive(dex.source)) or (dex.phase < 0) then
            set burstTimer[dex] = null
            call Cleanup(dex)
            call ReleaseTimer(t)
            set t = null
            return
        endif

        set shot = burstShotIndex[dex]
        call BurstLaunchShot(dex, shot)
        set burstShotIndex[dex] = shot + 1

        if burstShotIndex[dex] >= BURST_COUNT then
            if dex.time <= 0. then
                set burstTimer[dex] = null
                call Cleanup(dex)
                call ReleaseTimer(t)
                set t = null
                return
            else
                call BurstStop(dex)
            endif
        endif

        set t = null
    endfunction

    private function FireBurst takes SpellIndex dex returns nothing
        local unit source = dex.source
        local player owner = dex.user
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real baseAngle = aim[dex]
        local string baseModel = WeaponProfileGetTierMissileModel(WEAPON_PROFILE_ENEMY_CHASER, 1)
        local string wrapModel = GetPlayerMissileOverlayModelPath(owner)
        local real damage = WeaponProfileGetDamage(WEAPON_PROFILE_ENEMY_CHASER)*BASE_DAMAGE_MULT
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
        if (baseModel == "") then
            set baseModel = BASE_MISSILE_MODEL
        endif

        set burstBaseAngle[dex] = baseAngle
        set burstX[dex] = x
        set burstY[dex] = y
        set burstDamage[dex] = damage
        set burstInstances[dex] = instances
        set burstChosen[dex] = chosen
        set burstBonusActive[dex] = burstBonus
        set burstBaseModel[dex] = baseModel
        set burstWrapModel[dex] = wrapModel
        set burstShotIndex[dex] = 0

        call BurstLaunchShot(dex, 0)
        set burstShotIndex[dex] = 1

        if BURST_COUNT > 1 then
            set burstTimer[dex] = NewTimerEx(dex)
            call SetTimerDebugTag(burstTimer[dex], TIMER_DEBUG_TAG_LOADOUT_ROCKET)
            call TimerStart(burstTimer[dex], GetBurstStaggerInterval(), true, function OnBurstTick)
        else
            call BurstStop(dex)
        endif
        set source = null
        set owner = null
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
        local real step = GetSafeFireInterval()

        if (GetUnitTypeId(dex.source) == 0) or (not UnitAlive(dex.source)) or (dex.phase < 0) then
            call Cleanup(dex)
            set t = null
            return
        endif

        if dex.time <= 0. then
            if burstTimer[dex] == null then
                call Cleanup(dex)
            endif
            set t = null
            return
        endif

        call SetUnitAnimation(dex.source, CAST_ANIMATION)
        call FireBurst(dex)
        set dex.time = dex.time - step

        if (dex.time <= 0.) and (burstTimer[dex] == null) then
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

    function LoadoutRocketLauncherFire takes unit source, player owner, real tx, real ty returns boolean
        local integer id = GetHandleId(source)
        local SpellIndex dex
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real step = GetSafeFireInterval()
        local boolean useRapid
        local real duration = WeaponProfileGetCastDuration(WEAPON_PROFILE_ENEMY_CHASER)

        set useRapid = true

        if active.has(id) then
            set dex = active[id]
            if (dex.phase >= 0) and (GetUnitTypeId(dex.source) != 0) and UnitAlive(dex.source) then
                set aim[dex] = Atan2(ty - y, tx - x)
                // If a rocket burst is still emitting missiles, do not promote
                // this recast into dex.time > 0. Otherwise the last burst tick
                // only stops the burst timer and leaves active[dex] stuck with
                // no periodic timer, making future casts return without firing.
                if burstTimer[dex] != null then
                    call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
                    return true
                endif
                set dex.time = duration
                call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
                return true
            endif
            call Cleanup(dex)
        endif

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = owner
        if useRapid and (duration > 0.) then
            set dex.time = duration
        else
            set dex.time = 0.
        endif
        set dex.phase = 1
        set dex.clock = NewTimerEx(dex)
        call SetTimerDebugTag(dex.clock, TIMER_DEBUG_TAG_LOADOUT_ROCKET)
        set aim[dex] = Atan2(ty - y, tx - x)
        set active[id] = dex

        call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
        set delayedAnimTimer[dex] = NewTimerEx(dex)
        call SetTimerDebugTag(delayedAnimTimer[dex], TIMER_DEBUG_TAG_LOADOUT_ROCKET)
        call TimerStart(delayedAnimTimer[dex], FIRST_ANIMATION_DELAY, false, function DelayedStartAnimation)
        call FireBurst(dex)
        set dex.time = dex.time - step

        if dex.time > 0. then
            call TimerStart(dex.clock, step, true, function OnPeriodic)
        elseif burstTimer[dex] == null then
            call Cleanup(dex)
        endif

        return true
    endfunction

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        call LoadoutRocketLauncherFire(source, owner, GetSpellTargetX(), GetSpellTargetY())
        set source = null
        set owner = null
    endfunction

    private function Init takes nothing returns nothing
        set active = Table.create()
        call RegisterSpellEffectEvent(LOADOUT_ROCKET_LAUNCHER_SPELL, function OnEffect)
        //call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    endfunction
endlibrary

