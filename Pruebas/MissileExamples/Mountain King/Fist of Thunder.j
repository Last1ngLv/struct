//TESH.scrollpos=0
//TESH.alwaysfold=0
library FistOfThunder initializer Init uses SpellIndex /* v1.0
*************************************************************************************
*
*   Slams the ground in front of you, dealing damage to close enemies.
*   Emerging lightnings deal extra damage, when colliding with an enemy.
*
*************************************************************************************/
//**
//*  User settings:
//*  ==============
    globals
        private constant integer FIST_OF_THUNDER_ABILITY = 'A00C'
        //*  Damage options.
        private constant attacktype ATTACK_TYPE = ATTACK_TYPE_NORMAL
        private constant damagetype DAMAGE_TYPE = DAMAGE_TYPE_MAGIC
        //*  Set the lightning end z.
        private constant real MISSILE_END_Z = 175.
        //*  Effect options.
        private constant string LIGHTNING_MODEL         = "CLPB"
        private constant string SLAM_CENTER_FX          = "Abilities\\Spells\\Orc\\Purge\\PurgeBuffTarget.mdl"
        private constant real   SLAM_CENTER_FX_DURATION = 2.
        //*  Concept.
        private constant boolean DESTROY_MISSILE_ON_COLLIDE = true
    endglobals
    
    //*  Set the slam collision size.
    private constant function GetSlamCollisionSize takes integer level returns real
        return 180.
    endfunction
    //*  Set the damage dealt on slam.  
    private constant function GetSlamDamage takes integer level returns real
        return 40.*level - 10.
    endfunction
    //*  Set the travel distance for each missile.
    private constant function GetMissileFlyDistance takes integer level returns real
        return  600. + (50*level)
    endfunction
    //*  Set the amount of Missiles based on the ability level.
    private constant function GetMissileCount takes integer level returns integer
        return 4 + 2*level
    endfunction
    //*  Filter valid target units.
    private function FilterUnits takes unit target, player owner returns boolean
        return UnitAlive(target) and IsUnitEnemy(target, owner) and not IsUnitType(target, UNIT_TYPE_STRUCTURE)
    endfunction
    //*  Customize all missile members to your needs.
    private function CustomizeMissile takes Missile missile, integer level returns nothing
        set missile.speed  = 22. + 0.*level
        set missile.damage = 10. + 10.*level
        set missile.collision = 32.
        set missile.model = "Abilities\\Weapons\\SpiritOfVengeanceMissile\\SpiritOfVengeanceMissile.mdl"
        set missile.scale = 1.
    endfunction
    //*  These effects run on spell effect event.  Customize them to your needs.  
    private function RunOnSlamEffects takes unit source, real slamX, real slamY returns nothing
        //*  Runs sounds.
        local string file = "Abilities\\Spells\\Orc\\LightningBolt\\LightningBolt.wav"
        local sound s
        if (GetRandomInt(0, 1) == 0) then
            set file = "Abilities\\Spells\\Orc\\LightningShield\\LightningShieldTarget.wav" 
        endif
        set s = CreateSound(file, false, false, false, 10, 10, "")
        call AttachSoundToUnit(s, source)
        call StartSound(s)
        call KillSoundWhenDone(s)
        //*  Run special effects.
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", slamX, slamY))
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\StormBolt\\StormBoltMissile.mdl", source, "weapon,right"))
        //*
        set s = null
    endfunction
    //*  These effects run when a missile ( source ) collides with a unit ( hit )
    private function RunOnCollideEffects takes unit source, unit hit returns nothing
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", hit, "origin"))
    endfunction 
    
//========================================================================
//*  Fist of Thunder code. Make changes carefully.
//========================================================================
    
    //*  Uses Missile's API. For a destructable enum, add .onDestructable and .onDestructableFilter.
    private struct FistOfThunder extends array
        
        //*  Releases the lightning model.
        private static method onRemove takes Missile missile returns boolean
            call SpellIndex(missile.data).destroy()
            return true
        endmethod
        
        static method onCollide takes Missile missile, unit hit returns boolean
            if FilterUnits(hit, missile.owner) then
                call UnitDamageTarget(missile.source, hit, missile.damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
                call RunOnCollideEffects(missile.dummy, hit)
                return DESTROY_MISSILE_ON_COLLIDE
            endif
            return false
        endmethod
        
        static method onPeriod takes Missile missile returns boolean
            local MissilePosition pos = missile.origin
            call MoveLightningEx(SpellIndex(missile.data).flash, true, pos.x, pos.y, pos.z, missile.x, missile.y, missile.z + missile.terrainZ)
            return false
        endmethod
        
        implement MissileStruct
    endstruct
    
    private function Callback takes nothing returns nothing
        static if LIBRARY_TimerUtilsEx then
            call SpellIndex(ReleaseTimer(GetExpiredTimer())).destroy()
        else
            call SpellIndex(GetTimerData(GetExpiredTimer())).destroy()
            call ReleaseTimer(GetExpiredTimer())
        endif
    endfunction
    
    private function CreateMissiles takes unit source, player user, real x, real y, integer level returns nothing
        local integer dex = 0
        local integer end = GetMissileCount(level)
        local real spacing = bj_PI*2/end
        local real angle = GetRandomReal(-bj_PI, bj_PI)
        local real distance = GetMissileFlyDistance(level)
        local Missile missile
        loop   
            exitwhen (dex == end)
            //*  Create a new missile and assign it's members.
            set missile = Missile.create(x, y, 0., angle, distance, MISSILE_END_Z)
            call CustomizeMissile(missile, level)
            set missile.source = source
            set missile.owner = user
            set missile.data = SpellIndex.create()
            set SpellIndex(missile.data).flash = AddLightningEx(LIGHTNING_MODEL, true, x, y, missile.origin.z, x, y, missile.z + missile.terrainZ)
            call FistOfThunder.launch(missile)
            //*  Next missile.
            set angle = angle + spacing
            set dex = dex + 1
        endloop
    endfunction
    
    private function OnEffect takes nothing returns nothing
        local unit source = GetTriggerUnit()
        local player user = GetTriggerPlayer()
        local integer level = GetUnitAbilityLevel(source, FIST_OF_THUNDER_ABILITY)
        local real x = GetSpellTargetX()
        local real y = GetSpellTargetY()
        local real damage = GetSlamDamage(level)
        local SpellIndex dex = SpellIndex.create()
        local unit u
        //*  Runs Effects.
        call RunOnSlamEffects(source, x, y)
        call GroupEnumUnitsInRange(SpellIndex.GLOBAL_GROUP, x, y, GetSlamCollisionSize(level), null)
        loop
            set u = FirstOfGroup(SpellIndex.GLOBAL_GROUP)
            exitwhen u == null
            call GroupRemoveUnit(SpellIndex.GLOBAL_GROUP, u)
            if (FilterUnits(u, user)) then
                call UnitDamageTarget(source, u, damage, false, false, ATTACK_TYPE, DAMAGE_TYPE, null)
            endif
        endloop
        //*  Create all missiles.
        call CreateMissiles(source, user, x, y, level)
        //*  Create center model
        set dex.fx = AddSpecialEffect(SLAM_CENTER_FX, x, y)
        call TimerStart(NewTimerEx(dex), SLAM_CENTER_FX_DURATION, false, function Callback)
        set user = null
        set source = null
    endfunction
    
    private function Init takes nothing returns nothing
        call RegisterSpellEffectEvent(FIST_OF_THUNDER_ABILITY, function OnEffect)
    endfunction
endlibrary