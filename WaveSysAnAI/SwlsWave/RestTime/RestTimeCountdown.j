library RestTimeCountdown requires RestTimeState, RestTimeAudio, RestTimeUI

    function RestTimeStopPhaseTimer takes nothing returns nothing
        if RestPhaseTimer != null then
            call PauseTimer(RestPhaseTimer)
        endif
    endfunction

    private function RestTimeSetCountdownStatus takes nothing returns nothing
        if RestPhaseState == REST_PHASE_PURCHASE then
            call RestTimeSetStatusForActivePlayers("InterMission: " + I2S(RestPhaseRemaining))
            call RestTimeSetBoardTitle("|cFFFFFF99Descanso|r |cFFFFFFFFWave |r|cFFE6E6E6" + I2S(TargetWave) + "|r|cFFFF8C00/|r|cFFE6E6E610|r |cFFFFFFFF- Tienda: |r|cFF66FF99" + I2S(RestPhaseRemaining) + "|r")
        elseif RestPhaseState == REST_PHASE_INITIAL then
            call RestTimeSetStatusForActivePlayers("WaveIn: " + I2S(RestPhaseRemaining))
            call RestTimeSetBoardTitle("|cFFFFFF99Preparando|r |cFFFFFFFFWave |r|cFFE6E6E6" + I2S(TargetWave) + "|r|cFFFF8C00/|r|cFFE6E6E610|r |cFFFFFFFF- Inicia en: |r|cFF66CCFF" + I2S(RestPhaseRemaining) + "|r")
        endif
    endfunction

    function RestTimeLaunchCurrentWave takes nothing returns nothing
        call RestTimeCloseTenderForActivePlayers()
        set RestPhaseState = REST_PHASE_NONE
        set RestPhaseRemaining = 0
        call RestTimeSetStatusForActivePlayers("Wave " + I2S(TargetWave))
        call RestTimeSetBoardTitle("|cFF66FF99Activa|r |cFFFFFFFFWave |r|cFFE6E6E6" + I2S(TargetWave) + "|r|cFFFF8C00/|r|cFFE6E6E610|r")
        call RestTimeStopPhaseTimer()
        if SwlsWaveStartTrigger != null then
            call TriggerExecute(SwlsWaveStartTrigger)
        elseif WaveTgg != null and WaveTgg != "" then
            call ExecuteFunc(WaveTgg)
        endif
    endfunction

    private function RestTimePhaseTick takes nothing returns nothing
        set RestPhaseRemaining = RestPhaseRemaining - 1
        if RestPhaseRemaining <= 0 then
            call RestTimeLaunchCurrentWave()
            return
        endif
        call RestTimeSetCountdownStatus()
    endfunction

    function RestTimeBeginCountdown takes integer seconds, integer phaseState returns nothing
        if seconds < 1 then
            set seconds = 1
        endif
        if RestPhaseTimer == null then
            set RestPhaseTimer = CreateTimer()
        endif
        set RestPhaseState = phaseState
        set RestPhaseRemaining = seconds
        if phaseState == REST_PHASE_PURCHASE then
            set RestSurvivalEndSequenceActive = false
            call RestTimeSetStatusForActivePlayers("TimeOfPurchase: " + I2S(RestPhaseRemaining))
            call RestTimeSetBoardTitle("|cFFFFFF99Descanso|r |cFFFFFFFFWave |r|cFFE6E6E6" + I2S(TargetWave) + "|r|cFFFF8C00/|r|cFFE6E6E610|r |cFFFFFFFF- Tienda: |r|cFF66FF99" + I2S(RestPhaseRemaining) + "|r")
        else
            call RestTimeSetCountdownStatus()
        endif
        call PauseTimer(RestPhaseTimer)
        call TimerStart(RestPhaseTimer, REST_PHASE_TICK_SEC, true, function RestTimePhaseTick)
    endfunction

endlibrary
