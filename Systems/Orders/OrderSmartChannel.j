//TESH.scrollpos=81
//TESH.alwaysfold=0
library OrderSmartChannel

globals
    private trigger MZ       = CreateTrigger()
    private trigger SZ       = CreateTrigger()
    constant integer SmartIDHide = 'HDHD'
    
    private constant string KeyStringCMD = "Key_StringCMD" 
endglobals

private struct AuxiliarDataUnit
    unit u = null
    unit t = null
    item itm = null
    destructable des = null
    real x = 0
    real y = 0
endstruct

/*
//Code By DioD
private function FCC_Order2 takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local AuxiliarDataUnit d = GetHandleInt(GetHandleId(t), KeyStringCMD)
    
    if d.des != null then
        call IssueTargetOrder(d.u,"smart",d.des)
    elseif d.itm != null then
        call IssueTargetOrder(d.u,"smart",d.itm)
    elseif d.t != null then
        if IsUnitAlly(d.t,GetOwningPlayer(d.u)) then
            call IssueTargetOrder(d.u,"smart",d.t)
        else
            call IssueTargetOrder(d.u,"attack",d.t)
        endif
    else
    endif
    
    call DecUnitAbilityLevel(d.u,SmartIDHide)
    
    call RemoveInt(GetHandleId(t), KeyStringCMD)
    call RemoveBoolean(GetHandleId(d.u), KeyStringCMD)
    call DestroyTimer(t)
    call d.destroy()
    set t = null
endfunction

//Code By DioD
private function FCC_MAIN2 takes nothing returns nothing
    local AuxiliarDataUnit d = 0
    local timer t = null
    if GetIssuedOrderId() != OrderId("smart") then
        return
    elseif GetUnitAbilityLevel(GetTriggerUnit(),SmartIDHide) <= 0 or GetHandleBoolean(GetHandleId(GetTriggerUnit()), KeyStringCMD) then
        return
    endif
    
    set d = AuxiliarDataUnit.create()
    set d.u = GetTriggerUnit()
    set d.t = GetOrderTargetUnit()
    set d.itm = GetOrderTargetItem()
    set d.des = GetOrderTargetDestructable()
    set d.x = GetOrderPointX()
    set d.y = GetOrderPointY()
    
    call SetHandleBoolean(GetHandleId(d.u), KeyStringCMD, true)
    
    if d.des != null then
    elseif d.itm != null then
    elseif d.t != null then
    else
        call IssuePointOrder(d.u,"smart",d.x,d.y)
    endif
    
    call IncUnitAbilityLevel(d.u,SmartIDHide)

    set t = CreateTimer()
    call SetHandleInt(GetHandleId(t), KeyStringCMD, d)
    call TimerStart(t, 0, false, function FCC_Order2)
    set t = null
endfunction

private function StopChannelPoint takes nothing returns nothing
    if GetSpellAbilityId() == SmartIDHide then
        call IssueImmediateOrder(GetTriggerUnit(),"stop")
    endif
endfunction */

function SILENCE_TESTUNIT_AMOV takes unit a returns nothing
    call SetUnitAbilitySilenced(a,'Amov',false)//I return to the ability 'Amov' immune to silence
    call UnitAddAbility(a,SmartIDHide)//Added the channel skill with the "smart" order
    call UnitRemoveAbility(a,'Aatk')
    call UnitMakeAbilityPermanent(a,true,SmartIDHide)//The permanent ability to not be removed by a morph
    call SetUnitAbilitySilenced(a,SmartIDHide,true) // Here the Canal spell cannot be silenced and it will also have the Universal Spell option
    call UnitAddAbility(a,'Aro1') //I add Root to hide 'Amov'
    call UnitRemoveAbility(a,'Aro1') //Let's remove Aro1 "Root" since we don't need it anymore.
endfunction

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function EButts takes nothing returns nothing
    /*call TriggerRegisterAnyUnitEventBJ( MZ, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER )
    call TriggerRegisterAnyUnitEventBJ( MZ, EVENT_PLAYER_UNIT_ISSUED_ORDER )
    call TriggerRegisterAnyUnitEventBJ( MZ, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER )
    call TriggerAddAction( MZ, function FCC_MAIN2 )
    
    call TriggerRegisterAnyUnitEventBJ( SZ, EVENT_PLAYER_UNIT_SPELL_CAST )
    call TriggerAddAction( SZ, function StopChannelPoint ) */
    
    //call SILENCE_TESTUNIT_AMOV.execute()
endfunction

endlibrary