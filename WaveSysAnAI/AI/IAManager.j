library IAManager initializer Init requires Table, TimerUtils, WaveTest, TenderSystem, AIProfiles, AIConfig, TerrainPathability, WaveBarrierSkills, WaveAuraSkills, WaveRangedSkills, WaveSiegeSkills, WaveMortarSkills, WavePriestSkills, WaveTrapSkills, WaveSiegeZoneSkills, WaveWaveformSkills, TextTagDebug, AIManagerUtils

    globals
        private constant integer AI_TICK_MS = 500
        private constant integer AI_BUDGET_PER_TICK = 48
        private constant integer AI_IDLE_TICK_MS = 333
        private constant integer AI_MIN_TICK_MS = 150
        private constant integer AI_MAX_TICK_MS = 1000
        private constant integer AI_MIN_BUDGET_PER_TICK = 16
        private constant integer AI_MAX_BUDGET_PER_TICK = 192
        private constant integer AI_CAST_FAIL_BACKOFF_MS = 500
        private constant integer AI_ORDER_NONE = 0
        private constant integer AI_ORDER_ATTACK = 1
        private constant integer AI_ORDER_MOVE = 2
        private constant integer AI_TELEPORT_BACK_ATTEMPTS = 8
        private constant integer AI_TELEPORT_FALLBACK_ATTEMPTS = 12
        private constant integer AI_TELEPORT_MIN_COOLDOWN_MS = 250
        private constant integer AI_TELEPORT_MIN_ENTRY_DELAY_MS = 0
        private constant real AI_TELEPORT_MIN_OFFSET = 32.0
        private constant real AI_TELEPORT_FRONTBACK_DOT_THRESHOLD = 0.35
        private constant string AI_TELEPORT_ATTACH_POINT = "origin"
        private constant integer AI_BOSS_REINFORCEMENT_WINDUP_MS = 1500
        private constant integer AI_BOSS_REINFORCEMENT_INITIAL_MIN_MS = 15000
        private constant integer AI_BOSS_REINFORCEMENT_INITIAL_MAX_MS = 20000
        private constant integer AI_BOSS_REINFORCEMENT_COOLDOWN_MIN_MS = 50000
        private constant integer AI_BOSS_REINFORCEMENT_COOLDOWN_MAX_MS = 60000
        private constant string AI_BOSS_REINFORCEMENT_START_FX = "war3mapImported\\Bondage Blue SD.mdx"
        private constant string AI_BOSS_REINFORCEMENT_APPLY_FX = "Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl"
        private constant string AI_BOSS_REINFORCEMENT_ATTACH_POINT = "origin"
        private constant string AI_BOSS_REINFORCEMENT_TEXT = "invocando wave"
        private constant real AI_BOSS_REINFORCEMENT_TEXT_SIZE = 0.020
        private constant real AI_BOSS_REINFORCEMENT_TEXT_Z_OFFSET = 120.0
        private constant real AI_BOSS_REINFORCEMENT_TEXT_RISE_SPEED = 0.0125
        private constant real AI_BOSS_REINFORCEMENT_TEXT_LIFESPAN = 3.00
        private constant real AI_BOSS_REINFORCEMENT_TEXT_FADEPOINT = 2.25

        private Table AIUnitByIndex
        private Table AIIndexByUnit

        private Table AIUnitWaveId
        private Table AIUnitProfileId
        private Table AIUnitLaneId
        private Table AIUnitBehaviorFlags
        private Table AIUnitThreatWeight

        private Table AIUnitTarget
        private Table AIUnitNextRetargetMs
        private Table AIUnitNextOrderMs
        private Table AIUnitNextAbilityMs
        private Table AIUnitChannelLockUntilMs
        private Table AIUnitNextTeleportMs
        private Table AIUnitTeleportReadyMs
        private Table AIUnitNextDebugMs
        private Table AIUnitCooldownTables
        private Table AIUnitLastOrderType
        private Table AIUnitLastOrderTarget
        private Table AIUnitLastOrderX
        private Table AIUnitLastOrderY
        private Table AIBossReinforcementNextMs
        private Table AIBossReinforcementCastByUnit

        private Table AIWaveIsActive
        private Table AIWaveIsPaused
        private Table AIWaveUnitCount
        private Table AIWaveEnabledOverride

        private group AITempGroup
        private timer AITimer

        private integer AIClockMs = 0
        private integer AIUnitCount = 0
        private integer AIGlobalCursor = 1
        private integer AICurrentTickMs = AI_TICK_MS
        private integer AICurrentBudget = AI_BUDGET_PER_TICK
        private integer AIFixedTickMs = AI_TICK_MS
        private integer AIFixedBudget = AI_BUDGET_PER_TICK
        private integer AINextPerfLogMs = 0
        private integer AIDebugLogsThisTick = 0
        private integer AIDebugMaxLogsPerTick = 12
        private integer AIDebugWaveFilter = 0
        private integer AIDebugUnitTypeFilter = 0
        private boolean AIDebugEnabled = false
        private boolean AIUseDynamicScheduler = true
        private boolean AIUseGroupFallbackNoHeroes = true
        private unit array AITrackedHeroByPlayer[24]
        private real AITeleportPointX = 0.0
        private real AITeleportPointY = 0.0
    endglobals

    private function AILog takes string msg returns nothing
        if AIDebugEnabled then
            call BJDebugMsg("[IAManager] " + msg)
        endif
    endfunction

    private function AILogLimited takes string msg returns nothing
        if not AIDebugEnabled then
            return
        endif
        if AIDebugLogsThisTick >= AIDebugMaxLogsPerTick then
            return
        endif
        set AIDebugLogsThisTick = AIDebugLogsThisTick + 1
        call BJDebugMsg("[IAManager] " + msg)
    endfunction

    private function AIBossReinforcementRollInitialMs takes nothing returns integer
        return GetRandomInt(AI_BOSS_REINFORCEMENT_INITIAL_MIN_MS, AI_BOSS_REINFORCEMENT_INITIAL_MAX_MS)
    endfunction

    private function AIBossReinforcementRollCooldownMs takes nothing returns integer
        return GetRandomInt(AI_BOSS_REINFORCEMENT_COOLDOWN_MIN_MS, AI_BOSS_REINFORCEMENT_COOLDOWN_MAX_MS)
    endfunction

    private function AIBossReinforcementSupportsUnitType takes integer unitTypeId returns boolean
        return unitTypeId == 'zA01' or unitTypeId == 'zA02' or unitTypeId == 'zA03' or unitTypeId == 'zA04' or unitTypeId == 'zA05' or unitTypeId == 'zA06' or unitTypeId == 'zA07' or unitTypeId == 'zA08' or unitTypeId == 'zA09'
    endfunction

    private function AIBossReinforcementAnimationForUnitType takes integer unitTypeId returns string
        if unitTypeId == 'zA01' then
            return "attack"
        elseif unitTypeId == 'zA02' then
            return "stand victory"
        elseif unitTypeId == 'zA03' then
            return "spell"
        elseif unitTypeId == 'zA04' then
            return "stand victory"
        elseif unitTypeId == 'zA05' then
            return "spell"
        elseif unitTypeId == 'zA06' then
            return "spell"
        elseif unitTypeId == 'zA07' then
            return "stand victory"
        elseif unitTypeId == 'zA08' then
            return "attack"
        elseif unitTypeId == 'zA09' then
            return "Birth"
        endif
        return ""
    endfunction

    private function AIBossReinforcementApplySlots takes Wave w, integer maxWave returns nothing
        if w == 0 then
            return
        endif
        if maxWave < 1 then
            return
        elseif maxWave > 10 then
            set maxWave = 10
        endif

        call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HPEA, 'hpea', 1, false, 2, 1, 1, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
        if maxWave >= 2 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMIL, 'hmil', 1, false, 2, 1, 2, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
        endif
        if maxWave >= 3 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HFOO, 'hfoo', 1, false, 2, 1, 3, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
        endif
        if maxWave >= 4 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HRIF, 'hrif', 1, false, 2, 1, 4, -1, false, AI_PROFILE_WAVE4_SPELL, 0, 0, 1.00)
        endif
        if maxWave >= 5 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HKNI, 'hkni', 1, false, 2, 1, 5, -1, false, AI_PROFILE_MELEE, 0, 0, 1.00)
        endif
        if maxWave >= 6 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMTM, 'hmtm', 1, false, 2, 1, 6, -1, false, AI_PROFILE_WAVE6_SPELL, 0, 0, 1.00)
        endif
        if maxWave >= 7 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMPR, 'hmpr', 1, false, 2, 1, 7, -1, false, AI_PROFILE_WAVE7_SPELL, 0, 0, 1.10)
        endif
        if maxWave >= 8 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HSOR, 'hsor', 1, false, 2, 1, 8, -1, false, AI_PROFILE_WAVE8_SPELL, 0, 0, 1.20)
        endif
        if maxWave >= 9 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HMTT, 'hmtt', 1, false, 2, 1, 9, -1, false, AI_PROFILE_WAVE9_SPELL, 0, 0, 1.00)
        endif
        if maxWave >= 10 then
            call w.upsertSlotExByPlayers(AI_STAGE1_SLOT_GROUP_HWT3, 'hwt3', 1, false, 2, 1, 10, -1, false, AI_PROFILE_WAVE10_SPELL, 0, 0, 1.00)
        endif
    endfunction

    private function AICalcDynamicBudget takes integer unitCount returns integer
        local integer b
        if unitCount <= 200 then
            set b = 48
        elseif unitCount <= 500 then
            set b = 72
        elseif unitCount <= 1000 then
            set b = 96
        else
            set b = 128
        endif
        return AIClampInt(b, AI_MIN_BUDGET_PER_TICK, AI_MAX_BUDGET_PER_TICK)
    endfunction

    private function AICalcDynamicTick takes integer unitCount, boolean combatSeen returns integer
        local integer t
        if unitCount <= 200 then
            set t = 200
        elseif unitCount <= 500 then
            set t = 250
        elseif unitCount <= 1000 then
            set t = 300
        else
            set t = 333
        endif
        if not combatSeen then
            set t = t + 50
        endif
        return AIClampInt(t, AI_MIN_TICK_MS, AI_MAX_TICK_MS)
    endfunction

    private function AIHasBehaviorFlag takes integer flags, integer mask returns boolean
        if mask <= 0 then
            return false
        endif
        return ModuloInteger(flags/mask, 2) == 1
    endfunction

    private function AIDebugPassesFilter takes unit u, integer waveId returns boolean
        if AIDebugWaveFilter > 0 and waveId != AIDebugWaveFilter then
            return false
        endif
        if AIDebugUnitTypeFilter != 0 then
            if u == null then
                return false
            endif
            if GetUnitTypeId(u) != AIDebugUnitTypeFilter then
                return false
            endif
        endif
        return true
    endfunction

    private function AIDistanceSqUnits takes unit a, unit b returns real
        local real dx
        local real dy
        set dx = GetUnitX(a) - GetUnitX(b)
        set dy = GetUnitY(a) - GetUnitY(b)
        return dx*dx + dy*dy
    endfunction

    private function AIDistanceSqPoint takes real x1, real y1, real x2, real y2 returns real
        local real dx = x1 - x2
        local real dy = y1 - y2
        return dx*dx + dy*dy
    endfunction

    private function AIGetKeepDistanceBandHalf takes real preferredRange returns real
        local real bandHalf
        if preferredRange <= 0.0 then
            return 72.0
        endif
        set bandHalf = preferredRange*0.06
        if bandHalf < 72.0 then
            set bandHalf = 72.0
        endif
        return bandHalf
    endfunction

    private function AIShouldUseKeepDistanceBand takes integer profileId returns boolean
        return profileId == AI_PROFILE_WAVE4_SPELL
    endfunction

    private function AIMaybeIssueMoveOrder takes unit u, integer hid, real x, real y returns nothing
        local boolean shouldIssue = true
        local real lastX
        local real lastY
        if AIUnitLastOrderType.has(hid) and AIUnitLastOrderType[hid] == AI_ORDER_MOVE then
            set lastX = AIUnitLastOrderX.real[hid]
            set lastY = AIUnitLastOrderY.real[hid]
            if AIDistanceSqPoint(lastX, lastY, x, y) <= (96.0*96.0) then
                set shouldIssue = false
            endif
        endif
        if shouldIssue and IssuePointOrder(u, "move", x, y) then
            set AIUnitLastOrderType[hid] = AI_ORDER_MOVE
            set AIUnitLastOrderTarget[hid] = 0
            set AIUnitLastOrderX.real[hid] = x
            set AIUnitLastOrderY.real[hid] = y
        endif
    endfunction

    private function AIMoveToTargetRange takes unit u, unit target, integer hid, real desiredRange returns nothing
        local real angle
        local real x
        local real y
        if u == null or target == null then
            return
        endif
        if desiredRange < 64.0 then
            set desiredRange = 64.0
        endif
        set angle = Atan2(GetUnitY(u) - GetUnitY(target), GetUnitX(u) - GetUnitX(target))
        set x = GetUnitX(target) + Cos(angle)*desiredRange
        set y = GetUnitY(target) + Sin(angle)*desiredRange
        call AIMaybeIssueMoveOrder(u, hid, x, y)
    endfunction

    private function AIGetUnitHpPct takes unit u returns real
        local real maxHp = GetUnitState(u, UNIT_STATE_MAX_LIFE)
        if maxHp <= 0.0 then
            return 100.0
        endif
        return GetUnitState(u, UNIT_STATE_LIFE)*100.0/maxHp
    endfunction
    
    private function AIIsEnemyHero takes unit source, unit target returns boolean
        if source == null or target == null then
            return false
        endif
        if GetUnitTypeId(target) == 0 then
            return false
        endif
        if not UnitAlive(target) then
            return false
        endif
        if not IsUnitType(target, UNIT_TYPE_HERO) then
            return false
        endif
        if not IsUnitEnemy(target, GetOwningPlayer(source)) then
            return false
        endif
        return true
    endfunction

    private function AIGetFallbackObjectiveTarget takes unit source returns unit
        local unit target
        if source == null then
            return null
        endif
        set target = GetTenderUnit()
        if target == null or GetUnitTypeId(target) == 0 or not UnitAlive(target) then
            set target = null
            return null
        endif
        if not IsUnitEnemy(target, GetOwningPlayer(source)) then
            set target = null
            return null
        endif
        return target
    endfunction

    private function AIIsCombatObjective takes unit source, unit target returns boolean
        if AIIsEnemyHero(source, target) then
            return true
        endif
        return AIGetFallbackObjectiveTarget(source) == target
    endfunction

    private function AIHasAliveEnemyHeroTracked takes unit source returns boolean
        local integer i = 0
        local unit u
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set u = AITrackedHeroByPlayer[i]
            if AIIsEnemyHero(source, u) then
                set u = null
                return true
            endif
            set i = i + 1
        endloop
        set u = null
        return false
    endfunction

    private function AIGetNearestTrackedHeroDistSq takes unit source, boolean enemyOnly returns real
        local integer i = 0
        local unit u
        local real dSq
        local real best = -1.0
        if source == null then
            return -1.0
        endif
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set u = AITrackedHeroByPlayer[i]
            if u != null and GetUnitTypeId(u) != 0 and UnitAlive(u) and IsUnitType(u, UNIT_TYPE_HERO) then
                if (not enemyOnly) or AIIsEnemyHero(source, u) then
                    set dSq = AIDistanceSqUnits(source, u)
                    if best < 0.0 or dSq < best then
                        set best = dSq
                    endif
                endif
            endif
            set i = i + 1
        endloop
        set u = null
        return best
    endfunction

    private function AICountEnemyHeroesInRadius takes unit source, real radius returns integer
        local integer count = 0
        local integer i = 0
        local unit u
        local boolean hasTracked = false
        local real radiusSq

        if source == null or radius <= 0.0 then
            return 0
        endif
        set radiusSq = radius*radius

        // Fast path: heroes registrados por jugador (ideal para mapas grandes).
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set u = AITrackedHeroByPlayer[i]
            if u != null and GetUnitTypeId(u) != 0 and UnitAlive(u) and IsUnitType(u, UNIT_TYPE_HERO) then
                set hasTracked = true
                if AIIsEnemyHero(source, u) and AIDistanceSqUnits(source, u) <= radiusSq then
                    set count = count + 1
                endif
            endif
            set i = i + 1
        endloop
        if hasTracked then
            set u = null
            return count
        endif
        if not AIUseGroupFallbackNoHeroes then
            set u = null
            return count
        endif

        call GroupEnumUnitsInRange(AITempGroup, GetUnitX(source), GetUnitY(source), radius, null)
        loop
            set u = FirstOfGroup(AITempGroup)
            exitwhen u == null
            call GroupRemoveUnit(AITempGroup, u)
            if AIIsEnemyHero(source, u) then
                set count = count + 1
            endif
        endloop

        set u = null
        return count
    endfunction

    private function AISelectTargetHero takes unit source, real acquireRange, integer behaviorFlags, real threatWeight returns unit
        local unit best = null
        local integer i = 0
        local unit u
        local real distSq
        local real acquireRangeSq
        local real hpPct
        local real score
        local real bestScore = -999999.0
        local boolean hasTracked = false

        if source == null then
            return null
        endif
        if acquireRange <= 0.0 then
            set acquireRange = 900.0
        endif
        if threatWeight <= 0.0 then
            set threatWeight = 1.0
        endif
        set acquireRangeSq = acquireRange*acquireRange

        // Fast path: heroes registrados por jugador (ideal para mapas grandes).
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set u = AITrackedHeroByPlayer[i]
            if u != null and GetUnitTypeId(u) != 0 and UnitAlive(u) and IsUnitType(u, UNIT_TYPE_HERO) then
                set hasTracked = true
                if AIIsEnemyHero(source, u) then
                    set distSq = AIDistanceSqUnits(source, u)
                    if distSq <= acquireRangeSq then
                        set score = acquireRangeSq - distSq

                        if AIHasBehaviorFlag(behaviorFlags, AI_BEHAVIOR_LOW_HP_BIAS) then
                            set hpPct = AIGetUnitHpPct(u)
                            if hpPct <= 60.0 then
                                set score = score + (60.0 - hpPct)*3.0
                            endif
                        endif

                        set score = score*threatWeight
                        if score > bestScore then
                            set bestScore = score
                            set best = u
                        endif
                    endif
                endif
            endif
            set i = i + 1
        endloop
        if hasTracked then
            set u = null
            return best
        endif
        if not AIUseGroupFallbackNoHeroes then
            set u = null
            return best
        endif

        call GroupEnumUnitsInRange(AITempGroup, GetUnitX(source), GetUnitY(source), acquireRange, null)
        loop
            set u = FirstOfGroup(AITempGroup)
            exitwhen u == null
            call GroupRemoveUnit(AITempGroup, u)

            if AIIsEnemyHero(source, u) then
                set distSq = AIDistanceSqUnits(source, u)
                set score = acquireRangeSq - distSq

                if AIHasBehaviorFlag(behaviorFlags, AI_BEHAVIOR_LOW_HP_BIAS) then
                    set hpPct = AIGetUnitHpPct(u)
                    if hpPct <= 60.0 then
                        set score = score + (60.0 - hpPct)*3.0
                    endif
                endif

                set score = score*threatWeight
                if score > bestScore then
                    set bestScore = score
                    set best = u
                endif
            endif
        endloop

        set u = null
        return best
    endfunction

    private function AISelectCombatObjective takes unit source, real acquireRange, integer behaviorFlags, real threatWeight returns unit
        local unit target = AISelectTargetHero(source, acquireRange, behaviorFlags, threatWeight)
        if target != null then
            return target
        endif
        if AIHasAliveEnemyHeroTracked(source) then
            return null
        endif
        return AIGetFallbackObjectiveTarget(source)
    endfunction

    private function AISelectFarthestTrackedHero takes unit source returns unit
        local integer i = 0
        local unit best = null
        local unit u
        local real distSq
        local real bestDistSq = -1.0

        if source == null then
            return null
        endif

        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set u = AITrackedHeroByPlayer[i]
            if AIIsEnemyHero(source, u) then
                set distSq = AIDistanceSqUnits(source, u)
                if distSq > bestDistSq then
                    set bestDistSq = distSq
                    set best = u
                endif
            endif
            set i = i + 1
        endloop

        set u = null
        return best
    endfunction

    private function AIResetOrderState takes integer hid returns nothing
        set AIUnitLastOrderType[hid] = AI_ORDER_NONE
        set AIUnitLastOrderTarget[hid] = 0
        set AIUnitLastOrderX.real[hid] = 0.0
        set AIUnitLastOrderY.real[hid] = 0.0
    endfunction

    private struct AIBossReinforcementCast
        unit boss
        Wave wave
        effect windupFx
        texttag castText
        timer t
        integer bossHid
        integer profileId
        integer startedAtMs
    endstruct

    private function AICancelBossReinforcementCast takes integer hid returns nothing
        local AIBossReinforcementCast cast
        if hid == 0 or not AIBossReinforcementCastByUnit.has(hid) then
            return
        endif
        set cast = AIBossReinforcementCast(AIBossReinforcementCastByUnit[hid])
        call AIBossReinforcementCastByUnit.remove(hid)
        if cast.windupFx != null then
            call DestroyEffect(cast.windupFx)
            set cast.windupFx = null
        endif
        if cast.castText != null then
            call DestroyTrackedTextTag(cast.castText, TEXTTAG_DEBUG_AI)
            set cast.castText = null
        endif
        if cast.boss != null and GetUnitTypeId(cast.boss) != 0 then
            call PauseUnit(cast.boss, false)
        endif
        if cast.t != null then
            call ReleaseTimer(cast.t)
            set cast.t = null
        endif
        set cast.boss = null
        set cast.wave = 0
        call cast.destroy()
    endfunction

    private function AIBossReinforcementApply takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local integer castId = GetTimerData(t)
        local AIBossReinforcementCast cast = castId
        local unit boss
        local Wave w
        local integer hid = 0

        if castId != 0 then
            set boss = cast.boss
            set w = cast.wave
            set hid = cast.bossHid
            if hid != 0 and AIBossReinforcementCastByUnit.has(hid) and AIBossReinforcementCastByUnit[hid] == castId then
                call AIBossReinforcementCastByUnit.remove(hid)
            endif
            if cast.windupFx != null then
                call DestroyEffect(cast.windupFx)
                set cast.windupFx = null
            endif
            if boss != null and GetUnitTypeId(boss) != 0 then
                call PauseUnit(boss, false)
            endif
            if boss != null and GetUnitTypeId(boss) != 0 and UnitAlive(boss) and w != 0 and w.isOperational() and Wave[boss] == w then
                if AI_BOSS_REINFORCEMENT_APPLY_FX != "" then
                    call DestroyEffect(AddSpecialEffectTarget(AI_BOSS_REINFORCEMENT_APPLY_FX, boss, AI_BOSS_REINFORCEMENT_ATTACH_POINT))
                endif
                call AIBossReinforcementApplySlots(w, w.waveIndex)
                call w.refreshBoard()
                if hid != 0 then
                    set AIBossReinforcementNextMs[hid] = cast.startedAtMs + AI_BOSS_REINFORCEMENT_WINDUP_MS + AIBossReinforcementRollCooldownMs()
                    set AIUnitNextAbilityMs[hid] = cast.startedAtMs + AI_BOSS_REINFORCEMENT_WINDUP_MS + AIIntervalToMs(AIGetProfileThinkInterval(cast.profileId), 250)
                    set AIUnitNextOrderMs[hid] = cast.startedAtMs + AI_BOSS_REINFORCEMENT_WINDUP_MS + AIIntervalToMs(AIGetProfileOrderInterval(cast.profileId), 350)
                endif
            endif
            set cast.castText = null
            set cast.boss = null
            set cast.wave = 0
            call cast.destroy()
        endif

        call ReleaseTimer(t)
        set boss = null
        set w = 0
        set t = null
    endfunction

    private function AITryBossReinforcement takes unit u, integer hid, integer waveId, integer profileId returns boolean
        local Wave w
        local AIBossReinforcementCast cast
        local string animation
        local integer unitTypeId
        local integer channelLockUntil
        local integer nextReinforcementMs

        if u == null or hid == 0 then
            return false
        endif

        if AIBossReinforcementCastByUnit.has(hid) then
            return true
        endif

        set unitTypeId = GetUnitTypeId(u)
        if not AIBossReinforcementSupportsUnitType(unitTypeId) then
            return false
        endif

        set channelLockUntil = AIUnitChannelLockUntilMs[hid]
        if AIClockMs < channelLockUntil then
            return false
        endif

        if not AIBossReinforcementNextMs.has(hid) then
            set AIBossReinforcementNextMs[hid] = AIClockMs + AIBossReinforcementRollInitialMs()
            return false
        endif
        set nextReinforcementMs = AIBossReinforcementNextMs[hid]
        if AIClockMs < nextReinforcementMs then
            return false
        endif

        set w = Wave(waveId)
        if w == 0 or not w.isOperational() then
            return false
        endif

        call IssueImmediateOrder(u, "stop")
        call AIResetOrderState(hid)

        set animation = AIBossReinforcementAnimationForUnitType(unitTypeId)
        if animation != "" then
            call SetUnitAnimation(u, animation)
            call QueueUnitAnimationBJ(u, "stand")
        endif

        set cast = AIBossReinforcementCast.create()
        set cast.boss = u
        set cast.wave = w
        set cast.bossHid = hid
        set cast.profileId = profileId
        set cast.startedAtMs = AIClockMs
        if AI_BOSS_REINFORCEMENT_START_FX != "" then
            set cast.windupFx = AddSpecialEffectTarget(AI_BOSS_REINFORCEMENT_START_FX, u, AI_BOSS_REINFORCEMENT_ATTACH_POINT)
        else
            set cast.windupFx = null
        endif
        set cast.castText = CreateTrackedTextTag(TEXTTAG_DEBUG_AI)
        call SetTextTagText(cast.castText, AI_BOSS_REINFORCEMENT_TEXT, AI_BOSS_REINFORCEMENT_TEXT_SIZE)
        call SetTextTagPosUnit(cast.castText, u, AI_BOSS_REINFORCEMENT_TEXT_Z_OFFSET)
        call SetTextTagVelocity(cast.castText, 0.0, AI_BOSS_REINFORCEMENT_TEXT_RISE_SPEED)
        call SetTextTagLifespan(cast.castText, AI_BOSS_REINFORCEMENT_TEXT_LIFESPAN)
        call SetTextTagFadepoint(cast.castText, AI_BOSS_REINFORCEMENT_TEXT_FADEPOINT)
        call SetTextTagPermanent(cast.castText, false)
        call ReleaseTrackedTextTag(TEXTTAG_DEBUG_AI)
        set cast.t = NewTimer()
        call SetTimerDebugTag(cast.t, TIMER_DEBUG_TAG_AI)
        call SetTimerData(cast.t, cast)
        set AIBossReinforcementCastByUnit[hid] = cast
        call PauseUnit(u, true)

        set AIUnitChannelLockUntilMs[hid] = AIClockMs + AI_BOSS_REINFORCEMENT_WINDUP_MS
        set AIUnitNextAbilityMs[hid] = AIClockMs + AI_BOSS_REINFORCEMENT_WINDUP_MS
        set AIUnitNextOrderMs[hid] = AIClockMs + AI_BOSS_REINFORCEMENT_WINDUP_MS

        call TimerStart(cast.t, I2R(AI_BOSS_REINFORCEMENT_WINDUP_MS)*0.001, false, function AIBossReinforcementApply)
        set w = 0
        return true
    endfunction

    private function AIInitTeleportState takes integer hid, integer profileId returns nothing
        local integer readyMs = AIClockMs + AIGetRandomMsRange(AIGetProfileTeleportEntryDelayMin(profileId), AIGetProfileTeleportEntryDelayMax(profileId), 0, AI_TELEPORT_MIN_ENTRY_DELAY_MS)
        if AIGetProfileTeleportEnabled(profileId) then
            set AIUnitTeleportReadyMs[hid] = readyMs
            set AIUnitNextTeleportMs[hid] = readyMs
        else
            call AIUnitTeleportReadyMs.remove(hid)
            call AIUnitNextTeleportMs.remove(hid)
        endif
    endfunction

    private function AIIsTeleportPointValid takes unit hero, real x, real y returns boolean
        if hero == null or GetUnitTypeId(hero) == 0 or not UnitAlive(hero) then
            return false
        endif
        if not IsVisibleToPlayer(x, y, GetOwningPlayer(hero)) then
            return false
        endif
        if not IsTerrainWalkable(x, y) then
            return false
        endif
        return true
    endfunction

    private function AITryFindTeleportPointInArc takes unit hero, real baseAngle, real angleSpan, real minOffset, real maxOffset, integer attempts returns boolean
        local integer i = 0
        local real angle
        local real offset
        local real halfSpan = angleSpan*0.5
        local real heroX
        local real heroY

        if hero == null or attempts <= 0 then
            return false
        endif

        set heroX = GetUnitX(hero)
        set heroY = GetUnitY(hero)

        loop
            exitwhen i >= attempts
            set angle = baseAngle + AIGetRandomRealRange(-halfSpan, halfSpan)
            set offset = AIGetRandomRealRange(minOffset, maxOffset)
            set AITeleportPointX = heroX + Cos(angle)*offset
            set AITeleportPointY = heroY + Sin(angle)*offset
            if AIIsTeleportPointValid(hero, AITeleportPointX, AITeleportPointY) then
                return true
            endif
            set i = i + 1
        endloop

        return false
    endfunction

    private function AIGetTeleportBaseAngle takes unit source, unit hero returns real
        local real heroFacing
        local real dx
        local real dy
        local real len
        local real dot
        local real tmp

        if hero == null then
            return 0.0
        endif
        set heroFacing = GetUnitFacing(hero)*bj_DEGTORAD
        set dx = GetUnitX(source) - GetUnitX(hero)
        set dy = GetUnitY(source) - GetUnitY(hero)
        set len = SquareRoot(dx*dx + dy*dy)
        if len <= 0.0 then
            return heroFacing + bj_PI
        endif
        set dot = Cos(heroFacing)*(dx/len) + Sin(heroFacing)*(dy/len)
        if dot <= -AI_TELEPORT_FRONTBACK_DOT_THRESHOLD then
            return heroFacing
        endif
        return heroFacing + bj_PI
    endfunction

    private function AITryFindTeleportPoint takes unit source, unit hero, real minOffset, real maxOffset returns boolean
        local real baseAngle
        local real tmp
        if hero == null then
            return false
        endif
        set minOffset = AIClampReal(minOffset, AI_TELEPORT_MIN_OFFSET, 99999.0)
        set maxOffset = AIClampReal(maxOffset, AI_TELEPORT_MIN_OFFSET, 99999.0)
        if maxOffset < minOffset then
            set tmp = minOffset
            set minOffset = maxOffset
            set maxOffset = tmp
        endif
        set baseAngle = AIGetTeleportBaseAngle(source, hero)
        if AITryFindTeleportPointInArc(hero, baseAngle, bj_PI, minOffset, maxOffset, AI_TELEPORT_BACK_ATTEMPTS) then
            return true
        endif
        return AITryFindTeleportPointInArc(hero, AIGetRandomRealRange(0.0, 2.0*bj_PI), 2.0*bj_PI, minOffset, maxOffset, AI_TELEPORT_FALLBACK_ATTEMPTS)
    endfunction

    private function AITryTeleportByProfile takes unit u, unit currentTarget, integer hid, integer profileId returns boolean
        local unit blinkHero = currentTarget
        local integer nowMs = AIClockMs
        local integer nextTeleport
        local integer readyMs
        local integer cooldownMs
        local real minOffset
        local real maxOffset
        local string preFxPath
        local effect fx

        if u == null or GetUnitTypeId(u) == 0 or not UnitAlive(u) then
            return false
        endif
        if not AIGetProfileTeleportEnabled(profileId) then
            return false
        endif
        if AIGetProfileTeleportPrioritizeFarthestTrackedHero(profileId) then
            set blinkHero = AISelectFarthestTrackedHero(u)
        endif
        if blinkHero == null or not AIIsEnemyHero(u, blinkHero) then
            return false
        endif

        if not AIUnitTeleportReadyMs.has(hid) or not AIUnitNextTeleportMs.has(hid) then
            call AIInitTeleportState(hid, profileId)
        endif
        set readyMs = AIUnitTeleportReadyMs[hid]
        if nowMs < readyMs then
            return false
        endif
        set nextTeleport = AIUnitNextTeleportMs[hid]
        if nowMs < nextTeleport then
            return false
        endif

        set minOffset = AIGetProfileTeleportOffsetMin(profileId)
        set maxOffset = AIGetProfileTeleportOffsetMax(profileId)
        if maxOffset <= 0.0 then
            return false
        endif
        if not AITryFindTeleportPoint(u, blinkHero, minOffset, maxOffset) then
            return false
        endif

        set preFxPath = AIGetProfileTeleportPreFxPath(profileId)
        if preFxPath != "" then
            set fx = AddSpecialEffectTarget(preFxPath, u, AI_TELEPORT_ATTACH_POINT)
            call DestroyEffect(fx)
            set fx = null
        endif

        call SetUnitX(u, AITeleportPointX)
        call SetUnitY(u, AITeleportPointY)
        call AIResetOrderState(hid)
        set AIUnitTarget.unit[hid] = blinkHero
        set AIUnitNextRetargetMs[hid] = 0
        set AIUnitNextAbilityMs[hid] = nowMs + AIIntervalToMs(AIGetProfileThinkInterval(profileId), 250)
        set AIUnitNextOrderMs[hid] = nowMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
        set cooldownMs = AIGetRandomMsRange(AIGetProfileTeleportCooldownMin(profileId), AIGetProfileTeleportCooldownMax(profileId), AI_TELEPORT_MIN_COOLDOWN_MS, AI_TELEPORT_MIN_COOLDOWN_MS)
        set AIUnitNextTeleportMs[hid] = nowMs + cooldownMs
        if AIDebugEnabled then
            call AILogLimited("TELEPORT ut=" + I2S(GetUnitTypeId(u)) + " target=" + I2S(GetUnitTypeId(blinkHero)) + " x=" + R2S(AITeleportPointX) + " y=" + R2S(AITeleportPointY))
        endif
        set blinkHero = null
        return true
    endfunction

    private function AIGetUnitCooldownTable takes integer hid, boolean createIfMissing returns Table
        local Table t
        if AIUnitCooldownTables.has(hid) then
            return Table(AIUnitCooldownTables[hid])
        endif
        if createIfMissing then
            set t = Table.create()
            set AIUnitCooldownTables[hid] = t
            return t
        endif
        return 0
    endfunction

    private function AIUpdateWaveUnitCountOnRemove takes integer waveId returns nothing
        local integer c
        if waveId == 0 or not AIWaveUnitCount.has(waveId) then
            return
        endif
        set c = AIWaveUnitCount[waveId] - 1
        if c < 0 then
            set c = 0
        endif
        set AIWaveUnitCount[waveId] = c
        if c == 0 then
            set AIWaveIsActive[waveId] = 0
        endif
    endfunction

    private function AIRemoveUnitByIndex takes integer index returns nothing
        local integer last
        local unit u
        local unit moved
        local integer hid = 0
        local integer movedHid = 0
        local integer waveId = 0
        local Table cd

        if index < 1 or index > AIUnitCount then
            return
        endif

        set last = AIUnitCount
        set u = AIUnitByIndex.unit[index]
        if u != null then
            set hid = GetHandleId(u)
            if AIUnitWaveId.has(hid) then
                set waveId = AIUnitWaveId[hid]
            endif
        endif

        if index != last then
            set moved = AIUnitByIndex.unit[last]
            set AIUnitByIndex.unit[index] = moved
            if moved != null then
                set movedHid = GetHandleId(moved)
                if movedHid != 0 then
                    set AIIndexByUnit[movedHid] = index
                endif
            endif
        endif

        call AIUnitByIndex.remove(last)
        set AIUnitCount = last - 1

        if hid != 0 then
            call AICancelBossReinforcementCast(hid)
            call AIIndexByUnit.remove(hid)
            call AIUnitWaveId.remove(hid)
            call AIUnitProfileId.remove(hid)
            call AIUnitLaneId.remove(hid)
            call AIUnitBehaviorFlags.remove(hid)
            call AIUnitThreatWeight.remove(hid)
            call AIUnitTarget.remove(hid)
            call AIUnitNextRetargetMs.remove(hid)
            call AIUnitNextOrderMs.remove(hid)
            call AIUnitNextAbilityMs.remove(hid)
            call AIUnitChannelLockUntilMs.remove(hid)
            call AIUnitNextTeleportMs.remove(hid)
            call AIUnitTeleportReadyMs.remove(hid)
            call AIUnitNextDebugMs.remove(hid)
            call AIUnitLastOrderType.remove(hid)
            call AIUnitLastOrderTarget.remove(hid)
            call AIUnitLastOrderX.remove(hid)
            call AIUnitLastOrderY.remove(hid)
            call AIBossReinforcementNextMs.remove(hid)
            if AIUnitCooldownTables.has(hid) then
                set cd = Table(AIUnitCooldownTables[hid])
                call cd.destroy()
                call AIUnitCooldownTables.remove(hid)
            endif
        endif

        call AIUpdateWaveUnitCountOnRemove(waveId)

        if AIUnitCount <= 0 then
            set AIGlobalCursor = 1
        elseif AIGlobalCursor > AIUnitCount then
            set AIGlobalCursor = 1
        endif

        set cd = 0
        set moved = null
        set u = null
    endfunction

    private function AIAddOrUpdateUnit takes unit u, integer waveId, integer profileId, integer laneId, integer behaviorFlags, real threatWeight returns nothing
        local integer hid
        local integer idx
        local integer oldWaveId
        local integer oldProfileId

        if u == null or waveId == 0 then
            return
        endif
        if GetUnitTypeId(u) == 0 or not UnitAlive(u) then
            return
        endif

        set hid = GetHandleId(u)
        if profileId <= 0 then
            set profileId = AIGetDefaultProfileForUnitType(GetUnitTypeId(u))
        endif
        if profileId <= 0 then
            set profileId = AI_DEFAULT_PROFILE_ID
        endif
        if behaviorFlags == 0 then
            set behaviorFlags = AIGetProfileDefaultFlags(profileId)
        endif
        if threatWeight <= 0.0 then
            set threatWeight = 1.0
        endif

        if AIIndexByUnit.has(hid) then
            set oldWaveId = AIUnitWaveId[hid]
            set oldProfileId = AIUnitProfileId[hid]
            set AIUnitWaveId[hid] = waveId
            set AIUnitProfileId[hid] = profileId
            set AIUnitLaneId[hid] = laneId
            set AIUnitBehaviorFlags[hid] = behaviorFlags
            set AIUnitThreatWeight.real[hid] = threatWeight
            if AIGetProfileTeleportEnabled(profileId) then
                if oldProfileId != profileId or not AIUnitTeleportReadyMs.has(hid) or not AIUnitNextTeleportMs.has(hid) then
                    call AIInitTeleportState(hid, profileId)
                endif
            else
                call AIUnitNextTeleportMs.remove(hid)
                call AIUnitTeleportReadyMs.remove(hid)
            endif
            if oldWaveId != waveId then
                call AIUpdateWaveUnitCountOnRemove(oldWaveId)
                set AIWaveIsActive[waveId] = 1
                if not AIWaveIsPaused.has(waveId) then
                    set AIWaveIsPaused[waveId] = 0
                endif
                set AIWaveUnitCount[waveId] = AIWaveUnitCount[waveId] + 1
            endif
            return
        endif

        set AIUnitCount = AIUnitCount + 1
        set idx = AIUnitCount

        set AIUnitByIndex.unit[idx] = u
        set AIIndexByUnit[hid] = idx

        set AIUnitWaveId[hid] = waveId
        set AIUnitProfileId[hid] = profileId
        set AIUnitLaneId[hid] = laneId
        set AIUnitBehaviorFlags[hid] = behaviorFlags
        set AIUnitThreatWeight.real[hid] = threatWeight
        set AIUnitTarget.unit[hid] = null

        set AIUnitNextRetargetMs[hid] = 0
        set AIUnitNextOrderMs[hid] = 0
        set AIUnitNextAbilityMs[hid] = 0
        set AIUnitChannelLockUntilMs[hid] = 0
        call AIInitTeleportState(hid, profileId)
        set AIUnitNextDebugMs[hid] = 0
        call AIResetOrderState(hid)

        set AIWaveIsActive[waveId] = 1
        if not AIWaveIsPaused.has(waveId) then
            set AIWaveIsPaused[waveId] = 0
        endif
        set AIWaveUnitCount[waveId] = AIWaveUnitCount[waveId] + 1
    endfunction

    private function AICleanupWave takes integer waveId returns nothing
        local integer i = AIUnitCount
        local unit u
        local integer hid

        loop
            exitwhen i <= 0
            set u = AIUnitByIndex.unit[i]
            if u != null then
                set hid = GetHandleId(u)
                if hid != 0 and AIUnitWaveId.has(hid) and AIUnitWaveId[hid] == waveId then
                    call AIRemoveUnitByIndex(i)
                endif
            endif
            set i = i - 1
        endloop

        call AIWaveIsActive.remove(waveId)
        call AIWaveIsPaused.remove(waveId)
        call AIWaveUnitCount.remove(waveId)
        call AIWaveEnabledOverride.remove(waveId)

        set u = null
    endfunction

    private function AIIsWaveEnabled takes integer waveId returns boolean
        if AIWaveEnabledOverride.has(waveId) then
            return AIWaveEnabledOverride[waveId] == 1
        endif
        return true
    endfunction

    private function AITryCastByProfile takes unit u, unit target, integer hid, integer profileId, integer behaviorFlags returns boolean
        local integer slot = 1
        local integer count = AIGetProfileRuleCount(profileId)
        local integer bestSlot = 0
        local integer bestPriority = -2147483647
        local integer abilityId
        local integer targetType
        local integer minEnemies
        local integer level
        local integer nowMs = AIClockMs
        local integer minRangeOk
        local string orderString
        local real minRange
        local real maxRange
        local real selfHpMax
        local real enemyHpMax
        local real radius
        local real localCooldown
        local real distSq
        local real minRangeSq
        local real maxRangeSq
        local real selfHpPct
        local real enemyHpPct
        local integer isChanneling
        local real channelLockSeconds
        local boolean success = false
        local Table cdTable

        if count <= 0 or u == null or target == null then
            return false
        endif

        set distSq = AIDistanceSqUnits(u, target)
        set selfHpPct = AIGetUnitHpPct(u)
        set enemyHpPct = AIGetUnitHpPct(target)
        set cdTable = AIGetUnitCooldownTable(hid, true)

        loop
            exitwhen slot > count
            set abilityId = AIGetProfileRuleAbilityId(profileId, slot)
            if abilityId != 0 then
                set orderString = AIGetProfileRuleOrderString(profileId, slot)
                if orderString != "" then
                    set level = GetUnitAbilityLevel(u, abilityId)
                    if level > 0 then
                        if not cdTable.has(slot) or nowMs >= cdTable[slot] then
                            // Compatibilidad 1.27b: sin nativas Blz para cooldown/mana cost.
                            // Se valida por reglas IA + resultado real de la orden.
                            set minRange = AIGetProfileRuleMinRange(profileId, slot)
                            set maxRange = AIGetProfileRuleMaxRange(profileId, slot)
                            set minRangeOk = 1
                            set minRangeSq = minRange*minRange
                            set maxRangeSq = maxRange*maxRange

                            if minRange > 0.0 and distSq < minRangeSq then
                                set minRangeOk = 0
                            endif
                            if maxRange > 0.0 and distSq > maxRangeSq then
                                set minRangeOk = 0
                            endif

                            if minRangeOk == 1 then
                                set selfHpMax = AIGetProfileRuleSelfHpMaxPct(profileId, slot)
                                set enemyHpMax = AIGetProfileRuleEnemyHpMaxPct(profileId, slot)

                                if (selfHpMax <= 0.0 or selfHpPct <= selfHpMax) and (enemyHpMax <= 0.0 or enemyHpPct <= enemyHpMax) then
                                    set minEnemies = AIGetProfileRuleMinEnemiesInRadius(profileId, slot)
                                    if minEnemies > 0 then
                                        set radius = AIGetProfileRuleRadius(profileId, slot)
                                        if radius <= 0.0 or AICountEnemyHeroesInRadius(u, radius) < minEnemies then
                                            set minRangeOk = 0
                                        endif
                                    endif

                                    if minRangeOk == 1 and AIGetProfileRulePriority(profileId, slot) > bestPriority then
                                        set bestPriority = AIGetProfileRulePriority(profileId, slot)
                                        set bestSlot = slot
                                    endif
                                endif
                            endif
                        endif
                    endif
                endif
            endif
            set slot = slot + 1
        endloop

        if bestSlot > 0 then
            set targetType = AIGetProfileRuleTargetType(profileId, bestSlot)
            set orderString = AIGetProfileRuleOrderString(profileId, bestSlot)

            if targetType == AI_TARGET_NONE then
                set success = IssueImmediateOrder(u, orderString)
            elseif targetType == AI_TARGET_POINT then
                set success = IssuePointOrder(u, orderString, GetUnitX(target), GetUnitY(target))
            else
                set success = IssueTargetOrder(u, orderString, target)
            endif

            if success then
                set localCooldown = AIGetProfileRuleLocalCooldown(profileId, bestSlot)
                if localCooldown > 0.0 then
                    set cdTable[bestSlot] = nowMs + AIIntervalToMs(localCooldown, 0)
                endif
                set isChanneling = AIGetProfileRuleIsChanneling(profileId, bestSlot)
                if isChanneling == 1 then
                    set channelLockSeconds = AIGetProfileRuleChannelLock(profileId, bestSlot)
                    if channelLockSeconds <= 0.0 then
                        set channelLockSeconds = 1.00
                    endif
                    set AIUnitChannelLockUntilMs[hid] = nowMs + AIIntervalToMs(channelLockSeconds, 1000)
                else
                    set AIUnitChannelLockUntilMs[hid] = 0
                endif
                call AIResetOrderState(hid)
            else
                // Backoff corto para evitar reintentos de orden cada think tick.
                set cdTable[bestSlot] = nowMs + AI_CAST_FAIL_BACKOFF_MS
            endif
        endif

        set cdTable = 0
        return success
    endfunction

    private function AIMaybeIssueAttackOrder takes unit u, integer hid, unit target returns nothing
        local integer targetHid = 0
        if target != null then
            set targetHid = GetHandleId(target)
        endif
        if targetHid == 0 then
            return
        endif
        if AIUnitLastOrderType.has(hid) and AIUnitLastOrderType[hid] == AI_ORDER_ATTACK and AIUnitLastOrderTarget[hid] == targetHid then
            return
        endif
        if IssueTargetOrder(u, "attack", target) then
            set AIUnitLastOrderType[hid] = AI_ORDER_ATTACK
            set AIUnitLastOrderTarget[hid] = targetHid
            set AIUnitLastOrderX.real[hid] = 0.0
            set AIUnitLastOrderY.real[hid] = 0.0
        endif
    endfunction

