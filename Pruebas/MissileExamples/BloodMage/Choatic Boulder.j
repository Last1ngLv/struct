//TESH.scrollpos=12
//TESH.alwaysfold=0
library ChaoticBoulder initializer Init uses SpellIndex, IsDestructableTree /*v1.0
*************************************************************************************
*
*   Hurls a boulder of magma towards the targeted point, 
*   splitting on impact into tiny fragments that launch into the sky.
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer    CHAOTIC_BOULDER_ABILITY = 'A00D'
        //*  Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        //*  Effect options. 
        private constant string ON_EFFECT_FX     = "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl"
        private constant string ON_DAMAGE_BIG_FX = "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl"
    endglobals

    //*  Filter valid target units.
    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_FLYING)
    endfunction
    //*  Set the travel distance.
    private function GetSmallBoulderFlyDistance takes integer level returns real
        return  GetRandomReal(50., 200.)
    endfunction
    //*  Set the explosion radius on impact.
    private constant function GetExplosionRadius takes integer level returns real
        return 200. + (0.*level)
    endfunction
    //*  Set the amount of fragments.
    private function GetSmallBoulderCount takes integer level returns integer
        return GetRandomInt(4, 6) + 2*level
    endfunction
    //*  Customize all missile members to your needs. 
    private function CustomizeSmallMissile takes Missile missile, real distance, integer level returns nothing
        call missile.flightTime2Speed(GetRandomReal(1., 1.5)*distance/200.)
        set missile.damage = 10. + 10.*level
        set missile.collision = 96.
        set missile.arc = GetRandomReal(80., 85.)*bj_DEGTORAD
        set missile.model = "Abilities\\Spells\\Other\\Volcano\\VolcanoMissile.mdl"
        set missile.scale = 0.8
    endfunction
    //*  Customize all missile members to your needs.
    private function CustomizeBigMissile takes Missile missile, real distance, integer level returns nothing
        call missile.flightTime2Speed(GetRandomReal(1., 2.)*distance/800.)
        set missile.damage = 200. + 70.*level
        set missile.arc = 45.*bj_DEGTORAD + RMinBJ(20., distance*.1)*bj_DEGTORAD
        set missile.collision = 128.
        set missile.model = "Abilities\\Spells\\Other\\Volcano\\VolcanoMissile.mdl"
        set missile.scale = 1.2
    endfunction

//========================================================================
//*  Chaotic boulder code. Make changes carefully.
//========================================================================
    
    //*  Uses Missile's API. Add or remove whatever you need.
    private struct ChaoticBoulder extends array
        
        //*  Only living trees are valid targets.
        private static method onDestructable takes Missile missile, destructable hit returns boolean
            if IsDestructableTree(hit) and (GetWidgetLife(hit) > .405) then
                call KillDestructable(hit)
            endif
            return false
        endmethod
                
        private static method createSmallBoulders takes Missile big returns nothing
            local integer level = GetUnitAbilityLevel(big.source, CHAOTIC_BOULDER_ABILITY)
            local integer dex = 0
            local integer max = GetSmallBoulderCount(level)
            local Missile small
            loop
                exitwhen (dex >= max)
                set small = Missile.create(big.x, big.y, 0., GetRandomReal(-bj_PI, bj_PI), GetSmallBoulderFlyDistance(level), 0.)
                call CustomizeSmallMissile(small, small.origin.distance, level)
                set small.source = big.source
                set small.owner = big.owner
                set small.data = 0
                call thistype.launch(small)
                set dex = dex + 1
            endloop
        endmethod
                
        //*  Damages close unit on missile removal.
        private static method onRemove takes Missile missile returns boolean
            local unit u
            call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, missile.collision, null)
            loop
                set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                exitwhen u == null
                call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
                if FilterUnits(u, missile.owner) then
                    call UnitDamageTarget(missile.source, u, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                endif
            endloop
            //*  Detect big boulder. 
            if (missile.data == -1) then
                //*  Runs effects.
                call DestroyEffect(AddSpecialEffect(ON_DAMAGE_BIG_FX, missile.x, missile.y))
                call createSmallBoulders(missile)
            endif
            return true
        endmethod
        
        implement MissileStruct
    endstruct
        
    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local integer level = GetUnitAbilityLevel(source, CHAOTIC_BOULDER_ABILITY)
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        //*  Create the main missile.
        local Missile missile = Missile.createXYZ(x, y, GetUnitFlyHeight(source), GetSpellTargetX(), GetSpellTargetY(), 0.)
        call CustomizeBigMissile(missile, missile.origin.distance, level)
        set missile.source = source
        set missile.data = -1
        set missile.owner = GetTriggerPlayer()
        call ChaoticBoulder.launch(missile)
        //*  Runs Effects.
        call DestroyEffect(AddSpecialEffect(ON_EFFECT_FX, x, y))
        set source = null
    endfunction
    
    private function Init takes nothing returns nothing
        call RegisterSpellEffectEvent(CHAOTIC_BOULDER_ABILITY, function OnEffect)
    endfunction
    
endlibrary

