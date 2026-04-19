//TESH.scrollpos=81
//TESH.alwaysfold=0
library Whirlwind initializer Init uses SpellIndex /* v2.0
*************************************************************************************
*
*   The caster performs a deadly dance, dealing damage to all nearby units.
*   Units using whirlwind need a spin-walk animation i.e the blademaster.
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        //*  Only works for immolation based abilities.
        private constant integer WHIRLWIND_ABILITY = 'A00A'
        private constant integer WHIRLWIND_BUFF    = 'B003'
        //*  Do you wish to disable the default attack during whirlwind?
        private constant boolean DISABLE_ATTACK = true
        //*  Damage type options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_NORMAL
        //*  Set how often damage is dealt. Adjust the damage along with the timeout.
        private constant real TIMER_TIMEOUT = 0.25
    endglobals
    //*  Set the damage dealt per timer timeout.
    private constant function GetDamage takes integer level returns real
        return 0.00 + level*50.00
    endfunction
    //*  Set the collision size.
    private constant function GetCollision takes integer level returns real
        return 200.
    endfunction
    //*  Filter valid target units.
    private function FilterUnits takes unit target, player owner returns boolean
        return IsUnitEnemy(target, owner) and UnitAlive(target)
    endfunction
    
//========================================================================
//*  Whirlwind code. Make changes carefully.
//========================================================================
        
    globals
        //*  Reference casters.
        private Table table 
    endglobals
        
    private function Clear takes SpellIndex dex returns nothing
        static if DISABLE_ATTACK then
            if (dex.count == 0) then
                call UnitRemoveAbility(dex.source, 'Abun')
            endif
        endif
        call table.remove(GetHandleId(dex.source))
        call AddUnitAnimationProperties(dex.source, "spin", false)
        call UnitRemoveAbility(dex.source, WHIRLWIND_BUFF)
        call ReleaseTimer(dex.clock)
        call dex.destroy()
    endfunction
        
    private function OnPeriodic takes nothing returns nothing
        local SpellIndex dex = GetTimerData(GetExpiredTimer())
        local unit u
        if UnitAlive(dex.source) and (GetUnitAbilityLevel(dex.source, WHIRLWIND_BUFF) != 0) then
            call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, GetUnitX(dex.source), GetUnitY(dex.source), dex.collision, null)
            loop
                set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                exitwhen null == u
                call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
                if FilterUnits(u, dex.user) then
                    call UnitDamageTarget(dex.source, u, dex.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                endif
            endloop
        else
            call Clear(dex)
        endif
    endfunction
        
    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local SpellIndex dex = SpellIndex.create()
        set dex.source = source
        set dex.level = GetUnitAbilityLevel(source, WHIRLWIND_ABILITY)
        set dex.damage = GetDamage(dex.level)
        set dex.collision = GetCollision(dex.level)
        set dex.user = GetTriggerPlayer()
        //*  Run effects.
        call SetUnitAnimation(source, "spin")
        call AddUnitAnimationProperties(source, "spin", true)        
        static if DISABLE_ATTACK then
            set dex.count = GetUnitAbilityLevel(source, 'Abun')
            if (dex.count == 0) then
                call UnitAddAbility(source, 'Abun')
            endif
        endif
        set dex.clock = NewTimerEx(dex)
        call TimerStart(dex.clock, TIMER_TIMEOUT, true, function OnPeriodic)
        //*
        set table[GetHandleId(source)] = dex
        set source = null
    endfunction
    
    private function OnOrder takes nothing returns nothing
        local unit source = GetTriggerUnit()
        if (GetIssuedOrderId() == 852178) and (GetUnitAbilityLevel(source, WHIRLWIND_BUFF) != 0) and table.has(GetHandleId(source)) then
            //*  For pause units the clear function will not work at all.
            if not (IsUnitPaused(source)) then
                call Clear(table[GetHandleId(source)])
            endif
        endif
        set source = null
    endfunction
  
    private function Init takes nothing returns nothing
        set table = Table.create()
        call RegisterSpellEffectEvent(WHIRLWIND_ABILITY, function OnEffect)
        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnOrder)
    endfunction
    
endlibrary
