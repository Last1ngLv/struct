//TESH.scrollpos=15
//TESH.alwaysfold=0
library ReapersScythe initializer Init uses SpellIndex /*v2.0
*************************************************************************************
*
*    Brings a target to full realization of its own mortality,
*    dealing damage based on how much life the target is missing. Stuns for 1.5 second. 
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer REAPERS_SCYTHE_ABILITY = 'A005'
        //*  Damage type options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        //*  Effect options.
        private constant string ON_GROUND_FX           = "Doodads\\BlackCitadel\\Props\\RuneArt\\RuneArt1.mdl"
        private constant string GROUND_FX_ATTACH_POINT = "origin"
        private constant string ON_DAMAGE_FX           = "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl"
        private constant string DAMAGE_FX_ATTACH_POINT = "origin"
        //*  Buff variables. You may want to integrate you own stun system.
        private constant real       STUN_DURATION = 1.5//*  Must also be adjusted in the object editor.
        private constant integer    BUFF_ID       = 'B001'//*  Raw code of the Reaper's Scythe buff                - Object Editor (F6)
        private constant integer    BUFF_CAST_ID  = 'A006'//*  Raw code of the Reaper's Scythe Apply Buff ability  - Object Editor (F6)
        private constant integer    ORDER_ID      = 852095//*  Order of the Reaper's Scythe Apply Buff ability     - Trigger Editor (OrderIds) --> thunderbolt
    endglobals
    
    //*  Set the damage factor. The original Dota setup would be 0.4, 0.6, 0.9
    private constant function GetDamageFactor takes integer level returns real
        return 0.2 + (0.2*level) 
    endfunction
    
//========================================================================
//*  Reaper's scythe code. Make changes carefully.
//========================================================================

    private function Callback takes nothing returns nothing
        local SpellIndex dex = GetTimerData(GetExpiredTimer())
        local real life = GetUnitState(dex.target, UNIT_STATE_MAX_LIFE) - GetWidgetLife(dex.target)
        if UnitAlive(dex.target) and (GetUnitTypeId(dex.source) != 0) then
            call DestroyEffect(AddSpecialEffectTarget(ON_DAMAGE_FX, dex.target, DAMAGE_FX_ATTACH_POINT))
            call UnitDamageTarget(dex.source, dex.target, dex.damage*life, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
        endif
        call dex.destroy()//*  Null automatically all members.
        call ReleaseTimer(GetExpiredTimer())
    endfunction
    
    private function OnEffect takes nothing returns nothing
        //*  Get event variables now, because DummyCaster will override them.
        local unit target = GetSpellTargetUnit()
        local unit source = GetTriggerUnit() 
        local SpellIndex dex
        //*  Conditionally create a spell index.
        if DummyCaster[BUFF_CAST_ID].castTarget(GetTriggerPlayer(), 1, ORDER_ID, target) then
            set dex = SpellIndex.create()
            set dex.source = source
            set dex.target = target
            //*  Hardcoded ubersplat handle. I think you'll like it.
            set dex.splat = CreateUbersplat(GetUnitX(target), GetUnitY(target), "HFS1", 255, 255, 255, 150, true, true)
            set dex.fx = AddSpecialEffectTarget(ON_GROUND_FX, target, GROUND_FX_ATTACH_POINT)
            set dex.damage = GetDamageFactor(GetUnitAbilityLevel(source, REAPERS_SCYTHE_ABILITY))
            call SetUbersplatRenderAlways(dex.splat, true)
            call TimerStart(NewTimerEx(dex), STUN_DURATION, false, function Callback)
        endif
        set source = null
        set target = null
    endfunction
        
    private function Init takes nothing returns nothing
        call RegisterSpellEffectEvent(REAPERS_SCYTHE_ABILITY, function OnEffect)
    endfunction
    
endlibrary

