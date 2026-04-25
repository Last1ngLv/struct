library GameState

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
    endglobals

    function GameStateInitDefaults takes nothing returns nothing
        set TargetWave = 1
    endfunction

endlibrary
