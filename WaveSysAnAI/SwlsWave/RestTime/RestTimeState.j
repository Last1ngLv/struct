library RestTimeState

    globals
        constant integer REST_PHASE_NONE = 0
        constant integer REST_PHASE_INITIAL = 1
        constant integer REST_PHASE_PURCHASE = 2
        constant integer REST_INITIAL_WAVE_COUNTDOWN = 5
        constant integer REST_PURCHASE_COUNTDOWN = 10
        constant real REST_PHASE_TICK_SEC = 1.00
        constant real REST_SURVIVAL_END_DELAY = 18.00
        constant integer REST_FINAL_WAVE_DONE = 11
        constant integer REST_GOLD_REWARD = 2
        constant string REST_AMBIENT_TOWN_SOUND_PATH = ""
        constant string REST_SURVIVAL_END_SOUND_PATH = "war3mapImported\\SurvivalEnd.wav"
        constant real REST_TENDER_AUDIO_TICK_SEC = 0.25
        constant real REST_TENDER_AUDIO_RADIUS = 500.0
        constant integer REST_TENDER_AUDIO_VOLUME = 127
        constant boolean REST_TENDER_AUDIO_ENABLED = false

        timer RestPhaseTimer = null
        timer RestSurvivalEndTimer = null
        timer RestTenderAudioTimer = null
        integer RestPhaseState = REST_PHASE_NONE
        integer RestPhaseRemaining = 0
        integer RestTenderAudioTrackIndex = 0
        integer RestTenderAudioLastTrackIndex = 0
        sound RestAmbientTownSound = null
        sound RestSurvivalEndSound = null
        sound array RestTenderAudioSoundByPid
        boolean RestSurvivalEndSequenceActive = false
        boolean RestTenderAudioRunning = false
        boolean array RestTenderAudioActiveByPid
        string RestStatusText = ""
    endglobals

endlibrary
