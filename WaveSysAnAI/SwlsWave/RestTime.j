library TheEnd requires HeroLives, TenderSystem, PreConfi
    globals
        private constant integer WAVE_PHASE_NONE = 0
        private constant integer WAVE_PHASE_START = 1
        private constant integer WAVE_PHASE_PURCHASE = 2
        private constant integer INITIAL_WAVE_COUNTDOWN = 35
        private constant integer PURCHASE_COUNTDOWN = 50
        private constant real WAVE_PHASE_TICK_SEC = 1.00
        private constant integer TRADER_TRACK_COUNT = 6
        private constant real TENDER_SOUND_CHECK_PERIOD = 0.25
        private constant real TENDER_SOUND_RADIUS = 500.0
        private constant real SURVIVAL_END_DELAY = 18.00
        private constant integer PURCHASE_MUSIC_VOLUME = 127
        private constant real PURCHASE_MUSIC_PITCH = 1.00
        private constant string AMBIENT_TOWN_SOUND_PATH = "war3mapImported\\emptytown.wav"
        private constant string SURVIVAL_END_SOUND_PATH = "war3mapImported\\SurvivalEnd.wav"

        private timer WavePhaseTimer = null
        private timer TenderSoundTimer = null
        private timer SurvivalEndTimer = null
        private integer WavePhaseState = WAVE_PHASE_NONE
        private integer WavePhaseRemaining = 0
        private sound PurchasePhaseSound = null
        private sound AmbientTownSound = null
        private sound TenderAreaSound = null
        private sound SurvivalEndSound = null
        private integer LastPurchaseTrackIndex = 0
        private integer LastTenderTrackIndex = 0
        private integer CurrentTenderTrackIndex = 0
        private boolean SurvivalEndSequenceActive = false
    endglobals

    private function GetTraderTrackPath takes integer idx returns string
        if idx == 1 then
            return "war3mapImported\\Trader --- - Never Gonna Stay in The Abyss.wav"
        elseif idx == 2 then
            return "war3mapImported\\Trader 1 - Meanwhile, in The Abyss.wav"
        elseif idx == 3 then
            return "war3mapImported\\Trader 10 - Columba Noachi.wav"
        elseif idx == 4 then
            return "war3mapImported\\Trader 11 - Cold Wind.wav"
        elseif idx == 5 then
            return "war3mapImported\\Trader 12 - Crystal Breakin' Time.wav"
        elseif idx == 6 then
            return "war3mapImported\\Trader 9 - Weapon Check-up.wav"
        endif
        return ""
    endfunction

    private function PickTraderTrackIndex takes integer lastIndex returns integer
        local integer roll
        if TRADER_TRACK_COUNT <= 1 then
            return 1
        endif
        set roll = GetRandomInt(1, TRADER_TRACK_COUNT)
        if roll == lastIndex then
            set roll = roll + 1
            if roll > TRADER_TRACK_COUNT then
                set roll = 1
            endif
        endif
        return roll
    endfunction

    private function SetWaveStatusTextForActivePlayers takes string statusText returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]
            if hero != null and GetUnitTypeId(hero) != 0 then
                set client = Client[hero]
                if client != 0 then
                    call client.setWaveStatusTitle(statusText)
                endif
            endif
            set i = i + 1
        endloop
        set hero = null
    endfunction

    function CloseTenderForActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set isTender[u.id] = false
            if u.toPlayer() == Player(0) then
                set hero = PlayerHero[u.id]
                if hero != null and GetUnitTypeId(hero) != 0 then
                    set client = Client[hero]
                    if client != 0 then
                        call client.getButton(2).showPlayer(client.user.handle, false, client.camera)
                    endif
                endif
            endif
            set i = i + 1
        endloop
        set hero = null
    endfunction

    private function StopPurchaseMusic takes nothing returns nothing
        if PurchasePhaseSound != null then
            call StopSound(PurchasePhaseSound, true, false)
            call KillSoundWhenDone(PurchasePhaseSound)
            set PurchasePhaseSound = null
        endif
    endfunction

    private function StartPurchaseMusic takes nothing returns nothing
        local integer trackIndex
        local string trackPath
        call StopPurchaseMusic()
        set trackIndex = PickTraderTrackIndex(LastPurchaseTrackIndex)
        set trackPath = GetTraderTrackPath(trackIndex)
        if trackPath == null or trackPath == "" then
            return
        endif
        set LastPurchaseTrackIndex = trackIndex
        set PurchasePhaseSound = CreateSound(trackPath, true, false, false, 12700, 12700, "")
        if PurchasePhaseSound != null then
            call SetSoundVolume(PurchasePhaseSound, PURCHASE_MUSIC_VOLUME)
            call SetSoundPitch(PurchasePhaseSound, PURCHASE_MUSIC_PITCH)
            call StartSound(PurchasePhaseSound)
        endif
    endfunction

    function StopAmbientTownSound takes nothing returns nothing
        if AmbientTownSound != null then
            call StopSound(AmbientTownSound, true, false)
            call KillSoundWhenDone(AmbientTownSound)
            set AmbientTownSound = null
        endif
    endfunction

    function StartAmbientTownSound takes nothing returns nothing
        call StopAmbientTownSound()
        if AMBIENT_TOWN_SOUND_PATH == null or AMBIENT_TOWN_SOUND_PATH == "" then
            return
        endif
        set AmbientTownSound = CreateSound(AMBIENT_TOWN_SOUND_PATH, true, false, false, 12700, 12700, "")
        if AmbientTownSound != null then
            call SetSoundVolume(AmbientTownSound, 72)
            call SetSoundPitch(AmbientTownSound, 1.00)
            call StartSound(AmbientTownSound)
        endif
    endfunction

    private function StopTenderAreaSound takes nothing returns nothing
        if TenderAreaSound != null then
            call StopSound(TenderAreaSound, true, false)
            call KillSoundWhenDone(TenderAreaSound)
            set TenderAreaSound = null
        endif
    endfunction

    private function StartTenderAreaSound takes nothing returns nothing
        local string trackPath
        call StopTenderAreaSound()
        if CurrentTenderTrackIndex <= 0 then
            set CurrentTenderTrackIndex = PickTraderTrackIndex(LastTenderTrackIndex)
            set LastTenderTrackIndex = CurrentTenderTrackIndex
        endif
        set trackPath = GetTraderTrackPath(CurrentTenderTrackIndex)
        if trackPath == null or trackPath == "" then
            return
        endif
        set TenderAreaSound = CreateSound(trackPath, true, false, false, 12700, 12700, "")
        if TenderAreaSound != null then
            call SetSoundVolume(TenderAreaSound, 96)
            call SetSoundPitch(TenderAreaSound, 1.00)
            call StartSound(TenderAreaSound)
        endif
    endfunction

    private function StopSurvivalEndSound takes nothing returns nothing
        if SurvivalEndSound != null then
            call StopSound(SurvivalEndSound, true, false)
            call KillSoundWhenDone(SurvivalEndSound)
            set SurvivalEndSound = null
        endif
    endfunction

    private function OnTenderSoundTick takes nothing returns nothing
        local unit hero
        if SurvivalEndSequenceActive then
            call StopTenderAreaSound()
            return
        endif
        if WavePhaseState != WAVE_PHASE_PURCHASE then
            call StopTenderAreaSound()
            return
        endif
        set hero = PlayerHero[User.LocalId]
        if hero != null and GetUnitTypeId(hero) != 0 and GetWidgetLife(hero) > 0.405 then
            if IsUnitNearTender(hero, TENDER_SOUND_RADIUS) then
                if TenderAreaSound == null then
                    call StartTenderAreaSound()
                endif
            else
                call StopTenderAreaSound()
            endif
        else
            call StopTenderAreaSound()
        endif
        set hero = null
    endfunction

    function StartTenderSoundTracker takes nothing returns nothing
        if TenderSoundTimer == null then
            set TenderSoundTimer = CreateTimer()
        endif
        call PauseTimer(TenderSoundTimer)
        call TimerStart(TenderSoundTimer, TENDER_SOUND_CHECK_PERIOD, true, function OnTenderSoundTick)
    endfunction

    private function CompleteSurvivalEndSequence takes nothing returns nothing
        local integer i = 0
        local User u
        set SurvivalEndSequenceActive = false
        call StopSurvivalEndSound()
        call BJDebugMsg("|cff66ff66Mapa completado|r")
        call SetWaveStatusTextForActivePlayers("|cff66ff66Mapa completado|r")
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            call CustomVictoryBJ(u.toPlayer(), true, true)
            set i = i + 1
        endloop
    endfunction

    private function OnSurvivalEndTimer takes nothing returns nothing
        if SurvivalEndTimer != null then
            call PauseTimer(SurvivalEndTimer)
            call DestroyTimer(SurvivalEndTimer)
            set SurvivalEndTimer = null
        endif
        call CompleteSurvivalEndSequence()
    endfunction

    private function StartSurvivalEndSequence takes nothing returns nothing
        if SurvivalEndSequenceActive then
            return
        endif
        set SurvivalEndSequenceActive = true
        if WavePhaseTimer != null then
            call PauseTimer(WavePhaseTimer)
        endif
        call StopPurchaseMusic()
        call StopAmbientTownSound()
        call StopTenderAreaSound()
        call BJDebugMsg("|cff66ff66Superaste las 10 waves|r")
        call SetWaveStatusTextForActivePlayers("|cff66ff66Superaste las 10 waves|r")
        if SurvivalEndSound == null and SURVIVAL_END_SOUND_PATH != null and SURVIVAL_END_SOUND_PATH != "" then
            set SurvivalEndSound = CreateSound(SURVIVAL_END_SOUND_PATH, false, false, false, 12700, 12700, "")
            if SurvivalEndSound != null then
                call SetSoundVolume(SurvivalEndSound, 127)
                call SetSoundPitch(SurvivalEndSound, 1.00)
                call StartSound(SurvivalEndSound)
                call KillSoundWhenDone(SurvivalEndSound)
            endif
        endif
        if SurvivalEndTimer == null then
            set SurvivalEndTimer = CreateTimer()
        endif
        call PauseTimer(SurvivalEndTimer)
        call TimerStart(SurvivalEndTimer, SURVIVAL_END_DELAY, false, function OnSurvivalEndTimer)
    endfunction

    private function LaunchCurrentWave takes nothing returns nothing
        call StopPurchaseMusic()
        call StopAmbientTownSound()
        call StopTenderAreaSound()
        call CloseTenderForActivePlayers()
        call ExecuteFunc("MenuClientClearEnemyPreviewForActivePlayers")
        set WavePhaseState = WAVE_PHASE_NONE
        set WavePhaseRemaining = 0
        set CurrentTenderTrackIndex = 0
        call SetWaveStatusTextForActivePlayers("Wave " + I2S(TargetWave))
        if WavePhaseTimer != null then
            call PauseTimer(WavePhaseTimer)
        endif
        if WaveTgg != null and WaveTgg != "" then
            call ExecuteFunc(WaveTgg)
        endif
    endfunction

    private function OnWavePhaseTick takes nothing returns nothing
        set WavePhaseRemaining = WavePhaseRemaining - 1
        if WavePhaseRemaining <= 0 then
            call LaunchCurrentWave()
            return
        endif
        if WavePhaseState == WAVE_PHASE_PURCHASE then
            call SetWaveStatusTextForActivePlayers("TradeTime: " + I2S(WavePhaseRemaining))
        elseif WavePhaseState == WAVE_PHASE_START then
            call SetWaveStatusTextForActivePlayers("WaveIn: " + I2S(WavePhaseRemaining))
        endif
    endfunction

    private function BeginWaveCountdown takes integer seconds, integer phaseState returns nothing
        if seconds < 1 then
            set seconds = 1
        endif
        if WavePhaseTimer == null then
            set WavePhaseTimer = CreateTimer()
        endif
        set WavePhaseState = phaseState
        set WavePhaseRemaining = seconds
        if phaseState == WAVE_PHASE_PURCHASE then
            set SurvivalEndSequenceActive = false
            set CurrentTenderTrackIndex = PickTraderTrackIndex(LastTenderTrackIndex)
            set LastTenderTrackIndex = CurrentTenderTrackIndex
            call StartAmbientTownSound()
            call StopPurchaseMusic()
            call SetWaveStatusTextForActivePlayers("TimeOfPurchase: " + I2S(WavePhaseRemaining))
        else
            call StopPurchaseMusic()
            call StopTenderAreaSound()
            set CurrentTenderTrackIndex = 0
            call SetWaveStatusTextForActivePlayers("WaveIn: " + I2S(WavePhaseRemaining))
        endif
        call ExecuteFunc("MenuClientRefreshEnemyPreviewForActivePlayers")
        call PauseTimer(WavePhaseTimer)
        call TimerStart(WavePhaseTimer, WAVE_PHASE_TICK_SEC, true, function OnWavePhaseTick)
    endfunction

    function StartInitialWaveCountdown takes nothing returns nothing
        call BeginWaveCountdown(INITIAL_WAVE_COUNTDOWN, WAVE_PHASE_START)
    endfunction

    function StartPurchaseCountdown takes nothing returns nothing
        call BeginWaveCountdown(PURCHASE_COUNTDOWN, WAVE_PHASE_PURCHASE)
    endfunction

    function endF takes string thisWav returns nothing
        local string a = thisWav
        local integer i = 0
        local User u
        local integer currentGold
    
    call MultiboardSetTitleText(SwlsMultiboard,"Wave Successful")
    call StopSound(SwlsSound, true, false)
    set TargetWave = TargetWave + 1
    set WaveTgg = thisWav
    set isWavez = false
    
    call HeroLivesRefreshActivePlayers()
    call ReviveAndHealHeroes()
    if TargetWave == 11 then
        call StartSurvivalEndSequence()
        return
    endif
    
    loop
        exitwhen i == User.AmountPlaying //static jeje por eso sin variable
        set u = User.fromPlaying(i)
        
        call Client[PlayerHero[u.id]].show(true, PlayerCamera[u.id])
        set currentGold = GetPlayerState(u.toPlayer(), PLAYER_STATE_RESOURCE_GOLD)
        call SetPlayerState(u.toPlayer(), PLAYER_STATE_RESOURCE_GOLD, currentGold + 5)
        set i = i + 1
    endloop
    
        if GetTenderUnit() != null then
            call SetUnitAnimation(GetTenderUnit(), "Birth")
            call QueueUnitAnimationBJ(GetTenderUnit(), "stand")
        endif
        call StartPurchaseCountdown()
        
    endfunction


endlibrary
