library WaveRangedSkills initializer Init requires Table, TimerUtils, WaveTest, WaveProjectileCore, WaveProjectileConfig, TerrainPathability, WaveSkillVisuals

    globals
        public constant integer WAVE_HRIF_UNIT_ID = 'hrif'
        public constant integer WAVE_HRIF_BOSS_UNIT_ID = 'zA03'

        public constant string WAVE_HRIF_TELEGRAPH_LIGHTNING_CODE = "FORK"
        public constant real WAVE_HRIF_TELEGRAPH_DURATION = 1.00
        public constant real WAVE_HRIF_BOSS_TELEGRAPH_DURATION = 1.00
        public constant real WAVE_HRIF_TELEGRAPH_TICK = 0.05
        public constant real WAVE_HRIF_LIGHTNING_SOURCE_Z = 90.0
        public constant real WAVE_HRIF_LIGHTNING_TARGET_Z = 90.0
        public constant string WAVE_HRIF_TARGET_MARKER_MODEL = "war3mapImported\\Spell Marker Green.mdx"

        public constant real WAVE_HRIF_COOLDOWN_MIN = 4.50
        public constant real WAVE_HRIF_COOLDOWN_MAX = 7.00
        public constant real WAVE_HRIF_INITIAL_DELAY_MIN = 1.50
        public constant real WAVE_HRIF_INITIAL_DELAY_MAX = 3.00

        public constant real WAVE_HRIF_BOSS_COOLDOWN_MIN = 12.00
        public constant real WAVE_HRIF_BOSS_COOLDOWN_MAX = 16.00
        public constant real WAVE_HRIF_BOSS_INITIAL_DELAY_MIN = 3.00
        public constant real WAVE_HRIF_BOSS_INITIAL_DELAY_MAX = 5.00
        public constant integer WAVE_HRIF_BOSS_VOLLEY_COUNT = 10
        public constant real WAVE_HRIF_BOSS_VOLLEY_INTERVAL = 0.50

        private constant integer WAVE_RANGED_MODE_HRIF = 1
        private constant integer WAVE_RANGED_MODE_HRIF_BOSS = 2
        private constant integer WAVE_RANGED_PHASE_TELEGRAPH = 1
        private constant integer WAVE_RANGED_PHASE_VOLLEY = 2

        private Table WaveRangedNextCastMs
        private Table WaveRangedActiveCastByUnit
        private timer WaveRangedTickTimer
        private boolean WaveRangedTickRunning = false
        private integer WaveRangedCastHead = 0
        private integer WaveRangedCastCount = 0
        private unit array WaveRangedTrackedHeroByPlayer[24]

        private integer array WaveRangedCastNext
        private integer array WaveRangedCastPrev
        private integer array WaveRangedCastMode
        private integer array WaveRangedCastPhase
        private integer array WaveRangedCastVolleyRemaining
        private real array WaveRangedCastVolleyAccumulator
        private unit array WaveRangedCastSource
        private unit array WaveRangedCastTarget
        private real array WaveRangedCastTargetX
        private real array WaveRangedCastTargetY
        private real array WaveRangedCastElapsed
        private integer array WaveRangedCastTargetMarker
        private lightning array WaveRangedCastLightning
        private lightning array WaveRangedBossLightningByIndex
        private boolean array WaveRangedCastSourcePaused
    endglobals

    private function WaveRangedBossLightningIndex takes integer castId, integer playerId returns integer
        return castId*bj_MAX_PLAYER_SLOTS + playerId
    endfunction

    private function WaveRangedSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WaveRangedRandomMsRange takes real minSec, real maxSec returns integer
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
        return WaveRangedSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WaveRangedUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WaveRangedIsEnemyHeroOfSource takes unit source, unit target returns boolean
        if not WaveRangedUnitAlive(source) or not WaveRangedUnitAlive(target) then
            return false
        endif
        if not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif
        return IsUnitEnemy(target, GetOwningPlayer(source))
    endfunction

    private function WaveRangedIsHrifBase takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HRIF_UNIT_ID
    endfunction

    private function WaveRangedIsHrifBoss takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HRIF_BOSS_UNIT_ID
    endfunction

    private function WaveRangedCastAdd takes integer castId returns nothing
        set WaveRangedCastPrev[castId] = 0
        set WaveRangedCastNext[castId] = WaveRangedCastHead
        if WaveRangedCastHead != 0 then
            set WaveRangedCastPrev[WaveRangedCastHead] = castId
        endif
        set WaveRangedCastHead = castId
    endfunction

    private function WaveRangedCastRemove takes integer castId returns nothing
        local integer p = WaveRangedCastPrev[castId]
        local integer n = WaveRangedCastNext[castId]
        if p != 0 then
            set WaveRangedCastNext[p] = n
        else
            set WaveRangedCastHead = n
        endif
        if n != 0 then
            set WaveRangedCastPrev[n] = p
        endif
        set WaveRangedCastPrev[castId] = 0
        set WaveRangedCastNext[castId] = 0
    endfunction

    private function WaveRangedDestroyBossLightnings takes integer castId returns nothing
        local integer playerId = 0
        local integer lightningIndex
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            set lightningIndex = WaveRangedBossLightningIndex(castId, playerId)
            if WaveRangedBossLightningByIndex[lightningIndex] != null then
                call DestroyLightning(WaveRangedBossLightningByIndex[lightningIndex])
                set WaveRangedBossLightningByIndex[lightningIndex] = null
            endif
            set playerId = playerId + 1
        endloop
    endfunction

    private function WaveRangedCastDestroy takes integer castId returns nothing
        local unit source = WaveRangedCastSource[castId]
        local integer hid = 0
        if source != null and GetUnitTypeId(source) != 0 then
            set hid = GetHandleId(source)
        endif
        call WaveRangedCastRemove(castId)
        if hid != 0 and WaveRangedActiveCastByUnit.has(hid) and WaveRangedActiveCastByUnit[hid] == castId then
            call WaveRangedActiveCastByUnit.remove(hid)
        endif
        if WaveRangedCastLightning[castId] != null then
            call DestroyLightning(WaveRangedCastLightning[castId])
            set WaveRangedCastLightning[castId] = null
        endif
        call WaveRangedDestroyBossLightnings(castId)
        if WaveRangedCastTargetMarker[castId] != 0 then
            call WaveSkillVisualDestroy(WaveRangedCastTargetMarker[castId])
            set WaveRangedCastTargetMarker[castId] = 0
        endif
        if WaveRangedCastSourcePaused[castId] and source != null and GetUnitTypeId(source) != 0 then
            call PauseUnit(source, false)
        endif
        set WaveRangedCastMode[castId] = 0
        set WaveRangedCastPhase[castId] = 0
        set WaveRangedCastVolleyRemaining[castId] = 0
        set WaveRangedCastVolleyAccumulator[castId] = 0.0
        set WaveRangedCastSource[castId] = null
        set WaveRangedCastTarget[castId] = null
        set WaveRangedCastTargetX[castId] = 0.0
        set WaveRangedCastTargetY[castId] = 0.0
        set WaveRangedCastElapsed[castId] = 0.0
        set WaveRangedCastSourcePaused[castId] = false
    endfunction

    private function WaveRangedCreateHrifImpactMarker takes unit source, real tx, real ty returns nothing
        local real dx
        local real dy
        local real duration
        if not WaveRangedUnitAlive(source) then
            return
        endif
        set dx = tx - GetUnitX(source)
        set dy = ty - GetUnitY(source)
        set duration = SquareRoot(dx*dx + dy*dy) / WAVE_HRIF_PROJECTILE_SPEED
        if duration < 0.10 then
            set duration = 0.10
        endif
        call WaveSkillVisualCreateTimedMarker(tx, ty, 0.0, WAVE_HRIF_TARGET_MARKER_MODEL, WAVE_HRIF_PROJECTILE_FINISH_AOE, duration)
    endfunction

    private function WaveRangedLaunchHrifProjectilePoint takes unit source, real tx, real ty returns nothing
        if not WaveRangedUnitAlive(source) then
            return
        endif
        call WaveRangedCreateHrifImpactMarker(source, tx, ty)
        call WaveProjectileLaunchFromSourceToPointExact(WAVE_PROJECTILE_TYPE_HRIF, source, tx, ty, WAVE_HRIF_PROJECTILE_DAMAGE)
    endfunction

    private function WaveRangedLaunchHrifProjectile takes integer castId returns nothing
        call WaveRangedLaunchHrifProjectilePoint(WaveRangedCastSource[castId], WaveRangedCastTargetX[castId], WaveRangedCastTargetY[castId])
    endfunction

    private function WaveRangedBossCountEnemyHeroes takes unit source returns integer
        local integer playerId = 0
        local integer count = 0
        local unit hero
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            set hero = WaveRangedTrackedHeroByPlayer[playerId]
            if WaveRangedIsEnemyHeroOfSource(source, hero) then
                set count = count + 1
            endif
            set playerId = playerId + 1
        endloop
        set hero = null
        return count
    endfunction

    private function WaveRangedBossFireVolley takes integer castId returns nothing
        local unit source = WaveRangedCastSource[castId]
        local unit hero
        local integer playerId = 0
        local boolean fired = false
        if not WaveRangedUnitAlive(source) then
            set source = null
            return
        endif
        call SetUnitAnimation(source, "attack")
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            set hero = WaveRangedTrackedHeroByPlayer[playerId]
            if WaveRangedIsEnemyHeroOfSource(source, hero) then
                call WaveRangedLaunchHrifProjectilePoint(source, GetUnitX(hero), GetUnitY(hero))
                set fired = true
            endif
            set playerId = playerId + 1
        endloop
        if (not fired) and WaveRangedIsEnemyHeroOfSource(source, WaveRangedCastTarget[castId]) then
            call WaveRangedLaunchHrifProjectilePoint(source, GetUnitX(WaveRangedCastTarget[castId]), GetUnitY(WaveRangedCastTarget[castId]))
        endif
        set hero = null
        set source = null
    endfunction

    private function WaveRangedBossCreateTelegraphs takes integer castId returns nothing
        local integer playerId = 0
        local integer lightningIndex
        local unit source = WaveRangedCastSource[castId]
        local unit hero
        local real sx
        local real sy
        if not WaveRangedUnitAlive(source) then
            set source = null
            return
        endif
        set sx = GetUnitX(source)
        set sy = GetUnitY(source)
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            set hero = WaveRangedTrackedHeroByPlayer[playerId]
            if WaveRangedIsEnemyHeroOfSource(source, hero) then
                set lightningIndex = WaveRangedBossLightningIndex(castId, playerId)
                set WaveRangedBossLightningByIndex[lightningIndex] = AddLightningEx(WAVE_HRIF_TELEGRAPH_LIGHTNING_CODE, true, sx, sy, WAVE_HRIF_LIGHTNING_SOURCE_Z, GetUnitX(hero), GetUnitY(hero), WAVE_HRIF_LIGHTNING_TARGET_Z)
            endif
            set playerId = playerId + 1
        endloop
        set hero = null
        set source = null
    endfunction

    private function WaveRangedBossUpdateTelegraphs takes integer castId returns nothing
        local integer playerId = 0
        local integer lightningIndex
        local unit source = WaveRangedCastSource[castId]
        local unit hero
        local real sx
        local real sy
        if not WaveRangedUnitAlive(source) then
            set source = null
            return
        endif
        set sx = GetUnitX(source)
        set sy = GetUnitY(source)
        loop
            exitwhen playerId >= bj_MAX_PLAYER_SLOTS
            set lightningIndex = WaveRangedBossLightningIndex(castId, playerId)
            set hero = WaveRangedTrackedHeroByPlayer[playerId]
            if WaveRangedBossLightningByIndex[lightningIndex] != null then
                if WaveRangedIsEnemyHeroOfSource(source, hero) then
                    call MoveLightningEx(WaveRangedBossLightningByIndex[lightningIndex], true, sx, sy, WAVE_HRIF_LIGHTNING_SOURCE_Z, GetUnitX(hero), GetUnitY(hero), WAVE_HRIF_LIGHTNING_TARGET_Z)
                else
                    call DestroyLightning(WaveRangedBossLightningByIndex[lightningIndex])
                    set WaveRangedBossLightningByIndex[lightningIndex] = null
                endif
            elseif WaveRangedIsEnemyHeroOfSource(source, hero) then
                set WaveRangedBossLightningByIndex[lightningIndex] = AddLightningEx(WAVE_HRIF_TELEGRAPH_LIGHTNING_CODE, true, sx, sy, WAVE_HRIF_LIGHTNING_SOURCE_Z, GetUnitX(hero), GetUnitY(hero), WAVE_HRIF_LIGHTNING_TARGET_Z)
            endif
            set playerId = playerId + 1
        endloop
        set hero = null
        set source = null
    endfunction

    private function WaveRangedOnTick takes nothing returns nothing
        local integer castId = WaveRangedCastHead
        local integer nextCastId
        local unit source
        local unit target
        local real sx
        local real sy
        loop
            exitwhen castId == 0
            set nextCastId = WaveRangedCastNext[castId]
            set source = WaveRangedCastSource[castId]
            set target = WaveRangedCastTarget[castId]
            if not WaveRangedUnitAlive(source) then
                call WaveRangedCastDestroy(castId)
            elseif WaveRangedCastMode[castId] == WAVE_RANGED_MODE_HRIF then
                if WaveRangedUnitAlive(target) then
                    set WaveRangedCastTargetX[castId] = GetUnitX(target)
                    set WaveRangedCastTargetY[castId] = GetUnitY(target)
                endif
                set sx = GetUnitX(source)
                set sy = GetUnitY(source)
                if WaveRangedCastLightning[castId] != null then
                    call MoveLightningEx(WaveRangedCastLightning[castId], true, sx, sy, WAVE_HRIF_LIGHTNING_SOURCE_Z, WaveRangedCastTargetX[castId], WaveRangedCastTargetY[castId], WAVE_HRIF_LIGHTNING_TARGET_Z)
                endif
                set WaveRangedCastElapsed[castId] = WaveRangedCastElapsed[castId] + WAVE_HRIF_TELEGRAPH_TICK
                if WaveRangedCastElapsed[castId] >= WAVE_HRIF_TELEGRAPH_DURATION then
                    call WaveRangedLaunchHrifProjectile(castId)
                    call WaveRangedCastDestroy(castId)
                endif
            elseif WaveRangedCastMode[castId] == WAVE_RANGED_MODE_HRIF_BOSS then
                if WaveRangedCastPhase[castId] == WAVE_RANGED_PHASE_TELEGRAPH then
                    call WaveRangedBossUpdateTelegraphs(castId)
                    set WaveRangedCastElapsed[castId] = WaveRangedCastElapsed[castId] + WAVE_HRIF_TELEGRAPH_TICK
                    if WaveRangedCastElapsed[castId] >= WAVE_HRIF_BOSS_TELEGRAPH_DURATION then
                        call WaveRangedDestroyBossLightnings(castId)
                        set WaveRangedCastPhase[castId] = WAVE_RANGED_PHASE_VOLLEY
                        set WaveRangedCastElapsed[castId] = 0.0
                        set WaveRangedCastVolleyAccumulator[castId] = 0.0
                        call WaveRangedBossFireVolley(castId)
                        set WaveRangedCastVolleyRemaining[castId] = WaveRangedCastVolleyRemaining[castId] - 1
                        if WaveRangedCastVolleyRemaining[castId] <= 0 then
                            call WaveRangedCastDestroy(castId)
                        endif
                    endif
                else
                    set WaveRangedCastVolleyAccumulator[castId] = WaveRangedCastVolleyAccumulator[castId] + WAVE_HRIF_TELEGRAPH_TICK
                    loop
                        exitwhen WaveRangedCastVolleyRemaining[castId] <= 0 or WaveRangedCastVolleyAccumulator[castId] < WAVE_HRIF_BOSS_VOLLEY_INTERVAL
                        set WaveRangedCastVolleyAccumulator[castId] = WaveRangedCastVolleyAccumulator[castId] - WAVE_HRIF_BOSS_VOLLEY_INTERVAL
                        call WaveRangedBossFireVolley(castId)
                        set WaveRangedCastVolleyRemaining[castId] = WaveRangedCastVolleyRemaining[castId] - 1
                    endloop
                    if WaveRangedCastVolleyRemaining[castId] <= 0 then
                        call WaveRangedCastDestroy(castId)
                    endif
                endif
            else
                call WaveRangedCastDestroy(castId)
            endif
            set castId = nextCastId
        endloop

        if WaveRangedCastHead == 0 and WaveRangedTickRunning then
            call PauseTimer(WaveRangedTickTimer)
            set WaveRangedTickRunning = false
        endif

        set source = null
        set target = null
    endfunction

    private function WaveRangedEnsureTickTimer takes nothing returns nothing
        if not WaveRangedTickRunning then
            set WaveRangedTickRunning = true
            call TimerStart(WaveRangedTickTimer, WAVE_HRIF_TELEGRAPH_TICK, true, function WaveRangedOnTick)
        endif
    endfunction

    private function WaveRangedStartHrifCast takes unit source, unit target returns nothing
        local integer castId = WaveRangedCastCount + 1
        local integer hid = GetHandleId(source)
        local real tx = GetUnitX(target)
        local real ty = GetUnitY(target)
        local real angle = Atan2(ty - GetUnitY(source), tx - GetUnitX(source))

        set WaveRangedCastCount = castId
        set WaveRangedCastMode[castId] = WAVE_RANGED_MODE_HRIF
        set WaveRangedCastPhase[castId] = WAVE_RANGED_PHASE_TELEGRAPH
        set WaveRangedCastVolleyRemaining[castId] = 0
        set WaveRangedCastVolleyAccumulator[castId] = 0.0
        set WaveRangedCastSource[castId] = source
        set WaveRangedCastTarget[castId] = target
        set WaveRangedCastTargetX[castId] = tx
        set WaveRangedCastTargetY[castId] = ty
        set WaveRangedCastElapsed[castId] = 0.0
        set WaveRangedCastLightning[castId] = null
        set WaveRangedCastTargetMarker[castId] = 0
        set WaveRangedCastSourcePaused[castId] = false

        call WaveRangedCastAdd(castId)
        set WaveRangedActiveCastByUnit[hid] = castId
        call IssueImmediateOrder(source, "stop")
        call SetUnitFacing(source, angle*bj_RADTODEG)
        call SetUnitAnimation(source, "attack")
        call WaveRangedEnsureTickTimer()
    endfunction

    private function WaveRangedStartHrifBossCast takes unit source, unit target returns nothing
        local integer castId = WaveRangedCastCount + 1
        local integer hid = GetHandleId(source)
        local real tx = 0.0
        local real ty = 0.0
        local real angle

        if target != null and GetUnitTypeId(target) != 0 then
            set tx = GetUnitX(target)
            set ty = GetUnitY(target)
        else
            set tx = GetUnitX(source)
            set ty = GetUnitY(source)
        endif
        set angle = Atan2(ty - GetUnitY(source), tx - GetUnitX(source))

        set WaveRangedCastCount = castId
        set WaveRangedCastMode[castId] = WAVE_RANGED_MODE_HRIF_BOSS
        set WaveRangedCastPhase[castId] = WAVE_RANGED_PHASE_TELEGRAPH
        set WaveRangedCastVolleyRemaining[castId] = WAVE_HRIF_BOSS_VOLLEY_COUNT
        set WaveRangedCastVolleyAccumulator[castId] = 0.0
        set WaveRangedCastSource[castId] = source
        set WaveRangedCastTarget[castId] = target
        set WaveRangedCastTargetX[castId] = tx
        set WaveRangedCastTargetY[castId] = ty
        set WaveRangedCastElapsed[castId] = 0.0
        set WaveRangedCastLightning[castId] = null
        set WaveRangedCastSourcePaused[castId] = true

        call WaveRangedCastAdd(castId)
        set WaveRangedActiveCastByUnit[hid] = castId
        call IssueImmediateOrder(source, "stop")
        call SetUnitFacing(source, angle*bj_RADTODEG)
        call SetUnitAnimation(source, "attack")
        call PauseUnit(source, true)
        call WaveRangedBossCreateTelegraphs(castId)
        call WaveRangedEnsureTickTimer()
    endfunction

    private function WaveRangedCleanupDeadCaster takes nothing returns nothing
        local unit u = GetWaveEventUnit()
        local integer hid
        local integer castId
        local integer unitType
        if u == null then
            return
        endif
        set unitType = GetUnitTypeId(u)
        if unitType != WAVE_HRIF_UNIT_ID and unitType != WAVE_HRIF_BOSS_UNIT_ID then
            set u = null
            return
        endif
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveRangedCleanupDeadCaster enter " + WaveDeathDebugContextSummary())
        endif
        set hid = GetHandleId(u)
        if hid != 0 and WaveRangedActiveCastByUnit.has(hid) then
            set castId = WaveRangedActiveCastByUnit[hid]
            if castId != 0 then
                call WaveRangedCastDestroy(castId)
            endif
        endif
        if hid != 0 and WaveRangedNextCastMs.has(hid) then
            call WaveRangedNextCastMs.remove(hid)
        endif
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveRangedCleanupDeadCaster exit " + WaveDeathDebugContextSummary())
        endif
        set u = null
    endfunction

    function WaveRangedSkillsSetTrackedHeroForPlayer takes integer playerId, unit hero returns nothing
        if playerId < 0 or playerId >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if hero != null and GetUnitTypeId(hero) == 0 then
            set hero = null
        endif
        set WaveRangedTrackedHeroByPlayer[playerId] = hero
    endfunction

    function WaveRangedSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        local integer hid
        local integer nextMs
        local boolean isBoss = false
        if not WaveRangedUnitAlive(source) then
            return false
        endif
        if WaveRangedIsHrifBoss(source) then
            set isBoss = true
        elseif not WaveRangedIsHrifBase(source) then
            return false
        endif
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) or not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif

        set hid = GetHandleId(source)
        if hid == 0 then
            return false
        endif

        if WaveRangedActiveCastByUnit.has(hid) and WaveRangedActiveCastByUnit[hid] != 0 then
            return true
        endif

        if not WaveRangedNextCastMs.has(hid) then
            if isBoss then
                set WaveRangedNextCastMs[hid] = nowMs + WaveRangedRandomMsRange(WAVE_HRIF_BOSS_INITIAL_DELAY_MIN, WAVE_HRIF_BOSS_INITIAL_DELAY_MAX)
            else
                set WaveRangedNextCastMs[hid] = nowMs + WaveRangedRandomMsRange(WAVE_HRIF_INITIAL_DELAY_MIN, WAVE_HRIF_INITIAL_DELAY_MAX)
            endif
            return false
        endif

        set nextMs = WaveRangedNextCastMs[hid]
        if nowMs < nextMs then
            return false
        endif

        if isBoss then
            if WaveRangedBossCountEnemyHeroes(source) > 0 then
                call WaveRangedStartHrifBossCast(source, target)
                set WaveRangedNextCastMs[hid] = nowMs + WaveRangedRandomMsRange(WAVE_HRIF_BOSS_COOLDOWN_MIN, WAVE_HRIF_BOSS_COOLDOWN_MAX)
                return true
            endif
            return false
        endif

        call WaveRangedStartHrifCast(source, target)
        set WaveRangedNextCastMs[hid] = nowMs + WaveRangedRandomMsRange(WAVE_HRIF_COOLDOWN_MIN, WAVE_HRIF_COOLDOWN_MAX)
        return true
    endfunction

    private function Init takes nothing returns nothing
        set WaveRangedNextCastMs = Table.create()
        set WaveRangedActiveCastByUnit = Table.create()
        set WaveRangedTickTimer = NewTimer()
        call SetTimerDebugTag(WaveRangedTickTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)

        // Reafirma el perfil base del proyectil para hrif desde la capa de skill.
        call WaveProjectileSetFinishAoe(WAVE_PROJECTILE_TYPE_HRIF, WAVE_HRIF_PROJECTILE_FINISH_AOE)

        // Hooks listos para cleanup y futuras extensiones.
        call RegisterWaveDeathEvent(function WaveRangedCleanupDeadCaster)
    endfunction
endlibrary
