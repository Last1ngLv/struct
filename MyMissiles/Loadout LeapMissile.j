library LoadoutLeapMissile initializer Init uses SpellIndex, Missile, PlayerMissileLoadout, IsUnitChanneling, DamageTextUtil, LoadoutOrbBalance, IsTerrainWalkable, SimError, WaveDamageCredit, Table
//**
//* User settings:
//* ==============
    globals
        private constant integer LOADOUT_LEAP_MISSILE_SPELL = 'U0A4'

        //* Base Jump settings
        private constant real BASE_JUMP_HEIGHT = 550.0
        private constant real BASE_JUMP_SPEED = 1200.0
        private constant boolean USE_FIXED_TIME = false
        private constant real FIXED_JUMP_TIME = 1.20

        //* Rapid Fire options.
        private constant real FIRE_DURATION = 1.00
        private constant integer FIRE_COUNT = 3
        private constant real RAPID_FIRE_ANIMATION_TIME_SCALE = 5.25
        private constant real ANIMATION_TIME_SCALE_ON_END = 1.00

        //* Base Impact Settings
        private constant real BASE_IMPACT_AREA = 350.0
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        private constant real IMPACT_FX_DURATION = 1.00
        private constant real DUMMY_SCALE_PER_100_AREA = 0.50
        private constant string IMPACT_SOUND = "" // Configurable impact sound (e.g. "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.wav")
        
        //* Buff variables
        private constant integer BUFF_CAST_ID = 'AB01' // Raw code of Leap Apply buff ability
        private constant integer ORDER_ID     = 852075 // Order of the Leap Apply buff ability (e.g. slow)
        private constant integer BUFF_APPLIED_ID = 'BB01' // Configure the buff rawcode applied by BUFF_CAST_ID.
        
        //* Animations
        private constant string CAST_ANIMATION = "spell" // What animation plays while jumping
        private constant string ANIMATION_TAG = "" // Added by AddUnitAnimationProperties. Empty if none.
        private constant real FIRST_ANIMATION_DELAY = 0.03

        //* Companion fallback unit type (used only if loadout returns 0).
        private constant integer COMPANION_DUMMY_FALLBACK_ID = 'dumi'
        
        //* Orbs Visuals
        private constant string RAY_LIGHTNING_TYPE = "CLPB" // Chain Lightning Primary
        private constant string RAY_HIT_FX = "Abilities\\Spells\\Orc\\LightningShield\\LightningShieldTarget.mdl"
        private constant string RAY_HIT_FX_ATTACH = "origin"
        
        //* Floating Text Colors 
        private constant integer DEFAULT_TEXT_R = 255
        private constant integer DEFAULT_TEXT_G = 255
        private constant integer DEFAULT_TEXT_B = 255
        
        private constant integer POISON_TEXT_R = 100
        private constant integer POISON_TEXT_G = 255
        private constant integer POISON_TEXT_B = 50
        
        private constant integer FIRE_TEXT_R = 255
        private constant integer FIRE_TEXT_G = 125
        private constant integer FIRE_TEXT_B = 40
        
        private constant integer BLOOD_TEXT_R = 255
        private constant integer BLOOD_TEXT_G = 40
        private constant integer BLOOD_TEXT_B = 40

        private constant integer DARK_TEXT_R = 180
        private constant integer DARK_TEXT_G = 50
        private constant integer DARK_TEXT_B = 255

        private constant string POISON_DOT_FX = "Abilities\\Spells\\NightElf\\shadowstrike\\shadowstrike.mdl"
        private constant string POISON_DOT_FX_ATTACH = "head"

        
    endglobals

