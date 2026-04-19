scope EquipItem initializer Init

    function IsInvItm2H takes InvItem itm returns boolean
        return (itm.slot == 13 and itm.slotAlt == 0)
    endfunction
    
    private function Actions takes nothing returns nothing
        local InvItem itm = InvEventItem
        local player p = InvEventPlayer
        local unit u = Equipment.PlayerCurrentUnit[User[p].id]
        local Inventory inv = Inventory[u]
        local Equipment gear = Equipment[u]
        local boolean is2h = IsInvItm2H(itm)
        
        // 2H weapon conditions
        if (is2h) then
        
            if (gear.item[14-1] > 0) then
                call SimError(p, "You cannot equip a two-handed weapon with an offhand item.")
                call gear.unequip(gear.item[itm.slot-1], itm.slot-1)
                
                if (inv > 0) then
                    call inv.addItem(itm)
                else
                    call SetItemUserData(UnitAddItemById(u, itm.id), itm.tempCustomId)
                    set itm.tempCustomId = 0
                endif
            endif
            
        elseif (itm.slot == 14 or itm.slotAlt == 14) then
        
            if (gear.item[13-1] > 0 and IsInvItm2H(gear.item[13-1])) then
                call SimError(p, "You cannot equip an offhand item with a two-handed weapon.")
                call gear.unequip(gear.item[14-1], 14-1)
                
                if (inv > 0) then
                    call inv.addItem(itm)
                else
                    call SetItemUserData(UnitAddItemById(u, itm.id), itm.tempCustomId)
                    set itm.tempCustomId = 0
                endif
            
            endif
            
        endif
        
        set u = null
    endfunction

    //===========================================================================
    private function Init takes nothing returns nothing
        set InvItem.onEquip = CreateTrigger()
        call TriggerAddAction(InvItem.onEquip, function Actions)
    endfunction

endscope