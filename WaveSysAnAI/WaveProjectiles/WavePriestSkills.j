library WavePriestSkills initializer Init requires Table, TimerUtils, SpellIndex, WaveTest, WaveSkillVisuals

    globals
        public constant integer WAVE_HMPR_UNIT_ID = 'hmpr'
        public constant integer WAVE_HMPR_BOSS_UNIT_ID = 'zA07'
        public constant integer WAVE_HMPR_NORMAL_PASSIVE_ID = 'A004'
        public constant integer WAVE_HMPR_BOSS_PASSIVE_ID = 'A005'

        public constant string WAVE_HMPR_AURA_VISUAL_MODEL = "war3mapImported\\Ubershield Starfire x3.mdx"
        public constant string WAVE_HMPR_BOSS_AURA_VISUAL_MODEL = "war3mapImported\\Ubershield Starfire x3.mdx"

        public constant real WAVE_HMPR_AURA_RADIUS = 300.0
        public constant real WAVE_HMPR_AURA_DURATION = 5.0
        public constant real WAVE_HMPR_AURA_SCALE_BONUS = 1.0
        public constant real WAVE_HMPR_INITIAL_DELAY_MIN = 2.00
        public constant real WAVE_HMPR_INITIAL_DELAY_MAX = 4.00
        public constant real WAVE_HMPR_COOLDOWN_MIN = 10.00
        public constant real WAVE_HMPR_COOLDOWN_MAX = 12.00

        public constant real WAVE_HMPR_BOSS_AURA_RADIUS = 850.0
        public constant real WAVE_HMPR_BOSS_AURA_DURATION = 10.0
        public constant real WAVE_HMPR_BOSS_AURA_SCALE_BONUS = 1.75
        public constant real WAVE_HMPR_BOSS_INITIAL_DELAY_MIN = 3.50
        public constant real WAVE_HMPR_BOSS_INITIAL_DELAY_MAX = 5.50
        public constant real WAVE_HMPR_BOSS_COOLDOWN_MIN = 15.00
        public constant real WAVE_HMPR_BOSS_COOLDOWN_MAX = 18.00

        private constant real WAVE_HMPR_TICK = 0.25
        private constant integer WAVE_HMPR_MEMBER_STRIDE = 1024
        private constant integer WAVE_HMPR_AURA_TYPE_NORMAL = 1
        private constant integer WAVE_HMPR_AURA_TYPE_BOSS = 2

        private Table WavePriestNextCastMs
        private Table WavePriestActiveAuraByUnit
        private Table WavePriestSeenTokenByUnit
        private Table WavePriestNormalCountByUnit
        private Table WavePriestBossCountByUnit
        private Table WavePriestBaseScaleByUnit

        private timer WavePriestTimer
        private boolean WavePriestTimerRunning = false
        private integer WavePriestHead = 0
        private integer WavePriestCount = 0

        private integer array WavePriestNext
        private integer array WavePriestPrev
        private integer array WavePriestAuraType
        private integer array WavePriestSweepToken
        private integer array WavePriestMemberCount
        private unit array WavePriestSource
        private real array WavePriestRadius
        private real array WavePriestRemaining
        private integer array WavePriestVisualId
        private unit array WavePriestMemberUnit
    endglobals

    private function WavePriestMemberKey takes integer auraId, integer index returns integer
        return auraId*WAVE_HMPR_MEMBER_STRIDE + index
    endfunction

    private function WavePriestSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WavePriestRandomMsRange takes real minSec, real maxSec returns integer
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
        return WavePriestSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WavePriestUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WavePriestIsNormal takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HMPR_UNIT_ID
    endfunction

    private function WavePriestIsBoss takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HMPR_BOSS_UNIT_ID
    endfunction

    private function WavePriestRefreshScale takes unit target returns nothing
        local integer hid
        local real baseScale = 1.0
        local integer normalCount = 0
        local integer bossCount = 0
        local real nextScale
        if target == null or GetUnitTypeId(target) == 0 then
            return
        endif
        set hid = GetHandleId(target)
        if hid != 0 and WavePriestBaseScaleByUnit.has(hid) then
            set baseScale = WavePriestBaseScaleByUnit.real[hid]
        endif
        if hid != 0 and WavePriestNormalCountByUnit.has(hid) then
            set normalCount = R2I(WavePriestNormalCountByUnit.real[hid])
        endif
        if hid != 0 and WavePriestBossCountByUnit.has(hid) then
            set bossCount = R2I(WavePriestBossCountByUnit.real[hid])
        endif
        set nextScale = baseScale + I2R(normalCount)*WAVE_HMPR_AURA_SCALE_BONUS + I2R(bossCount)*WAVE_HMPR_BOSS_AURA_SCALE_BONUS
        if nextScale < 0.10 then
            set nextScale = 0.10
        endif
        call SetUnitScale(target, nextScale, nextScale, nextScale)
    endfunction

    private function WavePriestGetAuraCount takes Table countTable, integer hid returns integer
        if hid != 0 and countTable.has(hid) then
            return R2I(countTable.real[hid])
        endif
        return 0
    endfunction

    private function WavePriestSetAuraCount takes Table countTable, integer hid, integer amount returns nothing
        if hid == 0 then
            return
        endif
        if amount <= 0 then
            if countTable.has(hid) then
                call countTable.remove(hid)
            endif
        else
            set countTable.real[hid] = I2R(amount)
        endif
    endfunction

    private function WavePriestApplyAuraEffect takes integer auraType, unit target returns nothing
        local integer hid
        local integer amount
        if target == null or GetUnitTypeId(target) == 0 then
            return
        endif
        set hid = GetHandleId(target)
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            set amount = WavePriestGetAuraCount(WavePriestBossCountByUnit, hid)
            if amount == 0 then
                if not WavePriestBaseScaleByUnit.has(hid) then
                    set WavePriestBaseScaleByUnit.real[hid] = 1.0
                endif
                call UnitAddAbility(target, WAVE_HMPR_BOSS_PASSIVE_ID)
            endif
            call WavePriestSetAuraCount(WavePriestBossCountByUnit, hid, amount + 1)
            call WavePriestRefreshScale(target)
        else
            set amount = WavePriestGetAuraCount(WavePriestNormalCountByUnit, hid)
            if amount == 0 then
                if not WavePriestBaseScaleByUnit.has(hid) then
                    set WavePriestBaseScaleByUnit.real[hid] = 1.0
                endif
                call UnitAddAbility(target, WAVE_HMPR_NORMAL_PASSIVE_ID)
            endif
            call WavePriestSetAuraCount(WavePriestNormalCountByUnit, hid, amount + 1)
            call WavePriestRefreshScale(target)
        endif
    endfunction

    private function WavePriestRemoveAuraEffect takes integer auraType, unit target returns nothing
        local integer hid
        local integer amount
        if target == null or GetUnitTypeId(target) == 0 then
            return
        endif
        set hid = GetHandleId(target)
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            set amount = WavePriestGetAuraCount(WavePriestBossCountByUnit, hid)
            if amount <= 1 then
                call UnitRemoveAbility(target, WAVE_HMPR_BOSS_PASSIVE_ID)
                call WavePriestSetAuraCount(WavePriestBossCountByUnit, hid, 0)
            else
                call WavePriestSetAuraCount(WavePriestBossCountByUnit, hid, amount - 1)
            endif
            call WavePriestRefreshScale(target)
            if WavePriestGetAuraCount(WavePriestNormalCountByUnit, hid) == 0 and WavePriestGetAuraCount(WavePriestBossCountByUnit, hid) == 0 and WavePriestBaseScaleByUnit.has(hid) then
                call WavePriestBaseScaleByUnit.remove(hid)
            endif
        else
            set amount = WavePriestGetAuraCount(WavePriestNormalCountByUnit, hid)
            if amount <= 1 then
                call UnitRemoveAbility(target, WAVE_HMPR_NORMAL_PASSIVE_ID)
                call WavePriestSetAuraCount(WavePriestNormalCountByUnit, hid, 0)
            else
                call WavePriestSetAuraCount(WavePriestNormalCountByUnit, hid, amount - 1)
            endif
            call WavePriestRefreshScale(target)
            if WavePriestGetAuraCount(WavePriestNormalCountByUnit, hid) == 0 and WavePriestGetAuraCount(WavePriestBossCountByUnit, hid) == 0 and WavePriestBaseScaleByUnit.has(hid) then
                call WavePriestBaseScaleByUnit.remove(hid)
            endif
        endif
    endfunction

    private function WavePriestVisualModelForType takes integer auraType returns string
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            return WAVE_HMPR_BOSS_AURA_VISUAL_MODEL
        endif
        return WAVE_HMPR_AURA_VISUAL_MODEL
    endfunction

    private function WavePriestTargetIsValid takes unit source, unit target returns boolean
        local integer sourceWave
        local integer targetWave
        local integer unitTypeId
        if not WavePriestUnitAlive(source) or not WavePriestUnitAlive(target) then
            return false
        endif
        if source == target then
            return false
        endif
        if not IsWaveManagedUnit(target) then
            return false
        endif
        if not IsUnitAlly(target, GetOwningPlayer(source)) then
            return false
        endif
        if IsUnitType(target, UNIT_TYPE_HERO) or IsUnitType(target, UNIT_TYPE_STRUCTURE) then
            return false
        endif
        set unitTypeId = GetUnitTypeId(target)
        if unitTypeId == WAVE_HMPR_UNIT_ID or unitTypeId == WAVE_HMPR_BOSS_UNIT_ID then
            return false
        endif
        set sourceWave = Wave[source]
        set targetWave = Wave[target]
        if sourceWave == 0 or targetWave == 0 or sourceWave != targetWave then
            return false
        endif
        return true
    endfunction

    private function WavePriestAdd takes integer auraId returns nothing
        set WavePriestPrev[auraId] = 0
        set WavePriestNext[auraId] = WavePriestHead
        if WavePriestHead != 0 then
            set WavePriestPrev[WavePriestHead] = auraId
        endif
        set WavePriestHead = auraId
    endfunction

    private function WavePriestRemove takes integer auraId returns nothing
        local integer p = WavePriestPrev[auraId]
        local integer n = WavePriestNext[auraId]
        if p != 0 then
            set WavePriestNext[p] = n
        else
            set WavePriestHead = n
        endif
        if n != 0 then
            set WavePriestPrev[n] = p
        endif
        set WavePriestPrev[auraId] = 0
        set WavePriestNext[auraId] = 0
    endfunction

    private function WavePriestFindMemberIndex takes integer auraId, unit target returns integer
        local integer idx = 1
        loop
            exitwhen idx > WavePriestMemberCount[auraId]
            if WavePriestMemberUnit[WavePriestMemberKey(auraId, idx)] == target then
                return idx
            endif
            set idx = idx + 1
        endloop
        return 0
    endfunction

    private function WavePriestAddMember takes integer auraId, unit target returns nothing
        local integer count
        local integer key
        if target == null or GetUnitTypeId(target) == 0 then
            return
        endif
        if WavePriestFindMemberIndex(auraId, target) != 0 then
            return
        endif
        set count = WavePriestMemberCount[auraId] + 1
        set WavePriestMemberCount[auraId] = count
        set key = WavePriestMemberKey(auraId, count)
        set WavePriestMemberUnit[key] = target
        call WavePriestApplyAuraEffect(WavePriestAuraType[auraId], target)
    endfunction

    private function WavePriestRemoveMemberAt takes integer auraId, integer index returns nothing
        local integer count = WavePriestMemberCount[auraId]
        local integer key = WavePriestMemberKey(auraId, index)
        local integer lastKey = WavePriestMemberKey(auraId, count)
        local unit target = WavePriestMemberUnit[key]
        if index <= 0 or index > count then
            set target = null
            return
        endif
        if target != null and GetUnitTypeId(target) != 0 then
            call WavePriestRemoveAuraEffect(WavePriestAuraType[auraId], target)
        endif
        if index != count then
            set WavePriestMemberUnit[key] = WavePriestMemberUnit[lastKey]
        endif
        set WavePriestMemberUnit[lastKey] = null
        set WavePriestMemberCount[auraId] = count - 1
        set target = null
    endfunction

    private function WavePriestRemoveAllMembers takes integer auraId returns nothing
        loop
            exitwhen WavePriestMemberCount[auraId] <= 0
            call WavePriestRemoveMemberAt(auraId, WavePriestMemberCount[auraId])
        endloop
    endfunction

    private function WavePriestDestroyAura takes integer auraId returns nothing
        local unit source = WavePriestSource[auraId]
        local integer hid = 0
        if auraId <= 0 then
            return
        endif
        if source != null and GetUnitTypeId(source) != 0 then
            set hid = GetHandleId(source)
        endif
        call WavePriestRemove(auraId)
        call WavePriestRemoveAllMembers(auraId)
        if hid != 0 and WavePriestActiveAuraByUnit.has(hid) and WavePriestActiveAuraByUnit[hid] == auraId then
            call WavePriestActiveAuraByUnit.remove(hid)
        endif
        if WavePriestVisualId[auraId] != 0 then
            call WaveSkillVisualDestroy(WavePriestVisualId[auraId])
            set WavePriestVisualId[auraId] = 0
        endif
        set WavePriestAuraType[auraId] = 0
        set WavePriestSweepToken[auraId] = 0
        set WavePriestMemberCount[auraId] = 0
        set WavePriestSource[auraId] = null
        set WavePriestRadius[auraId] = 0.0
        set WavePriestRemaining[auraId] = 0.0
    endfunction

    private function WavePriestProcessAura takes integer auraId returns nothing
        local unit source = WavePriestSource[auraId]
        local unit target
        local integer idx
        local integer hid
        local integer token
        if not WavePriestUnitAlive(source) then
            call WavePriestDestroyAura(auraId)
            return
        endif

        set WavePriestRemaining[auraId] = WavePriestRemaining[auraId] - WAVE_HMPR_TICK
        if WavePriestRemaining[auraId] <= 0.0 then
            call WavePriestDestroyAura(auraId)
            return
        endif

        set token = WavePriestSweepToken[auraId] + 1
        set WavePriestSweepToken[auraId] = token
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, GetUnitX(source), GetUnitY(source), WavePriestRadius[auraId], null)
        loop
            set target = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen target == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, target)
            if WavePriestTargetIsValid(source, target) then
                set hid = GetHandleId(target)
                set WavePriestSeenTokenByUnit.real[hid] = I2R(token)
                call WavePriestAddMember(auraId, target)
            endif
        endloop

        set idx = WavePriestMemberCount[auraId]
        loop
            exitwhen idx <= 0
            set target = WavePriestMemberUnit[WavePriestMemberKey(auraId, idx)]
            if target == null or GetUnitTypeId(target) == 0 then
                call WavePriestRemoveMemberAt(auraId, idx)
            else
                set hid = GetHandleId(target)
                if (not WavePriestSeenTokenByUnit.has(hid)) or R2I(WavePriestSeenTokenByUnit.real[hid]) != token then
                    call WavePriestRemoveMemberAt(auraId, idx)
                elseif WavePriestAuraType[auraId] == WAVE_HMPR_AURA_TYPE_BOSS then
                    if GetUnitAbilityLevel(target, WAVE_HMPR_BOSS_PASSIVE_ID) == 0 then
                        call UnitAddAbility(target, WAVE_HMPR_BOSS_PASSIVE_ID)
                    endif
                else
                    if GetUnitAbilityLevel(target, WAVE_HMPR_NORMAL_PASSIVE_ID) == 0 then
                        call UnitAddAbility(target, WAVE_HMPR_NORMAL_PASSIVE_ID)
                    endif
                endif
            endif
            set idx = idx - 1
        endloop

        set target = null
        set source = null
    endfunction

    private function WavePriestOnTick takes nothing returns nothing
        local integer auraId = WavePriestHead
        local integer nextAuraId
        loop
            exitwhen auraId == 0
            set nextAuraId = WavePriestNext[auraId]
            call WavePriestProcessAura(auraId)
            set auraId = nextAuraId
        endloop
        if WavePriestHead == 0 and WavePriestTimerRunning then
            call PauseTimer(WavePriestTimer)
            set WavePriestTimerRunning = false
        endif
    endfunction

    private function WavePriestEnsureTimer takes nothing returns nothing
        if not WavePriestTimerRunning then
            set WavePriestTimerRunning = true
            call TimerStart(WavePriestTimer, WAVE_HMPR_TICK, true, function WavePriestOnTick)
        endif
    endfunction

    private function WavePriestStartAura takes unit source, integer auraType returns nothing
        local integer auraId = WavePriestCount + 1
        local integer hid = GetHandleId(source)
        set WavePriestCount = auraId
        set WavePriestAuraType[auraId] = auraType
        set WavePriestSweepToken[auraId] = 0
        set WavePriestMemberCount[auraId] = 0
        set WavePriestSource[auraId] = source
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            set WavePriestRadius[auraId] = WAVE_HMPR_BOSS_AURA_RADIUS
            set WavePriestRemaining[auraId] = WAVE_HMPR_BOSS_AURA_DURATION
        else
            set WavePriestRadius[auraId] = WAVE_HMPR_AURA_RADIUS
            set WavePriestRemaining[auraId] = WAVE_HMPR_AURA_DURATION
        endif
        set WavePriestVisualId[auraId] = WaveSkillVisualCreateFollowerScaled(source, WavePriestVisualModelForType(auraType), WaveSkillVisualShieldScaleForRadius(WavePriestRadius[auraId]))
        call WavePriestAdd(auraId)
        set WavePriestActiveAuraByUnit[hid] = auraId
        call IssueImmediateOrder(source, "stop")
        call SetUnitAnimation(source, "spell")
        call WavePriestEnsureTimer()
    endfunction

    private function WavePriestCleanupWaveDeath takes nothing returns nothing
        local unit deadUnit = GetWaveEventUnit()
        local integer hid
        local integer auraId
        local integer unitTypeId
        if deadUnit == null or GetUnitTypeId(deadUnit) == 0 then
            return
        endif
        set unitTypeId = GetUnitTypeId(deadUnit)
        if unitTypeId != WAVE_HMPR_UNIT_ID and unitTypeId != WAVE_HMPR_BOSS_UNIT_ID then
            return
        endif
        set hid = GetHandleId(deadUnit)
        if hid != 0 and WavePriestNextCastMs.has(hid) then
            call WavePriestNextCastMs.remove(hid)
        endif
        if hid != 0 and WavePriestActiveAuraByUnit.has(hid) then
            set auraId = WavePriestActiveAuraByUnit[hid]
            call WavePriestDestroyAura(auraId)
        endif
    endfunction

    function WavePriestSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        local integer hid
        local integer nextMs
        local integer auraType = 0
        if not WavePriestUnitAlive(source) then
            return false
        endif
        if WavePriestIsBoss(source) then
            set auraType = WAVE_HMPR_AURA_TYPE_BOSS
        elseif WavePriestIsNormal(source) then
            set auraType = WAVE_HMPR_AURA_TYPE_NORMAL
        else
            return false
        endif
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) or not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif

        set hid = GetHandleId(source)
        if hid == 0 then
            return false
        endif
        if WavePriestActiveAuraByUnit.has(hid) and WavePriestActiveAuraByUnit[hid] != 0 then
            return true
        endif
        if not WavePriestNextCastMs.has(hid) then
            if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
                set WavePriestNextCastMs[hid] = nowMs + WavePriestRandomMsRange(WAVE_HMPR_BOSS_INITIAL_DELAY_MIN, WAVE_HMPR_BOSS_INITIAL_DELAY_MAX)
            else
                set WavePriestNextCastMs[hid] = nowMs + WavePriestRandomMsRange(WAVE_HMPR_INITIAL_DELAY_MIN, WAVE_HMPR_INITIAL_DELAY_MAX)
            endif
            return false
        endif

        set nextMs = WavePriestNextCastMs[hid]
        if nowMs < nextMs then
            return false
        endif

        call WavePriestStartAura(source, auraType)
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            set WavePriestNextCastMs[hid] = nowMs + WavePriestRandomMsRange(WAVE_HMPR_BOSS_COOLDOWN_MIN, WAVE_HMPR_BOSS_COOLDOWN_MAX)
        else
            set WavePriestNextCastMs[hid] = nowMs + WavePriestRandomMsRange(WAVE_HMPR_COOLDOWN_MIN, WAVE_HMPR_COOLDOWN_MAX)
        endif
        return true
    endfunction

    private function Init takes nothing returns nothing
        set WavePriestNextCastMs = Table.create()
        set WavePriestActiveAuraByUnit = Table.create()
        set WavePriestSeenTokenByUnit = Table.create()
        set WavePriestNormalCountByUnit = Table.create()
        set WavePriestBossCountByUnit = Table.create()
        set WavePriestBaseScaleByUnit = Table.create()
        set WavePriestTimer = NewTimer()
        call SetTimerDebugTag(WavePriestTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)
        call RegisterWaveDeathEvent(function WavePriestCleanupWaveDeath)
    endfunction
endlibrary
