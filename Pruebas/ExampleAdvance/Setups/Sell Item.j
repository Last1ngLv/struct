scope SellItem initializer Init

    globals
        private InvItem array SellItem
        private integer array SellSlot
        private Inventory array SellInv
    endglobals 
    
    private function OnAgree takes nothing returns boolean
        local User user = User[GetTriggerPlayer()]
        local InvItem itm = SellItem[user.id]
        local integer slot = SellSlot[user.id]
        local Inventory inv = SellInv[user.id] 
        
        call inv.setItem(slot, 0)
        call SetPlayerState(inv.user.toPlayer(), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(inv.user.toPlayer(), PLAYER_STATE_RESOURCE_GOLD) + itm.cost)
        call DisplayTimedTextToPlayer(inv.user.toPlayer(), 0, 0, 15, "You sold \"" + GetObjectName(itm.id) + "\" for |cffffcc00" + I2S(itm.cost) + "|r gold.")
        
        return false
    endfunction
    
    private function Actions takes nothing returns nothing
        local InvItem itm = InvEventItem
        local player p = InvEventPlayer
        local Inventory inv = Inventory.PlayerCurrent[User[p].id]
        local integer slot = InvEventSlot
        
        if (itm <= 0) then
            return
        endif
        
        set SellItem[inv.user.id] = itm
        set SellSlot[inv.user.id] = slot
        set SellInv[inv.user.id] = inv
        
        call inv.showTooltip(inv, false)
        
        call ShowYesNoDialog("Sell " + GetObjectName(itm.id) + "?", inv.user, Filter(function OnAgree))
    endfunction

    //===========================================================================
    private function Init takes nothing returns nothing
        set Inventory.onSell = CreateTrigger()
        call TriggerAddAction(Inventory.onSell, function Actions)
    endfunction

endscope