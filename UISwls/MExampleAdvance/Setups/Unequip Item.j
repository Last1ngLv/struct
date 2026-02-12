scope UnequipItem initializer Init

    private function Actions takes nothing returns nothing
        //call BJDebugMsg(GetPlayerName(InvEquipPlayer) + " unequipped " + GetObjectName(InvEquipItem.id))
    endfunction

    //===========================================================================
    private function Init takes nothing returns nothing
        set InvItem.onUnequip = CreateTrigger()
        call TriggerAddAction(InvItem.onUnequip, function Actions)
    endfunction

endscope