//**
//* Code:
//* =====
    globals
        private integer array specialAbility
        private real array storedDamage
        private integer array effectInstances
        private boolean array bonusActive
        private timer array delayedAnimTimer
        private sound error
        private Table active
        private real array rapidTargetX
        private real array rapidTargetY

        // FX arrays
        private effect array casterFx1
        private effect array casterFx2
        private effect array dummyFx1
        private effect array dummyFx2
        private unit array companionDummy
        
        // Ray Logic
        private lightning array rayLightning

        // Impact Effect Dummy
        private unit array impactDummy
        private effect array impactFx
        private effect array poisonFx
        private integer array poisonNext
        private integer array poisonPrev
        private integer poisonHead = 0
        private timer poisonTicker = null
    endglobals
    
    private keyword LeapMissileCore

    private function IsPointJumpable takes real x, real y returns boolean
        if not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
            return IsTerrainWalkable(x, y)
        endif
        return false
    endfunction

    private function GetLeapMissileScaleForArea takes real area returns real
        return (area/100.0)*DUMMY_SCALE_PER_100_AREA
    endfunction

    private function GetLeapMissileWindArea takes integer inst returns real
        return BASE_IMPACT_AREA + LOADOUT_ORB_WIND_AOE_PER_INSTANCE*LoadoutClampInstance(inst)
    endfunction

    private function GetSafeFireInterval takes nothing returns real
        if FIRE_DURATION <= 0. then
            return 0.03125
        endif
        if FIRE_COUNT <= 0 then
            return FIRE_DURATION
        endif
        return FIRE_DURATION / I2R(FIRE_COUNT)
    endfunction

    function GetLoadoutLeapMissileMoveCastDuration takes nothing returns real
        return FIRE_DURATION
    endfunction


    // Poison DOT Logic
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
        local unit target
        local integer ticks
        loop
            exitwhen node == 0
            set dex = SpellIndex(node)
            set nextNode = poisonNext[node]
            set target = dex.target
            set ticks = R2I(dex.count - 1)

            if (target == null) or (GetUnitTypeId(target) == 0) or (not UnitAlive(target)) or (GetUnitTypeId(dex.source) == 0) then
                call PoisonDestroy(dex)
            else
                call WaveRecordDamageCredit(dex.source, target)
                call UnitDamageTarget(dex.source, target, dex.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                call ShowCustomLoadoutText(target, "-" + FormatLoadoutDamageText(dex.damage), POISON_TEXT_R, POISON_TEXT_G, POISON_TEXT_B)
                if ticks <= 0 then
                    call PoisonDestroy(dex)
                else
                    set dex.count = ticks
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
        
        // Initial impact has no minus sign
        call WaveRecordDamageCredit(source, target)
        call UnitDamageTarget(source, target, damagePerSecond, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
        call ShowCustomLoadoutText(target, FormatLoadoutDamageText(damagePerSecond), POISON_TEXT_R, POISON_TEXT_G, POISON_TEXT_B)

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

        set dex.count = ticks
        call PoisonListAdd(dex)
        if poisonTicker == null then
            set poisonTicker = NewTimer()
            call TimerStart(poisonTicker, LOADOUT_ORB_POISON_TICK_INTERVAL, true, function OnPoisonTick)
        endif
    endfunction

    // Impact Dummy cleanup
    private function OnImpactDummyExpire takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local integer id = GetTimerData(t)
        
        if impactFx[id] != null then
            call DestroyEffect(impactFx[id])
            set impactFx[id] = null
        endif
        
        if impactDummy[id] != null then
            call RemoveUnit(impactDummy[id])
            set impactDummy[id] = null
        endif
        
        call SpellIndex(id).destroy()
        call ReleaseTimer(t)
        set t = null
    endfunction

    private struct LeapMissileCore extends array
        private static method onRemove takes Missile missile returns boolean
            local SpellIndex dex = missile.data
            
            // Clean up Caster Fx
            if casterFx1[missile] != null then
                call DestroyEffect(casterFx1[missile])
                set casterFx1[missile] = null
            endif
            if casterFx2[missile] != null then
                call DestroyEffect(casterFx2[missile])
                set casterFx2[missile] = null
            endif
            // Clean up Dummy Fx
            if dummyFx1[missile] != null then
                call DestroyEffect(dummyFx1[missile])
                set dummyFx1[missile] = null
            endif
            if dummyFx2[missile] != null then
                call DestroyEffect(dummyFx2[missile])
                set dummyFx2[missile] = null
            endif
            // Clean up Ray
            if rayLightning[missile] != null then
                call DestroyLightning(rayLightning[missile])
                set rayLightning[missile] = null
            endif
            if companionDummy[missile] != null then
                call RemoveUnit(companionDummy[missile])
                set companionDummy[missile] = null
            endif
            if delayedAnimTimer[dex] != null then
                call ReleaseTimer(delayedAnimTimer[dex])
                set delayedAnimTimer[dex] = null
            endif
            
            // Re-enable target unit and reset tags
            if (GetUnitTypeId(dex.source) != 0) then
                if ANIMATION_TAG != "" then
                    call AddUnitAnimationProperties(dex.source, ANIMATION_TAG, false)
                endif
                call UnitRemoveAbility(dex.source, BUFF_APPLIED_ID)
            endif
            
            call dex.destroy()
            return true
        endmethod

        private static method onPeriod takes Missile missile returns boolean
            local SpellIndex dex = missile.data
            local unit source = dex.source
            local unit companion = companionDummy[missile]
            local real x = missile.x
            local real y = missile.y
            local real z = missile.z + missile.terrainZ
            local real flightOffset = GetPlayerLeapDummyFlightOffset(dex.user)
            local unit enumUnit
            local real damage
            
            if (GetUnitTypeId(source) == 0) or IsUnitType(source, UNIT_TYPE_DEAD) then
                return true // End leap if caster died
            endif

            if companion != null and GetUnitTypeId(companion) != 0 then
                call SetUnitX(companion, x)
                call SetUnitY(companion, y)
                call SetUnitFlyHeight(companion, z + flightOffset, 0.0)
            endif
            
            // Move Lightning for Ray
            if bonusActive[missile] and specialAbility[missile] == LOADOUT_ORB_ABILITY_RAY then
                if rayLightning[missile] != null then
                    call MoveLightningEx(rayLightning[missile], true, x, y, missile.z + missile.terrainZ, x, y, missile.terrainZ)
                endif
                
                // Damage targets below
                set damage = storedDamage[missile]
                call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, BASE_IMPACT_AREA, null)
                loop
                    set enumUnit = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                    exitwhen enumUnit == null
                    call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, enumUnit)
                    if IsUnitEnemy(enumUnit, dex.user) and not IsUnitType(enumUnit, UNIT_TYPE_DEAD) and not IsUnitType(enumUnit, UNIT_TYPE_MAGIC_IMMUNE) and (not missile.hasHitWidget(enumUnit)) then
                        call missile.hitWidget(enumUnit)
                        call WaveRecordDamageCredit(source, enumUnit)
                        call UnitDamageTarget(source, enumUnit, damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                        call DestroyEffect(AddSpecialEffectTarget(RAY_HIT_FX, enumUnit, RAY_HIT_FX_ATTACH))
                    endif
                endloop
            endif

            return false
        endmethod

        private static method applyImpact takes Missile missile returns nothing
            local SpellIndex dex = missile.data
            local unit source = dex.source
            local real x = missile.x
            local real y = missile.y
            local real baseArea = BASE_IMPACT_AREA
            local real finalDamage = storedDamage[missile]
            local real bloodMult
            local integer inst = effectInstances[missile]
            local integer abilityChoice = specialAbility[missile]
            local boolean bonus = bonusActive[missile]
            local unit enumUnit
            local timer t
            local integer tid
            local integer bloodPct
            local unit iDummy
            local sound s
            local string impactModel = GetPlayerLeapImpactFx(dex.user)
            local real dummyScale = GetLeapMissileScaleForArea(baseArea)

            call UnitRemoveAbility(source, BUFF_APPLIED_ID)
            
            if bonus and abilityChoice == LOADOUT_ORB_ABILITY_WIND then
                set baseArea = GetLeapMissileWindArea(inst)
            endif
            set dummyScale = GetLeapMissileScaleForArea(baseArea)

            // Fire modifies raw damage.
            if bonus and abilityChoice == LOADOUT_ORB_ABILITY_FIRE then
                set finalDamage = LoadoutGetFireDamage(storedDamage[missile], inst)
            endif

            // Create Impact Dummy
            set iDummy = CreateUnit(dex.user, 'dumi', x, y, 270)
            call UnitAddAbility(iDummy, 'Aloc') // Locust
            call PauseUnit(iDummy, true)
            call SetUnitScale(iDummy, dummyScale, dummyScale, dummyScale)
            
            if IMPACT_SOUND != "" then
                set s = CreateSound(IMPACT_SOUND, false, false, false, 10, 10, "")
                call SetSoundPosition(s, x, y, 0)
                call SetSoundVolume(s, 127)
                call StartSound(s)
                call KillSoundWhenDone(s)
                set s = null
            endif

            if impactModel != null and impactModel != "" then
                // We create a timer to destroy the effect properly
                set tid = SpellIndex.create()
                set t = NewTimerEx(tid)
                set impactDummy[tid] = iDummy
                set impactFx[tid] = AddSpecialEffectTarget(impactModel, iDummy, "origin")
                call TimerStart(t, IMPACT_FX_DURATION, false, function OnImpactDummyExpire)
            else
                call RemoveUnit(iDummy)
            endif
            set iDummy = null

            // Area Damage
            call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, baseArea, null)
            loop
                set enumUnit = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                exitwhen enumUnit == null
                
                if IsUnitEnemy(enumUnit, dex.user) and not IsUnitType(enumUnit, UNIT_TYPE_DEAD) and not IsUnitType(enumUnit, UNIT_TYPE_MAGIC_IMMUNE) then
                    // Ray: Normal damage
                    if abilityChoice == LOADOUT_ORB_ABILITY_RAY or not bonus then
                        call WaveRecordDamageCredit(source, enumUnit)
                        call UnitDamageTarget(source, enumUnit, finalDamage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                    
                    // Poison: DoT
                    elseif bonus and abilityChoice == LOADOUT_ORB_ABILITY_POISON then
                        call ApplyPoison(source, enumUnit, LoadoutGetPoisonTickDamage(storedDamage[missile]), LoadoutGetPoisonDuration(inst))
                    
                    // Dark: Max HP %
                    elseif bonus and abilityChoice == LOADOUT_ORB_ABILITY_DARK then
                        set finalDamage = storedDamage[missile] + LoadoutGetDarkBonus(enumUnit, inst)
                        call WaveRecordDamageCredit(source, enumUnit)
                        call UnitDamageTarget(source, enumUnit, finalDamage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                        call ShowCustomLoadoutText(enumUnit, FormatLoadoutDamageText(finalDamage), DARK_TEXT_R, DARK_TEXT_G, DARK_TEXT_B)

                    // Fire: Just display text
                    elseif bonus and abilityChoice == LOADOUT_ORB_ABILITY_FIRE then
                        call WaveRecordDamageCredit(source, enumUnit)
                        call UnitDamageTarget(source, enumUnit, finalDamage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                        call ShowCustomLoadoutText(enumUnit, FormatLoadoutDamageText(finalDamage), FIRE_TEXT_R, FIRE_TEXT_G, FIRE_TEXT_B)

                    // Blood: Just display text
                    elseif bonus and abilityChoice == LOADOUT_ORB_ABILITY_BLOOD then
                        set bloodMult = LoadoutGetBloodRandomMultiplier(inst)
                        set finalDamage = storedDamage[missile]*bloodMult
                        set bloodPct = LoadoutBloodMultiplierToPercent(bloodMult)
                        call WaveRecordDamageCredit(source, enumUnit)
                        call UnitDamageTarget(source, enumUnit, finalDamage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                        call ShowCustomLoadoutText(enumUnit, FormatLoadoutDamageText(finalDamage) + "   //" + I2S(bloodPct) + "%", BLOOD_TEXT_R, BLOOD_TEXT_G, BLOOD_TEXT_B)
                    
                    // Wind: Just damage
                    elseif bonus and abilityChoice == LOADOUT_ORB_ABILITY_WIND then
                        set finalDamage = LoadoutGetWindDamage(storedDamage[missile])
                        call WaveRecordDamageCredit(source, enumUnit)
                        call UnitDamageTarget(source, enumUnit, finalDamage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                    endif
                endif
                
                call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, enumUnit)
            endloop
        endmethod

        private static method onFinish takes Missile missile returns boolean
            call applyImpact(missile)
            return true
        endmethod

        private static method onCollide takes Missile missile, unit hit returns boolean
            return false // Leap doesn't collide with units mid-air
        endmethod

        private static method onDestructable takes Missile missile, destructable dest returns boolean
            return false // Leap doesn't collide with trees
        endmethod

        implement MissileStruct
    endstruct

    private function Cleanup takes SpellIndex dex returns nothing
        local unit source = dex.source
        local integer id = GetHandleId(source)
        if active.has(id) and (active[id] == dex) then
            call active.remove(id)
        endif
        if GetUnitTypeId(source) != 0 then
            call SetUnitTimeScale(source, ANIMATION_TIME_SCALE_ON_END)
        endif
        if delayedAnimTimer[dex] != null then
            call ReleaseTimer(delayedAnimTimer[dex])
            set delayedAnimTimer[dex] = null
        endif
        set rapidTargetX[dex] = 0.0
        set rapidTargetY[dex] = 0.0
        call ReleaseTimer(dex.clock)
        call dex.destroy()
        set source = null
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
                if ANIMATION_TAG != "" then
                    call AddUnitAnimationProperties(source, ANIMATION_TAG, true)
                endif
            endif
        endif
        
        call ReleaseTimer(t)
        set source = null
        set t = null
    endfunction

    private function FireLeapMissile takes SpellIndex dex returns nothing
        local unit source = dex.source
        local player owner = dex.user
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real tx = rapidTargetX[dex]
        local real ty = rapidTargetY[dex]
        local real dx = tx - x
        local real dy = ty - y
        local real distance = SquareRoot(dx * dx + dy * dy)
        local real arc = 0.0
        local real speed
        local real damage
        local integer instances
        local integer chosen
        local integer chosenLevel
        local SpellIndex mDex
        local Missile missile
        local string cFx1 = GetPlayerLeapCasterFx1(owner)
        local string cFx2 = GetPlayerLeapCasterFx2(owner)
        local string dFx1 = GetPlayerLeapDummyFx1(owner)
        local string dFx2 = GetPlayerLeapDummyFx2(owner)
        local real dummyScale = 1.0
        local real companionFacing = Atan2(ty - y, tx - x)*bj_RADTODEG
        local integer companionUnitId = GetPlayerLeapCompanionUnitId(owner)
        local unit buffDummy
        local unit companion
        local unit fxTarget

        set chosen = GetPlayerMissileAbilityChoice(owner)
        set chosenLevel = 0
        if chosen != 0 then
            set chosenLevel = GetUnitAbilityLevel(source, chosen)
        endif

        if USE_FIXED_TIME then
            if FIXED_JUMP_TIME > 0.0 then
                set speed = distance / FIXED_JUMP_TIME
            else
                set speed = BASE_JUMP_SPEED
            endif
        else
            set speed = BASE_JUMP_SPEED + GetPlayerMissileSpeedBonus(owner)
        endif

        if speed < 1.0 then
            set speed = 1.0
        endif

        set damage = GetPlayerMissileDamageValue(owner)
        if damage < 0. then
            set damage = 0.
        endif
        set instances = GetPlayerMissileInstanceCount(owner)
        if instances < 1 then
            set instances = 1
        endif

        set mDex = SpellIndex.create()
        set mDex.source = source
        set mDex.user = owner
        set missile = Missile.createXYZ(x, y, 0.0, tx, ty, 0.0)
        set missile.data = mDex
        set missile.collision = 0.0 // Important so it doesnt collide
        if distance > 0.0 then
            set arc = Atan((4.0*BASE_JUMP_HEIGHT)/distance)
        else
            set arc = 0.0
        endif
        set missile.arc = arc
        if USE_FIXED_TIME and FIXED_JUMP_TIME > 0.0 then
            call missile.flightTime2Speed(FIXED_JUMP_TIME)
        else
            call missile.setMovementSpeed(speed)
        endif

        set specialAbility[missile] = chosen
        set storedDamage[missile] = damage
        set effectInstances[missile] = instances
        set bonusActive[missile] = (chosen != 0) and (chosenLevel > 0)

        if companionUnitId == 0 then
            set companionUnitId = COMPANION_DUMMY_FALLBACK_ID
        endif
        set companion = CreateUnit(owner, companionUnitId, x, y, 0.0)
        if companion != null and GetUnitTypeId(companion) != 0 then
            call UnitAddAbility(companion, 'Aloc')
            call UnitAddAbility(companion, 'Amrf')
            call UnitRemoveAbility(companion, 'Amrf')
            call SetUnitPathing(companion, false)
            call PauseUnit(companion, true)
            call SetUnitFacing(companion, companionFacing)
            call SetUnitScale(companion, dummyScale, dummyScale, dummyScale)
            call SetUnitFlyHeight(companion, 0.0, 0.0)
            set companionDummy[missile] = companion
        else
            set companionDummy[missile] = null
        endif
        
        set fxTarget = companionDummy[missile]
        if fxTarget == null or GetUnitTypeId(fxTarget) == 0 then
            set fxTarget = missile.dummy
            call SetUnitScale(fxTarget, dummyScale, dummyScale, dummyScale)
        endif

        // Attach all launch FX to the dummy visual target
        if fxTarget != null and GetUnitTypeId(fxTarget) != 0 then
            if cFx1 != null and cFx1 != "" then
                set casterFx1[missile] = AddSpecialEffectTarget(cFx1, fxTarget, "chest")
            endif
            if cFx2 != null and cFx2 != "" then
                set casterFx2[missile] = AddSpecialEffectTarget(cFx2, fxTarget, "origin")
            endif
            if dFx1 != null and dFx1 != "" then
                set dummyFx1[missile] = AddSpecialEffectTarget(dFx1, fxTarget, "chest")
            endif
            if dFx2 != null and dFx2 != "" then
                set dummyFx2[missile] = AddSpecialEffectTarget(dFx2, fxTarget, "origin")
            endif
        endif

        // Special Ray init
        if bonusActive[missile] and chosen == LOADOUT_ORB_ABILITY_RAY then
            set rayLightning[missile] = AddLightningEx(RAY_LIGHTNING_TYPE, true, x, y, 0.0, x, y, 0.0)
        endif
        
        // Buff the caster during flight
        set buffDummy = CreateUnit(owner, 'dumi', x, y, 0)
        call UnitAddAbility(buffDummy, 'Aloc')
        call UnitAddAbility(buffDummy, BUFF_CAST_ID)
        call IssueTargetOrderById(buffDummy, ORDER_ID, source)
        call UnitApplyTimedLife(buffDummy, 'BTLF', 1.0)
        set buffDummy = null
        set companion = null
        set fxTarget = null
        
        call LeapMissileCore.launch(missile)

        set source = null
        set owner = null
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
            call Cleanup(dex)
            set t = null
            return
        endif

        call SetUnitAnimation(dex.source, CAST_ANIMATION)
        call FireLeapMissile(dex)
        set dex.time = dex.time - step

        if dex.time <= 0. then
            call Cleanup(dex)
        endif

        set t = null
    endfunction

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        local integer id = GetHandleId(source)
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real tx = GetSpellTargetX()
        local real ty = GetSpellTargetY()
        local SpellIndex dex
        local real step = GetSafeFireInterval()
        local boolean useRapid = GetPlayerMissileUseRapidFire(owner)

        if not IsPointJumpable(tx, ty) then
            call SimError(owner, GetUnitName(source) + " can't jump there!")
            set source = null
            set owner = null
            return
        endif

        if not IsVisibleToPlayer(tx, ty, owner) then
            call SimError(owner, GetUnitName(source) + " needs vision at target!")
            set source = null
            set owner = null
            return
        endif

        if active.has(id) then
            set dex = active[id]
            if (dex.phase >= 0) and (GetUnitTypeId(dex.source) != 0) and UnitAlive(dex.source) then
                set rapidTargetX[dex] = tx
                set rapidTargetY[dex] = ty
                set dex.time = FIRE_DURATION
                call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
                set source = null
                set owner = null
                return
            endif
            call Cleanup(dex)
        endif

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = owner
        if useRapid and (FIRE_DURATION > 0.) then
            set dex.time = FIRE_DURATION
        else
            set dex.time = 0.
        endif
        set dex.phase = 1
        set dex.clock = NewTimerEx(dex)
        set rapidTargetX[dex] = tx
        set rapidTargetY[dex] = ty
        set active[id] = dex

        set delayedAnimTimer[dex] = NewTimerEx(dex)
        call TimerStart(delayedAnimTimer[dex], FIRST_ANIMATION_DELAY, false, function DelayedStartAnimation)

        call SetUnitTimeScale(source, RAPID_FIRE_ANIMATION_TIME_SCALE)
        call FireLeapMissile(dex)
        set dex.time = dex.time - step

        if dex.time > 0. then
            call TimerStart(dex.clock, step, true, function OnPeriodic)
        else
            call Cleanup(dex)
        endif

        set source = null
        set owner = null
    endfunction

    private function Init takes nothing returns nothing
        set active = Table.create()
        set error = CreateSoundFromLabel("InterfaceError", false, false, false, 10, 10)
        call RegisterSpellEffectEvent(LOADOUT_LEAP_MISSILE_SPELL, function OnEffect)
    endfunction
endlibrary
