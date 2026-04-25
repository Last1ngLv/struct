library WaveMultiboard requires WaveTest, PlayerUtils, TimerUtils, TextTagDebug, HealthBarTextTags, HeroLives, WaveStreaks
    globals
        private constant integer MB_MAX_PLAYERS = 8
        private constant integer MB_COLUMN_COUNT = 7
        private constant integer MB_ROW_COUNT = 13
        private constant integer MB_ROW_WAVE = 0
        private constant integer MB_ROW_PLAYER_START = 1
        private constant integer MB_ROW_DEBUG_TIMER = 9
        private constant integer MB_ROW_DEBUG_LOADOUT = 10
        private constant integer MB_ROW_DEBUG_SYSTEMS = 11
        private constant integer MB_ROW_DEBUG_TEXTTAGS = 12
    endglobals

    private function MBSetCell takes multiboard board, integer row, integer column, string value, real width returns nothing
        local multiboarditem boardItem = MultiboardGetItem(board, row, column)
        call MultiboardSetItemStyle(boardItem, true, false)
        call MultiboardSetItemWidth(boardItem, width)
        call MultiboardSetItemValue(boardItem, value)
        call MultiboardReleaseItem(boardItem)
        set boardItem = null
    endfunction

    private function MBEnsureLayout takes multiboard board returns nothing
        if board == null then
            return
        endif
        if MultiboardGetColumnCount(board) != MB_COLUMN_COUNT then
            call MultiboardSetColumnCount(board, MB_COLUMN_COUNT)
        endif
        if MultiboardGetRowCount(board) != MB_ROW_COUNT then
            call MultiboardSetRowCount(board, MB_ROW_COUNT)
        endif
    endfunction

    private function MBWaveStateText takes Wave w returns string
        if w.isDestroyed or w.isFinishing then
            return "|cFFB0B0B0Finalizada|r"
        endif
        if w.isPaused then
            return "|cFFFFFF00Pausada|r"
        endif
        if w.isRunning then
            return "|cFF66FF99Activa|r"
        endif
        return "|cFFC0C0C0Inactiva|r"
    endfunction

    private function MBWaveTitle takes Wave w returns string
        return MBWaveStateText(w) + " |cFFFFFFFFWave |r|cFFE6E6E6" + I2S(w.waveIndex) + "|r|cFFFF8C00/|r|cFFE6E6E6" + I2S(w.waveTotal) + "|r |cFFFFFFFF| |r |cFFFFFFFFToKill |r|cFFFF3333" + I2S(w.totalKilled) + "|r|cFFFF8C00/|r|cFFCC66FF" + I2S(w.totalToSpawn) + "|r"
    endfunction

    private function MBWaveCell takes Wave w returns string
        return "|cFFE6E6E6W|r|cFFC0C0C0a|r|cFF8C8C8Cv|r|cFF707070e|r|cFFFFFFFF: |r|cFFE6E6E6" + I2S(w.waveIndex) + "|r|cFFFF8C00/|r|cFFC0C0C0" + I2S(w.waveTotal) + "|r"
    endfunction

    private function MBToSpawnCell takes Wave w returns string
        return "|cFFFFD700T|r|cFFFFC300o|r|cFFFFA500S|r|cFFFF8C00pawn|r|cFFFFFFFF: |r|cffff0000" + I2S(w.remainingUnits) + "|r|cFFFF8C00/|r|cFFFFD700" + I2S(w.remainingUnits + w.remainingBosses) + "|r|cFFFF8C00/|r|cFF0080FF" + I2S(w.remainingBosses) + "|r"
    endfunction

    private function MBUnitsCell takes Wave w returns string
        return "|cFFFF6666U|r|cFFFF4C4Cn|r|cFFFF3333i|r|cFFFF1A1At|r|cFFCC0000s|r|cFFFFFFFF: |r|cFFCC66FF" + I2S(w.killsDoneUnits) + "|r|cFFFF8C00/|r|cFF00FF00" + I2S(w.activeUnits) + "|r|cFFFF8C00/|r|cffff0000" + I2S(w.totalUnits) + "|r"
    endfunction

    private function MBBossCell takes Wave w returns string
        return "|cFF00FFFFB|r|cFF00E5FFo|r|cFF00CCFFs|r|cFF00B2FFs|r|cFFFFFFFF: |r|cFFCC66FF" + I2S(w.killsDoneBoss) + "|r|cFFFF8C00/|r|cFF00FF00" + I2S(w.activeBosses) + "|r|cFFFF8C00/|r|cFF0080FF" + I2S(w.totalBosses) + "|r"
    endfunction

    private function MBToKillCell takes Wave w returns string
        return "|cFFCC66FFT|r|cFFB24CFFo|r|cFF9933FFK|r|cFF7F1AFFill|r|cFFFFFFFF: |r|cFFFF3333" + I2S(w.totalKilled) + "|r|cFFFF8C00/|r|cFFCC66FF" + I2S(w.totalToSpawn) + "|r"
    endfunction

    private function MBOnMapCell takes Wave w returns string
        return "|cFF66FF99O|r|cFF4DFF88n|r|cFF33FF77M|r|cFF1AFF66a|r|cFF00CC55p|r|cFFFFFFFF: |r|cFF00FF00" + I2S(w.activeOnMap) + "|r"
    endfunction

    private function MBPlayerIsActive takes integer pid returns boolean
        if pid < 0 or pid >= MB_MAX_PLAYERS then
            return false
        endif
        return User.fromIndex(pid).isPlaying
    endfunction

    private function MBActivePlayerCount takes nothing returns integer
        local integer pid = 0
        local integer count = 0
        loop
            exitwhen pid >= MB_MAX_PLAYERS
            if MBPlayerIsActive(pid) then
                set count = count + 1
            endif
            set pid = pid + 1
        endloop
        return count
    endfunction

    private function MBPlayersCell takes nothing returns string
        return "|cFF66FF99Jug|r|cFFFFFFFF: |r|cFFFFFFCC" + I2S(MBActivePlayerCount()) + "|r|cFFFF8C00/|r|cFFFFFFCC" + I2S(MB_MAX_PLAYERS) + "|r"
    endfunction

    private function MBPlayerStatusText takes integer pid returns string
        if MBPlayerIsActive(pid) then
            return "|cFF66FF99Activo|r"
        endif
        return "|cFFFF6666Descon.|r"
    endfunction

    private function MBPlayerColorHex takes integer pid returns string
        if pid == 0 then
            return "|cffff0303"
        elseif pid == 1 then
            return "|cff0042ff"
        elseif pid == 2 then
            return "|cff1ce6b9"
        elseif pid == 3 then
            return "|cff540081"
        elseif pid == 4 then
            return "|cfffffc01"
        elseif pid == 5 then
            return "|cfffe8a0e"
        elseif pid == 6 then
            return "|cff20c000"
        elseif pid == 7 then
            return "|cffe55bb0"
        endif
        return "|cffffffff"
    endfunction

    private function MBPlayerSlotFallbackName takes integer pid returns string
        if pid == 0 then
            return "Rojo"
        elseif pid == 1 then
            return "Azul"
        elseif pid == 2 then
            return "Teal"
        elseif pid == 3 then
            return "Morado"
        elseif pid == 4 then
            return "Amarillo"
        elseif pid == 5 then
            return "Naranja"
        elseif pid == 6 then
            return "Verde"
        elseif pid == 7 then
            return "Rosa"
        endif
        return "Slot"
    endfunction

    private function MBPlayerNameText takes integer pid returns string
        local string playerName = GetPlayerName(Player(pid))
        if playerName == "" then
            set playerName = MBPlayerSlotFallbackName(pid)
        endif
        return MBPlayerColorHex(pid) + playerName + "|r"
    endfunction

    private function MBPlayerKillsText takes integer pid returns string
        return "|cFFFFFF00K|r|cFFFFFFFF: |r|cFFFFFFCC" + I2S(GetWavePlayerTotalKills(pid)) + "|r"
    endfunction

    private function MBPlayerStreakText takes integer pid returns string
        return "|cFFFF9933R|r|cFFFFFFFF: |r|cFFFFCC66" + I2S(GetWavePlayerCurrentStreak(pid)) + "|r"
    endfunction

    private function MBPlayerMultiText takes integer pid returns string
        return "|cFF66CCFFM|r|cFFFFFFFF: |r|cFF99E6FF" + I2S(GetWavePlayerCurrentMulti(pid)) + "|r"
    endfunction

    private function MBPlayerDeathsText takes integer pid returns string
        return "|cFFFF6666D|r|cFFFFFFFF: |r|cFFFFB3B3" + I2S(GetWavePlayerTotalDeaths(pid)) + "|r"
    endfunction

    private function MBPlayerLivesText takes integer pid returns string
        return "|cFF66FF99V|r|cFFFFFFFF: |r|cFFCCFFDD" + I2S(HeroLivesGetRemaining(pid)) + "|r"
    endfunction

    private function MBDebugInUse takes nothing returns string
        return "|cFF66CCFFInUse|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerUtilsInUse()) + "|r"
    endfunction

    private function MBDebugCap takes nothing returns string
        return "|cFF66FF99Cap|r|cFFFFFFFF: |r|cFFCCFFDD" + I2S(GetTimerUtilsCapacity()) + "|r"
    endfunction

    private function MBDebugPeak takes nothing returns string
        return "|cFFFFCC66Peak|r|cFFFFFFFF: |r|cFFFFE0B3" + I2S(GetTimerUtilsPeakInUse()) + "|r"
    endfunction

    private function MBDebugAvail takes nothing returns string
        return "|cFF9999FFAvail|r|cFFFFFFFF: |r|cFFD6D6FF" + I2S(GetTimerUtilsAvailable()) + "|r"
    endfunction

    private function MBLoadoutDebugCell takes string label, string color, integer tag returns string
        return color + label + "|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(tag)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(tag)) + "|r"
    endfunction

    private function MBTaggedDebugCell takes string label, string color, integer tag returns string
        return color + label + "|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(tag)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(tag)) + "|r"
    endfunction

    private function MBTextTagTotalCell takes string label, string color, integer liveValue, integer peakValue returns string
        return color + label + "|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(liveValue) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(peakValue) + "|r"
    endfunction

    function BMT1 takes nothing returns nothing
        local Wave w
        local integer row
        local integer pid

        if CurrentBoardContext == null then
            return
        endif

        set w = WaveByBoard[GetHandleId(CurrentBoardContext)]
        if w == 0 then
            return
        endif

        call MBEnsureLayout(w.board)
        call MultiboardSetTitleText(w.board, MBWaveTitle(w))

        // Row 0: metricas completas de la wave con layout fijo.
        call MBSetCell(w.board, MB_ROW_WAVE, 0, MBWaveCell(w), 0.08)
        call MBSetCell(w.board, MB_ROW_WAVE, 1, MBToSpawnCell(w), 0.14)
        call MBSetCell(w.board, MB_ROW_WAVE, 2, MBUnitsCell(w), 0.13)
        call MBSetCell(w.board, MB_ROW_WAVE, 3, MBBossCell(w), 0.11)
        call MBSetCell(w.board, MB_ROW_WAVE, 4, MBToKillCell(w), 0.12)
        call MBSetCell(w.board, MB_ROW_WAVE, 5, MBOnMapCell(w), 0.09)
        call MBSetCell(w.board, MB_ROW_WAVE, 6, MBPlayersCell(), 0.08)

        // Rows 1..8: slots fijos rojo..rosa. Nunca mover debug por AmountPlaying.
        set pid = 0
        loop
            exitwhen pid >= MB_MAX_PLAYERS
            set row = MB_ROW_PLAYER_START + pid

            call MBSetCell(w.board, row, 0, MBPlayerNameText(pid), 0.14)
            call MBSetCell(w.board, row, 1, MBPlayerStatusText(pid), 0.09)
            call MBSetCell(w.board, row, 2, MBPlayerKillsText(pid), 0.09)
            call MBSetCell(w.board, row, 3, MBPlayerStreakText(pid), 0.09)
            call MBSetCell(w.board, row, 4, MBPlayerMultiText(pid), 0.08)
            call MBSetCell(w.board, row, 5, MBPlayerDeathsText(pid), 0.09)
            call MBSetCell(w.board, row, 6, MBPlayerLivesText(pid), 0.08)

            set pid = pid + 1
        endloop

        // Fila debug general: TimerUtils
        call MBSetCell(w.board, MB_ROW_DEBUG_TIMER, 0, "|cFFBBBBBBDebug Timer|r", 0.14)
        call MBSetCell(w.board, MB_ROW_DEBUG_TIMER, 1, MBDebugInUse(), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TIMER, 2, MBDebugCap(), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TIMER, 3, MBDebugPeak(), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TIMER, 4, MBDebugAvail(), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TIMER, 5, "", 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TIMER, 6, "", 0.08)

        // Fila debug loadouts: live/peak por sistema
        call MBSetCell(w.board, MB_ROW_DEBUG_LOADOUT, 0, "|cFFBBBBBBDebug Load|r", 0.14)
        call MBSetCell(w.board, MB_ROW_DEBUG_LOADOUT, 1, MBLoadoutDebugCell("Ctrl", "|cFFFF6666", TIMER_DEBUG_TAG_LOADOUT_CONTROL), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_LOADOUT, 2, MBLoadoutDebugCell("Miss", "|cFF66CCFF", TIMER_DEBUG_TAG_LOADOUT_MISSILE), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_LOADOUT, 3, MBLoadoutDebugCell("Leap", "|cFF66FF99", TIMER_DEBUG_TAG_LOADOUT_LEAP), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_LOADOUT, 4, MBLoadoutDebugCell("LpMs", "|cFFFFCC66", TIMER_DEBUG_TAG_LOADOUT_LEAP_MISS), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_LOADOUT, 5, MBLoadoutDebugCell("Rckt", "|cFFFF99CC", TIMER_DEBUG_TAG_LOADOUT_ROCKET), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_LOADOUT, 6, "", 0.08)

        // Fila debug sistemas: wave / ia / skills / movecast / otros
        call MBSetCell(w.board, MB_ROW_DEBUG_SYSTEMS, 0, "|cFFBBBBBBDebug Sys|r", 0.14)
        call MBSetCell(w.board, MB_ROW_DEBUG_SYSTEMS, 1, MBTaggedDebugCell("Wave", "|cFF99CCFF", TIMER_DEBUG_TAG_WAVE_CORE), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_SYSTEMS, 2, MBTaggedDebugCell("IA", "|cFFFF9999", TIMER_DEBUG_TAG_AI), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_SYSTEMS, 3, MBTaggedDebugCell("Skill", "|cFF99FF99", TIMER_DEBUG_TAG_UNIT_SKILLS), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_SYSTEMS, 4, MBTaggedDebugCell("Move", "|cFFFFCC66", TIMER_DEBUG_TAG_MOVECAST), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_SYSTEMS, 5, MBTaggedDebugCell("Other", "|cFFD6B3FF", TIMER_DEBUG_TAG_OTHER), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_SYSTEMS, 6, "", 0.08)

        call MBSetCell(w.board, MB_ROW_DEBUG_TEXTTAGS, 0, "|cFFBBBBBBDebug Tags|r", 0.14)
        call MBSetCell(w.board, MB_ROW_DEBUG_TEXTTAGS, 1, MBTextTagTotalCell("Total", "|cFF66CCFF", GetTextTagDebugLiveTotal(), GetTextTagDebugPeakTotal()), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TEXTTAGS, 2, MBTextTagTotalCell("UI", "|cFFFF9999", GetTextTagDebugLive(TEXTTAG_DEBUG_UI), GetTextTagDebugPeak(TEXTTAG_DEBUG_UI)), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TEXTTAGS, 3, MBTextTagTotalCell("Move", "|cFFFFCC66", GetTextTagDebugLive(TEXTTAG_DEBUG_MOVECAST), GetTextTagDebugPeak(TEXTTAG_DEBUG_MOVECAST)), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TEXTTAGS, 4, MBTextTagTotalCell("Dmg", "|cFFD6B3FF", GetTextTagDebugLive(TEXTTAG_DEBUG_DAMAGE), GetTextTagDebugPeak(TEXTTAG_DEBUG_DAMAGE)), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TEXTTAGS, 5, MBTextTagTotalCell("HP", "|cFF99FF99", GetHealthBarVisibleCount(), GetHealthBarTextTagCap()), 0.09)
        call MBSetCell(w.board, MB_ROW_DEBUG_TEXTTAGS, 6, "", 0.08)
    endfunction
endlibrary
