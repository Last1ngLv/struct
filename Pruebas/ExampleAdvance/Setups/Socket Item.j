scope SocketItem initializer Init

    globals
        private InvItem array SockItem
        private integer array SockSlot
        private Inventory array SockInv
        private integer array SockLast
        
        integer SocketLast
        integer SocketSlot
        Inventory SocketInv
    endglobals 
    
    private function OnAgree takes nothing returns boolean
        local User user = User[GetTriggerPlayer()]
        local InvItem itm = SockItem[user.id]
        local integer slot = SockSlot[user.id]
        local Inventory inv = SockInv[user.id] 
        local InvItem socketItm = inv.getItem(slot)
        
        set socketItm.tempCustomId = inv.getItemId(slot)
        
        if (socketItm.addSocket(itm)) then
        
            static if (InvItem.buildDescription.exists) then
                set socketItm.tempCustomId = inv.getItemId((Inventory.MAX_SLOTS*inv.currentPage)+slot)

                call socketItm.buildDescription(inv.owner)
            else
                call inv.setTooltipInfo(GetItemDescription(socketItm.id))
            endif
            
            call inv.setTooltipTitle(GetObjectName(socketItm.id))
            call inv.setTooltipCost("|cffffcc00" + I2S(GetInvItem(socketItm.id).cost) + "|r")
            call inv.setTooltipIcon(inv.localInt(inv.pid, GetItemIcon(socketItm.id), Inventory.ICON_TRANSPARENT))
            
            call inv.showTooltip(inv, true)
            
            call inv.setItem(SockLast[user.id], 0)
        endif
        
        return false
    endfunction
    
    private function Actions takes nothing returns nothing
        local Inventory inv = SocketInv
        local InvItem itm = inv.getItem(SocketLast)
        local InvItem socketItm = inv.getItem(SocketSlot)
        
        set SockItem[inv.user.id] = itm
        set SockSlot[inv.user.id] = SocketSlot
        set SockInv[inv.user.id] = SocketInv
        set SockLast[inv.user.id] = SocketLast
        
        call inv.showTooltip(inv, false)
        
        call ShowYesNoDialog("Socket " + GetObjectName(itm.id) + " into " + GetObjectName(socketItm.id) + "?", inv.user, Filter(function OnAgree))
    endfunction

    //===========================================================================
    private function Init takes nothing returns nothing
        set Equipment.onSocket = CreateTrigger()
        call TriggerAddAction(Equipment.onSocket, function Actions)
    endfunction

endscope