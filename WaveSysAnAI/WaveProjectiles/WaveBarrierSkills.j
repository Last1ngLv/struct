library WaveBarrierSkills initializer Init requires Table, TimerUtils, WaveTest, TerrainPathability, WaveSkillVisuals

    globals
        public constant integer WAVE_HFOO_UNIT_ID = 'hfoo'
        public constant integer WAVE_HFOO_BOSS_UNIT_ID = 'zA02'
        public constant string WAVE_HFOO_BARRIER_VISUAL_MODEL = "war3mapImported\\Ubershield Azure x3.mdx"
        public constant string WAVE_HFOO_BOSS_BARRIER_VISUAL_MODEL = "war3mapImported\\Ubershield Azure x3.mdx"

        constant integer WAVE_BARRIER_PROJECTILE_KIND_NORMAL = 1
        constant integer WAVE_BARRIER_PROJECTILE_KIND_WIND = 2
        constant integer WAVE_BARRIER_PROJECTILE_KIND_RAY = 3

        constant integer WAVE_BARRIER_INTERACTION_NONE = 0
        constant integer WAVE_BARRIER_INTERACTION_BLOCK = 1
        constant integer WAVE_BARRIER_INTERACTION_WIND = 2
        constant integer WAVE_BARRIER_INTERACTION_RAY = 3

        public constant string WAVE_HFOO_DEFEND_TAG = "defend"

        public constant real WAVE_HFOO_BARRIER_RADIUS = 300.0
        public constant real WAVE_HFOO_BARRIER_DURATION = 5.0
        public constant real WAVE_HFOO_BARRIER_TICK = 0.05
        public constant real WAVE_HFOO_INITIAL_DELAY_MIN = 2.00
        public constant real WAVE_HFOO_INITIAL_DELAY_MAX = 4.00
        public constant real WAVE_HFOO_COOLDOWN_MIN = 12.00
        public constant real WAVE_HFOO_COOLDOWN_MAX = 15.00

        public constant real WAVE_HFOO_BOSS_BARRIER_RADIUS = 850.0
        public constant real WAVE_HFOO_BOSS_BARRIER_DURATION = 8.0
        public constant real WAVE_HFOO_BOSS_INITIAL_DELAY_MIN = 3.00
        public constant real WAVE_HFOO_BOSS_INITIAL_DELAY_MAX = 5.00
        public constant real WAVE_HFOO_BOSS_COOLDOWN_MIN = 18.00
        public constant real WAVE_HFOO_BOSS_COOLDOWN_MAX = 22.00

        private Table WaveBarrierNextCastMs
        private Table WaveBarrierActiveBarrierByUnit
        private Table WaveBarrierVisualByUnit
        private timer WaveBarrierTimer
        private boolean WaveBarrierTimerRunning = false
        private integer WaveBarrierHead = 0
        private integer WaveBarrierCount = 0

        private integer array WaveBarrierNext
        private integer array WaveBarrierPrev
        private unit array WaveBarrierSource
        private integer array WaveBarrierVisualFx
        private real array WaveBarrierRadius
        private real array WaveBarrierRemaining
        private integer array WaveBarrierProjectileBarrierId
        private integer array WaveBarrierProjectileInteractionByKind
    endglobals

    private function WaveBarrierSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WaveBarrierRandomMsRange takes real minSec, real maxSec returns integer
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
        return WaveBarrierSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WaveBarrierUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WaveBarrierIsHfoo takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HFOO_UNIT_ID
    endfunction

    private function WaveBarrierIsHfooBoss takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HFOO_BOSS_UNIT_ID
    endfunction

    private function WaveBarrierVisualModelForSource takes unit source returns string
        if WaveBarrierIsHfooBoss(source) then
            return WAVE_HFOO_BOSS_BARRIER_VISUAL_MODEL
        endif
        return WAVE_HFOO_BARRIER_VISUAL_MODEL
    endfunction

    private function WaveBarrierAdd takes integer barrierId returns nothing
        set WaveBarrierPrev[barrierId] = 0
        set WaveBarrierNext[barrierId] = WaveBarrierHead
        if WaveBarrierHead != 0 then
            set WaveBarrierPrev[WaveBarrierHead] = barrierId
        endif
        set WaveBarrierHead = barrierId
    endfunction

    private function WaveBarrierRemove takes integer barrierId returns nothing
        local integer p = WaveBarrierPrev[barrierId]
        local integer n = WaveBarrierNext[barrierId]
        if p != 0 then
            set WaveBarrierNext[p] = n
        else
            set WaveBarrierHead = n
        endif
        if n != 0 then
            set WaveBarrierPrev[n] = p
        endif
        set WaveBarrierPrev[barrierId] = 0
        set WaveBarrierNext[barrierId] = 0
    endfunction

    private function WaveBarrierContains takes integer barrierId, player projectileOwner, real x, real y returns boolean
        local unit source = WaveBarrierSource[barrierId]
        local real dx
        local real dy
        local real radius
        if barrierId <= 0 or projectileOwner == null then
            return false
        endif
        if not WaveBarrierUnitAlive(source) then
            return false
        endif
        if not IsPlayerEnemy(projectileOwner, GetOwningPlayer(source)) then
            return false
        endif
        set radius = WaveBarrierRadius[barrierId]
        set dx = x - GetUnitX(source)
        set dy = y - GetUnitY(source)
        return dx*dx + dy*dy <= radius*radius
    endfunction

    private function WaveBarrierFindAt takes player projectileOwner, real x, real y returns integer
        local integer barrierId = WaveBarrierHead
        loop
            exitwhen barrierId == 0
            if WaveBarrierContains(barrierId, projectileOwner, x, y) then
                return barrierId
            endif
            set barrierId = WaveBarrierNext[barrierId]
        endloop
        return 0
    endfunction

    private function WaveBarrierDestroyVisual takes integer barrierId returns nothing
        if barrierId <= 0 then
            return
        endif
        if WaveBarrierVisualFx[barrierId] != 0 then
            call WaveSkillVisualDestroy(WaveBarrierVisualFx[barrierId])
            set WaveBarrierVisualFx[barrierId] = 0
        endif
    endfunction

    private function WaveBarrierDestroy takes integer barrierId returns nothing
        local unit source = WaveBarrierSource[barrierId]
        local integer hid = 0
        if barrierId <= 0 then
            return
        endif
        if source != null and GetUnitTypeId(source) != 0 then
            set hid = GetHandleId(source)
        endif
        call WaveBarrierRemove(barrierId)
        if hid != 0 and WaveBarrierActiveBarrierByUnit.has(hid) and WaveBarrierActiveBarrierByUnit[hid] == barrierId then
            call WaveBarrierActiveBarrierByUnit.remove(hid)
        endif
        if source != null and GetUnitTypeId(source) != 0 then
            call AddUnitAnimationProperties(source, WAVE_HFOO_DEFEND_TAG, false)
        endif
        call WaveBarrierDestroyVisual(barrierId)
        if hid != 0 and WaveBarrierVisualByUnit.has(hid) then
            call WaveBarrierVisualByUnit.remove(hid)
        endif
        set WaveBarrierSource[barrierId] = null
        set WaveBarrierRadius[barrierId] = 0.0
        set WaveBarrierRemaining[barrierId] = 0.0
    endfunction

    private function WaveBarrierTick takes nothing returns nothing
        local integer barrierId = WaveBarrierHead
        local integer nextBarrierId
        local unit source
        loop
            exitwhen barrierId == 0
            set nextBarrierId = WaveBarrierNext[barrierId]
            set source = WaveBarrierSource[barrierId]
            if not WaveBarrierUnitAlive(source) then
                call WaveBarrierDestroy(barrierId)
            else
                set WaveBarrierRemaining[barrierId] = WaveBarrierRemaining[barrierId] - WAVE_HFOO_BARRIER_TICK
                if WaveBarrierRemaining[barrierId] <= 0.0 then
                    call WaveBarrierDestroy(barrierId)
                endif
            endif
            set barrierId = nextBarrierId
            set source = null
        endloop

        if WaveBarrierHead == 0 and WaveBarrierTimerRunning then
            call PauseTimer(WaveBarrierTimer)
            set WaveBarrierTimerRunning = false
        endif
    endfunction

    private function WaveBarrierEnsureTimer takes nothing returns nothing
        if not WaveBarrierTimerRunning then
            set WaveBarrierTimerRunning = true
            call TimerStart(WaveBarrierTimer, WAVE_HFOO_BARRIER_TICK, true, function WaveBarrierTick)
        endif
    endfunction

    private function WaveBarrierStart takes unit source, real radius, real duration returns nothing
        local integer barrierId = WaveBarrierCount + 1
        local integer hid = GetHandleId(source)
        local integer visualFx = 0
        set WaveBarrierCount = barrierId
        set WaveBarrierSource[barrierId] = source
        set WaveBarrierRadius[barrierId] = radius
        set WaveBarrierRemaining[barrierId] = duration
        call WaveBarrierAdd(barrierId)
        set WaveBarrierActiveBarrierByUnit[hid] = barrierId
        call IssueImmediateOrder(source, "stop")
        call SetUnitAnimation(source, "stand")
        call AddUnitAnimationProperties(source, WAVE_HFOO_DEFEND_TAG, true)
        if WaveBarrierVisualByUnit.has(hid) then
            call WaveSkillVisualDestroy(WaveBarrierVisualByUnit[hid])
            call WaveBarrierVisualByUnit.remove(hid)
        endif
        set visualFx = WaveSkillVisualCreateFollowerScaled(source, WaveBarrierVisualModelForSource(source), WaveSkillVisualShieldScaleForRadius(radius))
        set WaveBarrierVisualFx[barrierId] = visualFx
        set WaveBarrierVisualByUnit[hid] = visualFx
        call WaveBarrierEnsureTimer()
    endfunction

    function WaveBarrierSetProjectileInteraction takes integer projectileKind, integer interaction returns nothing
        if projectileKind <= 0 then
            return
        endif
        if interaction < WAVE_BARRIER_INTERACTION_NONE or interaction > WAVE_BARRIER_INTERACTION_RAY then
            return
        endif
        set WaveBarrierProjectileInteractionByKind[projectileKind] = interaction
    endfunction

    function WaveBarrierClearProjectileTrace takes integer projectileId returns nothing
        if projectileId <= 0 then
            return
        endif
        set WaveBarrierProjectileBarrierId[projectileId] = 0
    endfunction

    function WaveBarrierCheckPlayerProjectile takes integer projectileId, player projectileOwner, real x, real y, integer projectileKind returns integer
        local integer currentBarrierId
        local integer foundBarrierId
        if projectileId <= 0 or projectileOwner == null then
            return WAVE_BARRIER_INTERACTION_NONE
        endif

        set currentBarrierId = WaveBarrierProjectileBarrierId[projectileId]
        if currentBarrierId != 0 and WaveBarrierContains(currentBarrierId, projectileOwner, x, y) then
            return WAVE_BARRIER_INTERACTION_NONE
        endif

        set WaveBarrierProjectileBarrierId[projectileId] = 0
        set foundBarrierId = WaveBarrierFindAt(projectileOwner, x, y)
        if foundBarrierId == 0 then
            return WAVE_BARRIER_INTERACTION_NONE
        endif

        set WaveBarrierProjectileBarrierId[projectileId] = foundBarrierId
        if projectileKind <= 0 then
            set projectileKind = WAVE_BARRIER_PROJECTILE_KIND_NORMAL
        endif
        return WaveBarrierProjectileInteractionByKind[projectileKind]
    endfunction

    function WaveBarrierSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        local integer hid
        local integer nextMs
        local boolean isBoss = false
        if not WaveBarrierUnitAlive(source) then
            return false
        endif
        if WaveBarrierIsHfooBoss(source) then
            set isBoss = true
        elseif not WaveBarrierIsHfoo(source) then
            return false
        endif
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) or not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif

        set hid = GetHandleId(source)
        if hid == 0 then
            return false
        endif

        if WaveBarrierActiveBarrierByUnit.has(hid) and WaveBarrierActiveBarrierByUnit[hid] != 0 then
            return true
        endif

        if not WaveBarrierNextCastMs.has(hid) then
            if isBoss then
                set WaveBarrierNextCastMs[hid] = nowMs + WaveBarrierRandomMsRange(WAVE_HFOO_BOSS_INITIAL_DELAY_MIN, WAVE_HFOO_BOSS_INITIAL_DELAY_MAX)
            else
                set WaveBarrierNextCastMs[hid] = nowMs + WaveBarrierRandomMsRange(WAVE_HFOO_INITIAL_DELAY_MIN, WAVE_HFOO_INITIAL_DELAY_MAX)
            endif
            return false
        endif

        set nextMs = WaveBarrierNextCastMs[hid]
        if nowMs < nextMs then
            return false
        endif

        if isBoss then
            call WaveBarrierStart(source, WAVE_HFOO_BOSS_BARRIER_RADIUS, WAVE_HFOO_BOSS_BARRIER_DURATION)
            set WaveBarrierNextCastMs[hid] = nowMs + WaveBarrierRandomMsRange(WAVE_HFOO_BOSS_COOLDOWN_MIN, WAVE_HFOO_BOSS_COOLDOWN_MAX)
            return true
        endif

        call WaveBarrierStart(source, WAVE_HFOO_BARRIER_RADIUS, WAVE_HFOO_BARRIER_DURATION)
        set WaveBarrierNextCastMs[hid] = nowMs + WaveBarrierRandomMsRange(WAVE_HFOO_COOLDOWN_MIN, WAVE_HFOO_COOLDOWN_MAX)
        return true
    endfunction

    private function WaveBarrierCleanupDeadSource takes nothing returns nothing
        local unit u = GetWaveEventUnit()
        local integer hid
        local integer barrierId
        local integer unitType
        if u == null then
            return
        endif
        set unitType = GetUnitTypeId(u)
        if unitType != WAVE_HFOO_UNIT_ID and unitType != WAVE_HFOO_BOSS_UNIT_ID then
            set u = null
            return
        endif
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveBarrierCleanupDeadSource enter " + WaveDeathDebugContextSummary())
        endif
        set hid = GetHandleId(u)
        if hid != 0 and WaveBarrierActiveBarrierByUnit.has(hid) then
            set barrierId = WaveBarrierActiveBarrierByUnit[hid]
            if barrierId != 0 then
                call WaveBarrierDestroy(barrierId)
            endif
        endif
        if hid != 0 and WaveBarrierNextCastMs.has(hid) then
            call WaveBarrierNextCastMs.remove(hid)
        endif
        if hid != 0 and WaveBarrierVisualByUnit.has(hid) then
            call WaveBarrierVisualByUnit.remove(hid)
        endif
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveBarrierCleanupDeadSource exit " + WaveDeathDebugContextSummary())
        endif
        set u = null
    endfunction

    private function Init takes nothing returns nothing
        set WaveBarrierNextCastMs = Table.create()
        set WaveBarrierActiveBarrierByUnit = Table.create()
        set WaveBarrierVisualByUnit = Table.create()
        set WaveBarrierTimer = NewTimer()
        call SetTimerDebugTag(WaveBarrierTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)

        set WaveBarrierProjectileInteractionByKind[WAVE_BARRIER_PROJECTILE_KIND_NORMAL] = WAVE_BARRIER_INTERACTION_BLOCK
        set WaveBarrierProjectileInteractionByKind[WAVE_BARRIER_PROJECTILE_KIND_WIND] = WAVE_BARRIER_INTERACTION_WIND
        set WaveBarrierProjectileInteractionByKind[WAVE_BARRIER_PROJECTILE_KIND_RAY] = WAVE_BARRIER_INTERACTION_RAY

        call RegisterWaveDeathEvent(function WaveBarrierCleanupDeadSource)
    endfunction
endlibrary
