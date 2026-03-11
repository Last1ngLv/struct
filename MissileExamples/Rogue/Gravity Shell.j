//TESH.scrollpos=0
//TESH.alwaysfold=0
library GravityShell initializer Init uses SpellIndex, Missile, DummyCaster /* v1.0
*************************************************************************************
*
*   Launches a projectile towards the cast point with configurable deceleration.
*   The projectile does no damage while traveling.
*   On finish it explodes in area and can spawn radial projectiles.
*
*   Optional path-catch mode:
*       - On collision, catches up to N units in an area.
*       - Caught units are lifted, stunned and then fall, dealing AoE damage.
*       - At max lift height it can spawn radial projectiles.
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer GRAVITY_SHELL_ABILITY = 'S00C'
        //* Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        //* Main projectile launch options.
        private constant real PROJECTILE_START_Z = 65.
        private constant string PROJECTILE_MODEL = "units\\critters\\Penguin\\Penguin.mdl"
        private constant real PROJECTILE_SCALE = 1.95
        private constant real PROJECTILE_COLLISION = 96.
        //* Main projectile speed profile.
        private constant real PROJECTILE_DECEL_TIME = 1.15     //* Total intended flight time.
        private constant real ADJUST_START_TIME = 0.25        //* At this time, switch from phase-1 correction to final correction.
        private constant real ADJUST_START_DISTANCE_RATIO = 0.98//* By ADJUST_START_TIME, projectile should reach this % of total distance.
        private constant real MIN_ACTIVE_SPEED = 1.00          //* Safety floor to avoid missile stall at 0 speed.
        //* Main impact.
        private constant real MAIN_IMPACT_AOE = 200.
        private constant string MAIN_IMPACT_FX = "Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl"
        private constant real MAIN_IMPACT_DAMAGE_BASE = 80.
        private constant real MAIN_IMPACT_DAMAGE_PER_LEVEL = 50.
        //* Caught-unit landing impact.
        private constant real CATCH_IMPACT_AOE = 220.
        private constant string CATCH_IMPACT_FX = "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl"
        private constant real CATCH_IMPACT_DAMAGE_BASE = 60.
        private constant real CATCH_IMPACT_DAMAGE_PER_LEVEL = 35.
        //* Sounds.
        private constant string LAUNCH_SOUND = "war3mapImported\\By_Yeti_Kcharte_vos.mp3"
        private constant string IMPACT_SOUND = "war3mapImported\\YetixGemi.mp3"
        private constant real RADIAL_LAUNCH_PITCH = 1.2
        private constant real IMPACT_SOUND_PITCH = 1.2
        //* Caster animation on cast (delayed to avoid cast-order conflict).
        private constant string CAST_ANIMATION = "attack"
        private constant real FIRST_ANIMATION_DELAY = 0.03
        //* Optional path-catch mode.
        private constant boolean ENABLE_PATH_CATCH = true
        private constant integer MAX_CAUGHT_UNITS = 3
        private constant real EXTRA_CATCH_AOE = 250.
        private constant real CATCH_LIFT_HEIGHT = 1000.
        private constant real CATCH_RISE_TIME = 0.25
        private constant real CATCH_FALL_TIME = 0.90
        private constant real CATCH_RISE_ADJUST_TIME = 0.10
        private constant real CATCH_RISE_ADJUST_HEIGHT_RATIO = 0.70
        private constant real CATCH_FALL_ADJUST_TIME = 0.30
        private constant real CATCH_FALL_ADJUST_HEIGHT_RATIO = 0.60
        private constant real CATCH_MOTION_PERIOD = 0.03125
        private constant integer STUN_BUFF_CAST_ID = 'A006'
        private constant integer STUN_ORDER_ID = 852095 //* thunderbolt
        //* Optional branch A: spawn radial projectiles at peak height of caught unit.
        private constant boolean SPAWN_RADIAL_ON_CATCH_PEAK = true
        private constant real CATCH_PEAK_RADIAL_DISTANCE = 400.
        //* Optional branch B: if main projectile hits no unit, use bigger AoE and spawn radials.
        private constant boolean NO_HIT_BIG_AOE_AND_RADIAL = true
        private constant real NO_HIT_BIG_AOE = 325.
        private constant real NO_HIT_RADIAL_DISTANCE = 500.
        //* Shared radial projectile options.
        private constant integer RADIAL_PROJECTILE_COUNT = 8
        private constant real RADIAL_IMPACT_AOE = 140.
        private constant string RADIAL_IMPACT_FX = "Abilities\\Weapons\\Bolt\\BoltImpact.mdl"
        private constant real RADIAL_DAMAGE_BASE = 35.
        private constant real RADIAL_DAMAGE_PER_LEVEL = 20.
    endglobals
    
    private keyword ShockCore

    private constant function GetMainImpactDamage takes integer level returns real
        return MAIN_IMPACT_DAMAGE_BASE + MAIN_IMPACT_DAMAGE_PER_LEVEL*level
    endfunction

    private constant function GetCatchImpactDamage takes integer level returns real
        return CATCH_IMPACT_DAMAGE_BASE + CATCH_IMPACT_DAMAGE_PER_LEVEL*level
    endfunction

    private constant function GetRadialDamage takes integer level returns real
        return RADIAL_DAMAGE_BASE + RADIAL_DAMAGE_PER_LEVEL*level
    endfunction

    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
    endfunction

//========================================================================
//* Gravity shell code. Make changes carefully.
//========================================================================

    globals
        private constant integer KIND_MAIN = 1
        private constant integer KIND_RADIAL = 2

        private integer array missileKind
        private real array currentSpeed
        private real array decelElapsed
        private real array elapsedTotal
        private real array profileDecelDuration
        private real array profileStartDecelTime
        private real array profileStartDecelDistanceRatio
        private boolean array decelStarted
        private real array profileInitSpeed
        private real array profileMinSpeed
        private real array profileDecelTime
        private boolean array mainCaught
        private sound array mainLaunchSound
        private integer array catchStage
        private boolean array catchPeakRadialEnabled
        private real array catchElapsed
        private real array catchBaseHeight
        private real array catchDistanceTotal
        private real array catchDistanceProgress
        private real array radialAoe
        private real array radialDamage
    endglobals

    private function PlayLaunchSound takes unit source, real pitch returns nothing
        local sound s = CreateSound(LAUNCH_SOUND, false, false, false, 10, 10, "")
        call SetSoundPitch(s, pitch)
        if source != null then
            call AttachSoundToUnit(s, source)
        endif
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function StartLaunchSound takes unit source, real pitch returns sound
        local sound s = CreateSound(LAUNCH_SOUND, false, false, false, 10, 10, "")
        call SetSoundPitch(s, pitch)
        if source != null then
            call AttachSoundToUnit(s, source)
        endif
        call StartSound(s)
        return s
    endfunction

    private function StopLaunchSound takes sound s returns nothing
        if s != null then
            call SetSoundVolume(s, 0)
            call StopSound(s, true, true)
            call KillSoundWhenDone(s)
        endif
    endfunction

    private function PlayImpactSound takes real x, real y returns nothing
        local sound s = CreateSound(IMPACT_SOUND, false, false, false, 10, 10, "")
        call SetSoundPosition(s, x, y, 0.)
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function PlayImpactSoundPitch takes real x, real y, real pitch returns nothing
        local sound s = CreateSound(IMPACT_SOUND, false, false, false, 10, 10, "")
        call SetSoundPitch(s, pitch)
        call SetSoundPosition(s, x, y, 0.)
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function PreloadSounds takes nothing returns nothing
        local sound s
        call Preload(LAUNCH_SOUND)
        call Preload(IMPACT_SOUND)

        set s = CreateSound(LAUNCH_SOUND, false, false, false, 10, 10, "")
        call SetSoundVolume(s, 0)
        call StartSound(s)
        call StopSound(s, false, false)
        call KillSoundWhenDone(s)

        set s = CreateSound(IMPACT_SOUND, false, false, false, 10, 10, "")
        call SetSoundVolume(s, 0)
        call StartSound(s)
        call StopSound(s, false, false)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function DelayedStartAnimation takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit source = dex.source

        if (GetUnitTypeId(source) != 0) and UnitAlive(source) then
            call SetUnitAnimation(source, CAST_ANIMATION)
        endif

        call ReleaseTimer(t)
        call dex.destroy()
        set source = null
        set t = null
    endfunction

    private function SetupSpeedProfile takes Missile missile returns nothing
        local real startTime
        local real startDistanceRatio
        local real distance
        local real time
        local real seedSpeed
        set profileDecelTime[missile] = PROJECTILE_DECEL_TIME
        set profileDecelDuration[missile] = PROJECTILE_DECEL_TIME
        set profileStartDecelTime[missile] = 0.
        set profileStartDecelDistanceRatio[missile] = 0.
        set decelStarted[missile] = false
        set profileInitSpeed[missile] = 0.
        set profileMinSpeed[missile] = 0.
        set decelElapsed[missile] = 0.
        set elapsedTotal[missile] = 0.

        if PROJECTILE_DECEL_TIME <= 0. then
            return
        endif

        set distance = missile.origin.distance
        if distance < 0. then
            set distance = 0.
        endif
        set time = PROJECTILE_DECEL_TIME
        set startTime = ADJUST_START_TIME
        set startDistanceRatio = ADJUST_START_DISTANCE_RATIO
        if startTime < 0. then
            set startTime = 0.
        elseif startTime > time then
            set startTime = time
        endif
        if startDistanceRatio < 0. then
            set startDistanceRatio = 0.
        elseif startDistanceRatio > 1. then
            set startDistanceRatio = 1.
        endif

        if time > 0. then
            set seedSpeed = distance/time
        else
            set seedSpeed = 0.
        endif

        if seedSpeed < 0. then
            set seedSpeed = 0.
        endif

        set profileDecelDuration[missile] = time - startTime
        if profileDecelDuration[missile] < 0. then
            set profileDecelDuration[missile] = 0.
        endif
        set profileStartDecelTime[missile] = startTime
        set profileStartDecelDistanceRatio[missile] = startDistanceRatio
        set profileInitSpeed[missile] = seedSpeed
        set profileMinSpeed[missile] = 0.

        call missile.setMovementSpeed(seedSpeed)
        set currentSpeed[missile] = seedSpeed
    endfunction

    private function ApplySpeedProfile takes Missile missile returns nothing
        local real decelTime
        local real startTime
        local real startDistanceRatio
        local real remainingTime
        local real remainingDistance
        local real phaseTargetDistance
        local real phaseRemainingTime
        local real elapsedNow
        local real desiredSpeed
        local real totalDistance
        set decelTime = profileDecelTime[missile]
        set startTime = profileStartDecelTime[missile]
        set startDistanceRatio = profileStartDecelDistanceRatio[missile]

        if decelTime <= 0. then
            return
        endif

        set totalDistance = missile.origin.distance
        set elapsedNow = elapsedTotal[missile] + Missile_TIMER_TIMEOUT

        if elapsedNow < startTime then
            // Phase 1 target: reach the time-proportional checkpoint by startTime.
            // This accelerates if behind and decelerates if ahead.
            set phaseTargetDistance = totalDistance*startDistanceRatio
            set remainingDistance = phaseTargetDistance - missile.distance
            if remainingDistance < 0. then
                set remainingDistance = 0.
            endif
            set phaseRemainingTime = startTime - elapsedNow
            if phaseRemainingTime <= Missile_TIMER_TIMEOUT then
                set desiredSpeed = remainingDistance/Missile_TIMER_TIMEOUT
            else
                set desiredSpeed = remainingDistance/phaseRemainingTime
            endif
        else
            // Phase 2 target: reach impact exactly at total time.
            set remainingDistance = totalDistance - missile.distance
            if remainingDistance < 0. then
                set remainingDistance = 0.
            endif
            set remainingTime = decelTime - elapsedNow
            if remainingDistance <= 0. then
                set desiredSpeed = 0.
            elseif remainingTime <= Missile_TIMER_TIMEOUT then
                set desiredSpeed = remainingDistance/Missile_TIMER_TIMEOUT
            else
                set desiredSpeed = remainingDistance/remainingTime
            endif
        endif

        if desiredSpeed < 0. then
            set desiredSpeed = 0.
        endif
        if (desiredSpeed < MIN_ACTIVE_SPEED) and (remainingDistance > 0.) then
            set desiredSpeed = MIN_ACTIVE_SPEED
        endif
        if currentSpeed[missile] != desiredSpeed then
            call missile.setMovementSpeed(desiredSpeed)
            set currentSpeed[missile] = desiredSpeed
        endif
        set elapsedTotal[missile] = elapsedNow
    endfunction

    private function DealAreaDamage takes unit source, player owner, real x, real y, real radius, real amount returns nothing
        local unit u
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, radius, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if FilterUnits(u, owner) then
                call UnitDamageTarget(source, u, amount, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
            endif
        endloop
    endfunction

    private function LaunchRadialProjectiles takes unit source, player owner, integer level, real x, real y, real z, real distance returns nothing
        local integer i = 0
        local real angle
        local Missile missile
        local real step
        local real damage = GetRadialDamage(level)
        if RADIAL_PROJECTILE_COUNT <= 0 then
            return
        endif
        set step = (2.*bj_PI)/RADIAL_PROJECTILE_COUNT
        loop
            exitwhen i >= RADIAL_PROJECTILE_COUNT
            set angle = step*i
            set missile = Missile.create(x, y, z, angle, distance, 0.)
            set missile.source = source
            set missile.owner = owner
            set missile.collision = 0.
            set missile.model = PROJECTILE_MODEL
            set missile.scale = PROJECTILE_SCALE
            set missileKind[missile] = KIND_RADIAL
            call SetupSpeedProfile(missile)
            set radialAoe[missile] = RADIAL_IMPACT_AOE
            set radialDamage[missile] = damage
            call ShockCore.launch(missile)
            call PlayLaunchSound(source, RADIAL_LAUNCH_PITCH)
            set i = i + 1
        endloop
    endfunction

    private function ComputeMotionSpeed takes real elapsed, real totalTime, real adjustTime, real adjustRatio, real totalDistance, real progressed returns real
        local real targetDistance
        local real remainingDistance
        local real remainingTime
        local real speed

        if totalDistance <= 0. then
            return 0.
        endif
        if adjustTime < 0. then
            set adjustTime = 0.
        elseif adjustTime > totalTime then
            set adjustTime = totalTime
        endif
        if adjustRatio < 0. then
            set adjustRatio = 0.
        elseif adjustRatio > 1. then
            set adjustRatio = 1.
        endif

        if elapsed < adjustTime then
            set targetDistance = totalDistance*adjustRatio
            set remainingDistance = targetDistance - progressed
            set remainingTime = adjustTime - elapsed
        else
            set remainingDistance = totalDistance - progressed
            set remainingTime = totalTime - elapsed
        endif

        if remainingDistance <= 0. then
            return 0.
        endif
        if remainingTime <= CATCH_MOTION_PERIOD then
            set speed = remainingDistance/CATCH_MOTION_PERIOD
        else
            set speed = remainingDistance/remainingTime
        endif
        if speed < MIN_ACTIVE_SPEED then
            set speed = MIN_ACTIVE_SPEED
        endif
        return speed
    endfunction

    private function ClearCaughtData takes SpellIndex dex returns nothing
        set catchStage[dex] = 0
        set catchPeakRadialEnabled[dex] = false
        set catchElapsed[dex] = 0.
        set catchBaseHeight[dex] = 0.
        set catchDistanceTotal[dex] = 0.
        set catchDistanceProgress[dex] = 0.
    endfunction

    private function OnCaughtMotion takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit u = dex.target
        local real speed
        local real step
        local real total
        local real h
        local real x
        local real y

        if (GetUnitTypeId(u) == 0) or (not UnitAlive(u)) then
            call ReleaseTimer(t)
            call ClearCaughtData(dex)
            call dex.destroy()
            set u = null
            set t = null
            return
        endif

        if catchStage[dex] == 0 then
            set total = catchDistanceTotal[dex]
            set speed = ComputeMotionSpeed(catchElapsed[dex], CATCH_RISE_TIME, CATCH_RISE_ADJUST_TIME, CATCH_RISE_ADJUST_HEIGHT_RATIO, total, catchDistanceProgress[dex])
            set step = speed*CATCH_MOTION_PERIOD
            if step > total - catchDistanceProgress[dex] then
                set step = total - catchDistanceProgress[dex]
            endif
            if step < 0. then
                set step = 0.
            endif
            set catchDistanceProgress[dex] = catchDistanceProgress[dex] + step
            call SetUnitFlyHeight(u, catchBaseHeight[dex] + catchDistanceProgress[dex], 99999.)
            set catchElapsed[dex] = catchElapsed[dex] + CATCH_MOTION_PERIOD

            if (catchDistanceProgress[dex] >= total) or (catchElapsed[dex] >= CATCH_RISE_TIME) then
                if SPAWN_RADIAL_ON_CATCH_PEAK and catchPeakRadialEnabled[dex] then
                    call LaunchRadialProjectiles(dex.source, dex.user, dex.level, GetUnitX(u), GetUnitY(u), catchBaseHeight[dex] + catchDistanceProgress[dex], CATCH_PEAK_RADIAL_DISTANCE)
                endif
                set catchStage[dex] = 1
                set catchElapsed[dex] = 0.
                set catchDistanceTotal[dex] = catchDistanceProgress[dex]
                set catchDistanceProgress[dex] = 0.
            endif

        else
            set total = catchDistanceTotal[dex]
            set speed = ComputeMotionSpeed(catchElapsed[dex], CATCH_FALL_TIME, CATCH_FALL_ADJUST_TIME, CATCH_FALL_ADJUST_HEIGHT_RATIO, total, catchDistanceProgress[dex])
            set step = speed*CATCH_MOTION_PERIOD
            if step > total - catchDistanceProgress[dex] then
                set step = total - catchDistanceProgress[dex]
            endif
            if step < 0. then
                set step = 0.
            endif
            set catchDistanceProgress[dex] = catchDistanceProgress[dex] + step
            set h = catchBaseHeight[dex] + total - catchDistanceProgress[dex]
            if h < 0. then
                set h = 0.
            endif
            call SetUnitFlyHeight(u, h, 99999.)
            set catchElapsed[dex] = catchElapsed[dex] + CATCH_MOTION_PERIOD

            if (catchDistanceProgress[dex] >= total) or (catchElapsed[dex] >= CATCH_FALL_TIME) then
                set x = GetUnitX(u)
                set y = GetUnitY(u)
                call SetUnitFlyHeight(u, 0., 99999.)
                call DestroyEffect(AddSpecialEffect(CATCH_IMPACT_FX, x, y))
                call DealAreaDamage(dex.source, dex.user, x, y, dex.collision, dex.damage)
                call PlayImpactSound(x, y)

                call ReleaseTimer(t)
                call ClearCaughtData(dex)
                call dex.destroy()
                set u = null
                set t = null
                return
            endif
        endif

        set u = null
        set t = null
    endfunction

    private function CatchOneUnit takes unit source, player owner, integer level, unit target, boolean allowPeakRadial returns nothing
        local SpellIndex dex = SpellIndex.create()
        if (GetUnitTypeId(target) == 0) then
            call dex.destroy()
            return
        endif
        // Enable flying and lift.
        call UnitAddAbility(target, 'Amrf')
        call UnitRemoveAbility(target, 'Amrf')
        call SetUnitFlyHeight(target, GetUnitFlyHeight(target), 99999.)
        // Stun through dummy caster (configure stun duration to match CATCH_RISE_TIME + CATCH_FALL_TIME).
        call DummyCaster[STUN_BUFF_CAST_ID].castTarget(owner, 1, STUN_ORDER_ID, target)

        set dex.source = source
        set dex.user = owner
        set dex.level = level
        set dex.target = target
        set dex.damage = GetCatchImpactDamage(level)
        set dex.collision = CATCH_IMPACT_AOE
        set catchStage[dex] = 0
        set catchPeakRadialEnabled[dex] = allowPeakRadial
        set catchElapsed[dex] = 0.
        set catchBaseHeight[dex] = GetUnitFlyHeight(target)
        set catchDistanceTotal[dex] = RMaxBJ(0., CATCH_LIFT_HEIGHT)
        set catchDistanceProgress[dex] = 0.
        call TimerStart(NewTimerEx(dex), CATCH_MOTION_PERIOD, true, function OnCaughtMotion)
    endfunction

    private function HandlePathCatch takes Missile missile, unit firstHit returns nothing
        local unit source = missile.source
        local player owner = missile.owner
        local integer level = SpellIndex(missile.data).level
        local integer picked = 0
        local unit u
        if MAX_CAUGHT_UNITS <= 0 then
            set source = null
            set owner = null
            return
        endif
        call CatchOneUnit(source, owner, level, firstHit, true)
        set picked = 1
        if MAX_CAUGHT_UNITS > 1 then
            call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, GetUnitX(firstHit), GetUnitY(firstHit), EXTRA_CATCH_AOE, null)
            loop
                set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                exitwhen u == null
                call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
                if (picked < MAX_CAUGHT_UNITS) and (u != firstHit) and FilterUnits(u, owner) then
                    call CatchOneUnit(source, owner, level, u, false)
                    set picked = picked + 1
                endif
            endloop
        endif
        set source = null
        set owner = null
        set u = null
    endfunction

    private struct ShockCore extends array
        private static method onCollide takes Missile missile, unit hit returns boolean
            if (missileKind[missile] == KIND_MAIN) and ENABLE_PATH_CATCH and (not mainCaught[missile]) and FilterUnits(hit, missile.owner) then
                call StopLaunchSound(mainLaunchSound[missile])
                set mainLaunchSound[missile] = null
                call PlayLaunchSound(missile.source, 1.00)
                set mainCaught[missile] = true
                set missile.collision = 0.
                set SpellIndex(missile.data).phase = 1
                call HandlePathCatch(missile, hit)
                return true
            endif
            return false
        endmethod

        private static method onPeriod takes Missile missile returns boolean
            call ApplySpeedProfile(missile)
            return false
        endmethod

        private static method onFinish takes Missile missile returns boolean
            local SpellIndex dex
            local real aoe
            local real damage
            if missileKind[missile] == KIND_MAIN then
                set dex = missile.data
                if (dex.phase == 0) and (not mainCaught[missile]) then
                    set aoe = MAIN_IMPACT_AOE
                    if NO_HIT_BIG_AOE_AND_RADIAL then
                        set aoe = NO_HIT_BIG_AOE
                    endif
                    set damage = GetMainImpactDamage(dex.level)
                    call DealAreaDamage(missile.source, missile.owner, missile.x, missile.y, aoe, damage)
                    call DestroyEffect(AddSpecialEffectTarget(MAIN_IMPACT_FX, missile.dummy, "origin"))
                    call PlayImpactSound(missile.x, missile.y)
                    if NO_HIT_BIG_AOE_AND_RADIAL then
                        call LaunchRadialProjectiles(missile.source, missile.owner, dex.level, missile.x, missile.y, missile.z + missile.terrainZ, NO_HIT_RADIAL_DISTANCE)
                    endif
                endif
                return true
            elseif missileKind[missile] == KIND_RADIAL then
                call DealAreaDamage(missile.source, missile.owner, missile.x, missile.y, radialAoe[missile], radialDamage[missile])
                call DestroyEffect(AddSpecialEffectTarget(RADIAL_IMPACT_FX, missile.dummy, "origin"))
                call PlayImpactSoundPitch(missile.x, missile.y, IMPACT_SOUND_PITCH)
                return true
            endif
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            call StopLaunchSound(mainLaunchSound[missile])
            set mainLaunchSound[missile] = null
            if missileKind[missile] == KIND_MAIN then
                call SpellIndex(missile.data).destroy()
            endif
            set missileKind[missile] = 0
            set currentSpeed[missile] = 0.
            set decelElapsed[missile] = 0.
            set profileInitSpeed[missile] = 0.
            set profileMinSpeed[missile] = 0.
            set profileDecelTime[missile] = 0.
            set elapsedTotal[missile] = 0.
            set profileDecelDuration[missile] = 0.
            set profileStartDecelTime[missile] = 0.
            set profileStartDecelDistanceRatio[missile] = 0.
            set decelStarted[missile] = false
            set mainCaught[missile] = false
            set radialAoe[missile] = 0.
            set radialDamage[missile] = 0.
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        local integer level = GetUnitAbilityLevel(source, GRAVITY_SHELL_ABILITY)
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real tx = GetSpellTargetX()
        local real ty = GetSpellTargetY()
        local SpellIndex dex = SpellIndex.create()
        local SpellIndex animDex
        local Missile missile = Missile.createXYZ(x, y, PROJECTILE_START_Z, tx, ty, PROJECTILE_START_Z)

        set dex.source = source
        set dex.user = owner
        set dex.level = level
        set dex.phase = 0 //* 0 = no unit caught, 1 = unit caught.

        set missile.source = source
        set missile.owner = owner
        set missile.data = dex
        set missile.model = PROJECTILE_MODEL
        set missile.scale = PROJECTILE_SCALE
        if ENABLE_PATH_CATCH then
            set missile.collision = PROJECTILE_COLLISION
        else
            set missile.collision = 0.
        endif

        set missileKind[missile] = KIND_MAIN
        set mainCaught[missile] = false
        call SetupSpeedProfile(missile)

        call ShockCore.launch(missile)
        set mainLaunchSound[missile] = StartLaunchSound(source, 1.00)
        set animDex = SpellIndex.create()
        set animDex.source = source
        if FIRST_ANIMATION_DELAY <= 0. then
            call SetUnitAnimation(source, CAST_ANIMATION)
            call animDex.destroy()
        else
            call TimerStart(NewTimerEx(animDex), FIRST_ANIMATION_DELAY, false, function DelayedStartAnimation)
        endif

        set source = null
        set owner = null
    endfunction

    private function Init takes nothing returns nothing
        call PreloadSounds()
        call RegisterSpellEffectEvent(GRAVITY_SHELL_ABILITY, function OnEffect)
    endfunction
endlibrary
