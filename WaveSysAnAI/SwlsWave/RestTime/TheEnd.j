library TheEnd requires RestTimeAudio, RestTimeCountdown, RestTimeEndFlow

    function CloseTenderForActivePlayers takes nothing returns nothing
        call RestTimeCloseTenderForActivePlayers()
    endfunction

    function StartInitialWaveCountdown takes nothing returns nothing
        call RestTimeBeginCountdown(REST_INITIAL_WAVE_COUNTDOWN, REST_PHASE_INITIAL)
    endfunction

    function StartPurchaseCountdown takes nothing returns nothing
        call RestTimeBeginCountdown(REST_PURCHASE_COUNTDOWN, REST_PHASE_PURCHASE)
    endfunction

    function endF takes string nextWaveFunc returns nothing
        call RestTimeOnWaveFinished(nextWaveFunc)
    endfunction

endlibrary
