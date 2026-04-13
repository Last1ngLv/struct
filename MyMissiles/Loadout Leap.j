library LoadoutLeap initializer Init uses TimerUtils, Table, SpellIndex, Missile, PlayerMissileLoadout, IsUnitChanneling, DamageTextUtil, LoadoutOrbBalance, IsTerrainWalkable, SimError, WaveDamageCredit
//**
//* User settings:
//* ==============
    globals
        private constant integer LOADOUT_LEAP_SPELL = 'U0A2'

        //* Base Jump settings
        private constant real BASE_JUMP_HEIGHT = 550.0
        private constant real BASE_JUMP_SPEED = 1200.0
        private constant boolean USE_FIXED_TIME = false
        private constant real FIXED_JUMP_TIME = 1.20

        //* Base Impact Settings
        private constant real BASE_IMPACT_AREA = 250.0
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        private constant real IMPACT_FX_DURATION = 1.00
        private constant real IMPACT_DUMMY_BASE_SCALE = 0.75
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

        //* Orbs Balance (visual-only add-on for wind dummy size).
        private constant real WIND_SCALE_BONUS = 0.15 // Dummy gets +0.50 scale per instance
        
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
        private Table activeLeapMissileByUnit

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
        private real array impactRemaining
        private integer array impactNext
        private integer array impactPrev
        private integer impactHead = 0
        private timer impactTicker = null
        private effect array poisonFx
        private integer array poisonNext
        private integer array poisonPrev
        private integer poisonHead = 0
        private timer poisonTicker = null
    endglobals
    
    private keyword LeapCore

    private function IsPointJumpable takes real x, real y returns boolean
        if not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
            return IsTerrainWalkable(x, y)
        endif
        return false
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
            call SetTimerDebugTag(poisonTicker, TIMER_DEBUG_TAG_LOADOUT_LEAP)
            call TimerStart(poisonTicker, LOADOUT_ORB_POISON_TICK_INTERVAL, true, function OnPoisonTick)
        endif
    endfunction

    // Impact Dummy cleanup
    private function ImpactListAdd takes integer id returns nothing
        set impactPrev[id] = 0
        set impactNext[id] = impactHead
        if impactHead != 0 then
            set impactPrev[impactHead] = id
        endif
        set impactHead = id
    endfunction

    private function ImpactListRemove takes integer id returns nothing
        local integer p = impactPrev[id]
        local integer n = impactNext[id]
        if p != 0 then
            set impactNext[p] = n
        else
            set impactHead = n
        endif
        if n != 0 then
            set impactPrev[n] = p
        endif
        set impactPrev[id] = 0
        set impactNext[id] = 0
    endfunction

    private function DestroyImpactDummy takes integer id returns nothing
        call ImpactListRemove(id)
        if impactFx[id] != null then
            call DestroyEffect(impactFx[id])
            set impactFx[id] = null
        endif
        if impactDummy[id] != null then
            call RemoveUnit(impactDummy[id])
            set impactDummy[id] = null
        endif
        set impactRemaining[id] = 0.0
        call SpellIndex(id).destroy()
    endfunction

    private function OnImpactTicker takes nothing returns nothing
        local integer node = impactHead
        local integer nextNode
        loop
            exitwhen node == 0
            set nextNode = impactNext[node]
            set impactRemaining[node] = impactRemaining[node] - 0.03125
            if impactRemaining[node] <= 0.0 then
                call DestroyImpactDummy(node)
            endif
            set node = nextNode
        endloop
        if (impactHead == 0) and (impactTicker != null) then
            call ReleaseTimer(impactTicker)
            set impactTicker = null
        endif
    endfunction

    private function QueueImpactDummy takes unit whichDummy, string impactModel returns nothing
        local integer id
        if whichDummy == null or GetUnitTypeId(whichDummy) == 0 then
            return
        endif
        if impactModel == null or impactModel == "" then
            call RemoveUnit(whichDummy)
            return
        endif
        set id = SpellIndex.create()
        set impactDummy[id] = whichDummy
        set impactFx[id] = AddSpecialEffectTarget(impactModel, whichDummy, "origin")
        set impactRemaining[id] = IMPACT_FX_DURATION
        call ImpactListAdd(id)
        if impactTicker == null then
            set impactTicker = NewTimer()
            call SetTimerDebugTag(impactTicker, TIMER_DEBUG_TAG_LOADOUT_LEAP)
            call TimerStart(impactTicker, 0.03125, true, function OnImpactTicker)
        endif
    endfunction

    private struct LeapCore extends array
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
                if activeLeapMissileByUnit.has(GetHandleId(dex.source)) and activeLeapMissileByUnit[GetHandleId(dex.source)] == missile then
                    call activeLeapMissileByUnit.remove(GetHandleId(dex.source))
                endif
                if ANIMATION_TAG != "" then
                    call AddUnitAnimationProperties(dex.source, ANIMATION_TAG, false)
                endif
                call SetUnitPathing(dex.source, true)
                call SetUnitTimeScale(dex.source, 1.0)
                call SetUnitFlyHeight(dex.source, 0.0, 99999.)
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
            local integer bloodPct
            local unit iDummy
            local sound s
            local string impactModel = GetPlayerLeapImpactFx(dex.user)
            local real dummyScale = IMPACT_DUMMY_BASE_SCALE

            call SetUnitFlyHeight(source, 0.0, 0.0)
            call UnitRemoveAbility(source, BUFF_APPLIED_ID)
            
            if bonus and abilityChoice == LOADOUT_ORB_ABILITY_WIND then
                set baseArea = LoadoutGetWindAoe(inst)
                set dummyScale = dummyScale + (WIND_SCALE_BONUS * inst)
            endif

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

            call QueueImpactDummy(iDummy, impactModel)
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


    private function DelayedStartAnimation takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit source = dex.source
        set delayedAnimTimer[dex] = null
        
        if (GetUnitTypeId(source) != 0) and UnitAlive(source) then
            call SetUnitAnimation(source, CAST_ANIMATION)
            if ANIMATION_TAG != "" then
                call AddUnitAnimationProperties(source, ANIMATION_TAG, true)
            endif
        endif
        
        call ReleaseTimer(t)
        set source = null
        set t = null
    endfunction

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real tx = GetSpellTargetX()
        local real ty = GetSpellTargetY()
        local real dx = tx - x
        local real dy = ty - y
        local real distance = SquareRoot(dx * dx + dy * dy)
        local real arc = 0.0
        local real speed
        local real damage
        local integer instances
        local integer chosen
        local integer chosenLevel
        local SpellIndex dex
        local Missile missile
        
        local string cFx1 = GetPlayerLeapCasterFx1(owner)
        local string cFx2 = GetPlayerLeapCasterFx2(owner)
        local string dFx1 = GetPlayerLeapDummyFx1(owner)
        local string dFx2 = GetPlayerLeapDummyFx2(owner)
        local real dummyScale = GetPlayerLeapDummyScale(owner)
        local real companionFacing = Atan2(ty - y, tx - x)*bj_RADTODEG
        local integer companionUnitId = GetPlayerLeapCompanionUnitId(owner)
        local unit buffDummy
        local unit companion

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

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = owner
        set missile = Missile.createEx(source, tx, ty, 0.0)
        set missile.data = dex
        set activeLeapMissileByUnit[GetHandleId(source)] = missile
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
        
        // Add Crow Form so caster can fly
        if UnitAddAbility(source, 'Amrf') and UnitRemoveAbility(source, 'Amrf') then
        endif
        
        // Disable pathing so caster flies over things
        call SetUnitPathing(source, false)

        // Attach Caster FX
        if cFx1 != null and cFx1 != "" then
            set casterFx1[missile] = AddSpecialEffectTarget(cFx1, source, "chest")
        endif
        if cFx2 != null and cFx2 != "" then
            set casterFx2[missile] = AddSpecialEffectTarget(cFx2, source, "origin")
        endif
        // Attach Dummy FX
        if companionDummy[missile] != null then
            if dFx1 != null and dFx1 != "" then
                set dummyFx1[missile] = AddSpecialEffectTarget(dFx1, companionDummy[missile], "chest")
            endif
            if dFx2 != null and dFx2 != "" then
                set dummyFx2[missile] = AddSpecialEffectTarget(dFx2, companionDummy[missile], "origin")
            endif
        endif

        // Special Ray init
        if bonusActive[missile] and chosen == LOADOUT_ORB_ABILITY_RAY then
            set rayLightning[missile] = AddLightningEx(RAY_LIGHTNING_TYPE, true, x, y, 0.0, x, y, 0.0)
        endif

        set delayedAnimTimer[dex] = NewTimerEx(dex)
        call SetTimerDebugTag(delayedAnimTimer[dex], TIMER_DEBUG_TAG_LOADOUT_LEAP)
        call TimerStart(delayedAnimTimer[dex], FIRST_ANIMATION_DELAY, false, function DelayedStartAnimation)
        
        // Buff the caster during flight
        set buffDummy = CreateUnit(owner, 'dumi', x, y, 0)
        call UnitAddAbility(buffDummy, 'Aloc')
        call UnitAddAbility(buffDummy, BUFF_CAST_ID)
        call IssueTargetOrderById(buffDummy, ORDER_ID, source)
        call UnitApplyTimedLife(buffDummy, 'BTLF', 1.0)
        set buffDummy = null
        set companion = null
        
        call LeapCore.launch(missile)

        set source = null
        set owner = null
    endfunction

    function CancelLoadoutLeapForUnit takes unit u returns nothing
        local integer hid
        local Missile missile
        if u == null or GetUnitTypeId(u) == 0 then
            return
        endif
        set hid = GetHandleId(u)
        if hid != 0 and activeLeapMissileByUnit.has(hid) then
            set missile = activeLeapMissileByUnit[hid]
            call activeLeapMissileByUnit.remove(hid)
            if missile != 0 then
                call missile.terminate()
            endif
        elseif GetUnitAbilityLevel(u, BUFF_APPLIED_ID) > 0 then
            call UnitRemoveAbility(u, BUFF_APPLIED_ID)
            call SetUnitPathing(u, true)
            call SetUnitTimeScale(u, 1.0)
            call SetUnitFlyHeight(u, 0.0, 99999.)
        endif
    endfunction

    private function Init takes nothing returns nothing
        set activeLeapMissileByUnit = Table.create()
        set error = CreateSoundFromLabel("InterfaceError", false, false, false, 10, 10)
        call RegisterSpellEffectEvent(LOADOUT_LEAP_SPELL, function OnEffect)
    endfunction
endlibrary
