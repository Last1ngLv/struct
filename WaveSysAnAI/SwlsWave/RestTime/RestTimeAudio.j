library RestTimeAudio requires RestTimeState

    function StopAmbientTownSound takes nothing returns nothing
        if RestAmbientTownSound != null then
            call StopSound(RestAmbientTownSound, true, false)
            call KillSoundWhenDone(RestAmbientTownSound)
            set RestAmbientTownSound = null
        endif
    endfunction

    function StartAmbientTownSound takes nothing returns nothing
        call StopAmbientTownSound()
        if REST_AMBIENT_TOWN_SOUND_PATH == null or REST_AMBIENT_TOWN_SOUND_PATH == "" then
            return
        endif
        set RestAmbientTownSound = CreateSound(REST_AMBIENT_TOWN_SOUND_PATH, true, false, false, 12700, 12700, "")
        if RestAmbientTownSound != null then
            call SetSoundVolume(RestAmbientTownSound, 72)
            call SetSoundPitch(RestAmbientTownSound, 1.00)
            call StartSound(RestAmbientTownSound)
        endif
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
