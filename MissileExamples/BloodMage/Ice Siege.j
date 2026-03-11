//TESH.scrollpos=0
//TESH.alwaysfold=0
library IceSiege initializer Init uses SpellIndex /*v2.0
*************************************************************************************
*
*   The caster covers himself with a amor of ice.
*   The armor slows and damages nearby foes.
*
*************************************************************************************
*
*   uses TimerUtils, UnitIndexer
*   optional DummyCaster, SpellEffectEvent, Alloc
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer    ICE_SIEGE_ABILITY = 'A001'
        private constant real       TIMER_TIMEOUT     = 1.0//*  The interval between each periodic damage event
        //*  Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_NORMAL
        //*  Effect options.
        private constant string ON_CASTER_FX    = "Abilities\\Spells\\Undead\\FrostArmor\\FrostArmorTarget.mdl"
        private constant string FX_ATTACH_POINT = "chest"
        //*  Buff variables.
        private constant integer    BUFF_CAST_ID = 'A004'//*  Raw code of the Ice Siege Apply buff ability  - Object Editor (F6)
        private constant integer    ORDER_ID     = 852226//*  Order of the Ice Siege Apply buff ability     - Trigger Editor (OrderIds) --> Frostnova
    endglobals
    
    //*  Filter out which units should recieve period damage.
    private function FilterUnits takes unit target, player p returns boolean
        return (UnitAlive(target)) and (IsUnitEnemy(target, p)) and (not IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE))
    endfunction
    //*  Set the damage.
    private constant function GetDamage takes integer level returns real
        return 45. + (10*level)
    endfunction
    //*  Set how often periodic damage is applied.
    private constant function GetWaves takes integer level returns integer
        return 4 + 0*level
    endfunction
    //*  Set the collision size of the spell.
    private constant function GetRange takes integer level returns integer
        return 400 + 100*level
    endfunction

//========================================================================
//*  Ice siege code. Make changes carefully.
//========================================================================
    
    private function OnPeriodic takes nothing returns nothing   
        local SpellIndex dex = GetTimerData(GetExpiredTimer())
        local unit u
        if (dex.count > 0) and UnitAlive(dex.source) then
            set dex.count = dex.count - 1
            call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, GetUnitX(dex.source), GetUnitY(dex.source), dex.collision, null)
            loop
                set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                exitwhen u == null
                call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
                if (FilterUnits(u, dex.user)) then
                    call DummyCaster[BUFF_CAST_ID].castTarget(dex.user, 1, ORDER_ID, u)
                    call UnitDamageTarget(dex.source, u, dex.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                endif
            endloop
        else
            call dex.destroy()//*  Nulls all members automatically.
            call ReleaseTimer(GetExpiredTimer())
        endif
    endfunction
        
    private function OnEffect takes nothing returns nothing
        local integer level = GetUnitAbilityLevel(GetTriggerUnit(), ICE_SIEGE_ABILITY)
        //*  Allocate a spell index and assign members.
        local SpellIndex dex = SpellIndex.create()
        set dex.user = GetTriggerPlayer()
        set dex.source = GetTriggerUnit()
        set dex.damage = GetDamage(level)
        set dex.collision = GetRange(level)
        set dex.count = GetWaves(level)
        set dex.fx = AddSpecialEffectTarget(ON_CASTER_FX, dex.source, FX_ATTACH_POINT)
        call TimerStart(NewTimerEx(dex), TIMER_TIMEOUT, true, function OnPeriodic)
    endfunction
        
    private function Init takes nothing returns nothing
        call RegisterSpellEffectEvent(ICE_SIEGE_ABILITY, function OnEffect)
    endfunction
    
endlibrary

