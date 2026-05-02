library RestTimeUI requires PlayerUtils, PreConfi, RestTimeState, RestTimeMenuBridge

    function RestTimeSetBoardTitle takes string title returns nothing
        if SwlsMultiboard != null then
            call MultiboardSetTitleText(SwlsMultiboard, title)
            call MultiboardDisplay(SwlsMultiboard, true)
        endif
    endfunction

    function RestTimeSetStatusForActivePlayers takes string statusText returns nothing
        set RestStatusText = statusText
        call RestTimeMenuApplyStatusForActivePlayers()
    endfunction

    function RestTimeCloseTenderForActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set isTender[u.id] = false
            set i = i + 1
        endloop
        call RestTimeMenuCloseTenderForActivePlayers()
    endfunction

    function RestTimeShowClientsForActivePlayers takes nothing returns nothing
        call RestTimeMenuShowClientsForActivePlayers()
    endfunction

endlibrary
