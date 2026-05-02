library InitialGoldConfig requires PlayerUtils

    globals
        private constant integer INITIAL_PLAYER_GOLD = 1
        private constant integer MAX_HUMAN_PLAYER_SLOTS = 8
    endglobals

    function InitInitialPlayerGold takes nothing returns nothing
        local integer i = 0
        local User u
        local player p
        local integer currentGold

        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            if u.id >= 0 and u.id < MAX_HUMAN_PLAYER_SLOTS then
                set p = u.toPlayer()
                set currentGold = GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, currentGold + INITIAL_PLAYER_GOLD)
            endif
            set i = i + 1
        endloop

        set p = null
    endfunction

endlibrary
