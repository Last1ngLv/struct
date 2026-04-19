library PreConfi initializer Init requires PlayerUtils, TimerUtils, TenderSystem, MovementSystem, TextTagDebug

    globals
        integer array ManaPassiveUnit

        multiboard SwlsMultiboard
        sound SwlsSound
        integer TargetWave
        sound error
        sound error_Neg
        string Message
        string WaveTgg
        boolean array isTender[11]
        boolean isWavez = false

        private timer PreloadResTimer = null
        private integer PreloadResCursor = 1
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
        call SetInitialBoardCell(4, 5, "|cFF99FF99Health|r|cFFFFFFFF: |r|cFFFFFF00" + I2S(GetTextTagDebugLive(TEXTTAG_DEBUG_HEALTHBAR)) + "|r|cFFFF8C00/|r|cFFFFCC66" + I2S(GetHealthBarTextTagCap()) + "|r", 0.12)
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

    // Precarga agresiva de audio:
    // 1) Preload(path)
    // 2) CreateSound + StartSound (volumen 0)
    // 3) KillSoundWhenDone
    private function WarmupSound takes string path returns nothing
        local sound s
        if path == null or path == "" then
            return
        endif
        call Preload(path)
        set s = CreateSound(path, false, false, false, 10, 10, "")
        if s != null then
            call SetSoundVolume(s, 0)
            call StartSound(s)
            call KillSoundWhenDone(s)
        endif
        set s = null
    endfunction

    // Tabla lineal de rutas para precarga escalonada.
    private function GetPreloadSoundPath takes integer idx returns string
        if idx == 1 then
            return "war3mapImported\\announcer_1stblood_01.wav"
        elseif idx == 2 then
            return "war3mapImported\\RDK_RompeRacha.mp3"
        elseif idx == 3 then
            return "war3mapImported\\RDK_RompeCombo1.mp3"
        elseif idx == 4 then
            return "war3mapImported\\RDK_RompeCombo2.mp3"
        elseif idx == 5 then
            return "war3mapImported\\announcer_kill_spree_01.mp3"
        elseif idx == 6 then
            return "war3mapImported\\announcer_kill_dominate_01.mp3"
        elseif idx == 7 then
            return "war3mapImported\\announcer_kill_mega_01.mp3"
        elseif idx == 8 then
            return "war3mapImported\\announcer_kill_unstop_01.mp3"
        elseif idx == 9 then
            return "war3mapImported\\announcer_kill_wicked_01.mp3"
        elseif idx == 10 then
            return "war3mapImported\\announcer_kill_monster_01.mp3"
        elseif idx == 11 then
            return "war3mapImported\\announcer_kill_godlike_01.mp3"
        elseif idx == 12 then
            return "war3mapImported\\announcer_kill_holy_01.mp3"
        elseif idx == 13 then
            return "war3mapImported\\announcer_kill_double_01.mp3"
        elseif idx == 14 then
            return "war3mapImported\\announcer_kill_triple_01.mp3"
        elseif idx == 15 then
            return "war3mapImported\\announcer_kill_ultra_01.mp3"
        elseif idx == 16 then
            return "war3mapImported\\announcer_kill_rampage_01.mp3"
        endif
        return ""
    endfunction

    private function PreloadMapResourcesTick takes nothing returns nothing
        local string path = GetPreloadSoundPath(PreloadResCursor)
        if path == "" then
            call PauseTimer(PreloadResTimer)
            call DestroyTimer(PreloadResTimer)
            set PreloadResTimer = null
            return
        endif
        call WarmupSound(path)
        set PreloadResCursor = PreloadResCursor + 1
    endfunction

    // Precarga exclusiva de recursos (audio), escalonada para evitar picos/fallos.
    // Mantener esta lista alineada con los defaults de WaveStreaks.
    private function PreloadMapResources takes nothing returns nothing
        set PreloadResCursor = 1
        if PreloadResTimer != null then
            call PauseTimer(PreloadResTimer)
            call DestroyTimer(PreloadResTimer)
        endif
        set PreloadResTimer = CreateTimer()
        // Arranque diferido para que el motor de sonido esté listo.
        call TimerStart(PreloadResTimer, 0.10, true, function PreloadMapResourcesTick)
    endfunction

    private function InitDefaultWaveOwnerResearches takes nothing returns nothing
        local integer i = 8
        local integer researchedLevel = User.AmountPlaying

        loop
            exitwhen i > 12
            call SetPlayerTechResearched(Player(i), 'Rhar', researchedLevel)
            set i = i + 1
        endloop
    endfunction

    function InitTrig_Vars takes nothing returns nothing
        //ForSwlsWave
        set TargetWave = 1
        set SwlsMultiboard = CreateMultiboard()
        call ShowInitialWaveMultiboard()
        if InitialBoardTimer == null then
            set InitialBoardTimer = CreateTimer()
            call TimerStart(InitialBoardTimer, 0.10, true, function InitialWaveMultiboardTick)
        endif
        call RefreshTenderUnitByType(TenderUnitTypeId, TenderX, TenderY, TenderFacing)
        call PreloadMapResources()
        call InitDefaultWaveOwnerResearches()

        //ForSwlsWave
        //call SILENCE_TESTUNIT_AMOV()

        //HostilNeutralInits
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[8], bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[9], bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[10], bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[11], bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_FORCE_PLAYER[8], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_FORCE_PLAYER[9], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_FORCE_PLAYER[10], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_FORCE_PLAYER[11], bj_ALLIANCE_ALLIED_VISION )

        //SpellsToMovementCast
        //call RegisterMovementSpell('A001',"curse")
        call RegisterMovementSpellTarget('A000',"thunderbolt")
        call RegisterMovementSpellTarget('AHdr',"drain")

        //call SetCameraField(CAMERA_FIELD_FARZ, 10000., 0)
        //call FogEnable(false)
        //call FogMaskEnable(false)
        call SetPlayerState(Player(0), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(1), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(2), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(3), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(4), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(5), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(6), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(7), PLAYER_STATE_GIVES_BOUNTY, 0)

        set error = CreateSound("Sound\\Interface\\Warning\\Human\\KnightNoGold1.wav", false, false, false, 12700,12700,"")
        set error_Neg = CreateSound("war3mapImported\\Error.mp3", false, false, false, 12700,12700,"")
        set Message = "BIENVENIDO!! me alegra que llegaras a tiempo no se como llegaste pero... espero no te pase lo mismo que a anteriores jugadores, los primeros que siempre ayudaron el pueblo cayeron... confio en ti"
    endfunction

    private function Init takes nothing returns nothing
        call InitTrig_Vars()
    endfunction

endlibrary

