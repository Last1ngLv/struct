library InitialWaveMultiboard requires PlayerUtils, TimerUtils, TextTagDebug, HealthBarTextTags, GameState

    globals
        private timer InitialBoardTimer = null
    endglobals

    private function SetInitialBoardCell takes integer row, integer column, string value, real width returns nothing
        local multiboarditem boardItem

        if SwlsMultiboard == null then
            return
        endif

        set boardItem = MultiboardGetItem(SwlsMultiboard, row, column)
        call MultiboardSetItemStyle(boardItem, true, false)
        call MultiboardSetItemWidth(boardItem, width)
        call MultiboardSetItemValue(boardItem, value)
        call MultiboardReleaseItem(boardItem)
        set boardItem = null
    endfunction

    private function PopulateInitialWaveMultiboard takes nothing returns nothing
        if SwlsMultiboard == null then
            return
        endif

        call MultiboardSetColumnCount(SwlsMultiboard, 6)
        call MultiboardSetRowCount(SwlsMultiboard, 5)
        call MultiboardSetTitleText(SwlsMultiboard, "|cFFC0C0C0Preparando |r|cFFFFFFFFWave |r|cFFE6E6E6" + I2S(TargetWave) + "|r|cFFFF8C00/|r|cFFE6E6E610|r")

        call SetInitialBoardCell(0, 0, "|cFFBBBBBBEstado|r|cFFFFFFFF: |r|cFFFFFF99Seleccion|r", 0.16)
        call SetInitialBoardCell(0, 1, "|cFFE6E6E6Wave|r|cFFFFFFFF: |r|cFFE6E6E6" + I2S(TargetWave) + "|r|cFFFF8C00/|r|cFFC0C0C010|r", 0.12)
        call SetInitialBoardCell(0, 2, "|cFF66FF99Activos|r|cFFFFFFFF: |r|cFFFFFFCC" + I2S(User.AmountPlaying) + "|r", 0.12)
        call SetInitialBoardCell(0, 3, "|cFFBBBBBBVista|r|cFFFFFFFF: |r|cFFDDDDDDDebug|r", 0.12)
        call SetInitialBoardCell(0, 4, "|cFFBBBBBBNota|r|cFFFFFFFF: |r|cFFD8D8D8Esperando heroes|r", 0.16)
        call SetInitialBoardCell(0, 5, "", 0.01)

        call SetInitialBoardCell(1, 0, "|cFFBBBBBBDebug TimerUtils|r", 0.16)
        call SetInitialBoardCell(1, 1, "|cFF66CCFFInUse|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerUtilsInUse()) + "|r", 0.12)
        call SetInitialBoardCell(1, 2, "|cFF66FF99Cap|r|cFFFFFFFF: |r|cFFCCFFDD" + I2S(GetTimerUtilsCapacity()) + "|r", 0.11)
        call SetInitialBoardCell(1, 3, "|cFFFFCC66Peak|r|cFFFFFFFF: |r|cFFFFE0B3" + I2S(GetTimerUtilsPeakInUse()) + "|r", 0.11)
        call SetInitialBoardCell(1, 4, "|cFF9999FFAvail|r|cFFFFFFFF: |r|cFFD6D6FF" + I2S(GetTimerUtilsAvailable()) + "|r", 0.12)
        call SetInitialBoardCell(1, 5, "", 0.01)

        call SetInitialBoardCell(2, 0, "|cFFBBBBBBDebug Loadouts|r", 0.16)
        call SetInitialBoardCell(2, 1, "|cFFFF6666Control|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_LOADOUT_CONTROL)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_LOADOUT_CONTROL)) + "|r", 0.11)
        call SetInitialBoardCell(2, 2, "|cFF66CCFFMissile|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_LOADOUT_MISSILE)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_LOADOUT_MISSILE)) + "|r", 0.11)
        call SetInitialBoardCell(2, 3, "|cFF66FF99Leap|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_LOADOUT_LEAP)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_LOADOUT_LEAP)) + "|r", 0.10)
        call SetInitialBoardCell(2, 4, "|cFFFFCC66LeapMs|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_LOADOUT_LEAP_MISS)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_LOADOUT_LEAP_MISS)) + "|r", 0.10)
        call SetInitialBoardCell(2, 5, "|cFFFF99CCRocket|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_LOADOUT_ROCKET)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_LOADOUT_ROCKET)) + "|r", 0.10)

        call SetInitialBoardCell(3, 0, "|cFFBBBBBBDebug Systems|r", 0.16)
        call SetInitialBoardCell(3, 1, "|cFF99CCFFWave|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_WAVE_CORE)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_WAVE_CORE)) + "|r", 0.11)
        call SetInitialBoardCell(3, 2, "|cFFFF9999IA|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_AI)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_AI)) + "|r", 0.10)
        call SetInitialBoardCell(3, 3, "|cFF99FF99UnitSkills|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_UNIT_SKILLS)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_UNIT_SKILLS)) + "|r", 0.12)
        call SetInitialBoardCell(3, 4, "|cFFFFCC66MoveCast|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_MOVECAST)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_MOVECAST)) + "|r", 0.12)
        call SetInitialBoardCell(3, 5, "|cFFD6B3FFOther|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTimerDebugLive(TIMER_DEBUG_TAG_OTHER)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTimerDebugPeak(TIMER_DEBUG_TAG_OTHER)) + "|r", 0.11)

        call SetInitialBoardCell(4, 0, "|cFFBBBBBBDebug TextTags|r", 0.16)
        call SetInitialBoardCell(4, 1, "|cFF66CCFFTotal|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTextTagDebugLiveTotal()) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTextTagDebugPeakTotal()) + "|r", 0.11)
        call SetInitialBoardCell(4, 2, "|cFFFF9999UI|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTextTagDebugLive(TEXTTAG_DEBUG_UI)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTextTagDebugPeak(TEXTTAG_DEBUG_UI)) + "|r", 0.10)
        call SetInitialBoardCell(4, 3, "|cFFFFCC66Move|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTextTagDebugLive(TEXTTAG_DEBUG_MOVECAST)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTextTagDebugPeak(TEXTTAG_DEBUG_MOVECAST)) + "|r", 0.10)
        call SetInitialBoardCell(4, 4, "|cFFD6B3FFDmg|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTextTagDebugLive(TEXTTAG_DEBUG_DAMAGE)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetTextTagDebugPeak(TEXTTAG_DEBUG_DAMAGE)) + "|r", 0.11)
        call SetInitialBoardCell(4, 5, "|cFF99FF99Health|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetHealthBarVisibleCount()) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetHealthBarTextTagCap()) + "|r", 0.12)
    endfunction

    private function InitialWaveMultiboardTick takes nothing returns nothing
        if SwlsMultiboard == null or isWavez then
            return
        endif
        call PopulateInitialWaveMultiboard()
        call MultiboardDisplay(SwlsMultiboard, true)
    endfunction

    function ShowInitialWaveMultiboard takes nothing returns nothing
        call PopulateInitialWaveMultiboard()
        call MultiboardDisplay(SwlsMultiboard, true)
    endfunction

    function InitInitialWaveMultiboard takes nothing returns nothing
        set SwlsMultiboard = CreateMultiboard()
        call ShowInitialWaveMultiboard()
        if InitialBoardTimer == null then
            set InitialBoardTimer = CreateTimer()
            call TimerStart(InitialBoardTimer, 0.10, true, function InitialWaveMultiboardTick)
        endif
    endfunction

endlibrary
