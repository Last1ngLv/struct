scope DropItem initializer Init

    globals
        private InvItem array DropItem
        private integer array DropSlot
        private Inventory array DropInv
    endglobals 
    
    private function OnAgree takes nothing returns boolean
        local User user = User[GetTriggerPlayer()]
        local InvItem itm = DropItem[user.id]
        local integer slot = DropSlot[user.id]
        local Inventory inv = DropInv[user.id] 
        
        call SetItemUserData(CreateItem(itm.id, GetUnitX(inv.owner), GetUnitY(inv.owner)), inv.getItemId(slot))
        call inv.setItem(slot, 0)
        
        call DisplayTimedTextToPlayer(user.toPlayer(), 0, 0, 15, "You dropped \"" + GetObjectName(itm.id) + "\".")
        
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
        
        set DropItem[inv.user.id] = itm
        set DropSlot[inv.user.id] = slot
        set DropInv[inv.user.id] = inv
        
        call inv.showTooltip(inv, false)
        
        call ShowYesNoDialog("Drop " + GetObjectName(itm.id) + "?", inv.user, Filter(function OnAgree))
    endfunction

    //===========================================================================
    private function Init takes nothing returns nothing
        set Inventory.onDrop = CreateTrigger()
        call TriggerAddAction(Inventory.onDrop, function Actions)
    endfunction

endscope