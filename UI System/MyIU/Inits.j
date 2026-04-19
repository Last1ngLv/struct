library Clk initializer Init requires MenuClient, UserInterface, SelectionSystem

    globals
        private boolean ClkMenuRegistered = false
    endglobals

    function Trig_MenuClient_Actions takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local player p = GetTriggerPlayer()
        local integer pid = GetPlayerId(p)

        if u != PlayerHero[pid] then
            set u = null
            set p = null
            return
        endif

        call Client[u].show(true, PlayerCamera[pid])

        set u = null
        set p = null
    endfunction

    // Compatibilidad con GUI-style init, pero sin gg_trg_ShowMenuClient.
    function InitTrig_ShowMenuClient takes nothing returns nothing
        local trigger t
        local integer i = 0

        if ClkMenuRegistered then
            return
        endif
        set ClkMenuRegistered = true

        set t = CreateTrigger()
        loop
            exitwhen i > 7
            call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_SELECTED, null)
            set i = i + 1
        endloop
        call TriggerAddAction(t, function Trig_MenuClient_Actions)

        set t = null
    endfunction

    private function Init takes nothing returns nothing
        call InitTrig_ShowMenuClient()
    endfunction

endlibrary
