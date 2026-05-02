library RestTimeAudio requires RestTimeState

    function StopAmbientTownSound takes nothing returns nothing
        if RestAmbientTownSound != null then
            call StopSound(RestAmbientTownSound, true, false)
            call KillSoundWhenDone(RestAmbientTownSound)
            set RestAmbientTownSound = null
        endif
    endfunction

    function StartAmbientTownSound takes nothing returns nothing
        // Desactivado: no hay ambiente emptytown al inicio ni en RestTime.
    endfunction

    function RestTimeStopSurvivalEndSound takes nothing returns nothing
        if RestSurvivalEndSound != null then
            call StopSound(RestSurvivalEndSound, true, false)
            call KillSoundWhenDone(RestSurvivalEndSound)
            set RestSurvivalEndSound = null
        endif
    endfunction

    function RestTimeStartSurvivalEndSound takes nothing returns nothing
        if RestSurvivalEndSound == null and REST_SURVIVAL_END_SOUND_PATH != null and REST_SURVIVAL_END_SOUND_PATH != "" then
            set RestSurvivalEndSound = CreateSound(REST_SURVIVAL_END_SOUND_PATH, false, false, false, 12700, 12700, "")
            if RestSurvivalEndSound != null then
                call SetSoundVolume(RestSurvivalEndSound, 127)
                call SetSoundPitch(RestSurvivalEndSound, 1.00)
                call StartSound(RestSurvivalEndSound)
                call KillSoundWhenDone(RestSurvivalEndSound)
            endif
        endif
    endfunction

endlibrary
