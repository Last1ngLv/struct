library SelectionStartFlow requires TheEnd, GameState, InitialWaveMultiboard, SelectionClientBridge

    function SelectionStartGameAfterAllSelected takes nothing returns nothing
        call SelectionCreateClients()
        call SelectionShowClients()
        call ShowInitialWaveMultiboard()
        set WaveTgg = "Trig_w1_Actions"
        call StartInitialWaveCountdown()
    endfunction

endlibrary
