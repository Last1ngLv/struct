library PreConfi initializer Init requires PlayerUtils, TenderSystem, MovementSystem

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
    endglobals

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

