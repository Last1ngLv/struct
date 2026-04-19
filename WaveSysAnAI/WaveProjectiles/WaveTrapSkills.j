library WaveTrapSkills initializer Init requires Table, TimerUtils, Missile, SpellIndex, RegisterPlayerUnitEvent, WaveTest, WaveSkillVisuals

    globals
        public constant integer WAVE_HSOR_UNIT_ID = 'hsor'
        public constant integer WAVE_HSOR_BOSS_UNIT_ID = 'zA06'

        public constant string WAVE_HSOR_PROJECTILE_MODEL = "war3mapImported\\Ubershield Azure x3.mdx"
        public constant string WAVE_HSOR_BOSS_PROJECTILE_MODEL = "war3mapImported\\Ubershield Starfire x3.mdx"
        public constant real WAVE_HSOR_PROJECTILE_SPEED = 950.0
        public constant real WAVE_HSOR_PROJECTILE_START_Z = 75.0
        public constant real WAVE_HSOR_PROJECTILE_ARC = 0.12
        public constant real WAVE_HSOR_PROJECTILE_CATCH_RADIUS = 150.0
        public constant real WAVE_HSOR_WINDUP = 1.50
        public constant real WAVE_HSOR_CAST_RANGE = 2000.0

        public constant real WAVE_HSOR_TRAP_RADIUS = 150.0
        public constant real WAVE_HSOR_TRAP_DURATION = 3.50
        public constant real WAVE_HSOR_INITIAL_DELAY_MIN = 2.00
        public constant real WAVE_HSOR_INITIAL_DELAY_MAX = 3.50
        public constant real WAVE_HSOR_COOLDOWN_MIN = 8.00
        public constant real WAVE_HSOR_COOLDOWN_MAX = 10.00

        public constant real WAVE_HSOR_BOSS_TRAP_RADIUS = 850.0
        public constant real WAVE_HSOR_BOSS_TRAP_DURATION = 5.50
        public constant real WAVE_HSOR_BOSS_INITIAL_DELAY_MIN = 3.00
        public constant real WAVE_HSOR_BOSS_INITIAL_DELAY_MAX = 4.50
        public constant real WAVE_HSOR_BOSS_COOLDOWN_MIN = 10.00
        public constant real WAVE_HSOR_BOSS_COOLDOWN_MAX = 12.00

        private constant real WAVE_HSOR_TICK = 0.05

        private Table WaveTrapNextCastMs
        private Table WaveTrapActiveCastByUnit
        private timer WaveTrapTimer
        private boolean WaveTrapTimerRunning = false
        private integer WaveTrapCastHead = 0
        private integer WaveTrapCastCount = 0
        private integer WaveTrapHead = 0
        private integer WaveTrapCount = 0

        private integer array WaveTrapCastNext
        private integer array WaveTrapCastPrev
        private unit array WaveTrapCastSource
        private real array WaveTrapCastTargetX
        private real array WaveTrapCastTargetY
        private real array WaveTrapCastRemaining
        private real array WaveTrapCastRadius
        private real array WaveTrapCastDuration
        private string array WaveTrapCastModel
        private boolean array WaveTrapCastPaused

        private integer array WaveTrapNext
        private integer array WaveTrapPrev
        private player array WaveTrapOwner
        private real array WaveTrapX
        private real array WaveTrapY
        private real array WaveTrapRadius
        private real array WaveTrapRemaining
        private integer array WaveTrapVisualId

        private player array WaveTrapMissileOwner
        private real array WaveTrapMissileRadius
        private real array WaveTrapMissileDuration
        private string array WaveTrapMissileModel
        private boolean array WaveTrapMissilePlanted

        private real array WaveTrapComputedStunByPlayer
        private boolean array WaveTrapHeroStunnedByPlayer
    endglobals

    private function WaveTrapSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WaveTrapRandomMsRange takes real minSec, real maxSec returns integer
        local real lo = minSec
        local real hi = maxSec
        if hi < lo then
            set lo = maxSec
            set hi = minSec
        endif
        if hi <= 0.0 then
            return 0
        endif
        if lo < 0.0 then
            set lo = 0.0
        endif
        return WaveTrapSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WaveTrapUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WaveTrapTargetInCastRange takes unit source, unit target returns boolean
        local real dx
        local real dy
        if not WaveTrapUnitAlive(source) or not WaveTrapUnitAlive(target) then
            return false
        endif
        set dx = GetUnitX(target) - GetUnitX(source)
        set dy = GetUnitY(target) - GetUnitY(source)
        return dx*dx + dy*dy <= WAVE_HSOR_CAST_RANGE*WAVE_HSOR_CAST_RANGE
    endfunction

    private function WaveTrapIsBoss takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HSOR_BOSS_UNIT_ID
    endfunction

    private function WaveTrapAddCast takes integer castId returns nothing
        set WaveTrapCastPrev[castId] = 0
        set WaveTrapCastNext[castId] = WaveTrapCastHead
        if WaveTrapCastHead != 0 then
            set WaveTrapCastPrev[WaveTrapCastHead] = castId
        endif
        set WaveTrapCastHead = castId
    endfunction

    private function WaveTrapRemoveCast takes integer castId returns nothing
        local integer p = WaveTrapCastPrev[castId]
        local integer n = WaveTrapCastNext[castId]
        if p != 0 then
            set WaveTrapCastNext[p] = n
        else
            set WaveTrapCastHead = n
        endif
        if n != 0 then
            set WaveTrapCastPrev[n] = p
        endif
        set WaveTrapCastPrev[castId] = 0
        set WaveTrapCastNext[castId] = 0
    endfunction

    private function WaveTrapDestroyCast takes integer castId returns nothing
        local unit source = WaveTrapCastSource[castId]
        local integer hid = 0
        if source != null and GetUnitTypeId(source) != 0 then
            set hid = GetHandleId(source)
            if WaveTrapCastPaused[castId] then
                call PauseUnit(source, false)
            endif
        endif
        call WaveTrapRemoveCast(castId)
        if hid != 0 and WaveTrapActiveCastByUnit.has(hid) and WaveTrapActiveCastByUnit[hid] == castId then
            call WaveTrapActiveCastByUnit.remove(hid)
        endif
        set WaveTrapCastSource[castId] = null
        set WaveTrapCastTargetX[castId] = 0.0
        set WaveTrapCastTargetY[castId] = 0.0
        set WaveTrapCastRemaining[castId] = 0.0
        set WaveTrapCastRadius[castId] = 0.0
        set WaveTrapCastDuration[castId] = 0.0
        set WaveTrapCastModel[castId] = ""
        set WaveTrapCastPaused[castId] = false
    endfunction

    private function WaveTrapAdd takes integer trapId returns nothing
        set WaveTrapPrev[trapId] = 0
        set WaveTrapNext[trapId] = WaveTrapHead
        if WaveTrapHead != 0 then
            set WaveTrapPrev[WaveTrapHead] = trapId
        endif
        set WaveTrapHead = trapId
    endfunction

    private function WaveTrapRemove takes integer trapId returns nothing
        local integer p = WaveTrapPrev[trapId]
        local integer n = WaveTrapNext[trapId]
        if p != 0 then
            set WaveTrapNext[p] = n
        else
            set WaveTrapHead = n
        endif
        if n != 0 then
            set WaveTrapPrev[n] = p
        endif
        set WaveTrapPrev[trapId] = 0
        set WaveTrapNext[trapId] = 0
    endfunction

    private function WaveTrapDestroy takes integer trapId returns nothing
        if trapId <= 0 then
            return
        endif
        call WaveTrapRemove(trapId)
        if WaveTrapVisualId[trapId] != 0 then
            call WaveSkillVisualDestroy(WaveTrapVisualId[trapId])
            set WaveTrapVisualId[trapId] = 0
        endif
        set WaveTrapOwner[trapId] = null
        set WaveTrapX[trapId] = 0.0
        set WaveTrapY[trapId] = 0.0
        set WaveTrapRadius[trapId] = 0.0
        set WaveTrapRemaining[trapId] = 0.0
    endfunction

    private function WaveTrapPlant takes player owner, real x, real y, real radius, real duration, string modelPath returns nothing
        local integer trapId
        if owner == null or duration <= 0.0 or radius <= 0.0 then
            return
        endif
        set trapId = WaveTrapCount + 1
        set WaveTrapCount = trapId
        set WaveTrapOwner[trapId] = owner
        set WaveTrapX[trapId] = x
        set WaveTrapY[trapId] = y
        set WaveTrapRadius[trapId] = radius
        set WaveTrapRemaining[trapId] = duration
        set WaveTrapVisualId[trapId] = WaveSkillVisualCreateTimedMarkerScaled(x, y, 0.0, modelPath, WaveSkillVisualShieldScaleForRadius(radius), duration)
        call WaveTrapAdd(trapId)
    endfunction

    private function WaveTrapCanCatchHero takes player owner, unit target returns boolean
        if owner == null or not WaveTrapUnitAlive(target) then
            return false
        endif
        if not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif
        if not IsUnitEnemy(target, owner) then
            return false
        endif
        if GetUnitAbilityLevel(target, 'Avul') > 0 then
            return false
        endif
        return true
    endfunction

    private struct WaveTrapMissile extends array
        private static method plantFromMissile takes Missile missile, real x, real y returns nothing
            if WaveTrapMissilePlanted[missile] then
                return
            endif
            set WaveTrapMissilePlanted[missile] = true
            call WaveTrapPlant(WaveTrapMissileOwner[missile], x, y, WaveTrapMissileRadius[missile], WaveTrapMissileDuration[missile], WaveTrapMissileModel[missile])
        endmethod

        private static method onCollide takes Missile missile, unit hit returns boolean
            if WaveTrapCanCatchHero(missile.owner, hit) then
                call thistype.plantFromMissile(missile, GetUnitX(hit), GetUnitY(hit))
                return true
            endif
            return false
        endmethod

        private static method onFinish takes Missile missile returns boolean
            call thistype.plantFromMissile(missile, missile.x, missile.y)
            return true
        endmethod

        private static method onRemove takes Missile missile returns boolean
            set WaveTrapMissileOwner[missile] = null
            set WaveTrapMissileRadius[missile] = 0.0
            set WaveTrapMissileDuration[missile] = 0.0
            set WaveTrapMissileModel[missile] = ""
            set WaveTrapMissilePlanted[missile] = false
            return true
        endmethod

        implement MissileStruct
    endstruct

    private function WaveTrapLaunchProjectile takes unit source, real tx, real ty, real radius, real duration, string modelPath returns nothing
        local Missile missile
        local real sx
        local real sy
        if not WaveTrapUnitAlive(source) then
            return
        endif
        set sx = GetUnitX(source)
        set sy = GetUnitY(source)
        set missile = Missile.createXYZ(sx, sy, WAVE_HSOR_PROJECTILE_START_Z, tx, ty, WAVE_HSOR_PROJECTILE_START_Z)
        set missile.source = source
        set missile.owner = GetOwningPlayer(source)
        set missile.model = modelPath
        set missile.scale = WaveSkillVisualShieldScaleForRadius(radius)
        set missile.collision = WAVE_HSOR_PROJECTILE_CATCH_RADIUS
        set missile.arc = WAVE_HSOR_PROJECTILE_ARC
        call missile.setMovementSpeed(WAVE_HSOR_PROJECTILE_SPEED)
        set WaveTrapMissileOwner[missile] = GetOwningPlayer(source)
        set WaveTrapMissileRadius[missile] = radius
        set WaveTrapMissileDuration[missile] = duration
        set WaveTrapMissileModel[missile] = modelPath
        set WaveTrapMissilePlanted[missile] = false
        call WaveTrapMissile.launch(missile)
    endfunction

    private function WaveTrapStartCast takes unit source, real tx, real ty, real radius, real duration, string modelPath returns nothing
        local integer castId = WaveTrapCastCount + 1
        local integer hid = GetHandleId(source)
        set WaveTrapCastCount = castId
        set WaveTrapCastSource[castId] = source
        set WaveTrapCastTargetX[castId] = tx
        set WaveTrapCastTargetY[castId] = ty
        set WaveTrapCastRemaining[castId] = WAVE_HSOR_WINDUP
        set WaveTrapCastRadius[castId] = radius
        set WaveTrapCastDuration[castId] = duration
        set WaveTrapCastModel[castId] = modelPath
        set WaveTrapCastPaused[castId] = true
        call WaveTrapAddCast(castId)
        set WaveTrapActiveCastByUnit[hid] = castId
        call IssueImmediateOrder(source, "stop")
        call SetUnitAnimation(source, "spell")
        call PauseUnit(source, true)
    endfunction

    private function WaveTrapUpdateStuns takes nothing returns nothing
        local integer playerId = 0
        local integer trapId
        local unit hero
        local real dx
        local real dy
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            set WaveTrapComputedStunByPlayer[playerId] = 0.0
            set playerId = playerId + 1
        endloop

        set trapId = WaveTrapHead
        loop
            exitwhen trapId == 0
            set playerId = 0
            loop
                exitwhen playerId >= bj_MAX_PLAYER_SLOTS
                set hero = PlayerHero[playerId]
                if WaveTrapCanCatchHero(WaveTrapOwner[trapId], hero) then
                    set dx = GetUnitX(hero) - WaveTrapX[trapId]
                    set dy = GetUnitY(hero) - WaveTrapY[trapId]
                    if dx*dx + dy*dy <= WaveTrapRadius[trapId]*WaveTrapRadius[trapId] and WaveTrapRemaining[trapId] > WaveTrapComputedStunByPlayer[playerId] then
                        set WaveTrapComputedStunByPlayer[playerId] = WaveTrapRemaining[trapId]
                    endif
                endif
                set playerId = playerId + 1
            endloop
            set trapId = WaveTrapNext[trapId]
        endloop

        set playerId = 0
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            set hero = PlayerHero[playerId]
            if hero != null and GetUnitTypeId(hero) != 0 and WaveTrapComputedStunByPlayer[playerId] > 0.0 then
                if not WaveTrapHeroStunnedByPlayer[playerId] then
                    call IssueImmediateOrder(hero, "stop")
                    call PauseUnit(hero, true)
                    set WaveTrapHeroStunnedByPlayer[playerId] = true
                endif
            else
                if WaveTrapHeroStunnedByPlayer[playerId] and hero != null and GetUnitTypeId(hero) != 0 and UnitAlive(hero) then
                    call PauseUnit(hero, false)
                endif
                set WaveTrapHeroStunnedByPlayer[playerId] = false
            endif
            set playerId = playerId + 1
        endloop
        set hero = null
    endfunction

    private function WaveTrapOnTick takes nothing returns nothing
        local integer castId = WaveTrapCastHead
        local integer nextCastId
        local integer trapId = WaveTrapHead
        local integer nextTrapId
        loop
            exitwhen castId == 0
            set nextCastId = WaveTrapCastNext[castId]
            if not WaveTrapUnitAlive(WaveTrapCastSource[castId]) then
                call WaveTrapDestroyCast(castId)
            else
                set WaveTrapCastRemaining[castId] = WaveTrapCastRemaining[castId] - WAVE_HSOR_TICK
                if WaveTrapCastRemaining[castId] <= 0.0 then
                    call WaveTrapLaunchProjectile(WaveTrapCastSource[castId], WaveTrapCastTargetX[castId], WaveTrapCastTargetY[castId], WaveTrapCastRadius[castId], WaveTrapCastDuration[castId], WaveTrapCastModel[castId])
                    call WaveTrapDestroyCast(castId)
                endif
            endif
            set castId = nextCastId
        endloop

        loop
            exitwhen trapId == 0
            set nextTrapId = WaveTrapNext[trapId]
            set WaveTrapRemaining[trapId] = WaveTrapRemaining[trapId] - WAVE_HSOR_TICK
            if WaveTrapRemaining[trapId] <= 0.0 then
                call WaveTrapDestroy(trapId)
            endif
            set trapId = nextTrapId
        endloop

        call WaveTrapUpdateStuns()

    endfunction


    private function WaveTrapCleanupWaveDeath takes nothing returns nothing
        local unit deadUnit = GetWaveEventUnit()
        local integer hid
        local integer castId
        local integer unitTypeId
        if deadUnit == null or GetUnitTypeId(deadUnit) == 0 then
            return
        endif
        set unitTypeId = GetUnitTypeId(deadUnit)
        if unitTypeId != WAVE_HSOR_UNIT_ID and unitTypeId != WAVE_HSOR_BOSS_UNIT_ID then
            return
        endif
        set hid = GetHandleId(deadUnit)
        if hid != 0 and WaveTrapNextCastMs.has(hid) then
            call WaveTrapNextCastMs.remove(hid)
        endif
        if hid != 0 and WaveTrapActiveCastByUnit.has(hid) then
            set castId = WaveTrapActiveCastByUnit[hid]
            call WaveTrapDestroyCast(castId)
        endif
    endfunction

    private function WaveTrapOnPlayerUnitDeath takes nothing returns boolean
        local unit deadUnit = GetTriggerUnit()
        local integer playerId = 0
        if deadUnit == null then
            return false
        endif
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            if PlayerHero[playerId] == deadUnit then
                if WaveTrapHeroStunnedByPlayer[playerId] then
                    call PauseUnit(deadUnit, false)
                    set WaveTrapHeroStunnedByPlayer[playerId] = false
                    set WaveTrapComputedStunByPlayer[playerId] = 0.0
                endif
                set playerId = bj_MAX_PLAYER_SLOTS
            endif
            set playerId = playerId + 1
        endloop
        set deadUnit = null
        return false
    endfunction

    function WaveTrapSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        local integer hid
        local integer nextMs
        local real radius
        local real duration
        local string modelPath
        local boolean isBoss = false
        if not WaveTrapUnitAlive(source) then
            return false
        endif
        if WaveTrapIsBoss(source) then
            set isBoss = true
        elseif GetUnitTypeId(source) != WAVE_HSOR_UNIT_ID then
            return false
        endif
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) or not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif
        if not WaveTrapTargetInCastRange(source, target) then
            return false
        endif

        set hid = GetHandleId(source)
        if hid == 0 then
            return false
        endif
        if WaveTrapActiveCastByUnit.has(hid) and WaveTrapActiveCastByUnit[hid] != 0 then
            return true
        endif
        if not WaveTrapNextCastMs.has(hid) then
            if isBoss then
                set WaveTrapNextCastMs[hid] = nowMs + WaveTrapRandomMsRange(WAVE_HSOR_BOSS_INITIAL_DELAY_MIN, WAVE_HSOR_BOSS_INITIAL_DELAY_MAX)
            else
                set WaveTrapNextCastMs[hid] = nowMs + WaveTrapRandomMsRange(WAVE_HSOR_INITIAL_DELAY_MIN, WAVE_HSOR_INITIAL_DELAY_MAX)
            endif
            return false
        endif

        set nextMs = WaveTrapNextCastMs[hid]
        if nowMs < nextMs then
            return false
        endif

        if isBoss then
            set radius = WAVE_HSOR_BOSS_TRAP_RADIUS
            set duration = WAVE_HSOR_BOSS_TRAP_DURATION
            set modelPath = WAVE_HSOR_BOSS_PROJECTILE_MODEL
            set WaveTrapNextCastMs[hid] = nowMs + WaveTrapRandomMsRange(WAVE_HSOR_BOSS_COOLDOWN_MIN, WAVE_HSOR_BOSS_COOLDOWN_MAX)
        else
            set radius = WAVE_HSOR_TRAP_RADIUS
            set duration = WAVE_HSOR_TRAP_DURATION
            set modelPath = WAVE_HSOR_PROJECTILE_MODEL
            set WaveTrapNextCastMs[hid] = nowMs + WaveTrapRandomMsRange(WAVE_HSOR_COOLDOWN_MIN, WAVE_HSOR_COOLDOWN_MAX)
        endif

        call WaveTrapStartCast(source, GetUnitX(target), GetUnitY(target), radius, duration, modelPath)
        return true
    endfunction

    private function Init takes nothing returns nothing
        set WaveTrapNextCastMs = Table.create()
        set WaveTrapActiveCastByUnit = Table.create()
        set WaveTrapTimer = NewTimer()
        call SetTimerDebugTag(WaveTrapTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)
        set WaveTrapTimerRunning = true
        call TimerStart(WaveTrapTimer, WAVE_HSOR_TICK, true, function WaveTrapOnTick)
        call RegisterWaveDeathEvent(function WaveTrapCleanupWaveDeath)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function WaveTrapOnPlayerUnitDeath)
    endfunction
endlibrary
