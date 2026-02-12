function Trig_show_bag_Conditions takes nothing returns boolean
    if ( not ( GetSpellAbilityId() == 'A002' ) ) then
        return false
    endif
    return true
endfunction

function Trig_show_bag_Actions takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local Inventory inv = Inventory[u]
    local integer pid = GetPlayerId(GetOwningPlayer(u))
    local unit u2 = Equipment[Equipment.PlayerCurrentUnit[pid]].unit
    
    call inv.show(not inv.displayed, PlayerCamera[pid])
    
    if (u2 != null and u2 != u) then
        call Equipment[Equipment.PlayerCurrentUnit[pid]].show(false, PlayerCamera[pid])
    endif
    
    set u = null
endfunction

//===========================================================================
function InitTrig_Show_Inventory takes nothing returns nothing
    set gg_trg_Show_Inventory = CreateTrigger(  )
    call TriggerRegisterAnyUnitEventBJ( gg_trg_Show_Inventory, EVENT_PLAYER_UNIT_SPELL_EFFECT )
    call TriggerAddCondition( gg_trg_Show_Inventory, Condition( function Trig_show_bag_Conditions ) )
    call TriggerAddAction( gg_trg_Show_Inventory, function Trig_show_bag_Actions )
endfunction

