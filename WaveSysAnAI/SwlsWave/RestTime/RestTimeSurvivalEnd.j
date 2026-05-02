library RestTimeSurvivalEnd requires PlayerUtils, RestTimeState, RestTimeAudio, RestTimeUI

    function RestTimeCompleteSurvivalEndSequence takes nothing returns nothing
        local integer i = 0
        local User u
        set RestSurvivalEndSequenceActive = false
        call RestTimeStopSurvivalEndSound()
        call BJDebugMsg("|cff66ff66Mapa completado|r")
        call RestTimeSetBoardTitle("|cFF66FF66Mapa completado|r")
        call RestTimeSetStatusForActivePlayers("|cff66ff66Mapa completado|r")
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            call CustomVictoryBJ(u.toPlayer(), true, true)
            set i = i + 1
        endloop
    endfunction

    private function RestTimeOnSurvivalEndTimer takes nothing returns nothing
        if RestSurvivalEndTimer != null then
            call PauseTimer(RestSurvivalEndTimer)
            call DestroyTimer(RestSurvivalEndTimer)
            set RestSurvivalEndTimer = null
        endif
        call RestTimeCompleteSurvivalEndSequence()
    endfunction

    function RestTimeStartSurvivalEndSequence takes nothing returns nothing
        if RestSurvivalEndSequenceActive then
            return
        endif
        set RestSurvivalEndSequenceActive = true
        if RestPhaseTimer != null then
            call PauseTimer(RestPhaseTimer)
        endif
        call BJDebugMsg("|cff66ff66Superaste las 10 waves|r")
        call RestTimeSetBoardTitle("|cFF66FF66Superaste las 10 waves|r")
        call RestTimeSetStatusForActivePlayers("|cff66ff66Superaste las 10 waves|r")
        call RestTimeStartSurvivalEndSound()
        if RestSurvivalEndTimer == null then
            set RestSurvivalEndTimer = CreateTimer()
        endif
        call PauseTimer(RestSurvivalEndTimer)
        call TimerStart(RestSurvivalEndTimer, REST_SURVIVAL_END_DELAY, false, function RestTimeOnSurvivalEndTimer)
    endfunction

endlibrary
