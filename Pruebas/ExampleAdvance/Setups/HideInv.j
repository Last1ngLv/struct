scope HideInventory initializer Init

    private function OnIndex takes nothing returns boolean
        local unit u = GetIndexedUnit()
        local Inventory inv = Inventory[u]
        local unit u2 = Equipment[Equipment.PlayerCurrentUnit[inv.pid]].unit

        if (u == u2 and u != null) then
            call Equipment[u2].show(false, PlayerCamera[inv.pid])
        endif
        
        if (Inventory.PlayerCurrent[inv.pid] == inv) then
            call inv.show(false, PlayerCamera[inv.pid])
        endif
        
        return false
    endfunction
    
    private function OnDeath takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local Inventory inv = Inventory[u]
        local unit u2 = Equipment[Equipment.PlayerCurrentUnit[inv.pid]].unit
        
        if (u == u2 and u != null) then
            call Equipment[u2].show(false, PlayerCamera[inv.pid])
        endif
        
        if (Inventory.PlayerCurrent[inv.pid] == inv) then
            call inv.show(false, PlayerCamera[inv.pid])
        endif
    endfunction
    
    private function Init takes nothing returns nothing
        local trigger t = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_DEATH)
        call TriggerAddAction(t, function OnDeath)
        
        call OnUnitDeindex(function OnIndex)
    endfunction

endscope