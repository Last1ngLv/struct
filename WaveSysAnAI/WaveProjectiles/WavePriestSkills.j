library WavePriestSkills initializer Init requires Table, TimerUtils, SpellIndex, WaveTest, WaveSkillVisuals, FileIO

    globals
        public constant integer WAVE_HMPR_UNIT_ID = 'hmpr'
        public constant integer WAVE_HMPR_BOSS_UNIT_ID = 'zA07'
        public constant integer WAVE_HMPR_NORMAL_PASSIVE_ID = 'A004'
        public constant integer WAVE_HMPR_BOSS_PASSIVE_ID = 'A005'
        private constant integer WAVE_ANY_BOSS_1 = 'zA01'
        private constant integer WAVE_ANY_BOSS_2 = 'zA02'
        private constant integer WAVE_ANY_BOSS_3 = 'zA03'
        private constant integer WAVE_ANY_BOSS_4 = 'zA04'
        private constant integer WAVE_ANY_BOSS_5 = 'zA05'
        private constant integer WAVE_ANY_BOSS_6 = 'zA06'
        private constant integer WAVE_ANY_BOSS_7 = 'zA07'
        private constant integer WAVE_ANY_BOSS_8 = 'zA08'
        private constant integer WAVE_ANY_BOSS_9 = 'zA09'

        public constant string WAVE_HMPR_AURA_VISUAL_MODEL = "war3mapImported\\Ubershield Starfire x3.mdx"
        public constant string WAVE_HMPR_BOSS_AURA_VISUAL_MODEL = "war3mapImported\\Ubershield Starfire x3.mdx"

        public constant real WAVE_HMPR_AURA_RADIUS = 500.0
        public constant real WAVE_HMPR_AURA_DURATION = 5.0
        public constant real WAVE_HMPR_AURA_SCALE_BONUS = 1.0
        public constant real WAVE_HMPR_INITIAL_DELAY_MIN = 2.00
        public constant real WAVE_HMPR_INITIAL_DELAY_MAX = 4.00
        public constant real WAVE_HMPR_COOLDOWN_MIN = 10.00
        public constant real WAVE_HMPR_COOLDOWN_MAX = 12.00

        public constant real WAVE_HMPR_BOSS_AURA_RADIUS = 950.0
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
        private constant boolean WAVE_HMPR_DEBUG = false
        private constant integer WAVE_HMPR_DEBUG_FILE_BATCH = 32
        private constant string WAVE_HMPR_DEBUG_FILE_FOLDER = "struct"

        private Table WavePriestNextCastMs
        private Table WavePriestActiveAuraByUnit
        private Table WavePriestBaseScaleByUnit
        private Table WavePriestNormalOwnerAuraByUnit
        private Table WavePriestBossOwnerAuraByUnit
        private Table WavePriestMemberUnitByKey
        private Table WavePriestMemberHidByKey
        private timer WavePriestTimer
        private boolean WavePriestTimerRunning = false
        private integer WavePriestHead = 0
        private integer WavePriestCount = 0

        private integer array WavePriestNext
        private integer array WavePriestPrev
        private integer array WavePriestAuraType
        private integer array WavePriestMemberCount
        private unit array WavePriestSource
        private real array WavePriestRadius
        private real array WavePriestRemaining
        private integer array WavePriestVisualId

        private File WavePriestDebugFile = 0
        private integer WavePriestDebugFileSegment = 0
        private integer WavePriestDebugFileLineCount = 0
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
        if unitTypeId == WAVE_ANY_BOSS_1 or unitTypeId == WAVE_ANY_BOSS_2 or unitTypeId == WAVE_ANY_BOSS_3 or unitTypeId == WAVE_ANY_BOSS_4 or unitTypeId == WAVE_ANY_BOSS_5 or unitTypeId == WAVE_ANY_BOSS_6 or unitTypeId == WAVE_ANY_BOSS_7 or unitTypeId == WAVE_ANY_BOSS_8 or unitTypeId == WAVE_ANY_BOSS_9 then
            return false
        endif
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

    private function WavePriestIsNormal takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HMPR_UNIT_ID
    endfunction

    private function WavePriestIsBoss takes unit source returns boolean
        return source != null and GetUnitTypeId(source) == WAVE_HMPR_BOSS_UNIT_ID
    endfunction

    private function WavePriestAuraTypeName takes integer auraType returns string
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            return "BOSS"
        endif
        return "NORMAL"
    endfunction

    private function WavePriestDebugMsg takes string msg returns nothing
        local string line
        if WAVE_HMPR_DEBUG then
            set line = "[WavePriest] " + msg
            call BJDebugMsg("|cffffcc00" + line + "|r")
            if File.enabled then
                if WavePriestDebugFile == 0 then
                    set WavePriestDebugFile = File.open(WAVE_HMPR_DEBUG_FILE_FOLDER, "WavePriestDebug_" + I2S(WavePriestDebugFileSegment), File.Flag.WRITE)
                    set WavePriestDebugFileLineCount = 0
                endif
                call WavePriestDebugFile.write(line)
                set WavePriestDebugFileLineCount = WavePriestDebugFileLineCount + 1
                if WavePriestDebugFileLineCount >= WAVE_HMPR_DEBUG_FILE_BATCH then
                    call WavePriestDebugFile.close()
                    set WavePriestDebugFile = 0
                    set WavePriestDebugFileSegment = WavePriestDebugFileSegment + 1
                    set WavePriestDebugFileLineCount = 0
                endif
            endif
        endif
        set line = null
    endfunction

    private function WavePriestDebugTargetState takes string action, integer auraId, integer auraType, unit target returns nothing
        local integer hid = 0
        local integer normalOwner = 0
        local integer bossOwner = 0
        local integer normalLevel = 0
        local integer bossLevel = 0
        local string unitName = "null"
        if not WAVE_HMPR_DEBUG then
            return
        endif
        if target != null and GetUnitTypeId(target) != 0 then
            set hid = GetHandleId(target)
            set unitName = GetUnitName(target)
            set normalLevel = GetUnitAbilityLevel(target, WAVE_HMPR_NORMAL_PASSIVE_ID)
            set bossLevel = GetUnitAbilityLevel(target, WAVE_HMPR_BOSS_PASSIVE_ID)
            if WavePriestNormalOwnerAuraByUnit.has(hid) then
                set normalOwner = WavePriestNormalOwnerAuraByUnit[hid]
            endif
            if WavePriestBossOwnerAuraByUnit.has(hid) then
                set bossOwner = WavePriestBossOwnerAuraByUnit[hid]
            endif
        endif
        call WavePriestDebugMsg(action + " aura=" + I2S(auraId) + " type=" + WavePriestAuraTypeName(auraType) + " target=" + unitName + " hid=" + I2S(hid) + " nOwner=" + I2S(normalOwner) + " bOwner=" + I2S(bossOwner) + " nLvl=" + I2S(normalLevel) + " bLvl=" + I2S(bossLevel))
    endfunction

    private function WavePriestTargetInAuraRange takes unit source, unit target, real radius returns boolean
        local real dx
        local real dy
        if not WavePriestTargetIsValid(source, target) then
            return false
        endif
        set dx = GetUnitX(target) - GetUnitX(source)
        set dy = GetUnitY(target) - GetUnitY(source)
        return dx*dx + dy*dy <= radius*radius
    endfunction

    private function WavePriestRefreshScale takes unit target returns nothing
        local integer hid
        local real baseScale = 1.0
        local real nextScale
        if target == null or GetUnitTypeId(target) == 0 then
            return
        endif
        set hid = GetHandleId(target)
        if hid != 0 and WavePriestBaseScaleByUnit.real.has(hid) then
            set baseScale = WavePriestBaseScaleByUnit.real[hid]
        endif
        set nextScale = baseScale
        if hid != 0 and WavePriestNormalOwnerAuraByUnit.has(hid) then
            set nextScale = nextScale + WAVE_HMPR_AURA_SCALE_BONUS
        endif
        if hid != 0 and WavePriestBossOwnerAuraByUnit.has(hid) then
            set nextScale = nextScale + WAVE_HMPR_BOSS_AURA_SCALE_BONUS
        endif
        if nextScale < 0.10 then
            set nextScale = 0.10
        endif
        call SetUnitScale(target, nextScale, nextScale, nextScale)
        if hid != 0 and (not WavePriestNormalOwnerAuraByUnit.has(hid)) and (not WavePriestBossOwnerAuraByUnit.has(hid)) and WavePriestBaseScaleByUnit.real.has(hid) then
            call WavePriestBaseScaleByUnit.real.remove(hid)
        endif
    endfunction

    private function WavePriestConfiguredBaseScale takes unit target returns real
        local integer unitTypeId
        if target == null or GetUnitTypeId(target) == 0 then
            return 1.0
        endif
        set unitTypeId = GetUnitTypeId(target)
        // Si algún tipo necesita escala base distinta, se declara acá.
        // En 1.27b no tenemos un native seguro para leer la escala real del object data.
        if unitTypeId == 0 then
            return 1.0
        endif
        return 1.0
    endfunction

    private function WavePriestApplyAuraEffect takes integer auraId, integer auraType, unit target returns boolean
        local integer hid
        if target == null or GetUnitTypeId(target) == 0 then
            return false
        endif
        set hid = GetHandleId(target)
        if hid == 0 then
            return false
        endif
        if not WavePriestBaseScaleByUnit.real.has(hid) then
            set WavePriestBaseScaleByUnit.real[hid] = WavePriestConfiguredBaseScale(target)
        endif
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            if WavePriestBossOwnerAuraByUnit.has(hid) or GetUnitAbilityLevel(target, WAVE_HMPR_BOSS_PASSIVE_ID) > 0 then
                call WavePriestDebugTargetState("APPLY_REJECT", auraId, auraType, target)
                return false
            endif
            set WavePriestBossOwnerAuraByUnit[hid] = auraId
            if GetUnitAbilityLevel(target, WAVE_HMPR_BOSS_PASSIVE_ID) <= 0 then
                call UnitAddAbility(target, WAVE_HMPR_BOSS_PASSIVE_ID)
            endif
        else
            if WavePriestNormalOwnerAuraByUnit.has(hid) or GetUnitAbilityLevel(target, WAVE_HMPR_NORMAL_PASSIVE_ID) > 0 then
                call WavePriestDebugTargetState("APPLY_REJECT", auraId, auraType, target)
                return false
            endif
            set WavePriestNormalOwnerAuraByUnit[hid] = auraId
            if GetUnitAbilityLevel(target, WAVE_HMPR_NORMAL_PASSIVE_ID) <= 0 then
                call UnitAddAbility(target, WAVE_HMPR_NORMAL_PASSIVE_ID)
            endif
        endif
        call WavePriestRefreshScale(target)
        call WavePriestDebugTargetState("APPLY_OK", auraId, auraType, target)
        return true
    endfunction

    private function WavePriestRemoveAuraEffect takes integer auraId, integer auraType, unit target returns nothing
        local integer hid
        if target == null or GetUnitTypeId(target) == 0 then
            return
        endif
        set hid = GetHandleId(target)
        if hid == 0 then
            return
        endif
        call WavePriestDebugTargetState("REMOVE_BEGIN", auraId, auraType, target)
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            if WavePriestBossOwnerAuraByUnit.has(hid) and WavePriestBossOwnerAuraByUnit[hid] == auraId then
                call WavePriestBossOwnerAuraByUnit.remove(hid)
                if GetUnitAbilityLevel(target, WAVE_HMPR_BOSS_PASSIVE_ID) > 0 then
                    call UnitRemoveAbility(target, WAVE_HMPR_BOSS_PASSIVE_ID)
                endif
            endif
        else
            if WavePriestNormalOwnerAuraByUnit.has(hid) and WavePriestNormalOwnerAuraByUnit[hid] == auraId then
                call WavePriestNormalOwnerAuraByUnit.remove(hid)
                if GetUnitAbilityLevel(target, WAVE_HMPR_NORMAL_PASSIVE_ID) > 0 then
                    call UnitRemoveAbility(target, WAVE_HMPR_NORMAL_PASSIVE_ID)
                endif
            endif
        endif
        call WavePriestRefreshScale(target)
        call WavePriestDebugTargetState("REMOVE_END", auraId, auraType, target)
    endfunction

    private function WavePriestVisualModelForType takes integer auraType returns string
        if auraType == WAVE_HMPR_AURA_TYPE_BOSS then
            return WAVE_HMPR_BOSS_AURA_VISUAL_MODEL
        endif
        return WAVE_HMPR_AURA_VISUAL_MODEL
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
            if WavePriestMemberUnitByKey.unit[WavePriestMemberKey(auraId, idx)] == target then
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
            call WavePriestDebugTargetState("ADD_SKIP_EXISTS", auraId, WavePriestAuraType[auraId], target)
            return
        endif
        set count = WavePriestMemberCount[auraId] + 1
        set WavePriestMemberCount[auraId] = count
        set key = WavePriestMemberKey(auraId, count)
        set WavePriestMemberUnitByKey.unit[key] = target
        set WavePriestMemberHidByKey[key] = GetHandleId(target)
        call WavePriestDebugMsg("MEMBER_PUSH aura=" + I2S(auraId) + " type=" + WavePriestAuraTypeName(WavePriestAuraType[auraId]) + " count=" + I2S(WavePriestMemberCount[auraId]) + " target=" + GetUnitName(target))
        if not WavePriestApplyAuraEffect(auraId, WavePriestAuraType[auraId], target) then
            call WavePriestMemberUnitByKey.remove(key)
            if WavePriestMemberHidByKey.has(key) then
                call WavePriestMemberHidByKey.remove(key)
            endif
            set WavePriestMemberCount[auraId] = count - 1
            call WavePriestDebugMsg("MEMBER_POP_ROLLBACK aura=" + I2S(auraId) + " type=" + WavePriestAuraTypeName(WavePriestAuraType[auraId]) + " count=" + I2S(WavePriestMemberCount[auraId]) + " target=" + GetUnitName(target))
            call WavePriestDebugTargetState("ADD_ROLLBACK", auraId, WavePriestAuraType[auraId], target)
        else
            call WavePriestDebugTargetState("ADD_OK", auraId, WavePriestAuraType[auraId], target)
        endif
    endfunction

    private function WavePriestRemoveMemberAt takes integer auraId, integer index returns nothing
        local integer count = WavePriestMemberCount[auraId]
        local integer key = WavePriestMemberKey(auraId, index)
        local integer lastKey = WavePriestMemberKey(auraId, count)
        local unit target = WavePriestMemberUnitByKey.unit[key]
        local unit moved = null
        if index <= 0 or index > count then
            set target = null
            return
        endif
        if target != null and GetUnitTypeId(target) != 0 then
            call WavePriestDebugTargetState("REMOVE_MEMBER", auraId, WavePriestAuraType[auraId], target)
            call WavePriestRemoveAuraEffect(auraId, WavePriestAuraType[auraId], target)
        endif
        if index != count then
            set moved = WavePriestMemberUnitByKey.unit[lastKey]
            set WavePriestMemberUnitByKey.unit[key] = moved
            if WavePriestMemberHidByKey.has(lastKey) then
                set WavePriestMemberHidByKey[key] = WavePriestMemberHidByKey[lastKey]
            elseif WavePriestMemberHidByKey.has(key) then
                call WavePriestMemberHidByKey.remove(key)
            endif
        endif
        call WavePriestMemberUnitByKey.remove(lastKey)
        if WavePriestMemberHidByKey.has(lastKey) then
            call WavePriestMemberHidByKey.remove(lastKey)
        endif
        set WavePriestMemberCount[auraId] = count - 1
        call WavePriestDebugMsg("MEMBER_POP aura=" + I2S(auraId) + " type=" + WavePriestAuraTypeName(WavePriestAuraType[auraId]) + " count=" + I2S(WavePriestMemberCount[auraId]))
        set moved = null
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
        call WavePriestDebugMsg("DESTROY_AURA aura=" + I2S(auraId) + " type=" + WavePriestAuraTypeName(WavePriestAuraType[auraId]) + " members=" + I2S(WavePriestMemberCount[auraId]))
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
        set WavePriestMemberCount[auraId] = 0
        set WavePriestSource[auraId] = null
        set WavePriestRadius[auraId] = 0.0
        set WavePriestRemaining[auraId] = 0.0
        if WAVE_HMPR_DEBUG and WavePriestHead == 0 and WavePriestDebugFile != 0 then
            call WavePriestDebugFile.close()
            set WavePriestDebugFile = 0
            set WavePriestDebugFileSegment = WavePriestDebugFileSegment + 1
            set WavePriestDebugFileLineCount = 0
        endif
    endfunction

    private function WavePriestProcessAura takes integer auraId returns nothing
        local unit source = WavePriestSource[auraId]
        local unit target
        local integer idx
        call WavePriestDebugMsg("TICK aura=" + I2S(auraId) + " type=" + WavePriestAuraTypeName(WavePriestAuraType[auraId]) + " members=" + I2S(WavePriestMemberCount[auraId]) + " remaining=" + R2S(WavePriestRemaining[auraId]))
        if not WavePriestUnitAlive(source) then
            call WavePriestDebugMsg("TICK_DESTROY_DEAD aura=" + I2S(auraId))
            call WavePriestDestroyAura(auraId)
            return
        endif

        set WavePriestRemaining[auraId] = WavePriestRemaining[auraId] - WAVE_HMPR_TICK
        if WavePriestRemaining[auraId] <= 0.0 then
            call WavePriestDebugMsg("TICK_DESTROY_TIMEOUT aura=" + I2S(auraId))
            call WavePriestDestroyAura(auraId)
            return
        endif

        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, GetUnitX(source), GetUnitY(source), WavePriestRadius[auraId], null)
        loop
            set target = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen target == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, target)
            if WavePriestTargetIsValid(source, target) then
                call WavePriestAddMember(auraId, target)
            endif
        endloop

        set idx = WavePriestMemberCount[auraId]
        loop
            exitwhen idx <= 0
            set target = WavePriestMemberUnitByKey.unit[WavePriestMemberKey(auraId, idx)]
            if target == null or GetUnitTypeId(target) == 0 then
                call WavePriestDebugMsg("REMOVE_CAUSE_NULL aura=" + I2S(auraId) + " idx=" + I2S(idx))
                call WavePriestRemoveMemberAt(auraId, idx)
            else
                if not WavePriestTargetInAuraRange(source, target, WavePriestRadius[auraId]) then
                    call WavePriestDebugMsg("REMOVE_CAUSE_RANGE aura=" + I2S(auraId) + " idx=" + I2S(idx) + " target=" + GetUnitName(target))
                    call WavePriestRemoveMemberAt(auraId, idx)
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
        call WavePriestDebugMsg("START_AURA aura=" + I2S(auraId) + " type=" + WavePriestAuraTypeName(auraType) + " source=" + GetUnitName(source))
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
        set WavePriestBaseScaleByUnit = Table.create()
        set WavePriestNormalOwnerAuraByUnit = Table.create()
        set WavePriestBossOwnerAuraByUnit = Table.create()
        set WavePriestMemberUnitByKey = Table.create()
        set WavePriestMemberHidByKey = Table.create()
        set WavePriestTimer = NewTimer()
        call SetTimerDebugTag(WavePriestTimer, TIMER_DEBUG_TAG_UNIT_SKILLS)
        call RegisterWaveDeathEvent(function WavePriestCleanupWaveDeath)
    endfunction
endlibrary
