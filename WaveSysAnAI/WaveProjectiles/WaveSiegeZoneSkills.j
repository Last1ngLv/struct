library WaveSiegeZoneSkills initializer Init requires Table, TimerUtils, SpellIndex, WaveTest

    globals
        public constant integer WAVE_HMTT_UNIT_ID = 'hmtt'
        public constant integer WAVE_HMTT_BOSS_UNIT_ID = 'zA08'
        public constant string WAVE_HMTT_ZONE_MODEL = "war3mapImported\\NuclearExplosion.mdx"
        public constant string WAVE_HMTT_AREA_MODEL = "war3mapImported\\Spell Marker Green.mdx"

        public constant real WAVE_HMTT_WINDUP = 0.50
        public constant real WAVE_HMTT_ZONE_DURATION = 10.0
        public constant real WAVE_HMTT_ZONE_TICK = 1.00
        public constant real WAVE_HMTT_CAST_RANGE = 1000.0

        public constant real WAVE_HMTT_RADIUS = 850.0
        public constant real WAVE_HMTT_DAMAGE = 15.0
        public constant real WAVE_HMTT_INITIAL_DELAY_MIN = 1.00
        public constant real WAVE_HMTT_INITIAL_DELAY_MAX = 1.50
        public constant real WAVE_HMTT_COOLDOWN_MIN = 4.00
        public constant real WAVE_HMTT_COOLDOWN_MAX = 6.00

        public constant real WAVE_HMTT_BOSS_RADIUS = 1500.0
        public constant real WAVE_HMTT_BOSS_DAMAGE = 30.0
        public constant real WAVE_HMTT_BOSS_INITIAL_DELAY_MIN = 1.00
        public constant real WAVE_HMTT_BOSS_INITIAL_DELAY_MAX = 1.50
        public constant real WAVE_HMTT_BOSS_COOLDOWN_MIN = 5.00
        public constant real WAVE_HMTT_BOSS_COOLDOWN_MAX = 7.00

        private constant real WAVE_HMTT_TICK = 0.05
        private constant integer WAVE_HMTT_DUMMY_ID = 'dumi'
        private constant integer WAVE_HMTT_LOCUST_ID = 'Aloc'
        private constant integer WAVE_HMTT_INVUL_ID = 'Avul'

        private Table WaveSiegeZoneNextCastMs
        private Table WaveSiegeZoneActiveCastByUnit
        private timer WaveSiegeZoneTimer
        private boolean WaveSiegeZoneTimerRunning = false
        private integer WaveSiegeZoneCastHead = 0
        private integer WaveSiegeZoneCastCount = 0
        private integer WaveSiegeZoneHead = 0
        private integer WaveSiegeZoneCount = 0

        private integer array WaveSiegeZoneCastNext
        private integer array WaveSiegeZoneCastPrev
        private unit array WaveSiegeZoneCastSource
        private real array WaveSiegeZoneCastTargetX
        private real array WaveSiegeZoneCastTargetY
        private real array WaveSiegeZoneCastRemaining
        private real array WaveSiegeZoneCastRadius
        private real array WaveSiegeZoneCastDamage
        private boolean array WaveSiegeZoneCastPaused

        private integer array WaveSiegeZoneNext
        private integer array WaveSiegeZonePrev
        private unit array WaveSiegeZoneSource
        private player array WaveSiegeZoneOwner
        private real array WaveSiegeZoneX
        private real array WaveSiegeZoneY
        private real array WaveSiegeZoneRadius
        private real array WaveSiegeZoneDamage
        private real array WaveSiegeZoneRemaining
        private real array WaveSiegeZoneAccumulator
        private unit array WaveSiegeZoneDummy
        private effect array WaveSiegeZoneFx
        private effect array WaveSiegeZoneAreaFx
    endglobals

    private function WaveSiegeZoneScaleForRadius takes real radius returns real
        if radius <= 0.0 then
            return 0.01
        endif
        return radius/200.0
    endfunction

    private function WaveSiegeZoneSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WaveSiegeZoneRandomMsRange takes real minSec, real maxSec returns integer
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
        return WaveSiegeZoneSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WaveSiegeZoneUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WaveSiegeZoneAddCast takes integer castId returns nothing
        set WaveSiegeZoneCastPrev[castId] = 0
        set WaveSiegeZoneCastNext[castId] = WaveSiegeZoneCastHead
        if WaveSiegeZoneCastHead != 0 then
            set WaveSiegeZoneCastPrev[WaveSiegeZoneCastHead] = castId
        endif
        set WaveSiegeZoneCastHead = castId
    endfunction

    private function WaveSiegeZoneRemoveCast takes integer castId returns nothing
        local integer p = WaveSiegeZoneCastPrev[castId]
        local integer n = WaveSiegeZoneCastNext[castId]
        if p != 0 then
            set WaveSiegeZoneCastNext[p] = n
        else
            set WaveSiegeZoneCastHead = n
        endif
        if n != 0 then
            set WaveSiegeZoneCastPrev[n] = p
        endif
        set WaveSiegeZoneCastPrev[castId] = 0
        set WaveSiegeZoneCastNext[castId] = 0
    endfunction

    private function WaveSiegeZoneDestroyCast takes integer castId returns nothing
        local unit source = WaveSiegeZoneCastSource[castId]
        local integer hid = 0
        if source != null and GetUnitTypeId(source) != 0 then
            set hid = GetHandleId(source)
            if WaveSiegeZoneCastPaused[castId] then
                call PauseUnit(source, false)
            endif
        endif
        call WaveSiegeZoneRemoveCast(castId)
        if hid != 0 and WaveSiegeZoneActiveCastByUnit.has(hid) and WaveSiegeZoneActiveCastByUnit[hid] == castId then
            call WaveSiegeZoneActiveCastByUnit.remove(hid)
        endif
        set WaveSiegeZoneCastSource[castId] = null
        set WaveSiegeZoneCastTargetX[castId] = 0.0
        set WaveSiegeZoneCastTargetY[castId] = 0.0
        set WaveSiegeZoneCastRemaining[castId] = 0.0
        set WaveSiegeZoneCastRadius[castId] = 0.0
        set WaveSiegeZoneCastDamage[castId] = 0.0
        set WaveSiegeZoneCastPaused[castId] = false
    endfunction

    private function WaveSiegeZoneAdd takes integer zoneId returns nothing
        set WaveSiegeZonePrev[zoneId] = 0
        set WaveSiegeZoneNext[zoneId] = WaveSiegeZoneHead
        if WaveSiegeZoneHead != 0 then
            set WaveSiegeZonePrev[WaveSiegeZoneHead] = zoneId
        endif
        set WaveSiegeZoneHead = zoneId
    endfunction

    private function WaveSiegeZoneRemove takes integer zoneId returns nothing
        local integer p = WaveSiegeZonePrev[zoneId]
        local integer n = WaveSiegeZoneNext[zoneId]
        if p != 0 then
            set WaveSiegeZoneNext[p] = n
        else
            set WaveSiegeZoneHead = n
        endif
        if n != 0 then
            set WaveSiegeZonePrev[n] = p
        endif
        set WaveSiegeZonePrev[zoneId] = 0
        set WaveSiegeZoneNext[zoneId] = 0
    endfunction

    private function WaveSiegeZoneDestroy takes integer zoneId returns nothing
        if zoneId <= 0 then
            return
        endif
        call WaveSiegeZoneRemove(zoneId)
        if WaveSiegeZoneFx[zoneId] != null then
            call DestroyEffect(WaveSiegeZoneFx[zoneId])
            set WaveSiegeZoneFx[zoneId] = null
        endif
        if WaveSiegeZoneAreaFx[zoneId] != null then
            call DestroyEffect(WaveSiegeZoneAreaFx[zoneId])
            set WaveSiegeZoneAreaFx[zoneId] = null
        endif
        if WaveSiegeZoneDummy[zoneId] != null and GetUnitTypeId(WaveSiegeZoneDummy[zoneId]) != 0 then
            call RemoveUnit(WaveSiegeZoneDummy[zoneId])
        endif
        set WaveSiegeZoneDummy[zoneId] = null
        set WaveSiegeZoneSource[zoneId] = null
        set WaveSiegeZoneOwner[zoneId] = null
        set WaveSiegeZoneX[zoneId] = 0.0
        set WaveSiegeZoneY[zoneId] = 0.0
        set WaveSiegeZoneRadius[zoneId] = 0.0
        set WaveSiegeZoneDamage[zoneId] = 0.0
        set WaveSiegeZoneRemaining[zoneId] = 0.0
        set WaveSiegeZoneAccumulator[zoneId] = 0.0
    endfunction

    private function WaveSiegeZoneCreate takes unit source, real x, real y, real radius, real damage returns nothing
        local integer zoneId
        local unit dummy
        if not WaveSiegeZoneUnitAlive(source) then
            return
        endif
        set zoneId = WaveSiegeZoneCount + 1
        set WaveSiegeZoneCount = zoneId
        set dummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), WAVE_HMTT_DUMMY_ID, x, y, 0.0)
        if dummy != null and GetUnitTypeId(dummy) != 0 then
            call UnitAddAbility(dummy, WAVE_HMTT_LOCUST_ID)
            call UnitAddAbility(dummy, WAVE_HMTT_INVUL_ID)
            call SetUnitPathing(dummy, false)
            call SetUnitScale(dummy, WaveSiegeZoneScaleForRadius(radius), WaveSiegeZoneScaleForRadius(radius), WaveSiegeZoneScaleForRadius(radius))
            set WaveSiegeZoneFx[zoneId] = AddSpecialEffectTarget(WAVE_HMTT_ZONE_MODEL, dummy, "origin")
            set WaveSiegeZoneAreaFx[zoneId] = AddSpecialEffectTarget(WAVE_HMTT_AREA_MODEL, dummy, "origin")
        endif
        set WaveSiegeZoneDummy[zoneId] = dummy
        set WaveSiegeZoneSource[zoneId] = source
        set WaveSiegeZoneOwner[zoneId] = GetOwningPlayer(source)
        set WaveSiegeZoneX[zoneId] = x
        set WaveSiegeZoneY[zoneId] = y
        set WaveSiegeZoneRadius[zoneId] = radius
        set WaveSiegeZoneDamage[zoneId] = damage
        set WaveSiegeZoneRemaining[zoneId] = WAVE_HMTT_ZONE_DURATION
        set WaveSiegeZoneAccumulator[zoneId] = 0.0
        call WaveSiegeZoneAdd(zoneId)
        set dummy = null
    endfunction

    private function WaveSiegeZoneApplyDamage takes integer zoneId returns nothing
        local unit hit
        local unit source = WaveSiegeZoneSource[zoneId]
        if WaveSiegeZoneOwner[zoneId] == null then
            set source = null
            return
        endif
        if source == null or GetUnitTypeId(source) == 0 then
            set source = WaveSiegeZoneDummy[zoneId]
        endif
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, WaveSiegeZoneX[zoneId], WaveSiegeZoneY[zoneId], WaveSiegeZoneRadius[zoneId], null)
        loop
            set hit = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen hit == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, hit)
            if UnitAlive(hit) and IsUnitEnemy(hit, WaveSiegeZoneOwner[zoneId]) then
                if source != null and GetUnitTypeId(source) != 0 then
                    call UnitDamageTarget(source, hit, WaveSiegeZoneDamage[zoneId], false, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, null)
                endif
            endif
        endloop
        set hit = null
        set source = null
    endfunction

    private function WaveSiegeZoneOnTick takes nothing returns nothing
        local integer castId = WaveSiegeZoneCastHead
        local integer nextCastId
        local integer zoneId = WaveSiegeZoneHead
        local integer nextZoneId
        loop
            exitwhen castId == 0
            set nextCastId = WaveSiegeZoneCastNext[castId]
            if not WaveSiegeZoneUnitAlive(WaveSiegeZoneCastSource[castId]) then
                call WaveSiegeZoneDestroyCast(castId)
            else
                set WaveSiegeZoneCastRemaining[castId] = WaveSiegeZoneCastRemaining[castId] - WAVE_HMTT_TICK
                if WaveSiegeZoneCastRemaining[castId] <= 0.0 then
                    call WaveSiegeZoneCreate(WaveSiegeZoneCastSource[castId], WaveSiegeZoneCastTargetX[castId], WaveSiegeZoneCastTargetY[castId], WaveSiegeZoneCastRadius[castId], WaveSiegeZoneCastDamage[castId])
                    call WaveSiegeZoneDestroyCast(castId)
                endif
            endif
            set castId = nextCastId
        endloop

        loop
            exitwhen zoneId == 0
            set nextZoneId = WaveSiegeZoneNext[zoneId]
            set WaveSiegeZoneRemaining[zoneId] = WaveSiegeZoneRemaining[zoneId] - WAVE_HMTT_TICK
            set WaveSiegeZoneAccumulator[zoneId] = WaveSiegeZoneAccumulator[zoneId] + WAVE_HMTT_TICK
            loop
                exitwhen WaveSiegeZoneAccumulator[zoneId] < WAVE_HMTT_ZONE_TICK
                set WaveSiegeZoneAccumulator[zoneId] = WaveSiegeZoneAccumulator[zoneId] - WAVE_HMTT_ZONE_TICK
                call WaveSiegeZoneApplyDamage(zoneId)
            endloop
            if WaveSiegeZoneRemaining[zoneId] <= 0.0 then
                call WaveSiegeZoneDestroy(zoneId)
            endif
            set zoneId = nextZoneId
        endloop

        if WaveSiegeZoneCastHead == 0 and WaveSiegeZoneHead == 0 and WaveSiegeZoneTimerRunning then
            call PauseTimer(WaveSiegeZoneTimer)
            set WaveSiegeZoneTimerRunning = false
        endif
    endfunction

    private function WaveSiegeZoneEnsureTimer takes nothing returns nothing
        if not WaveSiegeZoneTimerRunning then
            set WaveSiegeZoneTimerRunning = true
            call TimerStart(WaveSiegeZoneTimer, WAVE_HMTT_TICK, true, function WaveSiegeZoneOnTick)
        endif
    endfunction

    private function WaveSiegeZoneStartCast takes unit source, real tx, real ty, real radius, real damage returns nothing
        local integer castId = WaveSiegeZoneCastCount + 1
        local integer hid = GetHandleId(source)
        set WaveSiegeZoneCastCount = castId
        set WaveSiegeZoneCastSource[castId] = source
        set WaveSiegeZoneCastTargetX[castId] = tx
        set WaveSiegeZoneCastTargetY[castId] = ty
        set WaveSiegeZoneCastRemaining[castId] = WAVE_HMTT_WINDUP
        set WaveSiegeZoneCastRadius[castId] = radius
        set WaveSiegeZoneCastDamage[castId] = damage
        set WaveSiegeZoneCastPaused[castId] = true
        call WaveSiegeZoneAddCast(castId)
        set WaveSiegeZoneActiveCastByUnit[hid] = castId
        call IssueImmediateOrder(source, "stop")
        call SetUnitAnimation(source, "attack")
        call PauseUnit(source, true)
    endfunction

    private function WaveSiegeZoneCleanupWaveDeath takes nothing returns nothing
        local unit deadUnit = GetWaveEventUnit()
        local integer hid
        local integer castId
        local integer unitTypeId
        if deadUnit == null or GetUnitTypeId(deadUnit) == 0 then
            return
        endif
        set unitTypeId = GetUnitTypeId(deadUnit)
        if unitTypeId != WAVE_HMTT_UNIT_ID and unitTypeId != WAVE_HMTT_BOSS_UNIT_ID then
            return
        endif
        set hid = GetHandleId(deadUnit)
        if hid != 0 and WaveSiegeZoneNextCastMs.has(hid) then
            call WaveSiegeZoneNextCastMs.remove(hid)
        endif
        if hid != 0 and WaveSiegeZoneActiveCastByUnit.has(hid) then
            set castId = WaveSiegeZoneActiveCastByUnit[hid]
            call WaveSiegeZoneDestroyCast(castId)
        endif
    endfunction

    function WaveSiegeZoneSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        local integer hid
        local integer nextMs
        local real radius
        local real damage
        local real dx
        local real dy
        local boolean isBoss = false
        if not WaveSiegeZoneUnitAlive(source) then
            return false
        endif
        if GetUnitTypeId(source) == WAVE_HMTT_BOSS_UNIT_ID then
            set isBoss = true
        elseif GetUnitTypeId(source) != WAVE_HMTT_UNIT_ID then
            return false
        endif
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) or not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif
        set dx = GetUnitX(target) - GetUnitX(source)
        set dy = GetUnitY(target) - GetUnitY(source)
        if dx*dx + dy*dy > WAVE_HMTT_CAST_RANGE*WAVE_HMTT_CAST_RANGE then
            return false
        endif

        set hid = GetHandleId(source)
        if hid == 0 then
            return false
        endif
        if WaveSiegeZoneActiveCastByUnit.has(hid) and WaveSiegeZoneActiveCastByUnit[hid] != 0 then
            return true
        endif
        if not WaveSiegeZoneNextCastMs.has(hid) then
            if isBoss then
                set WaveSiegeZoneNextCastMs[hid] = nowMs + WaveSiegeZoneRandomMsRange(WAVE_HMTT_BOSS_INITIAL_DELAY_MIN, WAVE_HMTT_BOSS_INITIAL_DELAY_MAX)
            else
                set WaveSiegeZoneNextCastMs[hid] = nowMs + WaveSiegeZoneRandomMsRange(WAVE_HMTT_INITIAL_DELAY_MIN, WAVE_HMTT_INITIAL_DELAY_MAX)
            endif
            return false
        endif

        set nextMs = WaveSiegeZoneNextCastMs[hid]
        if nowMs < nextMs then
            return false
        endif

        if isBoss then
            set radius = WAVE_HMTT_BOSS_RADIUS
            set damage = WAVE_HMTT_BOSS_DAMAGE
            set WaveSiegeZoneNextCastMs[hid] = nowMs + WaveSiegeZoneRandomMsRange(WAVE_HMTT_BOSS_COOLDOWN_MIN, WAVE_HMTT_BOSS_COOLDOWN_MAX)
        else
            set radius = WAVE_HMTT_RADIUS
            set damage = WAVE_HMTT_DAMAGE
            set WaveSiegeZoneNextCastMs[hid] = nowMs + WaveSiegeZoneRandomMsRange(WAVE_HMTT_COOLDOWN_MIN, WAVE_HMTT_COOLDOWN_MAX)
        endif

        call WaveSiegeZoneStartCast(source, GetUnitX(target), GetUnitY(target), radius, damage)
        call WaveSiegeZoneEnsureTimer()
        return true
    endfunction

    private function Init takes nothing returns nothing
        set WaveSiegeZoneNextCastMs = Table.create()
        set WaveSiegeZoneActiveCastByUnit = Table.create()
        set WaveSiegeZoneTimer = NewTimer()
        call SetTimerDebugTag(WaveSiegeZoneTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)
        call RegisterWaveDeathEvent(function WaveSiegeZoneCleanupWaveDeath)
    endfunction
endlibrary
