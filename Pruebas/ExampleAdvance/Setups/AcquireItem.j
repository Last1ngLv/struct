scope AcquireItem initializer Init
    
    private function Actions takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local item itm = GetManipulatedItem()
        local Inventory inv = Inventory[u]
        local InvItem itemData
        local InvCustomItem data
        
        if (inv == 0) then
            return
        endif
        
        set itemData = GetInvItem(GetItemTypeId(itm))
        if (itemData <= 0) then
            return
        endif
        
        set data = GetItemUserData(itm)
        
        if (data == 0) then
            set data = InvCustomItem.create()
            call SetItemUserData(itm, data)
        endif
        
        set itemData.tempCustomId = data
        
        if (inv.addItem(itemData)) then
            call RemoveItem(itm)
        else
            call UnitRemoveItem(u, itm)
        endif
        
        set itm = null
        set u = null
    endfunction

    //===========================================================================
    private function Init takes nothing returns nothing
        local trigger t = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_PICKUP_ITEM)
        call TriggerAddAction(t, function Actions)
    endfunction

endscope