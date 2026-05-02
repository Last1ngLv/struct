library RestTimeMenuBridge requires PlayerUtils, PlayerHeroState, MenuClient, RestTimeState

    function RestTimeMenuApplyStatusForActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]
            if hero != null and GetUnitTypeId(hero) != 0 then
                set client = Client[hero]
                if client != 0 then
                    call client.setWaveStatusTitle(RestStatusText)
                endif
            endif
            set i = i + 1
        endloop
        set hero = null
    endfunction

    function RestTimeMenuCloseTenderForActivePlayers takes nothing returns nothing
        // No-op: RestTime ya no abre/cierra paneles especiales del MenuClient.
    endfunction

    function RestTimeMenuShowClientsForActivePlayers takes nothing returns nothing
        // No-op: el MenuClient minimal se muestra desde Selection/Stage, no desde RestTime.
    endfunction

endlibrary
