library MenuClientInitConfig requires GameState

    function InitMenuClientDefaults takes nothing returns nothing
        set error = CreateSound("Sound\\Interface\\Warning\\Human\\KnightNoGold1.wav", false, false, false, 12700,12700, "")
        set error_Neg = CreateSound("war3mapImported\\Error.mp3", false, false, false, 12700,12700, "")
        set Message = "BIENVENIDO!! me alegra que llegaras a tiempo no se como llegaste pero... espero no te pase lo mismo que a anteriores jugadores, los primeros que siempre ayudaron el pueblo cayeron... confio en ti"
    endfunction

endlibrary
