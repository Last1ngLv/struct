//TESH.scrollpos=0
//TESH.alwaysfold=0
library UnitTypeMissile initializer Init uses SpellIndex, Missile, UnitTypeMissileLoadout, IsUnitChanneling, RegisterPlayerUnitEvent, Table, SpellEffectEvent, SpellFinishEvent, WaveDamageCredit
//******************************************************************************
// Sistema de missile basado en tipo de unidad.
// Spell es channeling: al iniciar, muestra dummy + FX; tras dummyDelay dispara.
// Si el canal se rompe (stun/muerte/endcast), se cancela y limpia.
//******************************************************************************
    globals
        private constant integer MISSILE_ABILITY_ID = 'AU01'
        private constant string WRAP_ATTACH_POINT = "origin"
        private constant real POINT_IMPACT_LINGER = 3.00
        private constant integer CLEANUP_REASON_NONE = 0
        private constant integer CLEANUP_REASON_INTERRUPTED = 1
        private constant integer CLEANUP_REASON_COMPLETED = 2

        private constant integer DUMMY_UNIT_ID = 'dumi'
        private constant integer DUMMY_ABILITY = 'Avul'

        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
    endglobals

    globals
        private Table activeData // caster hid -> SpellIndex castDex

        private unit array castDummy
        private effect array castFx
        private effect array castWaitFx
        private real array castX
        private real array castY
        private real array castAngle
        private real array castDistance
        private real array castTargetX
        private real array castTargetY
        private boolean array castUseRapid
        private real array castRapidRemaining
        private real array castRapidInterval
        private string array castAnim
        private real array castAnimScale
        private string array castSoundWaitEnd
        private string array castSoundInterrupted
        private string array castSoundChannelComplete
        private timer array delayedAnimTimer
        private integer array castNormalPointData
        private integer array castSpecialPointData
        private integer array castNormalShots

        private effect array overlayFx
        private unit array pointDummy
        private effect array pointFx
        private string array pointImpactFx
        private integer array pointPending
        private boolean array pointImpactApplied
        private boolean array pointClosed
        private boolean array pointHadImpact
        private string array pointSoundImpact
        private string array pointSoundLastMissile
        private string array pointSoundDummyClear
        private integer array pointByMissile
        private boolean array pointDoneByMissile
        private boolean array impactOnPathByMissile

        private unit array lingerDummy
        private effect array lingerFx
        private string array lingerSound
    endglobals

    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
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

    private function PlaySoundOnUnit takes string file, unit source returns nothing
        local sound s
        if (file == null) or (file == "") or (source == null) or (GetUnitTypeId(source) == 0) then
            return
        endif
        set s = CreateSound(file, false, false, false, 10, 10, "")
        call SetSoundPosition(s, GetUnitX(source), GetUnitY(source), 0.)
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function PlaySoundAt takes string file, real x, real y returns nothing
        local sound s
        if (file == null) or (file == "") then
            return
        endif
        set s = CreateSound(file, false, false, false, 10, 10, "")
        call SetSoundPosition(s, x, y, 0.)
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function OnLingerExpire takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local real x = 0.
        local real y = 0.
        local string snd = lingerSound[dex]
        if lingerDummy[dex] != null then
            set x = GetUnitX(lingerDummy[dex])
            set y = GetUnitY(lingerDummy[dex])
        endif
        // Sound: when DEFAULT_DUMMY_MODEL is fully removed (after linger).
        call PlaySoundAt(snd, x, y)
        if lingerFx[dex] != null then
            call DestroyEffect(lingerFx[dex])
            set lingerFx[dex] = null
        endif
        if lingerDummy[dex] != null then
            call RemoveUnit(lingerDummy[dex])
            set lingerDummy[dex] = null
        endif
        set lingerSound[dex] = null
        call ReleaseTimer(t)
        call dex.destroy()
        set t = null
    endfunction

    private function StartLingerCleanup takes unit dummy, effect fx, string snd returns nothing
        local SpellIndex dex
        local timer t
        if (dummy == null) and (fx == null) then
            return
        endif
        set dex = SpellIndex.create()
        set lingerDummy[dex] = dummy
        set lingerFx[dex] = fx
        set lingerSound[dex] = snd
        set t = NewTimerEx(dex)
        call SetTimerDebugTag(t, TIMER_DEBUG_TAG_OTHER)
        call TimerStart(t, POINT_IMPACT_LINGER, false, function OnLingerExpire)
        set t = null
    endfunction

    private function ReleasePointDataIfIdle takes integer pointDex returns nothing
        local real x = 0.
        local real y = 0.
        local string snd
        local string impactModel
        local effect newFx
        if pointDex == 0 then
            return
        endif
        if not pointClosed[pointDex] then
            return
        endif
        if pointPending[pointDex] > 0 then
            return
        endif
        if pointDummy[pointDex] != null then
            set x = GetUnitX(pointDummy[pointDex])
            set y = GetUnitY(pointDummy[pointDex])
        endif
        if pointHadImpact[pointDex] then
            // This point already had missile impact(s), finalize with impact FX + linger.
            if not pointImpactApplied[pointDex] then
                if pointFx[pointDex] != null then
                    call DestroyEffect(pointFx[pointDex])
                    set pointFx[pointDex] = null
                endif
                set impactModel = pointImpactFx[pointDex]
                if (pointDummy[pointDex] != null) and (impactModel != null) and (impactModel != "") then
                    set newFx = AddSpecialEffectTarget(impactModel, pointDummy[pointDex], "origin")
                    set pointFx[pointDex] = newFx
                endif
                set pointImpactApplied[pointDex] = true
                set impactModel = null
            endif
            // Sound: special sound for last missile resolved in this point group.
            set snd = pointSoundLastMissile[pointDex]
            call PlaySoundAt(snd, x, y)
            call StartLingerCleanup(pointDummy[pointDex], pointFx[pointDex], pointSoundDummyClear[pointDex])
            set pointDummy[pointDex] = null
            set pointFx[pointDex] = null
        else
            set snd = pointSoundDummyClear[pointDex]
            // Sound: dummy removed without impact (e.g. canceled before any missile hit).
            call PlaySoundAt(snd, x, y)
            if pointFx[pointDex] != null then
                call DestroyEffect(pointFx[pointDex])
                set pointFx[pointDex] = null
            endif
            if pointDummy[pointDex] != null then
                call RemoveUnit(pointDummy[pointDex])
                set pointDummy[pointDex] = null
            endif
        endif
        set pointImpactFx[pointDex] = null
        set pointSoundImpact[pointDex] = null
        set pointSoundLastMissile[pointDex] = null
        set pointSoundDummyClear[pointDex] = null
        set pointPending[pointDex] = 0
        set pointImpactApplied[pointDex] = false
        set pointClosed[pointDex] = false
        set pointHadImpact[pointDex] = false
        call SpellIndex(pointDex).destroy()
        set snd = null
        set newFx = null
    endfunction

    private function ResolvePointFromMissile takes Missile missile, boolean applyImpactFx returns nothing
        local integer pointDex = pointByMissile[missile]
        local string impactModel
        local string snd
        local effect newFx
        local real sx
        local real sy

        if pointDoneByMissile[missile] then
            return
        endif
        set pointDoneByMissile[missile] = true

        if pointDex == 0 then
            return
        endif

        // Sound: missile impact (normal and special use same flow).
        if applyImpactFx then
            set pointHadImpact[pointDex] = true
            set snd = pointSoundImpact[pointDex]
            call PlaySoundAt(snd, missile.x, missile.y)
        endif

        set pointPending[pointDex] = pointPending[pointDex] - 1
        if pointPending[pointDex] <= 0 then
            set pointPending[pointDex] = 0
            if applyImpactFx and (not pointImpactApplied[pointDex]) then
                if pointFx[pointDex] != null then
                    call DestroyEffect(pointFx[pointDex])
                    set pointFx[pointDex] = null
                endif
                set impactModel = pointImpactFx[pointDex]
                if (pointDummy[pointDex] != null) and (impactModel != null) and (impactModel != "") then
                    set newFx = AddSpecialEffectTarget(impactModel, pointDummy[pointDex], "origin")
                    set pointFx[pointDex] = newFx
                endif
                set pointImpactApplied[pointDex] = true
                set impactModel = null
            endif
            // Keep point data alive while channel can still launch more shots.
            if not pointClosed[pointDex] then
                set pointByMissile[missile] = 0
                set snd = null
                set newFx = null
                return
            endif
            set sx = missile.x
            set sy = missile.y
            if pointDummy[pointDex] != null then
                set sx = GetUnitX(pointDummy[pointDex])
                set sy = GetUnitY(pointDummy[pointDex])
            endif
            // Sound: special sound for last missile resolved in this point group.
            if applyImpactFx then
                set snd = pointSoundLastMissile[pointDex]
                call PlaySoundAt(snd, sx, sy)
            endif
            call StartLingerCleanup(pointDummy[pointDex], pointFx[pointDex], pointSoundDummyClear[pointDex])
            set pointDummy[pointDex] = null
            set pointFx[pointDex] = null
            set pointImpactFx[pointDex] = null
            set pointSoundImpact[pointDex] = null
            set pointSoundLastMissile[pointDex] = null
            set pointSoundDummyClear[pointDex] = null
            set pointPending[pointDex] = 0
            set pointImpactApplied[pointDex] = false
            set pointClosed[pointDex] = false
            set pointHadImpact[pointDex] = false
            call SpellIndex(pointDex).destroy()
        endif

        set pointByMissile[missile] = 0
        set snd = null
        set newFx = null
    endfunction

    private struct UnitTypeMissileCore extends array
        private static method onCollide takes Missile missile, unit hit returns boolean
            if not impactOnPathByMissile[missile] then
                return false
            endif
            if not FilterUnits(hit, missile.owner) then
                return false
            endif
            call DamageArea(missile.source, missile.owner, missile.x, missile.y, missile.collision, missile.damage)
            call ResolvePointFromMissile(missile, true)
            return true
        endmethod

        private static method onFinish takes Missile missile returns boolean
            call DamageArea(missile.source, missile.owner, missile.x, missile.y, missile.collision, missile.damage)
            call ResolvePointFromMissile(missile, true)
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            if overlayFx[missile] != null then
                call DestroyEffect(overlayFx[missile])
                set overlayFx[missile] = null
            endif
            if not pointDoneByMissile[missile] then
                call ResolvePointFromMissile(missile, false)
            endif
            set pointByMissile[missile] = 0
            set pointDoneByMissile[missile] = false
            set impactOnPathByMissile[missile] = false
            call SpellIndex(missile.data).destroy()
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function Cleanup takes SpellIndex dex, integer reason returns nothing
        local integer hid
        local integer pointDex
        local integer pointDex2
        local string snd
        if dex == 0 then
            return
        endif

        if dex.source != null then
            if reason == CLEANUP_REASON_INTERRUPTED then
                // Sound: caster interrupted (stun/death/cancel).
                set snd = castSoundInterrupted[dex]
                call PlaySoundOnUnit(snd, dex.source)
            elseif reason == CLEANUP_REASON_COMPLETED then
                // Sound: channeling completed successfully.
                set snd = castSoundChannelComplete[dex]
                call PlaySoundOnUnit(snd, dex.source)
            endif
            set hid = GetHandleId(dex.source)
            if activeData.has(hid) and (activeData[hid] == dex) then
                call activeData.remove(hid)
            endif
            call SetUnitTimeScale(dex.source, 1.0)
            call SetUnitState(dex.source, UNIT_STATE_MANA, 0.)
        endif
        set pointDex = castNormalPointData[dex]
        set pointDex2 = castSpecialPointData[dex]
        if pointDex != 0 then
            set pointClosed[pointDex] = true
        endif
        if (pointDex2 != 0) and (pointDex2 != pointDex) then
            set pointClosed[pointDex2] = true
        endif
        call ReleasePointDataIfIdle(pointDex)
        if pointDex2 != pointDex then
            call ReleasePointDataIfIdle(pointDex2)
        endif
        set castNormalPointData[dex] = 0
        set castSpecialPointData[dex] = 0

        if castFx[dex] != null then
            call DestroyEffect(castFx[dex])
            set castFx[dex] = null
        endif
        if castWaitFx[dex] != null then
            call DestroyEffect(castWaitFx[dex])
            set castWaitFx[dex] = null
        endif
        if castDummy[dex] != null then
            call RemoveUnit(castDummy[dex])
            set castDummy[dex] = null
        endif

        if dex.clock != null then
            call ReleaseTimer(dex.clock)
            set dex.clock = null
        endif
        if delayedAnimTimer[dex] != null then
            call ReleaseTimer(delayedAnimTimer[dex])
            set delayedAnimTimer[dex] = null
        endif

        set castX[dex] = 0.
        set castY[dex] = 0.
        set castAngle[dex] = 0.
        set castDistance[dex] = 0.
        set castTargetX[dex] = 0.
        set castTargetY[dex] = 0.
        set castUseRapid[dex] = false
        set castRapidRemaining[dex] = 0.
        set castRapidInterval[dex] = 0.
        set castAnim[dex] = null
        set castAnimScale[dex] = 0.
        set castSoundWaitEnd[dex] = null
        set castSoundInterrupted[dex] = null
        set castSoundChannelComplete[dex] = null
        set castNormalPointData[dex] = 0
        set castSpecialPointData[dex] = 0
        set castNormalShots[dex] = 0

        set dex.source = null
        set dex.target = null
        call dex.destroy()
        set snd = null
    endfunction

    private function FireMissile takes SpellIndex castDex returns nothing
        local unit source = castDex.source
        local player owner = castDex.user
        local integer unitType
        local real startZ
        local real flyZ
        local real arcHeight
        local real arc
        local real speed
        local real damage
        local real collision
        local real scale
        local real manaCost
        local string model
        local string overlayModel
        local string impactFx
        local integer pointDex = 0
        local boolean impactOnPath
        local boolean specialEnabled
        local integer specialAfterNormal
        local boolean isSpecial = false
        local string specialModel
        local string specialOverlay
        local string soundImpact
        local string soundLastMissile
        local string soundDummyClear
        local real specialDamageMult
        local real specialAreaMult
        local real specialSpeedMult
        local real specialMissileScaleMult
        local real specialDummyScaleMult
        local string dummyModel
        local real dummyScale
        local real dummyArea
        local real baseDummyScale
        local real specialDummyScale
        local SpellIndex mDex
        local Missile missile

        if source == null or GetUnitTypeId(source) == 0 then
            set source = null
            set owner = null
            return
        endif

        set unitType = GetUnitTypeId(source)
        if not HasUnitTypeMissileConfig(unitType) then
            set source = null
            set owner = null
            return
        endif

        set speed = GetUnitTypeMissileSpeed(unitType)
        if speed < 1. then
            set speed = 1.
        endif

        set damage = GetUnitTypeMissileDamage(unitType)
        if damage < 0. then
            set damage = 0.
        endif

        set collision = GetUnitTypeMissileCollision(unitType)
        if collision < 0. then
            set collision = 0.
        endif

        set scale = GetUnitTypeMissileScale(unitType)
        if scale <= 0. then
            set scale = 0.01
        endif

        set model = GetUnitTypeMissileModel(unitType)
        set overlayModel = GetUnitTypeMissileOverlayModel(unitType)
        set impactFx = GetUnitTypeDummyImpactFx(unitType)
        set impactOnPath = GetUnitTypeImpactOnPath(unitType)
        set soundImpact = GetUnitTypeSoundImpact(unitType)
        set soundLastMissile = GetUnitTypeSoundLastMissile(unitType)
        set soundDummyClear = GetUnitTypeSoundDummyClear(unitType)
        set specialEnabled = GetUnitTypeSpecialEnabled(unitType)
        set specialAfterNormal = GetUnitTypeSpecialAfterNormalShots(unitType)
        if specialAfterNormal < 1 then
            set specialAfterNormal = 1
        endif
        if specialEnabled then
            if castNormalShots[castDex] >= specialAfterNormal then
                set isSpecial = true
                set castNormalShots[castDex] = 0
            else
                set castNormalShots[castDex] = castNormalShots[castDex] + 1
            endif
        endif

        if isSpecial then
            set specialModel = GetUnitTypeSpecialMissileModel(unitType)
            set specialOverlay = GetUnitTypeSpecialOverlayModel(unitType)
            set specialDamageMult = GetUnitTypeSpecialDamageMult(unitType)
            set specialAreaMult = GetUnitTypeSpecialAreaMult(unitType)
            set specialSpeedMult = GetUnitTypeSpecialSpeedMult(unitType)
            set specialMissileScaleMult = GetUnitTypeSpecialMissileScaleMult(unitType)
            if specialDamageMult < 0. then
                set specialDamageMult = 0.
            endif
            if specialAreaMult < 0. then
                set specialAreaMult = 0.
            endif
            if specialSpeedMult <= 0. then
                set specialSpeedMult = 0.01
            endif
            if specialMissileScaleMult <= 0. then
                set specialMissileScaleMult = 0.01
            endif
            if (specialModel != null) and (specialModel != "") then
                set model = specialModel
            endif
            if (specialOverlay != null) and (specialOverlay != "") then
                set overlayModel = specialOverlay
            endif
            set damage = damage*specialDamageMult
            set collision = collision*specialAreaMult
            set speed = speed*specialSpeedMult
            set scale = scale*specialMissileScaleMult
            if speed < 1. then
                set speed = 1.
            endif
            if scale <= 0. then
                set scale = 0.01
            endif
        endif

        set startZ = GetUnitTypeMissileStartZ(unitType)
        set flyZ = GetUnitTypeMissileFlyHeight(unitType)
        set arcHeight = GetUnitTypeMissileArc(unitType)
        if arcHeight < 0. then
            set arcHeight = 0.
        endif
        if castDistance[castDex] > 0. then
            set arc = Atan((4.0*arcHeight)/castDistance[castDex])
        else
            set arc = 0.
        endif

        set manaCost = GetUnitTypeManaCost(unitType)
        if manaCost > 0. then
            call SetUnitState(source, UNIT_STATE_MANA, RMaxBJ(0., GetUnitState(source, UNIT_STATE_MANA) - manaCost))
        endif

        set mDex = SpellIndex.create()
        set mDex.source = source
        set mDex.user = owner

        set missile = Missile.create(castX[castDex], castY[castDex], startZ, castAngle[castDex], castDistance[castDex], flyZ)
        set missile.source = source
        set missile.owner = owner
        set missile.data = mDex
        set missile.model = model
        set missile.scale = scale
        set missile.collision = collision
        set missile.arc = arc
        call missile.setMovementSpeed(speed)
        set missile.damage = damage

        call UnitTypeMissileCore.launch(missile)
        if (overlayModel != null) and (overlayModel != "") then
            set overlayFx[missile] = AddSpecialEffectTarget(overlayModel, missile.dummy, WRAP_ATTACH_POINT)
        else
            set overlayFx[missile] = null
        endif

        if isSpecial then
            set pointDex = castSpecialPointData[castDex]
            if pointDex == 0 then
                set dummyModel = GetUnitTypeDummyModel(unitType)
                if (dummyModel != null) and (dummyModel != "") then
                    set dummyScale = GetUnitTypeDummyScale(unitType)
                    if dummyScale <= 0. then
                        set dummyScale = 0.01
                    endif
                    set dummyArea = GetUnitTypeDummyArea(unitType)
                    if dummyArea <= 0. then
                        set dummyArea = 100.
                    endif
                    set specialDummyScaleMult = GetUnitTypeSpecialDummyScaleMult(unitType)
                    if specialDummyScaleMult <= 0. then
                        set specialDummyScaleMult = 0.01
                    endif
                    set baseDummyScale = dummyScale*(dummyArea/100.)
                    set specialDummyScale = baseDummyScale*specialDummyScaleMult
                    set pointDex = SpellIndex.create()
                    set castSpecialPointData[castDex] = pointDex
                    set pointDummy[pointDex] = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY_UNIT_ID, castTargetX[castDex], castTargetY[castDex], castAngle[castDex]*bj_RADTODEG)
                    call SetUnitScale(pointDummy[pointDex], specialDummyScale, specialDummyScale, specialDummyScale)
                    set pointFx[pointDex] = AddSpecialEffectTarget(dummyModel, pointDummy[pointDex], "origin")
                    call UnitAddAbility(pointDummy[pointDex], DUMMY_ABILITY)
                    call SetUnitAbilityLevel(pointDummy[pointDex], DUMMY_ABILITY, 1)
                    call UnitRemoveAbility(pointDummy[pointDex], DUMMY_ABILITY)
                    set pointImpactFx[pointDex] = impactFx
                    set pointSoundImpact[pointDex] = soundImpact
                    set pointSoundLastMissile[pointDex] = soundLastMissile
                    set pointSoundDummyClear[pointDex] = soundDummyClear
                    set pointPending[pointDex] = 0
                    set pointImpactApplied[pointDex] = false
                    set pointClosed[pointDex] = false
                    set pointHadImpact[pointDex] = false
                endif
            endif
        else
            set pointDex = castNormalPointData[castDex]
            if (pointDex == 0) and ((castDummy[castDex] != null) or (castFx[castDex] != null)) then
                set pointDex = SpellIndex.create()
                set castNormalPointData[castDex] = pointDex
                set pointDummy[pointDex] = castDummy[castDex]
                set pointFx[pointDex] = castFx[castDex]
                set pointImpactFx[pointDex] = impactFx
                set pointSoundImpact[pointDex] = soundImpact
                set pointSoundLastMissile[pointDex] = soundLastMissile
                set pointSoundDummyClear[pointDex] = soundDummyClear
                set pointPending[pointDex] = 0
                set pointImpactApplied[pointDex] = false
                set pointClosed[pointDex] = false
                set pointHadImpact[pointDex] = false
                set castDummy[castDex] = null
                set castFx[castDex] = null
            endif
        endif

        if pointDex != 0 then
            set pointPending[pointDex] = pointPending[pointDex] + 1
            set pointByMissile[missile] = pointDex
            set pointDoneByMissile[missile] = false
        else
            set pointByMissile[missile] = 0
            set pointDoneByMissile[missile] = true
        endif
        set impactOnPathByMissile[missile] = impactOnPath

        set source = null
        set owner = null
        set specialModel = null
        set specialOverlay = null
        set impactFx = null
        set soundImpact = null
        set soundLastMissile = null
        set soundDummyClear = null
        set dummyModel = null
    endfunction

    private function OnFire takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)

        // Timer consumed; don't keep a stale handle in dex.clock.
        if dex.clock == t then
            set dex.clock = null
        endif
        call ReleaseTimer(t)
        set t = null

        if (dex == 0) or (dex.source == null) or (GetUnitTypeId(dex.source) == 0) then
            call Cleanup(dex, CLEANUP_REASON_NONE)
            return
        endif
        if not UnitAlive(dex.source) then
            call Cleanup(dex, CLEANUP_REASON_INTERRUPTED)
            return
        endif
        if not IsUnitChanneling(dex.source) then
            call Cleanup(dex, CLEANUP_REASON_INTERRUPTED)
            return
        endif

        // Caster wait effect now persists during the whole cast and is removed in Cleanup.

        // Sound: wait finished and shot tick starts (fires each rapid-fire interval).
        call PlaySoundOnUnit(castSoundWaitEnd[dex], dex.source)
        // Rapid-fire animation: replay attack every interval.
        if (castAnim[dex] != null) and (castAnim[dex] != "") then
            call SetUnitAnimation(dex.source, castAnim[dex])
            call SetUnitTimeScale(dex.source, castAnimScale[dex])
        endif

        call FireMissile(dex)

        if castUseRapid[dex] then
            set castRapidRemaining[dex] = castRapidRemaining[dex] - castRapidInterval[dex]
            if castRapidRemaining[dex] > 0. then
                set dex.clock = NewTimerEx(dex)
                call SetTimerDebugTag(dex.clock, TIMER_DEBUG_TAG_OTHER)
                call TimerStart(dex.clock, castRapidInterval[dex], false, function OnFire)
                return
            endif
        endif

        // Wait for SPELL_FINISH to classify completion reliably.
        // This avoids marking "completed" from internal rapid-fire timer only.
        return
    endfunction

    private function DelayedStartAnimation takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local SpellIndex dex = GetTimerData(t)
        local unit source = dex.source
        local integer hid
        set delayedAnimTimer[dex] = null
        call ReleaseTimer(t)
        set t = null

        if (source != null) and UnitAlive(source) then
            set hid = GetHandleId(source)
            if activeData.has(hid) and (activeData[hid] == dex) then
                if (castAnim[dex] != null) and (castAnim[dex] != "") then
                    call SetUnitAnimation(source, castAnim[dex])
                    call SetUnitTimeScale(source, castAnimScale[dex])
                endif
            endif
        endif
        set source = null
    endfunction

    private function OnEffect takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local integer unitType = GetUnitTypeId(u)
        local integer hid = GetHandleId(u)
        local real x = GetUnitX(u)
        local real y = GetUnitY(u)
        local real tx = GetSpellTargetX()
        local real ty = GetSpellTargetY()
        local real dx = tx - x
        local real dy = ty - y
        local SpellIndex dex
        local string dummyModel
        local real dummyScale
        local real dummyArea
        local real dummyDelay
        local string casterWaitFx
        local string castAnimLocal
        local real castTimeScale
        local real castDelay
        local real interval
        local real duration
        local string soundCastStart
        local string soundWaitStart
        local string soundWaitEnd
        local string soundInterrupted
        local string soundChannelComplete

        if not HasUnitTypeMissileConfig(unitType) then
            // Cancel cast immediately when this unit type has no loadout config.
            call IssueImmediateOrder(u, "stop")
            set u = null
            return
        endif

        if activeData.has(hid) then
            call Cleanup(activeData[hid], CLEANUP_REASON_INTERRUPTED)
        endif

        set dex = SpellIndex.create()
        set dex.source = u
        set dex.user = GetOwningPlayer(u)
        set soundCastStart = GetUnitTypeSoundCastStart(unitType)
        set soundWaitStart = GetUnitTypeSoundWaitStart(unitType)
        set soundWaitEnd = GetUnitTypeSoundWaitEnd(unitType)
        set soundInterrupted = GetUnitTypeSoundInterrupted(unitType)
        set soundChannelComplete = GetUnitTypeSoundChannelComplete(unitType)
        set castSoundWaitEnd[dex] = soundWaitEnd
        set castSoundInterrupted[dex] = soundInterrupted
        set castSoundChannelComplete[dex] = soundChannelComplete

        // Sound: ability cast started.
        call PlaySoundOnUnit(soundCastStart, u)

        set castX[dex] = x
        set castY[dex] = y
        set castAngle[dex] = Atan2(dy, dx)
        set castDistance[dex] = SquareRoot(dx*dx + dy*dy)
        set castNormalPointData[dex] = 0
        set castSpecialPointData[dex] = 0
        set castNormalShots[dex] = 0
        if castDistance[dex] <= 0. then
            set castDistance[dex] = 1.
        endif
        set castTargetX[dex] = tx
        set castTargetY[dex] = ty
        set dummyModel = GetUnitTypeDummyModel(unitType)
        set dummyScale = GetUnitTypeDummyScale(unitType)
        set dummyArea = GetUnitTypeDummyArea(unitType)
        if dummyArea <= 0. then
            set dummyArea = 100.
        endif
        set dummyDelay = GetUnitTypeDummyDelay(unitType)
        if dummyDelay < 0. then
            set dummyDelay = 0.
        endif

        if (dummyModel != null) and (dummyModel != "") then
            set castDummy[dex] = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY_UNIT_ID, castTargetX[dex], castTargetY[dex], castAngle[dex]*bj_RADTODEG)
            call SetUnitScale(castDummy[dex], dummyScale*(dummyArea/100.), dummyScale*(dummyArea/100.), dummyScale*(dummyArea/100.))
            set castFx[dex] = AddSpecialEffectTarget(dummyModel, castDummy[dex], "origin")
            call UnitAddAbility(castDummy[dex], DUMMY_ABILITY)
            call SetUnitAbilityLevel(castDummy[dex], DUMMY_ABILITY, 1)
            call UnitRemoveAbility(castDummy[dex], DUMMY_ABILITY)
        else
            set castDummy[dex] = null
            set castFx[dex] = null
        endif

        set casterWaitFx = GetUnitTypeCasterWaitFx(unitType)
        if (casterWaitFx != null) and (casterWaitFx != "") then
            set castWaitFx[dex] = AddSpecialEffectTarget(casterWaitFx, u, "origin")
        else
            set castWaitFx[dex] = null
        endif
        // Sound: wait phase started.
        call PlaySoundOnUnit(soundWaitStart, u)

        set castUseRapid[dex] = GetUnitTypeUseRapidFire(unitType)
        set interval = GetUnitTypeRapidFireInterval(unitType)
        set duration = GetUnitTypeRapidFireDuration(unitType)
        if interval <= 0. then
            set interval = 0.10
        endif
        if duration < 0. then
            set duration = 0.
        endif
        set castRapidInterval[dex] = interval
        set castRapidRemaining[dex] = duration

        // Animation (immediate or delayed)
        set castAnimLocal = GetUnitTypeCastAnimation(unitType)
        set castDelay = GetUnitTypeCastAnimationDelay(unitType)
        set castTimeScale = GetUnitTypeCastAnimationTimeScale(unitType)
        if castTimeScale <= 0. then
            set castTimeScale = 1.
        endif
        set castAnim[dex] = castAnimLocal
        set castAnimScale[dex] = castTimeScale
        if (castAnimLocal != null) and (castAnimLocal != "") then
            if castDelay <= 0. then
                call SetUnitAnimation(u, castAnimLocal)
                call SetUnitTimeScale(u, castTimeScale)
            else
                set delayedAnimTimer[dex] = NewTimerEx(dex)
                call SetTimerDebugTag(delayedAnimTimer[dex], TIMER_DEBUG_TAG_OTHER)
                call TimerStart(delayedAnimTimer[dex], castDelay, false, function DelayedStartAnimation)
            endif
        endif

        set activeData[hid] = dex

        set dex.clock = NewTimerEx(dex)
        call SetTimerDebugTag(dex.clock, TIMER_DEBUG_TAG_OTHER)
        call TimerStart(dex.clock, dummyDelay, false, function OnFire)

        set soundCastStart = null
        set soundWaitStart = null
        set soundWaitEnd = null
        set soundInterrupted = null
        set soundChannelComplete = null
        set u = null
    endfunction

    private function OnInterrupted takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local integer hid = GetHandleId(u)
        if activeData.has(hid) then
            // Ignore transient endcast/orders while the caster is still channeling.
            // This avoids cutting the active cast flow on internal retarget/recast.
            if IsUnitChanneling(u) then
                set u = null
                return
            endif
            call Cleanup(activeData[hid], CLEANUP_REASON_INTERRUPTED)
        endif
        set u = null
    endfunction

    private function OnSpellFinish takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local integer hid = GetHandleId(u)
        if activeData.has(hid) then
            call Cleanup(activeData[hid], CLEANUP_REASON_COMPLETED)
        endif
        set u = null
    endfunction

    private function OnDeath takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local integer hid = GetHandleId(u)
        if activeData.has(hid) then
            call Cleanup(activeData[hid], CLEANUP_REASON_INTERRUPTED)
        endif
        set u = null
    endfunction

    private function Init takes nothing returns nothing
        set activeData = Table.create()
        call RegisterSpellEffectEvent(MISSILE_ABILITY_ID, function OnEffect)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_ENDCAST, function OnInterrupted)
        call RegisterSpellFinishEvent(MISSILE_ABILITY_ID, function OnSpellFinish)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function OnDeath)
    endfunction
endlibrary
