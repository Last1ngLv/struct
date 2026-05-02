library WaveStreaks initializer Init requires Table, TimerUtils, PlayerUtils, WaveTest, SelectionSystem, WaveDamageCredit, PlayerHeroState, PrisonerDropSystem

    globals
        private constant integer WAVE_STREAK_MAX_TIERS = 8
        private constant integer WAVE_MULTI_MAX_TIERS = 4
        private constant integer WAVE_STREAK_QUEUE_MAX = 256
        private constant real WAVE_STREAK_QUEUE_TICK = 0.03125
        private constant real WAVE_STREAK_MESSAGE_DURATION = 3.00
        private constant integer WAVE_QUEUE_KIND_GENERIC = 0
        private constant integer WAVE_QUEUE_KIND_FIRST_BLOOD = 1
        private constant integer WAVE_QUEUE_KIND_STREAK = 2
        private constant integer WAVE_QUEUE_KIND_MULTI = 3
        private constant integer WAVE_QUEUE_KIND_BREAK_STREAK = 4
        private constant integer WAVE_QUEUE_KIND_BREAK_MULTI = 5
        private constant integer WAVE_QUEUE_KIND_WAVE_FINISHER = 6
        private constant real WAVE_DEFAULT_MULTI_WINDOW = 5.00
        private constant real WAVE_DEFAULT_QUEUE_GAP = 1.30 

        private constant string WAVE_DEFAULT_SOUND_FIRST_BLOOD = "war3mapImported\\announcer_1stblood_01.wav"
        private constant string WAVE_DEFAULT_SOUND_STREAK_BREAK = "war3mapImported\\RDK_RompeRacha.mp3"
        private constant string WAVE_DEFAULT_SOUND_MULTI_BREAK_LOW = "war3mapImported\\RDK_RompeCombo1.mp3"
        private constant string WAVE_DEFAULT_SOUND_MULTI_BREAK_HIGH = "war3mapImported\\RDK_RompeCombo2.mp3"
        private constant string WAVE_DEFAULT_SOUND_WAVE_FINISHER = "war3mapImported\\te matee.wav"

        private constant string WAVE_DEFAULT_SOUND_STREAK_1 = "war3mapImported\\announcer_kill_spree_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_STREAK_2 = "war3mapImported\\announcer_kill_dominate_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_STREAK_3 = "war3mapImported\\announcer_kill_mega_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_STREAK_4 = "war3mapImported\\announcer_kill_unstop_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_STREAK_5 = "war3mapImported\\announcer_kill_wicked_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_STREAK_6 = "war3mapImported\\announcer_kill_monster_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_STREAK_7 = "war3mapImported\\announcer_kill_godlike_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_STREAK_8 = "war3mapImported\\announcer_kill_holy_01.mp3"

        private constant string WAVE_DEFAULT_SOUND_MULTI_1 = "war3mapImported\\announcer_kill_double_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_MULTI_2 = "war3mapImported\\announcer_kill_triple_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_MULTI_3 = "war3mapImported\\announcer_kill_ultra_01.mp3"
        private constant string WAVE_DEFAULT_SOUND_MULTI_4 = "war3mapImported\\announcer_kill_rampage_01.mp3"

        private Table WaveFirstBloodDoneByWave
        private Table WaveFinisherDoneByWave

        private integer array WavePlayerStreakKills
        private integer array WavePlayerMultiKills
        private integer array WavePlayerTotalKills
        private integer array WavePlayerTotalDeaths
        private real array WavePlayerMultiExpireAt
        private integer array WavePlayerLastStreakTier
        private integer array WavePlayerLastMultiTier
        private integer array WavePlayerLastStreakAnnouncedKills
        private integer array WavePlayerLastMultiAnnouncedKills

        private integer array WaveStreakThresholds
        private integer array WaveMultiThresholds

        private string WaveStreakFirstBloodSoundPath = ""
        private string array WaveStreakKillSoundPath
        private string array WaveMultiKillSoundPath
        private string WaveStreakBreakSoundPath = ""
        private string WaveMultiBreakLowSoundPath = ""
        private string WaveMultiBreakHighSoundPath = ""
        private string WaveFinisherSoundPath = ""

        private real WaveMultiKillWindowSec = WAVE_DEFAULT_MULTI_WINDOW
        private real WaveQueueGapSec = WAVE_DEFAULT_QUEUE_GAP
        private real WaveQueueCooldown = 0.00

        private string array WaveQueueSoundPath
        private string array WaveQueueText
        private integer array WaveQueueKind
        private integer array WaveQueuePid
        private string array WaveQueueTmpSoundPath
        private string array WaveQueueTmpText
        private integer array WaveQueueTmpKind
        private integer array WaveQueueTmpPid
        private integer WaveQueueRead = 1
        private integer WaveQueueWrite = 1
        private integer WaveQueueCount = 0
        private timer WaveClockTimer = null
        private timer WaveQueueTimer = null
        private boolean WaveQueueRunning = false
    endglobals

    private function WaveNow takes nothing returns real
        return TimerGetElapsed(WaveClockTimer)
    endfunction

    private function WaveClockNoop takes nothing returns nothing
    endfunction

    private function WaveWrapQueueIndex takes integer i returns integer
        if i > WAVE_STREAK_QUEUE_MAX then
            return 1
        endif
        return i
    endfunction

    private function WaveBroadcastText takes string msg returns nothing
        local integer i = 0
        local User u
        if msg == null or msg == "" then
            return
        endif
        loop
            exitwhen i >= User.AmountPlaying
            set u = User.fromPlaying(i)
            call DisplayTimedTextToPlayer(u.toPlayer(), 0.0, 0.0, WAVE_STREAK_MESSAGE_DURATION, msg)
            set i = i + 1
        endloop
    endfunction

    private function WavePlaySoundGlobal takes string path returns nothing
        local sound s
        if path == null or path == "" then
            return
        endif
        set s = CreateSound(path, false, false, false, 10, 10, "")
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    private function WaveQueuePopAndEmit takes nothing returns nothing
        local integer idx
        local string soundPath
        local string msg

        if WaveQueueCount <= 0 then
            return
        endif

        set idx = WaveQueueRead
        set WaveQueueRead = WaveWrapQueueIndex(WaveQueueRead + 1)
        set WaveQueueCount = WaveQueueCount - 1

        set soundPath = WaveQueueSoundPath[idx]
        set msg = WaveQueueText[idx]
        set WaveQueueSoundPath[idx] = ""
        set WaveQueueText[idx] = ""
        set WaveQueueKind[idx] = WAVE_QUEUE_KIND_GENERIC
        set WaveQueuePid[idx] = -1

        call WaveBroadcastText(msg)
        call WavePlaySoundGlobal(soundPath)
    endfunction

    private function WaveQueueOnTick takes nothing returns nothing
        if WaveQueueCount <= 0 then
            set WaveQueueRunning = false
            call PauseTimer(WaveQueueTimer)
            return
        endif

        if WaveQueueCooldown > 0.00 then
            set WaveQueueCooldown = WaveQueueCooldown - WAVE_STREAK_QUEUE_TICK
            return
        endif

        call WaveQueuePopAndEmit()
        set WaveQueueCooldown = WaveQueueGapSec
    endfunction

    private function WaveQueueDropPendingByKindAndPid takes integer kind, integer pid returns nothing
        local integer i = 0
        local integer idx = WaveQueueRead
        local integer kept = 0
        local integer writeIdx

        if WaveQueueCount <= 0 then
            return
        endif

        loop
            exitwhen i >= WaveQueueCount
            if not (WaveQueueKind[idx] == kind and WaveQueuePid[idx] == pid) then
                set kept = kept + 1
                set WaveQueueTmpSoundPath[kept] = WaveQueueSoundPath[idx]
                set WaveQueueTmpText[kept] = WaveQueueText[idx]
                set WaveQueueTmpKind[kept] = WaveQueueKind[idx]
                set WaveQueueTmpPid[kept] = WaveQueuePid[idx]
            endif
            set WaveQueueSoundPath[idx] = ""
            set WaveQueueText[idx] = ""
            set WaveQueueKind[idx] = WAVE_QUEUE_KIND_GENERIC
            set WaveQueuePid[idx] = -1
            set idx = WaveWrapQueueIndex(idx + 1)
            set i = i + 1
        endloop

        set WaveQueueRead = 1
        set WaveQueueWrite = 1
        set WaveQueueCount = 0
        set i = 1
        loop
            exitwhen i > kept
            set writeIdx = WaveQueueWrite
            set WaveQueueSoundPath[writeIdx] = WaveQueueTmpSoundPath[i]
            set WaveQueueText[writeIdx] = WaveQueueTmpText[i]
            set WaveQueueKind[writeIdx] = WaveQueueTmpKind[i]
            set WaveQueuePid[writeIdx] = WaveQueueTmpPid[i]
            set WaveQueueWrite = WaveWrapQueueIndex(WaveQueueWrite + 1)
            set WaveQueueCount = WaveQueueCount + 1
            set i = i + 1
        endloop
    endfunction

    private function WaveQueuePushTyped takes string soundPath, string msg, integer kind, integer pid returns nothing
        local integer idx
        if (soundPath == null or soundPath == "") and (msg == null or msg == "") then
            return
        endif

        set idx = WaveQueueWrite
        set WaveQueueSoundPath[idx] = soundPath
        set WaveQueueText[idx] = msg
        set WaveQueueKind[idx] = kind
        set WaveQueuePid[idx] = pid
        set WaveQueueWrite = WaveWrapQueueIndex(WaveQueueWrite + 1)

        if WaveQueueCount < WAVE_STREAK_QUEUE_MAX then
            set WaveQueueCount = WaveQueueCount + 1
        else
            // Cola llena: descarta el m?s viejo.
            set WaveQueueRead = WaveWrapQueueIndex(WaveQueueRead + 1)
        endif

        if not WaveQueueRunning then
            set WaveQueueRunning = true
            set WaveQueueCooldown = 0.00
            call TimerStart(WaveQueueTimer, WAVE_STREAK_QUEUE_TICK, true, function WaveQueueOnTick)
        endif
    endfunction

    private function WaveGetStreakTier takes integer kills returns integer
        local integer t = WAVE_STREAK_MAX_TIERS
        loop
            exitwhen t <= 0
            if kills >= WaveStreakThresholds[t] then
                return t
            endif
            set t = t - 1
        endloop
        return 0
    endfunction

    private function WaveGetMultiTier takes integer kills returns integer
        local integer t = WAVE_MULTI_MAX_TIERS
        loop
            exitwhen t <= 0
            if kills >= WaveMultiThresholds[t] then
                return t
            endif
            set t = t - 1
        endloop
        return 0
    endfunction

    private function WaveGetStreakMaxRepeatStep takes nothing returns integer
        local integer step = WaveStreakThresholds[WAVE_STREAK_MAX_TIERS] - WaveStreakThresholds[WAVE_STREAK_MAX_TIERS - 1]
        if step < 1 then
            set step = 1
        endif
        return step
    endfunction

    private function WaveGetMultiMaxRepeatStep takes nothing returns integer
        local integer step = WaveMultiThresholds[WAVE_MULTI_MAX_TIERS] - WaveMultiThresholds[WAVE_MULTI_MAX_TIERS - 1]
        if step < 1 then
            set step = 1
        endif
        return step
    endfunction

    private function WaveGetStreakTierName takes integer tier returns string
        if tier <= 1 then
            return "Killing Spree"
        elseif tier == 2 then
            return "Dominating"
        elseif tier == 3 then
            return "Mega Kill"
        elseif tier == 4 then
            return "Unstoppable"
        elseif tier == 5 then
            return "Wicked Sick"
        elseif tier == 6 then
            return "Monster Kill"
        elseif tier == 7 then
            return "Godlike"
        endif
        return "Beyond Godlike"
    endfunction

    private function WaveGetMultiTierName takes integer tier returns string
        if tier <= 1 then
            return "Double Kill"
        elseif tier == 2 then
            return "Triple Kill"
        elseif tier == 3 then
            return "Ultra Kill"
        endif
        return "Rampage"
    endfunction

    private function WaveGetOwnerPlayerId takes unit u returns integer
        local integer pid
        local integer hid
        if u == null then
            return -1
        endif
        set hid = GetHandleId(u)
        if hid != 0 and WaveExternalOwnerPidByUnit.has(hid) then
            set pid = WaveExternalOwnerPidByUnit[hid]
        else
            set pid = GetPlayerId(GetOwningPlayer(u))
        endif
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return -1
        endif
        // Los owners default del sistema wave tambi?n deben contar para rachas,
        // aunque no est?n en la lista de jugadores humanos activos.
        if WaveIsDefaultOwnerPlayerId(pid) then
            return pid
        endif
        // Para el resto de jugadores, solo creditamos si est?n realmente activos.
        if not User.fromIndex(pid).isPlaying then
            return -1
        endif
        return pid
    endfunction

    private function WaveGetHeroPlayerId takes unit hero returns integer
        local integer pid
        if hero == null then
            return -1
        endif
        set pid = GetPlayerId(GetOwningPlayer(hero))
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return -1
        endif
        if PlayerHero[pid] != hero then
            return -1
        endif
        return pid
    endfunction

    private function WaveResetPlayerState takes integer pid returns nothing
        set WavePlayerStreakKills[pid] = 0
        set WavePlayerMultiKills[pid] = 0
        set WavePlayerMultiExpireAt[pid] = 0.0
        set WavePlayerLastStreakTier[pid] = 0
        set WavePlayerLastMultiTier[pid] = 0
        set WavePlayerLastStreakAnnouncedKills[pid] = 0
        set WavePlayerLastMultiAnnouncedKills[pid] = 0
    endfunction

    private function WaveGetPlayerNameColoredById takes integer pid returns string
        local User u
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return "Player " + I2S(pid)
        endif
        set u = User.fromIndex(pid)
        if u.isPlaying then
            return u.nameColored
        endif
        return GetPlayerName(Player(pid))
    endfunction

    private function WaveFormatKillUnits takes integer kills returns string
        return I2S(kills) + " kill units"
    endfunction

    private function WaveQueueFirstBlood takes integer pid, integer waveId returns nothing
        call WaveQueuePushTyped(WaveStreakFirstBloodSoundPath, WaveGetPlayerNameColoredById(pid) + " |cffff3333FIRST BLOOD|r (Wave " + I2S(waveId) + ")", WAVE_QUEUE_KIND_FIRST_BLOOD, pid)
    endfunction

    private function WaveQueueFinisher takes integer pid, integer waveId returns nothing
        call WaveQueuePushTyped(WaveFinisherSoundPath, WaveGetPlayerNameColoredById(pid) + " |cff33ff66termino la Wave " + I2S(waveId) + "|r matando al ultimo enemigo", WAVE_QUEUE_KIND_WAVE_FINISHER, pid)
        set WaveQueueCooldown = 0.00
    endfunction

    private function WaveQueueStreakTier takes integer pid, integer tier, integer kills returns nothing
        call WaveQueueDropPendingByKindAndPid(WAVE_QUEUE_KIND_STREAK, pid)
        call WaveQueuePushTyped(WaveStreakKillSoundPath[tier], WaveGetPlayerNameColoredById(pid) + " |cffffff00" + WaveGetStreakTierName(tier) + "|r (" + WaveFormatKillUnits(kills) + ")", WAVE_QUEUE_KIND_STREAK, pid)
        set WaveQueueCooldown = 0.00
    endfunction

    private function WaveQueueMultiTier takes integer pid, integer tier, integer kills returns nothing
        call WaveQueueDropPendingByKindAndPid(WAVE_QUEUE_KIND_MULTI, pid)
        call WaveQueuePushTyped(WaveMultiKillSoundPath[tier], WaveGetPlayerNameColoredById(pid) + " |cff66ccff" + WaveGetMultiTierName(tier) + "|r (" + WaveFormatKillUnits(kills) + ")", WAVE_QUEUE_KIND_MULTI, pid)
        set WaveQueueCooldown = 0.00
    endfunction

    private function WaveQueueBreakStreak takes integer pid, integer kills returns nothing
        call WaveQueuePushTyped(WaveStreakBreakSoundPath, WaveGetPlayerNameColoredById(pid) + " |cffff6666perdió su racha|r (" + I2S(kills) + ")", WAVE_QUEUE_KIND_BREAK_STREAK, pid)
    endfunction

    private function WaveQueueBreakMulti takes integer pid, integer tier returns nothing
        if tier <= 2 then
            call WaveQueuePushTyped(WaveMultiBreakLowSoundPath, WaveGetPlayerNameColoredById(pid) + " |cff66ccffperdió su multi kill|r (I-II)", WAVE_QUEUE_KIND_BREAK_MULTI, pid)
        else
            call WaveQueuePushTyped(WaveMultiBreakHighSoundPath, WaveGetPlayerNameColoredById(pid) + " |cff66ccffperdió su multi kill|r (III-IV)", WAVE_QUEUE_KIND_BREAK_MULTI, pid)
        endif
    endfunction

    private function WaveStreakOnWaveStart takes nothing returns nothing
        local Wave w = GetWaveEventWave()
        if w != 0 then
            set WaveFirstBloodDoneByWave[w] = 0
            set WaveFinisherDoneByWave[w] = 0
        endif
    endfunction

    private function WaveStreakOnWaveFinish takes nothing returns nothing
        local Wave w = GetWaveEventWave()
        if w != 0 and WaveFirstBloodDoneByWave.has(w) then
            call WaveFirstBloodDoneByWave.remove(w)
        endif
        if w != 0 and WaveFinisherDoneByWave.has(w) then
            call WaveFinisherDoneByWave.remove(w)
        endif
    endfunction

    private function WaveStreakOnWaveDeath takes nothing returns nothing
        local unit dead = GetWaveEventUnit()
        local unit killer = GetWaveEventKiller()
        local Wave w = GetWaveEventWave()
        local integer waveId = w
        local integer pid = -1
        local integer killerPid = -1
        local integer fallbackPid = -1
        local integer streakTier
        local integer multiTier
        local integer repeatStep
        local string resolutionState = "native"
        local string returnReason = "none"
        local boolean eventExternal = IsWaveEventExternal()
        local boolean eventBoss = IsWaveEventBoss()

        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveStreakOnWaveDeath enter " + WaveDeathDebugContextSummary())
        endif
        set killerPid = WaveGetOwnerPlayerId(killer)
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveStreakOnWaveDeath after killerPid pid=" + I2S(killerPid) + " w=" + I2S(waveId) + " dead=" + WaveDebugUnitSummary(dead) + " killer=" + WaveDebugUnitSummary(killer))
        endif
        if killerPid >= 0 then
            set pid = killerPid
        else
            set resolutionState = "fallback"
            // Native killer resolution failed (proxy/script damage), fall back
            // to the last tracked damage credit for this dead wave unit.
            set fallbackPid = WaveGetDamageCreditOwnerPid(dead)
            set pid = fallbackPid
        endif
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveStreakOnWaveDeath after fallback pid=" + I2S(pid) + " fallbackPid=" + I2S(fallbackPid) + " resolution=" + resolutionState + " w=" + I2S(waveId))
        endif
        call WaveClearDamageCredit(dead)
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveStreakOnWaveDeath after clear damage credit w=" + I2S(waveId) + " dead=" + WaveDebugUnitSummary(dead))
        endif
        if pid < 0 then
            set returnReason = "pid_unresolved_after_fallback"
        endif
        if WAVE_DEBUG_ENABLED and (eventExternal or eventBoss or killerPid < 0 or pid < 0) then
            call WaveDebugLog("WaveStreakOnWaveDeath w=" + I2S(waveId) + " dead=" + WaveDebugUnitSummary(dead) + " killer=" + WaveDebugUnitSummary(killer) + " killerPid=" + I2S(killerPid) + " fallbackPid=" + I2S(fallbackPid) + " resolvedPid=" + I2S(pid) + " resolution=" + resolutionState + " external=" + I2S(WaveDebugBoolToInt(eventExternal)) + " boss=" + I2S(WaveDebugBoolToInt(eventBoss)) + " return=" + returnReason)
        endif
        if pid < 0 then
            return
        endif
        call PrisonerDropTrySpawnForPid(dead, pid)

        // First Blood por wave (solo heroe -> wave).
        if waveId != 0 then
            if (not WaveFirstBloodDoneByWave.has(waveId)) or WaveFirstBloodDoneByWave[waveId] == 0 then
                set WaveFirstBloodDoneByWave[waveId] = 1
                call WaveQueueFirstBlood(pid, waveId)
            endif
            if w.getToKillRemaining() <= 0 and ((not WaveFinisherDoneByWave.has(waveId)) or WaveFinisherDoneByWave[waveId] == 0) then
                set WaveFinisherDoneByWave[waveId] = 1
                call WaveQueueFinisher(pid, waveId)
            endif
        endif

        if User.fromIndex(pid).isPlaying then
            set WavePlayerTotalKills[pid] = WavePlayerTotalKills[pid] + 1
        endif

        // Kill streak.
        set WavePlayerStreakKills[pid] = WavePlayerStreakKills[pid] + 1
        set streakTier = WaveGetStreakTier(WavePlayerStreakKills[pid])
        if streakTier > WavePlayerLastStreakTier[pid] then
            call WaveQueueStreakTier(pid, streakTier, WavePlayerStreakKills[pid])
            set WavePlayerLastStreakTier[pid] = streakTier
            set WavePlayerLastStreakAnnouncedKills[pid] = WavePlayerStreakKills[pid]
        elseif streakTier == WAVE_STREAK_MAX_TIERS and WavePlayerLastStreakTier[pid] == WAVE_STREAK_MAX_TIERS then
            set repeatStep = WaveGetStreakMaxRepeatStep()
            if WavePlayerStreakKills[pid] >= WavePlayerLastStreakAnnouncedKills[pid] + repeatStep then
                call WaveQueueStreakTier(pid, streakTier, WavePlayerStreakKills[pid])
                set WavePlayerLastStreakAnnouncedKills[pid] = WavePlayerStreakKills[pid]
            endif
        endif

        // Multi kill (orden: streak primero, luego multikill).
        if WaveNow() <= WavePlayerMultiExpireAt[pid] then
            set WavePlayerMultiKills[pid] = WavePlayerMultiKills[pid] + 1
        else
            set WavePlayerMultiKills[pid] = 1
            set WavePlayerLastMultiTier[pid] = 0
            set WavePlayerLastMultiAnnouncedKills[pid] = 0
        endif
        set WavePlayerMultiExpireAt[pid] = WaveNow() + WaveMultiKillWindowSec

        set multiTier = WaveGetMultiTier(WavePlayerMultiKills[pid])
        if multiTier > WavePlayerLastMultiTier[pid] then
            call WaveQueueMultiTier(pid, multiTier, WavePlayerMultiKills[pid])
            set WavePlayerLastMultiTier[pid] = multiTier
            set WavePlayerLastMultiAnnouncedKills[pid] = WavePlayerMultiKills[pid]
        elseif multiTier == WAVE_MULTI_MAX_TIERS and WavePlayerLastMultiTier[pid] == WAVE_MULTI_MAX_TIERS then
            set repeatStep = WaveGetMultiMaxRepeatStep()
            if WavePlayerMultiKills[pid] >= WavePlayerLastMultiAnnouncedKills[pid] + repeatStep then
                call WaveQueueMultiTier(pid, multiTier, WavePlayerMultiKills[pid])
                set WavePlayerLastMultiAnnouncedKills[pid] = WavePlayerMultiKills[pid]
            endif
        endif
        if WAVE_DEBUG_ENABLED then
            call WaveDebugLog("WaveStreakOnWaveDeath exit " + WaveDeathDebugContextSummary() + " pid=" + I2S(pid) + " resolution=" + resolutionState + " return=" + returnReason)
        endif
    endfunction

    private function WaveStreakOnAnyDeath takes nothing returns nothing
        local unit dead = GetTriggerUnit()
        local unit killer = GetKillingUnit()
        local integer pid = WaveGetHeroPlayerId(dead)
        local integer multiTier

        if pid < 0 then
            set dead = null
            set killer = null
            return
        endif

        set multiTier = 0
        if WaveNow() <= WavePlayerMultiExpireAt[pid] then
            set multiTier = WaveGetMultiTier(WavePlayerMultiKills[pid])
        endif

        if multiTier > 0 then
            call WaveQueueBreakMulti(pid, multiTier)
        elseif WavePlayerStreakKills[pid] > 0 then
            call WaveQueueBreakStreak(pid, WavePlayerStreakKills[pid])
        endif

        set WavePlayerTotalDeaths[pid] = WavePlayerTotalDeaths[pid] + 1
        call WaveResetPlayerState(pid)

        set dead = null
        set killer = null
    endfunction

    function GetWavePlayerCurrentStreak takes integer pid returns integer
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return 0
        endif
        return WavePlayerStreakKills[pid]
    endfunction

    function GetWavePlayerCurrentMulti takes integer pid returns integer
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return 0
        endif
        if WaveNow() > WavePlayerMultiExpireAt[pid] then
            return 0
        endif
        return WavePlayerMultiKills[pid]
    endfunction

    function GetWavePlayerTotalKills takes integer pid returns integer
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return 0
        endif
        return WavePlayerTotalKills[pid]
    endfunction

    function GetWavePlayerTotalDeaths takes integer pid returns integer
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return 0
        endif
        return WavePlayerTotalDeaths[pid]
    endfunction

    function SetWaveStreakMultiKillWindow takes real sec returns nothing
        if sec < 0.10 then
            set sec = 0.10
        endif
        set WaveMultiKillWindowSec = sec
    endfunction

    function SetWaveStreakQueueGap takes real sec returns nothing
        if sec < 0.00 then
            set sec = 0.00
        endif
        set WaveQueueGapSec = sec
    endfunction

    function SetWaveStreakFirstBloodSound takes string path returns nothing
        set WaveStreakFirstBloodSoundPath = path
    endfunction

    function SetWaveStreakKillStreakSound takes integer tier, string path returns nothing
        if tier < 1 or tier > WAVE_STREAK_MAX_TIERS then
            return
        endif
        set WaveStreakKillSoundPath[tier] = path
    endfunction

    function SetWaveStreakMultiKillSound takes integer tier, string path returns nothing
        if tier < 1 or tier > WAVE_MULTI_MAX_TIERS then
            return
        endif
        set WaveMultiKillSoundPath[tier] = path
    endfunction

    function SetWaveStreakBreakSound takes string path returns nothing
        set WaveStreakBreakSoundPath = path
    endfunction

    function SetWaveStreakMultiBreakLowSound takes string path returns nothing
        set WaveMultiBreakLowSoundPath = path
    endfunction

    function SetWaveStreakMultiBreakHighSound takes string path returns nothing
        set WaveMultiBreakHighSoundPath = path
    endfunction

    function SetWaveStreakFinisherSound takes string path returns nothing
        set WaveFinisherSoundPath = path
    endfunction

    function SetWaveStreakKillStreakThreshold takes integer tier, integer kills returns nothing
        if tier < 1 or tier > WAVE_STREAK_MAX_TIERS then
            return
        endif
        if kills < 1 then
            set kills = 1
        endif
        set WaveStreakThresholds[tier] = kills
    endfunction

    function SetWaveStreakMultiKillThreshold takes integer tier, integer kills returns nothing
        if tier < 1 or tier > WAVE_MULTI_MAX_TIERS then
            return
        endif
        if kills < 1 then
            set kills = 1
        endif
        set WaveMultiThresholds[tier] = kills
    endfunction

    function SetWaveStreakKillStreakStep takes integer killsPerTier returns nothing
        local integer tier = 1
        if killsPerTier < 1 then
            set killsPerTier = 1
        endif
        loop
            exitwhen tier > WAVE_STREAK_MAX_TIERS
            call SetWaveStreakKillStreakThreshold(tier, tier*killsPerTier)
            set tier = tier + 1
        endloop
    endfunction

    function SetWaveStreakMultiKillStep takes integer killsPerTier returns nothing
        local integer tier = 1
        if killsPerTier < 1 then
            set killsPerTier = 1
        endif
        loop
            exitwhen tier > WAVE_MULTI_MAX_TIERS
            call SetWaveStreakMultiKillThreshold(tier, tier*killsPerTier)
            set tier = tier + 1
        endloop
    endfunction

    // Config default centralizada en este sistema para evitar dependencias circulares.
    private function ApplyWaveStreakDefaultConfig takes nothing returns nothing
        // Ventanas de tiempo
        call SetWaveStreakMultiKillWindow(WAVE_DEFAULT_MULTI_WINDOW)
        call SetWaveStreakQueueGap(WAVE_DEFAULT_QUEUE_GAP)

        // Sonidos globales
        call SetWaveStreakFirstBloodSound(WAVE_DEFAULT_SOUND_FIRST_BLOOD)
        call SetWaveStreakBreakSound(WAVE_DEFAULT_SOUND_STREAK_BREAK)
        call SetWaveStreakMultiBreakLowSound(WAVE_DEFAULT_SOUND_MULTI_BREAK_LOW)
        call SetWaveStreakMultiBreakHighSound(WAVE_DEFAULT_SOUND_MULTI_BREAK_HIGH)
        call SetWaveStreakFinisherSound(WAVE_DEFAULT_SOUND_WAVE_FINISHER)

        // Kill Streak (8 escalones)
        call SetWaveStreakKillStreakSound(1, WAVE_DEFAULT_SOUND_STREAK_1)
        call SetWaveStreakKillStreakSound(2, WAVE_DEFAULT_SOUND_STREAK_2)
        call SetWaveStreakKillStreakSound(3, WAVE_DEFAULT_SOUND_STREAK_3)
        call SetWaveStreakKillStreakSound(4, WAVE_DEFAULT_SOUND_STREAK_4)
        call SetWaveStreakKillStreakSound(5, WAVE_DEFAULT_SOUND_STREAK_5)
        call SetWaveStreakKillStreakSound(6, WAVE_DEFAULT_SOUND_STREAK_6)
        call SetWaveStreakKillStreakSound(7, WAVE_DEFAULT_SOUND_STREAK_7)
        call SetWaveStreakKillStreakSound(8, WAVE_DEFAULT_SOUND_STREAK_8)

        // Multi Kill (4 escalones)
        call SetWaveStreakMultiKillSound(1, WAVE_DEFAULT_SOUND_MULTI_1)
        call SetWaveStreakMultiKillSound(2, WAVE_DEFAULT_SOUND_MULTI_2)
        call SetWaveStreakMultiKillSound(3, WAVE_DEFAULT_SOUND_MULTI_3)
        call SetWaveStreakMultiKillSound(4, WAVE_DEFAULT_SOUND_MULTI_4)

        // Escalones por step configurable
        call SetWaveStreakKillStreakStep(30)
        call SetWaveStreakMultiKillStep(10)
    endfunction

    private function Init takes nothing returns nothing
        local trigger t = CreateTrigger()
        local integer i = 0

        set WaveFirstBloodDoneByWave = Table.create()
        set WaveFinisherDoneByWave = Table.create()
        set WaveClockTimer = NewTimer()
        set WaveQueueTimer = NewTimer()
        call SetTimerDebugTag(WaveClockTimer, TIMER_DEBUG_TAG_WAVE_CORE)
        call SetTimerDebugTag(WaveQueueTimer, TIMER_DEBUG_TAG_WAVE_CORE)
        call TimerStart(WaveClockTimer, 999999.0, false, function WaveClockNoop)

        call ApplyWaveStreakDefaultConfig()

        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            call WaveResetPlayerState(i)
            call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_DEATH, null)
            set i = i + 1
        endloop
        call TriggerAddAction(t, function WaveStreakOnAnyDeath)

        call RegisterWaveStartEvent(function WaveStreakOnWaveStart)
        call RegisterWaveFinishEvent(function WaveStreakOnWaveFinish)
        call RegisterWaveDeathEvent(function WaveStreakOnWaveDeath)
    endfunction

endlibrary

