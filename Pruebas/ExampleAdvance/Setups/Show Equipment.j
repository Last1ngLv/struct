function Trig_show_equip_Conditions takes nothing returns boolean
    if ( not ( GetSpellAbilityId() == 'A001' ) ) then
        return false
    endif
    return true
endfunction

function Trig_show_equip_Actions takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer pid = GetPlayerId(GetOwningPlayer(u))
    local boolean flag = not Equipment[u].displayed
    
    call Equipment[u].show(flag, PlayerCamera[pid])
    
    set u = null
endfunction

//===========================================================================
function InitTrig_Show_Equipment takes nothing returns nothing
    set gg_trg_Show_Equipment = CreateTrigger(  )
    call TriggerRegisterAnyUnitEventBJ( gg_trg_Show_Equipment, EVENT_PLAYER_UNIT_SPELL_EFFECT )
    call TriggerAddCondition( gg_trg_Show_Equipment, Condition( function Trig_show_equip_Conditions ) )
    call TriggerAddAction( gg_trg_Show_Equipment, function Trig_show_equip_Actions )
endfunction

