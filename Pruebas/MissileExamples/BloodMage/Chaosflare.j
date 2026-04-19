//TESH.scrollpos=0
//TESH.alwaysfold=0
library Chaosflare initializer Init uses SpellIndex /* v2.0
*************************************************************************************
*
*   The caster concentrates his power to let loose a powerful beam of fire
*   towards the target, dealing damage and burning the target.
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer    CHAOSFLARE_ABILITY    = 'A002'
        private constant real       TIMER_TIMEOUT         = 1.0//*  The interval between two dot damage events.
        //*  Damage options.
        private constant attacktype ATTACK_TYPE           = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE           = DAMAGE_TYPE_MAGIC
        //*  Effects options.
        private constant string     FLAME_FX              = "Abilities\\Weapons\\RedDragonBreath\\RedDragonMissile.mdl"
        private constant real       SPACE_BETWEEN_FLAMES  = 75.
        private constant integer    MAX_FLAMES            = 15//*  Performance protection.
        private constant string     ON_CASTER_FX          = "Abilities\\Spells\\Other\\Volcano\\VolcanoDeath.mdl"
        private constant string     ON_TARGET_FX          = "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl"
        private constant string     DOT_FX                = "Abilities\\Spells\\NightElf\\Immolation\\ImmolationDamage.mdl"
        private constant string     DOT_FX_ATTACH_POINT   = "origin"
        //*  Buff variables.
        private constant integer    BUFF_ID      = 'B000'//*  Raw code of the Chaosflare buff                - Object Editor (F6)
        private constant integer    BUFF_CAST_ID = 'A000'//*  Raw code of the Chaosflare Apply buff ability  - Object Editor (F6)
        private constant integer    ORDER_ID     = 852075//*  Order of the Chaosflare Apply buff ability     - Trigger Editor (OrderIds) --> slow
    endglobals
    
    //*  Set the impact damage.  
    private constant function GetImpactDamage takes integer level returns real
        return 45. + (10*level)
    endfunction
    //*  Set the periodic damage.
    private constant function GetDamageOverTime takes integer level returns real
        return 20. + (10*level)
    endfunction
    //*  Set how often damage over time is applied.
    private constant function GetDamageOverTimeCount takes integer level returns integer
        return 4 + 0*level
    endfunction
    
//========================================================================
//*  Chaosflare code. Make changes carefully.
//========================================================================
    
    private function OnPeriodic takes nothing returns nothing
        local SpellIndex dex = GetTimerData(GetExpiredTimer())
        if (dex.count <= 0) or not UnitAlive(dex.target) or (GetUnitAbilityLevel(dex.target, BUFF_ID) == 0) then
            call UnitRemoveAbility(dex.target, BUFF_ID)
            call ReleaseTimer(GetExpiredTimer())
            call dex.destroy()//*  Nulls members automatically.
            return
        //*  Deal damage.
        elseif (GetUnitTypeId(dex.source) != 0) then
            call UnitDamageTarget(dex.source, dex.target, dex.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
            call DestroyEffect(AddSpecialEffectTarget(DOT_FX, dex.target, DOT_FX_ATTACH_POINT))        
        endif
        set dex.count = dex.count - 1
    endfunction
    
    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local unit target = GetSpellTargetUnit()
        local real posX = GetUnitX(source)
        local real posY = GetUnitY(source)
        local real angle = Atan2(GetUnitY(target) - posY, GetUnitX(target) - posX)
        local real cos = SPACE_BETWEEN_FLAMES*Cos(angle)
        local real sin = SPACE_BETWEEN_FLAMES*Sin(angle)
        local integer level = GetUnitAbilityLevel(source, CHAOSFLARE_ABILITY)
        local integer i = 0
        local SpellIndex dex 
        //*  Run effects.
        call DestroyEffect(AddSpecialEffect(ON_CASTER_FX, posX, posY))
        call DestroyEffect(AddSpecialEffectTarget(ON_TARGET_FX, target, "origin"))
        loop
            exitwhen (IsUnitInRangeXY(target, posX, posY, SPACE_BETWEEN_FLAMES)) or (i == MAX_FLAMES)
            set posX = posX + cos
            set posY = posY + sin
            call DestroyEffect(AddSpecialEffect(FLAME_FX, posX, posY))
            set i = i + 1
        endloop
        //*  Deal damage and apply the buff. Conditionally start the timer.
        if UnitDamageTarget(source, target, GetImpactDamage(level), false, false, ATTACK_TYPE, DAMAGE_TYPE, null) then
            if DummyCaster[BUFF_CAST_ID].castTarget(GetOwningPlayer(source), 1, ORDER_ID, target) then 
                //*  Allocate a spell instance.
                set dex = SpellIndex.create()
                set dex.source = source
                set dex.target = target
                set dex.count  = GetDamageOverTimeCount(level)
                set dex.damage = GetDamageOverTime(level)
                call TimerStart(NewTimerEx(dex), TIMER_TIMEOUT, true, function OnPeriodic)
            endif
        endif
        set source = null
        set target = null
    endfunction
    
    private function Init takes nothing returns nothing
        call RegisterSpellEffectEvent(CHAOSFLARE_ABILITY, function OnEffect)
    endfunction
endlibrary
