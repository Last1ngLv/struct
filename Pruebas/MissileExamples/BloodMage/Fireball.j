//TESH.scrollpos=0
//TESH.alwaysfold=0
library Fireball initializer Init uses SpellIndex, Missile /*v2.0
*************************************************************************************
*
*    The caster hurls a fireball towards the target location,
*    dealing damage in a small aoe on impact. 
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer    FIREBALL_ABILITY = 'A007'
        //*  Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        //*  Constant missile options.
        private constant real FIREBALL_FLY_HEIGHT = 65.
        //*  Effect options.
        private constant string ON_EXPLODE_FX = "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl"
    endglobals
    
    //*  Filter valid target units.
    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
    endfunction
    //*  Set the travel distance.
    private constant function GetFlyDistance takes integer level returns real
        return  800. + (200*level)
    endfunction
    //*  Set the explosion aoe on impact.
    private constant function GetExplosionRadius takes integer level returns real
        return 200. + (0*level)
    endfunction
    //*  Customize all missile members to your needs. For example there is also arc & curve
    private function CustomizeMissile takes Missile missile, integer level returns nothing
        set missile.speed  = 20. + 0.*level
        set missile.damage = 70. + 70.*level
        set missile.collision = 32.
        set missile.model = "Abilities\\Weapons\\FireBallMissile\\FireBallMissile.mdl"
        set missile.scale = 1.
    endfunction

//========================================================================
//*  Fireball code. Make changes carefully.
//========================================================================
    
    //*  Uses Missile's API. Add or remove whatever you need.
    private struct Fireball extends array
                
        //*  Damages close unit on missile removal.
        private static method onRemove takes Missile missile returns boolean
            local unit u
            call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, missile.x, missile.y, GetExplosionRadius(missile.data), null)
            loop
                set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
                exitwhen u == null
                call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
                if FilterUnits(u, missile.owner) then
                    call UnitDamageTarget(missile.source, u, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                endif
            endloop
            //*  Run Effects.
            call DestroyEffect(AddSpecialEffectTarget(ON_EXPLODE_FX, missile.dummy, "origin"))
            return true
        endmethod
        
        //*  Runs on missile collide with any unit. Explodes on valid targets.
        private static method onCollide takes Missile missile, unit hit returns boolean
            return (FilterUnits(hit, missile.owner))
        endmethod
        
        implement MissileStruct
    endstruct
        
    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local integer level = GetUnitAbilityLevel(source, FIREBALL_ABILITY)
        local real x = GetUnitX(source)
        local real y = GetUnitY(source)
        local real angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        //*  Create a new missile and assign its members.
        local Missile missile = Missile.create(x, y, FIREBALL_FLY_HEIGHT, angle, GetFlyDistance(level), FIREBALL_FLY_HEIGHT)
        //*  Allows high level configuration.
        call CustomizeMissile(missile, level)
        //*  Override user settings. These missile members are reserved.
        set missile.source = source
        set missile.owner = GetTriggerPlayer()
        set missile.data = level
        call Fireball.launch(missile)
        set source = null
    endfunction
    
    private function Init takes nothing returns nothing
        call RegisterSpellEffectEvent(FIREBALL_ABILITY, function OnEffect)
    endfunction
    
endlibrary