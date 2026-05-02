library RestTimeEndFlow requires HeroLives, TenderSystem, PreConfi, PlayerUtils, RestTimeState, RestTimeCountdown, RestTimeSurvivalEnd, RestTimeUI

    private function RestTimeRewardActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u
        local integer currentGold
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set currentGold = GetPlayerState(u.toPlayer(), PLAYER_STATE_RESOURCE_GOLD)
            call SetPlayerState(u.toPlayer(), PLAYER_STATE_RESOURCE_GOLD, currentGold + REST_GOLD_REWARD)
            set i = i + 1
        endloop
    endfunction

    private function RestTimeAnimateTender takes nothing returns nothing
        if GetTenderUnit() != null then
            call SetUnitAnimation(GetTenderUnit(), "Birth")
            call QueueUnitAnimationBJ(GetTenderUnit(), "stand")
        endif
    endfunction

    function RestTimeOnWaveFinished takes string nextWaveFunc returns nothing
        if SwlsMultiboard != null then
            call MultiboardSetTitleText(SwlsMultiboard, "|cFF66FF99Wave completada|r")
        endif
        set TargetWave = TargetWave + 1
        set WaveTgg = nextWaveFunc
        set isWavez = false

        call HeroLivesRefreshActivePlayers()
        call ReviveAndHealHeroes()

        if TargetWave >= REST_FINAL_WAVE_DONE then
            if SwlsSound != null then
                call StopSound(SwlsSound, true, false)
                set SwlsSound = null
            endif
            call RestTimeStartSurvivalEndSequence()
            return
        endif

        if SwlsSound != null then
            call SetSoundVolume(SwlsSound, R2I(I2R(SwlsSoundWaveVolume) * 0.50))
        endif
        call RestTimeRewardActivePlayers()
        call RestTimeAnimateTender()
        call RestTimeBeginCountdown(REST_PURCHASE_COUNTDOWN, REST_PHASE_PURCHASE)
    endfunction

endlibrary
