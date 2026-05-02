library RestTimeTenderAudio requires RestTimeState

    function RestTimeTenderAudioStart takes nothing returns nothing
        // Desactivado: el audio local del Tender queda fuera del flujo de RestTime.
        set RestTenderAudioRunning = false
    endfunction

    function RestTimeTenderAudioStop takes nothing returns nothing
        set RestTenderAudioRunning = false
        if RestTenderAudioTimer != null then
            call PauseTimer(RestTenderAudioTimer)
        endif
        set RestTenderAudioTrackIndex = 0
    endfunction

endlibrary
