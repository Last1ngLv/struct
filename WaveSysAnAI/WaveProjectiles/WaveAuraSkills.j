library WaveAuraSkills initializer Init requires Table, TimerUtils, WaveTest, TerrainPathability, WaveSkillVisuals

    globals
        public constant integer WAVE_HKNI_UNIT_ID = 'hkni'
        public constant integer WAVE_HKNI_BOSS_UNIT_ID = 'zA04'
        public constant integer WAVE_HKNI_PHASE_ITEM_ID = 'rspl'
        public constant integer WAVE_HKNI_PHASE_BUFF_ID = 'BOwk'
        private constant integer WAVE_AURA_TEMP_INVENTORY_ABILITY_ID = 'AInv'
        public constant string WAVE_HKNI_AURA_VISUAL_MODEL = "war3mapImported\\Ubershield Starfire x3.mdx"
        public constant string WAVE_HKNI_BOSS_AURA_VISUAL_MODEL = "war3mapImported\\Ubershield Starfire x3.mdx"

        public constant real WAVE_HKNI_AURA_RADIUS = 300.0
        public constant real WAVE_HKNI_AURA_DURATION = 5.0
        public constant real WAVE_HKNI_AURA_REFRESH_INTERVAL = 0.25
        public constant real WAVE_HKNI_INITIAL_DELAY_MIN = 2.00
        public constant real WAVE_HKNI_INITIAL_DELAY_MAX = 4.00
        public constant real WAVE_HKNI_COOLDOWN_MIN = 10.00
        public constant real WAVE_HKNI_COOLDOWN_MAX = 12.00

        public constant real WAVE_HKNI_BOSS_AURA_RADIUS = 850.0
        public constant real WAVE_HKNI_BOSS_AURA_DURATION = 10.0
        public constant real WAVE_HKNI_BOSS_INITIAL_DELAY_MIN = 3.50
        public constant real WAVE_HKNI_BOSS_INITIAL_DELAY_MAX = 5.50
        public constant real WAVE_HKNI_BOSS_COOLDOWN_MIN = 15.00
        public constant real WAVE_HKNI_BOSS_COOLDOWN_MAX = 18.00

        // Para el caso de StageExample/wave 1: WaveAuraSetDebug(true), WaveAuraSetDebugWaveFilter(1), WaveAuraSetDebugUnitTypeFilter('hkni')
        private boolean WAVE_AURA_DEBUG_ENABLED = false
        private integer WAVE_AURA_DEBUG_WAVE_FILTER = 0
        private integer WAVE_AURA_DEBUG_UNIT_TYPE_FILTER = 0
        private integer WAVE_AURA_DEBUG_MAX_LOGS_PER_TICK = 40
        private integer WAVE_AURA_DEBUG_MAX_REJECT_LOGS_PER_TICK = 8
        private integer WAVE_AURA_DEBUG_MAX_NULL_REJECT_LOGS_PER_TICK = 4
        private integer WAVE_AURA_DEBUG_MAX_RAW_ENUM_LOGS_PER_TICK = 4
        private boolean WAVE_AURA_DEBUG_LOG_ACTIVE_AURA_EXISTS = false

        private constant integer WAVE_AURA_MEMBER_STRIDE = 256

        private Table WaveAuraNextCastMs
        private Table WaveAuraActiveAuraByUnit
        private Table WaveAuraUnitOwnerAura
        private Table WaveAuraUnitMemberIndex
        private Table WaveAuraMemberUnitByKey
        private Table WaveAuraMemberHidByKey
        private Table WaveAuraSeenTokenByUnit
        private Table WaveAuraVisualByUnit
        private Table WaveAuraUnitInventoryGranted

        private group WaveAuraEnumGroup
        private timer WaveAuraTimer
        private boolean WaveAuraTimerRunning = false
        private integer WaveAuraHead = 0
        private integer WaveAuraCount = 0
        private integer WaveAuraEnumAuraId = 0

        private integer array WaveAuraNext
        private integer array WaveAuraPrev
        private integer array WaveAuraSweepToken
        private integer array WaveAuraMemberCount
        private unit array WaveAuraSource
        private integer array WaveAuraVisualFx
        private real array WaveAuraRadius
        private real array WaveAuraRemaining
        private integer array WaveAuraDebugEnumCount
        private integer array WaveAuraDebugApplyCount
        private integer array WaveAuraDebugRejectCount
        private integer array WaveAuraDebugRemovalCount
        private integer array WaveAuraDebugRejectLogs
        private integer array WaveAuraDebugNullRejectLogs
        private integer array WaveAuraDebugRawEnumLogs
        private integer WaveAuraDebugLogsThisTick = 0
    endglobals

    private function WaveAuraMemberKey takes integer auraId, integer index returns integer
        return auraId*WAVE_AURA_MEMBER_STRIDE + index
    endfunction

    private function WaveAuraClearMemberState takes integer key, integer hid, unit target returns nothing
        if target != null and GetUnitTypeId(target) != 0 and WaveAuraUnitInventoryGranted.has(hid) and WaveAuraUnitInventoryGranted[hid] != 0 then
            call UnitRemoveAbility(target, WAVE_AURA_TEMP_INVENTORY_ABILITY_ID)
        endif
        if WaveAuraUnitInventoryGranted.has(hid) then
            call WaveAuraUnitInventoryGranted.remove(hid)
        endif
        if key != 0 and WaveAuraMemberHidByKey.has(key) then
            call WaveAuraMemberHidByKey.remove(key)
        endif
        call WaveAuraUnitOwnerAura.remove(hid)
        if WaveAuraUnitMemberIndex.has(hid) then
            call WaveAuraUnitMemberIndex.remove(hid)
        endif
    endfunction

    private function WaveAuraSecToMs takes real sec returns integer
        if sec <= 0.0 then
            return 0
        endif
        return R2I(sec*1000.0 + 0.5)
    endfunction

    private function WaveAuraRandomMsRange takes real minSec, real maxSec returns integer
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
        return WaveAuraSecToMs(GetRandomReal(lo, hi))
    endfunction

    private function WaveAuraBoolToInt takes boolean b returns integer
        if b then
            return 1
        endif
        return 0
    endfunction

    private function WaveAuraUnitAlive takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and UnitAlive(u)
    endfunction

    private function WaveAuraUnitWaveId takes unit u returns integer
        if u == null or GetUnitTypeId(u) == 0 then
            return 0
        endif
        return Wave[u]
    endfunction

    private function WaveAuraDebugUnitSummary takes unit u returns string
        local integer waveId
        if u == null then
            return "null"
        endif
        set waveId = WaveAuraUnitWaveId(u)
        return GetUnitName(u) + " ut=" + I2S(GetUnitTypeId(u)) + " hid=" + I2S(GetHandleId(u)) + " ownerPid=" + I2S(GetPlayerId(GetOwningPlayer(u))) + " wave=" + I2S(waveId)
    endfunction

    private function WaveAuraDebugPassesFilter takes unit source returns boolean
        local integer unitTypeId
        local integer waveId
        if not WAVE_AURA_DEBUG_ENABLED then
            return false
        endif
        if source == null or GetUnitTypeId(source) == 0 then
            return false
        endif
        set unitTypeId = GetUnitTypeId(source)
        if WAVE_AURA_DEBUG_UNIT_TYPE_FILTER != 0 and unitTypeId != WAVE_AURA_DEBUG_UNIT_TYPE_FILTER then
            return false
        endif
        if WAVE_AURA_DEBUG_WAVE_FILTER > 0 then
            set waveId = WaveAuraUnitWaveId(source)
            if waveId != WAVE_AURA_DEBUG_WAVE_FILTER then
                return false
            endif
        endif
        return true
    endfunction

    private function WaveAuraDebugLog takes string msg returns nothing
        if not WAVE_AURA_DEBUG_ENABLED then
            return
        endif
        if WaveAuraDebugLogsThisTick >= WAVE_AURA_DEBUG_MAX_LOGS_PER_TICK then
            return
        endif
        set WaveAuraDebugLogsThisTick = WaveAuraDebugLogsThisTick + 1
        call BJDebugMsg("[WaveAura] " + msg)
    endfunction

    private function WaveAuraTargetDebugDetails takes unit source, unit target returns string
        local integer sourceWave = 0
        local integer targetWave = 0
        local integer targetHid = 0
        local integer ownerAuraId = 0
        local boolean waveManaged = false
        if target == null or GetUnitTypeId(target) == 0 then
            return "target=null"
        endif
        set waveManaged = IsWaveManagedUnit(target)
        set sourceWave = WaveAuraUnitWaveId(source)
        set targetWave = WaveAuraUnitWaveId(target)
        set targetHid = GetHandleId(target)
        if targetHid != 0 and WaveAuraUnitOwnerAura.has(targetHid) then
            set ownerAuraId = WaveAuraUnitOwnerAura[targetHid]
        endif
        return "waveManaged=" + I2S(WaveAuraBoolToInt(waveManaged)) + " sourceWave=" + I2S(sourceWave) + " targetWave=" + I2S(targetWave) + " hero=" + I2S(WaveAuraBoolToInt(IsUnitType(target, UNIT_TYPE_HERO))) + " structure=" + I2S(WaveAuraBoolToInt(IsUnitType(target, UNIT_TYPE_STRUCTURE))) + " ownerAuraId=" + I2S(ownerAuraId)
    endfunction

    private function WaveAuraTargetRejectReason takes integer auraId, unit source, unit target returns string
        local integer sourceWave
        local integer targetWave
        local integer targetHid
        if not WaveAuraUnitAlive(source) then
            return "source_dead"
        endif
        if not WaveAuraUnitAlive(target) then
            return "target_dead_or_invalid"
        endif
        if GetUnitAbilityLevel(target, WAVE_HKNI_PHASE_BUFF_ID) > 0 then
            return "phase_buff_active"
        endif
        if not IsWaveManagedUnit(target) then
            return "target_not_wave_managed"
        endif
        set sourceWave = WaveAuraUnitWaveId(source)
        set targetWave = WaveAuraUnitWaveId(target)
        if sourceWave != targetWave then
            return "wave_mismatch srcWave=" + I2S(sourceWave) + " targetWave=" + I2S(targetWave)
        endif
        if IsUnitType(target, UNIT_TYPE_HERO) or IsUnitType(target, UNIT_TYPE_STRUCTURE) then
            return "hero_or_structure"
        endif
        set targetHid = GetHandleId(target)
        if targetHid != 0 and WaveAuraUnitOwnerAura.has(targetHid) and WaveAuraUnitOwnerAura[targetHid] != auraId then
            return "owned_by_other_aura ownerAuraId=" + I2S(WaveAuraUnitOwnerAura[targetHid])
        endif
        return ""
    endfunction

    private function WaveAuraIsHkni takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HKNI_UNIT_ID
    endfunction

    private function WaveAuraIsHkniBoss takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HKNI_BOSS_UNIT_ID
    endfunction

    private function WaveAuraVisualModelForSource takes unit source returns string
        if WaveAuraIsHkniBoss(source) then
            return WAVE_HKNI_BOSS_AURA_VISUAL_MODEL
        endif
        return WAVE_HKNI_AURA_VISUAL_MODEL
    endfunction

    private function WaveAuraIsValidTarget takes integer auraId, unit source, unit target returns boolean
        return WaveAuraTargetRejectReason(auraId, source, target) == ""
    endfunction

    private function WaveAuraAdd takes integer auraId returns nothing
        set WaveAuraPrev[auraId] = 0
        set WaveAuraNext[auraId] = WaveAuraHead
        if WaveAuraHead != 0 then
            set WaveAuraPrev[WaveAuraHead] = auraId
        endif
        set WaveAuraHead = auraId
    endfunction

    private function WaveAuraRemove takes integer auraId returns nothing
        local integer p = WaveAuraPrev[auraId]
        local integer n = WaveAuraNext[auraId]
        if p != 0 then
            set WaveAuraNext[p] = n
        else
            set WaveAuraHead = n
        endif
        if n != 0 then
            set WaveAuraPrev[n] = p
        endif
        set WaveAuraPrev[auraId] = 0
        set WaveAuraNext[auraId] = 0
    endfunction

    private function WaveAuraRemoveMember takes integer auraId, integer hid, unit target, string reason returns nothing
        local integer index
        local integer last
        local integer key
        local integer lastKey
        local unit moved
        local unit source = WaveAuraSource[auraId]
        local integer inventoryGranted = 0
        if hid == 0 or not WaveAuraUnitOwnerAura.has(hid) or WaveAuraUnitOwnerAura[hid] != auraId then
            return
        endif
        set index = WaveAuraUnitMemberIndex[hid]
        set last = WaveAuraMemberCount[auraId]
        if index <= 0 or index > last then
            set key = WaveAuraMemberKey(auraId, index)
            call WaveAuraClearMemberState(key, hid, target)
            return
        endif
        if target != null and GetUnitTypeId(target) != 0 then
            if WaveAuraDebugPassesFilter(source) then
                call WaveAuraDebugLog("removeMember auraId=" + I2S(auraId) + " reason=" + reason + " source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " inventoryAbility=" + I2S(WAVE_AURA_TEMP_INVENTORY_ABILITY_ID) + " item=" + I2S(WAVE_HKNI_PHASE_ITEM_ID) + " buff=" + I2S(WAVE_HKNI_PHASE_BUFF_ID))
            endif
            call UnitRemoveBuffBJ(WAVE_HKNI_PHASE_BUFF_ID, target)
            set key = WaveAuraMemberKey(auraId, index)
            call WaveAuraClearMemberState(key, hid, target)
            set WaveAuraDebugRemovalCount[auraId] = WaveAuraDebugRemovalCount[auraId] + 1
        endif
        set key = WaveAuraMemberKey(auraId, index)
        set lastKey = WaveAuraMemberKey(auraId, last)
        if index != last then
            set moved = WaveAuraMemberUnitByKey.unit[lastKey]
            set WaveAuraMemberUnitByKey.unit[key] = moved
            if moved != null and GetUnitTypeId(moved) != 0 then
                set WaveAuraMemberHidByKey[key] = GetHandleId(moved)
                set WaveAuraUnitMemberIndex[GetHandleId(moved)] = index
            endif
        endif
        call WaveAuraMemberUnitByKey.remove(lastKey)
        call WaveAuraMemberHidByKey.remove(lastKey)
        call WaveAuraUnitOwnerAura.remove(hid)
        if WaveAuraUnitMemberIndex.has(hid) then
            call WaveAuraUnitMemberIndex.remove(hid)
        endif
        set WaveAuraMemberCount[auraId] = last - 1
        set moved = null
    endfunction

    private function WaveAuraRemoveAllMembers takes integer auraId returns nothing
        local integer last
        local integer key
        local unit target
        loop
            set last = WaveAuraMemberCount[auraId]
            exitwhen last <= 0
            set key = WaveAuraMemberKey(auraId, last)
            set target = WaveAuraMemberUnitByKey.unit[key]
        if target != null and GetUnitTypeId(target) != 0 then
            call WaveAuraRemoveMember(auraId, GetHandleId(target), target, "destroy_cleanup")
        else
            if WaveAuraMemberHidByKey.has(key) then
                call WaveAuraMemberHidByKey.remove(key)
            endif
            call WaveAuraMemberUnitByKey.remove(key)
            set WaveAuraMemberCount[auraId] = last - 1
            endif
            set target = null
        endloop
    endfunction

    private function WaveAuraDestroyVisual takes integer auraId returns nothing
        if auraId <= 0 then
            return
        endif
        if WaveAuraVisualFx[auraId] != 0 then
            call WaveSkillVisualDestroy(WaveAuraVisualFx[auraId])
            set WaveAuraVisualFx[auraId] = 0
        endif
    endfunction

    private function WaveAuraDestroy takes integer auraId, string reason returns nothing
        local unit source = WaveAuraSource[auraId]
        local integer hid = 0
        if source != null and GetUnitTypeId(source) != 0 then
            set hid = GetHandleId(source)
        endif
        if WaveAuraDebugPassesFilter(source) then
            call WaveAuraDebugLog("destroy auraId=" + I2S(auraId) + " reason=" + reason + " source=" + WaveAuraDebugUnitSummary(source) + " remainingSec=" + R2S(WaveAuraRemaining[auraId]) + " members=" + I2S(WaveAuraMemberCount[auraId]) + " sweepToken=" + I2S(WaveAuraSweepToken[auraId]))
        endif
        call WaveAuraRemoveAllMembers(auraId)
        call WaveAuraRemove(auraId)
        if hid != 0 and WaveAuraActiveAuraByUnit.has(hid) and WaveAuraActiveAuraByUnit[hid] == auraId then
            call WaveAuraActiveAuraByUnit.remove(hid)
        endif
        call WaveAuraDestroyVisual(auraId)
        if hid != 0 and WaveAuraVisualByUnit.has(hid) then
            call WaveAuraVisualByUnit.remove(hid)
        endif
        set WaveAuraSweepToken[auraId] = 0
        set WaveAuraMemberCount[auraId] = 0
        set WaveAuraSource[auraId] = null
        set WaveAuraRadius[auraId] = 0.0
        set WaveAuraRemaining[auraId] = 0.0
    endfunction

    private function WaveAuraApplyTarget takes integer auraId, unit target returns nothing
        local integer hid = GetHandleId(target)
        local integer index
        local boolean addedInventory = false
        local item rune = null
        if hid == 0 then
            return
        endif
        if not WaveAuraUnitOwnerAura.has(hid) then
            if WaveAuraMemberCount[auraId] >= (WAVE_AURA_MEMBER_STRIDE - 1) then
                return
            endif
            set addedInventory = UnitAddAbility(target, WAVE_AURA_TEMP_INVENTORY_ABILITY_ID)
            set rune = UnitAddItemById(target, WAVE_HKNI_PHASE_ITEM_ID)
            if rune == null then
                if addedInventory then
                    call UnitRemoveAbility(target, WAVE_AURA_TEMP_INVENTORY_ABILITY_ID)
                endif
                return
            endif
            if WaveAuraDebugPassesFilter(WaveAuraSource[auraId]) then
                call WaveAuraDebugLog("applyTarget auraId=" + I2S(auraId) + " action=grantRune source=" + WaveAuraDebugUnitSummary(WaveAuraSource[auraId]) + " target=" + WaveAuraDebugUnitSummary(target) + " item=" + I2S(WAVE_HKNI_PHASE_ITEM_ID) + " inventoryAbility=" + I2S(WAVE_AURA_TEMP_INVENTORY_ABILITY_ID) + " addedInventory=" + I2S(WaveAuraBoolToInt(addedInventory)))
            endif
            call RemoveItem(rune)
            set rune = null
            if addedInventory then
                set WaveAuraUnitInventoryGranted[hid] = 1
            endif
            set index = WaveAuraMemberCount[auraId] + 1
            set WaveAuraMemberCount[auraId] = index
            set WaveAuraMemberUnitByKey.unit[WaveAuraMemberKey(auraId, index)] = target
            set WaveAuraMemberHidByKey[WaveAuraMemberKey(auraId, index)] = hid
            set WaveAuraUnitOwnerAura[hid] = auraId
            set WaveAuraUnitMemberIndex[hid] = index
        endif
        set WaveAuraSeenTokenByUnit[hid] = WaveAuraSweepToken[auraId]
        set rune = null
    endfunction

    private function WaveAuraEnum takes nothing returns nothing
        local integer auraId = WaveAuraEnumAuraId
        local unit source = WaveAuraSource[auraId]
        local unit target = GetFilterUnit()
        local string rejectReason
        set WaveAuraDebugEnumCount[auraId] = WaveAuraDebugEnumCount[auraId] + 1
        if WaveAuraDebugPassesFilter(source) and WaveAuraDebugRawEnumLogs[auraId] < WAVE_AURA_DEBUG_MAX_RAW_ENUM_LOGS_PER_TICK then
            call WaveAuraDebugLog("enumRaw auraId=" + I2S(auraId) + " source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " targetTypeId=" + I2S(GetUnitTypeId(target)) + " targetHid=" + I2S(GetHandleId(target)))
            set WaveAuraDebugRawEnumLogs[auraId] = WaveAuraDebugRawEnumLogs[auraId] + 1
        endif
        set rejectReason = WaveAuraTargetRejectReason(auraId, source, target)
        if rejectReason == "" then
            set WaveAuraDebugApplyCount[auraId] = WaveAuraDebugApplyCount[auraId] + 1
            call WaveAuraApplyTarget(auraId, target)
        else
            set WaveAuraDebugRejectCount[auraId] = WaveAuraDebugRejectCount[auraId] + 1
            if WaveAuraDebugPassesFilter(source) then
                if target == null or GetUnitTypeId(target) == 0 then
                    if WaveAuraDebugNullRejectLogs[auraId] < WAVE_AURA_DEBUG_MAX_NULL_REJECT_LOGS_PER_TICK then
                        call WaveAuraDebugLog("enumRejectNull auraId=" + I2S(auraId) + " source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " reason=" + rejectReason)
                        set WaveAuraDebugNullRejectLogs[auraId] = WaveAuraDebugNullRejectLogs[auraId] + 1
                    endif
                elseif WaveAuraDebugRejectLogs[auraId] < WAVE_AURA_DEBUG_MAX_REJECT_LOGS_PER_TICK then
                    call WaveAuraDebugLog("enumReject auraId=" + I2S(auraId) + " source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " reason=" + rejectReason + " details=" + WaveAuraTargetDebugDetails(source, target))
                    set WaveAuraDebugRejectLogs[auraId] = WaveAuraDebugRejectLogs[auraId] + 1
                endif
            endif
        endif
        set source = null
        set target = null
    endfunction

    private function WaveAuraSweepMembers takes integer auraId returns nothing
        local integer index = WaveAuraMemberCount[auraId]
        local integer key
        local unit target
        local integer hid
        loop
            exitwhen index <= 0
            set key = WaveAuraMemberKey(auraId, index)
            set target = WaveAuraMemberUnitByKey.unit[key]
            if target == null or GetUnitTypeId(target) == 0 then
                call WaveAuraMemberUnitByKey.remove(key)
                set WaveAuraMemberCount[auraId] = WaveAuraMemberCount[auraId] - 1
            else
                set hid = GetHandleId(target)
                if not WaveAuraUnitAlive(target) then
                    call WaveAuraRemoveMember(auraId, hid, target, "sweep_lost_contact")
                endif
            endif
            set index = index - 1
            set target = null
        endloop
    endfunction

    private function WaveAuraTick takes nothing returns nothing
        local integer auraId = WaveAuraHead
        local integer nextAuraId
        local unit source
        set WaveAuraDebugLogsThisTick = 0
        loop
            exitwhen auraId == 0
            set nextAuraId = WaveAuraNext[auraId]
            set source = WaveAuraSource[auraId]
            if not WaveAuraUnitAlive(source) then
                call WaveAuraDestroy(auraId, "source_dead")
            else
                set WaveAuraDebugEnumCount[auraId] = 0
                set WaveAuraDebugApplyCount[auraId] = 0
                set WaveAuraDebugRejectCount[auraId] = 0
                set WaveAuraDebugRemovalCount[auraId] = 0
                set WaveAuraDebugRejectLogs[auraId] = 0
                set WaveAuraDebugNullRejectLogs[auraId] = 0
                set WaveAuraDebugRawEnumLogs[auraId] = 0
                set WaveAuraRemaining[auraId] = WaveAuraRemaining[auraId] - WAVE_HKNI_AURA_REFRESH_INTERVAL
                if WaveAuraRemaining[auraId] <= 0.0 then
                    if WaveAuraDebugPassesFilter(source) then
                        call WaveAuraDebugLog("tickExpire auraId=" + I2S(auraId) + " source=" + WaveAuraDebugUnitSummary(source) + " remainingSec=" + R2S(WaveAuraRemaining[auraId]))
                    endif
                    call WaveAuraDestroy(auraId, "duration_expired")
                else
                    set WaveAuraSweepToken[auraId] = WaveAuraSweepToken[auraId] + 1
                    if WaveAuraSweepToken[auraId] <= 0 then
                        set WaveAuraSweepToken[auraId] = 1
                    endif
                    set WaveAuraEnumAuraId = auraId
                    call GroupEnumUnitsInRange(WaveAuraEnumGroup, GetUnitX(source), GetUnitY(source), WaveAuraRadius[auraId], function WaveAuraEnum)
                    call GroupClear(WaveAuraEnumGroup)
                    call WaveAuraSweepMembers(auraId)
                    if WaveAuraDebugPassesFilter(source) then
                        call WaveAuraDebugLog("tick auraId=" + I2S(auraId) + " source=" + WaveAuraDebugUnitSummary(source) + " remainingSec=" + R2S(WaveAuraRemaining[auraId]) + " radius=" + R2S(WaveAuraRadius[auraId]) + " sweepToken=" + I2S(WaveAuraSweepToken[auraId]) + " enum=" + I2S(WaveAuraDebugEnumCount[auraId]) + " applied=" + I2S(WaveAuraDebugApplyCount[auraId]) + " rejected=" + I2S(WaveAuraDebugRejectCount[auraId]) + " removed=" + I2S(WaveAuraDebugRemovalCount[auraId]) + " members=" + I2S(WaveAuraMemberCount[auraId]))
                    endif
                endif
            endif
            set auraId = nextAuraId
            set source = null
        endloop

        if WaveAuraHead == 0 and WaveAuraTimerRunning then
            call PauseTimer(WaveAuraTimer)
            set WaveAuraTimerRunning = false
        endif
    endfunction

    private function WaveAuraEnsureTimer takes nothing returns nothing
        if not WaveAuraTimerRunning then
            set WaveAuraTimerRunning = true
            call TimerStart(WaveAuraTimer, WAVE_HKNI_AURA_REFRESH_INTERVAL, true, function WaveAuraTick)
        endif
    endfunction

    private function WaveAuraStart takes unit source, real radius, real duration returns nothing
        local integer auraId = WaveAuraCount + 1
        local integer hid = GetHandleId(source)
        local integer visualFx = 0
        set WaveAuraCount = auraId
        set WaveAuraSource[auraId] = source
        set WaveAuraRadius[auraId] = radius
        set WaveAuraRemaining[auraId] = duration
        set WaveAuraSweepToken[auraId] = 0
        set WaveAuraMemberCount[auraId] = 0
        set WaveAuraDebugEnumCount[auraId] = 0
        set WaveAuraDebugApplyCount[auraId] = 0
        set WaveAuraDebugRejectCount[auraId] = 0
        set WaveAuraDebugRemovalCount[auraId] = 0
        set WaveAuraDebugRejectLogs[auraId] = 0
        set WaveAuraDebugNullRejectLogs[auraId] = 0
        set WaveAuraDebugRawEnumLogs[auraId] = 0
        call WaveAuraAdd(auraId)
        set WaveAuraActiveAuraByUnit[hid] = auraId
        if WaveAuraDebugPassesFilter(source) then
            call WaveAuraDebugLog("start auraId=" + I2S(auraId) + " source=" + WaveAuraDebugUnitSummary(source) + " radius=" + R2S(radius) + " durationSec=" + R2S(duration) + " visual=" + WaveAuraVisualModelForSource(source) + " hid=" + I2S(hid))
        endif
        call SetUnitAnimation(source, "attack")
        if WaveAuraVisualByUnit.has(hid) then
            call WaveSkillVisualDestroy(WaveAuraVisualByUnit[hid])
            call WaveAuraVisualByUnit.remove(hid)
        endif
        set visualFx = WaveSkillVisualCreateFollowerScaled(source, WaveAuraVisualModelForSource(source), WaveSkillVisualShieldScaleForRadius(radius))
        set WaveAuraVisualFx[auraId] = visualFx
        set WaveAuraVisualByUnit[hid] = visualFx
        call WaveAuraEnsureTimer()
    endfunction

    private function WaveAuraCleanupDeadSource takes nothing returns nothing
        local unit u = GetWaveEventUnit()
        local integer hid
        local integer auraId
        local integer unitType
        if u == null then
            return
        endif
        set unitType = GetUnitTypeId(u)
        if unitType != WAVE_HKNI_UNIT_ID and unitType != WAVE_HKNI_BOSS_UNIT_ID then
            set u = null
            return
        endif
        if WaveAuraDebugPassesFilter(u) then
            call WaveAuraDebugLog("cleanupDeadSource enter source=" + WaveAuraDebugUnitSummary(u) + " waveDeath=" + WaveDeathDebugContextSummary())
        endif
        set hid = GetHandleId(u)
        if hid != 0 and WaveAuraActiveAuraByUnit.has(hid) then
            set auraId = WaveAuraActiveAuraByUnit[hid]
            if auraId != 0 then
                call WaveAuraDestroy(auraId, "wave_death_event")
            endif
        endif
        if hid != 0 and WaveAuraNextCastMs.has(hid) then
            call WaveAuraNextCastMs.remove(hid)
        endif
        if hid != 0 and WaveAuraVisualByUnit.has(hid) then
            call WaveAuraVisualByUnit.remove(hid)
        endif
        if WaveAuraDebugPassesFilter(u) then
            call WaveAuraDebugLog("cleanupDeadSource exit source=" + WaveAuraDebugUnitSummary(u) + " waveDeath=" + WaveDeathDebugContextSummary())
        endif
        set u = null
    endfunction

    function WaveAuraSkillsTryExecute takes unit source, unit target, integer nowMs returns boolean
        local integer hid
        local integer nextMs
        local boolean isBoss = false
        local boolean debugOn
        if not WaveAuraUnitAlive(source) then
            if WaveAuraDebugPassesFilter(source) then
                call WaveAuraDebugLog("tryExecute reject reason=source_dead source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " nowMs=" + I2S(nowMs))
            endif
            return false
        endif
        set debugOn = WaveAuraDebugPassesFilter(source)
        if WaveAuraIsHkniBoss(source) then
            set isBoss = true
        elseif not WaveAuraIsHkni(source) then
            if debugOn then
                call WaveAuraDebugLog("tryExecute reject reason=source_type_mismatch source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " nowMs=" + I2S(nowMs))
            endif
            return false
        endif
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) or not IsUnitType(target, UNIT_TYPE_HERO) then
            if debugOn then
                call WaveAuraDebugLog("tryExecute reject reason=target_invalid_or_not_hero source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " nowMs=" + I2S(nowMs))
            endif
            return false
        endif

        set hid = GetHandleId(source)
        if hid == 0 then
            if debugOn then
                call WaveAuraDebugLog("tryExecute reject reason=source_handle_zero source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " nowMs=" + I2S(nowMs))
            endif
            return false
        endif

        if WaveAuraActiveAuraByUnit.has(hid) and WaveAuraActiveAuraByUnit[hid] != 0 then
            if debugOn and WAVE_AURA_DEBUG_LOG_ACTIVE_AURA_EXISTS then
                call WaveAuraDebugLog("tryExecute reject reason=active_aura_exists source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " auraId=" + I2S(WaveAuraActiveAuraByUnit[hid]) + " nowMs=" + I2S(nowMs))
            endif
            return false
        endif

        if not WaveAuraNextCastMs.has(hid) then
            if isBoss then
                set WaveAuraNextCastMs[hid] = nowMs + WaveAuraRandomMsRange(WAVE_HKNI_BOSS_INITIAL_DELAY_MIN, WAVE_HKNI_BOSS_INITIAL_DELAY_MAX)
            else
                set WaveAuraNextCastMs[hid] = nowMs + WaveAuraRandomMsRange(WAVE_HKNI_INITIAL_DELAY_MIN, WAVE_HKNI_INITIAL_DELAY_MAX)
            endif
            if debugOn then
                call WaveAuraDebugLog("tryExecute arm reason=seed_initial_delay source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " nextMs=" + I2S(WaveAuraNextCastMs[hid]) + " nowMs=" + I2S(nowMs) + " boss=" + I2S(WaveAuraBoolToInt(isBoss)))
            endif
            return false
        endif

        set nextMs = WaveAuraNextCastMs[hid]
        if nowMs < nextMs then
            if debugOn then
                call WaveAuraDebugLog("tryExecute reject reason=waiting_cooldown source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " nowMs=" + I2S(nowMs) + " nextMs=" + I2S(nextMs) + " waitMs=" + I2S(nextMs - nowMs) + " boss=" + I2S(WaveAuraBoolToInt(isBoss)))
            endif
            return false
        endif

        if isBoss then
            call WaveAuraStart(source, WAVE_HKNI_BOSS_AURA_RADIUS, WAVE_HKNI_BOSS_AURA_DURATION)
            set WaveAuraNextCastMs[hid] = nowMs + WaveAuraRandomMsRange(WAVE_HKNI_BOSS_COOLDOWN_MIN, WAVE_HKNI_BOSS_COOLDOWN_MAX)
            if debugOn then
                call WaveAuraDebugLog("tryExecute start reason=ready source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " auraId=" + I2S(WaveAuraActiveAuraByUnit[hid]) + " radius=" + R2S(WAVE_HKNI_BOSS_AURA_RADIUS) + " durationSec=" + R2S(WAVE_HKNI_BOSS_AURA_DURATION) + " nextMs=" + I2S(WaveAuraNextCastMs[hid]) + " nowMs=" + I2S(nowMs) + " boss=1")
            endif
            return true
        endif

        call WaveAuraStart(source, WAVE_HKNI_AURA_RADIUS, WAVE_HKNI_AURA_DURATION)
        set WaveAuraNextCastMs[hid] = nowMs + WaveAuraRandomMsRange(WAVE_HKNI_COOLDOWN_MIN, WAVE_HKNI_COOLDOWN_MAX)
        if debugOn then
            call WaveAuraDebugLog("tryExecute start reason=ready source=" + WaveAuraDebugUnitSummary(source) + " target=" + WaveAuraDebugUnitSummary(target) + " auraId=" + I2S(WaveAuraActiveAuraByUnit[hid]) + " radius=" + R2S(WAVE_HKNI_AURA_RADIUS) + " durationSec=" + R2S(WAVE_HKNI_AURA_DURATION) + " nextMs=" + I2S(WaveAuraNextCastMs[hid]) + " nowMs=" + I2S(nowMs) + " boss=0")
        endif
        return true
    endfunction

    function WaveAuraSetDebug takes boolean enabled returns nothing
        set WAVE_AURA_DEBUG_ENABLED = enabled
        set WaveAuraDebugLogsThisTick = 0
    endfunction

    function WaveAuraSetDebugWaveFilter takes integer waveId returns nothing
        if waveId < 0 then
            set waveId = 0
        endif
        set WAVE_AURA_DEBUG_WAVE_FILTER = waveId
        set WaveAuraDebugLogsThisTick = 0
    endfunction

    function WaveAuraSetDebugUnitTypeFilter takes integer unitTypeId returns nothing
        if unitTypeId < 0 then
            set unitTypeId = 0
        endif
        set WAVE_AURA_DEBUG_UNIT_TYPE_FILTER = unitTypeId
        set WaveAuraDebugLogsThisTick = 0
    endfunction

    function WaveAuraSetDebugMaxLogsPerTick takes integer maxLogs returns nothing
        if maxLogs < 1 then
            set maxLogs = 1
        elseif maxLogs > 200 then
            set maxLogs = 200
        endif
        set WAVE_AURA_DEBUG_MAX_LOGS_PER_TICK = maxLogs
        set WaveAuraDebugLogsThisTick = 0
    endfunction

    function WaveAuraSetDebugMaxRejectLogsPerTick takes integer maxLogs returns nothing
        if maxLogs < 0 then
            set maxLogs = 0
        elseif maxLogs > 64 then
            set maxLogs = 64
        endif
        set WAVE_AURA_DEBUG_MAX_REJECT_LOGS_PER_TICK = maxLogs
        set WaveAuraDebugLogsThisTick = 0
    endfunction

    private function Init takes nothing returns nothing
        set WaveAuraNextCastMs = Table.create()
        set WaveAuraActiveAuraByUnit = Table.create()
        set WaveAuraUnitOwnerAura = Table.create()
        set WaveAuraUnitMemberIndex = Table.create()
        set WaveAuraMemberUnitByKey = Table.create()
        set WaveAuraMemberHidByKey = Table.create()
        set WaveAuraSeenTokenByUnit = Table.create()
        set WaveAuraVisualByUnit = Table.create()
        set WaveAuraUnitInventoryGranted = Table.create()
        set WaveAuraEnumGroup = CreateGroup()
        set WaveAuraTimer = NewTimer()
        call SetTimerDebugTag(WaveAuraTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)

        call RegisterWaveDeathEvent(function WaveAuraCleanupDeadSource)
    endfunction
endlibrary
