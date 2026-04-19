//TESH.scrollpos=0
//TESH.alwaysfold=0
library TargetSling initializer Init uses SpellIndex, Missile, DummyCaster, WorldBounds /* v1.0
*************************************************************************************
*
*   Unit-target spell sequence:
*   1) Creates a configured carrier unit and launches it as a missile to the target.
*      Target interception is predicted to account for target movement.
*   2) On arrival: plays sound + floating text (fades in 1.00s), and aligns facing
*      of both carrier and target toward cast origin.
*   3) +1.35s: creates second text on the target.
*   4) +2.03s: creates third text, plays carrier spell animation, then launches the
*      target unit as a missile back to the cast origin.
*   5) On impact: target plays death animation, AoE stun + AoE damage, and bonus
*      damage to launched target.
*   6) Carrier is removed 1.00s after target launch.
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer TARGET_SLING_ABILITY = 'S00D'
        private constant integer CARRIER_UNIT_ID = 'ewsp' //* Configure this rawcode.

        //* Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC

        //* Carrier missile (first launch).
        private constant real CARRIER_START_Z = 80.
        private constant real CARRIER_SPEED = 1650.
        private constant real CARRIER_ARRIVAL_TIME = 1.00 //* Guaranteed first-contact timing target.
        private constant real CARRIER_MIN_SPEED = 1.00
        private constant real CARRIER_ARC = 10.*bj_DEGTORAD
        private constant real CARRIER_LAND_OFFSET = 90. //* Positive pushes landing point beyond target from cast direction.
        private constant real FIRST_CONTACT_RADIUS = 96.
        private constant integer INTERCEPT_ITERATIONS = 2

        //* Target throw (second launch).
        private constant real TARGET_THROW_SPEED = 1200.
        private constant boolean USE_TARGET_IMPACT_TIME = true
        private constant real TARGET_IMPACT_TIME_FROM_ACTION1 = 2.18 //* Absolute time since action 1 when thrown target must impact.
        private constant real TARGET_THROW_ARC = 28.*bj_DEGTORAD
        private constant string TARGET_IMPACT_ANIMATION = "death"

        //* Sequence timing (relative to action-1).
        private constant real ACTION2_DELAY = 1.35
        private constant real ACTION3_DELAY = 2.03
        private constant real SEQUENCE_PERIOD = 0.03125
        private constant real CARRIER_REMOVE_DELAY_AFTER_THROW = 1.00

        //* Texts.
        private constant string ACTION1_TEXT = "Desahuevate CTMR"
        private constant string ACTION2_TEXT = "No Jefe Yo.."
        private constant string ACTION3_TEXT = "CALLATE MRD"
        private constant real TEXT_SIZE = 0.023
        private constant real TEXT_Z_OFFSET = 120.
        private constant real TEXT_RISE_SPEED = 0.035
        private constant integer TEXT_RED = 255
        private constant integer TEXT_GREEN = 240
        private constant integer TEXT_BLUE = 80
        private constant integer TEXT_ALPHA = 255
        private constant real ACTION1_TEXT_LIFESPAN = 1.00
        private constant real ACTION_TEXT_LIFESPAN = 1.00

        //* Effects and sounds.
        private constant string ACTION1_SOUND = "war3mapImported\\CuevaSpell1.mp3"
        private constant string IMPACT_SOUND = "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode1.wav"
        private constant string IMPACT_FX = "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl"
        private constant string CARRIER_CAST_ANIMATION = "spell"

        //* Impact area.
        private constant real IMPACT_AOE = 250.
        private constant real AOE_DAMAGE_BASE = 90.
        private constant real AOE_DAMAGE_PER_LEVEL = 40.
        private constant real BONUS_TARGET_DAMAGE_BASE = 60.
        private constant real BONUS_TARGET_DAMAGE_PER_LEVEL = 35.

        //* AoE stun (configure stun duration in object editor).
        private constant boolean ENABLE_AOE_STUN = true
        private constant integer STUN_BUFF_CAST_ID = 'A006'
        private constant integer STUN_ORDER_ID = 852095 //* thunderbolt

        //* Safety clamp inside world bounds.
        private constant real WORLD_CLAMP_MARGIN = 64.
    endglobals

    private keyword SlingCore

    private constant function GetAoeDamage takes integer level returns real
        return AOE_DAMAGE_BASE + AOE_DAMAGE_PER_LEVEL*level
    endfunction

    private constant function GetBonusTargetDamage takes integer level returns real
        return BONUS_TARGET_DAMAGE_BASE + BONUS_TARGET_DAMAGE_PER_LEVEL*level
    endfunction

    private function FilterLaunchTarget takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
    endfunction

    private function FilterImpactTarget takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
    endfunction

//========================================================================
//* Target sling code. Make changes carefully.
//========================================================================

    globals
        private constant integer KIND_CARRIER = 1
        private constant integer KIND_TARGET_THROW = 2

        private integer array missileKind
        private unit array carrierUnit
        private real array castPointX
        private real array castPointY
        private boolean array firstArrived
        private boolean array targetHeld
        private boolean array targetInFlight
        private boolean array cleaned
        private real array carrierElapsed
        private real predictedImpactX = 0.
        private real predictedImpactY = 0.
    endglobals

    private function ClampX takes real x returns real
        if x < WorldBounds.minX + WORLD_CLAMP_MARGIN then
            return WorldBounds.minX + WORLD_CLAMP_MARGIN
        endif
        if x > WorldBounds.maxX - WORLD_CLAMP_MARGIN then
            return WorldBounds.maxX - WORLD_CLAMP_MARGIN
        endif
        return x
    endfunction

    private function ClampY takes real y returns real
        if y < WorldBounds.minY + WORLD_CLAMP_MARGIN then
            return WorldBounds.minY + WORLD_CLAMP_MARGIN
        endif
        if y > WorldBounds.maxY - WORLD_CLAMP_MARGIN then
            return WorldBounds.maxY - WORLD_CLAMP_MARGIN
        endif
        return y
    endfunction

    private function PlaySoundOnUnit takes string file, unit source returns nothing
        local sound s = CreateSound(file, false, false, false, 10, 10, "")
        if source != null then
            call AttachSoundToUnit(s, source)
        endif
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function PlaySoundAt takes string file, real x, real y returns nothing
        local sound s = CreateSound(file, false, false, false, 10, 10, "")
        call SetSoundPosition(s, x, y, 0.)
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function KillAndRemoveUnit takes unit u returns nothing
        if GetUnitTypeId(u) != 0 then
            call PauseUnit(u, false)
            call SetUnitInvulnerable(u, false)
            call KillUnit(u)
            call RemoveUnit(u)
        endif
    endfunction

    private function OnCarrierRemove takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit u = dex.target
        call KillAndRemoveUnit(u)
        call ReleaseTimer(t)
        call dex.destroy()
        set u = null
        set t = null
    endfunction

    private function ScheduleCarrierRemove takes unit carrier, real delay returns nothing
        local SpellIndex dex
        if GetUnitTypeId(carrier) == 0 then
            return
        endif
        if delay <= 0. then
            call KillAndRemoveUnit(carrier)
            return
        endif
        set dex = SpellIndex.create()
        set dex.target = carrier
        call TimerStart(NewTimerEx(dex), delay, false, function OnCarrierRemove)
    endfunction

    private function ShowFloatingText takes unit whichUnit, string msg, real lifespan returns nothing
        local texttag t
        local real x
        local real y
        if whichUnit == null then
            return
        endif
        if GetUnitTypeId(whichUnit) == 0 then
            return
        endif
        set x = GetUnitX(whichUnit)
        set y = GetUnitY(whichUnit)
        set t = CreateTextTag()
        call SetTextTagText(t, msg, TEXT_SIZE)
        call SetTextTagPos(t, x, y, TEXT_Z_OFFSET)
        call SetTextTagColor(t, TEXT_RED, TEXT_GREEN, TEXT_BLUE, TEXT_ALPHA)
        call SetTextTagVelocity(t, 0., TEXT_RISE_SPEED)
        call SetTextTagPermanent(t, false)
        call SetTextTagLifespan(t, lifespan)
        call SetTextTagFadepoint(t, 0.)
        set t = null
    endfunction

    private function PredictCarrierImpactPoint takes real sx, real sy, unit target returns nothing
        local real tx = GetUnitX(target)
        local real ty = GetUnitY(target)
        local real targetSpeed = GetUnitMoveSpeed(target)
        local real targetAngle = GetUnitFacing(target)*bj_DEGTORAD
        local real vx = targetSpeed*Cos(targetAngle)
        local real vy = targetSpeed*Sin(targetAngle)
        local real px = tx
        local real py = ty
        local real t = 0.
        local real dx
        local real dy
        local integer i = 0

        if CARRIER_SPEED <= 0. then
            set predictedImpactX = ClampX(tx)
            set predictedImpactY = ClampY(ty)
            return
        endif

        loop
            exitwhen i >= INTERCEPT_ITERATIONS
            set dx = px - sx
            set dy = py - sy
            set t = SquareRoot(dx*dx + dy*dy)/CARRIER_SPEED
            set px = tx + vx*t
            set py = ty + vy*t
            set i = i + 1
        endloop

        set predictedImpactX = ClampX(px)
        set predictedImpactY = ClampY(py)
    endfunction

    private function CleanupDex takes SpellIndex dex, boolean removeCarrier returns nothing
        local unit carrier
        if dex == 0 then
            return
        endif
        if cleaned[dex] then
            return
        endif
        set cleaned[dex] = true

        if dex.clock != null then
            call ReleaseTimer(dex.clock)
            set dex.clock = null
        endif

        if (targetHeld[dex] or targetInFlight[dex]) and (GetUnitTypeId(dex.target) != 0) then
            call PauseUnit(dex.target, false)
            call SetUnitPathing(dex.target, true)
            call SetUnitInvulnerable(dex.target, false)
        endif

        set carrier = carrierUnit[dex]
        if GetUnitTypeId(carrier) != 0 then
            call PauseUnit(carrier, false)
            call SetUnitInvulnerable(carrier, false)
        endif
        if removeCarrier and (GetUnitTypeId(carrier) != 0) then
            call KillAndRemoveUnit(carrier)
        endif

        set carrierUnit[dex] = null
        set castPointX[dex] = 0.
        set castPointY[dex] = 0.
        set firstArrived[dex] = false
        set targetHeld[dex] = false
        set targetInFlight[dex] = false
        call dex.destroy()
        set carrier = null
    endfunction

    private function DealImpact takes SpellIndex dex, unit launched, real x, real y returns nothing
        local unit source = dex.source
        local player owner = dex.user
        local unit u
        local real aoeDamage = GetAoeDamage(dex.level)

        call DestroyEffect(AddSpecialEffect(IMPACT_FX, x, y))
        call PlaySoundAt(IMPACT_SOUND, x, y)

        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, IMPACT_AOE, null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if FilterImpactTarget(u, owner) then
                if GetUnitTypeId(source) != 0 then
                    call UnitDamageTarget(source, u, aoeDamage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                endif
                if ENABLE_AOE_STUN then
                    call DummyCaster[STUN_BUFF_CAST_ID].castTarget(owner, 1, STUN_ORDER_ID, u)
                endif
            endif
        endloop

        if (launched != null) and UnitAlive(launched) and (GetUnitTypeId(source) != 0) then
            call UnitDamageTarget(source, launched, GetBonusTargetDamage(dex.level), false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
        endif

        set source = null
        set owner = null
        set u = null
    endfunction

    private function LaunchTargetBack takes SpellIndex dex returns boolean
        local unit target = dex.target
        local unit carrier = carrierUnit[dex]
        local Missile missile
        local real remainingTime
        if (GetUnitTypeId(target) == 0) or (not UnitAlive(target)) then
            if GetUnitTypeId(carrier) != 0 then
                call PauseUnit(carrier, false)
                call SetUnitInvulnerable(carrier, false)
                call ScheduleCarrierRemove(carrier, CARRIER_REMOVE_DELAY_AFTER_THROW)
            endif
            call CleanupDex(dex, false)
            set target = null
            set carrier = null
            return false
        endif

        call UnitAddAbility(target, 'Amrf')
        call UnitRemoveAbility(target, 'Amrf')
        call SetUnitPathing(target, false)
        call PauseUnit(target, true)
        call SetUnitInvulnerable(target, true)
        set targetHeld[dex] = false
        set targetInFlight[dex] = true

        set missile = Missile.createEx(target, castPointX[dex], castPointY[dex], 0.)
        set missile.source = dex.source
        set missile.owner = dex.user
        set missile.data = dex
        set missile.collision = 0.
        set missile.arc = TARGET_THROW_ARC
        if USE_TARGET_IMPACT_TIME then
            set remainingTime = TARGET_IMPACT_TIME_FROM_ACTION1 - dex.time
            if remainingTime <= Missile_TIMER_TIMEOUT then
                set remainingTime = Missile_TIMER_TIMEOUT
            endif
            call missile.flightTime2Speed(remainingTime)
        else
            call missile.setMovementSpeed(TARGET_THROW_SPEED)
        endif
        set missileKind[missile] = KIND_TARGET_THROW
        call SlingCore.launch(missile)

        if GetUnitTypeId(carrier) != 0 then
            call PauseUnit(carrier, false)
            call SetUnitInvulnerable(carrier, false)
            call ScheduleCarrierRemove(carrier, CARRIER_REMOVE_DELAY_AFTER_THROW)
        endif

        set target = null
        set carrier = null
        return true
    endfunction

    private function OnSequenceTick takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit carrier = carrierUnit[dex]

        if cleaned[dex] then
            call ReleaseTimer(t)
            set t = null
            set carrier = null
            return
        endif

        set dex.time = dex.time + SEQUENCE_PERIOD

        if (dex.phase == 1) and (dex.time >= ACTION2_DELAY) then
            call ShowFloatingText(dex.target, ACTION2_TEXT, ACTION_TEXT_LIFESPAN)
            set dex.phase = 2
        endif

        if (dex.phase == 2) and (dex.time >= ACTION3_DELAY) then
            call ShowFloatingText(carrier, ACTION3_TEXT, ACTION_TEXT_LIFESPAN)
            if GetUnitTypeId(carrier) != 0 then
                call SetUnitAnimation(carrier, CARRIER_CAST_ANIMATION)
            endif
            call LaunchTargetBack(dex)

            if dex.clock == t then
                call ReleaseTimer(t)
                set dex.clock = null
            endif
        endif

        set carrier = null
        set t = null
    endfunction

    private function BeginFirstAction takes SpellIndex dex, Missile missile returns nothing
        local unit carrier = carrierUnit[dex]
        local unit target = dex.target
        local real castAngle
        local real carrierFacing
        local real targetFacing
        local real tx
        local real ty
        local real x
        local real y

        if firstArrived[dex] then
            set carrier = null
            set target = null
            return
        endif

        if (GetUnitTypeId(target) == 0) or (not UnitAlive(target)) then
            call CleanupDex(dex, true)
            set carrier = null
            set target = null
            return
        endif

        set tx = GetUnitX(target)
        set ty = GetUnitY(target)
        set castAngle = Atan2(ty - castPointY[dex], tx - castPointX[dex])
        set x = ClampX(tx + CARRIER_LAND_OFFSET*Cos(castAngle))
        set y = ClampY(ty + CARRIER_LAND_OFFSET*Sin(castAngle))

        set firstArrived[dex] = true

        if GetUnitTypeId(carrier) != 0 then
            call SetUnitPosition(carrier, x, y)
        endif

        set carrierFacing = Atan2(castPointY[dex] - y, castPointX[dex] - x)*bj_RADTODEG
        if GetUnitTypeId(carrier) != 0 then
            call SetUnitFacing(carrier, carrierFacing)
        endif
        if GetUnitTypeId(target) != 0 then
            set targetFacing = Atan2(y - ty, x - tx)*bj_RADTODEG
            call SetUnitFacing(target, targetFacing)
            // Hold target from contact (action 1) until throw starts.
            call PauseUnit(target, true)
            set targetHeld[dex] = true
        endif

        call PlaySoundOnUnit(ACTION1_SOUND, carrier)
        call ShowFloatingText(carrier, ACTION1_TEXT, ACTION1_TEXT_LIFESPAN)

        set dex.phase = 1
        set dex.time = 0.
        if dex.clock != null then
            call ReleaseTimer(dex.clock)
        endif
        set dex.clock = NewTimerEx(dex)
        call TimerStart(dex.clock, SEQUENCE_PERIOD, true, function OnSequenceTick)

        set carrier = null
        set target = null
    endfunction

    private struct SlingCore extends array
        private static method onCollide takes Missile missile, unit hit returns boolean
            local SpellIndex dex
            if missileKind[missile] == KIND_CARRIER then
                set dex = missile.data
                if hit == dex.target then
                    call BeginFirstAction(dex, missile)
                    return true
                endif
            endif
            return false
        endmethod

        private static method onPeriod takes Missile missile returns boolean
            local SpellIndex dex
            local unit target
            local real elapsed
            local real remainingTime
            local real remainingDistance
            local real desiredSpeed
            local real dx
            local real dy

            if missileKind[missile] != KIND_CARRIER then
                return false
            endif

            set dex = missile.data
            if cleaned[dex] or firstArrived[dex] then
                return false
            endif

            set target = dex.target
            if (GetUnitTypeId(target) == 0) or (not UnitAlive(target)) then
                call missile.destroy()
                set target = null
                return false
            endif

            // Continuous guidance to moving target while preserving parabolic movement.
            call PredictCarrierImpactPoint(missile.x, missile.y, target)
            call missile.impact.move(predictedImpactX, predictedImpactY, GetUnitFlyHeight(target))
            set missile.arc = CARRIER_ARC

            set elapsed = carrierElapsed[missile] + Missile_TIMER_TIMEOUT
            if elapsed > CARRIER_ARRIVAL_TIME then
                set elapsed = CARRIER_ARRIVAL_TIME
            endif
            set remainingTime = CARRIER_ARRIVAL_TIME - elapsed

            set dx = predictedImpactX - missile.x
            set dy = predictedImpactY - missile.y
            set remainingDistance = SquareRoot(dx*dx + dy*dy)

            if remainingDistance <= 0. then
                set desiredSpeed = CARRIER_MIN_SPEED
            elseif remainingTime <= Missile_TIMER_TIMEOUT then
                set desiredSpeed = remainingDistance/Missile_TIMER_TIMEOUT
            else
                set desiredSpeed = remainingDistance/remainingTime
            endif

            if desiredSpeed < CARRIER_MIN_SPEED then
                set desiredSpeed = CARRIER_MIN_SPEED
            endif

            call missile.setMovementSpeed(desiredSpeed)
            set carrierElapsed[missile] = elapsed
            set target = null
            return false
        endmethod

        private static method onFinish takes Missile missile returns boolean
            local SpellIndex dex = missile.data
            local unit target
            local real x
            local real y

            if missileKind[missile] == KIND_CARRIER then
                call BeginFirstAction(dex, missile)

            elseif missileKind[missile] == KIND_TARGET_THROW then
                set target = missile.dummy
                set x = missile.x
                set y = missile.y

                if GetUnitTypeId(target) != 0 then
                    call PauseUnit(target, false)
                    call SetUnitPathing(target, true)
                    call SetUnitInvulnerable(target, false)
                    call SetUnitPosition(target, x, y)
                    call SetUnitAnimation(target, TARGET_IMPACT_ANIMATION)
                endif

                set targetInFlight[dex] = false
                call DealImpact(dex, target, x, y)
                call CleanupDex(dex, false)
            endif

            set target = null
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            local SpellIndex dex = missile.data
            if missileKind[missile] == KIND_CARRIER then
                if (not firstArrived[dex]) and (not cleaned[dex]) then
                    call CleanupDex(dex, true)
                endif
            elseif missileKind[missile] == KIND_TARGET_THROW then
                if not cleaned[dex] then
                    call CleanupDex(dex, false)
                endif
            endif
            set carrierElapsed[missile] = 0.
            set missileKind[missile] = 0
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player owner = GetTriggerPlayer()
        local unit target = GetSpellTargetUnit()
        local integer level = GetUnitAbilityLevel(source, TARGET_SLING_ABILITY)
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real angle
        local SpellIndex dex
        local Missile missile
        local unit carrier

        if not FilterLaunchTarget(target, owner) then
            set source = null
            set owner = null
            set target = null
            return
        endif

        call PredictCarrierImpactPoint(x, y, target)
        set angle = Atan2(predictedImpactY - y, predictedImpactX - x)

        set carrier = CreateUnit(owner, CARRIER_UNIT_ID, x, y, angle*bj_RADTODEG)
        if GetUnitTypeId(carrier) == 0 then
            set source = null
            set owner = null
            set target = null
            set carrier = null
            return
        endif

        call UnitAddAbility(carrier, 'Amrf')
        call UnitRemoveAbility(carrier, 'Amrf')
        call UnitAddAbility(carrier, 'Aloc')
        call SetUnitFlyHeight(carrier, CARRIER_START_Z, 0.)
        call SetUnitPathing(carrier, false)
        call PauseUnit(carrier, true)
        call SetUnitInvulnerable(carrier, true)

        set dex = SpellIndex.create()
        set dex.source = source
        set dex.user = owner
        set dex.target = target
        set dex.level = level
        set dex.phase = 0
        set dex.time = 0.
        set dex.clock = null

        set castPointX[dex] = x
        set castPointY[dex] = y
        set carrierUnit[dex] = carrier
        set firstArrived[dex] = false
        set targetHeld[dex] = false
        set targetInFlight[dex] = false
        set cleaned[dex] = false

        set missile = Missile.createEx(carrier, predictedImpactX, predictedImpactY, GetUnitFlyHeight(target))
        set missile.source = source
        set missile.owner = owner
        set missile.data = dex
        set missile.collision = FIRST_CONTACT_RADIUS
        set missile.arc = CARRIER_ARC
        set carrierElapsed[missile] = 0.
        call missile.setMovementSpeed(CARRIER_SPEED)
        set missileKind[missile] = KIND_CARRIER
        call SlingCore.launch(missile)

        set source = null
        set owner = null
        set target = null
        set carrier = null
    endfunction

    private function Init takes nothing returns nothing
        call RegisterSpellEffectEvent(TARGET_SLING_ABILITY, function OnEffect)
    endfunction
endlibrary