private function AIApplyMovement takes unit u, unit target, integer hid, integer profileId, integer behaviorFlags returns nothing
        local real preferredRange = AIGetProfilePreferredRange(profileId)
        local real distSq
        local real bandHalf
        local real innerRange
        local real outerRange
        local real moveAwayRange
        local real moveCloseRange

        if preferredRange <= 0.0 then
            set preferredRange = 180.0
        endif

        set distSq = AIDistanceSqUnits(u, target)
        if AIHasBehaviorFlag(behaviorFlags, AI_BEHAVIOR_KEEP_DISTANCE) then
            if AIShouldUseKeepDistanceBand(profileId) then
                set bandHalf = AIGetKeepDistanceBandHalf(preferredRange)
                set innerRange = preferredRange - bandHalf
                set outerRange = preferredRange + bandHalf
                if innerRange < 64.0 then
                    set innerRange = 64.0
                endif
                if outerRange < innerRange then
                    set outerRange = innerRange
                endif

                if distSq < innerRange*innerRange then
                    set moveAwayRange = preferredRange + 64.0
                    call AIMoveToTargetRange(u, target, hid, moveAwayRange)
                elseif distSq > outerRange*outerRange then
                    set moveCloseRange = preferredRange - 64.0
                    if moveCloseRange < 96.0 then
                        set moveCloseRange = 96.0
                    endif
                    call AIMoveToTargetRange(u, target, hid, moveCloseRange)
                else
                    call AIMaybeIssueAttackOrder(u, hid, target)
                endif
            else
                if distSq < (preferredRange*0.75)*(preferredRange*0.75) then
                    set moveAwayRange = preferredRange
                    call AIMoveToTargetRange(u, target, hid, moveAwayRange)
                else
                    call AIMaybeIssueAttackOrder(u, hid, target)
                endif
            endif
        else
            call AIMaybeIssueAttackOrder(u, hid, target)
        endif

        set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
    endfunction

    private function AIEvaluateUnit takes unit u returns boolean
        local integer hid
        local integer waveId
        local integer profileId
        local integer behaviorFlags
        local integer nextRetarget
        local integer nextAbility
        local integer nextOrder
        local integer nextDebug
        local boolean shouldRetarget = false
        local unit target
        local real leashRange
        local real leashRangeSq
        local real chaseBias
        local real acquireRange
        local real threatWeight
        local real nearTrackedEnemySq
        local real nearTrackedAnySq
        local real nearTrackedEnemyDist
        local real nearTrackedAnyDist
        local integer channelLockUntil
        local boolean casted

        if u == null then
            return false
        endif
        if GetUnitTypeId(u) == 0 or not UnitAlive(u) then
            return false
        endif

        set hid = GetHandleId(u)
        if hid == 0 or not AIUnitWaveId.has(hid) then
            return false
        endif

        set waveId = AIUnitWaveId[hid]
        if not AIIsWaveEnabled(waveId) then
            return false
        endif
        if AIWaveIsPaused.has(waveId) and AIWaveIsPaused[waveId] == 1 then
            return false
        endif

        set profileId = AIUnitProfileId[hid]
        if profileId <= 0 then
            set profileId = AIGetDefaultProfileForUnitType(GetUnitTypeId(u))
            if profileId <= 0 then
                set profileId = AI_DEFAULT_PROFILE_ID
            endif
            set AIUnitProfileId[hid] = profileId
        endif

        set behaviorFlags = AIUnitBehaviorFlags[hid]
        if behaviorFlags == 0 then
            set behaviorFlags = AIGetProfileDefaultFlags(profileId)
            set AIUnitBehaviorFlags[hid] = behaviorFlags
        endif

        if AIUnitThreatWeight.real.has(hid) then
            set threatWeight = AIUnitThreatWeight.real[hid]
        else
            set threatWeight = 1.0
            set AIUnitThreatWeight.real[hid] = threatWeight
        endif

        if AITryBossReinforcement(u, hid, waveId, profileId) then
            return true
        endif

        set target = AIUnitTarget.unit[hid]
        if target == null or not AIIsCombatObjective(u, target) then
            set shouldRetarget = true
        else
            set leashRange = AIGetProfileLeashRange(profileId)
            if leashRange <= 0.0 then
                set leashRange = 1400.0
            endif
            set chaseBias = AIGetProfileChaseBias(profileId)
            if chaseBias <= 0.0 then
                set chaseBias = 1.0
            endif
            set leashRangeSq = (leashRange*chaseBias)*(leashRange*chaseBias)
            if AIDistanceSqUnits(u, target) > leashRangeSq then
                set shouldRetarget = true
            endif
        endif

        set nextRetarget = AIUnitNextRetargetMs[hid]
        if AIClockMs >= nextRetarget then
            set shouldRetarget = true
        endif

        if shouldRetarget then
            set acquireRange = AIGetProfileAcquireRange(profileId)
            set target = AISelectCombatObjective(u, acquireRange, behaviorFlags, threatWeight)
            set AIUnitTarget.unit[hid] = target
            set AIUnitNextRetargetMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileRetargetInterval(profileId), 500)
        endif

        if target == null then
            if AIDebugEnabled and AIDebugPassesFilter(u, waveId) then
                set nextDebug = AIUnitNextDebugMs[hid]
                if AIClockMs >= nextDebug then
                    set nearTrackedEnemySq = AIGetNearestTrackedHeroDistSq(u, true)
                    set nearTrackedAnySq = AIGetNearestTrackedHeroDistSq(u, false)
                    if nearTrackedEnemySq >= 0.0 then
                        set nearTrackedEnemyDist = SquareRoot(nearTrackedEnemySq)
                    else
                        set nearTrackedEnemyDist = -1.0
                    endif
                    if nearTrackedAnySq >= 0.0 then
                        set nearTrackedAnyDist = SquareRoot(nearTrackedAnySq)
                    else
                        set nearTrackedAnyDist = -1.0
                    endif
                    call AILogLimited("IDLE no-target w=" + I2S(waveId) + " ut=" + I2S(GetUnitTypeId(u)) + " acq=" + R2S(acquireRange) + " nearestEnemyTracked=" + R2S(nearTrackedEnemyDist) + " nearestAnyTracked=" + R2S(nearTrackedAnyDist) + " fallback=" + I2S(AIBoolToInt(AIUseGroupFallbackNoHeroes)))
                    set AIUnitNextDebugMs[hid] = AIClockMs + 1500
                endif
            endif
            return false
        endif

        set channelLockUntil = AIUnitChannelLockUntilMs[hid]
        if AIClockMs < channelLockUntil then
            return true
        endif

        if AITryTeleportByProfile(u, target, hid, profileId) then
            set target = null
            return true
        endif

        if WaveBarrierSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        if WaveAuraSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        if WaveRangedSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        if WaveSiegeSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        if WaveMortarSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        if WavePriestSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        if WaveTrapSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        if WaveSiegeZoneSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        if WaveWaveformSkillsTryExecute(u, target, AIClockMs) then
            set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
            set target = null
            return true
        endif

        set nextAbility = AIUnitNextAbilityMs[hid]
        if AIClockMs >= nextAbility then
            set casted = AITryCastByProfile(u, target, hid, profileId, behaviorFlags)
            set AIUnitNextAbilityMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileThinkInterval(profileId), 250)
            if casted then
                set AIUnitNextOrderMs[hid] = AIClockMs + AIIntervalToMs(AIGetProfileOrderInterval(profileId), 350)
                set target = null
                return true
            endif
        endif

        set nextOrder = AIUnitNextOrderMs[hid]
        if AIClockMs >= nextOrder then
            call AIApplyMovement(u, target, hid, profileId, behaviorFlags)
        endif

        set target = null
        return true
    endfunction

    private function AIOnTick takes nothing returns nothing
        local integer processed = 0
        local integer idx
        local integer budget
        local integer nextTickMs
        local unit u
        local boolean combatSeen = false

        set AIDebugLogsThisTick = 0
        set AIClockMs = AIClockMs + AICurrentTickMs

        if AIUseDynamicScheduler then
            set budget = AICalcDynamicBudget(AIUnitCount)
        else
            set budget = AIFixedBudget
        endif
        set budget = AIClampInt(budget, AI_MIN_BUDGET_PER_TICK, AI_MAX_BUDGET_PER_TICK)
        set AICurrentBudget = budget

        if AIUnitCount > 0 then
            loop
                exitwhen processed >= budget or AIUnitCount <= 0

                if AIGlobalCursor < 1 or AIGlobalCursor > AIUnitCount then
                    set AIGlobalCursor = 1
                endif

                set idx = AIGlobalCursor
                set u = AIUnitByIndex.unit[idx]
                set AIGlobalCursor = idx + 1

                if u == null or GetUnitTypeId(u) == 0 or not UnitAlive(u) then
                    call AIRemoveUnitByIndex(idx)
                else
                    if AIEvaluateUnit(u) then
                        set combatSeen = true
                    endif
                endif

                set processed = processed + 1
            endloop
        endif

        if AIUseDynamicScheduler then
            set nextTickMs = AICalcDynamicTick(AIUnitCount, combatSeen)
        else
            set nextTickMs = AIFixedTickMs
        endif
        set AICurrentTickMs = AIClampInt(nextTickMs, AI_MIN_TICK_MS, AI_MAX_TICK_MS)
        if AIDebugEnabled and AIClockMs >= AINextPerfLogMs then
            call AILogLimited("tick=" + I2S(AICurrentTickMs) + " budget=" + I2S(AICurrentBudget) + " units=" + I2S(AIUnitCount) + " combatSeen=" + I2S(AIBoolToInt(combatSeen)))
            set AINextPerfLogMs = AIClockMs + 1000
        endif
        call TimerStart(AITimer, I2R(AICurrentTickMs)*0.001, false, function AIOnTick)

        set u = null
    endfunction

    private function AIOnWaveSpawn takes nothing returns nothing
        local Wave w = GetWaveEventWave()
        local unit u = GetWaveEventUnit()
        local WaveSlot s = GetWaveEventSlot()
        local integer profileId = 0
        local integer laneId = 0
        local integer behaviorFlags = 0
        local real threatWeight = 1.0

        if w == 0 or u == null then
            set u = null
            return
        endif

        if s != 0 then
            set profileId = s.aiProfileId
            set laneId = s.laneId
            set behaviorFlags = s.behaviorFlags
            set threatWeight = s.threatWeight
        endif

        if profileId <= 0 then
            set profileId = AIGetDefaultProfileForUnitType(GetUnitTypeId(u))
        endif
        if profileId <= 0 then
            set profileId = AI_DEFAULT_PROFILE_ID
        endif
        if behaviorFlags == 0 then
            set behaviorFlags = AIGetProfileDefaultFlags(profileId)
        endif
        if threatWeight <= 0.0 then
            set threatWeight = 1.0
        endif

        call AIAddOrUpdateUnit(u, w, profileId, laneId, behaviorFlags, threatWeight)
        if AIBossReinforcementSupportsUnitType(GetUnitTypeId(u)) then
            set AIBossReinforcementNextMs[GetHandleId(u)] = AIClockMs + AIBossReinforcementRollInitialMs()
        endif
        if AIDebugEnabled and AIDebugPassesFilter(u, w) then
            call AILogLimited("SPAWN w=" + I2S(w) + " ut=" + I2S(GetUnitTypeId(u)) + " owner=" + I2S(GetPlayerId(GetOwningPlayer(u))) + " profile=" + I2S(profileId) + " flags=" + I2S(behaviorFlags) + " threat=" + R2S(threatWeight))
        endif

        set u = null
    endfunction

    private function AIOnWaveExternal takes nothing returns nothing
        local unit u = GetWaveEventUnit()
        local Wave w = GetWaveEventWave()
        local WaveSlot s = GetWaveEventSlot()
        local integer profileId = 0
        local integer laneId = 0
        local integer behaviorFlags = 0
        local real threatWeight = 1.0

        if w == 0 or u == null then
            set u = null
            return
        endif

        if s != 0 then
            set profileId = s.aiProfileId
            set laneId = s.laneId
            set behaviorFlags = s.behaviorFlags
            set threatWeight = s.threatWeight
        endif

        if profileId <= 0 then
            set profileId = AIGetDefaultProfileForUnitType(GetUnitTypeId(u))
        endif
        if profileId <= 0 then
            set profileId = AI_DEFAULT_PROFILE_ID
        endif
        if behaviorFlags == 0 then
            set behaviorFlags = AIGetProfileDefaultFlags(profileId)
        endif
        if threatWeight <= 0.0 then
            set threatWeight = 1.0
        endif

        call AIAddOrUpdateUnit(u, w, profileId, laneId, behaviorFlags, threatWeight)
        if AIBossReinforcementSupportsUnitType(GetUnitTypeId(u)) then
            set AIBossReinforcementNextMs[GetHandleId(u)] = AIClockMs + AIBossReinforcementRollInitialMs()
        endif
        set u = null
    endfunction

    private function AIOnWaveDeath takes nothing returns nothing
        local unit u = GetWaveEventUnit()
        local integer hid
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("AIOnWaveDeath enter " + WaveDeathDebugContextSummary())
        endif

        if u == null then
            if WAVE_DEBUG_ENABLED then
                call WaveDebugLog("AIOnWaveDeath exit unit=null")
            endif
            return
        endif

        set hid = GetHandleId(u)
        if hid != 0 and AIIndexByUnit.has(hid) then
            call AIRemoveUnitByIndex(AIIndexByUnit[hid])
        endif

        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("AIOnWaveDeath exit " + WaveDeathDebugContextSummary())
        endif

        set u = null
    endfunction

    private function AIOnWavePause takes nothing returns nothing
        local Wave w = GetWaveEventWave()
        if w != 0 then
            set AIWaveIsPaused[w] = 1
        endif
    endfunction

    private function AIOnWaveResume takes nothing returns nothing
        local Wave w = GetWaveEventWave()
        if w != 0 then
            set AIWaveIsPaused[w] = 0
        endif
    endfunction

    private function AIOnWaveFinish takes nothing returns nothing
        local Wave w = GetWaveEventWave()
        if w != 0 then
            if AIDebugEnabled and (AIDebugWaveFilter == 0 or AIDebugWaveFilter == w) then
                call AILogLimited("FINISH w=" + I2S(w) + " cleanup")
            endif
            call AICleanupWave(w)
        endif
    endfunction

    private function AIOnWaveStart takes nothing returns nothing
        local Wave w = GetWaveEventWave()
        if w != 0 then
            set AIWaveIsActive[w] = 1
            set AIWaveIsPaused[w] = 0
            if not AIWaveUnitCount.has(w) then
                set AIWaveUnitCount[w] = 0
            endif
        endif
    endfunction

    function AIEnableWave takes integer waveId, boolean enabled returns nothing
        if waveId <= 0 then
            return
        endif
        if enabled then
            set AIWaveEnabledOverride[waveId] = 1
        else
            set AIWaveEnabledOverride[waveId] = 0
        endif
    endfunction

    function AISetDebug takes boolean enabled returns nothing
        set AIDebugEnabled = enabled
    endfunction

    function AISetDebugWaveFilter takes integer waveId returns nothing
        if waveId < 0 then
            set waveId = 0
        endif
        set AIDebugWaveFilter = waveId
    endfunction

    function AISetDebugUnitTypeFilter takes integer unitTypeId returns nothing
        set AIDebugUnitTypeFilter = unitTypeId
    endfunction

    function AISetDebugMaxLogsPerTick takes integer maxLogs returns nothing
        if maxLogs < 1 then
            set maxLogs = 1
        elseif maxLogs > 64 then
            set maxLogs = 64
        endif
        set AIDebugMaxLogsPerTick = maxLogs
    endfunction

    function AISetDynamicScheduler takes boolean enabled returns nothing
        set AIUseDynamicScheduler = enabled
    endfunction

    function AISetFixedTickMs takes integer ms returns nothing
        set AIFixedTickMs = AIClampInt(ms, AI_MIN_TICK_MS, AI_MAX_TICK_MS)
    endfunction

    function AISetFixedBudget takes integer budget returns nothing
        set AIFixedBudget = AIClampInt(budget, AI_MIN_BUDGET_PER_TICK, AI_MAX_BUDGET_PER_TICK)
    endfunction

    function AIGetCurrentTickMs takes nothing returns integer
        return AICurrentTickMs
    endfunction

    function AIGetCurrentBudget takes nothing returns integer
        return AICurrentBudget
    endfunction

    // true: si no hay heroes registrados, usa GroupEnumUnitsInRange (modo compatible).
    // false: si no hay heroes registrados, no hace fallback por grupo (modo estricto/optimizado).
    function AISetUseGroupFallbackNoHeroes takes boolean enabled returns nothing
        set AIUseGroupFallbackNoHeroes = enabled
    endfunction

    // Registra héroe objetivo por player id (0..bj_MAX_PLAYER_SLOTS-1).
    // Cuando hay al menos uno registrado, el targeting evita GroupEnumUnitsInRange.
    function AISetTrackedHeroForPlayer takes integer playerId, unit hero returns nothing
        if playerId < 0 or playerId >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if hero != null and GetUnitTypeId(hero) == 0 then
            set hero = null
        endif
        set AITrackedHeroByPlayer[playerId] = hero
        call WaveRangedSkillsSetTrackedHeroForPlayer(playerId, hero)
        if AIDebugEnabled then
            if hero != null then
                call AILog("TrackedHero p=" + I2S(playerId) + " ut=" + I2S(GetUnitTypeId(hero)) + " owner=" + I2S(GetPlayerId(GetOwningPlayer(hero))))
            else
                call AILog("TrackedHero p=" + I2S(playerId) + " cleared")
            endif
        endif
    endfunction

    // Helper: registra por owner de la unidad.
    function AISetTrackedHero takes unit hero returns nothing
        if hero == null or GetUnitTypeId(hero) == 0 then
            return
        endif
        call AISetTrackedHeroForPlayer(GetPlayerId(GetOwningPlayer(hero)), hero)
    endfunction

    function AIClearTrackedHeroes takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set AITrackedHeroByPlayer[i] = null
            set i = i + 1
        endloop
    endfunction

    function AIDebugDumpTrackedHeroes takes nothing returns nothing
        local integer i = 0
        local unit u
        if not AIDebugEnabled then
            return
        endif
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set u = AITrackedHeroByPlayer[i]
            if u != null and GetUnitTypeId(u) != 0 then
                call BJDebugMsg("[IAManager] tracked[" + I2S(i) + "] ut=" + I2S(GetUnitTypeId(u)) + " owner=" + I2S(GetPlayerId(GetOwningPlayer(u))) + " alive=" + I2S(AIBoolToInt(UnitAlive(u))))
            else
                call BJDebugMsg("[IAManager] tracked[" + I2S(i) + "] = null")
            endif
            set i = i + 1
        endloop
        set u = null
    endfunction

    private function Init takes nothing returns nothing
        set AIUnitByIndex = Table.create()
        set AIIndexByUnit = Table.create()

        set AIUnitWaveId = Table.create()
        set AIUnitProfileId = Table.create()
        set AIUnitLaneId = Table.create()
        set AIUnitBehaviorFlags = Table.create()
        set AIUnitThreatWeight = Table.create()

        set AIUnitTarget = Table.create()
        set AIUnitNextRetargetMs = Table.create()
        set AIUnitNextOrderMs = Table.create()
        set AIUnitNextAbilityMs = Table.create()
        set AIUnitChannelLockUntilMs = Table.create()
        set AIUnitNextTeleportMs = Table.create()
        set AIUnitTeleportReadyMs = Table.create()
        set AIUnitNextDebugMs = Table.create()
        set AIUnitCooldownTables = Table.create()
        set AIUnitLastOrderType = Table.create()
        set AIUnitLastOrderTarget = Table.create()
        set AIUnitLastOrderX = Table.create()
        set AIUnitLastOrderY = Table.create()
        set AIBossReinforcementNextMs = Table.create()
        set AIBossReinforcementCastByUnit = Table.create()

        set AIWaveIsActive = Table.create()
        set AIWaveIsPaused = Table.create()
        set AIWaveUnitCount = Table.create()
        set AIWaveEnabledOverride = Table.create()

        set AITempGroup = CreateGroup()
        set AITimer = NewTimer()
        call SetTimerDebugTag(AITimer, TIMER_DEBUG_TAG_AI)
        set AIFixedTickMs = AIClampInt(AIFixedTickMs, AI_MIN_TICK_MS, AI_MAX_TICK_MS)
        set AIFixedBudget = AIClampInt(AIFixedBudget, AI_MIN_BUDGET_PER_TICK, AI_MAX_BUDGET_PER_TICK)
        set AICurrentTickMs = AIFixedTickMs
        set AICurrentBudget = AIFixedBudget
        set AINextPerfLogMs = 0
        call TimerStart(AITimer, I2R(AICurrentTickMs)*0.001, false, function AIOnTick)

        call RegisterWaveStartEvent(function AIOnWaveStart)
        call RegisterWaveSpawnEvent(function AIOnWaveSpawn)
        call RegisterWaveExternalEvent(function AIOnWaveExternal)
        call RegisterWaveDeathEvent(function AIOnWaveDeath)
        call RegisterWavePauseEvent(function AIOnWavePause)
        call RegisterWaveResumeEvent(function AIOnWaveResume)
        call RegisterWaveFinishEvent(function AIOnWaveFinish)

        call AILog("Initialized")
    endfunction
endlibrary

